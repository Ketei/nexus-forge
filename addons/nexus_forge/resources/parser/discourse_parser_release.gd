class_name ReleaseDialogParser
extends DialogParser
## The [DialogParser] that NexusForge will use while its running on exported projects.
##
## On an exported project the resources parsed will be [ReleaseDiscourseDialog]
## which contain a different structure from the editor files.[br]
## For the editor parser see [EditorDialogParser].[br]

## The resource containing the localizable data of a dialog.
var localization: DiscourseDialogLocale = null 
# Example of how data will be structured in the dialog resource (Release).
#const store = {
		#NodeTypes.DIALOG: {
			#"node_type": NodeTypes.DIALOG,
			#"character_id": &"",
			#"persist": true,
			#"character_settings": {},
			#"dialog_settings": {},
			#"text_source": &"", # External key source for dialog
			#"text_key": &"", # Refers to the localization
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
			#"text": &""}} # Key to localization
			



# The anchor pointers will be replaced by their pointed target
# Dialog merge will be replaced by their target merge
# Settings will be embeded in the relevant block
# Localized text will be a key pointer towards a translation file

func _process_logic(uuid: StringName) -> String:
	if uuid.is_empty():
		return ""
	
	var data: Dictionary = _dialog_resource.dialog_nodes[uuid]
	
	match data["node_type"]:
		NodeTypes.ENTRY:
			return _process_logic(data["next_node"])
		NodeTypes.DIALOG:
			var font: String = data["dialog_settings"]["font_resource"] if data["dialog_settings"]["font_resource_node"] == &"" else _get_data(data["dialog_settings"]["font_resource_node"])
			var scene: String = data["dialog_settings"]["dialog_scene"] if data["dialog_settings"]["dialog_scene_node"] == &"" else _get_data(data["dialog_settings"]["dialog_scene_node"])
			var speed: float = data["dialog_settings"]["dialog_speed"] if data["dialog_settings"]["dialog_speed_node"] == &"" else _get_data(data["dialog_settings"]["dialog_speed_node"])
			var display_name: String = data["character_settings"]["display_name"] if data["character_settings"]["display_name_node"] == &"" else _get_data(data["character_settings"]["display_name_node"])
			var portrait_id: String = data["character_settings"]["portrait_id"] if data["character_settings"]["portrait_id_node"] == &"" else _get_data(data["character_settings"]["portrait_id_node"])
			if data["text_source"].is_empty():
				dialog_reached.emit({
					"dialog_text": _parse_dialog(String(uuid), localization.get_text(_dialog_resource.conversation_uuid, uuid)),
					"character_id": data["character_id"],
					"persist": data["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id})
			else:
				dialog_reached.emit({
					"dialog_text": _parse_dialog(String(uuid), _get_data(data["text_source"])),
					"character_id": data["character_id"],
					"persist": data["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id})
			return data["next_node"]
		NodeTypes.OPTIONS:
			var available_options: Array[Dictionary] = []
			var localized_options: PackedStringArray = localization.get_options(_dialog_resource.conversation_uuid, uuid)
			
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
							"target": option["next_node"]})
				else:
					var opt_settings: Dictionary = _dialog_resource.dialog_nodes[option["settings"]]
					var show: bool = true if opt_settings["available"].is_empty() else _get_data(opt_settings["available"])
				
					if not show:
						continue
					var unlocked: bool = true if opt_settings["unlocked"].is_empty() else _get_data(opt_settings["unlocked"])
					
					if unlocked:
						option_duuid += "_unlocked"
					else:
						option_duuid += "_locked"
					
					available_options.append({
						"unlocked": unlocked,
						"text": _parse_dialog(option_duuid, localized_options[idx] if unlocked else _get_data(opt_settings["lock_hint"])),
						"target": option["next_node"]})
			
			options_reached.emit(available_options)
			return uuid
		NodeTypes.BRANCH:
			var use_a: bool = _get_data(data["result"])
			if use_a:
				return _process_logic(data["case_true"])
			else:
				return _process_logic(data["case_false"])
		NodeTypes.EVENT:
			if not data["variable_path"].is_empty() and not data["value"].is_empty():
				NexusForge.Blackboard.set_variable(
						data["variable_path"],
						data["variable"],
						data["value"])
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


func _get_data(uuid: StringName) -> Variant:
	if _dialog_resource == null or not _dialog_resource.dialog_nodes.has(uuid):
		return null
	
	var data: Dictionary = _dialog_resource.dialog_nodes[uuid]
	
	match data["node_type"]:
		NodeTypes.VALUE:
			return data["value"]
		NodeTypes.RANDOM_VALUE:
			match data["random_type"]:
				TYPE_INT:
					var min_value: int = data["min_value"] if data["min_source"].is_empty() else _get_data(data["min_source"])
					var max_value: int = data["max_value"] if data["max_source"].is_empty() else _get_data(data["max_source"])
					return randi_range(min_value, max_value)
				TYPE_FLOAT:
					var min_value: float = data["min_value"] if data["min_source"].is_empty() else _get_data(data["min_source"])
					var max_value: float = data["max_value"] if data["max_source"].is_empty() else _get_data(data["max_source"])
					return snappedf(
							randf_range(
									min_value,
									max_value),
							FLOAT_SNAP)
				TYPE_BOOL:
					var true_probability: int = data["min_value"] if data["min_source"].is_empty() else _get_data(data["min_source"])
					if true_probability == 0:
						return false
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
			return localization.get_text(_dialog_resource.conversation_uuid, data["text"])
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
			return null


func _dialog_resource_set(new_resource: DiscourseDialog) -> void:
	_dialog_id_map.clear()
	if new_resource != null:
		_dialog_id_map.assign(new_resource.id_map)
		_load_locale(language, region)
	else:
		localization = null


func _locale_set(new_language: String, new_region: String = "base") -> void:
	_load_locale(new_language, new_region)


func _load_locale(new_language: String, new_region: String) -> void:
	var locale_path: String = str(
			ProjectSettings.get_setting("nexus_forge/localization_directory", "res://localization/"), # Project settings base path
			new_language,
			"-",
			new_region,
			"/dialog/",
			_dialog_resource.localization_uuid,
			".tres")
	#var _example = "res://localization/en-base/dialog/(dialog_uuid).tres"
	localization = load(locale_path)


## Loads a dialog and sets the dialog ID to the start of the conversation
## unless a valid [param starting_id] is given.[br]
## It also loads the relevant locale to [member localization].
func load_dialog(path: String, starting_id: String = "") -> bool:
	if _conversation_cache.is_in_cache(path):
		_dialog_resource = _conversation_cache.get_resource(path)
	else:
		var res: Resource = load(path)
		if res == null or res is not ReleaseDiscourseDialog:
			_next_uuid = ""
			_dialog_resource = null
			return false
		_conversation_cache.cache_resource(res)
		_dialog_resource = res
	
	if _dialog_id_map.has(starting_id):
		_next_uuid = _dialog_id_map[starting_id]
	elif _dialog_resource.dialog_nodes.has(starting_id):
		_next_uuid = starting_id
	else:
		_next_uuid = _dialog_resource.entry_node
	
	return true
