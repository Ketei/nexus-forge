@tool
extends DiscourseGraphNode


func _post_init() -> void:
	set_node_id(&"Entry")
	title = "Entry"
	size = Vector2(160.0, 80.0)
	node_type = DialogueNodeType.ENTRY
	parent_mode = PortMode.NONE
	parent_port = 0
	var entry_label: Label = Label.new()
	entry_label.text = "Dialog Start"
	entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	entry_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entry_label.size_flags_vertical = Control.SIZE_EXPAND
	entry_label.custom_minimum_size.y = 32
	add_field(&"connection", entry_label, true, -1, SlotConnectionType.DIALOG)


func _ready() -> void:
	graph_icon = get_theme_icon("Play", "EditorIcons")
	set_slot_color_right(0, COLORS.dialog)
	set_slot_custom_icon_right(0, flow_icon)


func _get_node_data() -> Dictionary:
	var output_connections: Dictionary = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	return _build_node_data({}, output_connections)


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if not has_any_output(0):
		issues.append("Warning: No node connected to entry")
	return issues
