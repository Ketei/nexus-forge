extends DiscourseGraphNode


func _post_init() -> void:
	name = &"DialogBranch"
	parent_mode = PortMode.INPUT
	parent_port = 0
	node_type = DialogueNodeType.BRANCH
	size = Vector2(200, 110)
	title = "Branch"
	
	var true_label: Label = Label.new()
	var false_label: Label = Label.new()
	var result_label: Label = Label.new()
	var low_container: HBoxContainer = HBoxContainer.new()
	
	true_label.name = &"TrueLbl"
	false_label.name = &"FalseLbl"
	result_label.name = &"ResultLbl"
	low_container.name = &"LabelContainer"
	true_label.text = "True"
	true_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	true_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	false_label.text = "False"
	false_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	false_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	result_label.text = "Result"
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	low_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	low_container.add_child(result_label)
	low_container.add_child(false_label)
	
	var conn_idx: int = add_field(
			&"connection",
			true_label,
			false,
			SlotConnectionType.DIALOG,
			SlotConnectionType.DIALOG)
	var eval_idx: int = add_field(
			&"arg_eval",
			low_container,
			false,
			SlotConnectionType.VAR_BOOL,
			SlotConnectionType.DIALOG)
	
	set_slot_color_left(conn_idx, COLORS.dialog)
	set_slot_color_right(conn_idx, COLORS.dialog)
	set_slot_color_left(eval_idx, COLORS.bool)
	set_slot_color_right(eval_idx, COLORS.dialog)
	
	set_slot_custom_icon_right(conn_idx, flow_icon)
	set_slot_custom_icon_left(conn_idx, flow_icon)
	set_slot_custom_icon_right(eval_idx, flow_icon)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/branch_icon.svg")
	set_input_connection_icon(&"arg_eval", get_theme_icon("bool", "EditorIcons"))


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if not has_any_input(0):
		issues.append("Warning: Node is orphan.")
	if not has_any_input(1):
		issues.append("Error: No argument for evaluation connected.")
	return issues


func _get_node_data() -> Dictionary:
	var input_connections: Dictionary = {
		"path_direction": get_uuid_and_port_connected_to(PortMode.INPUT, 1)}
	var output_connections: Dictionary = {
		"next_node_true": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0),
		"next_node_false": get_uuid_and_port_connected_to(PortMode.OUTPUT, 1)}
	return _build_node_data({}, output_connections, input_connections)
