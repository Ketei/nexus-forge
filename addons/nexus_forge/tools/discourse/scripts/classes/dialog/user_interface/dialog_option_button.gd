class_name DialogOptionsContainer
extends Control


signal option_focus_changed(focused: int)
## Emmited when an option is selected.
signal option_selected(option_idx: int)

enum OptionTypes {
	GENERAL, ## An option with no special behaviour.
	CANCEL, ## This chouce is automatically selected when you press the cancel button
}

@export var max_options_displayed: int = 2
@export var default_option_scene: PackedScene
@export var button_size: Vector2i = Vector2i.ZERO
@export_group("Controls")
@export var next_option: StringName = &"ui_down"
@export var prev_option: StringName = &"ui_up"
@export var confirm_choice: StringName = &"ui_accept"
@export var cancel_choice: StringName = &"ui_cancel"
@export_group("Sounds")
@export var option_focus_sound: AudioStream
@export var option_select_sound: AudioStream

#var interface_node: DialogBox
var focused_choice_idx: int = -1 : set = set_focus_idx
var listening_to_input: bool = false: 
	set(listening_input):
		listening_to_input = listening_input
		set_process_unhandled_key_input(listening_input)
var _options_pointers: Array[DialogOption] = []
var _top_display: int = 0 # The option at the top of the option box
var _cancel_option: int = -1

@onready var options_margin_container: MarginContainer = $OptionsContainer/OptionsMarginContainer
@onready var options_scroll: ScrollContainer = $OptionsContainer/OptionsMarginContainer/OptionsScroll
@onready var option_button_container: VBoxContainer = $OptionsContainer/OptionsMarginContainer/OptionsScroll/OptionButtonContainer

@onready var option_pointer: TextureRect = $OptionPointer
@onready var top_arrow: TextureRect = $TopArrow
@onready var bottom_arrow: TextureRect = $BottomArrow

@onready var option_focus_player: AudioStreamPlayer = $OptionFocusPlayer
@onready var option_confirm_player: AudioStreamPlayer = $OptionConfirmPlayer


func _ready() -> void:
	#add_option("You can do it!!")
	#add_option("Let me help!")
	#add_option("[Walk away]")
	#add_option("[Put more eggs in him]")
	
	visible = false
	
	set_process_unhandled_key_input(false)
	
	option_focus_player.stream = option_focus_sound
	option_confirm_player.stream = option_select_sound
	
	#_prepare()
	
	option_focus_changed.connect(_on_option_focus_changed)
	option_selected.connect(_on_option_selected)


func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(next_option):
		focus_next_option()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed(prev_option):
		focus_previous_option()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed(cancel_choice):
		select_option(_cancel_option)
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed(confirm_choice):
		select_option()
		get_viewport().set_input_as_handled()


## Called to add an option to the scene. To add a cutom option pass it an
## INSTANCIATED scene as second argument.
func add_option(option_text: String, is_cancel := false, custom_scene: DialogOption = null) -> void:
	var assigned_id: int = _options_pointers.size()
	var new_option: DialogOption = default_option_scene.instantiate() if custom_scene == null else custom_scene
	new_option.option_id = assigned_id
	new_option.custom_minimum_size = button_size
	option_button_container.add_child(new_option)
	new_option.set_option_text(option_text)
	_options_pointers.append(new_option)
	
	if is_cancel:
		_cancel_option = assigned_id


func clear_options() -> void:
	for option in _options_pointers:
		option.visible = false
		option.queue_free()
	_options_pointers.clear()


## Called right before the options are shown.
func _prepare() -> void:
	var total_size := Vector2i(0, 0)
	total_size.y += options_margin_container.get_theme_constant(&"margin_top") + options_margin_container.get_theme_constant(&"margin_bottom")
	total_size.y += button_size.y * mini(max_options_displayed, _options_pointers.size())
	total_size.x = button_size.x + options_margin_container.get_theme_constant(&"margin_left") + options_margin_container.get_theme_constant(&"margin_right")
	custom_minimum_size = total_size
	if 0 < _options_pointers.size():
		focused_choice_idx = 0


## Called to show the options.
func _open() -> void:
	visible = true


## Called to hide the options.
func _close() -> void:
	visible = false


func set_focus_idx(new_focus: int) -> void:
	var choice_size: int = _options_pointers.size()
	var next_focus: int = clampi(
			new_focus,
			-1 if choice_size == 0 else 0,
			choice_size - 1)
	
	if next_focus != focused_choice_idx:
		
		focused_choice_idx = next_focus
		
		var valid_option: bool = 0 <= focused_choice_idx
		
		if option_pointer.visible != valid_option:
			option_pointer.visible = valid_option
		
		if valid_option:
			var new_pointer_pos: float = 0
			var choice_distance: int = 0
			
			# --- Setting the scrollbar to the correct position ---
			if focused_choice_idx < _top_display:
				choice_distance = -(Math.distancei(_top_display, focused_choice_idx))
			elif _top_display + (max_options_displayed - 1) < focused_choice_idx:
				choice_distance = Math.distancei(_top_display + max_options_displayed - 1, focused_choice_idx)
			
			if choice_distance != 0:
				_top_display += choice_distance
				options_scroll.get_v_scroll_bar().value += choice_distance * button_size.y
			# -----------------------------------------------------
			
			# --- Setting the new pointer position ---
			new_pointer_pos = floorf(get_new_pointer_position(focused_choice_idx))
			if option_pointer.position.y != new_pointer_pos:
				option_pointer.position.y = new_pointer_pos
			# ----------------------------------------
			
			option_focus_changed.emit(focused_choice_idx)
			top_arrow.visible = 0 < _top_display
			bottom_arrow.visible = (_top_display + max_options_displayed) < choice_size


func get_new_pointer_position(option_index: int) -> float:
	var new_height: float = 0.0
	new_height += options_margin_container.get_theme_constant(&"margin_top")
	new_height += ((option_index - _top_display) * button_size.y) + (button_size.y / 2.0)
	new_height -= option_pointer.size.y / 2
	return new_height


func focus_next_option() -> void:
	focused_choice_idx += 1


func focus_previous_option() -> void:
	focused_choice_idx -= 1


## Submits the focused choice or a choice if passed as an argument. If a
## negative number is passed it'll go around. -1 will select the last option.
func select_option(option_idx: int = focused_choice_idx) -> void:
	var opt_size: int = _options_pointers.size()
	
	if opt_size == 0:
		return # No option to select.
	
	var selected_opt: int = 0
	
	if option_idx == focused_choice_idx:
		selected_opt = option_idx
	else:
		selected_opt = int(fposmod(option_idx, opt_size))
	option_selected.emit(selected_opt)


func has_options() -> bool:
	return not _options_pointers.is_empty()


func _on_option_focus_changed(_focus_choce: int) -> void:
	if option_focus_sound != null and not option_focus_player.playing:
		option_focus_player.play()


func _on_option_selected(_option_selected: int) -> void:
	if option_select_sound != null and not option_confirm_player.playing:
		option_confirm_player.play()
