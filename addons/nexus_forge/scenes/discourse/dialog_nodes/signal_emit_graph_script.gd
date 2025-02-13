@tool
extends DiscourseGraphNode


var args: Array[Control] = []
@onready var signal_opt_btn: OptionButton = $SignalOptBtn


func _ready() -> void:
	graph_type = GraphType.SIGNAL
	register_output_connection("signal", 0, true)
	
	for signal_name in NFDiscourseTool.get_discourse_signals():
		signal_opt_btn.add_item(String(signal_name))
	
	add_utility()
	
	if 0 < signal_opt_btn.item_count:
		on_signal_selected(0)
	
	signal_opt_btn.item_selected.connect(on_field_changed)
	signal_opt_btn.item_selected.connect(on_signal_selected)


func on_field_changed(_arg: Variant = null) -> void:
	node_updated.emit()


func _get_node_data() -> Dictionary:
	var arguments: Array[Dictionary] = []
	for arg_idx in range(args.size()):
		arguments.append(
			{
				"id": -1 if not has_any_input_connection(str(arg_idx + 1)) else get_input_connections(str(arg_idx + 1))[0].node_id,
				"value": get_node_value(args[arg_idx])
			})
	return {
		"signal": StringName(signal_opt_btn.get_item_text(signal_opt_btn.selected)) if signal_opt_btn.selected != -1 else &"",
		"arguments": arguments,
		"_type": graph_type,
		"_offset": position_offset}


func _is_orphan() -> bool:
	if has_any_output_connection("signal"):
		for sig_out in get_output_connections("signal"):
			if not sig_out._is_orphan():
				return false
	return true


func _connection_set(is_input: bool, connection_id: String, node: DiscourseGraphNode) -> void:
	if is_input:
		var con_id: int = int(connection_id)
		set_arg_enabled(con_id - 1, node == null)
		if node != null and node.graph_type == GraphType.VALUE:
			var val_node: DiscourseGraphNode = get_input_connections(connection_id)[0]
			val_node.set_type(val_node.op_native_to_type(get_arg_type(con_id - 1)), true)


func set_signal_args(signal_args: Array) -> void:
	for idx in range(clampi(signal_args.size(), 0, args.size())):
		match typeof(signal_args[idx]):
			TYPE_INT:
				if args[idx] is SpinBox:
					args[idx].value = signal_args[idx]
			TYPE_FLOAT:
				if args[idx] is SpinBox:
					args[idx].value = signal_args[idx]
			TYPE_STRING:
				if args[idx] is LineEdit:
					args[idx].text = signal_args[idx]
			TYPE_BOOL:
				if args[idx] is CheckButton:
					args[idx].button_pressed = signal_args[idx]


func select_signal(signal_name: StringName) -> void:
	var signal_string: String = String(signal_name)
	
	for item in range(signal_opt_btn.item_count):
		if signal_opt_btn.get_item_text(item) == signal_string:
			signal_opt_btn.select(item)
			on_signal_selected(item)


func get_node_value(node: Control) -> Variant:
	if node is SpinBox:
		if node.step == 1.0:
			return int(node.value)
		else:
			return float(node.value)
	elif node is LineEdit:
		return node.text.strip_edges()
	elif node is CheckButton:
		return node.button_pressed
	else:
		return null


func on_signal_selected(select_idx: int) -> void:
	var signal_name := StringName(signal_opt_btn.get_item_text(select_idx))
	
	for idx in range(args.size()):
		var arg_id: String = str(idx + 1)
		
		if has_any_input_connection(arg_id):
			var from := get_input_connections(arg_id)
			disconnect_signaled.emit(
					from[0].name,
					from[0].get_output_connection_port_by_id("value"),
					name,
					get_input_port(arg_id))
			disconnect_input_node(arg_id, from[0])
		args[idx].visible = false
		args[idx].queue_free()
	
	args.clear()
	
	for signal_dict in NFDiscourseTool.get_signal_args(signal_name):
		var new_field: Control = null
		
		match signal_dict["type"]:
			TYPE_INT:
				new_field = SpinBox.new()
				new_field.step = 1.0
				new_field.allow_greater = true
				new_field.allow_lesser = true
			TYPE_FLOAT:
				new_field = SpinBox.new()
				new_field.step = 0.01
				new_field.allow_greater = true
				new_field.allow_lesser = true
			TYPE_BOOL:
				new_field = CheckButton.new()
				new_field.toggled.connect(_on_check_btn_toggled)
				new_field.text = "False"
			TYPE_STRING:
				new_field = LineEdit.new()
				new_field.placeholder_text = "Text Field"
				
		new_field.custom_minimum_size.y = 32
		add_child(new_field)
		var idx: int = new_field.get_index()
		args.append(new_field)
		register_input_connection(str(idx), idx - 1, true)
		set_slot(
				idx,
				true,
				PortType.VALUE,
				Color(0.163, 0.836, 0.729),
				false,
				0,
				Color.WHITE)
	
	size.y = 84 + (34 * args.size())


func get_arg_type(idx: int) -> int:
	var node: Control = args[idx]
	if node is LineEdit:
		return TYPE_STRING
	elif node is SpinBox:
		if node.step == 1.0:
			return TYPE_INT
		else:
			return TYPE_FLOAT
	else:
		return TYPE_STRING


func set_arg_enabled(idx: int, is_enabled: bool) -> void:
	var arg: Control = args[idx]
	
	if arg is LineEdit:
		arg.editable = is_enabled
	elif arg is SpinBox:
		arg.editable = is_enabled
	elif arg is LineEdit:
		arg.editable = is_enabled
	elif arg is CheckButton:
		arg.disabled = not is_enabled


func _on_check_btn_toggled(is_toggled: bool, btn: CheckButton) -> void:
	btn.text = "True" if is_toggled else "False"
