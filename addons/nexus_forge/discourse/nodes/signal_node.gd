extends DiscourseGraphNode


var available_signals: Dictionary = {}


func _post_init() -> void:
	name = &"Signal"
	custom_id = "Signal"
	title = "Signal"
	graph_icon = get_theme_icon("Signal", "EditorIcons")
	node_type = DialogueNodeType.SIGNAL
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(260, 83)
	
	available_signals = get_user_signals()
	
	var signals_node: OptionButton = OptionButton.new()
	signals_node.name = &"SignalsOptBtn"
	signals_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	signals_node.fit_to_longest_item = false
	signals_node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	for user_signal:String in available_signals.keys():
		signals_node.add_item(user_signal.capitalize())
		signals_node.set_item_metadata(-1, user_signal)
	
	add_field(
			&"signals",
			signals_node,
			false,
			-1,
			SlotConnectionType.SIGNAL,
			null,
			get_theme_icon("Signals", "EditorIcons"))
	set_slot_color_right(0, COLORS["signal"])
	
	if not available_signals.is_empty():
		signals_node.select(0)
		for arg in available_signals[signals_node.get_item_metadata(0)]:
			add_input_arg(arg["name"], arg["type"])
	else:
		signals_node.disabled = true
	
	signals_node.item_selected.connect(_on_signal_selected)


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
	var data: Dictionary = {}
	var arguments: Array[Dictionary] = []
	for arg_idx in range(get_child_count() - 1):
		arguments.append(get_uuid_and_port_connected_to(PortMode.INPUT, arg_idx))
	
	data["node_type"] = node_type
	data["position"] = position_offset
	data["output_connectons"] = {
		"signaler": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	data["signal"] = get_current_signal()
	data["arguments"] = arguments
	return data


func _set_node_data(data: Dictionary) -> void:
	var sign_btn: OptionButton = get_field(&"signals")
	position_offset = data["position"]
	for idx in range(sign_btn.item_count):
		if sign_btn.get_item_metadata(idx) == data["signal"]:
			sign_btn.select(idx)
			load_signal(data["signal"])
			break


func _on_signal_selected(idx: int) -> void:
	var signal_id: String = get_field(&"signals").get_item_metadata(idx)
	load_signal(signal_id)
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
	
	add_field(
			field_id,
			arg,
			false,
			slot_type,
			-1,
			input_icon)
	set_slot_color_left(slot_target, input_color)


func clear_input_args() -> void:
	for item in range(get_child_count() - 1, 0, -1):
		var field_id: StringName = &"argument_" + StringName(str(item))
		remove_field(field_id, 32)


func get_user_signals() -> Dictionary:
	var user_signals: Dictionary = {}
	var signal_blacklist: Array[String] = []
	var singleton: DialogParser.DiscourseAPI = DialogParser.DiscourseAPI.new()
	var prev_signals: Array = DialogParser.new().get_signal_list()
	
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
