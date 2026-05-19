class_name DialogParser
extends RefCounted
## The parser that NexusForge will use while its running on exported projects.
##
## The resources parsed by this object are [DiscourseDialog] which
## contain a different structure from the editor files.[br]
## For the editor parser see [EditorDialogParser].[br]


signal dialog_started
signal dialog_finished
@warning_ignore_start("unused_signal")
signal dialog_paused
# "dialog_text": "", "character_id": &"", "persist": false, "scene": "res://", "font": "res://", "speed": 0.0, display_name: "", "portrait_id": ""
## Emmited when a dialog event is reached.
signal dialog_reached(dialog_data: Dictionary)
#[
	#{"unlocked": false, "text": "Available", "target": "uuid"}, 
	#{"unlocked": true, "text": "Requires more strength", "target": "uuid"}]
signal options_reached(options: Array[Dictionary])
@warning_ignore_restore("unused_signal")


enum NodeTypes { 
	ENTRY = 0, ## The entry for a conversation.
	DIALOG = 1, ## A generic dialog node
	OPTIONS = 2, ## A collection of dialog options.
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
	VARIABLE_GET = 15,
	ANCHOR_POINTER = 16, ## A pointer that directs to a SHORTCUT_OUT.
	ANCHOR = 17, ## A node for SHORTCUT_IN to point to.
	DIALOG_END = 18,
	DIALOG_MERGE = 19,
	COMMENT = 20, ## A node that exists to explain something.
	SETTINGS_CHARACTER = 21,
	SETTINGS_DIALOG = 22,
	SETTINGS_OPTION = 23,
	RANDOM_VALUE = 24,
	RESOURCE = 25,
	DATA_EVENT = 26,
	LOCALIZED_TEXT = 27,
	METADATA = 28}

const RANDOM_DEFAULT_WEIGHT: int = 1
const FLOAT_SNAP: float = 0.01

var API: DiscourseAPI = null
var locale: String = "en":
	set(new_locale):
		locale = TranslationServer.standardize_locale(new_locale.strip_edges())

# Maps UUID: CustomID
#var _dialog_id_map: Dictionary[StringName, StringName] = {}

var _dialog_resource: DiscourseDialog = null:
	set(d):
		_dialog_resource = d
		_dialog_resource_set(d)
var _conversation_started: bool = false
var _next_uuid: String = ""
var _conversation_cache: ResourceCache = null
var _parser_cache: Cache = null

var _path_to_id: Dictionary[StringName, StringName] = {}
# {"dialogs.village.mayor": {"data_path": "res://asdas", "locale_file": "---.json"}
var _id_to_data: Dictionary[StringName, Dictionary] = {}

var _logic_overrides: Dictionary[String, String] = {}
var _locale_overrides: Dictionary = {
	#"dialog_id": {"locale_code": "new_path"}
	}
var _dialog_edits: Dictionary = {
	"dialogs.village.greet": {
		"en": {
			"NodeID": "Hello there!"
		}
	}
}

## The [DialogParser] that NexusForge will use while its running on exported projects.
##
## On an exported project the resources parsed will be [ReleaseDiscourseDialog]
## which contain a different structure from the editor files.[br]
## For the editor parser see [EditorDialogParser].[br]

## The resource containing the localizable data of a dialog.
#var localization: DiscourseDialogLocale = null 
# Example of how data will be structured in the dialog resource (Release).
#const store = {
		#UUID - NodeTypes.DIALOG: { # <- UUUID used to access localization if text_source is empty
			#"node_type": NodeTypes.DIALOG,
			#"character_id": &"",
			#"persist": true,
			#"character_settings": {},
			#"dialog_settings": {},
			#"text_source": &"", # External key source for dialog
			#"next_node": &""},
		#NodeTypes.OPTIONS: {
			#"node_type": null,
			#"options": [
				#{"next_node": "", "settings": {"available": &"", "locked": &"", "lock_hint": &""}},
				#{"next_node": "", "settings": {}}]},
		#NodeTypes.BRANCH: {
			#"node_type": null,
			#"result": &"", # What node provides the result
			#"case_true": &"",
			#"case_false": &""},
		#NodeTypes.CONDITION_SELECT: {
			#"node_type": null,
			#"result": &"", # What node provides the result
			#"true_value": &"",
			#"false_value": &""},
		#NodeTypes.COMPARATION: {
			#"node_type": null,
			#"operator": OP_EQUAL,
			#"value_a": &"",
			#"value_b": &""},
		#NodeTypes.EVENT: {
			#"variable_path": &"",
			#"variable": &"",
			#"value": &"",
			#"callable": &"",
			#"signal": &"",
			#"next_node": &""},
		#NodeTypes.MATCH: {
			#"case_default": &"",
			#"match_value": &"",
			#"cases": [
				#{"value": 0, "next_node": &""},
				#{"value": "X3", "next_node": &""}]},
		#NodeTypes.PAUSE: {
			#"next_node": &""},
		#NodeTypes.RANDOM: {
			#"default_override": &"",
			#"options": [
				#{"target": &"", "weight": &""}]},
		#NodeTypes.TYPE_GUARD: {
			#"type": TYPE_INT,
			#"value": &"",
			#"fallback": 100},
		#NodeTypes.VALUE: {
			#"value": 50},
		#NodeTypes.SIGNAL: {
			#"signal": &"",
			#"arguments": [&"", &""]}, # Sources for the arguments
		#NodeTypes.CALLABLE: {
			#"method": &"",
			#"arguments": [&""]},
		#NodeTypes.CALLABLE_RETURN: {
			#"method": &"",
			#"arguments": [&"", &""]},
		#NodeTypes.VARIABLE_GET: {
			#"path": &"",
			#"variable": &""},
		#NodeTypes.RANDOM_VALUE: {
			#"random_type": TYPE_BOOL,
			#"min_value": 0.0,
			#"max_value": 100.0,
			#"min_source": &"",
			#"max_source": &""},
		#NodeTypes.RESOURCE: {
			#"uuid": ""},
		#NodeTypes.DATA_EVENT: {
			#"variable_path": &"",
			#"variable": &"",
			#"value": &"",
			#"callable": &"",
			#"signal": &"",
			#"data_source": &""}, # Where is the data to get.
		#NodeTypes.LOCALIZED_TEXT: {
			#"type": NodeTypes.LOCALIZED_TEXT,
			#"text": &""}} # Key to localization


func _init() -> void:
	_conversation_cache = ResourceCache.new()
	_parser_cache = Cache.new()
	API = DiscourseAPI.new()


func generate_locale_map() -> void:
	var file: FileAccess = FileAccess.open(
			StringUtils.make_path([
				ProjectSettings.get_setting(
					EditorNFPlugin.get_project_settings_path("discourse"),
					"res://localization/"),
				"dialog_locale_map.json"]),
			FileAccess.READ)
	
	if file == null:
		return
	
	var data = JSON.parse_string(file.get_as_text())
	
	if typeof(data) != TYPE_DICTIONARY or not data.has_all(["file_to_id", "id_to_locale_file"]):
		return
	
	for file_path in data.keys():
		if typeof(file_path) != TYPE_STRING or not data["id_to_locale_file"].has(file_path) or typeof(data["id_to_locale_file"][file_path]) != TYPE_STRING:
			continue
		var file_id: String = data["file_to_id"][file_path]
		_path_to_id[file_path] = file_id
		_id_to_data[data["file_to_id"][file_id]] = data["id_to_locale_file"][file_id]


## Function to parse the dialog in a custom manner. Modify if needed.
func _parse_dialog(dialog_id: String, dialog: String) -> String:
	var DUUID: String = dialog_id# + "/" + language + "_" + region
	# (UUID)/en_US
	if _dialog_resource.parsed_dialog_cache.is_in_cache(DUUID):
		var cached_data: ParsedDialog = _dialog_resource.parsed_dialog_cache.get_cache(DUUID)
		return cached_data.get_dialog()
	
	var parsed: ParsedDialog = ParsedDialog.new()
	#parsed.language = language
	#parsed.region = region
	parsed.dialog = dialog
	
	var functions_processed: PackedStringArray = []
	var variables_processed: PackedStringArray = []
	var phrases_processed: PackedStringArray = []
	var random_processed: PackedStringArray = []
	
	var function_regex: RegEx = RegEx.new()
	var variable_regex: RegEx = RegEx.new()
	var phrase_regex: RegEx = RegEx.new()
	var random_regex: RegEx = RegEx.new()
	function_regex.compile("\\{\\![^\\s\\}]+\\}")
	variable_regex.compile("\\{\\$[^\\s\\}]+\\}")
	phrase_regex.compile("\\{\\&[^\\s\\}]+\\}")
	random_regex.compile("\\{\\?[^\\}]+\\}")
	
	for rgx_rand_result in random_regex.search_all(dialog):
		if random_processed.has(rgx_rand_result.get_string()):
			continue
		
		random_processed.append(rgx_rand_result.get_string())
		
		var clean_string: String = rgx_rand_result.get_string().trim_prefix("{").trim_suffix("}")
		var options: Array[String] = []
		options.assign(clean_string.trim_prefix("?").split("|", false))
		
		parsed.set_format_callable(
			clean_string,
			options.pick_random)
	
	# Searching for function calls.
	
	for rgx_func_result in function_regex.search_all(dialog):
		if functions_processed.has(rgx_func_result.get_string()):
			continue
		
		functions_processed.append(rgx_func_result.get_string())
		
		# {!get_name|a,b} -> !get_name|a,b
		var clean_string: String = rgx_func_result.get_string().trim_prefix("{").trim_suffix("}")
		
		parsed.set_format_callable(
				clean_string,
				_build_callable_for_method(clean_string.trim_prefix("!")))
		
	# Processing variables
	
	for rgx_var_result in variable_regex.search_all(dialog):
		if variables_processed.has(rgx_var_result.get_string()):
			continue
		
		var key: String = rgx_var_result.get_string().trim_prefix("{").trim_suffix("}")
		variables_processed.append(rgx_var_result.get_string())
		
		var callable: Callable = _build_callable_for_variable(key.trim_prefix("{$").trim_suffix("}"))
		
		parsed.set_format_callable(
				key,
				_build_callable_for_variable(key.trim_prefix("$")))
	
	# Revealing the phrase text.
	for rgx_phrase_result in phrase_regex.search_all(dialog):
		if phrases_processed.has(rgx_phrase_result.get_string()):
			continue
		var phrase_key: String = rgx_phrase_result.get_string().trim_prefix("{").trim_suffix("}")
		var prefix_trim_key: String = phrase_key.trim_prefix("&")
		phrases_processed.append(phrase_key)
		
		#var phrase: String = _dialog_resource.get_localized_string(
				#prefix_trim_key,
				#language,
				#region)
		#var phrase: String = localization.get_format_string_text(
		var phrase: String = _dialog_resource._active_locale.get_format_string_text(
				_dialog_resource.localization_uuid,
				prefix_trim_key)
		
		var argument_cases: Dictionary[String, Dictionary] = _dialog_resource._active_locale.get_format_string_args(
			_dialog_resource.localization_uuid,
			prefix_trim_key)
		
		parsed.create_format_phrase(phrase_key, phrase, argument_cases)
		
		for random_section in random_regex.search_all(phrase):
			var replace: String = random_section.get_string().trim_prefix("{").trim_suffix("}")
			var items: Array[String] = []
			items.assign(replace.trim_prefix("?").split("|", false))
			parsed.set_format_phrase_callable(
					phrase_key,
					replace,
					items.pick_random)
		
		for function_section in function_regex.search_all(phrase):
		#{!askdjal}
			var replace: String = function_section.get_string().trim_prefix("{").trim_suffix("}")
			parsed.set_format_phrase_callable(
					phrase_key,
					replace,
					_build_callable_for_method(replace.trim_prefix("!")))
		
		for variable_section in variable_regex.search_all(phrase):
			var replace: String = variable_section.get_string().trim_prefix("{").trim_suffix("}")
			parsed.set_format_phrase_callable(
					phrase_key,
					replace,
					_build_callable_for_variable(replace.trim_prefix("$")))
	
	_dialog_resource.parsed_dialog_cache.cache_data(
		DUUID,
		parsed)
	
	return parsed.get_dialog()


func _build_callable_for_variable(text: String) -> Callable:
	var paths: PackedStringArray = text.trim_prefix("$").rsplit("/", false, 1)
	var callable: Callable = Callable(
			NexusForge.Blackboard.get_variable.bind(
					paths[0],
					StringName(paths[1])))
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
		callable = callable.bindv(final_arguments)
	
	return callable


func _can_compare(a, b) -> bool:
	var type_a: int = typeof(a)
	var type_b: int = typeof(b)
	
	if type_a == type_b:
		return true
	elif type_a == TYPE_INT or type_a == TYPE_FLOAT:
		return type_b == TYPE_INT or type_b == TYPE_FLOAT
	else:
		return false


#region Override
## Returns the UUID of the next dialog.
func _process_logic(uuid: StringName) -> String:
	if uuid.is_empty():
		return ""
	
	var dialog_id: String = _path_to_id[_dialog_resource.resource_path]
	var data: Dictionary = _dialog_resource.dialog_nodes[uuid]
	match data["node_type"]:
		NodeTypes.ENTRY:
			return _process_logic(data["next_node"])
		NodeTypes.DIALOG:
			var font: String = _get_data(data["dialog_settings"]["font_resource"], "")
			var scene: String = _get_data(data["dialog_settings"]["dialog_scene"], "")
			var speed: float = _get_data(data["dialog_settings"]["dialog_speed"], 0.0)
			var display_name: String = _get_data(data["character_settings"]["display_name"], "")
			var portrait_id: String = _get_data(data["character_settings"]["portrait_id"], "")
			var metadata: Dictionary[String, Variant] = {}
			
			if DictUtils.has_nested_path(data, ["dialog_settings", "metadata"]):
				for meta_key in data["dialog_settings"]["metadata"].keys():
					metadata[meta_key] = _get_data(data["dialog_settings"]["metadata"][meta_key])
			
			if data["text_source"].is_empty():
				dialog_reached.emit({
					"dialog_text": _parse_dialog(String(uuid), _dialog_resource._get_text(dialog_id, uuid)),
					"character_id": data["character_id"],
					"persist": data["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id,
					"metadata": metadata})
			else:
				dialog_reached.emit({
					"dialog_text": _parse_dialog(String(uuid), _get_data(data["text_source"], "")),
					"character_id": data["character_id"],
					"persist": data["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id,
					"metadata": metadata})
			return data["next_node"]
		NodeTypes.OPTIONS:
			var available_options: Array[Dictionary] = []
			var localized_options: PackedStringArray = _dialog_resource._get_choices(dialog_id, uuid)#_get_choices_for(dialog_id, uuid)
			var target_size: int = data["options"].size()
			
			if localized_options.size() != target_size:
				localized_options.resize(target_size)
			
			var idx: int = -1
			var option_duuid: String = ""
			for option:Dictionary in data["options"]:
				idx += 1
				option_duuid = String(uuid) + "_" + str(idx)
				
				if option["settings"].is_empty():
					option_duuid += "_unlocked"
					available_options.append(
						{
							"unlocked": true,
							"text": _parse_dialog(option_duuid, localized_options[idx]),
							"target": option["next_node"],
							"metadata": {}})
				else:
					var opt_settings: Dictionary = option["settings"]
					var show: bool = _get_data(opt_settings["available"], true)
				
					if not show:
						continue
					var unlocked: bool = _get_data(opt_settings["unlocked"], true)
					var text: String = localized_options[idx]
					var metadata: Dictionary[String, Variant] = {}
					
					if opt_settings.has("metadata"):
						for meta_key in opt_settings["metadata"].keys():
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
						"text": _parse_dialog(option_duuid, text),
						"target": option["next_node"],
						"metadata": metadata})
			
			options_reached.emit(available_options)
			return uuid
		NodeTypes.BRANCH:
			var use_a: bool = _get_data(data["result"], true)
			if use_a:
				return _process_logic(data["case_true"])
			else:
				return _process_logic(data["case_false"])
		NodeTypes.EVENT:
			if not data["variable_path"].is_empty() and not data["value"].is_empty():
				NexusForge.Blackboard.set_variable(
						data["variable_path"],
						data["variable"],
						_get_data(data["value"]))
			if not data["callable"].is_empty():
				var call_data: Dictionary = _dialog_resource.dialog_nodes[data["callable"]]
				var call_args: Array = []
				
				for argument_key in call_data["arguments"]:
					call_args.append(_get_data(argument_key))
				
				NexusForge.Discourse.API.callv(
						call_data["method"],
						call_args)
			
			if not data["signal"].is_empty():
				var signal_data: Dictionary = _dialog_resource.dialog_nodes[data["signal"]]
				var signal_args: Array = []
				
				for argument_key in signal_data["arguments"]:
					signal_args.append(_get_data(argument_key))
				
				NexusForge.Discourse.API.emit_signal(
						data["signal"],
						signal_args)
				
			return _process_logic(data["next_node"])
		NodeTypes.MATCH:
			var match_data = _get_data(data["match_value"])
			for case:Dictionary in data["cases"]:
				if case["value"] == match_data:
					return _process_logic(case["next_node"])
			return _process_logic(data["case_default"])
		NodeTypes.PAUSE:
			dialog_paused.emit()
			return data["next_node"]
		NodeTypes.RANDOM:
			var total_weight: int = 0
			var choices: Array[Dictionary] = []
			
			for choice:Dictionary in data["options"]:
				var weight: int = RANDOM_DEFAULT_WEIGHT if choice["weight_override"].is_empty() else _get_data(choice["weight_override"])
				if weight == 0:
					continue
				choices.append({
					"next": choice["target"],
					"weight": weight})
				total_weight += weight
			
			if choices.is_empty():
				return ""
			
			choices.sort_custom(func(a, b): return a["weight"] > b["weight"])
			var random_select: int = randi_range(1, total_weight)
			
			var current_weight: int = 0
			for choice in choices:
				current_weight += choice["weight"]
				if random_select <= current_weight:
					return _process_logic(choice["next"])
			return _process_logic(choices[-1]["next"]) # In case of loop error
		NodeTypes.DIALOG_END:
			return ""
		_:
			return ""


func _get_data(uuid: StringName, fallback = null) -> Variant:
	if _dialog_resource == null or not _dialog_resource.dialog_nodes.has(uuid):
		return fallback
	var data: Dictionary = _dialog_resource.node_logic[uuid]
	
	match data["node_type"]:
		NodeTypes.VALUE:
			return data["value"]
		NodeTypes.RANDOM_VALUE:
			match data["random_type"]:
				TYPE_INT:
					var min_value: int = data["min_value"] if data["min_override"].is_empty() else _get_data(data["min_override"])
					var max_value: int = data["max_value"] if data["max_override"].is_empty() else _get_data(data["max_override"])
					return randi_range(min_value, max_value)
				TYPE_FLOAT:
					var min_value: float = data["min_value"] if data["min_override"].is_empty() else _get_data(data["min_override"])
					var max_value: float = data["max_value"] if data["max_override"].is_empty() else _get_data(data["max_override"])
					return snappedf(
							randf_range(
									min_value,
									max_value),
							FLOAT_SNAP)
				TYPE_BOOL:
					var true_probability: int = data["min_value"] if data["min_override"].is_empty() else _get_data(data["min_override"], 100)
					if true_probability == 0:
						return false
					elif true_probability == 100:
						return true
					else:
						var true_range: int = randi_range(
								1,
								100)
						return true_range <= true_probability
				_:
					return null
		NodeTypes.TYPE_GUARD:
			var guard_data = _get_data(data["value"])
			if typeof(guard_data) == typeof(data["type"]):
				return guard_data
			else:
				return data["fallback"]
		NodeTypes.VARIABLE_GET:
			return NexusForge.Blackboard.get_variable(data["path"], data["variable"])
		NodeTypes.CALLABLE_RETURN:
			var method: Callable = Callable(NexusForge.Discourse.API, data["method"])
			var args: Array = []
			for arg:StringName in data["arguments"]:
				args.append(_get_data(arg))
			return method.callv(args)
		NodeTypes.DATA_EVENT:
			if not data["variable_path"].is_empty() and not data["variable"].is_empty() and not data["value"].is_empty():
				NexusForge.Blackboard.set_variable(
						data["variable_path"],
						data["variable"],
						_get_data(data["value"]))
			if not data["callable"].is_empty():
				var call_data: Dictionary = _dialog_resource.dialog_nodes[data["callable"]]
				var call_args: Array = []
				
				for argument_id in call_data["arguments"]:
					call_args.append(_get_data(argument_id))
				
				NexusForge.Discourse.API.callv(
						call_data["method"],
						call_args)
			
			if not data["signal"].is_empty():
				var signal_data: Dictionary = _dialog_resource.dialog_nodes[data["signal"]]
				var signal_args: Array = []
				
				for argument_key in signal_data["arguments"]:
					signal_args.append(_get_data(argument_key))
				
				NexusForge.Discourse.API.emit_signal(
						data["signal"],
						signal_args)
			return _get_data(data["data_source"])
		NodeTypes.LOCALIZED_TEXT:
			return _dialog_resource._get_text(_path_to_id[_dialog_resource.resource_path], uuid)
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


func _load_locale(locale_code: String) -> void:
	var locale_id: String = DictUtils.get_nested_value(
			_path_to_id,
			[_dialog_resource.resource_path],
			"")
	
	_dialog_resource._set_locale(locale_code)
	
	if DictUtils.has_nested_path(_locale_overrides, [locale_id, locale]):
		#var res: DiscourseDialogLocale = _load_json_locale(_locale_overrides[locale_id][locale])
		var file: FileAccess = FileAccess.open(
				_locale_overrides[locale_id][locale],
				FileAccess.READ)
	
		if file != null:
			var res: DiscourseDialogLocale = DiscourseDialogLocale.new_from_json(file.get_as_text())
			res.json_file = _locale_overrides[locale_id][locale].get_file()
			_dialog_resource._store_locale(locale_code, res)
			return
	
	var base_locale_path: String = ""
	
	# Register modded conversations
	if _dialog_resource is ModDiscourseDialog:
		base_locale_path = _dialog_resource.localization_folder
		if not _path_to_id.has(StringName(_dialog_resource.resource_path)):
			var path_strn: StringName = StringName(_dialog_resource.resource_path)
			var id: StringName = StringName(_dialog_resource.dialog_id)
			_path_to_id[path_strn] = id
			_id_to_data[id] = {
				"data_path": path_strn,
				"locale_file": _dialog_resource.resource_path.to_lower().md5_text().substr(0, 12) + "-" + _dialog_resource.resource_path.get_file().get_basename() + ".json"}
	else:
		base_locale_path = ProjectSettings.get_setting(
					"nexus_forge/localization_directory",
					"res://localization/")
	
	var localization_filename: String = _id_to_data[locale_id]["locale_file"]
	var hash_slice: String = localization_filename.substr(0, 2)
	
	var locale_path: String = StringUtils.make_path([
			base_locale_path,
			locale_code,
			hash_slice,
			localization_filename])
	
	var file: FileAccess = FileAccess.open(locale_path, FileAccess.READ)
	
	if file != null:
		var res: DiscourseDialogLocale = DiscourseDialogLocale.new_from_json(file.get_as_text())
		res.json_file = localization_filename
		_dialog_resource._store_locale(locale_code, res)


func _dialog_resource_set(new_resource: DiscourseDialog) -> void:
	if new_resource == null:
		return
		
	if new_resource._has_locale(locale):
		new_resource._set_locale(locale)
	else:
		_load_locale(locale)
#endregion


## Returns [code]true[/code] if a conversation is loaded and active.
func is_dialog_active() -> bool:
	return _dialog_resource != null and _conversation_started


## Loads a dialog and sets the dialog ID to the start of the conversation
## unless a valid [param starting_id] is given.[br]
## Returns [code]true[/code] if the dialog was loaded.
func load_dialog(path: String, starting_id: String = "") -> bool:
	var target_path: String = _logic_overrides[path] if _logic_overrides.has(path) else path
	
	if _conversation_cache.is_in_cache(target_path):
		var dialog_id: String = DictUtils.get_nested_value(_path_to_id, [path], "")
		var data: DiscourseDialog = _conversation_cache.get_resource(target_path)
		var locale_data: DiscourseDialogLocale = data._get_locale(locale)
		var reload_locale: bool = locale_data != null and locale_data.json_file != _id_to_data[dialog_id]["locale_file"]
		
		_dialog_resource = data
		
		if _dialog_edits.has(dialog_id) and _dialog_resource.dialog_overrides != _dialog_edits[dialog_id]:
			_dialog_resource.dialog_overrides = _dialog_edits[dialog_id]
		
		if reload_locale:
			_load_locale(locale)
	else:
		var res: Resource = load(target_path)
		var id: String = DictUtils.get_nested_value(_path_to_id, [path], "")
		
		if res == null or res is not DiscourseDialog:
			_next_uuid = ""
			_dialog_resource = null
			return false
			
		if _dialog_edits.has(id):
			res.dialog_overrides = _dialog_edits[id]
		_conversation_cache.cache_resource(res)
		_dialog_resource = res
	
	if _dialog_resource.id_map.has(starting_id):
		_next_uuid = _dialog_resource.id_map[starting_id]
	elif _dialog_resource.dialog_nodes.has(starting_id):
		_next_uuid = starting_id
	else:
		_next_uuid = _dialog_resource.entry_node
	
	return true


## Sets the dialog to be at a specific point. [param id] can be the dialog
## id or the UUID. If invalid it'll set the dialog to be at the beggining.
func set_dialog_id(id: String) -> void:
	if _dialog_resource == null:
		return
	
	if _dialog_resource.id_map.has(id):
		_next_uuid = _dialog_resource.id_map[id]
	elif _dialog_resource.dialog_nodes.has(id):
		_next_uuid = id
	else:
		_next_uuid = _dialog_resource.entry_node


## Progresses the conversation
func next_dialog() -> void:
	if _dialog_resource == null:
		return
	
	if not _conversation_started:
		_conversation_started = true
		dialog_started.emit()
	
	_next_uuid = _process_logic(_next_uuid)
	
	if _next_uuid.is_empty():
		_conversation_started = false
		_next_uuid = _dialog_resource.entry_node
		dialog_finished.emit()


## Overrides the logic file. When a dialog data is loaded, the file provided in
## [param override_path] will be used instead. This does NOT change the localization
## file used.
func override_dialog_data(dialog_id: String, override_path: String) -> void:
	override_path = override_path.strip_edges().simplify_path()
	
	if override_path.is_empty():
		_logic_overrides.erase(dialog_id)
	else:
		_logic_overrides[_id_to_data[dialog_id]["data_path"]] = override_path


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
	
	DictUtils.set_nested_value(
			_locale_overrides,
			[dialog_id, locale_code],
			path)


## Adds an override for a specific dialog on a specific locale.[br]
## Data needs to be either a PackedStringArray or a string. If you pass
## [code]null[/code] to [param data] the edited dialog will be removed and the
## original used instead.
func edit_dialog(locale_code: String, dialog_id: String, node_id: String, data) -> void:
	var type: int = typeof(data)
	if type == TYPE_NIL:
		if DictUtils.has_nested_path(_dialog_edits, [dialog_id, locale_code, node_id]):
			_dialog_edits[dialog_id][locale_code].erase(node_id)
		return
	elif type != TYPE_STRING and type != TYPE_PACKED_STRING_ARRAY:
		return
	
	if not _dialog_edits.has(dialog_id):
		_dialog_edits[dialog_id] = {}
		
	if not _dialog_edits[dialog_id].has(locale_code):
		_dialog_edits[dialog_id][locale_code] = {}
	
	if type == TYPE_STRING:
		_dialog_edits[dialog_id][locale_code][node_id] = data
	elif type == TYPE_PACKED_STRING_ARRAY:
		var responses: PackedStringArray = []
		for item in data:
			if typeof(item) == TYPE_STRING:
				responses.append(item)
			else:
				responses.append(str(data))
		_dialog_edits[dialog_id][locale_code][node_id] = responses


func edit_choice(dialog_id: String, locale_code: String, node_id: String, choice_index: int, data: String) -> void:
	if not _dialog_edits.has(dialog_id):
		_dialog_edits[dialog_id] = {}
		
	if not _dialog_edits[dialog_id].has(locale_code):
		_dialog_edits[dialog_id][locale_code] = {}
	
	if not _dialog_edits[dialog_id][locale_code].has(node_id) or not typeof(_dialog_edits[dialog_id][locale_code][node_id]) == TYPE_PACKED_STRING_ARRAY:
		_dialog_edits[dialog_id][locale_code][node_id] = PackedStringArray()
	
	var target: PackedStringArray = _dialog_edits[dialog_id][locale_code][node_id]
	
	if target.size() < choice_index + 1:
		target.resize(choice_index + 1)
	
	target[choice_index] = data


# Clears the whole cache. Used on exit to prevent leaked resources
func _clear_cache() -> void:
	if _dialog_resource != null:
		_dialog_resource.parsed_dialog_cache.clear()
	_parser_cache.clear()
	_conversation_cache.clear()
