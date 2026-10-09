class_name NFEditorDialogParser
extends NFDialogParser
## The aprser that NexusForge will use while its running in the editor.
##
## The resources parsed by this object are [EditorDiscourseDialog] which
## contain a different structure from the released files.[br]
## [b]Note:[/b] This parser is designed only to be used during editor builds
## and can't process release resources.
## [br][br]
## For the release parser see [NFDialogParser].


## Emmited when data is set on the NexusForge.Blackboard singleton.
signal data_set(path: String, data: Variant)
## Emmited when a method is called from the DiscourseAPI.
signal method_called(method_string: String, arguments: Array)
## Emmited when a signal is emmited from the DiscourseAPI.
signal signal_emitted(signal_name: String, arguments: Array)


## Loads a dialog and sets the dialog ID to the start of the conversation
## unless a valid [param starting_id] is given.[br]
## Returns [code]true[/code] if the dialog was loaded.
func load_dialog(path: String, starting_id: StringName = &"") -> bool:
	_clear_target_travel_stack()
	
	if _conversation_cache.is_in_cache(path):
		_dialog_resource = _conversation_cache.get_resource(path)
		var dialog_id: String = _dialog_resource.dialog_id
		if _dialog_edits.has(dialog_id) and _dialog_resource._dialog_overrides != _dialog_edits[dialog_id]:
			_dialog_resource._dialog_overrides = _dialog_edits[dialog_id]
		if starting_id.is_empty():
			_next_uuid = _dialog_resource.entry_node
		elif _dialog_resource.node_data.has(starting_id):
			_next_uuid = starting_id
		else:
			var data: Dictionary = _dialog_resource.find_uuid_from_id(starting_id)
			if data["found"]:
				_next_uuid = data["uuid"]
			else:
				_next_uuid = _dialog_resource.entry_node
				NFPluginGameHandler._log_msg(
						"discourse",
						"ID '%s' was not found. Setting to entry",
						NFPluginGameHandler._LogLevel.WARNING)
		return true
	else:
		var res: Resource = load(path)
		if res == null or res is not EditorDiscourseDialog:
			_next_uuid = ""
			_dialog_resource = null
			return false
		var dialog_id: String = res.dialog_id
		if _dialog_edits.has(dialog_id) and res._dialog_overrides != _dialog_edits[dialog_id]:
			res._dialog_overrides = _dialog_edits[dialog_id]
		_conversation_cache.cache_resource(res)
		_dialog_resource = res
	
	if starting_id.is_empty():
		_next_uuid = _dialog_resource.entry_node
	elif _dialog_resource.node_data.has(starting_id):
		_next_uuid = starting_id
	else:
		var data: Dictionary = _dialog_resource.find_uuid_from_id(starting_id)
		if data["found"]:
			_next_uuid = data["uuid"]
		else:
			_next_uuid = _dialog_resource.entry_node
			NFPluginGameHandler._log_msg(
					"discourse",
					"Can't set dialog to inexistent ID '%s'." % starting_id,
					NFPluginGameHandler._LogLevel.ERROR)
	return true


## Sets the dialog to be at a specific point. If invalid it'll
## set the dialog to be at the beggining.
func set_dialog_id(id: StringName) -> void:
	if _dialog_resource == null:
		return
	
	if _dialog_resource.node_data.has(id):
		_next_uuid = id
	else:
		var data: Dictionary = _dialog_resource.find_uuid_from_id(id)
		if data["found"]:
			_next_uuid = data["uuid"]
		else:
			NFPluginGameHandler._log_msg(
					"discourse",
					"'%s' does not exist in dialog. Set aborted." % id,
					NFPluginGameHandler._LogLevel.ERROR)


func _process_logic(uuid: StringName) -> Dictionary[String, Variant]:
	var target: Dictionary[String, Variant] = {"current": &"", "next": &"", "type": -1, "data": {}}
	if uuid.is_empty():
		return target
	
	var data: Dictionary = _dialog_resource.node_data.get(uuid, {})
	
	if data.is_empty():
		NFPluginGameHandler._log_msg(
			"discourse",
			"Data for node with NFUUID '%s' was not found." % uuid,
			NFPluginGameHandler._LogLevel.ERROR)
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
				var settings: Dictionary = _dialog_resource.node_data.get(data["input_connections"]["dialog_settings"]["target_node_uuid"], {})
				if not settings.is_empty() and not settings["input_connections"]["font_resource"]["target_node_uuid"].is_empty():
					font = _get_data(settings["input_connections"]["font_resource"]["target_node_uuid"], font)
				if not settings["input_connections"]["dialog_scene"]["target_node_uuid"].is_empty():
					scene = _get_data(settings["input_connections"]["dialog_scene"]["target_node_uuid"], scene)
				if not settings["input_connections"]["dialog_speed"]["target_node_uuid"].is_empty():
					speed = _get_data(settings["input_connections"]["dialog_speed"]["target_node_uuid"], speed)
				if not settings["input_connections"]["metadata"]["target_node_uuid"].is_empty():
					var metadata_node: Dictionary = _dialog_resource.node_data.get(settings["input_connections"]["metadata"]["target_node_uuid"], {})
					if not metadata_node.is_empty() and metadata_node.has_all(["input_connections", "metadata"]) and metadata_node["metadata"].has("metadata_connections"):
						for meta_entry: Dictionary in metadata_node["metadata"]["metadata_connections"]:
							if not metadata_node["input_connections"].has(meta_entry["id"]):
								NFPluginGameHandler._log_msg(
									"dialog-exporter",
									"Metadata connection missing for '%s' on node '%s' on resource '%s'. Setting to NULL." % [meta_entry["id"], metadata_node["name"], _dialog_resource.resource_path],
									NFPluginGameHandler._LogLevel.ERROR)
								dialog_metadata[meta_entry["id"]] = null
							else:
								dialog_metadata[meta_entry["id"]] = _get_data(metadata_node["input_connections"][meta_entry["id"]]["target_node_uuid"])
			
			if not data["input_connections"]["character_settings"]["target_node_uuid"].is_empty():
				var settings: Dictionary = _dialog_resource.node_data.get(data["input_connections"]["character_settings"]["target_node_uuid"], {})
				if settings.is_empty():
					NFPluginGameHandler._log_msg(
							"discourse",
							"Coudln't access node '%s' connected to node with ID '%s'" % [data["input_connections"]["character_settings"]["target_node_uuid"], data.get("name", "(UNKNOWN)")],
							NFPluginGameHandler._LogLevel.ERROR)
				else:
					if not settings["input_connections"]["display_name"]["target_node_uuid"].is_empty():
						display_name = _get_data(settings["input_connections"]["display_name"]["target_node_uuid"], display_name)
					if not settings["input_connections"]["portrait_id"]["target_node_uuid"].is_empty():
						portrait_id = _get_data(settings["input_connections"]["portrait_id"]["target_node_uuid"], display_name)
			
			if data["input_connections"]["dialog_text_source"]["target_node_uuid"].is_empty():
				var text_data: Dictionary[String, Variant] = _dialog_resource._get_text_data_localized(uuid, locale)
				target["data"] = {
					"dialog_text": _parse_dialog(
							uuid,
							text_data["text"],
							text_data["is_override"]),
					"character_id": metadata["character_id"],
					"persist": metadata["persist"],
					"font": font,
					"scene": scene,
					"speed": speed,
					"display_name": display_name,
					"portrait_id": portrait_id,
					"metadata": dialog_metadata}
			else:
				var data_source = _get_data(data["input_connections"]["dialog_text_source"]["target_node_uuid"], "")
				var text: String = ""
				var is_override: bool = false
				var source_type: int = typeof(data_source)
				
				if source_type == TYPE_STRING:
					text = data_source
				elif source_type == TYPE_DICTIONARY:
					text = data_source.get("text", "")
					is_override = data_source.get("is_override", false)
				else:
					text = "[ERROR GETING DATA FROM %s]" % data["input_connections"]["dialog_text_source"]["target_node_uuid"]
				
				target["data"] = {
					"dialog_text": _parse_dialog(
							uuid,
							text,
							is_override),
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
			var localized_data: Dictionary = _dialog_resource._get_array_data_localized(uuid, locale)
			var localized_choices: PackedStringArray = localized_data["choices"]
			var available_options: Array[Dictionary] = []
			var option_idx: int = -1
			var option_duuid: String = ""
			var is_overridden: bool = localized_data["is_override"]
			
			for option:Dictionary in metadata["choices"]:
				option_idx += 1
				option_duuid = uuid + "_" + str(option_idx)
				
				if option["input_connections"]["settings"]["target_node_uuid"].is_empty():
					option_duuid += "_unlocked"
					available_options.append(
						{
							"unlocked": true,
							"text": _parse_dialog(
									option_duuid,
									localized_choices[option_idx],
									is_overridden),
							"target": option["output_connections"]["next_node"]["target_node_uuid"],
							"metadata": {}})
				else:
					var opt_settings: Dictionary = _dialog_resource.node_data.get(option["input_connections"]["settings"]["target_node_uuid"], {})
					if opt_settings.is_empty():
						NFPluginGameHandler._log_msg(
								"discourse",
								"Couldn't access Settings node '%s' connected to node with ID '%s'" % [option["input_connections"]["settings"]["target_node_uuid"], data.get("name", "(UNKNOWN)")],
								NFPluginGameHandler._LogLevel.ERROR)
						continue
					var show: bool = true if opt_settings["input_connections"]["option_available"]["target_node_uuid"].is_empty() else _get_bool_result(opt_settings["input_connections"]["option_available"]["target_node_uuid"])
				
					if not show:
						continue
					
					var choice_text: String = localized_choices[option_idx]
					var unlocked: bool = true if opt_settings["input_connections"]["option_unlocked"]["target_node_uuid"].is_empty() else _get_bool_result(opt_settings["input_connections"]["option_unlocked"]["target_node_uuid"])
					var option_metadata: Dictionary[String, Variant] = {}
					
					if not unlocked and not opt_settings["input_connections"]["locked_hint"]["target_node_uuid"].is_empty():
						var lock_hint: String = _get_data(opt_settings["input_connections"]["locked_hint"]["target_node_uuid"], "")
						if not lock_hint.is_empty():
							choice_text = lock_hint
							
					if not opt_settings["input_connections"]["metadata"]["target_node_uuid"].is_empty():
						var metadata_node: Dictionary = _dialog_resource.node_data.get(opt_settings["input_connections"]["metadata"]["target_node_uuid"], {})
						if metadata_node.is_empty():
							NFPluginGameHandler._log_msg(
									"discourse",
									"Couldn't access Choice Settings node '%s' connected to node '%s'" % [opt_settings["input_connections"]["metadata"]["target_node_uuid"], data.get("name", "(UNKNOWN)")],
									NFPluginGameHandler._LogLevel.ERROR)
						elif metadata_node.has_all(["input_connections", "metadata"]) and metadata_node["metadata"].has("metadata_connections"):
							for meta_entry: Dictionary in metadata_node["metadata"]["metadata_connections"]:
								if not metadata_node["input_connections"].has(meta_entry["id"]):
									NFPluginGameHandler._log_msg(
											"discourse",
											"Metadata connection missing for '%s' on node '%s' on resource '%s'. Setting to NULL." % [meta_entry["id"], metadata_node["name"], _dialog_resource.resource_path],
											NFPluginGameHandler._LogLevel.ERROR)
									option_metadata[meta_entry["id"]] = null
								else:
									option_metadata[meta_entry["id"]] = _get_data(metadata_node["input_connections"][meta_entry["id"]]["target_node_uuid"])
					if unlocked:
						option_duuid += "_unlocked"
					else:
						option_duuid += "_locked"
					
					available_options.append({
						"unlocked": unlocked,
						"text": _parse_dialog(
								option_duuid,
								choice_text,
								is_overridden),
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
					NFPluginGameHandler._log_msg(
						"discourse",
						"Node '%s' couldn't set data on '%s'" % [data["name"], path.strip_edges().simplify_path()],
						NFPluginGameHandler._LogLevel.ERROR)
			if data["input_connections"]["callable"]["target_node_uuid"] != "":
				var call_data: Dictionary = _dialog_resource.node_data.get(data["input_connections"]["callable"]["target_node_uuid"], {})
				if call_data.is_empty():
					NFPluginGameHandler._log_msg(
							"discourse",
							"Couldn't access Callable node '%s' connected to node with ID '%s'" % [data["input_connections"]["callable"]["target_node_uuid"], data.get("name", "(UNKNOWN)")],
							NFPluginGameHandler._LogLevel.ERROR)
				else:
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
						NFPluginGameHandler._log_msg(
								"discourse",
								"Node '%s' attempted to call inexistent method '%s'." % [data["name"], call_metadata["method"]],
								NFPluginGameHandler._LogLevel.ERROR)
			
			if data["input_connections"]["signal"]["target_node_uuid"] != "":
				var signal_data: Dictionary = _dialog_resource.node_data.get(data["input_connections"]["signal"]["target_node_uuid"], {})
				if signal_data.is_empty():
					NFPluginGameHandler._log_msg(
							"discourse",
							"Couldn't access Signal node '%s' connected to node with ID '%s'" % [data["input_connections"]["signal"]["target_node_uuid"], data.get("name", "(UNKNOWN)")],
							NFPluginGameHandler._LogLevel.ERROR)
				else:
					var signal_metadata: Dictionary = signal_data["metadata"]
					
					if NexusForge.Discourse.API.has_signal(signal_metadata["signal"]):
						var signal_args: Array = []
						
						for arg_connection in signal_metadata["arguments"]:
							signal_args.append(_get_data(arg_connection["target_node_uuid"]))
						
						var api_signal: Signal = Signal(
								NexusForge.Discourse.API,
								signal_metadata["signal"])
						
						if signal_args.is_empty():
							api_signal.emit()
						else:
							var signal_emittion: Callable = api_signal.emit.bindv(signal_args)
							signal_emittion.call()
						
						signal_emitted.emit(signal_metadata["signal"], signal_args)
					else:
						NFPluginGameHandler._log_msg(
								"discourse",
								"Node '%s' attempted to emit an inexistent signal '%s'." % [data["name"], signal_metadata["signal"]],
								NFPluginGameHandler._LogLevel.ERROR)
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
				var weight: int = NFDialogParser.RANDOM_DEFAULT_WEIGHT
				if not choice["input_connections"]["weight"]["target_node_uuid"].is_empty():
					weight = _get_data(choice["input_connections"]["weight"]["target_node_uuid"], weight)
				if weight <= 0:
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
		NodeTypes.SHORTCUT_IN:
			return _process_logic(metadata["anchor_target"])
		NodeTypes.SHORTCUT_OUT:
			return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
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
			_add_target_to_travel_stack(data["output_connections"]["next_node"]["target_node_uuid"])
			return _process_logic(metadata["travel_target"])
		NodeTypes.TRAVEL_TARGET:
			return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		NodeTypes.TRAVEL_BACK:
			if _get_target_travel_stack_size() == 0:
				NFPluginGameHandler._log_msg(
						"discourse",
						"Travel Back node '%s' called, but no item remains in the travel stack" % data.get("name", "ID NOT FOUND"),
						NFPluginGameHandler._LogLevel.WARNING)
			return _process_logic(_pop_last_travel_node_stack())
		NodeTypes.DIALOG_MERGE:
			return _process_logic(data["output_connections"]["next_node"]["target_node_uuid"])
		_:
			return target


func _get_data(from_uuid: StringName, fallback = null) -> Variant:
	if _dialog_resource == null or not _dialog_resource.node_data.has(from_uuid):
		return null
	
	var data: Dictionary = _dialog_resource.node_data.get(from_uuid, {})
	
	var metadata: Dictionary = data["metadata"]
	
	match data["type"]:
		NodeTypes.VALUE:
			return metadata["value"]
		NodeTypes.RANDOM_VALUE:
			match metadata["mode"]:
				TYPE_INT:
					var val_base: int = metadata["values"]["base"]
					var val_max: int = metadata["values"]["max"]
					
					var override_base: StringName = data["input_connections"]["base_value"]["target_node_uuid"]
					var override_max: StringName = data["input_connections"]["max_value"]["target_node_uuid"]
					if not override_base.is_empty():
						val_base = _get_data(override_base, val_base)
					if not override_max.is_empty():
						val_max = _get_data(override_max, val_max)
					
					if val_max < val_base:
						val_max = val_base
					return randi_range(val_base, val_max)
				TYPE_FLOAT:
					var val_base: float = metadata["values"]["base"]
					var val_max: float = metadata["values"]["max"]
					
					var override_base: StringName = data["input_connections"]["base_value"]["target_node_uuid"]
					var override_max: StringName = data["input_connections"]["max_value"]["target_node_uuid"]
					if not override_base.is_empty():
						val_base = _get_data(override_base, val_base)
					if not override_max.is_empty():
						val_max = _get_data(override_max, val_max)
					
					if val_max < val_base:
						val_max = val_base
					
					return snappedf(
							randf_range(val_base, val_max),
							FLOAT_SNAP)
				TYPE_BOOL:
					var val_base: float = metadata["values"]["base"]
					
					var override_base: StringName = data["input_connections"]["base_value"]["target_node_uuid"]
					if not override_base.is_empty():
						val_base = _get_data(override_base, val_base)
					
					if val_base <= 0:
						return false
					elif 100 <= val_base:
						return true
					else:
						var true_range: int = randi_range(1, 100)
						return true_range <= val_base
				_:
					return fallback
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
			var args: Array = []
			for argument in metadata["arguments"]:
				args.append(
						_get_data(argument["target_node_uuid"]))
			return NexusForge.Discourse.API.callv(
					metadata["method"],
					args)
		NodeTypes.DATA_EVENT:
			if metadata["variable_path"] != "" and data["input_connections"]["variable_value"] != "":
				var path: String = metadata["variable_path"]
				var data_conn = _get_data(data["input_connections"]["variable_value"]["target_node_uuid"])
				if NexusForge.Blackboard.set_variable(
						path,
						data_conn):
					data_set.emit(path, data_conn)
				else:
					NFPluginGameHandler._log_msg(
							"discourse",
							"Node '%s' couldn't set data on path '%s'." % [data["name"], path.strip_edges().simplify_path()],
							NFPluginGameHandler._LogLevel.ERROR)
			if data["input_connections"]["callable"]["target_node_uuid"] != "":
				var call_data: Dictionary = _dialog_resource.node_data.get(data["input_connections"]["callable"]["target_node_uuid"], {})
				if call_data.is_empty():
					NFPluginGameHandler._log_msg(
							"discourse",
							 "Couldn't access Callable node '%s' connected to node with ID '%s'" % [data["input_connections"]["callable"]["target_node_uuid"], data.get("name", "(UNKNOWN)")],
							NFPluginGameHandler._LogLevel.ERROR)
				elif NexusForge.Discourse.API.has_method(call_data["metadata"]["method"]):
					var call_args: Array = []
					
					for arg_connection in call_data["metadata"]["arguments"]:
						call_args.append(
								_get_data(arg_connection["target_node_uuid"]))
					
					NexusForge.Discourse.API.callv(
							call_data["metadata"]["method"],
							call_args)
					method_called.emit(call_data["metadata"]["method"], call_args.duplicate(true))
				else:
					NFPluginGameHandler._log_msg(
						"discourse",
						"Node %s attempted to call an inexistent method '%s'." % [data["name"], call_data["metadata"]["method"]],
						NFPluginGameHandler._LogLevel.ERROR)
			
			if data["input_connections"]["signal"]["target_node_uuid"] != "":
				var signal_data: Dictionary = _dialog_resource.node_data.get(data["input_connections"]["signal"]["target_node_uuid"], {})
				if signal_data.is_empty():
					NFPluginGameHandler._log_msg(
							"discourse",
							"Couldn't access Signal node '%s' connected to node with ID '%s'" % [data["input_connections"]["signal"]["target_node_uuid"], data.get("name", "(UNKNOWN)")],
							NFPluginGameHandler._LogLevel.ERROR)
				elif NexusForge.Discourse.API.has_signal(signal_data["metadata"]["signal"]):
					var signal_args: Array = []
					var api_signal: Signal = Signal(
						NexusForge.Discourse.API,
						signal_data["metadata"]["signal"])
					
					for arg_connection in signal_data["metadata"]["arguments"]:
						signal_args.append(_get_data(arg_connection["target_node_uuid"]))
					
					api_signal.emit.callv(signal_args)
					
					signal_emitted.emit(signal_data["metadata"]["signal"], signal_args)
				else:
					NFPluginGameHandler._log_msg(
						"discourse",
						"Node %s attempted to emit an inexistent signal '%s'." % [data["name"], signal_data["metadata"]["signal"]],
						NFPluginGameHandler._LogLevel.ERROR)
			return _get_data(data["input_connections"]["data_input"]["target_node_uuid"])
		NodeTypes.LOCALIZED_TEXT:
			return _dialog_resource._get_text_data_localized(
					from_uuid,
					locale)
		NodeTypes.CONDITION_SELECT:
			var true_value: bool = _get_bool_result(data["input_connections"]["result"]["target_node_uuid"])
			if true_value:
				return _get_data(data["input_connections"]["true_value"]["target_node_uuid"])
			else:
				return _get_data(data["input_connections"]["false_value"]["target_node_uuid"])
		NodeTypes.RESOURCE:
			return metadata["resource_path"]
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
			return null


func _get_current_dialog_id() -> StringName:
	if is_instance_valid(_dialog_resource):
		return StringName(_dialog_resource.dialog_id)
	return &""


func _dialog_resource_set() -> void:
	return


func _parse_dialog(dialog_id: String, dialog_text: String, is_override: bool) -> String:
	if not ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path(
					"use_discourse_parser"),
					true):
		return dialog_text
	
	var DUUID: String = ""
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
	parsed.locale = locale
	parsed.dialog = dialog_text
	
	var functions_processed: Dictionary[String, Variant] = {}
	var variables_processed: Dictionary[String, Variant] = {}
	var phrases_processed: Dictionary[String, Variant] = {}
	var random_processed: Dictionary[String,Variant] = {}
	
	for reg_result in _parser_regex.search_all(dialog_text):
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
			
			var phrase: String = _dialog_resource._get_format_string_localized(phrase_key, locale)
			
			var argument_cases: Dictionary[String, Dictionary] = _dialog_resource._get_format_string_args_localized(
					phrase_key,
					locale)
			
			parsed.create_format_phrase(
					format_key,
					phrase,
					argument_cases)
			
			for format_result in _parser_regex.search_all(phrase):
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
	if _dialog_resource == null or _current_uuid.is_empty() or not _dialog_resource.node_data.has(_current_uuid):
		return
	
	var dialog_type: NodeTypes = _dialog_resource.node_data[_current_uuid]["type"]
	
	if dialog_type != NodeTypes.DIALOG and dialog_type != NodeTypes.CHOICES:
		return
	var result: Dictionary[String, Variant] = _process_logic(_current_uuid)
	
	if result["type"] == NodeTypes.DIALOG:
		dialog_reached.emit(result["data"])
	elif result["type"] == NodeTypes.CHOICES:
		choices_reached.emit(result["data"])


## Progresses the conversation
func advance() -> void:
	if _dialog_resource == null:
		return
	
	if _next_uuid.is_empty() or _dialog_resource.has_dialog_entry(_next_uuid):
		super()
	else:
		NFPluginGameHandler._log_msg(
			"discourse",
			"Can't advance to inexistent dialog entry '%s'." % _next_uuid,
			NFPluginGameHandler._LogLevel.ERROR)


func _get_bool_result(from_uuid: String) -> bool:
	if _dialog_resource == null or from_uuid.is_empty() or not _dialog_resource.node_data.has(from_uuid):
		return false
	
	var result: Variant = _get_data(from_uuid, false)
	
	var result_type: int = typeof(result)
	if result_type == TYPE_BOOL:
		return result
	elif result_type == TYPE_INT or result_type == TYPE_FLOAT:
		return bool(result)
	
	return false
