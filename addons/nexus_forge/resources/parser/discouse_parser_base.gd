class_name DialogParser
extends RefCounted
## The base class for Discourse dialog parsers.


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
	LOCALIZED_TEXT = 27}

const RANDOM_DEFAULT_WEIGHT: int = 1
const FLOAT_SNAP: float = 0.01

var API: DiscourseAPI = null
var language: String = "en":
	set(l):
		language = l
		_locale_set(language, region)
var region: String = "base":
	set(new_region):
		region = "base" if new_region.is_empty() else new_region
		_locale_set(language, region)

# Maps UUID: CustomID
var _dialog_id_map: Dictionary[String, StringName] = {}

var _dialog_resource: DiscourseDialog = null:
	set(d):
		_dialog_resource = d
		_dialog_resource_set(d)
var _conversation_started: bool = false
var _next_uuid: String = ""
var _conversation_cache: ResourceCache = null
var _parser_cache: Cache = null


## Call instead of new() to get a proper parser.
static func new_parser() -> DialogParser:
	if OS.has_feature("editor"):
		return EditorDialogParser.new()
	else:
		return ReleaseDialogParser.new()


func _init() -> void:
	_conversation_cache = ResourceCache.new()
	_parser_cache = Cache.new()
	API = DiscourseAPI.new()


## Function to parse the dialog in a custom manner. Modify if needed.
func _parse_dialog(dialog_id: String, dialog: String) -> String:
	var DUUID: String = dialog_id + "/" + language + "_" + region
	# (UUID)/en_US
	if _dialog_resource.parsed_dialog_cache.is_in_cache(DUUID):
		var cached_data: ParsedDialog = _dialog_resource.parsed_dialog_cache.get_cache(DUUID)
		return cached_data.get_dialog()
	
	var parsed: ParsedDialog = ParsedDialog.new()
	parsed.language = language
	parsed.region = region
	parsed.dialog = dialog
	var functions_processed: PackedStringArray = []
	var variables_processed: PackedStringArray = []
	var phrases_processed: PackedStringArray = []
	
	var function_regex: RegEx = RegEx.new()
	var variable_regex: RegEx = RegEx.new()
	var phrase_regex: RegEx = RegEx.new()
	function_regex.compile("\\{\\!([^|\\s]+)(?:\\|([^}\\s]+))?\\}")
	variable_regex.compile("\\{(\\$[^\\s\\}]+)\\}")
	phrase_regex.compile("\\{\\&([^\\s\\}]+)\\}")
	
	# Searching for function calls.
	
	for rgx_func_result in function_regex.search_all(dialog):
		if functions_processed.has(rgx_func_result.get_string()):
			continue
		
		functions_processed.append(rgx_func_result.get_string())
		
		#var replace: String = rgx_func_result.get_string().trim_prefix("{").trim_suffix("}")
		#var method: String = rgx_func_result.get_string(1)
		var method_args: PackedStringArray = []
		var string_args: String = rgx_func_result.get_string(2)
		if not string_args.is_empty():
			method_args = string_args.split(",", false)
		
		#var replacement: String = str(NexusForge.Discourse.API.callv(
				#StringName(method), method_args))
		
		parsed.set_format_callable(
				rgx_func_result.get_string(1),
				_build_callable_for_format(rgx_func_result.get_string(1)),
				method_args)
		
	
	# Processing variables
	
	for rgx_var_result in variable_regex.search_all(dialog):
		var key: String = rgx_var_result.get_string(1)
		if variables_processed.has(key):
			continue
		
		variables_processed.append(key)
		#var var_val: String = str(
				#NexusForge.Variables.get_variable(key))
		
		parsed.set_format_callable(
				key,
				_build_callable_for_format(key))
		
	
	# Revealing the phrase text.
	for rgx_phrase_result in phrase_regex.search_all(dialog):
		var phrase_key: String = rgx_phrase_result.get_string(1)
		if phrases_processed.has(phrase_key):
			continue
		var format_replace = "&" + phrase_key
		phrases_processed.append(phrase_key)
		
		var phrase: String = _dialog_resource.get_localized_string(
				phrase_key,
				language,
				region)
		
		var argument_cases: Dictionary[String, Dictionary] = _dialog_resource.get_localized_arguments(
				phrase_key,
				language,
				region)
		
		parsed.create_format_phrase(format_replace, phrase, argument_cases)
		
		for function_section in function_regex.search_all(phrase):
		#{!askdjal}
			var replace: String = function_section.get_string(1)
			parsed.set_format_phrase_callable(
					format_replace,
					replace,
					_build_callable_for_format(replace))
		
		for variable_section in variable_regex.search_all(phrase):
			var replace: String = variable_section.get_string(1)
			parsed.set_format_phrase_callable(
					format_replace,
					replace,
					_build_callable_for_format(replace))
	
	_dialog_resource.parsed_dialog_cache.cache_data(
		DUUID,
		parsed)
	
	return parsed.get_dialog()


func _build_callable_for_format(text: String) -> Callable:
	# Must pass an argument that starts with ! or $
	if text.begins_with("$"):
		var a: Callable = Callable(NexusForge.Blackboard.get_variable.bind(text.trim_prefix("$")))
		return a
	else: # begins with !
		var parts: PackedStringArray = text.split("|", false, 1)
		var method: StringName = StringName(parts[0].trim_prefix("!"))
		var arguments: PackedStringArray = []
		
		if 1 < parts.size():
			arguments = parts[1].split(",")
		
		var final_arguments: Array = []
		
		for argument in arguments:
			if argument.begins_with("$") or argument.begins_with("!"):
				final_arguments.append(_build_callable_for_format(argument))
			else:
				final_arguments.append(argument)
		
		return Callable(NexusForge.Discourse.API, method).bind(final_arguments)


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
func _process_logic(_uuid: StringName) -> String:
	return ""
	#if uuid.is_empty():
		#return ""
	#
	#var data: Dictionary = _dialog_resource.get_node_data(uuid, language, region)
	#
	#match data["node_type"]:
		#NODE_TYPES.ENTRY:
			#return _process_logic(
					#data["output_connections"]["next_node"]["target_node_uuid"])
		#NODE_TYPES.DIALOG:
			#var font: String = ""
			#var scene: String = ""
			#var speed: float = 0.0
			#if data["input_connections"]["dialog_settings"]["target_node_uuid"] != "":
				#var settings: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["dialog_settings"]["target_node_uuid"], language, region)
				#if settings["font_resource"]["target_node_uuid"] != "":
					#font = _get_data(settings["font_resource"]["target_node_uuid"])
				#if settings["dialog_scene"]["target_node_uuid"] != "":
					#scene = _get_data(settings["dialog_scene"]["target_node_uuid"])
				#if settings["dialog_speed"]["target_node_uuid"] != "":
					#speed = _get_data(settings["dialog_speed"]["target_node_uuid"])
			#
			#if data["input_connections"]["dialog_text_source"]["target_node_uuid"] == "":
				#dialog_reached.emit({
					#"dialog_text": _parse_dialog(uuid, data["dialog_text"]),
					#"font": font,
					#"scene": scene,
					#"speed": speed})
			#else:
				#dialog_reached.emit({
					#"dialog_text": _parse_dialog(uuid, _get_data(data["input_connections"]["dialog_text_source"]["target_node_uuid"])),
					#"font": font,
					#"scene": scene,
					#"speed": speed})
			#return data["output_connections"]["next_node"]["target_node_uuid"]
		#NODE_TYPES.OPTIONS:
			#var available_options: Array[Dictionary] = []
			#
			#for option:Dictionary in data["options"]:
				#if option["input_connections"]["settings"]["target_node_uuid"] != "":
					#var opt_settings: Dictionary = _dialog_resource.get_node_data(option["input_connections"]["settings"]["target_node_uuid"], "common")
					#var show: bool = true if opt_settings["option_available"]["target_node_uuid"] == "" else _get_bool_result(opt_settings["option_available"]["target_node_uuid"])
				#
					#if not show:
						#continue
					#var unlocked: bool = true if opt_settings["option_unlocked"]["target_node_uuid"] == "" else _get_bool_result(opt_settings["option_unlocked"]["target_node_uuid"])
					#available_options.append({
						#"unlocked": unlocked,
						#"text": _parse_dialog(uuid, option["option_text"] if unlocked else _get_data(opt_settings["locked_hint"]["target_node_uuid"])),
						#"target": option["output_connections"]["next_node"]["target_node_uuid"]})
				#else:
					#available_options.append(
						#{
							#"unlocked": true,
							#"text": _parse_dialog(uuid, option["option_text"]),
							#"target": option["output_connections"]["next_node"]["target_node_uuid"]})
			#
			#options_reached.emit(available_options)
			#return uuid
		#NODE_TYPES.BRANCH:
			#var use_a: bool = _get_bool_result(data["input_connections"]["path_direction"]["target_node_uuid"])
			#if use_a:
				#return _process_logic(
						#data["output_connections"]["next_node_true"]["target_node_uuid"])
			#else:
				#return _process_logic(
						#data["output_connections"]["next_node_false"]["target_node_uuid"])
		#NODE_TYPES.EVENT:
			#if data["variable_path"] != "" and data["input_connections"]["variable_value"]["target_node_uuid"] != "":
				#NexusForge.Variables.set_variable(
						#data["variable_path"],
						#_get_data(data["input_connections"]["variable_value"]["target_node_uuid"]))
			#if data["input_connections"]["callable"]["target_node_uuid"] != "":
				#var call_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["callable"]["target_node_uuid"], language, region)
				#var call_args: Array = []
				#
				#for arg_connection in call_data["arguments"]:
					#call_args.append(
							#_get_data(arg_connection["target_node_uuid"]))
				#
				#NexusForge.Discourse.API.callv(
						#data["method"],
						#call_args)
			#
			#if data["input_connections"]["signal"]["target_node_uuid"] != "":
				#var signal_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["signal"]["target_node_uuid"], language, region)
				#var signal_args: Array = []
				#
				#for arg_connection in signal_data["arguments"]:
					#signal_args.append(_get_data(arg_connection["target_node_uuid"]))
				#
				#NexusForge.Discourse.API.emit_signal(
						#data["signal"],
						#signal_args)
				#
			#return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		#NODE_TYPES.MATCH:
			#var data_comp = _get_data(data["input_connections"]["match_value_source"]["target_node_uuid"])
			#for case:Dictionary in data["cases"]:
				#if case["value"] == data_comp:
					#return _process_logic(case["output_connections"]["next_node"]["target_node_uuid"])
			#return _process_logic(data["output_connections"]["default"]["target_node_uuid"])
		#NODE_TYPES.PAUSE:
			#dialog_paused.emit()
			#return data["output_connections"]["next_node"]["target_node_uuid"]
		#NODE_TYPES.RANDOM:
			#var defalut_weight: int = preload("res://random_select.gd").DEFAULT_WEIGHT
			#var total_weight: int = 1
			#var choices: Array[Dictionary] = []
			#
			#for choice:Dictionary in data["options"]:
				#var weight: int = defalut_weight if choice["weight"]["target_node_uuid"] == "" else _get_data(choice["weight"]["target_node_uuid"])
				#if weight == 0:
					#continue
				#choices.append({
					#"next": choice["output_connections"]["next_node"]["target_node_uuid"],
					#"weight": weight})
				#total_weight += weight
			#
			#if choices.is_empty():
				#return ""
			#
			#choices.sort_custom(func(a, b): return a["weight"] > b["weight"])
			#var random_select: int = randi_range(1, total_weight)
			#
			#var current_weight: int = 0
			#for choice in choices:
				#current_weight += choice["weight"]
				#if random_select <= current_weight:
					#return _process_logic(choice["next"])
			#return _process_logic(choices[-1]["next"]) # In case of loop error
		#NODE_TYPES.ANCHOR_POINTER:
			#return _process_logic(data["anchor_target"])
		#NODE_TYPES.ANCHOR:
			#return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		#NODE_TYPES.DIALOG_END:
			#return ""
		#NODE_TYPES.DIALOG_MERGE:
			#return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		#_:
			#return ""


func _get_data(_from_uuid: StringName) -> Variant:
	return null
	#if _dialog_resource == null or not _dialog_resource.dialog_nodes.has(from_uuid):
		#return null
	#
	#var data: Dictionary = _dialog_resource.get_node_data(from_uuid, language, region)
	#
	#match data["node_type"]:
		#NODE_TYPES.VALUE:
			#return data["value"]
		#NODE_TYPES.RANDOM_VALUE:
			#match data["mode"]:
				#TYPE_INT:
					#return randi_range(
							#data["values"]["base"],
							#data["values"]["max"])
				#TYPE_FLOAT:
					#return snappedf(
							#randf_range(
									#data["values"]["base"],
									#data["values"]["max"]),
							#0.01)
				#TYPE_BOOL:
					#var true_range: int = randi_range(
							#1,
							#100 if data["input_connections"]["base_value"]["target_node_uuid"] == "" else _get_data(data["input_connections"]["base_value"]["target_node_uuid"]))
					#return true_range <= data["values"]["base"]
				#_:
					#return null
		#NODE_TYPES.TYPE_GUARD:
			#var guard_data = _get_data(data["input_connections"]["value"]["target_node_uuid"])
			#if typeof(guard_data) == typeof(data["fallback_value"]):
				#return guard_data
			#else:
				#return data["fallback_value"]
		#NODE_TYPES.VARIABLE_GET:
			#return NexusForge.Variables.get_variable(data["variable_path"])
		#NODE_TYPES.CALLABLE_RETURN:
			#return NexusForge.Discourse.API.callv(
					#data["method"],
					#data["arguments"])
		#NODE_TYPES.DATA_EVENT:
			#if data["variable_path"] != "" and data["input_connections"]["variable_value"] != "":
				#NexusForge.Variables.set_variable(
						#data["variable_path"],
						#_get_data(data["input_connections"]["variable_value"]["target_node_uuid"]))
			#if data["input_connections"]["callable"]["target_node_uuid"] != "":
				#var call_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["callable"]["target_node_uuid"], language, region)
				#var call_args: Array = []
				#
				#for arg_connection in call_data["arguments"]:
					#call_args.append(
							#_get_data(arg_connection["target_node_uuid"]))
				#
				#NexusForge.Discourse.API.callv(
						#data["method"],
						#call_args)
			#
			#if data["input_connections"]["signal"]["target_node_uuid"] != "":
				#var signal_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["signal"]["target_node_uuid"], language, region)
				#var signal_args: Array = []
				#
				#for arg_connection in signal_data["arguments"]:
					#signal_args.append(_get_data(arg_connection["target_node_uuid"]))
				#
				#NexusForge.Discourse.API.emit_signal(
						#data["signal"],
						#signal_args)
			#return _get_data(data["input_connections"]["data_input"]["target_node_uuid"])
		#NODE_TYPES.LOCALIZED_TEXT:
			#return data["text"]
		#NODE_TYPES.CONDITION_SELECT:
			#var true_value: bool = _get_bool_result(data["input_connections"]["result"]["target_node_uuid"])
			#if true_value:
				#return _get_data(data["input_connections"]["true_value"]["target_node_uuid"])
			#else:
				#return _get_data(data["input_connections"]["false_value"]["target_node_uuid"])
		#NODE_TYPES.RESOURCE:
			#return data["resource_path"]
		#_:
			#return null


func _locale_set(new_language: String, new_region: String = "base") -> void:
	pass


func _dialog_resource_set(new_resource: DiscourseDialog) -> void:
	pass
	#_dialog_id_map.clear()
	#if new_resource != null:
		#_dialog_id_map.assign(new_resource.get_id_map())
#endregion


## Returns [code]true[/code] if a conversation is loaded and active.
func is_dialog_active() -> bool:
	return _dialog_resource != null and _conversation_started


## Loads a dialog and sets the dialog ID to the start of the conversation
## unless a valid [param starting_id] is given.
func load_dialog(path: String, starting_id: String = "") -> void:
	if _conversation_cache.is_in_cache(path):
		_dialog_resource = _conversation_cache.get_resource(path)
	else:
		var res: Resource = load(path)
		if res == null or res is not EditorDiscourseDialog:
			_next_uuid = ""
			_dialog_resource = null
			return
		_conversation_cache.cache_resource(res)
		_dialog_resource = res
	
	if _dialog_id_map.has(starting_id):
		_next_uuid = _dialog_id_map[starting_id]
	elif _dialog_resource.dialog_nodes.has(starting_id):
		_next_uuid = starting_id
	else:
		_next_uuid = _dialog_resource.entry_node


## Sets the dialog to be at a specific point. [param id] can be the dialog
## id or the UUID. If invalid it'll set the dialog to be at the beggining.
func set_dialog_id(id: String) -> void:
	if _dialog_resource == null:
		return
	
	if _dialog_id_map.has(id):
		_next_uuid = _dialog_id_map[id]
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
