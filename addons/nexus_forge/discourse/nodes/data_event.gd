extends DiscourseGraphNode


func _post_init() -> void:
	name = &"DataEvent"
	custom_id = "DataEvent"
	title = "Event (Data)"
	size = Vector2(240.0, 196.0)
	node_type = DialogueNodeType.DATA_EVENT
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	
	var connection_ctrn: Control = Control.new()
	var call_label: Label = Label.new()
	var var_label: Label = Label.new()
	var signal_label: Label = Label.new()
	var variable_path: LineEdit = LineEdit.new()
	var var_panel: PanelContainer = PanelContainer.new()
	
	var_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var_panel.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	
	variable_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	variable_path.custom_minimum_size.y = 32
	variable_path.visible = false
	variable_path.placeholder_text = "Variable Path"
	
	var_panel.add_child(var_label)
	var_panel.add_child(variable_path)
	
	connection_ctrn.custom_minimum_size.y = 24
	connection_ctrn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	call_label.text = "Call method"
	call_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	call_label.custom_minimum_size.y = 32
	var_label.text = "Set variable"
	var_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var_label.custom_minimum_size.y = 32
	signal_label.text = "Emit signal"
	signal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	signal_label.custom_minimum_size.y = 32
	
	add_field(
			&"data",
			connection_ctrn,
			false,
			SlotConnectionType.VAR_ANY,
			SlotConnectionType.VAR_ANY)
	set_slot_color_right(0, Color.TRANSPARENT)
	set_slot_type_right(0, -1)
	
	add_field(
			&"variable",
			var_panel,
			false,
			SlotConnectionType.VAR_ANY,
			-1)
	map_field(&"variable", &"path", variable_path)
	
	add_field(
			&"callable",
			call_label,
			false,
			SlotConnectionType.CALL,
			-1)
	
	add_field(
			&"signal",
			signal_label,
			false,
			SlotConnectionType.SIGNAL,
			-1)
	 
	set_slot_color_left(0, COLORS["any"])
	set_slot_color_left(1, COLORS["any"])
	set_slot_color_left(2, COLORS["method"])
	set_slot_color_left(3, COLORS["signal"])
	
	variable_path.focus_exited.connect(_on_var_path_focus_lost)
	variable_path.text_changed.connect(node_updated.emit)


func _ready() -> void:
	set_input_connection_icon(&"variable", get_theme_icon("Variant", "EditorIcons"))
	set_input_connection_icon(&"callable", get_theme_icon("Callable", "EditorIcons"))
	set_input_connection_icon(&"signal", get_theme_icon("Signals", "EditorIcons"))


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if has_any_input(1) and get_mapped_field(&"variable", &"path").text.strip_edges().is_empty():
		issues.append("Error: Variable is being set but no path provided.")
	return issues


func _on_input_connected(input_port: int, from_node: DiscourseGraphNode, from_port: int) -> void:
	if input_port == 1:
		var set_var: PanelContainer = get_field(&"variable")
		set_var.get_child(0).visible = false
		set_var.get_child(1).visible = true
	elif input_port == 0:
		var input_type: int = from_node.get_output_port_type(from_port)
		var input_color: Color = from_node.get_output_port_color(from_port)
		set_slot_enabled_right(0, true)
		set_slot_color_right(0, input_color)
		set_slot_type_right(0, input_type)
		set_slot_color_left(0, input_color)


func _on_input_disconnected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	if input_port == 0:
		if has_any_output(0):
			var to_node: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, 0)
			disconnect_requested.emit(
					name,
					0,
					to_node.name,
					to_node.get_port_connected_to(PortMode.INPUT, self, 0))
		set_slot_color_right(0, Color.TRANSPARENT)
		set_slot_color_left(0, COLORS["any"])
		set_slot_type_right(0, -1)
	elif input_port == 1:
		var set_var: PanelContainer = get_field(&"variable")
		set_var.get_child(0).visible = true
		set_var.get_child(1).visible = false


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["variable_path"] = get_mapped_field(&"variable", &"path").text.strip_edges() if has_any_input(1) else ""
	data["output_connections"] = {
		"data_output": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)
	}
	data["input_connections"] = {
		"data_input": get_uuid_and_port_connected_to(PortMode.INPUT, 0),
		"variable_value": get_uuid_and_port_connected_to(PortMode.INPUT, 1),
		"callable": get_uuid_and_port_connected_to(PortMode.INPUT, 2),
		"signal": get_uuid_and_port_connected_to(PortMode.INPUT, 3)
	}
	
	return data


func _set_node_data(data: Dictionary) -> void:
	get_mapped_field(&"variable", &"path").text = data["variable_path"]
	position_offset = data["position"]


func _on_var_path_focus_lost() -> void:
	var var_path: LineEdit = get_mapped_field(&"variable", &"path")
	var_path.tooltip_text = var_path.text.strip_edges()
