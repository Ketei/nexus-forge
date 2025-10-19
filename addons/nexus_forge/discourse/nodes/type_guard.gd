extends DiscourseGraphNode


var filter_mode: int = TYPE_NIL


func _post_init() -> void:
	name = &"TypeGuard"
	custom_id = "TypeGuard"
	title = "Type Guard"
	node_type = DialogueNodeType.TYPE_GUARD
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(220.0, 120.0)
	
	var connection_label: Label = Label.new()
	var fallback_panel: PanelContainer = PanelContainer.new()
	var spinbox_container: HBoxContainer = HBoxContainer.new()
	var spnbx_label: Label = Label.new()
	var val_fallback: SpinBox = SpinBox.new()
	var bool_fallback: CheckButton = CheckButton.new()
	var str_fallback: LineEdit = LineEdit.new()
	var awaiting_label: Label = Label.new()
	
	awaiting_label.text = "- Fallback -"
	awaiting_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	awaiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	connection_label.text = "Input Output"
	connection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	connection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fallback_panel.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	fallback_panel.custom_minimum_size.y = 32.0
	fallback_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spnbx_label.text = "Fallback"
	spnbx_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_fallback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_fallback.allow_greater = true
	val_fallback.allow_lesser = true
	bool_fallback.text = "Is True"
	bool_fallback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	str_fallback.placeholder_text = "Fallback"
	
	spinbox_container.visible = false
	bool_fallback.visible = false
	str_fallback.visible = false
	
	spinbox_container.add_child(spnbx_label)
	spinbox_container.add_child(val_fallback)
	
	fallback_panel.add_child(spinbox_container)
	fallback_panel.add_child(bool_fallback)
	fallback_panel.add_child(str_fallback)
	fallback_panel.add_child(awaiting_label)
	
	add_field(
			&"connection",
			connection_label,
			false,
			SlotConnectionType.VAR_ANY,
			SlotConnectionType.VAR_GUARD,
			get_theme_icon("Variant", "EditorIcons"),
			get_theme_icon("Variant", "EditorIcons"))
	set_slot_color_left(0, COLORS["any"])
	set_slot_color_right(0, COLORS["any"])
	add_field(&"fallback", fallback_panel)


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	return issues


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["input_connections"] = {
		"value": get_uuid_and_port_connected_to(PortMode.INPUT, 0)}
	data["output_connections"] = {
		"output": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	data["fallback_value"] = get_active_data_type()
	return data


func _set_node_data(data: Dictionary) -> void:
	position_offset = data["position"]
	match typeof(data["fallback_value"]):
		TYPE_INT:
			get_field(&"fallback").get_child(0).get_child(1).value = data["fallback_value"]
		TYPE_FLOAT:
			get_field(&"fallback").get_child(0).get_child(1).value = data["fallback_value"]
		TYPE_BOOL:
			get_field(&"fallback").get_child(1).button_pressed = data["fallback_value"]
		TYPE_STRING:
			get_field(&"fallback").get_child(2).text = data["fallback_value"]


func _on_output_connected(output: int, to_node: DiscourseGraphNode, _to_port: int) -> void:
	var fallback_panel: PanelContainer = get_field(&"fallback")
	var type: int = to_node.get_input_port_type(
			to_node.get_port_connected_to(PortMode.INPUT, self, output))
	
	for child in fallback_panel.get_children():
		child.visible = false
	
	match type as SlotConnectionType:
		SlotConnectionType.VAR_INT:
			var child: HBoxContainer = fallback_panel.get_child(0)
			set_slot_type_right(0, SlotConnectionType.VAR_INT)
			set_slot_color_right(0, COLORS["integer"])
			set_output_connection_icon(&"connection", get_theme_icon("int", "EditorIcons"))
			child.visible = true
			child.get_child(1).step = 1.0
			filter_mode = TYPE_INT
		SlotConnectionType.VAR_FLOAT:
			var child: HBoxContainer = fallback_panel.get_child(0)
			set_slot_type_right(0, SlotConnectionType.VAR_FLOAT)
			set_slot_color_right(0, COLORS["float"])
			set_output_connection_icon(&"connection", get_theme_icon("float", "EditorIcons"))
			child.visible = true
			child.get_child(1).step = 0.01
			filter_mode = TYPE_FLOAT
		SlotConnectionType.VAR_BOOL:
			set_slot_type_right(0, SlotConnectionType.VAR_BOOL)
			fallback_panel.get_child(1).visible = true
			set_slot_color_right(0, COLORS["bool"])
			set_output_connection_icon(&"connection", get_theme_icon("bool", "EditorIcons"))
			filter_mode = TYPE_BOOL
		SlotConnectionType.VAR_STRING:
			set_slot_type_right(0, SlotConnectionType.VAR_STRING)
			fallback_panel.get_child(2).visible = true
			set_slot_color_right(0, COLORS["string"])
			set_output_connection_icon(&"connection", get_theme_icon("String", "EditorIcons"))
			filter_mode = TYPE_STRING


func _on_output_disconnected(_output: int, _to_node: DiscourseGraphNode, _to_port: int) -> void:
	var fallback: Control = get_field(&"fallback")
	for child in fallback.get_children():
		child.visible = false
	fallback.get_child(3).visible = true
	set_slot_type_right(0, SlotConnectionType.VAR_GUARD)
	set_slot_color_right(0, COLORS["any"])
	filter_mode = TYPE_NIL


func get_active_data_type() -> Variant:
	var fallback_panel: PanelContainer = get_field(&"fallback")
	match filter_mode:
		TYPE_INT:
			return int(fallback_panel.get_child(0).get_child(1).value)
		TYPE_FLOAT:
			return float(fallback_panel.get_child(0).get_child(1).value)
		TYPE_STRING:
			return fallback_panel.get_child(2).text
		TYPE_BOOL:
			return fallback_panel.get_child(1).button_pressed
		_:
			return null
