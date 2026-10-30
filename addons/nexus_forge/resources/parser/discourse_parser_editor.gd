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

var _next_node_uuid: String = "":
	set(uid):
		_next_node_uuid = uid
		if uid.is_empty():
			_next_id = &""
		elif _dialog_resource.node_data.has(uid) and _dialog_resource.node_data[uid].has("name"):
			_next_id = StringName(_dialog_resource.node_data[uid]["name"])
		else:
			NFPluginGameHandler._log_msg(
					"discourse",
					"Couldn't find ID for node '%s'" % uid,
					NFPluginGameHandler._LogLevel.ERROR)

var _current_node_uuid: String = "":
	set(uid):
		_current_node_uuid = uid
		if uid.is_empty():
			_current_id = &""
		elif _dialog_resource.node_data.has(uid) and _dialog_resource.node_data[uid].has("name"):
			_current_id = StringName(_dialog_resource.node_data[uid]["name"])
		else:
			NFPluginGameHandler._log_msg(
					"discourse",
					"Couldn't find ID for node '%s'" % uid,
					NFPluginGameHandler._LogLevel.ERROR)

## Loads a dialog and sets the dialog ID to the start of the conversation
## unless a valid [param starting_id] is given.[br]
## Returns [code]true[/code] if the dialog was loaded.
func load_dialog(path: String, starting_id: StringName = &"") -> bool:
	_clear_target_travel_stack()
	
	if _conversation_cache.is_in_cache(path):
		_dialog_resource = _conversation_cache.get_resource(path)
		var dialog_id: String = _dialog_resource.dialog_id
		
		var d_o: RefCounted = _dialog_edits.get(dialog_id)
		var p_o: RefCounted = _phrase_overrides.get(dialog_id)
		
		if _dialog_resource._dialog_overrides != d_o:
			_dialog_resource._dialog_overrides = d_o
		if _dialog_resource._phrase_overrides != p_o:
			_dialog_resource._phrase_overrides = p_o
		
		if starting_id.is_empty():
			_next_node_uuid = _dialog_resource.entry_node_uuid
		elif _dialog_resource.node_data.has(starting_id):
			_next_node_uuid = String(starting_id)
		else:
			var data: Dictionary = _dialog_resource.find_uuid_from_id(starting_id)
			if data["found"]:
				_next_node_uuid = data["uuid"]
			else:
				_next_node_uuid = _dialog_resource.entry_node_uuid
				NFPluginGameHandler._log_msg(
						"discourse",
						"ID '%s' was not found. Setting to entry" % starting_id,
						NFPluginGameHandler._LogLevel.WARNING)
		return true
	else:
		var res: Resource = load(path)
		if res == null or res is not EditorDiscourseDialog:
			_next_node_uuid = ""
			_dialog_resource = null
			return false
		var dialog_id: String = res.dialog_id
		
		var d_o: RefCounted = _dialog_edits.get(dialog_id)
		var p_o: RefCounted = _phrase_overrides.get(dialog_id)
		
		if res._dialog_overrides != d_o:
			res._dialog_overrides = d_o
		if res._phrase_overrides != p_o:
			res._phrase_overrides = p_o
		
		_conversation_cache.cache_resource(res)
		_dialog_resource = res
	
	if starting_id.is_empty():
		_next_node_uuid = _dialog_resource.entry_node_uuid
	elif _dialog_resource.node_data.has(starting_id):
		_next_node_uuid = starting_id
	else:
		var data: Dictionary = _dialog_resource.find_uuid_from_id(starting_id)
		if data["found"]:
			_next_node_uuid = data["uuid"]
		else:
			_next_node_uuid = _dialog_resource.entry_node_uuid
			NFPluginGameHandler._log_msg(
					"discourse",
					"Can't set dialog to inexistent ID '%s'." % starting_id,
					NFPluginGameHandler._LogLevel.ERROR)
	return true


## Sets the dialog to be at a specific point. If invalid it'll
## set the dialog to be at the beggining.
func set_dialog_id(id: StringName) -> bool:
	if _dialog_resource == null:
		return false
	
	if _dialog_resource.node_data.has(id):
		_next_node_uuid = id
	else:
		var data: Dictionary = _dialog_resource.find_uuid_from_id(id)
		if data["found"]:
			_next_node_uuid = data["uuid"]
		else:
			NFPluginGameHandler._log_msg(
					"discourse",
					"Attempted to set an invalid dialog ID '%s' in loaded resource. Setting to dialogue end." % id,
					NFPluginGameHandler._LogLevel.ERROR)
			_next_node_uuid = ""
			return false
	return true


## Sets the state of the current dialog from a dictionary.
func set_state(to: Dictionary) -> bool:
	var new_id: StringName = &""
	var next_id: StringName = &""
	var conv_started: bool = false
	var new_stack: Array[StringName] = []
	
	var stack_value: Variant = to.get("dialog_travel_stack")
	if typeof(stack_value) == TYPE_ARRAY:
		for item in stack_value:
			var arr_type: int = typeof(item)
			if arr_type == TYPE_STRING or arr_type == TYPE_STRING_NAME:
				new_stack.append(StringName(item))
			else:
				NFPluginGameHandler._log_msg(
						"discourse",
						"Couldn't restore dialog stack. Item in stack is not String/StringName. Item type: %s" % type_string(arr_type),
						NFPluginGameHandler._LogLevel.ERROR)
				return false
	else:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Wrong or missing data for travel stack: %s. Setting to empty" % str(stack_value),
				NFPluginGameHandler._LogLevel.ERROR)
	
	var to_value: Variant = to.get("current_dialog_id")
	var type: int = typeof(to_value)
	if type == TYPE_STRING_NAME or type == TYPE_STRING:
		new_id = StringName(to_value)
	else:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Wrong or missing current dialogue from data: %s. Setting to empty." % str(to_value),
				NFPluginGameHandler._LogLevel.WARNING)
	
	var next_value: Variant = to.get("next_dialog_id")
	var type_next: int = typeof(next_value)
	if type_next == TYPE_STRING_NAME or type_next == TYPE_STRING:
		next_id = StringName(next_value)
	else:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Wrong or missing next dialogue from data: %s. Setting to empty." % str(next_value),
				NFPluginGameHandler._LogLevel.WARNING)
	
	var started_value: Variant = to.get("conversation_started")
	var type_started: int = typeof(started_value)
	if type_started == TYPE_BOOL:
		conv_started = started_value
	else:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Wrong or missing dialogue started from data: %s. Setting to false." % str(started_value),
				NFPluginGameHandler._LogLevel.WARNING)
	
	# Translate the IDs to UUIDs. Provides bridge with release data.
	var curr_id_data: Dictionary = _dialog_resource.find_uuid_from_id(new_id)
	var next_id_data: Dictionary = _dialog_resource.find_uuid_from_id(next_id)
	
	_clear_target_travel_stack()
	
	# Keep the layers in sync. Set these first as they update the base ones
	_current_node_uuid = curr_id_data["uuid"]
	_next_node_uuid = next_id_data["uuid"]
	
	# Set these ones next. Mimic relese behaviour
	_current_id = new_id
	_next_id = next_id
	
	# Assign the rest
	_conversation_started = conv_started
	_node_travel_stack.assign(new_stack)
	
	return true


func _process_logic(id: StringName) -> Dictionary[String, Variant]:
	const T: String = "target_node_uuid"
	const I: String = "input_connections"
	const O: String = "output_connections"
	
	var target: Dictionary[String, Variant] = {"current": "", "next": "", "type": -1, "data": {}}
	if id.is_empty():
		return target
	
	var E: Dictionary = NFDictUtils.EMPTY_DICT
	
	var translation_layer: Dictionary = _dialog_resource.find_uuid_from_id(id)
	
	if not translation_layer["found"]:
		return target
	
	var process_next: String = translation_layer["uuid"]
	var node_data: Dictionary = _dialog_resource.node_data.get(process_next, E)
	var remaining_travels: int = _NODE_PROCESS_MAX_TRAVEL
	
	while not node_data.is_empty() and 0 < remaining_travels:
		var current_node: String = process_next
		var metadata: Dictionary = node_data.get("metadata", E)
		match node_data.get("type", NodeTypes.INVALID):
			NodeTypes.ENTRY:
				process_next = node_data.get(
						"output_connections",
						E).get("next_node", E).get(T, "")
			NodeTypes.DIALOG:
				var input_conns: Dictionary = node_data.get("input_connections", E)
				var output_conns: Dictionary = node_data.get("output_connections", E)
				
				var font: String = ""
				var scene: String = ""
				var speed: float = 0.0
				var display_name: String = ""
				var portrait_id: String = ""
				var character_id: StringName = metadata.get("character_id", &"")
				var text_persist: bool = metadata.get("persist", false)
				var dialog_metadata: Dictionary[String, Variant] = {}
				
				# --- Connections ---
				var setting_target: String = input_conns.get("dialog_settings", E).get(T, "")
				var char_settings_node: String = input_conns.get("character_settings", E).get(T, "")
				var text_source_node: String = input_conns.get("dialog_text_source", E).get(T, "")
				
				if not setting_target.is_empty():
					var settings: Dictionary = _dialog_resource.node_data.get(setting_target, E)
					var sett_inputs: Dictionary = settings.get("input_connections", E)
					var font_target: String = sett_inputs.get("font_resource", E).get(T, "")
					var scene_target: String = sett_inputs.get("dialog_scene", E).get(T, "")
					var speed_target: String = sett_inputs.get("dialog_speed", E).get(T, "")
					var metadata_node: String = sett_inputs.get("metadata", E).get(T, "")
					
					if not font_target.is_empty():
						font = _get_data_string(font_target, font)
					if not scene_target.is_empty():
						scene = _get_data_string(scene_target, scene)
					if not speed_target.is_empty():
						var speed_data: Variant = _get_data_editor(speed_target, speed)
						var type: int = typeof(speed_data)
						if type == TYPE_INT or type == TYPE_FLOAT:
							speed = speed_data
					if not metadata_node.is_empty():
						var metadata_data: Dictionary = _dialog_resource.node_data.get(metadata_node, E)
						if not metadata_data.is_empty():
							var meta_in_connections: Dictionary = metadata_data.get(I, E)
							var meta_data: Dictionary = metadata_data.get("metadata", E)
							var meta_connections: Array = meta_data.get("metadata_connections", NFArrayUtils.EMPTY)
							
							for meta_entry: Dictionary in meta_connections:
								var id_found: bool = meta_entry.has("id")
								var meta_id: String = meta_entry.get("id", "[UNKNOWN]")
								
								if id_found and meta_in_connections.has(meta_id):
									dialog_metadata[meta_id] = _get_data_editor(meta_in_connections.get(meta_id, E).get(T, ""))
								else:
									if id_found:
										NFPluginGameHandler._log_msg(
											"discourse",
											"Metadata connection missing for '%s' on node '%s' on resource '%s'. Setting to NULL." % [meta_id, metadata_data.get("name", "[UNKNOWN]"), _dialog_resource.resource_path],
											NFPluginGameHandler._LogLevel.ERROR)
										dialog_metadata[meta_id] = null
									else:
										NFPluginGameHandler._log_msg(
											"discourse",
											"Metadata ID missing on node '%s' on resource '%s'. Skipping." % [metadata_data.get("name", "[UNKNOWN]"), _dialog_resource.resource_path],
											NFPluginGameHandler._LogLevel.ERROR)
					
				if not char_settings_node.is_empty():
					var char_settings: Dictionary = _dialog_resource.node_data.get(char_settings_node, E)
					if char_settings.is_empty():
						NFPluginGameHandler._log_msg(
								"discourse",
								"Coudln't access node '%s' connected to node with ID '%s'" % [char_settings_node, node_data.get("name", "(UNKNOWN)")],
								NFPluginGameHandler._LogLevel.ERROR)
					else:
						var char_inputs: Dictionary = char_settings.get("input_connections", E)
						var display_name_node: String = char_inputs.get("display_name", E).get(T, "")
						var portrait_id_node: String = char_inputs.get("portrait_id", E).get(T, "")
						
						if not display_name_node.is_empty():
							display_name = _get_data_string(display_name_node, display_name)
						if not portrait_id_node.is_empty():
							portrait_id = _get_data_string(portrait_id_node, portrait_id)
				
				if text_source_node.is_empty():
					var text_data: Dictionary[String, Variant] = _dialog_resource._get_text_data_localized(current_node, locale)
					target["data"] = {
						"dialog_text": _parse_dialog(
								current_node,
								text_data["text"],
								text_data["is_override"]),
						"character_id": character_id,
						"persist": text_persist,
						"font": font,
						"scene": scene,
						"speed": speed,
						"display_name": display_name,
						"portrait_id": portrait_id,
						"metadata": dialog_metadata}
				else:
					var data_source = _get_data_editor(text_source_node, "")
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
					
					target["data"] = {
						"dialog_text": _parse_dialog(
								current_node,
								text,
								is_override),
						"character_id": character_id,
						"persist": text_persist,
						"font": font,
						"scene": scene,
						"speed": speed,
						"display_name": display_name,
						"portrait_id": portrait_id,
						"metadata": dialog_metadata}
				
				target["type"] = NodeTypes.DIALOG
				target["current"] = current_node
				target["next"] = output_conns.get("next_node", E).get(T, "")
				return target
			NodeTypes.CHOICES:
				var localized_data: Dictionary = _dialog_resource._get_array_data_localized(current_node, locale)
				var localized_choices: PackedStringArray = localized_data["choices"]
				var available_options: Array[Dictionary] = []
				var option_idx: int = -1
				var option_duuid: String = ""
				var is_overridden: bool = localized_data["is_override"]
				
				for option:Dictionary in metadata.get("choices", NFArrayUtils.EMPTY):
					var input_connections: Dictionary = option.get(I, E)
					var output_connections: Dictionary = option.get(O, E)
					
					var choice_target: String = output_connections.get("next_node", E).get(T, "")
					var settings_node: String = input_connections.get("settings", E).get(T, "")
					
					option_idx += 1
					option_duuid = String(current_node) + "_" + str(option_idx)
					
					if settings_node.is_empty():
						option_duuid += "_unlocked"
						available_options.append({
								"unlocked": true,
								"text": _parse_dialog(
										option_duuid,
										localized_choices[option_idx],
										is_overridden),
								"target": choice_target,
								"metadata": {}})
					else:
						var opt_settings: Dictionary = _dialog_resource.node_data.get(settings_node, E)
						var opt_node_inputs: Dictionary = opt_settings.get(I, E)
						var available_node: String = opt_node_inputs.get("option_available", E).get(T, "")
						
						if opt_settings.is_empty():
							NFPluginGameHandler._log_msg(
									"discourse",
									"Couldn't access Settings node '%s' connected to node with ID '%s'" % [settings_node, node_data.get("name", "(UNKNOWN)")],
									NFPluginGameHandler._LogLevel.ERROR)
							continue
						
						var show: bool = true if available_node.is_empty() else _get_bool_result(available_node, true)
					
						if not show:
							continue
						
						var unlocked_node: String = opt_node_inputs.get("option_unlocked", E).get(T, "")
						var hint_node: String = opt_node_inputs.get("locked_hint", E).get(T, "")
						var metadata_node: String = opt_node_inputs.get("metadata", E).get(T, "")
						
						var choice_text: String = localized_choices[option_idx]
						var unlocked: bool = true if unlocked_node.is_empty() else _get_bool_result(unlocked_node, true)
						var option_metadata: Dictionary[String, Variant] = {}
						
						if not unlocked and not hint_node.is_empty():
							var lock_hint: String = _get_data_string(hint_node)
							if not lock_hint.is_empty():
								choice_text = lock_hint
						
						if not metadata_node.is_empty():
							var metadata_data: Dictionary = _dialog_resource.node_data.get(metadata_node, E)
							if metadata_data.is_empty():
								NFPluginGameHandler._log_msg(
										"discourse",
										"Couldn't access Choice Settings node '%s' connected to node '%s'" % [metadata_node, node_data.get("name", "(UNKNOWN)")],
										NFPluginGameHandler._LogLevel.ERROR)
							else:
								var meta_inputs: Dictionary = metadata_data.get(I, E)
								var meta_data: Dictionary = metadata_data.get("metadata", E)
								var meta_conn: Array = meta_data.get("metadata_connections", NFArrayUtils.EMPTY)
								
								for meta_entry: Dictionary in meta_conn:
									var has_id: bool = meta_entry.has("id")
									var entry_id: String = meta_entry.get("id", "[UNKNOWN]")
									
									if has_id and meta_inputs.has(entry_id):
										option_metadata[entry_id] = _get_data_editor(meta_inputs[entry_id].get(T, ""))
									else:
										if has_id:
											NFPluginGameHandler._log_msg(
													"discourse",
													"Metadata connection missing for '%s' on node '%s' on resource '%s'. Setting to NULL." % [entry_id, metadata_data.get("name", "[UNKNOWN]"), _dialog_resource.resource_path],
													NFPluginGameHandler._LogLevel.ERROR)
											option_metadata[meta_entry["id"]] = null
											pass
										else:
											NFPluginGameHandler._log_msg(
													"discourse",
													"Metadata ID missing on node '%s' on resource '%s'. Skipping." % [metadata_data.get("name", "[UNKNOWN]"), _dialog_resource.resource_path],
													NFPluginGameHandler._LogLevel.ERROR)
						
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
							"target": choice_target,
							"metadata": option_metadata})
				
				target["data"] = available_options
				target["type"] = NodeTypes.CHOICES
				target["current"] = current_node
				target["next"] = current_node
				return target
			NodeTypes.BRANCH:
				var output_conn: Dictionary = node_data.get(O, E)
				var use_a: bool = true
				var eval_node: String = node_data.get(I, E).get("path_direction", E).get(T, "")
				var next_node: String = ""
				
				if not eval_node.is_empty():
					use_a = _get_bool_result(eval_node, true)
				
				if use_a:
					next_node = output_conn.get(
							"next_node_true", E).get(T, "")
				else:
					next_node = output_conn.get(
							"next_node_false", E).get(T, "")
				
				process_next = next_node
			NodeTypes.EVENT:
				var input_conn: Dictionary = node_data.get(I, E)
				
				var set_node: String = input_conn.get("variable_value", E).get(T, "")
				var callable_node: String = input_conn.get("callable", E).get(T, "")
				var signal_node: String = input_conn.get("signal", E).get(T, "")
				
				var set_path: String = metadata.get("variable_path", "").strip_edges().simplify_path()
				
				if not set_node.is_empty() and not set_path.is_empty():
					var set_data: Variant = _get_data_editor(set_node)
					
					if NexusForge.Blackboard.set_variable(set_path, set_data):
						data_set.emit(set_path, set_data)
					else:
						NFPluginGameHandler._log_msg(
							"discourse",
							"Node '%s' couldn't set data on '%s'" % [node_data.get("name", "[UNKNOWN]"), set_path],
							NFPluginGameHandler._LogLevel.ERROR)
				
				if not callable_node.is_empty():
					var call_data: Dictionary = _dialog_resource.node_data.get(callable_node, E)
					if call_data.is_empty():
						NFPluginGameHandler._log_msg(
								"discourse",
								"Couldn't access Callable node '%s' connected to node with ID '%s'" % [callable_node, node_data.get("name", "[UNKNOWN]")],
								NFPluginGameHandler._LogLevel.ERROR)
					else:
						var call_metadata: Dictionary = call_data.get("metadata", E)
						var method_str: StringName = call_metadata.get("method", &"")
						
						if NexusForge.Discourse.API.has_method(method_str):
							var call_args: Array = []
							
							for arg_connection in call_metadata.get("arguments", NFArrayUtils.EMPTY):
								var arg_target: String = arg_connection.get(T, "")
								if arg_target.is_empty():
									continue
								call_args.append(_get_data_editor(arg_target))
							
							var notif_args: Array = call_args.duplicate(true)
							
							NexusForge.Discourse.API.callv(
									method_str,
									call_args)
							
							method_called.emit(method_str, notif_args)
						else:
							NFPluginGameHandler._log_msg(
									"discourse",
									"Node '%s' attempted to call inexistent method '%s'." % [node_data.get("name", "[UNKNOWN]"), method_str],
									NFPluginGameHandler._LogLevel.ERROR)
				
				if not signal_node.is_empty():
					var signal_data: Dictionary = _dialog_resource.node_data.get(signal_node, E)
					if signal_data.is_empty():
						NFPluginGameHandler._log_msg(
								"discourse",
								"Couldn't access Signal node '%s' connected to node with ID '%s'" % [signal_node, node_data.get("name", "[UNKNOWN]")],
								NFPluginGameHandler._LogLevel.ERROR)
					else:
						var signal_metadata: Dictionary = signal_data.get("metadata", E)
						var signal_str: StringName = signal_metadata.get("signal", &"")
						
						if NexusForge.Discourse.API.has_signal(signal_str):
							var signal_args: Array = []
							
							for arg_connection in signal_metadata.get("arguments", NFArrayUtils.EMPTY):
								var arg_target: String = arg_connection.get(T, "")
								if arg_target.is_empty():
									continue
								signal_args.append(_get_data_editor(arg_target))
							
							var notif_args: Array = signal_args.duplicate(true)
							var api_signal: Signal = Signal(
									NexusForge.Discourse.API,
									signal_metadata["signal"])
							
							api_signal.emit.callv(signal_args)
							
							signal_emitted.emit(signal_str, notif_args)
						else:
							NFPluginGameHandler._log_msg(
									"discourse",
									"Node '%s' attempted to emit an inexistent signal '%s'." % [node_data.get("name", "[UNKNOWN]"), signal_str],
									NFPluginGameHandler._LogLevel.ERROR)
				
				process_next = node_data.get(O, E).get("next_node", E).get(T, "")
			NodeTypes.MATCH:
				var next_node: String = node_data.get(O, E).get("default", E).get(T, "")
				var node_with_data: String = node_data.get(I, E).get("match_value_source", E).get(T, "")
				
				if node_with_data.is_empty():
					NFPluginGameHandler._log_msg(
							"discourse",
							"Match node has no data to match with. Selecting default.",
							NFPluginGameHandler._LogLevel.ERROR)
				else:
					var data_to_match: Variant = _get_data_editor(node_with_data)
				
					for case:Dictionary in metadata.get("cases", NFArrayUtils.EMPTY):
						if case.get("value") == data_to_match:
							next_node = case.get(O, E).get("next_node", E).get(T, "")
							break
				
				process_next = next_node
			NodeTypes.PAUSE:
				target["type"] = NodeTypes.PAUSE
				target["current"] = current_node
				target["next"] = node_data.get(O, E).get("next_node", E).get(T, "")
				return target
			NodeTypes.RANDOM:
				var total_weight: int = 0
				var choices: Array[Dictionary] = []
				var default_weight: int = NFDialogParser.RANDOM_DEFAULT_WEIGHT
				
				var def_w_override: String = node_data.get(I, E).get("default_weight", E).get(T, "")
				if not def_w_override.is_empty():
					default_weight = _get_data_editor(def_w_override, default_weight)
				
				for choice:Dictionary in metadata.get("options", NFArrayUtils.EMPTY):
					var weight: int = default_weight
					
					var ch_wg_override: String = choice.get(I, E).get("weight", E).get(T, "")
					if not ch_wg_override.is_empty():
						weight = _get_data_editor(ch_wg_override, weight)
					
					if weight <= 0:
						continue
					choices.append({
						"next": choice.get(O, E).get("next_node", E).get(T, ""),
						"weight": weight})
					total_weight += weight
				
				if choices.is_empty():
					return target
				
				choices.sort_custom(func(a, b): return a["weight"] > b["weight"])
				var random_select: int = randi_range(1, total_weight)
				
				var item_selected: bool = false
				var current_weight: int = 0
				for choice in choices:
					current_weight += choice["weight"]
					if random_select <= current_weight:
						process_next = choice["next"]
						item_selected = true
						break
				
				if not item_selected: # In case of loop error
					process_next = choices[-1]["next"]
			NodeTypes.SHORTCUT_IN:
				process_next = metadata.get("anchor_target", "")
			NodeTypes.SHORTCUT_OUT:
				process_next = node_data.get(O, E).get("next_node", E).get(T, "")
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
				
				# Translation layer
				var next_node: String = node_data.get(O, E).get("next_node", E).get(T, "")
				var node_id: StringName = _to_id(next_node)
				_add_target_to_travel_stack(node_id)
				# -----------------
				
				process_next = metadata.get("travel_target", "")
			NodeTypes.TRAVEL_TARGET:
				process_next = node_data.get(O, E).get("next_node", E).get(T, "")
			NodeTypes.TRAVEL_BACK:
				if _get_target_travel_stack_size() == 0:
					NFPluginGameHandler._log_msg(
							"discourse",
							"Travel Back node '%s' called, but no item remains in the travel stack" % node_data.get("name", "[UNKNOWN]"),
							NFPluginGameHandler._LogLevel.WARNING)
					return target
				
				var prev_id: StringName = _pop_last_travel_node_stack()
				process_next = _to_uuid(prev_id)
			NodeTypes.DIALOG_MERGE:
				process_next = node_data.get(O, E).get("next_node", E).get(T, "")
			_:
				NFPluginGameHandler._log_msg(
						"discourse",
						"Unknown dialog type for node '%s' on resource: %s" % [node_data.get("name", "[UNKNOWN]"), _dialog_resource.resource_path],
						NFPluginGameHandler._LogLevel.ERROR)
				return target
		
		node_data = _dialog_resource.node_data.get(process_next, E)
	
		if node_data.is_empty():
			NFPluginGameHandler._log_msg(
				"discourse",
				"Data for node with NFUUID '%s' was not found." % process_next,
				NFPluginGameHandler._LogLevel.ERROR)
			return target
		
		remaining_travels -= 1
		
	if remaining_travels <= 0:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Exceeded maximum node travel stack at node '%s'. Stopping process." % process_next,
				NFPluginGameHandler._LogLevel.ERROR)
	
	return target


func _get_data_editor(from_uuid: String, fallback = null, _remaining_travels: int = 250) -> Variant:
	if _dialog_resource == null:
		return fallback
	elif _remaining_travels <= 0:
		NFPluginGameHandler._log_msg(
				"discourse",
				"Exceeded maximum data node travel stack at node '%s'. Returning fallback." % from_uuid,
				NFPluginGameHandler._LogLevel.ERROR)
		return fallback
	elif not _dialog_resource.node_data.has(from_uuid):
		NFPluginGameHandler._log_msg(
				"discourse",
				"Unable to get data on a non-existent node '%s'. Returning fallback." % from_uuid,
				NFPluginGameHandler._LogLevel.ERROR)
		return fallback
	
	const T: String = "target_node_uuid"
	const I: String = "input_connections"
	
	var E: Dictionary = NFDictUtils.EMPTY_DICT
	var data: Dictionary = _dialog_resource.node_data.get(from_uuid, E)
	
	var metadata: Dictionary = data.get("metadata", E)
	
	match data.get("type", -1):
		NodeTypes.VALUE:
			return metadata.get("value", fallback)
		NodeTypes.RANDOM_VALUE:
			var inputs: Dictionary = data.get(I, E)
			var values_dict: Dictionary = metadata.get("values", E)
			
			match metadata.get("mode", -1):
				TYPE_INT:
					var val_base: int = values_dict.get("base", 0)
					var val_max: int = values_dict.get("max", 100)
					
					var override_base: String = inputs.get("base_value", E).get(T, "")
					var override_max: String = inputs.get("max_value", E).get(T, "")
					if not override_base.is_empty():
						var override_val: Variant = _get_data_editor(override_base, val_base, _remaining_travels - 1)
						var override_type: int = typeof(override_val)
						if override_type == TYPE_INT or override_type == TYPE_FLOAT:
							val_base = override_val
					
					if not override_max.is_empty():
						var override_val: Variant = _get_data_editor(override_max, val_max, _remaining_travels - 1)
						var override_type: int = typeof(override_val)
						if override_type == TYPE_INT or override_type == TYPE_FLOAT:
							val_max = override_val
					
					if val_max < val_base:
						val_max = val_base
					return randi_range(val_base, val_max)
				TYPE_FLOAT:
					var val_base: float = values_dict.get("base", 0.0)
					var val_max: float = values_dict.get("max", 100.0)
					
					var override_base: String = inputs.get("base_value", E).get(T, "")
					var override_max: String = inputs.get("max_value", E).get(T, "")
					
					if not override_base.is_empty():
						var override_val: Variant = _get_data_editor(override_base, val_base, _remaining_travels - 1)
						var override_type: int = typeof(override_val)
						if override_type == TYPE_INT or override_type == TYPE_FLOAT:
							val_base = override_type
					
					if not override_max.is_empty():
						var override_val: Variant = _get_data_editor(override_max, val_max, _remaining_travels - 1)
						var override_type: int = typeof(override_val)
						if override_type == TYPE_INT or override_type == TYPE_FLOAT:
							val_max = override_type
					
					if val_max < val_base:
						val_max = val_base
					
					return snappedf(
							randf_range(val_base, val_max),
							FLOAT_SNAP)
				TYPE_BOOL:
					var val_base: int = values_dict.get("base", 50)
					
					var override_base: String = inputs.get("base_value", E).get(T, "")
					if not override_base.is_empty():
						var override_val: Variant = _get_data_editor(override_base, val_base, _remaining_travels - 1)
						var override_type: int = typeof(override_val)
						if override_type == TYPE_INT or override_type == TYPE_FLOAT:
							val_base = override_type
					
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
			if not metadata.has("fallback_value"):
				NFPluginGameHandler._log_msg(
						"discourse",
						"Guard node '%s' doesn't have a fallback. Returning function fallback." % data.get("name", "[UNKNOWN]"),
						NFPluginGameHandler._LogLevel.ERROR)
				return fallback
			
			var node_fallback: Variant = metadata["fallback_value"]
			var data_node: String = data.get(I, E).get("value", E).get(T, "")
			var guard_data: Variant = _get_data_editor(data_node, null, _remaining_travels - 1)
			
			if typeof(guard_data) == typeof(node_fallback):
				return guard_data
			else:
				return node_fallback
		NodeTypes.VARIABLE_GET:
			var node_path: String = metadata.get("variable_path", "").strip_edges().simplify_path()
			if node_path.is_empty():
				NFPluginGameHandler._log_msg(
					"discourse",
					"Trying to get data from Blackboard using an empty string. Returning fallback",
					NFPluginGameHandler._LogLevel.ERROR)
				return fallback
			
			return NexusForge.Blackboard.get_variable(node_path, fallback)
		NodeTypes.CALLABLE_RETURN:
			var method_str: StringName = metadata.get("method", &"")
			
			if not NexusForge.Discourse.API.has_method(method_str):
				NFPluginGameHandler._log_msg(
						"discourse",
						"Trying to get data from non-existent method '%s'. Returning fallback." % method_str,
						NFPluginGameHandler._LogLevel.ERROR)
				return fallback
			
			var args: Array = []
			for argument in metadata.get("arguments", NFArrayUtils.EMPTY):
				var arg_node: String = argument.get(T, "")
				if arg_node.is_empty():
					continue
				args.append(_get_data_editor(arg_node, null, _remaining_travels - 1))
			return NexusForge.Discourse.API.callv(
					method_str,
					args)
		NodeTypes.DATA_EVENT:
			var event_inputs: Dictionary = data.get(I, E)
			var data_var_node: String = event_inputs.get("variable_value", E).get(T, "")
			var data_var_path: String = metadata.get("variable_path", "").strip_edges().simplify_path()
			
			var source_node: String = event_inputs.get("data_input", E).get(T, "")
			
			var callable_node: String = event_inputs.get("callable", E).get(T, "")
			var signal_node: String = event_inputs.get("signal", E).get(T, "")
			
			if not data_var_node.is_empty() and not data_var_path.is_empty():
				var data_conn: Variant = _get_data_editor(data_var_node, null, _remaining_travels - 1)
				if NexusForge.Blackboard.set_variable(
						data_var_path,
						data_conn):
					data_set.emit(data_var_path, data_conn)
				else:
					NFPluginGameHandler._log_msg(
							"discourse",
							"Node '%s' couldn't set data on path '%s'." % [data.get("name", "[UNKNOWN]"), data_var_path],
							NFPluginGameHandler._LogLevel.ERROR)
			
			if not callable_node.is_empty():
				var call_data: Dictionary = _dialog_resource.node_data.get(callable_node, E)
				var call_meta: Dictionary = call_data.get("metadata", E)
				var method_str: StringName = call_meta.get("method", &"")
				
				if call_data.is_empty():
					NFPluginGameHandler._log_msg(
							"discourse",
							 "Couldn't access Callable node '%s' connected to node with ID '%s'" % [callable_node, data.get("name", "[UNKNOWN]")],
							NFPluginGameHandler._LogLevel.ERROR)
				elif NexusForge.Discourse.API.has_method(method_str):
					var call_args: Array = []
					
					for arg_connection in call_data["metadata"]["arguments"]:
						var arg_node: String = arg_connection.get(T, "")
						if arg_node.is_empty():
							continue
						call_args.append(_get_data_editor(arg_node, null, _remaining_travels - 1))
					
					var notif_args: Array = call_args.duplicate(true)
					
					NexusForge.Discourse.API.callv(
							method_str,
							call_args)
						
					method_called.emit(method_str, notif_args)
				else:
					NFPluginGameHandler._log_msg(
						"discourse",
						"Node %s attempted to call an inexistent method '%s'." % [data.get("name", "[UNKNOWN]"), method_str],
						NFPluginGameHandler._LogLevel.ERROR)
			
			if not signal_node.is_empty():
				var signal_data: Dictionary = _dialog_resource.node_data.get(signal_node, E)
				var signal_meta: Dictionary = signal_data.get("metadata", E)
				var signal_str: StringName = signal_meta.get("signal", &"")
				
				if signal_data.is_empty():
					NFPluginGameHandler._log_msg(
							"discourse",
							"Couldn't access Signal node '%s' connected to node with ID '%s'" % [signal_node, data.get("name", "[UNKNOWN]")],
							NFPluginGameHandler._LogLevel.ERROR)
				elif NexusForge.Discourse.API.has_signal(signal_str):
					var signal_args: Array = []
					var api_signal: Signal = Signal(
						NexusForge.Discourse.API,
						signal_str)
					
					for arg_connection in signal_meta.get("arguments", NFArrayUtils.EMPTY):
						var arg_target: String = arg_connection.get(T, "")
						if arg_target.is_empty():
							continue
						signal_args.append(_get_data_editor(arg_target, null, _remaining_travels - 1))
					
					var notif_args: Array = signal_args.duplicate(true)
					
					api_signal.emit.callv(signal_args)
					
					signal_emitted.emit(signal_str, notif_args)
				else:
					NFPluginGameHandler._log_msg(
						"discourse",
						"Node %s attempted to emit an inexistent signal '%s'." % [data.get("name", "[UNKNOWN]"), signal_str],
						NFPluginGameHandler._LogLevel.ERROR)
			
			return _get_data_editor(source_node, fallback, _remaining_travels - 1)
		NodeTypes.LOCALIZED_TEXT:
			return _dialog_resource._get_text_data_localized(
					from_uuid,
					locale)
		NodeTypes.CONDITION_SELECT:
			var inputs: Dictionary = data.get(I, E)
			var data_source: String = inputs.get("result", E).get(T, "")
			
			if data_source.is_empty():
				NFPluginGameHandler._log_msg(
						"discourse",
						"Condition select node '%s' has no evaluator. Returning fallback." % data.get("name", "[UNKNOWN]"),
						NFPluginGameHandler._LogLevel.ERROR)
				return fallback
			
			var true_value: bool = _get_bool_result(data_source, false, _remaining_travels - 1)
			
			if true_value:
				var target_true: String = inputs.get("true_value", E).get(T, "")
				return _get_data_editor(target_true, fallback, _remaining_travels - 1)
			else:
				var target_false: String = inputs.get("false_value", E).get(T, "")
				return _get_data_editor(target_false, fallback, _remaining_travels - 1)
		NodeTypes.RESOURCE:
			return metadata.get("resource_path", fallback)
		NodeTypes.COMPARATION:
			var a_node: String = data.get(I, E).get("node_a", E).get(T, "")
			var b_node: String = data.get(I, E).get("node_b", E).get(T, "")
			var operator: int = metadata.get("operator", OP_EQUAL)
			
			if a_node.is_empty():
				NFPluginGameHandler._log_msg(
						"discourse",
						"Node '%s' has no input on port A" % data.get("name", "[UNKNOWN]"),
						NFPluginGameHandler._LogLevel.WARNING)
			if b_node.is_empty():
				NFPluginGameHandler._log_msg(
						"discourse",
						"Node '%s' has no input on port B" % data.get("name", "[UNKNOWN]"),
						NFPluginGameHandler._LogLevel.WARNING)
			
			var value_a: Variant = _get_data_editor(a_node, null, _remaining_travels - 1)
			var value_b: Variant = _get_data_editor(b_node, null, _remaining_travels - 1)
			
			if not _can_compare(value_a, value_b, operator):
				return operator == OP_NOT_EQUAL
			
			match operator:
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
			NFPluginGameHandler._log_msg(
					"discourse",
					"Attempting to get data of a non-data node '%s'. Returning fallback." % data.get("name", "[UNKNOWN]"),
					NFPluginGameHandler._LogLevel.ERROR)
			return fallback
	
	return fallback


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
	if _dialog_resource == null or _current_node_uuid.is_empty() or not _dialog_resource.node_data.has(_current_node_uuid):
		return
	
	var dialog_type: NodeTypes = _dialog_resource.node_data[_current_node_uuid]["type"]
	
	if dialog_type != NodeTypes.DIALOG and dialog_type != NodeTypes.CHOICES:
		return
	var result: Dictionary[String, Variant] = _process_logic(_current_id)
	
	if result["type"] == NodeTypes.DIALOG:
		dialog_reached.emit(result["data"])
	elif result["type"] == NodeTypes.CHOICES:
		choices_reached.emit(result["data"])


## Progresses the conversation
func advance() -> void:
	if _dialog_resource == null:
		return
	
	if not _next_node_uuid.is_empty() and not _dialog_resource.node_data.has(_next_node_uuid):
		NFPluginGameHandler._log_msg(
			"discourse",
			"Can't advance to inexistent dialog entry '%s'." % _next_node_uuid,
			NFPluginGameHandler._LogLevel.ERROR)
		return
		
	if not _conversation_started:
		_conversation_started = true
		dialog_started.emit()
	
	var result: Dictionary[String, Variant] = _process_logic(_next_id)
	
	if result["type"] == -1 or result["type"] == NodeTypes.DIALOG_END:
		_conversation_started = false
		_next_node_uuid = _dialog_resource.entry_node_uuid
		_current_node_uuid = ""
		_clear_target_travel_stack()
		dialog_finished.emit()
	else:
		_current_node_uuid = result["current"]
		_next_node_uuid = result["next"]
		
		match result["type"]:
			NodeTypes.DIALOG:
				dialog_reached.emit(result["data"])
			NodeTypes.CHOICES:
				choices_reached.emit(result["data"])
			NodeTypes.PAUSE:
				dialog_paused.emit()


func _get_bool_result(from_uuid: String, default: bool = false, _remaining_travels: int = 250) -> bool:
	if _dialog_resource == null or from_uuid.is_empty() or not _dialog_resource.node_data.has(from_uuid):
		return default
	
	var result: Variant = _get_data_editor(from_uuid, default, _remaining_travels)
	
	var result_type: int = typeof(result)
	if result_type == TYPE_BOOL:
		return result
	elif result_type == TYPE_INT or result_type == TYPE_FLOAT:
		return bool(result)
	
	return default


func _get_data_string_editor(node_uuid: String, fallback: String = "") -> String:
	var data: Variant = _get_data_editor(node_uuid, fallback)
	var type: int = typeof(data)
	if type == TYPE_STRING:
		return data
	elif type == TYPE_DICTIONARY: # Accounting for localization text
		if data.has("text"):
			var dict_data: Variant = data["text"]
			if typeof(dict_data) == TYPE_STRING:
				return dict_data
	return fallback


func _to_id(uuid: String) -> StringName:
	if _dialog_resource == null:
		return &""
	var id_name: String = _dialog_resource.node_data.get(uuid, NFDictUtils.EMPTY_DICT).get("name", "")
	return StringName(id_name)


func _to_uuid(id: String) -> String:
	if _dialog_resource == null:
		return ""
	var data: Dictionary = _dialog_resource.find_uuid_from_id(id)
	return data["uuid"]
