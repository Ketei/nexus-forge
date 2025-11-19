class_name EditorDialogParser
extends DialogParser
## The [DialogParser] that NexusForge will use while its running in the editor.
##
## Within the editor the resources parsed will be [EditorDiscourseDialog] which
## contain a different structure from the released files.[br]
## For the release parser see [ReleaseDialogParser].[br]
## This class will [b]NOT[/b] exist on exported projects.


# --- Editor Class ---
#const NodeTypes := DiscourseGraphNode.DialogueNodeType


func _process_logic(uuid: StringName) -> String:
	if uuid.is_empty():
		return ""
	
	var data: Dictionary = _dialog_resource.get_node_data(uuid, language, region)
	
	match data["node_type"]:
		NodeTypes.ENTRY:
			return _process_logic(
					data["output_connections"]["next_node"]["target_node_uuid"])
		NodeTypes.DIALOG:
			var font: String = ""
			var scene: String = ""
			var speed: float = 0.0
			var display_name: String = ""
			var portrait_id: String = ""
			
			if data["input_connections"]["dialog_settings"]["target_node_uuid"] != "":
				var settings: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["dialog_settings"]["target_node_uuid"], language, region)
				if settings["font_resource"]["target_node_uuid"] != "":
					font = _get_data(settings["font_resource"]["target_node_uuid"])
				if settings["dialog_scene"]["target_node_uuid"] != "":
					scene = _get_data(settings["dialog_scene"]["target_node_uuid"])
				if settings["dialog_speed"]["target_node_uuid"] != "":
					speed = _get_data(settings["dialog_speed"]["target_node_uuid"])
			
			if data["input_connections"]["character_settings"]["target_node_uuid"] != "":
				var settings: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["character_settings"]["target_node_uuid"], language, region)
				if settings["display_name"]["target_node_uuid"] != "":
					display_name = _get_data(settings["display_name"]["target_node_uuid"])
				if settings["portrait_id"]["target_node_uuid"] != "":
					portrait_id = _get_data(settings["portrait_id"]["target_node_uuid"])
				
			if data["input_connections"]["dialog_text_source"]["target_node_uuid"] == "":
				dialog_reached.emit({
					"dialog_text": _parse_dialog(uuid, data["dialog_text"]),
					"character_id": data["character_id"],
					"persist": data["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id})
			else:
				dialog_reached.emit({
					"dialog_text": _parse_dialog(uuid, _get_data(data["input_connections"]["dialog_text_source"]["target_node_uuid"])),
					"character_id": data["character_id"],
					"persist": data["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id})
			return data["output_connections"]["next_node"]["target_node_uuid"]
		NodeTypes.OPTIONS:
			var available_options: Array[Dictionary] = []
			
			for option:Dictionary in data["options"]:
				if option["input_connections"]["settings"]["target_node_uuid"] != "":
					var opt_settings: Dictionary = _dialog_resource.get_node_data(option["input_connections"]["settings"]["target_node_uuid"], "common")
					var show: bool = true if opt_settings["option_available"]["target_node_uuid"] == "" else _get_bool_result(opt_settings["option_available"]["target_node_uuid"])
				
					if not show:
						continue
					var locked: bool = false if opt_settings["option_locked"]["target_node_uuid"] == "" else _get_bool_result(opt_settings["option_locked"]["target_node_uuid"])
					available_options.append({
						"locked": locked,
						"text": _parse_dialog(uuid, option["option_text"] if locked else _get_data(opt_settings["locked_hint"]["target_node_uuid"])),
						"target": option["output_connections"]["next_node"]["target_node_uuid"]})
				else:
					available_options.append(
						{
							"locked": true,
							"text": _parse_dialog(uuid, option["option_text"]),
							"target": option["output_connections"]["next_node"]["target_node_uuid"]})
			
			options_reached.emit(available_options)
			return uuid
		NodeTypes.BRANCH:
			var use_a: bool = _get_bool_result(data["input_connections"]["path_direction"]["target_node_uuid"])
			if use_a:
				return _process_logic(
						data["output_connections"]["next_node_true"]["target_node_uuid"])
			else:
				return _process_logic(
						data["output_connections"]["next_node_false"]["target_node_uuid"])
		NodeTypes.EVENT:
			if data["variable_path"] != "" and data["input_connections"]["variable_value"]["target_node_uuid"] != "":
				var parts: PackedStringArray = data["variable_path"].rsplit("/", false, 1)
				NexusForge.Blackboard.set_variable(
						parts[0],
						parts[1],
						_get_data(data["input_connections"]["variable_value"]["target_node_uuid"]))
			if data["input_connections"]["callable"]["target_node_uuid"] != "":
				var call_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["callable"]["target_node_uuid"], language, region)
				var call_args: Array = []
				
				for arg_connection in call_data["arguments"]:
					call_args.append(
							_get_data(arg_connection["target_node_uuid"]))
				
				NexusForge.Discourse.API.callv(
						call_data["method"],
						call_args)
			
			if data["input_connections"]["signal"]["target_node_uuid"] != "":
				var signal_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["signal"]["target_node_uuid"], language, region)
				var signal_args: Array = []
				
				for arg_connection in signal_data["arguments"]:
					signal_args.append(_get_data(arg_connection["target_node_uuid"]))
				
				NexusForge.Discourse.API.emit_signal(
						signal_data["signal"],
						signal_args)
				
			return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		NodeTypes.MATCH:
			var data_comp = _get_data(data["input_connections"]["match_value_source"]["target_node_uuid"])
			for case:Dictionary in data["cases"]:
				if case["value"] == data_comp:
					return _process_logic(case["output_connections"]["next_node"]["target_node_uuid"])
			return _process_logic(data["output_connections"]["default"]["target_node_uuid"])
		NodeTypes.PAUSE:
			dialog_paused.emit()
			return data["output_connections"]["next_node"]["target_node_uuid"]
		NodeTypes.RANDOM:
			var defalut_weight: int = DialogParser.RANDOM_DEFAULT_WEIGHT
			var total_weight: int = 1
			var choices: Array[Dictionary] = []
			
			for choice:Dictionary in data["options"]:
				var weight: int = defalut_weight if choice["weight"]["target_node_uuid"] == "" else _get_data(choice["weight"]["target_node_uuid"])
				if weight == 0:
					continue
				choices.append({
					"next": choice["output_connections"]["next_node"]["target_node_uuid"],
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
		NodeTypes.ANCHOR_POINTER:
			return _process_logic(data["anchor_target"])
		NodeTypes.ANCHOR:
			return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		NodeTypes.DIALOG_END:
			return ""
		NodeTypes.DIALOG_MERGE:
			return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		_:
			return ""


func _get_data(from_uuid: StringName) -> Variant:
	if _dialog_resource == null or not _dialog_resource.dialog_nodes.has(from_uuid):
		return null
	
	var data: Dictionary = _dialog_resource.get_node_data(from_uuid, language, region)
	
	match data["node_type"]:
		NodeTypes.VALUE:
			return data["value"]
		NodeTypes.RANDOM_VALUE:
			match data["mode"]:
				TYPE_INT:
					return randi_range(
							data["values"]["base"],
							data["values"]["max"])
				TYPE_FLOAT:
					return snappedf(
							randf_range(
									data["values"]["base"],
									data["values"]["max"]),
							0.01)
				TYPE_BOOL:
					var true_range: int = randi_range(
							1,
							100 if data["input_connections"]["base_value"]["target_node_uuid"] == "" else _get_data(data["input_connections"]["base_value"]["target_node_uuid"]))
					return true_range <= data["values"]["base"]
				_:
					return null
		NodeTypes.TYPE_GUARD:
			var guard_data = _get_data(data["input_connections"]["value"]["target_node_uuid"])
			if typeof(guard_data) == typeof(data["fallback_value"]):
				return guard_data
			else:
				return data["fallback_value"]
		NodeTypes.VARIABLE_GET:
			var parts: PackedStringArray = data["variable_path"].rsplit("/", false, 1)
			return NexusForge.Blackboard.get_variable(parts[0], parts[1])
		NodeTypes.CALLABLE_RETURN:
			return NexusForge.Discourse.API.callv(
					data["method"],
					data["arguments"])
		NodeTypes.DATA_EVENT:
			if data["variable_path"] != "" and data["input_connections"]["variable_value"] != "":
				var parts: PackedStringArray = data["variable_path"].rsplit("/", false, 1)
				NexusForge.Blackboard.set_variable(
						parts[0],
						parts[1],
						_get_data(data["input_connections"]["variable_value"]["target_node_uuid"]))
			if data["input_connections"]["callable"]["target_node_uuid"] != "":
				var call_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["callable"]["target_node_uuid"], language, region)
				var call_args: Array = []
				
				for arg_connection in call_data["arguments"]:
					call_args.append(
							_get_data(arg_connection["target_node_uuid"]))
				
				NexusForge.Discourse.API.callv(
						call_data["method"],
						call_args)
			
			if data["input_connections"]["signal"]["target_node_uuid"] != "":
				var signal_data: Dictionary = _dialog_resource.get_node_data(data["input_connections"]["signal"]["target_node_uuid"], language, region)
				var signal_args: Array = []
				
				for arg_connection in signal_data["arguments"]:
					signal_args.append(_get_data(arg_connection["target_node_uuid"]))
				
				NexusForge.Discourse.API.emit_signal(
						signal_data["signal"],
						signal_args)
			return _get_data(data["input_connections"]["data_input"]["target_node_uuid"])
		NodeTypes.LOCALIZED_TEXT:
			return data["text"]
		NodeTypes.CONDITION_SELECT:
			var true_value: bool = _get_bool_result(data["input_connections"]["result"]["target_node_uuid"])
			if true_value:
				return _get_data(data["input_connections"]["true_value"]["target_node_uuid"])
			else:
				return _get_data(data["input_connections"]["false_value"]["target_node_uuid"])
		NodeTypes.RESOURCE:
			return data["resource_path"]
		_:
			return null


func _dialog_resource_set(new_resource: DiscourseDialog) -> void:
	_dialog_id_map.clear()
	if new_resource != null:
		_dialog_id_map.assign(new_resource.get_id_map())


func _get_bool_result(from_uuid: String) -> bool:
	if _dialog_resource == null or from_uuid.is_empty() or not _dialog_resource.dialog_nodes.has(from_uuid):
		return false
	
	var data: Dictionary = _dialog_resource.get_node_data(from_uuid, language, region)
	
	match data["node_type"]:
		NodeTypes.VALUE:
			var value = data["value"]
			if typeof(value) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
				return bool(value)
			else:
				return false
		NodeTypes.RANDOM_VALUE:
			if data["mode"] == TYPE_BOOL:
				var result: int = randi_range(1, 100)
				return data["values"]["base"] <= result
			elif data["mode"] in [TYPE_INT, TYPE_FLOAT]:
				return randi_range(
						 data["values"]["base"],
						 data["values"]["max"]) != 0
			else:
				return false
		NodeTypes.TYPE_GUARD:
			# Will get data if matches type, if not fallback is used
			var guard_data = _get_data(data["input_connections"]["value"]["target_node_uuid"])
			var data_type: int = typeof(data)
			if data_type  == TYPE_BOOL:
				return guard_data
			elif data_type == TYPE_INT or data_type == TYPE_FLOAT:
				return guard_data != 0
			else:
				return false
		NodeTypes.VARIABLE_GET:
			var variable = "Nexusforge"
			if typeof(variable) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
				return bool(variable)
			else:
				return false
		NodeTypes.COMPARATION:
			var value_a = _get_data(data["input_connections"]["node_a"])
			var value_b = _get_data(data["input_connections"]["node_b"])
			
			if not _can_compare(value_a, value_b):
				return false
			
			match data["operator"]:
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
