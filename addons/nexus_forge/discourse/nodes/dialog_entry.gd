@tool
extends DiscourseGraphNode


func _ready() -> void:
	print("Entry: ", get_titlebar_hbox().size)


func _post_init() -> void:
	name = &"Entry"
	custom_id = "Entry"
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
	var in_idx: int = add_field(&"connection", entry_label, true, -1, SlotConnectionType.DIALOG)
	set_slot_color_right(in_idx, COLORS.dialog)
	set_slot_custom_icon_right(in_idx, flow_icon)


func _get_node_data() -> Dictionary:
	var graph_data: Dictionary = {}
	graph_data["node_type"] = node_type
	graph_data["position"] = position_offset
	graph_data["output_connections"] = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)
	}
	return graph_data


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if not has_any_input(0):
		issues.append("Warning: No node connected to entry")
	return issues
