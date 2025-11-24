extends DiscourseGraphNode


func _post_init() -> void:
	name = &"Comparation"
	custom_id = "Comparation"
	title = "Comparation"
	size = Vector2(200.0, 150.0)
	node_type = DialogueNodeType.COMPARATION
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	
	var comparation_menu: MenuButton = MenuButton.new()
	var comparation_popup: PopupMenu = comparation_menu.get_popup()
	
	var comp_container: HBoxContainer = HBoxContainer.new()
	var comp_a_label: Label = Label.new()
	var comp_b_label: Label = Label.new()
	
	var a_result_container: HBoxContainer = HBoxContainer.new()
	var a_label: Label = Label.new()
	var result_label: Label = Label.new()
	var b_label: Label = Label.new()
	
	comparation_menu.flat = false
	comparation_menu.text = "=="
	comparation_menu.alignment = HORIZONTAL_ALIGNMENT_CENTER
	comparation_menu.set_meta(&"current_operator", OP_EQUAL)
	comparation_menu.expand_icon = false
	comparation_popup.add_item("==", OP_EQUAL)
	comparation_popup.add_item("!=", OP_NOT_EQUAL)
	comparation_popup.add_item("<", OP_LESS)
	comparation_popup.add_item("<=", OP_LESS_EQUAL)
	comparation_popup.add_item(">", OP_GREATER)
	comparation_popup.add_item(">=", OP_GREATER_EQUAL)
	
	comp_container.alignment = BoxContainer.ALIGNMENT_CENTER
	comp_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comp_a_label.text = "A"
	comp_a_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comp_a_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	comp_a_label.custom_minimum_size = Vector2(24.0, 24.0)
	comp_b_label.text = "B"
	comp_b_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comp_b_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	comp_b_label.custom_minimum_size = Vector2(24.0, 24.0)
	
	comparation_menu.custom_minimum_size = Vector2(32.0, 32.0)
	
	a_result_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a_label.text = "A"
	a_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	a_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_label.text = "Result"
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_label.text = "B"
	b_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	comparation_popup.id_pressed.connect(_on_comparation_changed)
	
	comp_container.add_child(comp_a_label)
	comp_container.add_child(comparation_menu)
	comp_container.add_child(comp_b_label)
	
	a_result_container.add_child(a_label)
	a_result_container.add_child(result_label)
	
	add_field(&"comparation", comp_container)
	map_field(&"comparation", &"comparation_menu", comparation_menu)
	var res_idx: int = add_field(
			&"result",
			a_result_container,
			false,
			SlotConnectionType.VAR_ANY,
			SlotConnectionType.VAR_BOOL)
	var b_idx: int = add_field(
			&"b_comparation",
			b_label,
			false,
			SlotConnectionType.VAR_ANY,
			-1)
	set_slot_color_left(res_idx, COLORS["any"])
	set_slot_color_right(res_idx, COLORS["bool"])
	set_slot_color_left(b_idx, COLORS["any"])


func _ready() -> void:
	set_field_connection_icons(
			&"result",
			get_theme_icon("Variant", "EditorIcons"),
			get_theme_icon("bool", "EditorIcons"))
	
	set_input_connection_icon(&"b_comparation", get_theme_icon("Variant", "EditorIcons"))


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if not has_any_input(0):
		issues.append("Error: Missing comparation node A")
	if not has_any_input(1):
		issues.append("Error: Missing comparation node N")
	return issues


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["operator"] = get_mapped_field(
			&"comparation",
			&"comparation_menu").get_meta(&"current_operator", 0)
	data["input_connections"] = {
		"node_a": get_uuid_and_port_connected_to(PortMode.INPUT, 0),
		"node_b": get_uuid_and_port_connected_to(PortMode.INPUT, 1)}
	data["output_connections"] = {
		"result": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	
	return data


func _set_node_data(data: Dictionary) -> void:
	var dropdown: MenuButton = get_mapped_field(&"comparation", &"comparation_menu")
	var operator: Variant.Operator = clampi(data["operator"], 0, 5) as Variant.Operator
	position_offset = data["position"]
	dropdown.set_meta(&"current_operator", data["operator"])
	match operator:
		OP_EQUAL:
			dropdown.text = "=="
		OP_NOT_EQUAL:
			dropdown.text = "!="
		OP_LESS:
			dropdown.text = "<"
		OP_LESS_EQUAL:
			dropdown.text = "<="
		OP_GREATER:
			dropdown.text = ">"
		OP_GREATER_EQUAL:
			dropdown.text = ">="


func _on_comparation_changed(id: int) -> void:
	var menu_btn: MenuButton = get_field(&"comparation").get_child(1)
	menu_btn.set_meta(&"current_operator", id)
	match id:
		OP_EQUAL:
			menu_btn.text = "=="
		OP_NOT_EQUAL:
			menu_btn.text = "!="
		OP_LESS:
			menu_btn.text = "<"
		OP_LESS_EQUAL:
			menu_btn.text = "<="
		OP_GREATER:
			menu_btn.text = ">"
		OP_GREATER_EQUAL:
			menu_btn.text = ">="
	node_updated.emit()
