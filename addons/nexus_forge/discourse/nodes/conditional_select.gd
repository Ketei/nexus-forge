extends DiscourseGraphNode


func _post_init() -> void:
	name = &"ConditionalValue"
	custom_id = "ConditionalValue"
	title = "Conditional Value"
	node_type = DialogueNodeType.CONDITION_SELECT
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(240.0, 140.0)
	
	var result_val_container: HBoxContainer = HBoxContainer.new()
	var result_lbl: Label = Label.new()
	var value_lbl: Label = Label.new()
	var true_lbl: Label = Label.new()
	var false_lbl: Label = Label.new()
	
	result_val_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_lbl.text = "Result"
	result_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_lbl.text = "Value"
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	true_lbl.text = "True"
	false_lbl.text = "False"
	
	result_val_container.add_child(result_lbl)
	result_val_container.add_child(value_lbl)
	
	var eval_idx: int = add_field(
			&"evaluation",
			result_val_container,
			false,
			SlotConnectionType.VAR_BOOL,
			SlotConnectionType.VAR_ANY,
			get_theme_icon("bool", "EditorIcons"),
			get_theme_icon("Variant", "EditorIcons"))
	var tr_var: int = add_field(
			&"true_var",
			true_lbl,
			false,
			SlotConnectionType.VAR_ANY,
			-1,
			get_theme_icon("Variant", "EditorIcons"))
	var fs_var: int = add_field(
			&"false_var",
			false_lbl,
			false,
			SlotConnectionType.VAR_ANY,
			-1,
			get_theme_icon("Variant", "EditorIcons"))
	
	set_slot_color_left(eval_idx, COLORS["bool"])
	set_slot_color_right(eval_idx, COLORS["any"])
	set_slot_color_left(tr_var, COLORS["any"])
	set_slot_color_left(fs_var, COLORS["any"])


func _get_node_data() -> Dictionary:
	var graph_data: Dictionary = {}
	graph_data["node_type"] = node_type
	graph_data["position"] = position_offset
	graph_data["input_connections"] = {
		"result": get_uuid_and_port_connected_to(PortMode.INPUT, 0),
		"true_value": get_uuid_and_port_connected_to(PortMode.INPUT, 1),
		"false_value": get_uuid_and_port_connected_to(PortMode.INPUT, 2)}
	graph_data["output_connections"] = {
		"output_value": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	
	return graph_data


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if not has_any_input(0):
		issues.append("Error: No evaluation result connected.")
	if not has_any_input(1):
		issues.append("Error: No value assigned for true evaluation")
	if not has_any_input(2):
		issues.append("Error: No value assigned for false evaluation")
	return PackedStringArray()
