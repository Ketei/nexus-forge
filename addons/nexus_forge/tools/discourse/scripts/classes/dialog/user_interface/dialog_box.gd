class_name DialogBox
extends Control


signal option_selected(option_idx: int)
signal dialog_string_signaled(signal_string: String)
signal conversation_started
signal conversation_ended

## How many seconds before choices can be selected after shown.
@export var choices_delay: float = 0.2:
	set(new_delay):
		choices_delay = snappedf(new_delay, 0.01)

var choice_time_elapsed: float = 0.0
var current_conversation: DialogData: 
	set(new_dialog):
		current_conversation = new_dialog
		current_conversation.build_dialog_map()
		

var conversation_paused: bool = false

var _current_dialog: String = ""
var _next_dialog: String = ""
var _conversation_started: bool = false

@onready var text_box: DialogTextBox = %DialogBox
@onready var options_control: DialogOptionsContainer = %OptionsBox
@onready var delta_timer: DeltaTimer


func _ready() -> void:
	delta_timer = DeltaTimer.new()
	add_child(delta_timer, false, Node.INTERNAL_MODE_FRONT)
	
	options_control.listening_to_input = false
	text_box.progress_scene_pressed.connect(_on_progress_conversation)
	
	# TEST scripts. Remove once everything works
	await get_tree().create_timer(2.0).timeout
	Characters.register_character(load("res://characters/ketei/ketei_character.tres"))
	Characters.register_character(load("res://characters/wulfre/wulfre_character.tres"))
	await get_tree().create_timer(2.0).timeout
	current_conversation = load("res://test_scenes/test_selg_dialog/new_dialog.tres")
	Characters.load_characters(current_conversation.get_conversation_characters())
	await get_tree().create_timer(1.0).timeout
	start_conversation()


# TODO Remove once testing is complete
func _unhandled_key_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_end"):
		start_conversation()


func compare_variants(var_a: Variant, var_b: Variant, comp_type: String) -> bool:
	match comp_type:
		"==":
			return var_a == var_b
		"!=":
			return var_a != var_b
		"<=":
			return var_a <= var_b
		">=":
			return var_b <= var_a
		"<":
			return var_a < var_b
		">":
			return var_b < var_a
		_:
			return false


func parse_variant(string_to_parse: String) -> Variant:
	if Strings.is_between(string_to_parse, "{", "}"): # Variable access
		return Variables.get_variable(string_to_parse.trim_prefix("{").trim_suffix("}"))
	
	elif Strings.is_between(string_to_parse,"[", "]"):
		var string_elements: PackedStringArray = Strings.split_and_strip(
				string_to_parse.trim_prefix("[").trim_suffix("]"), ",")
		
		var path: String = string_elements[0].simplify_path()
		var method: String = string_elements[1]
		
		var args: Array = []
		
		for arg in Strings.split_and_strip(string_elements[2].trim_prefix("{").trim_suffix("}"), ","):
			if Strings.is_between(arg, "{", "}"):
				args.append(Variables.get_variable(arg.trim_prefix("{").trim_suffix("}")))
			elif Strings.is_between(arg, "(", ")"):
				args.append(Strings.string_to_variant(arg.trim_prefix("(").trim_suffix(")")))
			else:
				args.append(arg)
		
		if get_tree().root.has_node(path):
			var obj: Node = get_tree().root.get_node(path)
			if obj.has_method(method):
				var callable: Callable = Callable(obj, method)
				return callable.callv(args)
		return string_to_parse
	else:
		return string_to_parse


## Clears and adds options to the option control
func set_options(possible_options: Array, cancel_option_idx: int = -1) -> void:
	options_control.clear_options()
	
	for option_idx in range(possible_options.size()):
		
		if not possible_options[option_idx]["conditions"].is_empty():
			var variant_a: Variant = parse_variant(possible_options[option_idx]["conditions"]["var_a"])
			var variant_b: Variant = parse_variant(possible_options[option_idx]["conditions"]["var_b"])
			if Variants.is_comparable(variant_a, variant_b):
				if not compare_variants(variant_a, variant_b, possible_options[option_idx]["conditions"]["comparator"]):
					continue # Condition to add option was not met, so we skip it

		options_control.add_option(
				possible_options[option_idx]["text"],
				cancel_option_idx == option_idx
		)
	
	options_control._prepare()


## Sets a new image in the portrait frames. If it has more frames to animate
## true can be passed as a second argument to play the animation.
func set_portrait(sprite_frames: SpriteFrames) -> void:
	text_box.portrait_texture_rect.portrait_frames = sprite_frames


func change_portrait(animation_name: StringName, playing: bool = false) -> void:
	if animation_name.is_empty():
		text_box.portrait_texture_rect.frame = -1
	else:
		text_box.portrait_texture_rect.set_anim_name(animation_name)
		text_box.portrait_texture_rect.playing = playing


## Sets the text and character name of the textbox. You can also pass a custom
## dialog speed that'll change the default textbox speed.
func set_dialog(character_dialogue: String, character_name: String = "", dialog_speed_change: float = -1) -> void:
	if 0 <= dialog_speed_change:
		text_box.letter_reveal_time = dialog_speed_change
	text_box.set_actor_name(character_name)
	text_box.set_dialog_text(character_dialogue)


## Call it to start the conversation from the intial dialogue in
## [member current_conversation]. This can't be called again in the middle
## of a conversation.
func start_conversation() -> void:
	if current_conversation == null or _conversation_started:
		return
	_current_dialog = current_conversation.dialog_entry
	next_dialogue()


## Process and displays the next dialog in the conversation.
func next_dialogue() -> void: # Coroutine
	if _current_dialog.is_empty():
		if text_box.visible:
			text_box.visible = false
			text_box.close_dialog_box()
		if _conversation_started:
			_conversation_started = false
			conversation_ended.emit()
		return

	if not _conversation_started:
		_conversation_started = true
		conversation_started.emit()
	
	text_box.listening_to_input = true
	options_control.listening_to_input = false
	conversation_paused = current_conversation.pause_after_display(_current_dialog)
	
	var current_character: Dictionary = current_conversation.get_character(_current_dialog)
	
	var character_name: String = ""
	var portrait: SpriteFrames = null
	
	if Characters.character_exists(current_character["id"]):
		var character_res: CharacterDefinition = Characters.get_character_data(
				current_conversation.get_character_id(_current_dialog))
		character_name = character_res.character_name
		portrait = character_res.character_portrait
	else:
		character_name = current_character["id"]
	
	set_dialog(
			current_conversation.get_dialog_text(_current_dialog),
			character_name,
			current_conversation.get_dialog(_current_dialog)["seconds_per_letter"])
		
	set_portrait(portrait)
	
	if current_conversation.has_replies(_current_dialog):
		set_options(
			current_conversation.get_dialog_replies(_current_dialog)["options"],
			current_conversation.get_dialog_replies(_current_dialog)["cancel"]
			)
	
	var variable_data: Dictionary = current_conversation.get_variables(_current_dialog)
	
	for variable_id in variable_data:
		Variables.set_variable(
				variable_id,
				variable_data[variable_id])
	
	if current_conversation.has_method_call(_current_dialog):
		var call_args: Dictionary = current_conversation.get_method_call(_current_dialog)
		var target_node: Node = get_tree().root.get_node_or_null(call_args["node"].simplify_path())
		var args: Array = []
		
		for arg:String in call_args["args"]:
			if Strings.is_between(arg,"{","}"):
				args.append(Variables.get_variable(arg.trim_prefix("{").trim_suffix("}")))
			elif Strings.is_between(arg, "(", ")"):
				args.append(Strings.string_to_variant(arg.trim_prefix("(").trim_suffix(")")))
			else:
				args.append(arg)
		
		if target_node != null and target_node.has_method(call_args["method"]):
			var callable: Callable = Callable(target_node, call_args["method"])
			callable.callv(args)
	
	if not current_conversation.get_signal_arg(_current_dialog).is_empty():
		dialog_string_signaled.emit(current_conversation.get_signal_arg(_current_dialog))
	
	if text_box.is_textbox_typing():
		change_portrait(
			current_character["talking"]["animation"],
			current_character["talking"]["animated"])
	else:
		change_portrait(
			current_character["idle"]["animation"],
			current_character["idle"]["animated"])
		
	
	text_box.open_dialog_box()
	text_box.start_dialogue()
	
	# TEST Check if the portrait is displayed correctly or if it needs to be
	# set earlier.
	if text_box.is_textbox_typing():
		change_portrait(
			current_character["talking"]["animation"],
			current_character["talking"]["animated"])
		await text_box.text_displayed
	
	change_portrait(
			current_character["idle"]["animation"],
			current_character["idle"]["animated"])
	
	if current_conversation.has_replies(_current_dialog):
		options_control._open()
		
		text_box.listening_to_input = false
		
		if 0 < choices_delay:
			await delta_timer.delta_timer_start(choices_delay).delta_timeout
		
		options_control.listening_to_input = true
		
		var option_idx: int = await options_control.option_selected
		
		var selected_data: Dictionary = current_conversation.get_option_data(_current_dialog, option_idx)
		
		for variable in selected_data["set_variable"]:
			Variables.set_variable(variable, selected_data[variable])
		
		if current_conversation.has_option_method_call(_current_dialog, option_idx):
			var call_args: Dictionary = current_conversation.get_option_data(_current_dialog, option_idx)
			var target_node: Node = get_tree().root.get_node_or_null(call_args["node"])
			if target_node != null and target_node.has_method(call_args["method"]):
				var callable: Callable = Callable(target_node, call_args["method"])
				callable.callv(call_args["args"])
		
		if not selected_data["signal"].is_empty():
			dialog_string_signaled.emit(selected_data["signal"])
		
		option_selected.emit(option_idx)
		options_control._close()
		
		options_control.listening_to_input = false
		text_box.listening_to_input = true
		
		_next_dialog = selected_data["next"]
		_on_progress_conversation()
	else:
		_next_dialog = current_conversation.get_next_dialog(_current_dialog)


func _on_progress_conversation() -> void:
	if conversation_paused:
		return
	_current_dialog = _next_dialog
	next_dialogue()
