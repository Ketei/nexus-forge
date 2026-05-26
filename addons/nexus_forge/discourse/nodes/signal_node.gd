extends DiscourseGraphNode


var available_signals: Dictionary = {}


func _post_init() -> void:
	set_node_id(&"Signal")
	title = "Signal"
	node_type = DialogueNodeType.SIGNAL
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(260, 83)
	
	available_signals = get_user_signals()
	
	var signal_keys: Array = available_signals.keys()
	signal_keys.sort_custom(ArrayUtils.sort_custom_alphabetically_asc)
	
	var signals_node: OptionButton = OptionButton.new()
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
	
	if not available_signals.is_empty():
		signals_node.select(0)
		for arg in available_signals[signals_node.get_item_metadata(0)]:
			add_input_arg(arg["name"], arg["type"])
	else:
		signals_node.disabled = true
	
	signals_node.item_selected.connect(_on_signal_selected)


func _ready() -> void:
	graph_icon = get_theme_icon("Signal", "EditorIcons")
	set_output_connection_icon(&"signals", get_theme_icon("Signals", "EditorIcons"))


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
	var arguments: Array[Dictionary] = []
	for arg_idx in range(get_child_count() - 1):
		arguments.append(get_uuid_and_port_connected_to(PortMode.INPUT, arg_idx))
	
	var output_connectons: Dictionary = {
		"signaler": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	var metadata: Dictionary = {
		"signal": get_current_signal(),
		"arguments": arguments}
	
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
	
	var sign_btn: OptionButton = get_field(&"signals")

	for idx in range(sign_btn.item_count):
		if sign_btn.get_item_metadata(idx) == metadata["signal"]:
			sign_btn.select(idx)
			load_signal(metadata["signal"])
			break


func _on_signal_selected(idx: int) -> void:
	var signal_id: String = get_field(&"signals").get_item_metadata(idx)
	load_signal(signal_id)
	node_updated.emit()


func reload_signals() -> void:
	available_signals = get_user_signals()
	var opt_btn: OptionButton = get_field(&"signals")
	var current_signal: String = "" if opt_btn.selected == -1 else opt_btn.get_selected_metadata()
	var new_signals = available_signals.keys()
	var new_idx: int = -1
	var emit_updated: bool = false
	
	new_signals.sort_custom(ArrayUtils.sort_custom_alphabetically_asc)
	
	if current_signal != "":
		new_idx = new_signals.find(current_signal)
	
	opt_btn.clear()
	
	for new_signal:String in new_signals:
		opt_btn.add_item(new_signal.capitalize())
		opt_btn.set_item_metadata(-1, new_signal)
	
	if new_idx == -1:
		if opt_btn.item_count == 0:
			clear_input_args()
		else:
			opt_btn.select(0)
			load_signal(opt_btn.get_item_metadata(0))
		node_updated.emit()
		return
	else:
		opt_btn.select(new_idx)
	
	var arg_idx: int = -1 # With the index
	for new_arg:Dictionary in available_signals[current_signal]:
		arg_idx += 1
		
		if get_child_count() - 1 <= arg_idx:
			add_input_arg(new_arg["name"], new_arg["type"])
			emit_updated = true
			continue # And we continue
		
		#var field_id: StringName = &"argument_" + StringName(str(arg_idx + 1))
		var current_input_type: int = get_input_port_type(arg_idx)
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
			emit_updated = true
		
		# If the types don't match we assign the type, change the color and icon.
		if current_input_type != new_port_type:
			set_slot_color_left(arg_idx, COLORS[new_type_color])
			set_slot_type_left(arg_idx, new_port_type)
			emit_updated = true
	
	if emit_updated:
		node_updated.emit()


func load_signal(signal_id: String) -> void:
	clear_input_args()
	for arg:Dictionary in available_signals[signal_id]:
		add_input_arg(arg["name"], arg["type"])


func get_current_signal() -> String:
	var sign_btn: OptionButton = get_field(&"signals")
	if sign_btn.selected == -1:
		return ""
	else:
		return sign_btn.get_item_metadata(sign_btn.selected)


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
	for item in range(get_child_count() - 1, 0, -1):
		var field_id: StringName = &"argument_" + StringName(str(item))
		remove_field(field_id, 32)


static func get_user_signals() -> Dictionary:
	var user_signals: Dictionary = {}
	var signal_blacklist: Array[String] = []
	var singleton: DiscourseAPI = DiscourseAPI.new()
	var prev_signals: Array = ClassDB.class_get_signal_list(&"RefCounted")
	
	for ref_signal in prev_signals:
		signal_blacklist.append(ref_signal["name"])
	
	for reg_signal:Dictionary in singleton.get_signal_list():
		if reg_signal["name"] in signal_blacklist:
			continue
		var args: Array[Dictionary] = []
		for arg: Dictionary in reg_signal["args"]:
			args.append({
				"name": arg["name"],
				"type": arg["type"]
			})
		user_signals[reg_signal["name"]] = args
	
	return user_signals
