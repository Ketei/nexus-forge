@tool
extends DiscourseGraphNode


signal operator_changed(uuid: StringName, old_operator: int, new_operator: int)


var comparation_menu: MenuButton


func _post_init() -> void:
	set_node_id(&"Comparation")
	title = "Comparation"
	size = Vector2(200.0, 150.0)
	node_type = DialogueNodeType.COMPARATION
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	
	comparation_menu = MenuButton.new()
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
	comparation_menu.set_meta(&"old_value", OP_EQUAL)
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
	graph_icon = preload("res://addons/nexus_forge/icons/scale_icon.svg")
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
	
	var metadata: Dictionary = {
		"operator": comparation_menu.get_meta(&"current_operator", 0)}
	var in_connections: Dictionary = {
		"node_a": get_uuid_and_port_connected_to(PortMode.INPUT, 0),
		"node_b": get_uuid_and_port_connected_to(PortMode.INPUT, 1)}
	var out_connections: Dictionary = {
		"result": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	
	return _build_node_data(metadata, out_connections, in_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if not metadata.has("operator") or typeof(metadata["operator"]) != TYPE_INT:
		return
	
	var operator: Variant.Operator = clampi(metadata["operator"], 0, 5) as Variant.Operator
	match operator:
		OP_EQUAL:
			comparation_menu.text = "=="
		OP_NOT_EQUAL:
			comparation_menu.text = "!="
		OP_LESS:
			comparation_menu.text = "<"
		OP_LESS_EQUAL:
			comparation_menu.text = "<="
		OP_GREATER:
			comparation_menu.text = ">"
		OP_GREATER_EQUAL:
			comparation_menu.text = ">="
	comparation_menu.set_meta(&"old_value", operator)
	comparation_menu.set_meta(&"current_operator", operator)


func set_operator(operator: int) -> void:
	match operator:
		OP_EQUAL, OP_NOT_EQUAL, OP_LESS, OP_LESS_EQUAL, OP_GREATER, OP_GREATER_EQUAL:
			if comparation_menu.get_meta(&"current_operator") != operator:
				comparation_menu.set_meta(&"current_operator", operator)
				comparation_menu.set_meta(&"old_value", operator)
				_set_operator_display(operator)
		_:
			return


func _on_comparation_changed(id: int) -> void:
	var old_operator: int = comparation_menu.get_meta(&"old_value")
	comparation_menu.set_meta(&"current_operator", id)
	
	if id == old_operator:
		return
	
	_set_operator_display(id)
	comparation_menu.set_meta(&"old_value", id)
	operator_changed.emit(
			get_node_uuid(),
			old_operator,
			id)


func _set_operator_display(id: int) -> void:
	match id:
		OP_EQUAL:
			comparation_menu.text = "=="
		OP_NOT_EQUAL:
			comparation_menu.text = "!="
		OP_LESS:
			comparation_menu.text = "<"
		OP_LESS_EQUAL:
			comparation_menu.text = "<="
		OP_GREATER:
			comparation_menu.text = ">"
		OP_GREATER_EQUAL:
			comparation_menu.text = ">="
