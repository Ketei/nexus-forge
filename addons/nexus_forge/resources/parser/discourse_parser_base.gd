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
		var new_standard: String = TranslationServer.standardize_locale(new_locale.strip_edges())
		if new_standard.is_empty() or locale == new_standard:
			return
		
		locale = new_standard
		if _dialog_resource == null:
			return
		
		if not _dialog_resource._has_locale(locale):
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

var _resource_id: String = ""
var _conversation_started: bool = false
var _next_uuid: StringName = &""
var _current_uuid: StringName = &""
var _conversation_cache: NFLRUResourceCache = null
var _parser_cache: NFLRUCache = null
var _parser_regex: RegEx = RegEx.new()
var _node_travel_stack: Array[StringName] = []

var _path_to_id: Dictionary[StringName, StringName] = {}
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
var _phrase_overrides: Dictionary[String, DiscourseDialog.NFPhraseEntryOverride] = {
	"dialogs.village.mayor": DiscourseDialog.NFPhraseEntryOverride.new()
}


func _init() -> void:
	_conversation_cache = NFLRUResourceCache.new()
	_parser_cache = NFLRUCache.new()
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
	
	for file_path in data["file_to_id"]:
		if typeof(file_path) != TYPE_STRING or typeof(data["file_to_id"][file_path]) != TYPE_STRING or not data["id_to_locale_file"].has(data["file_to_id"][file_path]) or typeof(data["id_to_locale_file"][data["file_to_id"][file_path]]) != TYPE_STRING:
			continue
		var file_id: String = data["file_to_id"][file_path]
		var localizaton_file: String = data["id_to_locale_file"][file_id]
		_path_to_id[file_path] = file_id
		_id_to_data[file_id] = {"data_path": file_path, "locale_file": localizaton_file}#localizaton_file


# Function to parse the dialog in a custom manner. Modify if needed.
func _parse_dialog(dialog_id: String, dialog_text: String, is_override: bool) -> String:
	if not ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path(
					"use_discourse_parser"),
					true):
		return dialog_text
	
	var DUUID: String = ""
	var p_override: DiscourseDialog.NFPhraseEntryOverride = _phrase_overrides.get(dialog_id)
	
	if p_override != null and p_override.has_override(_get_current_dialog_id()):
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
			var resource_id: StringName = _path_to_id[_dialog_resource.resource_path] if _path_to_id.has(_dialog_resource.resource_path) else &""
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
					clean_text, ""))
	
	return callable


func _build_callable_for_method(text: String) -> Callable:
	var parts: PackedStringArray = text.split("|", false, 1)
	var method: StringName = StringName(parts[0].trim_prefix("!"))
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
	
	var callable: Callable = Callable(NexusForge.Discourse.API, method)
	
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


func _can_compare(a, b) -> bool:
	var type_a: int = typeof(a)
	var type_b: int = typeof(b)
	
	if type_a == type_b:
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
func _process_logic(uuid: StringName) -> Dictionary[String, Variant]:
	var target: Dictionary[String, Variant] = {"current": &"", "next": &"", "type": -1, "data": {}}
	if uuid.is_empty() or not _dialog_resource.node_logic.has(uuid):
		return target
	
	var dialog_id: String = _resource_id
	var data: Dictionary = _dialog_resource.node_logic[uuid]
	
	match data["node_type"]:
		NodeTypes.ENTRY:
			return _process_logic(data["next_node"])
		NodeTypes.DIALOG:
			var settings: Dictionary = data.get("dialog_settings", {})
			var char_settings: Dictionary = data.get("character_settings", {})
			var dialog_metadata: Dictionary = settings.get("metadata", {})
			
			var font: String = _get_data(settings.get("font_resource", &""), "")
			var scene: String = _get_data(settings.get("dialog_scene", &""), "")
			var speed: float = _get_data(settings.get("dialog_speed", &""), 0.0)
			var display_name: String = _get_data(char_settings.get("display_name", &""), "")
			var portrait_id: String = _get_data(char_settings.get("portrait_id", &""), "")
			var metadata: Dictionary[String, Variant] = {}
			
			target["type"] = NodeTypes.DIALOG
			
			for meta_key in dialog_metadata:
				metadata[meta_key] = _get_data(dialog_metadata[meta_key])
			
			if data["text_source"].is_empty():
				var text_data: Dictionary[String, Variant] = _dialog_resource._get_text_data(dialog_id, uuid)
				target["data"] = {
					"dialog_text": _parse_dialog(
							String(uuid),
							text_data["text"],
							text_data["is_override"]),
					"character_id": data["character_id"],
					"persist": data["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id,
					"metadata": metadata}
			else:
				var data_source = _get_data(data["text_source"], "")
				var text: String = ""
				var is_override: bool = false
				var source_type: int = typeof(data_source)
				
				if source_type == TYPE_STRING:
					text = data_source
				elif source_type == TYPE_DICTIONARY:
					text = data_source.get("text", "")
					is_override = data_source.get("is_override", false)
				else:
					text = "[ERROR GETING DATA FROM %s]" % data["text_source"]
				
				target["data"] ={
					"dialog_text": _parse_dialog(
							String(uuid),
							text,
							is_override),
					"character_id": data["character_id"],
					"persist": data["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id,
					"metadata": metadata}
			
			target["current"] = uuid
			target["next"] = data["next_node"]
			
			return target
		NodeTypes.CHOICES:
			var available_options: Array[Dictionary] = []
			var target_size: int = data["choices"].size()
			var is_overridden: bool = _dialog_resource._dialog_overrides != null\
					and _dialog_resource._dialog_overrides.has_override(uuid, locale, TYPE_PACKED_STRING_ARRAY)
			
			var localized_options: PackedStringArray = []
			if is_overridden:
				localized_options = _dialog_resource._dialog_overrides.get_override(uuid, locale).duplicate()
			else:
				if _dialog_resource._active_locale != null:
					localized_options = _dialog_resource._active_locale.get_choices(dialog_id, uuid)
			
			var current_size: int = localized_options.size()
			target["type"] = NodeTypes.CHOICES
			
			if current_size < target_size:
				var err_msg: String = "[MISSING LOCALIZATION DATA]"
				for _step in range(target_size - current_size):
					localized_options.append(err_msg)
			elif target_size < current_size:
				localized_options.resize(target_size)
			
			var idx: int = -1
			var option_duuid: String = ""
			for option:Dictionary in data["choices"]:
				idx += 1
				option_duuid = String(uuid) + "_" + str(idx)
				
				if option["settings"].is_empty():
					option_duuid += "_unlocked"
					available_options.append(
						{
							"unlocked": true,
							"text": _parse_dialog(option_duuid, localized_options[idx], is_overridden),
							"target": option["next_node"],
							"metadata": NFDictUtils.create_typed(TYPE_STRING, TYPE_NIL)})
				else:
					var opt_settings: Dictionary = option["settings"]
					var show: bool = _get_data(opt_settings["available"], true)
				
					if not show:
						continue
					
					var unlocked: bool = _get_data(opt_settings["unlocked"], true)
					var text: String = localized_options[idx]
					var metadata: Dictionary[String, Variant] = {}
					
					if opt_settings.has("metadata"):
						for meta_key in opt_settings["metadata"]:
							metadata[meta_key] = _get_data(opt_settings["metadata"][meta_key])
					
					if not unlocked:
						var lock_hint: String = _get_data(opt_settings["lock_hint"], "")
						if not lock_hint.is_empty():
							text = lock_hint
					
					if unlocked:
						option_duuid += "_unlocked"
					else:
						option_duuid += "_locked"
					
					available_options.append({
						"unlocked": unlocked,
						"text": _parse_dialog(option_duuid, text, is_overridden),
						"target": option["next_node"],
						"metadata": metadata})
			
			target["data"] = available_options
			target["current"] = uuid
			target["next"] = uuid
			
			return target
		NodeTypes.BRANCH:
			var use_a: bool = _get_data(data["result"], true)
			if use_a:
				return _process_logic(data["case_true"])
			else:
				return _process_logic(data["case_false"])
		NodeTypes.EVENT:
			var path: String = data.get("variable_path", "")
			var val: StringName = data.get("value", &"")
			var call_node: StringName = data.get("callable", &"")
			var sign_node: StringName = data.get("signal", &"")
			
			if not path.is_empty() and not val.is_empty():
				NexusForge.Blackboard.set_variable(
						path,
						_get_data(val))
			if not call_node.is_empty():
				var call_data: Dictionary = _dialog_resource.node_logic[call_node]
				var call_args: Array = []
				
				for argument_key in call_data["arguments"]:
					if argument_key.is_empty():
						continue
					call_args.append(_get_data(argument_key))
				
				NexusForge.Discourse.API.callv(
						call_data["method"],
						call_args)
			
			if not sign_node.is_empty():
				var signal_data: Dictionary = _dialog_resource.node_logic[sign_node]
				var signal_args: Array = []
				var api_signal: Signal = Signal(
						NexusForge.Discourse.API,
						signal_data["signal"])
				
				for argument_key in signal_data["arguments"]:
					if argument_key.is_empty():
						continue
					signal_args.append(_get_data(argument_key))
				
				api_signal.emit.callv(signal_args)
				
			return _process_logic(data["next_node"])
		NodeTypes.MATCH:
			var match_data = _get_data(data["match_value"])
			for case:Dictionary in data["cases"]:
				if case["value"] == match_data:
					return _process_logic(case["next_node"])
			return _process_logic(data["case_default"])
		NodeTypes.PAUSE:
			target["type"] = NodeTypes.PAUSE
			target["current"] = uuid
			target["next"] = data["next_node"]
			
			return target
		NodeTypes.RANDOM:
			var total_weight: int = 0
			var choices: Array[Dictionary] = []
			
			for choice:Dictionary in data["choices"]:
				var weight: int = RANDOM_DEFAULT_WEIGHT
				if not choice["weight_override"].is_empty():
					weight = _get_data(choice["weight_override"], weight)
				if weight <= 0:
					continue
				choices.append({
					"next": choice["target"],
					"weight": weight})
				total_weight += weight
			
			if choices.is_empty():
				return target
			
			choices.sort_custom(func(a, b): return a["weight"] > b["weight"])
			var random_select: int = randi_range(1, total_weight)
			
			var current_weight: int = 0
			for choice in choices:
				current_weight += choice["weight"]
				if random_select <= current_weight:
					return _process_logic(choice["next"])
			return _process_logic(choices[-1]["next"]) # In case of loop error
		NodeTypes.DIALOG_END:
			target["current"] = uuid
			target["type"] = NodeTypes.DIALOG_END
			return target
		NodeTypes.TRAVEL_TO:
			if -1 < max_dialog_travel_stack and max_dialog_travel_stack <= _get_target_travel_stack_size():
				NFPluginGameHandler._log_msg(
					"discourse",
					"Travel stack overflow! Max depth of %d reached." % max_dialog_travel_stack,
					NFPluginGameHandler._LogLevel.ERROR)
				return target # Empty, so it should stop the dialog
			_add_target_to_travel_stack(data["next_node"])
			return _process_logic(data["travel_target"])
		NodeTypes.TRAVEL_TARGET:
			return _process_logic(data["next_node"])
		NodeTypes.TRAVEL_BACK:
			return _process_logic(_pop_last_travel_node_stack())
		_:
			return target


func _get_data(uuid: StringName, fallback = null) -> Variant:
	if _dialog_resource == null or not _dialog_resource.node_logic.has(uuid):
		return fallback
	var data: Dictionary = _dialog_resource.node_logic[uuid]
	
	match data["node_type"]:
		NodeTypes.VALUE:
			return data["value"]
		NodeTypes.RANDOM_VALUE:
			match data["random_type"]:
				TYPE_INT:
					var min_value: int = data["min_value"]
					var max_value: int = data["max_value"]
					
					if not data["min_override"].is_empty():
						min_value = _get_data(data["min_override"], min_value)
					if not data["max_override"].is_empty():
						max_value = _get_data(data["max_override"], max_value)
					
					if max_value < min_value:
						max_value = min_value
					
					return randi_range(min_value, max_value)
				TYPE_FLOAT:
					var min_value: float = data["min_value"]
					var max_value: float = data["max_value"]
					
					if not data["min_override"].is_empty():
						min_value = _get_data(data["min_override"], min_value)
					if not data["max_override"].is_empty():
						max_value = _get_data(data["max_override"], max_value)
					
					if max_value < min_value:
						max_value = min_value
					
					return snappedf(
							randf_range(
									min_value,
									max_value),
							FLOAT_SNAP)
				TYPE_BOOL:
					var true_probability: int = data["min_value"]
					
					if not data["min_override"].is_empty():
						true_probability = _get_data(data["min_override"], true_probability)
						
					if true_probability <= 0:
						return false
					elif 100 <= true_probability:
						return true
					else:
						var true_range: int = randi_range(1, 100)
						return true_range <= true_probability
				_:
					return null
		NodeTypes.TYPE_GUARD:
			var guard_data = _get_data(data["value"])
			if typeof(guard_data) == typeof(data["fallback"]):
				return guard_data
			else:
				return data["fallback"]
		NodeTypes.VARIABLE_GET:
			return NexusForge.Blackboard.get_variable(data["path"])
		NodeTypes.CALLABLE_RETURN:
			var method: Callable = Callable(NexusForge.Discourse.API, data["method"])
			var args: Array = []
			for arg:StringName in data["arguments"]:
				args.append(_get_data(arg))
			return method.callv(args)
		NodeTypes.DATA_EVENT:
			var var_path: String = data.get("variable_path", "")
			var val_node: StringName = data.get("value", &"")
			var call_node: StringName = data.get("callable", &"")
			var sign_node: StringName = data.get("signal", &"")
			if not var_path.is_empty() and not val_node.is_empty():
				NexusForge.Blackboard.set_variable(
						var_path,
						_get_data(val_node))
			if not call_node.is_empty():
				var call_data: Dictionary = _dialog_resource.node_logic[call_node]
				var call_args: Array = []
				
				for argument_id in call_data["arguments"]:
					if argument_id.is_empty():
						continue
					call_args.append(_get_data(argument_id))
				
				NexusForge.Discourse.API.callv(
						call_data["method"],
						call_args)
			
			if not sign_node.is_empty():
				var signal_data: Dictionary = _dialog_resource.node_logic[sign_node]
				var signal_args: Array = []
				
				for argument_key in signal_data["arguments"]:
					if argument_key.is_empty():
						continue
					signal_args.append(_get_data(argument_key))
				
				var sign_call: Signal = Signal(
						NexusForge.Discourse.API,
						signal_data["signal"])
				
				sign_call.emit.callv(signal_args)
				
			return _get_data(data["data_source"])
		NodeTypes.LOCALIZED_TEXT:
			return _dialog_resource._get_text_data(
					_path_to_id[_dialog_resource.resource_path],
					uuid)
		NodeTypes.COMPARATION:
			var a = _get_data(data["value_a"])
			var b = _get_data(data["value_b"])
			if not _can_compare(a, b):
				return false
			
			match data["operator"]:
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
					return false
		NodeTypes.CONDITION_SELECT:
			var condition: bool = _get_data(data["result"])
			if condition:
				return _get_data(data["true_value"])
			else:
				return _get_data(data["false_value"])
		NodeTypes.RESOURCE:
			return data["resource_path"]
		_:
			return fallback


func _load_locale_into(dialog: DiscourseDialog, locale_code: String, force_reload: bool = false) -> void:
	if dialog == null or locale_code.is_empty() or (dialog._has_locale(locale_code) and not force_reload):
		return
	
	var dialog_id: String = _resource_id
	if dialog_id.is_empty():
		return
	
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
					cascade_locale.json_file = ""
					cascade_locale.locale = locale_code
					locale_data = cascade_locale
					
				else:
					locale_data.merge_dialog(cascade_locale)
	
	if direct_fallback != null:
		if locale_data == null:
			locale_data = direct_fallback.duplicate(true)
			locale_data.json_file = ""
			locale_data.locale = locale_code
		else:
			locale_data.merge_dialog(direct_fallback)
	
	if locale_data != null:
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
			"nexus_forge/localization_directory",
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
			locale_data.json_file = filename
		return locale_data
	else:
		return null


func _dialog_resource_set() -> void:
	if _dialog_resource == null:
		return
	
	if not _dialog_resource._has_locale(locale):
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
	_clear_target_travel_stack()
	
	var target_path: String = _logic_overrides[path] if _logic_overrides.has(path) else path
	
	if _conversation_cache.is_in_cache(target_path):
		var dialog_id: String = _path_to_id.get(path, "")
		var data: DiscourseDialog = _conversation_cache.get_resource(target_path)
		var locale_data: DiscourseDialogLocale = data._get_locale(locale)
		
		var eff_locale_file: String = _locale_overrides.get(dialog_id, NFDictUtils.EMPTY_DICT).get(locale, _id_to_data[dialog_id]["locale_file"])
		var reload_locale: bool = locale_data != null and locale_data.json_file != eff_locale_file
		
		_dialog_resource = data
		_resource_id = dialog_id
		
		if _dialog_edits.has(dialog_id) and _dialog_resource._dialog_overrides != _dialog_edits[dialog_id]:
			_dialog_resource._dialog_overrides = _dialog_edits[dialog_id]
		
		var p_overrides: DiscourseDialog.NFPhraseEntryOverride = _phrase_overrides.get(dialog_id)
		if _dialog_resource._phrase_overrides != p_overrides:
			_dialog_resource._phrase_overrides = p_overrides
		
		if reload_locale:
			_load_locale_into(_dialog_resource, locale, true)
	else:
		var res: DiscourseDialog = load(target_path)
		var id: String = _path_to_id.get(path, "")
		
		if res == null or res is not DiscourseDialog:
			_next_uuid = &""
			_resource_id = ""
			_dialog_resource = null
			return false
		
		res._dialog_overrides = _dialog_edits.get(id)
		res._phrase_overrides = _phrase_overrides.get(id)
		
		_conversation_cache.cache_resource(res)
		_dialog_resource = res
		_resource_id = id
	
	if _dialog_resource.node_logic.has(starting_id):
		_next_uuid = starting_id
	else:
		_next_uuid = _dialog_resource.entry_node
	
	return true


## Loads the dialog from [param path] and localization files,
## then stores them in the dialogue cache making
## [method NFDialogParser.load_dialog] calls for the file at [param path]
## faster as long as the data remains in the cache.
## [br][br]
## Returns [code]true[/code] if the loading was successful.
func prepare_dialog(path: String) -> bool:
	var target_path: String = _logic_overrides[path] if _logic_overrides.has(path) else path
	var dialog_id: String = NFDictUtils.get_nested_value(_path_to_id, [path], "")
	
	if _conversation_cache.is_in_cache(target_path):
		var data: DiscourseDialog = _conversation_cache.get_resource(target_path)
		var locale_data: DiscourseDialogLocale = data._get_locale(locale)
		
		var eff_locale_file: String = _locale_overrides.get(dialog_id, NFDictUtils.EMPTY_DICT).get(locale, _id_to_data[dialog_id]["locale_file"])
		var reload_locale: bool = locale_data != null and locale_data.json_file != eff_locale_file
		if _dialog_edits.has(dialog_id) and data._dialog_overrides != _dialog_edits[dialog_id]:
			data._dialog_overrides = _dialog_edits[dialog_id]
		
		if reload_locale:
			_load_locale_into(data, locale, true)
	else:
		var res = load(target_path)
		
		if res == null or res is not DiscourseDialog:
			return false
			
		if _dialog_edits.has(dialog_id):
			res._dialog_overrides = _dialog_edits[dialog_id]
		if not res._has_locale(locale):
			_load_locale_into(res, locale)
		_conversation_cache.cache_resource(res)
	
	return true


## Sets the dialog to be at a specific point. If invalid it'll
## set the dialog to be at the beggining.
func set_dialog_id(id: StringName) -> void:
	if _dialog_resource == null:
		return
	
	if _dialog_resource.node_logic.has(id):
		_next_uuid = id
	else:
		_next_uuid = &""


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
func set_state(to: Dictionary) -> void:
	var new_uuid: StringName = &""
	var next_uuid: StringName = _next_uuid
	var conv_started: bool = _conversation_started
	var new_stack: Array[StringName] = []
	
	if to.has("current_dialog_id"):
		var type: int = typeof(to["current_dialog_id"])
		if type == TYPE_STRING_NAME or type == TYPE_STRING:
			new_uuid = StringName(to["current_dialog_id"])
	
	if to.has("next_dialog_id"):
		var type: int = typeof(to["next_dialog_id"])
		if type == TYPE_STRING_NAME or type == TYPE_STRING:
			next_uuid = StringName(to["next_dialog_id"])
	
	if to.has("conversation_started"):
		var type: int = typeof(to["conversation_started"])
		if type == TYPE_BOOL:
			conv_started = to["conversation_started"]
	
	if to.has("dialog_travel_stack") and typeof(to["dialog_travel_stack"]) == TYPE_ARRAY:
		
		for item in to["dialog_travel_stack"]:
			var arr_type: int = typeof(item)
			if arr_type == TYPE_STRING or arr_type == TYPE_STRING_NAME:
				new_stack.append(StringName(item))
			else:
				NFPluginGameHandler._log_msg(
						"discourse",
						"Couldn't restore dialog stack. Item in stack is not String/StringName. Item type: %s" % type_string(arr_type),
						NFPluginGameHandler._LogLevel.ERROR)
				return
	
	_clear_target_travel_stack()
	_current_uuid = new_uuid
	_next_uuid = next_uuid
	_conversation_started = conv_started
	_node_travel_stack.assign(new_stack)


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
	if path.is_empty():
		if _locale_overrides.has(dialog_id):
			_locale_overrides[dialog_id].erase(locale_code)
			if _locale_overrides[dialog_id].is_empty():
				_locale_overrides.erase(dialog_id)
		return
	
	if not _locale_overrides.has(dialog_id):
		var override: Dictionary[String, String] = {}
		_locale_overrides[dialog_id] = override
	
	_locale_overrides[dialog_id][locale_code] = path
	
	if not _id_to_data.has(dialog_id):
		return
	
	var data_path: String = _id_to_data[dialog_id]["data_path"]
	var target_path: String = _logic_overrides.get(data_path, data_path)
	
	if not _conversation_cache.is_in_cache(target_path):
		return
	
	var dialog: DiscourseDialog = _conversation_cache.get_resource(target_path)
	if dialog._has_locale(locale_code):
		_load_locale_into(dialog, locale_code, true)


## Adds an override for a specific dialog on a specific locale.[br]
## [param data] needs to be either a String or [code]null[/code]. If you pass
## [code]null[/code] to [param data] the edited dialog will be removed and the
## original used instead.
func set_dialog_text(locale_code: String, dialog_id: String, node_id: StringName, new_dialog) -> void:
	var type: int = typeof(new_dialog)
	
	locale_code = TranslationServer.standardize_locale(locale_code)
	
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
	
	if type == TYPE_NIL:
		if _dialog_edits.has(dialog_id):
			_dialog_edits[dialog_id].set_override(node_id, locale_code, null)
		return
	
	var target: DiscourseDialog.NFDialogEntryOverride = null
	
	if _dialog_edits.has(dialog_id):
		target = _dialog_edits[dialog_id]
	else:
		target = DiscourseDialog.NFDialogEntryOverride.new()
		_dialog_edits[dialog_id] = target
	
	target.set_override(node_id, locale_code, new_dialog)
	
	if _dialog_resource == null or _get_current_dialog_id() != dialog_id:
		return
	
	if _dialog_resource._dialog_overrides != target:
		_dialog_resource._dialog_overrides = target


## Adds an override for a specific set of choices on a specific locale.[br]
## [param data] needs to be either an Array, PackedStringArray or [code]null[/code].
## If you pass [code]null[/code] to [param data] the edited dialog will be 
## removed and the original used instead.
func set_choices_array(locale_code: String, dialog_id: String, node_id: StringName, new_choices) -> void:
	locale_code = TranslationServer.standardize_locale(locale_code)
	var type: int = typeof(new_choices)
	
	if locale_code.is_empty() or dialog_id.is_empty():
		NFPluginGameHandler._log_msg(
				"discourse",
				"Invalid locale code or empty dialog id on choice edit.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif type != TYPE_PACKED_STRING_ARRAY and type != TYPE_ARRAY and type != TYPE_NIL:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Can't assing choices based on a non-array.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	if type == TYPE_NIL:
		if _dialog_edits.has(dialog_id):
			_dialog_edits[dialog_id].set_override(node_id, locale_code, null)
		return
	
	var target: DiscourseDialog.NFDialogEntryOverride = null
	
	if _dialog_edits.has(dialog_id):
		target = _dialog_edits[dialog_id]
	else:
		target = DiscourseDialog.NFDialogEntryOverride.new()
		_dialog_edits[dialog_id] = target
	
	var responses: PackedStringArray = []
	
	for item in new_choices:
		var opt_type: int = typeof(item)
		if opt_type == TYPE_STRING:
			responses.append(item)
		else:
			NFPluginGameHandler._log_msg(
					"discourse",
					"Incorrect type for choice assing. Provided type: " + type_string(opt_type),
					NFPluginGameHandler._LogLevel.WARNING)
			responses.append("[INVALID FORMAT]")
	
	target.set_override(node_id, locale_code, responses)
	
	if _dialog_resource == null or _get_current_dialog_id() != dialog_id:
		return
	
	if _dialog_resource._dialog_overrides != target:
		_dialog_resource._dialog_overrides = target


## Adds an override for a specific choice on a specific locale.
func set_choice_text(locale_code: String, dialog_id: String, node_id: StringName, choice_index: int, data: String) -> void:
	locale_code = TranslationServer.standardize_locale(locale_code)
	var missing_path: bool = not _dialog_edits.has(dialog_id) or not _dialog_edits[dialog_id].has_override(node_id, locale_code)
	var not_packed_array: bool = false if missing_path else typeof(_dialog_edits[dialog_id].get_override(node_id, locale_code)) != TYPE_PACKED_STRING_ARRAY
	if missing_path:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Can't edit choice array. Ensure using edit_choices before editing single choices.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	elif not_packed_array:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Can't edit choice of non-array data.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var target: PackedStringArray = _dialog_edits[dialog_id].get_override(node_id, locale_code)
	
	if target.size() <= choice_index:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Choice index out of bounds.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	target[choice_index] = data


## Adds an override for a specific phrase's base string.[br]
## Pass [code]null[/code] to [param base] to remove the override.
func set_phrase_base_string_override(locale_code: String, dialog_id: String, phrase_id: String, base: Variant) -> void:
	var type: int = typeof(base)
	locale_code = TranslationServer.standardize_locale(locale_code)
	
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
	locale_code = TranslationServer.standardize_locale(locale_code)
	
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
	locale_code = TranslationServer.standardize_locale(locale_code)
	
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
	locale_code = TranslationServer.standardize_locale(locale_code)
	
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
	locale_code = TranslationServer.standardize_locale(locale_code)
	
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
		return _get_dialog_id(_dialog_resource.resource_path)
	return &""


func _path_has_id(path: String) -> bool:
	return _path_to_id.has(StringName(path))


# Clears the whole cache. Used on exit to prevent leaked resources
func _clear_cache() -> void:
	if _dialog_resource != null:
		_dialog_resource.parsed_dialog_cache.clear()
	_parser_cache.clear()
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
