@tool
extends DiscourseGraphNode


signal signal_changed(uuid: StringName, old_state: Dictionary, new_state: Dictionary)

static var available_signals: Dictionary = {}

var signals_node: OptionButton


static func _static_init() -> void:
	available_signals = get_user_signals()


func _post_init() -> void:
	set_node_id(&"Signal")
	title = "Signal"
	node_type = DialogueNodeType.SIGNAL
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(230, 83)
	
	var signal_keys: Array = available_signals.keys()
	signal_keys.sort_custom(ArrayUtils.sort_custom_alphabetically_asc)
	
	signals_node = OptionButton.new()
	signals_node.name = &"SignalsOptBtn"
	signals_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	signals_node.fit_to_longest_item = false
	signals_node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	for user_signal:String in signal_keys:
		signals_node.add_item(user_signal.capitalize())
		signals_node.set_item_metadata(-1, user_signal)
	
	add_field(
			&"signals",
			signals_node,
			false,
			-1,
			SlotConnectionType.SIGNAL)
	set_slot_color_right(0, COLORS["signal"])
	
	if available_signals.is_empty():
		signals_node.disabled = true
		signals_node.set_meta(&"old_value", "")
	else:
		signals_node.select(0)
		signals_node.set_meta(&"old_value", signals_node.get_item_metadata(0))
		await load_signal(signals_node.get_item_metadata(0))
	
	signals_node.item_selected.connect(_on_signal_selected)


func _ready() -> void:
	graph_icon = get_theme_icon("Signals", "EditorIcons")
	set_output_connection_icon(&"signals", get_theme_icon("Signals", "EditorIcons"))
	for arg_port in range(get_child_count() - 1):
		var id: StringName = StringName("argument_" + str(arg_port + 1))
		match get_input_port_type(arg_port):
			SlotConnectionType.VAR_INT:
				set_input_connection_icon(id, get_theme_icon("int", "EditorIcons"))
			SlotConnectionType.VAR_FLOAT:
				set_input_connection_icon(id, get_theme_icon("float", "EditorIcons"))
			SlotConnectionType.VAR_BOOL:
				set_input_connection_icon(id, get_theme_icon("bool", "EditorIcons"))
			SlotConnectionType.VAR_STRING:
				set_input_connection_icon(id, get_theme_icon("String", "EditorIcons"))
			_:
				set_input_connection_icon(id, get_theme_icon("Variant", "EditorIcons"))


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if available_signals.is_empty() and has_any_output(0):
		issues.append("Warning: Signal is in use but no Signal is available.")
	for arg_idx in range(0, get_child_count() - 1):
		if not has_any_input(arg_idx):
			issues.append("Error: Missing signal argument " + str(arg_idx) + ".")
	return issues


func _get_node_data() -> Dictionary:
	var output_connectons: Dictionary = {
		"signaler": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	var metadata: Dictionary = {
		"signal": get_current_signal(),
		"arguments": get_signal_arguments()}
	
	return _build_node_data(metadata, output_connectons)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if not metadata.has("signal") or typeof(metadata["signal"]) != TYPE_STRING:
		return
	
	if await set_signal(metadata["signal"]):
		signals_node.set_meta(&"old_value", metadata["signal"])


func get_signal_arguments() -> Array[Dictionary]:
	var arguments: Array[Dictionary] = []
	for arg_idx in range(get_child_count() - 1):
		arguments.append(
				get_uuid_and_port_connected_to(
						PortMode.INPUT,
						arg_idx))
	return arguments


func _on_signal_selected(idx: int) -> void:
	var old_value: String = signals_node.get_meta(&"old_value")
	var signal_id: String = signals_node.get_item_metadata(idx)
	
	if signal_id == old_value:
		return
	signals_node.set_meta(&"old_value", signal_id)
	
	var old_state: Dictionary = {
		"metadata": {
			"signal": old_value,
			"arguments": get_signal_arguments()}}
	await load_signal(signal_id)
	var new_state: Dictionary = {
		"metadata": {
			"signal": signal_id,
			"arguments": get_signal_arguments()}}
	
	signal_changed.emit(
			get_node_uuid(),
			old_state,
			new_state)


func reload_signals() -> void:
	available_signals = get_user_signals()
	
	if available_signals.is_empty():
		signals_node.clear()
		await clear_input_args()
		signals_node.disabled = true
		signals_node.set_meta(&"old_value", "")
		return
	
	if signals_node.disabled:
		signals_node.disabled = false
	
	var current_signal: String = "" if signals_node.selected == -1 else signals_node.get_selected_metadata()
	var new_signals = available_signals.keys()
	var new_idx: int = -1
	
	new_signals.sort_custom(ArrayUtils.sort_custom_alphabetically_asc)
	
	if current_signal != "":
		new_idx = new_signals.find(current_signal)
	
	signals_node.clear()
	
	for new_signal:String in new_signals:
		signals_node.add_item(new_signal.capitalize())
		signals_node.set_item_metadata(-1, new_signal)
	
	if new_idx == -1:
		signals_node.select(0)
		signals_node.set_meta(&"old_value", signals_node.get_item_metadata(0))
		await load_signal(signals_node.get_item_metadata(0))
		node_updated.emit()
		return
	else:
		signals_node.select(new_idx)
		await load_signal(current_signal)


func set_signal(signal_id: String) -> bool:
	if not available_signals.has(signal_id):
		return false
	
	for idx in range(signals_node.item_count):
		if signals_node.get_item_metadata(idx) == signal_id:
			signals_node.select(idx)
			signals_node.set_meta(&"old_value", signal_id)
			await load_signal(signal_id)
			return true
	
	return false


func load_signal(signal_id: String) -> void:
	if not available_signals.has(signal_id):
		return
	
	var arg_idx: int = -1 # With the index
	var arg_count: int = get_child_count() - 1
	
	for new_arg:Dictionary in available_signals[signal_id]:
		arg_idx += 1
		
		if arg_count <= arg_idx:
			add_input_arg(new_arg["name"], new_arg["type"])
			arg_count += 1
			continue # And we continue
		
		var current_input_type: int = get_slot_type_left(arg_idx + 1)
		var new_data_type: int = new_arg["type"]
		var new_port_type: int = 0
		var new_type_color: String = ""
		var compatible: bool = false
		var new_icon: Texture2D = null
		
		match new_data_type:
			TYPE_INT:
				new_port_type = SlotConnectionType.VAR_INT
				new_type_color = "integer"
				new_icon = get_theme_icon("int", "EditorIcons")
			TYPE_FLOAT:
				new_port_type = SlotConnectionType.VAR_FLOAT
				new_type_color = "float"
				new_icon = get_theme_icon("float", "EditorIcons")
			TYPE_BOOL:
				new_port_type = SlotConnectionType.VAR_BOOL
				new_type_color = "bool"
				new_icon = get_theme_icon("bool", "EditorIcons")
			TYPE_STRING:
				new_port_type = SlotConnectionType.VAR_STRING
				new_type_color = "string"
				new_icon = get_theme_icon("String", "EditorIcons")
			_:
				new_port_type = SlotConnectionType.VAR_ANY
				new_type_color = "any"
				new_icon = get_theme_icon("Variant", "EditorIcons")
		
		if has_any_input(arg_idx):
			match current_input_type:
				SlotConnectionType.VAR_INT:
					compatible = new_data_type == TYPE_INT
				SlotConnectionType.VAR_FLOAT:
					compatible = new_data_type == TYPE_FLOAT
				SlotConnectionType.VAR_BOOL:
					compatible = new_data_type == TYPE_BOOL
				SlotConnectionType.VAR_STRING:
					compatible = new_data_type == TYPE_STRING
				SlotConnectionType.VAR_ANY: # The current port accepts anything
					# We grab the node that connects to the argument
					var input_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, arg_idx)
					# And grab the port type of that node
					var output_type: int = -1 if input_target == null else input_target.get_output_port_type(
							input_target.get_port_connected_to(PortMode.OUTPUT, self, arg_idx))
					
					# And it's compatible if the new port type matches the output
					# port of the node connected to this one or is an "any".
					compatible = output_type == new_port_type or output_type == SlotConnectionType.VAR_ANY
			
			if not compatible: # If it isn't compatible we disconnect it.
				disconnect_port(PortMode.INPUT, arg_idx)
				await node_disconnected
		
		get_index_field(arg_idx + 1).text = new_arg["name"].capitalize()
		
		# If the types don't match we assign the type, change the color and icon.
		if current_input_type != new_port_type:
			set_slot_color_left.call_deferred(arg_idx + 1, COLORS[new_type_color])
			set_slot_type_left.call_deferred(arg_idx + 1, new_port_type)
	
	var fields_to_remove: Array[StringName] = []
	for item in range(arg_idx + 2, get_child_count()):
		var field_id: StringName = StringName("argument_" + str(item))
		fields_to_remove.append(field_id)
	
	if not fields_to_remove.is_empty():
		await remove_fields(fields_to_remove)
		_reset_height.call_deferred()


func get_current_signal() -> String:
	if signals_node.selected == -1:
		return ""
	else:
		return signals_node.get_item_metadata(signals_node.selected)


func add_input_arg(arg_text: String, arg_type: int) -> void:
	var slot_target: int = get_child_count()
	var arg: Label = Label.new()
	var slot_type: SlotConnectionType = SlotConnectionType.VAR_ANY
	var field_id: StringName = &"argument_" + StringName(str(slot_target))
	var input_icon: Texture2D = get_theme_icon("Variant", "EditorIcons")
	var input_color: Color = COLORS["any"]
	arg.custom_minimum_size.y = 24
	arg.text = arg_text.capitalize()
	arg.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	arg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	match arg_type:
		TYPE_INT:
			slot_type = SlotConnectionType.VAR_INT
			input_icon = get_theme_icon("int", "EditorIcons")
			input_color = COLORS["integer"]
		TYPE_FLOAT:
			slot_type = SlotConnectionType.VAR_FLOAT
			input_icon = get_theme_icon("float", "EditorIcons")
			input_color = COLORS["float"]
		TYPE_BOOL:
			slot_type = SlotConnectionType.VAR_BOOL
			input_icon = get_theme_icon("bool", "EditorIcons")
			input_color = COLORS["bool"]
		TYPE_STRING:
			slot_type = SlotConnectionType.VAR_STRING
			input_icon = get_theme_icon("String", "EditorIcons")
			input_color = COLORS["string"]
		_:
			slot_type = SlotConnectionType.VAR_ANY
			input_icon = get_theme_icon("Variant", "EditorIcons")
			input_color = COLORS["any"]
	
	add_field(
			field_id,
			arg,
			false,
			slot_type)
	set_input_connection_icon(field_id, input_icon)
	set_slot_color_left(slot_target, input_color)


func clear_input_args() -> void:
	var fields: Array[StringName] = []
	for item in range(get_child_count() - 1, 0, -1):
		var field_id: StringName = &"argument_" + StringName(str(item))
		fields.append(field_id)
	remove_fields(fields, -1)
	_reset_height.call_deferred()


func _reset_height() -> void:
	size.y = 0


static func get_user_signals() -> Dictionary:
	if api_path.is_empty() or not ResourceLoader.exists(api_path):
		var all_classes: Array[Dictionary] = ProjectSettings.get_global_class_list()
		for class_entry in all_classes:
			if class_entry["class"] == "DiscourseAPI":
				api_path = class_entry["path"]
				break
	
	var user_signals: Dictionary = {}
	
	if not ResourceLoader.exists(api_path):
		NFPluginGameHandler._log_msg(
				"discourse - editor",
				"Couldn't load DiscourseAPI script.",
				NFPluginGameHandler._LogLevel.ERROR)
		return user_signals
	
	var api_script: Script = load(api_path)
	var api_signals: Array[Dictionary] = api_script.get_script_signal_list()
	
	for reg_signal:Dictionary in api_signals:
		var args: Array[Dictionary] = []
		for arg: Dictionary in reg_signal["args"]:
			args.append({
				"name": arg["name"],
				"type": arg["type"]
			})
		user_signals[reg_signal["name"]] = args
	
	return user_signals
