class_name NFDialogParser
extends RefCounted
## The parser that NexusForge will use while its running on exported projects.
##
## The resources parsed by this object are [DiscourseDialog] which
## contain a different structure from the editor files.[br]
## [br]
## [b]Note:[/b] This parser is designed to be used on release builds and can't
## process editor resources.
## [br][br]
## For the editor parser see [NFEditorDialogParser].

## Emitted when a dialog starts.
signal dialog_started
## Emitted when a dialog reaches its end.
signal dialog_finished
## Emitted when a dialog reaches a "Pause" point.
signal dialog_paused
## Emmited when a dialog event is reached.
signal dialog_reached(dialog_data: Dictionary)
## Emited when a choice event is reached.
signal choices_reached(options: Array[Dictionary])


## The different types a node can be.
enum NodeTypes {
	INVALID = -1, ## Reserved for when a type isn't of a node.
	ENTRY = 0, ## The entry for a conversation.
	DIALOG = 1, ## A generic dialog node
	CHOICES = 2, ## A collection of dialog options.
	BRANCH = 3, ## A dialog split via if/else comparison.
	CONDITION_SELECT = 4, ## An if-else statement that outputs a variable.
	COMPARATION = 5, ## A direct comparation between 2 values.
	EVENT = 6, ## Triggers a method call, a variable set or a signal emit.
	MATCH = 7, ## Compares and selects the matching, if none match, uses default.
	PAUSE = 8, ## Pauses dialog execution until told to continue
	RANDOM = 9, ## Selects a random dialog. Weights can be passed around.
	TYPE_GUARD = 10, ## Verifies outputs.
	VALUE = 11, ## Represents specific data type
	SIGNAL = 12, ## Represents a registered signal
	CALLABLE = 13, ## Represents a method that can be called
	CALLABLE_RETURN = 14, ## Represents a method that can be called
	VARIABLE_GET = 15, ## Fetches data from the Blackboard
	SHORTCUT_IN = 16, ## A pointer that directs to a SHORTCUT_OUT.
	SHORTCUT_OUT = 17, ## A node for SHORTCUT_IN to point to.
	DIALOG_END = 18, ## A visual marker that signals the end of a dialogue
	DIALOG_MERGE = 19, ## A path-joiner merging multiple branches into one.
	COMMENT = 20, ## A node that exists to explain something.
	SETTINGS_CHARACTER = 21, ## Character settings for a DIALOG node.
	SETTINGS_DIALOG = 22, ## Dialogue settings for a DIALOG node.
	SETTINGS_OPTION = 23, ## Choice settings for an entry in the CHOICES node.
	RANDOM_VALUE = 24, ## Generates a random value of different types.
	RESOURCE = 25, ## Provides the path to a resource.
	DATA_EVENT = 26, ## An event that can set a variable, call a method or emit a signal.
	LOCALIZED_TEXT = 27, ## Text that changes based on the locale.
	METADATA = 28, ## A node representing entries in a dictionary to be passed as metadata.
	TRAVEL_TO = 29, ## A pointer to a TRAVEL_TARGET.
	TRAVEL_TARGET = 30, ## A waypoint for TRAVEL_TO nodes to jump to.
	TRAVEL_BACK = 31, ## A signaler to go to the next node after the last TRAVEL_TO node reached.
	}

const _NODE_PROCESS_MAX_TRAVEL: int = 1000
## The default weigth that the random path node uses.
const RANDOM_DEFAULT_WEIGHT: int = 1
## THe snapping decimal point for random values
const FLOAT_SNAP: float = 0.01

## An instance of the [DiscourseAPI] to which method calls and signals
## will draw from.
var API: DiscourseAPI = null
## The current locale of the parser
var locale: String = "en":
	set(new_locale):
		var new_standard: String = NFStringUtils.sanitize_locale(new_locale)
		if new_standard.is_empty() or locale == new_standard:
			return
		
		locale = new_standard
		if _dialog_resource == null:
			return
		
		if _id_to_data.has(_resource_id) and not _dialog_resource._has_locale(locale):
			_load_locale_into(_dialog_resource, locale)
		_dialog_resource._set_locale(locale)

## How many "steps" are kept track of for the travel_back node to
## go back to.[br]
## Setting this to [code]-1[/code] makes it unlimited.
var max_dialog_travel_stack: int = 100:
	set(s):
		max_dialog_travel_stack = maxi(-1, s)

var _dialog_resource: DiscourseDialog = null:
	set(new_res):
		_dialog_resource = new_res
		_dialog_resource_set()

var _resource_id: StringName = &""
var _conversation_started: bool = false
var _next_uuid: StringName = &""
var _current_uuid: StringName = &""
var _conversation_cache: NFLRUResourceCache = null
var _parser_regex: RegEx = RegEx.new()
var _node_travel_stack: Array[StringName] = []

var _path_to_id: Dictionary[String, StringName] = {}
# {"dialogs.village.mayor": {"data_path": "res://asdas", "locale_file": "---.json"}
var _id_to_data: Dictionary[StringName, Dictionary] = {}

var _logic_overrides: Dictionary[String, String] = {}
var _locale_overrides: Dictionary[String, Dictionary] = {
	#"dialog_id": {"locale_code": "new_path"}
	}
var _dialog_edits: Dictionary[String, DiscourseDialog.NFDialogEntryOverride] = {
	#"dialogs.village.greet": {
		#"en": {
			#"NodeID": "Hello there!"
		#}
	#}
}
var _phrase_overrides: Dictionary[String, DiscourseDialog.NFPhraseEntryOverride] = {}


func _init() -> void:
	_conversation_cache = NFLRUResourceCache.new()
	API = DiscourseAPI.new()
	_parser_regex.compile("\\{(\\![a-zA-Z\\_][a-zA-Z0-9\\_]*(?:\\|[^\\}]+)?|(?:[\\?\\&\\$][^\\}]+))\\}")


# Reads the exported JSON map from the .pck to build relationships between 
# file paths, dialog IDs, and localization files. 
#
# Note: This relies on a file generated ONLY during project export. It is 
# called automatically by NexusForge on it's parser. Can't be used on editor
# builds as files don't exist.
func _generate_locale_map() -> void:
	var file: FileAccess = FileAccess.open(
			NFStringUtils.make_path([
				ProjectSettings.get_setting(
					NFPluginGameHandler.get_setting_path("discourse"),
					"res://localization/"),
				"dialog_locale_map.json"]),
			FileAccess.READ)
	
	if file == null:
		return
	
	var data = JSON.parse_string(file.get_as_text())
	
	if typeof(data) != TYPE_DICTIONARY or not data.has_all(["file_to_id", "id_to_locale_file"]):
		return
	
	if not typeof(data["file_to_id"]) == TYPE_DICTIONARY or not typeof(data["id_to_locale_file"]) == TYPE_DICTIONARY:
		return
	
	var file_to_id: Dictionary = data["file_to_id"]
	var id_to_locale_file: Dictionary = data["id_to_locale_file"]
	
	for file_path in file_to_id:
		if typeof(file_path) != TYPE_STRING:
			continue
		
		var clean_file_path: String = file_path.strip_edges().simplify_path()
		
		var pos_file_id: Variant = file_to_id[file_path]
		if typeof(pos_file_id) != TYPE_STRING or not id_to_locale_file.has(pos_file_id):
			continue
		
		var pos_id_to_locale: Variant = id_to_locale_file[pos_file_id]
		if typeof(pos_id_to_locale) != TYPE_STRING:
			continue
		
		var file_id: String = pos_file_id
		var localization_file: String = pos_id_to_locale.strip_edges()
		
		_path_to_id[clean_file_path] = file_id
		_id_to_data[file_id] = {"data_path": clean_file_path, "locale_file": localization_file}


# Function to parse the dialog in a custom manner. Modify if needed.
func _parse_dialog(dialog_id: String, dialog_text: String, is_override: bool) -> String:
	if not ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path(
					"use_discourse_parser"),
					true):
		return dialog_text
	
	var DUUID: String = ""
	var p_override: DiscourseDialog.NFPhraseEntryOverride = _phrase_overrides.get(_resource_id)
	
	if p_override != null and p_override.has_override(_resource_id):
		is_override = true
	
	if is_override:
		DUUID = dialog_id + "/" + locale + "/override"
	else:
		DUUID = dialog_id + "/" + locale
	
	# (NFUUID)/en_US
	if _dialog_resource.parsed_dialog_cache.is_in_cache(DUUID):
		var cached_data: NFParsedDialog = _dialog_resource.parsed_dialog_cache.get_cache(DUUID)
		if cached_data.dialog == dialog_text:
			return cached_data.get_dialog()
	
	var parsed: NFParsedDialog = NFParsedDialog.new()
	parsed.dialog = dialog_text
	parsed.locale = locale
	
	var functions_processed: Dictionary[String, Variant] = {}
	var variables_processed: Dictionary[String, Variant] = {}
	var phrases_processed: Dictionary[String, Variant] = {}
	var random_processed: Dictionary[String,Variant] = {}
	
	for rgx_result in _parser_regex.search_all(dialog_text):
		var slice: String = rgx_result.get_string(1)
		var token: String = slice[0]
		
		if token == "?":
			if random_processed.has(rgx_result.get_string()):
				continue
			
			random_processed[rgx_result.get_string()] = null
			var options: Array[String] = []
			options.assign(slice.substr(1).split("|", false))
			
			parsed.set_format_callable(
					slice,
					options.pick_random)
		
		elif token == "!":
			if functions_processed.has(rgx_result.get_string()):
				continue
			functions_processed[rgx_result.get_string()] = null
			
			parsed.set_format_callable(
					rgx_result.get_string(1),
					_build_callable_for_method(slice.substr(1)))
		
		elif token == "$":
			if variables_processed.has(rgx_result.get_string()):
				continue
			variables_processed[rgx_result.get_string()] = null
			
			parsed.set_format_callable(
				rgx_result.get_string(1),
				_build_callable_for_variable(slice.substr(1)))
		
		elif token == "&":
			if phrases_processed.has(rgx_result.get_string()):
				continue
			var phrase_key: String = slice.substr(1)
			var resource_id: StringName = _resource_id
			phrases_processed[rgx_result.get_string()] = null
			
			var phrase: String = _dialog_resource._get_format_string(
					resource_id,
					phrase_key)
			
			var argument_cases: Dictionary[String, Dictionary] = _dialog_resource._get_format_string_args(
					resource_id,
					phrase_key)
			
			parsed.create_format_phrase(slice, phrase, argument_cases)
			
			for phrase_match in _parser_regex.search_all(phrase):
				var phrase_item: String = phrase_match.get_string(1)
				var phrase_token: String = phrase_item[0]
				
				if phrase_token == "?":
					var items: Array[String] = []
					items.assign(phrase_item.substr(1).split("|", false))
					parsed.set_format_phrase_callable(
							slice,
							phrase_item,
							items.pick_random)
				
				elif phrase_token == "!":
					parsed.set_format_phrase_callable(
							slice,
							phrase_item,
							_build_callable_for_method(phrase_item.substr(1)))
				
				elif phrase_token == "$":
					parsed.set_format_phrase_callable(
							slice,
							phrase_item,
							_build_callable_for_variable(phrase_item.substr(1)))
	
	_dialog_resource.parsed_dialog_cache.cache_data(
		DUUID,
		parsed)
	
	return parsed.get_dialog()


func _build_callable_for_variable(text: String) -> Callable:
	var clean_text: String = text.trim_prefix("$")
	var callable: Callable = Callable(
			NexusForge.Blackboard.get_variable.bind(
					clean_text, "[VARIABLE '%s' NOT FOUND]" % clean_text))
	
	return callable


func _build_callable_for_method(text: String) -> Callable:
	var parts: PackedStringArray = text.split("|", false, 1)
	var method: StringName = StringName(parts[0].trim_prefix("!"))
	var valid_method: bool = API.has_method(method)
	
	if not valid_method:
		var msg: String = "Attempted to use a non-existent API method '%s' on a dialogue." % method
		if OS.is_debug_build():
			assert(false, msg)
		else:
			NFPluginGameHandler._log_msg(
					"discourse",
					msg,
					NFPluginGameHandler._LogLevel.ERROR)
		
		return _string_return_method.bind("[METHOD '%s' NOT FOUND]" % method)
	
	var arguments: PackedStringArray = []
	if 1 < parts.size():
		arguments = parts[1].split(",")
	
	var final_arguments: Array = []
	
	for argument in arguments:
		if argument.begins_with("$"):
			final_arguments.append(_build_callable_for_variable(argument.trim_prefix("$")))
		elif argument.begins_with("!"):
			final_arguments.append(_build_callable_for_method(argument.trim_prefix("!")))
		else:
			final_arguments.append(argument)
	
	var callable: Callable = Callable(API, method)
	
	if not final_arguments.is_empty():
		return _build_lazy_wrapper.bind(callable, final_arguments)
	
	return callable


func _build_lazy_wrapper(target_method: Callable, args: Array) -> Variant:
	var resolved_args: Array = []
	for arg in args:
		if arg is Callable:
			resolved_args.append(arg.call())
		else:
			resolved_args.append(arg)
	return target_method.callv(resolved_args)


func _string_return_method(msg: String) -> String:
	return msg


func _can_compare(a, b, operator: int) -> bool:
	var type_a: int = typeof(a)
	var type_b: int = typeof(b)
	
	if type_a == type_b:
		match operator:
			OP_LESS, OP_LESS_EQUAL, OP_GREATER, OP_GREATER_EQUAL:
				match type_a:
					TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, \
					TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I,\
					TYPE_VECTOR4, TYPE_VECTOR4I, TYPE_RID:
						return true
					_:
						NFPluginGameHandler._log_msg(
								"discourse",
								"Invalid comparison: Cannot use <, >, <=, or >= operators on type %s." % type_string(type_a),
								NFPluginGameHandler._LogLevel.WARNING)
						return false
		
		return type_a != TYPE_NIL
	
	match type_a:
		TYPE_INT, TYPE_FLOAT:
			return type_b == TYPE_INT or type_b == TYPE_FLOAT
		TYPE_STRING, TYPE_STRING_NAME:
			return type_b == TYPE_STRING or type_b == TYPE_STRING_NAME
		_:
			return false

#region Override
# Returns a dictionary with the "current" dialog it emmited and the
# "next" uuid for processing
func _process_logic(node_id: StringName) -> Dictionary[String, Variant]:
	const T: String = "target_node_uuid"
	const I: String = "input_connections"
	const O: String = "output_connections"
	
	var target: Dictionary[String, Variant] = {"current": &"", "next": &"", "type": -1, "data": {}}
	if node_id.is_empty():
		return target
	
	var E: Dictionary = NFDictUtils.EMPTY_DICT
	
	var dialog_id: String = _resource_id
	var process_next: StringName = node_id
	var node_data: Dictionary = _dialog_resource.node_logic.get(node_id, E)
	var remaining_travels: int = _NODE_PROCESS_MAX_TRAVEL
	
	while not node_data.is_empty() and 0 < remaining_travels:
		var current_node: StringName = process_next
		
		match node_data.get("node_type", NodeTypes.INVALID):
			NodeTypes.ENTRY:
				process_next = node_data.get("next_node", &"")
			NodeTypes.DIALOG:
				var settings: Dictionary = node_data.get("dialog_settings", E)
				var char_settings: Dictionary = node_data.get("character_settings", E)
				var dialog_metadata: Dictionary = settings.get("metadata", E)
				
				var disp_name_node: StringName = char_settings.get("display_name", &"")
				var port_node: StringName = char_settings.get("portrait_id", &"")
				var font_node: StringName = settings.get("font_resource", &"")
				var scene_node: StringName = settings.get("dialog_scene", &"")
				var speed_node: StringName = settings.get("dialog_speed", &"")
				var text_source_node: StringName = node_data.get("text_source", &"")
				
				var character_id: StringName = node_data.get("character_id", &"")
				var persist_dialogue: bool = node_data.get("persist", false)
				var font: String = ""
				var scene: String = ""
				var speed: float = 0.0
				var display_name: String = ""
				var portrait_id: String = ""
				var dialogue_metadata: Dictionary[String, Variant] = {}
				
				var next_node: StringName = node_data.get("next_node", &"")
				
				if not font_node.is_empty():
					font = _get_data_string(font_node, font)
				if not scene_node.is_empty():
					scene = _get_data_string(scene_node, scene)
				if not speed_node.is_empty():
					var speed_data: Variant = _get_data(speed_node, speed)
					var sp_type: int = typeof(speed_data)
					if sp_type == TYPE_INT or sp_type == TYPE_FLOAT:
						speed = speed_data
				if not disp_name_node.is_empty():
					display_name = _get_data_string(disp_name_node, display_name)
				if not port_node.is_empty():
					portrait_id = _get_data_string(port_node, portrait_id)
				
				target["type"] = NodeTypes.DIALOG
				
				for meta_key in dialog_metadata:
					dialogue_metadata[meta_key] = _get_data(dialog_metadata[meta_key])
				
				if text_source_node.is_empty():
					var text_data: Dictionary[String, Variant] = _dialog_resource._get_text_data(dialog_id, current_node)
					target["data"] = {
						"dialog_text": _parse_dialog(
								String(current_node),
								text_data["text"],
								text_data["is_override"]),
						"character_id": character_id,
						"persist": persist_dialogue,
						"font": font,
						"scene": scene,
						"speed": speed,
						"display_name": display_name,
						"portrait_id": portrait_id,
						"metadata": dialogue_metadata}
				else:
					var data_source = _get_data(text_source_node, "")
					var text: String = ""
					var is_override: bool = false
					var source_type: int = typeof(data_source)
					
					if source_type == TYPE_STRING:
						text = data_source
					elif source_type == TYPE_DICTIONARY:
						text = data_source.get("text", "")
						is_override = data_source.get("is_override", false)
					else:
						text = "[ERROR GETTING DATA FROM '%s']" % text_source_node
					
					target["data"] ={
						"dialog_text": _parse_dialog(
								String(current_node),
								text,
								is_override),
						"character_id": character_id,
						"persist": persist_dialogue,
						"font": font,
						"scene": scene,
						"speed": speed,
						"display_name": display_name,
						"portrait_id": portrait_id,
						"metadata": dialogue_metadata}
				
				target["current"] = current_node
				target["next"] = next_node
				return target
			NodeTypes.CHOICES:
				var base_choices: Array = node_data.get("choices", NFArrayUtils.EMPTY)
				
				var available_options: Array[Dictionary] = []
				var target_size: int = base_choices.size()
				var is_overridden: bool = _dialog_resource._dialog_overrides != null\
						and _dialog_resource._dialog_overrides.has_override(current_node, locale, TYPE_ARRAY)
				
				var localized_options: PackedStringArray = _dialog_resource._get_choices(dialog_id, current_node)
				
				var current_size: int = localized_options.size()
				target["type"] = NodeTypes.CHOICES
				
				var err_msg: String = "[MISSING LOCALIZATION DATA]"
				
				if current_size < target_size:
					for _step in range(target_size - current_size):
						localized_options.append(err_msg)
				elif target_size < current_size:
					localized_options.resize(target_size)
				
				for i in range(target_size):
					if localized_options[i].strip_edges().is_empty():
						localized_options[i] = err_msg
				
				var idx: int = -1
				var option_duuid: String = ""
				for option:Dictionary in base_choices:
					var choice_target: StringName = option.get("next_node", &"")
					var option_settings: Dictionary = option.get("settings", E)
					
					idx += 1
					option_duuid = String(current_node) + "_" + str(idx)
					
					if option_settings.is_empty():
						option_duuid += "_unlocked"
						available_options.append(
							{
								"unlocked": true,
								"text": _parse_dialog(option_duuid, localized_options[idx], is_overridden),
								"target": choice_target,
								"metadata": NFDictUtils.create_typed(TYPE_STRING, TYPE_NIL)})
					else:
						var settings_node: StringName = option_settings.get("available", &"")
						var show: bool = _to_bool(
								_get_data(settings_node, true),
								true)
					
						if not show:
							continue
						
						var meta_data: Dictionary = option_settings.get("metadata", E)
						
						var unlocked_node: StringName = option_settings.get("unlocked", &"")
						var unlocked: bool = _to_bool(
								_get_data(unlocked_node, true),
								true)
						var text: String = localized_options[idx]
						var choice_metadata: Dictionary[String, Variant] = {}
						
						for meta_key in meta_data:
							var meta_node: StringName = meta_data[meta_key]
							if meta_node.is_empty():
								choice_metadata[meta_key] = null
							else:
								choice_metadata[meta_key] = _get_data(meta_node)
						
						if not unlocked:
							var lock_node: StringName = option_settings.get("lock_hint", &"")
							if not lock_node.is_empty():
								var lock_hint: String = _get_data_string(lock_node)
								if not lock_hint.is_empty():
									text = lock_hint
						
						if unlocked:
							option_duuid += "_unlocked"
						else:
							option_duuid += "_locked"
						
						var option_text: String = _parse_dialog(option_duuid, text, is_overridden)
						
						available_options.append({
							"unlocked": unlocked,
							"text": option_text,
							"target": choice_target,
							"metadata": choice_metadata})
				
				target["data"] = available_options
				target["current"] = current_node
				target["next"] = current_node
				
				return target
			NodeTypes.BRANCH:
				var val_node: StringName = node_data.get("result", &"")
				var branch_val: Variant = true
				if not val_node.is_empty():
					branch_val = _get_data(val_node, branch_val)
				
				var use_a: bool = _to_bool(branch_val, true)
				var next_target: StringName = &""
				
				if use_a:
					next_target = node_data.get("case_true", &"")
				else:
					next_target = node_data.get("case_false", &"")
				
				process_next = next_target
			NodeTypes.EVENT:
				var path: String = node_data.get("variable_path", "")
				var val: StringName = node_data.get("value", &"")
				var call_node: StringName = node_data.get("callable", &"")
				var sign_node: StringName = node_data.get("signal", &"")
				
				if not path.is_empty() and not val.is_empty():
					NexusForge.Blackboard.set_variable(
							path,
							_get_data(val))
				
				if not call_node.is_empty():
					var call_data: Dictionary = _dialog_resource.node_logic.get(call_node, E)
					var call_method: StringName = call_data.get("method", &"")
					
					if API.has_method(call_method):
						var call_args: Array = []
						
						for argument_key in call_data.get("arguments", NFArrayUtils.EMPTY):
							if argument_key.is_empty():
								continue
							var data: Variant = _get_data(argument_key)
							call_args.append(data)
						
						API.callv(
								call_method,
								call_args)
				
				if not sign_node.is_empty():
					var signal_data: Dictionary = _dialog_resource.node_logic.get(sign_node, E)
					var signal_str: StringName = signal_data.get("signal", &"")
					
					if API.has_signal(signal_str):
						var signal_args: Array = []
						var api_signal: Signal = Signal(
								API,
								signal_data["signal"])
						
						for argument_key in signal_data.get("arguments", NFArrayUtils.EMPTY):
							if argument_key.is_empty():
								continue
							var arg_data: Variant = _get_data(argument_key)
							signal_args.append(arg_data)
						
						api_signal.emit.callv(signal_args)
				
				process_next = node_data.get("next_node", &"")
			NodeTypes.MATCH:
				var match_node: StringName = node_data.get("match_value", &"")
				var match_result: StringName = node_data.get("case_default", &"")
				
				if not match_node.is_empty():
					var match_data: Variant = _get_data(match_node)
					for case:Dictionary in node_data.get("cases", NFArrayUtils.EMPTY):
						if case.get("value") == match_data:
							match_result = case.get("next_node", &"")
							break
				
				process_next = match_result
			NodeTypes.PAUSE:
				target["type"] = NodeTypes.PAUSE
				target["current"] = current_node
				target["next"] = node_data.get("next_node", &"")
				return target
			NodeTypes.RANDOM:
				var total_weight: int = 0
				var choices: Array[Dictionary] = []
				var default_weight: int = NFDialogParser.RANDOM_DEFAULT_WEIGHT
				
				var weigth_override_node: StringName = node_data.get("weight_override", &"")
				if not weigth_override_node.is_empty():
					default_weight = _get_data(weigth_override_node, default_weight)
				
				for choice:Dictionary in node_data.get("choices", NFArrayUtils.EMPTY):
					var choice_w_override: StringName = choice.get("weight_override", &"")
					var weight: int = default_weight
					if not choice_w_override.is_empty():
						weight = _get_data(choice_w_override, weight)
					if weight <= 0:
						continue
					choices.append({
						"next": choice.get("target", &""),
						"weight": weight})
					total_weight += weight
				
				if choices.is_empty():
					return target
				
				choices.sort_custom(func(a, b): return a["weight"] > b["weight"])
				var random_select: int = randi_range(1, total_weight)
				
				var choice_selected: bool = false
				var current_weight: int = 0
				var target_node: StringName = &""
				for choice in choices:
					current_weight += choice["weight"]
					if random_select <= current_weight:
						target_node = choice["next"]
						choice_selected = true
						break
				
				if not choice_selected:
					target_node = choices[-1]["next"]
				
				process_next = target_node
			NodeTypes.DIALOG_END:
				target["current"] = current_node
				target["type"] = NodeTypes.DIALOG_END
				return target
			NodeTypes.TRAVEL_TO:
				if -1 < max_dialog_travel_stack and max_dialog_travel_stack <= _get_target_travel_stack_size():
					NFPluginGameHandler._log_msg(
						"discourse",
						"Travel stack overflow! Max depth of %d reached." % max_dialog_travel_stack,
						NFPluginGameHandler._LogLevel.ERROR)
					return target # Empty, so it should stop the dialog
				var next_node: StringName = node_data.get("next_node", &"")
				_add_target_to_travel_stack(next_node)
				process_next = node_data.get("travel_target", &"")
			NodeTypes.TRAVEL_TARGET:
				process_next = node_data.get("next_node", &"")
			NodeTypes.TRAVEL_BACK:
				if _node_travel_stack.is_empty():
					return target
				process_next = _pop_last_travel_node_stack()
			_:
				return target
		
		node_data = _dialog_resource.node_logic.get(process_next, E)
		if node_data.is_empty():
			return target
		
		remaining_travels -= 1
	# --- while loop end ---
	
	if remaining_travels <= 0:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Exceeded maximum node travel stack at node '%s'. Stopping process." % process_next,
				NFPluginGameHandler._LogLevel.ERROR)
	
	return target


func _get_data(node_id: StringName, fallback = null, _remaining_travels: int = 250) -> Variant:
	if _dialog_resource == null or _remaining_travels <= 0 or not _dialog_resource.node_logic.has(node_id):
		return fallback
	var E: Dictionary = NFDictUtils.EMPTY_DICT
	var data: Dictionary = _dialog_resource.node_logic.get(node_id, E)
	
	match data.get("node_type", NodeTypes.INVALID):
		NodeTypes.VALUE:
			return data.get("value", fallback)
		NodeTypes.RANDOM_VALUE:
			match data["random_type"]:
				TYPE_INT:
					var min_value: int = data.get("min_value", 0)
					var max_value: int = data.get("max_value", 100)
					
					var min_override: StringName = data.get("min_override", &"")
					var max_override: StringName = data.get("max_override", &"")
					
					if not min_override.is_empty():
						var override_val: Variant = _get_data(min_override, min_value, _remaining_travels - 1)
						var override_type: int = typeof(override_val)
						if override_type == TYPE_INT or override_type == TYPE_FLOAT:
							min_value = override_val
					if not max_override.is_empty():
						var override_val: Variant = _get_data(max_override, max_value, _remaining_travels - 1)
						var override_type: int = typeof(override_val)
						if override_type == TYPE_INT or override_type == TYPE_FLOAT:
							max_value = override_val
					
					if max_value < min_value:
						max_value = min_value
					
					return randi_range(min_value, max_value)
				TYPE_FLOAT:
					var min_value: float = data.get("min_value", 0.0)
					var max_value: float = data.get("max_value", 100.0)
					
					var min_override: StringName = data.get("min_override", &"")
					var max_override: StringName = data.get("max_override", &"")
					
					if not min_override.is_empty():
						var override_val: Variant = _get_data(min_override, min_value, _remaining_travels - 1)
						var override_type: int = typeof(override_val)
						if override_type == TYPE_INT or override_type == TYPE_FLOAT:
							min_value = override_val
					if not max_override.is_empty():
						var override_val: Variant = _get_data(max_override, max_value, _remaining_travels - 1)
						var override_type: int = typeof(override_val)
						if override_type == TYPE_INT or override_type == TYPE_FLOAT:
							max_value = override_val
					
					if max_value < min_value:
						max_value = min_value
					
					return snappedf(
							randf_range(
									min_value,
									max_value),
							FLOAT_SNAP)
				TYPE_BOOL:
					var true_probability: int = data.get("min_value", 50)
					var min_override: StringName = data.get("min_override", &"")
					
					if not min_override.is_empty():
						var override_val: Variant = _get_data(min_override, true_probability, _remaining_travels - 1)
						var override_type: int = typeof(override_val)
						if override_type == TYPE_INT or override_type == TYPE_FLOAT:
							true_probability = override_val
					
					if true_probability <= 0:
						return false
					elif 100 <= true_probability:
						return true
					else:
						var true_range: int = randi_range(1, 100)
						return true_range <= true_probability
				_:
					return fallback
		NodeTypes.TYPE_GUARD:
			var data_node: StringName = data.get("value", &"")
			
			if data_node.is_empty():
				return fallback
			
			var origin_data: Variant = _get_data(data_node, null, _remaining_travels - 1)
			var guard_data: Variant = data.get("fallback")
			
			if typeof(origin_data) == typeof(guard_data):
				return origin_data
			else:
				return guard_data
		NodeTypes.VARIABLE_GET:
			var path: String = data.get("path", "").strip_edges().simplify_path()
			if path.is_empty():
				return fallback
			return NexusForge.Blackboard.get_variable(path, fallback)
		NodeTypes.CALLABLE_RETURN:
			var method_str: StringName = data.get("method", &"")
			if not API.has_method(method_str):
				return fallback
			
			var args: Array = []
			for arg:StringName in data.get("arguments", NFArrayUtils.EMPTY):
				if arg.is_empty():
					continue
				
				var arg_data: Variant = _get_data(arg, null, _remaining_travels - 1)
				args.append(arg_data)
			
			return API.callv(method_str, args)
		NodeTypes.DATA_EVENT:
			var var_path: String = data.get("variable_path", "").strip_edges().simplify_path()
			var val_node: StringName = data.get("value", &"")
			var call_node: StringName = data.get("callable", &"")
			var sign_node: StringName = data.get("signal", &"")
			
			var data_source: StringName = data.get("data_source", &"")
			
			if not var_path.is_empty() and not val_node.is_empty():
				NexusForge.Blackboard.set_variable(
						var_path,
						_get_data(val_node, null, _remaining_travels - 1))
			
			if not call_node.is_empty():
				var call_data: Dictionary = _dialog_resource.node_logic.get(call_node, E)
				var method_str: StringName = call_data.get("method", &"")
				
				if API.has_method(method_str):
					var call_args: Array = []
					for argument_id in call_data.get("arguments", NFArrayUtils.EMPTY):
						if argument_id.is_empty():
							continue
						var arg_data: Variant = _get_data(argument_id, null, _remaining_travels - 1)
						call_args.append(arg_data)
					
					API.callv(
							call_data["method"],
							call_args)
			
			if not sign_node.is_empty():
				var signal_data: Dictionary = _dialog_resource.node_logic.get(sign_node, E)
				var signal_str: StringName = signal_data.get("signal", &"")
				var signal_args: Array = []
				
				for argument_key in signal_data.get("arguments", NFArrayUtils.EMPTY):
					if argument_key.is_empty():
						continue
					var arg_data: Variant = _get_data(argument_key, null, _remaining_travels - 1)
					signal_args.append(arg_data)
				
				var sign_call: Signal = Signal(
						API,
						signal_str)
				
				sign_call.emit.callv(signal_args)
			
			if data_source.is_empty():
				return fallback
			else:
				return _get_data(data_source, fallback, _remaining_travels - 1)
		NodeTypes.LOCALIZED_TEXT:
			return _dialog_resource._get_text_data(
					_resource_id,
					node_id)
		NodeTypes.COMPARATION:
			var operator: int = data.get("operator", OP_EQUAL)
			var a_node: StringName = data.get("value_a", &"")
			var b_node: StringName = data.get("value_b", &"")
			
			var a: Variant = _get_data(a_node, null, _remaining_travels - 1)
			var b: Variant = _get_data(b_node, null, _remaining_travels - 1)
			
			if not _can_compare(a, b, operator):
				return operator == OP_NOT_EQUAL
			
			match operator:
				OP_EQUAL:
					return a == b
				OP_NOT_EQUAL:
					return a != b
				OP_LESS:
					return a < b
				OP_LESS_EQUAL:
					return a <= b
				OP_GREATER:
					return a > b
				OP_GREATER_EQUAL:
					return a >= b
				_:
					return operator == OP_NOT_EQUAL
		NodeTypes.CONDITION_SELECT:
			var data_source: StringName = data.get("result", &"")
			
			if data_source.is_empty():
				return fallback
			
			var branch_data: Variant = _get_data(data_source, false, _remaining_travels - 1)
			var condition: bool = _to_bool(branch_data)
			if condition:
				var node_true: StringName = data.get("true_value", &"")
				return _get_data(node_true, fallback, _remaining_travels - 1)
			else:
				var node_false: StringName = data.get("false_value", &"")
				return _get_data(node_false, fallback, _remaining_travels - 1)
		NodeTypes.RESOURCE:
			return data.get("resource_path", "")
		_:
			return fallback


func _get_data_string(node_id: StringName, fallback: String = "") -> String:
	var data: Variant = _get_data(node_id, fallback)
	var type: int = typeof(data)
	if type == TYPE_STRING:
		return data
	elif type == TYPE_DICTIONARY: # Accounting for localization text
		if data.has("text"):
			var dict_data: Variant = data["text"]
			if typeof(dict_data) == TYPE_STRING:
				return dict_data
	return fallback


func _load_locale_into(dialog: DiscourseDialog, locale_code: String, force_reload: bool = false, target_id: String = "") -> void:
	if dialog == null or locale_code.is_empty() or (dialog._has_locale(locale_code) and not force_reload):
		return
	
	var dialog_id: String = _resource_id if target_id.is_empty() else target_id
	if dialog_id.is_empty():
		return
	
	var e: Dictionary = NFDictUtils.EMPTY_DICT
	var base_path: String = _get_base_locale_path(dialog_id, locale_code)
	var file_path: String = _locale_overrides.get(dialog_id, e).get(locale_code, base_path)
	
	# 0 = No Fallback
	# 1 = Direct Fallback: Merge fallback_object with loaded objects
	# 2 = Cascade fallback
	var fallback_mode: int = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse_fallback_mode"),
			2)
	var lang_fallback: String = ProjectSettings.get_setting(
			"internationalization/locale/fallback")
	
	if fallback_mode == 0 or (0 < fallback_mode and locale_code == lang_fallback):
		var lang_data: DiscourseDialogLocale = _get_dialog_locale(
				dialog_id,
				locale_code)
		if lang_data != null:
			lang_data.invalidate_empty_strings()
			dialog._store_locale(locale_code, lang_data)
		return
	
	var locale_data: DiscourseDialogLocale = _get_dialog_locale(dialog_id, locale_code)
	var direct_fallback: DiscourseDialogLocale = null
	
	if dialog._has_locale(lang_fallback):
		direct_fallback = dialog._get_locale(lang_fallback)
	else:
		direct_fallback = _get_dialog_locale(
			dialog_id,
			lang_fallback)
	
	if fallback_mode == 2 and locale_code.contains("_"):
		var cascade_code: String = locale_code.get_slice("_", 0)
		if cascade_code != lang_fallback:
			var cascade_locale: DiscourseDialogLocale = _get_dialog_locale(
					dialog_id,
					cascade_code)
			if cascade_locale != null:
				if locale_data == null:
					locale_data = cascade_locale.duplicate(true)
					locale_data.json_file = file_path
					locale_data.locale = locale_code
					
				else:
					locale_data.merge_dialog(cascade_locale)
	
	if direct_fallback != null:
		if locale_data == null:
			locale_data = direct_fallback.duplicate(true)
			locale_data.json_file = file_path
			locale_data.locale = locale_code
		else:
			locale_data.merge_dialog(direct_fallback)
	
	
	if locale_data != null:
		locale_data.invalidate_empty_strings()
		dialog._store_locale(locale_code, locale_data)


func _get_dialog_locale(dialog_id: String, lang_code: String) -> DiscourseDialogLocale:
	var dialog_id_override: Variant = _locale_overrides.get(dialog_id, {}).get(lang_code)
	if typeof(dialog_id_override) == TYPE_STRING:
		var modded_path: String = dialog_id_override
		if FileAccess.file_exists(modded_path):
			var locale_data: DiscourseDialogLocale = DiscourseDialogLocale.new_from_json(FileAccess.get_file_as_string(modded_path))
			if locale_data != null:
				locale_data.json_file = modded_path
				locale_data.locale = lang_code
			return locale_data
	
	if not _id_to_data.has(dialog_id):
		return null
	
	var file_path: String = ProjectSettings.get_setting(
		NFPluginGameHandler.get_setting_path("discourse"),
			"res://localization/")
	var filename: String = _id_to_data[dialog_id]["locale_file"]
	var hash_slice: String = filename.substr(0, 2)
	var locale_path: String = NFStringUtils.make_path(
		[file_path, lang_code, hash_slice, filename])
	
	if FileAccess.file_exists(locale_path):
		var locale_data: DiscourseDialogLocale = DiscourseDialogLocale.new_from_json(
				FileAccess.get_file_as_string(locale_path))
		if locale_data != null:
			locale_data.locale = lang_code
			locale_data.json_file = locale_path
		return locale_data
	else:
		return null


func _dialog_resource_set() -> void:
	if _dialog_resource == null:
		return
	
	if _id_to_data.has(_resource_id) and not _dialog_resource._has_locale(locale):
		_load_locale_into(_dialog_resource, locale)
	
	_dialog_resource._set_locale(locale)

#endregion


## Returns [code]true[/code] if a conversation is loaded and active.
func is_dialog_active() -> bool:
	return _dialog_resource != null and _conversation_started


## Loads a dialog and sets the dialog ID to the start of the conversation
## unless a valid [param starting_id] is given.[br]
## Returns [code]true[/code] if the dialog was loaded.
func load_dialog(path: String, starting_id: StringName = &"") -> bool:
	path = path.simplify_path()
	_clear_target_travel_stack()
	
	var target_path: String = _logic_overrides.get(path, path)
	
	if _conversation_cache.is_in_cache(target_path):
		var dialog_id: StringName = _path_to_id.get(path, &"")
		var data: DiscourseDialog = _conversation_cache.get_resource(target_path)
		var locale_data: DiscourseDialogLocale = data._get_locale(locale)
		
		var base_path: String = _get_base_locale_path(dialog_id, locale)
		var eff_path: String = _locale_overrides.get(dialog_id, NFDictUtils.EMPTY_DICT).get(locale, base_path)
		
		var current_json: String = locale_data.json_file if locale_data != null else ""
		var reload_locale: bool = false
		
		if eff_path != current_json or eff_path.is_empty():
			# Cache miss. Must check disk.
			var eff_exists: bool = not eff_path.is_empty() and FileAccess.file_exists(eff_path)
			
			if not eff_exists and eff_path != base_path:
				# Override file missing. Gracefully revert to base_path.
				eff_path = base_path
				
				# FALLBACK OPTIMIZATION: Base file is already in memory. Zero disk I/O.
				eff_exists = true
				if eff_path != current_json or eff_path.is_empty():
					eff_exists = not eff_path.is_empty() and FileAccess.file_exists(eff_path)
					
			# Only reload if a valid file exists AND it differs from what is in memory
			reload_locale = eff_exists and (current_json != eff_path)
		
		_resource_id = dialog_id
		_dialog_resource = data
		
		var d_o: RefCounted = _dialog_edits.get(dialog_id)
		var p_o: RefCounted = _phrase_overrides.get(dialog_id)
		
		if _dialog_resource._dialog_overrides != d_o:
			_dialog_resource._dialog_overrides = d_o
		if _dialog_resource._phrase_overrides != p_o:
			_dialog_resource._phrase_overrides = p_o
		
		if reload_locale and _id_to_data.has(dialog_id):
			_load_locale_into(_dialog_resource, locale, true)
	else:
		var res: Variant = load(target_path)
		var id: String = _path_to_id.get(path, "")
		
		if res == null or res is not DiscourseDialog:
			_next_uuid = &""
			_resource_id = ""
			_dialog_resource = null
			return false
		
		var d_o: RefCounted = _dialog_edits.get(id)
		var p_o: RefCounted = _phrase_overrides.get(id)
		
		if res._dialog_overrides != d_o:
			res._dialog_overrides = d_o
		if res._phrase_overrides != p_o:
			res._phrase_overrides = p_o
		
		_conversation_cache.cache_resource(res)
		_resource_id = id
		_dialog_resource = res
		
	if _dialog_resource.node_logic.has(starting_id):
		_next_uuid = starting_id
	else:
		_next_uuid = _dialog_resource.entry_node
	
	return true


## Registers a new base dialogue to the parser so it can be properly loaded
## with [method NFDialogParser.load_dialog] and
## [method NFDialogParser.prepare_dialog]. Returns [code]true[/code] if
## the registration was successful.[br]
## You can use [param localization_folder] to specify which folder contains
## the localization jsons. If left empty, the Nexus Forge localization folder
## and default path formatting will be used instead. This is probably [b]NOT[/b] what
## you want.
## [br][br]
## [b]Note:[/b] This method is intended to register BASE dialogues. If you want
## to override a dialogue use [method NFDialogParser.override_dialog_data] and
## [method NFDialogParser.override_dialog_locale] respectively.
func register_dialog(dialog_id: StringName, resource_path: String, localization_json_filename: String, localization_folder: String = "") -> bool:
	localization_folder = localization_folder.strip_edges().simplify_path()
	localization_json_filename = localization_json_filename.strip_edges().get_file()
	
	if _id_to_data.has(dialog_id):
		NFPluginGameHandler._log_msg(
				"discourse",
				"Tried to register dialogue '%s' with ID '%s' but the ID is already taken. Aborting" % [resource_path, dialog_id],
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	elif _path_to_id.has(resource_path):
		NFPluginGameHandler._log_msg(
				"discourse",
				"Tried to register dialogue '%s' but the resource is already registered with ID '%s'. Aborting" % [resource_path, _path_to_id[resource_path]],
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	elif not FileAccess.file_exists(resource_path):
		NFPluginGameHandler._log_msg(
				"discourse",
				"Tried to register dialogue but resource '%s' doesn't exist. Aborting" % resource_path,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	elif localization_json_filename.get_extension() != "json":
		NFPluginGameHandler._log_msg(
				"discourse",
				"Tried to register dialogue but '%s' is not a valid JSON file name. Aborting" % localization_json_filename,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	elif not localization_folder.is_empty() and (not localization_folder.is_absolute_path() or not DirAccess.dir_exists_absolute(localization_folder)):
		NFPluginGameHandler._log_msg(
				"discourse",
				"Tried to register dialogue but '%s' is not a valid directory path. Aborting" % localization_folder,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	var new_data: Dictionary[String, String] = {
		"data_path": resource_path,
		"locale_file": localization_json_filename}
	
	if not localization_folder.is_empty():
		new_data["localization_folder"] = localization_folder
	
	_path_to_id[resource_path] = dialog_id
	_id_to_data[dialog_id] = new_data
	
	return true


## Removes [param dialog_id] from the internal registry, meaning that this parser
## will no longer be able to load it.[br]
## If [param path] is empty, the data will be removed using only the [param dialog_id]
## but if a path is specified it must match with the resource registered in order
## to be removed. Returns [code]true[/code] if the operation was successful.
## [br][br]
## [b]Note:[/b] A successful operation only means that the action succeeded,
## not that any data was changed.
func unregister_dialog(dialog_id: StringName, path: String = "") -> bool:
	if not _id_to_data.has(dialog_id):
		return true
	path = path.simplify_path()
	
	var resource_filepath: String = _id_to_data[dialog_id]["data_path"]
	if not path.is_empty() and resource_filepath != path:
		return false
	
	_path_to_id.erase(resource_filepath)
	_id_to_data.erase(dialog_id)
	return true


## Returns if the resource at [param path] is currently registered in this
## parser.
func is_resource_registered(path: String) -> bool:
	return _path_to_id.has(path.simplify_path())


## Returns whether the [param id] is already registered in this parser.
func is_resource_id_registered(id: StringName) -> bool:
	return _id_to_data.has(id)


## Returns the ID of the registered resource at [param path] or an empty
## [code]&""[/code] if not found.
func get_resource_id(path: String) -> StringName:
	return _path_to_id.get(path.simplify_path(), &"")


## Returns the path to the resource registered with the [param id] or
## an empty string if not found.
func get_resource_path_of_resource_id(id: StringName) -> String:
	if not _id_to_data.has(id):
		return ""
	return _id_to_data[id]["data_path"]


## Loads the dialog from [param path] and localization files,
## then stores them in the dialogue cache making
## [method NFDialogParser.load_dialog] calls for the file at [param path]
## faster as long as the data remains in the cache.
## [br][br]
## Returns [code]true[/code] if the loading was successful.
func prepare_dialog(path: String) -> bool:
	path = path.simplify_path()
	var target_path: String = _logic_overrides.get(path, path)
	var dialog_id: StringName = _path_to_id.get(path, &"")
	
	if not _conversation_cache.is_in_cache(target_path):
		var res: Variant = load(target_path)
		
		if res == null or res is not DiscourseDialog:
			return false
		
		var d_o: RefCounted = _dialog_edits.get(dialog_id)
		var p_o: RefCounted = _phrase_overrides.get(dialog_id)
		
		if res._dialog_overrides != d_o:
			res._dialog_overrides = d_o
		if res._phrase_overrides != p_o:
			res._phrase_overrides = p_o
		
		if not res._has_locale(locale) and _id_to_data.has(dialog_id):
			_load_locale_into(res, locale, false, dialog_id)
			
		_conversation_cache.cache_resource(res)
		return true
	
	var data: DiscourseDialog = _conversation_cache.get_resource(target_path)
	var locale_data: DiscourseDialogLocale = data._get_locale(locale)
	
	var base_path: String = _get_base_locale_path(dialog_id, locale)
	var eff_path: String = _locale_overrides.get(dialog_id, NFDictUtils.EMPTY_DICT).get(locale, base_path)
	
	var current_json: String = locale_data.json_file if locale_data != null else ""
	var reload_locale: bool = false
	
	if eff_path != current_json or eff_path.is_empty():
		# Cache miss. Must check disk.
		var eff_exists: bool = not eff_path.is_empty() and FileAccess.file_exists(eff_path)
		
		if not eff_exists and eff_path != base_path:
			# Override file missing. Gracefully revert to base_path.
			eff_path = base_path
			
			# FALLBACK OPTIMIZATION: Base file is already in memory. Zero disk I/O.
			eff_exists = true
			if eff_path != current_json or eff_path.is_empty():
				eff_exists = not eff_path.is_empty() and FileAccess.file_exists(eff_path)
				
		# Only reload if a valid file exists AND it differs from what is in memory
		reload_locale = eff_exists and (current_json != eff_path)
	
	if reload_locale and _id_to_data.has(dialog_id):
		_load_locale_into(data, locale, true, dialog_id)
	
	return true


## Sets the dialog to be at the specific point of [param id].[br]
## Returns [code]true[/code] if the ID was set successfully.
func set_dialog_id(id: StringName) -> bool:
	if _dialog_resource == null:
		return false
	
	if not _dialog_resource.node_logic.has(id):
		NFPluginGameHandler._log_msg(
				"discourse",
				"Attempted to set an invalid dialog ID '%s' in loaded resource. Setting to dialogue end." % id,
				NFPluginGameHandler._LogLevel.ERROR)
		_next_uuid = &""
		return false
	
	_next_uuid = id
	return true


## Returns the ID of the current dialog position.
func get_dialog_current_id() -> StringName:
	return _current_uuid


## Returns the current state of the dialog parser in raw data form for 
## serialization.
func get_state() -> Dictionary[String, Variant]:
	var data: Dictionary[String, Variant] = {
		"current_dialog_id": get_dialog_current_id(),
		"next_dialog_id": _next_uuid,
		"conversation_started": _conversation_started,
		"dialog_travel_stack": _node_travel_stack.duplicate(true)}
	return data


## Sets the state of the current dialog from a dictionary.
func set_state(to: Dictionary) -> bool:
	var new_uuid: StringName = &""
	var next_uuid: StringName = &""
	var conv_started: bool = false
	var new_stack: Array[StringName] = []
	
	var stack_value: Variant = to.get("dialog_travel_stack")
	if typeof(stack_value) == TYPE_ARRAY:
		for item in stack_value:
			var arr_type: int = typeof(item)
			if arr_type == TYPE_STRING or arr_type == TYPE_STRING_NAME:
				new_stack.append(StringName(item))
			else:
				return false
	
	var to_value: Variant = to.get("current_dialog_id")
	var type: int = typeof(to_value)
	if type == TYPE_STRING_NAME or type == TYPE_STRING:
		new_uuid = StringName(to_value)
	
	var next_value: Variant = to.get("next_dialog_id")
	var type_next: int = typeof(next_value)
	if type_next == TYPE_STRING_NAME or type_next == TYPE_STRING:
		next_uuid = StringName(next_value)
	
	var started_value: Variant = to.get("conversation_started")
	var type_started: int = typeof(started_value)
	if type_started == TYPE_BOOL:
		conv_started = started_value
	
	_clear_target_travel_stack()
	_current_uuid = new_uuid
	_next_uuid = next_uuid
	_conversation_started = conv_started
	_node_travel_stack.assign(new_stack)
	
	return true


## Progresses the conversation
func advance() -> void:
	if _dialog_resource == null:
		return
	
	if not _conversation_started:
		_conversation_started = true
		dialog_started.emit()
	
	var result: Dictionary[String, Variant] = _process_logic(_next_uuid)
	
	if result["type"] == -1 or result["type"] == NodeTypes.DIALOG_END:
		_conversation_started = false
		_next_uuid = _dialog_resource.entry_node
		_current_uuid = &""
		_clear_target_travel_stack()
		dialog_finished.emit()
	else:
		_current_uuid = result["current"]
		_next_uuid = result["next"]
		match result["type"]:
			NodeTypes.DIALOG:
				dialog_reached.emit(result["data"])
			NodeTypes.CHOICES:
				choices_reached.emit(result["data"])
			NodeTypes.PAUSE:
				dialog_paused.emit()


## Forces the parser to process the current dialog/choices node again,
## re-emitting the relevant signal. Useful when changing locales or
## loading a dialog from a specific point.[br]
## This method is automatically called on [code]NexusForge.Discourse[/code]
## if Godot's locale changed and
## [code]Update Discourse Locale With Godot[/code] is [code]On[/code].
## [br][br]
## [b]Note:[/b] This only reprocesses the current node if it is a dialog
## or choices node and does not re-trigger previous nodes leading up to it.
func refresh() -> void:
	if _dialog_resource == null or _current_uuid.is_empty() or not _dialog_resource.node_logic.has(_current_uuid):
		return
	
	var dialog_type: NodeTypes = _dialog_resource.node_logic[_current_uuid]["node_type"]
	
	if dialog_type != NodeTypes.DIALOG and dialog_type != NodeTypes.CHOICES:
		return
	
	var result: Dictionary[String, Variant] = _process_logic(_current_uuid)
	
	if _next_uuid != result["next"]:
		_next_uuid = result["next"]
	
	if result["type"] == NodeTypes.DIALOG:
		dialog_reached.emit(result["data"])
	elif result["type"] == NodeTypes.CHOICES:
		choices_reached.emit(result["data"])
	elif result["type"] == NodeTypes.PAUSE:
		dialog_paused.emit()


## Overrides the logic file. When a dialog data is loaded, the file provided in
## [param override_path] will be used instead. This does NOT change the localization
## file used.
func override_dialog_data(dialog_id: String, override_path: String) -> void:
	override_path = override_path.strip_edges().simplify_path()
	
	if not _id_to_data.has(dialog_id):
		return
		
	var original_data_path: String = _id_to_data[dialog_id]["data_path"]
	
	if override_path.is_empty():
		_logic_overrides.erase(original_data_path)
	else:
		_logic_overrides[original_data_path] = override_path


## Overrides a complete localization file. When a dialog file is loaded, the file
## provided in [param path] will be used for localization instead of the original
## one.
func override_dialog_locale(dialog_id: String, locale_code: String, path: String) -> void:
	var valid_code: String = NFStringUtils.sanitize_locale(locale_code)
	if valid_code.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Attempted to set an override with an invalid locale '%s'" % locale_code,
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var override_changed: bool = false
	
	if path.is_empty():
		if _locale_overrides.has(dialog_id) and _locale_overrides[dialog_id].erase(valid_code):
			if _locale_overrides[dialog_id].is_empty():
				_locale_overrides.erase(dialog_id)
			override_changed = true # Had something, we cleared it
	else:
		if _locale_overrides.has(dialog_id):
			# Overrides were different.
			override_changed = _locale_overrides[dialog_id].get(valid_code, "") != path
		else:
			var override: Dictionary[String, String] = {}
			_locale_overrides[dialog_id] = override
			override_changed = true # No override existed
		
		_locale_overrides[dialog_id][valid_code] = path
	
	if not override_changed or not _id_to_data.has(dialog_id):
		return # Dialog hasn't been registered YET
	
	# Dialogue is registered, we're going to check if it's loaded
	var data_path: String = _id_to_data[dialog_id]["data_path"]
	var target_path: String = _logic_overrides.get(data_path, data_path)
	
	if not _conversation_cache.is_in_cache(target_path):
		return # Not loaded
	
	var dialog: DiscourseDialog = _conversation_cache.get_resource(target_path)
	dialog.parsed_dialog_cache.clear() # We clear ALL the node data.
	
	var fallback_mode: int = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse_fallback_mode"), 2)
	var godot_fallback: String = NFStringUtils.sanitize_locale(
			ProjectSettings.get_setting("internationalization/locale/fallback", "en"))
	
	var locales_to_drop: Array[String] = []
	for cached_code: String in dialog._loaded_locales.keys():
		var needs_drop: bool = false
		
		if cached_code == valid_code:
			needs_drop = true
		elif fallback_mode == 1:
			needs_drop = valid_code == godot_fallback
		elif fallback_mode == 2:
			var cached_lang: String = NFStringUtils.get_locale_language(cached_code)
			needs_drop = valid_code == godot_fallback or valid_code == cached_lang
		
		if needs_drop:
			locales_to_drop.append(cached_code)
	
	if not locales_to_drop.is_empty():
		dialog._loaded_locales.remove_keys(locales_to_drop) # Drop specific locales
	
	if locales_to_drop.has(locale) or locale == valid_code:
		_load_locale_into(dialog, locale, true, dialog_id) # Since it has it we force a reload


## Adds an override for a specific dialog on a specific locale.[br]
## [param data] needs to be either a String or [code]null[/code]. If you pass
## [code]null[/code] to [param data] the edited dialog will be removed and the
## original used instead.[br]
## [param force] forces the override. This means that if a previous override wasn't
## for text, it'll be replaced with one for text.
func set_dialog_text(locale_code: String, dialog_id: String, node_id: StringName, new_dialog, force: bool = false) -> void:
	var type: int = typeof(new_dialog)
	if type == TYPE_STRING_NAME:
		new_dialog = String(new_dialog)
		type = TYPE_STRING
	
	locale_code = NFStringUtils.sanitize_locale(locale_code)
	
	if locale_code.is_empty() or dialog_id.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Invalid locale code or empty dialog id on dialog edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif type != TYPE_NIL and type != TYPE_STRING:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Data type error on dialog edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var target: DiscourseDialog.NFDialogEntryOverride = _dialog_edits.get(dialog_id)
	
	if type == TYPE_NIL:
		if target != null:
			target.remove_dialog_override(node_id, locale_code)
		return
	
	if target == null:
		target = DiscourseDialog.NFDialogEntryOverride.new()
		_dialog_edits[dialog_id] = target
	
	var success: bool = target.set_dialog_override(node_id, locale_code, new_dialog, force)
	if not success:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Dialogue override assingment failed. Previous choice override detected on ID '%s' of dialogue '%s' for locale '%s'" % [node_id, dialog_id, locale_code],
				NFPluginGameHandler._LogLevel.ERROR)
	
	if _dialog_resource == null or _get_current_dialog_id() != dialog_id:
		return
	
	if _dialog_resource._dialog_overrides != target:
		_dialog_resource._dialog_overrides = target


## Adds an override for a specific set of choices on a specific locale.
## [param new_choices] must be either an array or [code]null[/code].[br]
## If [param data] is null, ALL the choice overrides are removed for the
## specified node on the locale and the original data will be used instead[br]
## Overriding a choice text can be specific by passing null items inside the array.
## [codeblock]
## # We want to only override the second and third choice text, but not the first
## The original chocies are ["Yes", "Maybe", "No"]
## set_choices_array("en_US", "test.dialogue", "choice_node", [null, "Mayhaps", "Nope"])
## The choices are now ["Yes", "Mayhaps", "Nope"]
## [/codeblock]
## [param force] forces the override. This means that if a previous override wasn't
## for a choice, it'll be replaced with one for choices.
func set_choices_array(locale_code: String, dialog_id: String, node_id: StringName, new_choices, force: bool = false) -> void:
	locale_code = NFStringUtils.sanitize_locale(locale_code)
	var type: int = typeof(new_choices)
	
	if locale_code.is_empty() or dialog_id.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Invalid locale code or empty dialog id on choice edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif type != TYPE_ARRAY and type != TYPE_PACKED_STRING_ARRAY and type != TYPE_NIL:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Can't assing choices based on a non-array.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var target: DiscourseDialog.NFDialogEntryOverride = _dialog_edits.get(dialog_id)
	
	if type == TYPE_NIL:
		if target != null:
			target.clear_choice_overrides(node_id, locale_code)
		return
	
	if target == null:
		target = DiscourseDialog.NFDialogEntryOverride.new()
		_dialog_edits[dialog_id] = target
	
	var valid_responses: Array = []
		
	for idx in range(new_choices.size()):
		var opt_type: int = typeof(new_choices[idx])
		if opt_type == TYPE_STRING_NAME:
			valid_responses.append(String(new_choices[idx]))
		elif opt_type == TYPE_STRING or opt_type == TYPE_NIL:
			valid_responses.append(new_choices[idx])
		else:
			NFPluginGameHandler._log_msg(
					"discourse",
					"Incorrect type for choice assing on index %d. Provided type: %s. Skipping" % [idx, type_string(opt_type)],
					NFPluginGameHandler._LogLevel.WARNING)
			valid_responses.append(null)
	
	var success: bool = target.set_choices_override(
			node_id,
			locale_code,
			valid_responses,
			force)
	if not success:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Dialogue override assingment failed. Previous text override detected on ID '%s' of dialogue '%s' for locale '%s'" % [node_id, dialog_id, locale_code],
				NFPluginGameHandler._LogLevel.ERROR)
	
	if _dialog_resource == null or _get_current_dialog_id() != dialog_id:
		return
	
	if _dialog_resource._dialog_overrides != target:
		_dialog_resource._dialog_overrides = target


## Adds an override for a specific choice on a specific locale. [param data]
## must be either a string or [code]null[/code]. If [param data]
## is [code]null[/code] the override will be cleared and the original data used[br]
## [param force] forces the override. This means that if a previous override wasn't
## for a choice, it'll be replaced with one for choices.
func set_choice_text(locale_code: String, dialog_id: String, node_id: StringName, choice_index: int, data: Variant, force: bool = false) -> void:
	if choice_index < 0:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Choice overrides doesn't work with negative indexes: %d" % choice_index,
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif dialog_id.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Invalid dialog id on choice edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	locale_code = NFStringUtils.sanitize_locale(locale_code)
	
	if locale_code.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Invalid locale code on choice edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var data_type: int = typeof(data)
	if data_type == TYPE_STRING_NAME:
		data = String(data)
		data_type = TYPE_STRING
	var target: DiscourseDialog.NFDialogEntryOverride = _dialog_edits.get(dialog_id)
	
	if data_type == TYPE_NIL:
		if target != null:
			target.remove_choice_override(node_id, locale_code, choice_index)
		return
	elif data_type != TYPE_STRING:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Data type error on choice edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	if target == null:
		target = DiscourseDialog.NFDialogEntryOverride.new()
		_dialog_edits[dialog_id] = target
	
	var success: bool = target.set_choice_override(node_id, locale_code, choice_index, data, force)
	if not success:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Dialogue override assingment failed. Previous text override detected on ID '%s' of dialogue '%s' for locale '%s'" % [node_id, dialog_id, locale_code],
				NFPluginGameHandler._LogLevel.ERROR)
	
	if _dialog_resource == null or _get_current_dialog_id() != dialog_id:
		return
	
	if _dialog_resource._dialog_overrides != target:
		_dialog_resource._dialog_overrides = target


## Adds an override for a specific phrase's base string.[br]
## Pass [code]null[/code] to [param base] to remove the override.
func set_phrase_base_string_override(locale_code: String, dialog_id: String, phrase_id: String, base: Variant) -> void:
	var type: int = typeof(base)
	if type == TYPE_STRING_NAME:
		base = String(base)
		type = TYPE_STRING
	locale_code = NFStringUtils.sanitize_locale(locale_code)
	
	if locale_code.is_empty() or dialog_id.is_empty() or phrase_id.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Invalid locale code or empty id on phrase or dialog for phrase base string edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif type != TYPE_NIL and type != TYPE_STRING:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Data type error on phrase base string edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	if type == TYPE_NIL:
		if _phrase_overrides.has(dialog_id):
			_phrase_overrides[dialog_id].set_base_string_override(dialog_id, locale_code, phrase_id, null)
		return
	
	var target: DiscourseDialog.NFPhraseEntryOverride = _phrase_overrides.get(dialog_id)
	if target == null:
		var new_entry := DiscourseDialog.NFPhraseEntryOverride.new()
		_phrase_overrides[dialog_id] = new_entry
		target = new_entry
	
	target.set_base_string_override(dialog_id, locale_code, phrase_id, base)
	
	if _dialog_resource == null or _get_current_dialog_id() != dialog_id:
		return
	
	if _dialog_resource._phrase_overrides != _phrase_overrides[dialog_id]:
		_dialog_resource._phrase_overrides = _phrase_overrides[dialog_id]


## Adds an override for a specific phrase's format default.[br]
## Pass [code]null[/code] to [param default_val] to remove the override.
func set_phrase_format_default_override(locale_code: String, dialog_id: String, phrase_id: String, format_id: String, default_val: Variant) -> void:
	var type: int = typeof(default_val)
	if type == TYPE_STRING_NAME:
		default_val = String(default_val)
		type = TYPE_STRING
	locale_code = NFStringUtils.sanitize_locale(locale_code)
	
	if locale_code.is_empty() or dialog_id.is_empty() or phrase_id.is_empty() or format_id.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Invalid locale code or empty id on phrase format edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif type != TYPE_NIL and type != TYPE_STRING:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Data type error on phrase format edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	if type == TYPE_NIL:
		if _phrase_overrides.has(dialog_id):
			_phrase_overrides[dialog_id].set_format_default_override(dialog_id, locale_code, phrase_id, format_id, null)
		return
	
	var target: DiscourseDialog.NFPhraseEntryOverride = _phrase_overrides.get(dialog_id)
	if target == null:
		var new_override := DiscourseDialog.NFPhraseEntryOverride.new()
		_phrase_overrides[dialog_id] = new_override
		target = new_override
	
	target.set_format_default_override(dialog_id, locale_code, phrase_id, format_id, default_val)
	
	if _dialog_resource == null or _get_current_dialog_id() != dialog_id:
		return
	
	if _dialog_resource._phrase_overrides != _phrase_overrides[dialog_id]:
		_dialog_resource._phrase_overrides = _phrase_overrides[dialog_id]


## Adds an override for a specific phrase's format case.[br]
## Pass [code]null[/code] to [param result] to remove the override.
func set_phrase_format_case_override(locale_code: String, dialog_id: String, phrase_id: String, format_id: String, case_id: String, result: Variant) -> void:
	var type: int = typeof(result)
	if type == TYPE_STRING_NAME:
		result = String(result)
		type = TYPE_STRING
	
	locale_code = NFStringUtils.sanitize_locale(locale_code)
	
	if locale_code.is_empty() or dialog_id.is_empty() or phrase_id.is_empty() or format_id.is_empty() or case_id.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Invalid locale code or empty id on phrase format case edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif type != TYPE_NIL and type != TYPE_STRING:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Data type error on phrase format case edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	if type == TYPE_NIL:
		if _phrase_overrides.has(dialog_id):
			_phrase_overrides[dialog_id].set_format_case_override(dialog_id, locale_code, phrase_id, format_id, case_id, null)
		return
	
	var target: DiscourseDialog.NFPhraseEntryOverride = _phrase_overrides.get(dialog_id)
	if target == null:
		var new_override := DiscourseDialog.NFPhraseEntryOverride.new()
		_phrase_overrides[dialog_id] = new_override
		target = new_override
	
	target.set_format_case_override(dialog_id, locale_code, phrase_id, format_id, case_id, result)
	
	if _dialog_resource == null or _get_current_dialog_id() != dialog_id:
		return
	
	if _dialog_resource._phrase_overrides != _phrase_overrides[dialog_id]:
		_dialog_resource._phrase_overrides = _phrase_overrides[dialog_id]


## Overrides a specific phrase's format to use the default text.
func set_phrase_format_case_to_default(locale_code: String, dialog_id: String, phrase_id: String, format_id: String, case_id: String) -> void:
	locale_code = NFStringUtils.sanitize_locale(locale_code)
	
	if locale_code.is_empty() or dialog_id.is_empty() or phrase_id.is_empty() or format_id.is_empty() or case_id.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Invalid locale code or empty id on phrase case default edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var target: DiscourseDialog.NFPhraseEntryOverride = _phrase_overrides.get(dialog_id)
	if target == null:
		var new_override := DiscourseDialog.NFPhraseEntryOverride.new()
		_phrase_overrides[dialog_id] = new_override
		target = new_override
	
	target.override_format_case_to_default(dialog_id, phrase_id, format_id, case_id, locale_code)
	
	if _dialog_resource == null or _get_current_dialog_id() != dialog_id:
		return
	
	if _dialog_resource._phrase_overrides != _phrase_overrides[dialog_id]:
		_dialog_resource._phrase_overrides = _phrase_overrides[dialog_id]


## Removes the default override for a specific phrase's case, restoring its base data.
func clear_phrase_format_case_default(locale_code: String, dialog_id: String, phrase_id: String, format_id: String, case_id: String) -> void:
	locale_code = NFStringUtils.sanitize_locale(locale_code)
	
	if locale_code.is_empty() or dialog_id.is_empty() or phrase_id.is_empty() or format_id.is_empty() or case_id.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Invalid locale code or empty id on phrase case default clear.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var target: DiscourseDialog.NFPhraseEntryOverride = _phrase_overrides.get(dialog_id)
		
	if target == null:
		return
	
	target.clear_format_case_default(dialog_id, phrase_id, format_id, case_id, locale_code)
	
	if _dialog_resource == null or _get_current_dialog_id() != dialog_id:
		return
		
	if _dialog_resource._phrase_overrides != _phrase_overrides[dialog_id]:
		_dialog_resource._phrase_overrides = _phrase_overrides[dialog_id]


func _get_dialog_id(path: String) -> StringName:
	var key: StringName = StringName(path)
	if _path_to_id.has(key):
		return _path_to_id[key]
	return &""


func _get_current_dialog_id() -> StringName:
	if is_instance_valid(_dialog_resource):
		return StringName(_resource_id)
	return &""


func _path_has_id(path: String) -> bool:
	return _path_to_id.has(StringName(path))


# Clears the whole cache. Used on exit to prevent leaked resources
func _clear_cache() -> void:
	if _dialog_resource != null:
		_dialog_resource.parsed_dialog_cache.clear()
	_conversation_cache.clear()


func _pop_last_travel_node_stack() -> StringName:
	if _node_travel_stack.is_empty():
		return &""
	return _node_travel_stack.pop_back()


func _add_target_to_travel_stack(target: StringName) -> void:
	_node_travel_stack.append(target)


func _clear_target_travel_stack() -> void:
	_node_travel_stack.clear()


func _get_target_travel_stack_size() -> int:
	return _node_travel_stack.size()


func _to_bool(data: Variant, fallback: bool = false) -> bool:
	match typeof(data):
		TYPE_BOOL:
			return data
		TYPE_INT, TYPE_FLOAT:
			return bool(data)
		_:
			return fallback


func _get_base_locale_path(dialog_id: StringName, target_locale: String) -> String:
	var e: Dictionary = NFDictUtils.EMPTY_DICT
	var dialog_data: Dictionary = _id_to_data.get(dialog_id, e)
	var m_file: String = dialog_data.get("locale_file", "")
	
	if m_file.is_empty():
		return ""
		
	if dialog_data.has("localization_folder"):
		# Mod Structure: folder / locale / filename
		var m_folder: String = dialog_data["localization_folder"]
		return m_folder.path_join(target_locale).path_join(m_file)
		
	# Vanilla Structure: default_path / locale / hash / filename
	var default_loc: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse"), 
			"res://localization/")
	var hash_slice: String = m_file.substr(0, 2)
	
	return default_loc.path_join(target_locale).path_join(hash_slice).path_join(m_file)
