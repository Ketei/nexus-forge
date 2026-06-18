class_name EditorDialogParser
extends DialogParser
## The [DialogParser] that NexusForge will use while its running in the editor.
##
## The resources parsed by this object are [EditorDiscourseDialog] which
## contain a different structure from the released files.[br]


## Emmited when data is set on the NexusForge.Blackboard singleton.
signal data_set(path: String, data: Variant)
## Emmited when a method is called from the DiscourseAPI.
signal method_called(method_string: String, arguments: Array)
## Emmited when a signal is emmited from the DiscourseAPI.
signal signal_emmited(signal_name: String, arguments: Array)


func load_dialog(path: String, starting_id: StringName = &"") -> bool:
	if _conversation_cache.is_in_cache(path):
		_dialog_resource = _conversation_cache.get_resource(path)
		var dialog_id: String = _dialog_edits.dialog_id
		if _dialog_edits.has(dialog_id) and _dialog_resource.dialog_overrides != _dialog_edits[dialog_id]:
			_dialog_resource.dialog_overrides = _dialog_edits[dialog_id]
		return true
	else:
		var res: Resource = load(path)
		if res == null or res is not EditorDiscourseDialog:
			_next_uuid = ""
			_dialog_resource = null
			return false
		var dialog_id: String = res.dialog_id
		
		if _dialog_edits.has(dialog_id) and res.dialog_overrides != _dialog_edits[dialog_id]:
			res.dialog_overrides = _dialog_edits[dialog_id]
		_conversation_cache.cache_resource(res)
		_dialog_resource = res
	
	if _dialog_resource.id_map.has(starting_id):
		_next_uuid = _dialog_resource.id_map[starting_id]
	elif _dialog_resource.node_data.has(starting_id):
		_next_uuid = starting_id
	else:
		_next_uuid = _dialog_resource.entry_node
	
	return true


func set_dialog_id(id: StringName) -> void:
	if _dialog_resource == null:
		return
	
	if _dialog_resource.node_data.has(id):
		_next_uuid = id
	else:
		_next_uuid = _get_uuid_from_id(id)


func _get_uuid_from_id(id: StringName) -> StringName:
	for entry in _dialog_resource.node_data.keys():
		if _dialog_resource.node_data[entry]["name"] == id:
			return entry
	return &""


func _process_logic(uuid: StringName) -> Dictionary[String, Variant]:
	var target: Dictionary[String, Variant] = {"current": &"", "next": &"", "type": -1, "data": {}}
	if uuid.is_empty():
		return target
	
	var data: Dictionary = _dialog_resource.get_node_data(uuid, locale)
	
	if data.is_empty():
		push_error(
			"[DISCOURSE] DATA FOR NODE WITH UUID \"",
			uuid,
			"\" WAS NOT FOUND")
		return target
	
	var metadata: Dictionary = data["metadata"]
	match data["type"]:
		NodeTypes.ENTRY:
			return _process_logic(
					data["output_connections"]["next_node"]["target_node_uuid"])
		NodeTypes.DIALOG:
			var font: String = ""
			var scene: String = ""
			var speed: float = 0.0
			var display_name: String = ""
			var portrait_id: String = ""
			var dialog_metadata: Dictionary[String, Variant] = {}
			
			if not data["input_connections"]["dialog_settings"]["target_node_uuid"].is_empty():
				var settings: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["dialog_settings"]["target_node_uuid"], locale)
				if not settings["input_connections"]["font_resource"]["target_node_uuid"].is_empty():
					font = _get_data(settings["input_connections"]["font_resource"]["target_node_uuid"])
				if not settings["input_connections"]["dialog_scene"]["target_node_uuid"].is_empty():
					scene = _get_data(settings["input_connections"]["dialog_scene"]["target_node_uuid"])
				if not settings["input_connections"]["dialog_speed"]["target_node_uuid"].is_empty():
					speed = _get_data(settings["input_connections"]["dialog_speed"]["target_node_uuid"])
				if not settings["input_connections"]["metadata"]["target_node_uuid"].is_empty():
					var metadata_node: Dictionary = _dialog_resource.get_node_data(settings["input_connections"]["metadata"]["target_node_uuid"])
					if metadata_node.has_all(["input_connections", "metadata"]) and metadata_node["metadata"].has("metadata_connections"):
						for meta_entry: Dictionary in metadata_node["metadata"]["metadata_connections"]:
							if not metadata_node["input_connections"].has(meta_entry["id"]):
								push_error(
										"[NexusForge] Metadata connection missing for metadata \"", meta_entry["id"], "\" on node \"", metadata_node["name"], "\" on resoruce \"", _dialog_resource.resource_path, "\"")
								dialog_metadata[meta_entry["id"]] = null
							else:
								dialog_metadata[meta_entry["id"]] = _get_data(metadata_node["input_connections"][meta_entry["id"]]["target_node_uuid"])
			
			if not data["input_connections"]["character_settings"]["target_node_uuid"].is_empty():
				var settings: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["character_settings"]["target_node_uuid"], locale)
				if not settings["input_connections"]["display_name"]["target_node_uuid"].is_empty():
					display_name = _get_data(settings["input_connections"]["display_name"]["target_node_uuid"])
				if not settings["input_connections"]["portrait_id"]["target_node_uuid"].is_empty():
					portrait_id = _get_data(settings["input_connections"]["portrait_id"]["target_node_uuid"])
			
			if data["input_connections"]["dialog_text_source"]["target_node_uuid"].is_empty():
				target["data"] = {
					"dialog_text": _parse_dialog(uuid, metadata["dialog_text"]),
					"character_id": metadata["character_id"],
					"persist": metadata["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id,
					"metadata": dialog_metadata}
			else:
				target["data"] = {
					"dialog_text": _parse_dialog(uuid, _get_data(data["input_connections"]["dialog_text_source"]["target_node_uuid"])),
					"character_id": metadata["character_id"],
					"persist": metadata["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id,
					"metadata": dialog_metadata}
			
			target["type"] = NodeTypes.DIALOG
			target["current"] = uuid
			target["next"] = data["output_connections"]["next_node"]["target_node_uuid"]
			
			return target
		NodeTypes.CHOICES:
			var available_options: Array[Dictionary] = []
			var option_idx: int = -1
			var option_duuid: String = ""
			for option:Dictionary in metadata["choices"]:
				option_idx += 1
				option_duuid = uuid + "_" + str(option_idx)
				if option["input_connections"]["settings"]["target_node_uuid"].is_empty():
					option_duuid += "_unlocked"
					available_options.append(
						{
							"unlocked": true,
							"text": _parse_dialog(option_duuid, option["text"]),
							"target": option["output_connections"]["next_node"]["target_node_uuid"],
							"metadata": {}})
				else:
					var opt_settings: Dictionary = _dialog_resource.get_node_data(option["input_connections"]["settings"]["target_node_uuid"])
					var show: bool = true if opt_settings["input_connections"]["option_available"]["target_node_uuid"].is_empty() else _get_bool_result(opt_settings["input_connections"]["option_available"]["target_node_uuid"])
				
					if not show:
						continue
					
					var unlocked: bool = true if opt_settings["input_connections"]["option_unlocked"]["target_node_uuid"].is_empty() else _get_bool_result(opt_settings["input_connections"]["option_unlocked"]["target_node_uuid"])
					var text: String = option["text"]
					var option_metadata: Dictionary[String, Variant] = {}
					
					if not unlocked and not opt_settings["input_connections"]["locked_hint"]["target_node_uuid"].is_empty():
						var lock_hint: String = _get_data(opt_settings["input_connections"]["locked_hint"]["target_node_uuid"])
						if not lock_hint.is_empty():
							text = lock_hint
					if not opt_settings["input_connections"]["metadata"]["target_node_uuid"].is_empty():
						var metadata_node: Dictionary = _dialog_resource.get_node_data(opt_settings["input_connections"]["metadata"]["target_node_uuid"])
						if metadata_node.has_all(["input_connections", "metadata"]) and metadata_node["metadata"].has("metadata_connections"):
							for meta_entry: Dictionary in metadata_node["metadata"]["metadata_connections"]:
								if not metadata_node["input_connections"].has(meta_entry["id"]):
									push_error(
											"[NexusForge] Metadata connection missing for metadata \"", meta_entry["id"], "\" on node \"", metadata_node["name"], "\" on resoruce \"", _dialog_resource.resource_path, "\"")
									option_metadata[meta_entry["id"]] = null
								else:
									option_metadata[meta_entry["id"]] = _get_data(metadata_node["input_connections"][meta_entry["id"]]["target_node_uuid"])
					
					if unlocked:
						option_duuid += "_unlocked"
					else:
						option_duuid += "_locked"
					
					available_options.append({
						"unlocked": unlocked,
						"text": _parse_dialog(option_duuid, text),
						"target": option["output_connections"]["next_node"]["target_node_uuid"],
						"metadata": option_metadata})
			
			target["data"] = available_options
			target["type"] = NodeTypes.CHOICES
			target["current"] = uuid
			target["next"] = uuid
			
			return target
		NodeTypes.BRANCH:
			var use_a: bool = _get_bool_result(data["input_connections"]["path_direction"]["target_node_uuid"])
			if use_a:
				return _process_logic(
						data["output_connections"]["next_node_true"]["target_node_uuid"])
			else:
				return _process_logic(
						data["output_connections"]["next_node_false"]["target_node_uuid"])
		NodeTypes.EVENT:
			if not metadata["variable_path"].is_empty() and not data["input_connections"]["variable_value"]["target_node_uuid"].is_empty():
				var path: String = metadata["variable_path"]
				var set_data: Variant = _get_data(data["input_connections"]["variable_value"]["target_node_uuid"])
				
				if NexusForge.Blackboard.set_variable(path, set_data):
					data_set.emit(path, set_data)
				else:
					push_error("[DISCOURSE] Node ", data["name"], " couldn't set data on path: ", path.strip_edges().simplify_path())
			if data["input_connections"]["callable"]["target_node_uuid"] != "":
				var call_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["callable"]["target_node_uuid"])
				var call_metadata: Dictionary = call_data["metadata"]
				
				if NexusForge.Discourse.API.has_method(call_metadata["method"]):
					var call_args: Array = []
					
					for arg_connection in call_metadata["arguments"]:
						if arg_connection["target_node_uuid"].is_empty():
							continue
						call_args.append(
								_get_data(arg_connection["target_node_uuid"]))
					
					NexusForge.Discourse.API.callv(
							call_metadata["method"],
							call_args)
					
					method_called.emit(call_metadata["method"], call_args.duplicate(true))
				else:
					push_error("[DISCOURSE] Node ", data["name"], " attemted to call inexistent method: ", call_metadata["method"])
			
			if data["input_connections"]["signal"]["target_node_uuid"] != "":
				var signal_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["signal"]["target_node_uuid"])
				var signal_metadata: Dictionary = signal_data["metadata"]
				
				if NexusForge.Discourse.API.has_signal(signal_metadata["signal"]):
					var signal_args: Array = []
					
					for arg_connection in signal_metadata["arguments"]:
						signal_args.append(_get_data(arg_connection["target_node_uuid"]))
					
					NexusForge.Discourse.API.emit_signal(
							signal_metadata["signal"],
							signal_args)
					signal_emmited.emit(signal_metadata["signal"], signal_args)
				else:
					push_error("[DISCOURSE] Node ", data["name"], " attempted to emit an inexistent signal: ", signal_metadata["signal"])
			return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		NodeTypes.MATCH:
			var data_comp = _get_data(data["input_connections"]["match_value_source"]["target_node_uuid"])
			for case:Dictionary in metadata["cases"]:
				if case["value"] == data_comp:
					return _process_logic(case["output_connections"]["next_node"]["target_node_uuid"])
			return _process_logic(data["output_connections"]["default"]["target_node_uuid"])
		NodeTypes.PAUSE:
			target["type"] = NodeTypes.PAUSE
			target["current"] = uuid
			target["next"] = data["output_connections"]["next_node"]["target_node_uuid"]
			return target
		NodeTypes.RANDOM:
			var total_weight: int = 0
			var choices: Array[Dictionary] = []
			
			for choice:Dictionary in metadata["options"]:
				var weight: int = DialogParser.RANDOM_DEFAULT_WEIGHT if choice["input_connections"]["weight"]["target_node_uuid"].is_empty() else _get_data(choice["input_connections"]["weight"]["target_node_uuid"])
				if weight == 0:
					continue
				choices.append({
					"next": choice["output_connections"]["next_node"]["target_node_uuid"],
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
		NodeTypes.ANCHOR_POINTER:
			return _process_logic(metadata["anchor_target"])
		NodeTypes.ANCHOR:
			return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		NodeTypes.DIALOG_END:
			target["current"] = uuid
			target["type"] = NodeTypes.DIALOG_END
			return target
		NodeTypes.DIALOG_MERGE:
			return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		_:
			return target


func _get_data(from_uuid: StringName, fallback = null) -> Variant:
	if _dialog_resource == null or not _dialog_resource.node_data.has(from_uuid):
		return null
	
	var data: Dictionary = _dialog_resource.get_node_data(from_uuid, locale)
	var metadata: Dictionary = data["metadata"]
	
	match data["type"]:
		NodeTypes.VALUE:
			return metadata["value"]
		NodeTypes.RANDOM_VALUE:
			match metadata["mode"]:
				TYPE_INT:
					return randi_range(
							metadata["values"]["base"],
							metadata["values"]["max"])
				TYPE_FLOAT:
					return snappedf(
							randf_range(
									metadata["values"]["base"],
									metadata["values"]["max"]),
							0.01)
				TYPE_BOOL:
					var true_range: int = randi_range(
							1,
							100 if data["input_connections"]["base_value"]["target_node_uuid"] == "" else _get_data(data["input_connections"]["base_value"]["target_node_uuid"]))
					
					return true_range <= metadata["values"]["base"]
				_:
					return null
		NodeTypes.TYPE_GUARD:
			var guard_data = _get_data(data["input_connections"]["value"]["target_node_uuid"])
			if typeof(guard_data) == typeof(metadata["fallback_value"]):
				return guard_data
			else:
				return metadata["fallback_value"]
		NodeTypes.VARIABLE_GET:
			var path: String = metadata["variable_path"]
			return NexusForge.Blackboard.get_variable(path)
		NodeTypes.CALLABLE_RETURN:
			return NexusForge.Discourse.API.callv(
					metadata["method"],
					metadata["arguments"])
		NodeTypes.DATA_EVENT:
			if metadata["variable_path"] != "" and data["input_connections"]["variable_value"] != "":
				var path: String = metadata["variable_path"]
				var data_conn = _get_data(data["input_connections"]["variable_value"]["target_node_uuid"])
				if NexusForge.Blackboard.set_variable(
						path,
						data_conn):
					data_set.emit(path, data_conn)
				else:
					push_error("[DISCOURSE] Node ", data["name"], " couldn't set data on path: ", path.strip_edges().simplify_path())
			if data["input_connections"]["callable"]["target_node_uuid"] != "":
				var call_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["callable"]["target_node_uuid"], locale)
				
				if NexusForge.Discourse.API.has_method(call_data["metadata"]["method"]):
					var call_args: Array = []
					
					for arg_connection in call_data["metadata"]["arguments"]:
						call_args.append(
								_get_data(arg_connection["target_node_uuid"]))
					
					NexusForge.Discourse.API.callv(
							call_data["metadata"]["method"],
							call_args)
					method_called.emit(call_data["metadata"]["method"], call_args.duplicate(true))
				else:
					push_error("[DISCOURSE] Node ", data["name"], " attemted to call inexistent method: ", call_data["metadata"]["method"])
			
			if data["input_connections"]["signal"]["target_node_uuid"] != "":
				var signal_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["signal"]["target_node_uuid"], locale)
				
				if NexusForge.Discourse.API.has_signal(signal_data["metadata"]["signal"]):
					var signal_args: Array = []
					
					for arg_connection in signal_data["metadata"]["arguments"]:
						signal_args.append(_get_data(arg_connection["target_node_uuid"]))
					
					NexusForge.Discourse.API.emit_signal(
							signal_data["metadata"]["signal"],
							signal_args)
					signal_emmited.emit(signal_data["metadata"]["signal"], signal_args)
				else:
						push_error("[DISCOURSE] Node ", data["name"], " attempted to emit an inexistent signal: ", signal_data["metadata"]["signal"])
			return _get_data(data["input_connections"]["data_input"]["target_node_uuid"])
		NodeTypes.LOCALIZED_TEXT:
			return metadata["text"]
		NodeTypes.CONDITION_SELECT:
			var true_value: bool = _get_bool_result(data["input_connections"]["result"]["target_node_uuid"])
			if true_value:
				return _get_data(data["input_connections"]["true_value"]["target_node_uuid"])
			else:
				return _get_data(data["input_connections"]["false_value"]["target_node_uuid"])
		NodeTypes.RESOURCE:
			return metadata["resource_path"]
		_:
			return null


func _dialog_resource_set(new_resource: DiscourseDialog) -> void:
	return


func _parse_dialog(dialog_id: String, dialog: String) -> String:
	var DUUID: String = dialog_id + "/" + locale
	# (UUID)/en_US
	if _dialog_resource.parsed_dialog_cache.is_in_cache(DUUID):
		var cached_data: ParsedDialog = _dialog_resource.parsed_dialog_cache.get_cache(DUUID)
		return cached_data.get_dialog()
	
	var parsed: ParsedDialog = ParsedDialog.new()
	parsed.locale = locale
	parsed.dialog = dialog
	
	var functions_processed: Dictionary[String, Variant] = {}
	var variables_processed: Dictionary[String, Variant] = {}
	var phrases_processed: Dictionary[String, Variant] = {}
	var random_processed: Dictionary[String,Variant] = {}
	
	var regex_search: RegEx = RegEx.new()
	regex_search.compile("\\{((?:\\![^\\}\\s]+)|(?:[\\?\\&\\$][^\\}]+))\\}")
	
	for reg_result in regex_search.search_all(dialog):
		var format_key: String = reg_result.get_string(1)
		var token: String = format_key[0]
		
		if token == "?":
			if random_processed.has(reg_result.get_string()):
				continue
			
			random_processed[reg_result.get_string()] = null
			var options: Array[String] = []
			options.assign(
					format_key.substr(1).split("|", false))
			
			parsed.set_format_callable(
					format_key,
					options.pick_random)
		
		elif token == "!":
			if functions_processed.has(reg_result.get_string()):
				continue
			
			functions_processed[reg_result.get_string()] = null
			
			parsed.set_format_callable(
					format_key,
					_build_callable_for_method(format_key.substr(1)))
		
		elif token == "$":
			if variables_processed.has(reg_result.get_string()):
				continue
			
			variables_processed[reg_result.get_string()] = null
			
			parsed.set_format_callable(
					format_key,
					_build_callable_for_variable(format_key.substr(1)))
		
		elif token == "&":
			if phrases_processed.has(reg_result.get_string()):
				continue
			phrases_processed[reg_result.get_string()] = null
			var phrase_key: String = format_key.substr(1)
			
			var phrase: String = _dialog_resource.get_format_string(
					format_key,
					locale)
			
			var argument_cases: Dictionary[String, Dictionary] = _dialog_resource.get_format_string_arguments(
					format_key,
					locale)
			
			parsed.create_format_phrase(
					format_key,
					phrase,
					argument_cases)
			
			for format_result in regex_search.search_all(phrase):
				var phrase_case: String = format_result.get_string(1)
				var case_token: String = phrase_case[0]
				
				if case_token == "?":
					var options: Array[String] = []
					options.assign(
							phrase_case.substr(1).split("|", false))
					
					parsed.set_format_phrase_callable(
							format_key,
							phrase_case,
							options.pick_random)
				
				elif case_token == "!":
					parsed.set_format_phrase_callable(
							format_key,
							phrase_case,
							_build_callable_for_method(phrase_case.substr(1)))
				
				elif case_token == "$":
					parsed.set_format_phrase_callable(
							format_key,
							phrase_case,
							_build_callable_for_variable(phrase_case.substr(1)))
	
	_dialog_resource.parsed_dialog_cache.cache_data(
		DUUID,
		parsed)
	
	return parsed.get_dialog()


func _load_locale_to_active_dialog(_locale_code: String) -> void:
	return


func _get_bool_result(from_uuid: String) -> bool:
	if _dialog_resource == null or from_uuid.is_empty() or not _dialog_resource.node_data.has(from_uuid):
		return false
	
	var data: Dictionary = _dialog_resource.get_node_data(from_uuid, locale)
	var metadata: Dictionary = data["metadata"]
	match data["type"]:
		NodeTypes.VALUE:
			var value = metadata["value"]
			if typeof(value) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
				return bool(value)
			else:
				return false
		NodeTypes.RANDOM_VALUE:
			if metadata["mode"] == TYPE_BOOL:
				var result: int = randi_range(1, 100)
				return metadata["values"]["base"] <= result
			elif metadata["mode"] in [TYPE_INT, TYPE_FLOAT]:
				return randi_range(
						 metadata["values"]["base"],
						 metadata["values"]["max"]) != 0
			else:
				return false
		NodeTypes.TYPE_GUARD:
			# Will get data if matches type, if not fallback is used
			var guard_data = _get_data(data["input_connections"]["value"]["target_node_uuid"])
			var data_type: int = typeof(guard_data)
			
			if data_type  == TYPE_BOOL:
				return guard_data
			elif data_type == TYPE_INT or data_type == TYPE_FLOAT:
				return guard_data != 0
			else:
				return false
		NodeTypes.VARIABLE_GET:
			var path: String = metadata["variable_path"]
			
			var variable = NexusForge.Blackboard.get_variable(path)
			
			if typeof(variable) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
				return bool(variable)
			else:
				return false
		NodeTypes.COMPARATION:
			var value_a = _get_data(data["input_connections"]["node_a"]["target_node_uuid"])
			var value_b = _get_data(data["input_connections"]["node_b"]["target_node_uuid"])
			
			if not _can_compare(value_a, value_b):
				return metadata["operator"] == OP_NOT_EQUAL
			
			match metadata["operator"]:
				OP_EQUAL:
					return value_a == value_b
				OP_NOT_EQUAL:
					return value_a != value_b
				OP_LESS:
					return value_a < value_b
				OP_LESS_EQUAL:
					return value_a <= value_b
				OP_GREATER:
					return value_b < value_a
				OP_GREATER_EQUAL:
					return value_b <= value_a
				_:
					return false
		_:
			return false
