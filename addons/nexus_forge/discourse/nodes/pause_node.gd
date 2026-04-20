extends DiscourseGraphNode


## Runs once the initiation is done. Used to set up the visual part of the node.
func _post_init() -> void:
	name = &"Pause"
	title = "Pause"
	size = Vector2(200.0, 90.0)
	node_type = DialogueNodeType.PAUSE
	parent_mode = PortMode.INPUT
	parent_port = 0
	var continue_label: Label = Label.new()
	continue_label.text = "Continue"
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	continue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_field(
			&"connection",
			continue_label,
			true,
			SlotConnectionType.DIALOG,
			SlotConnectionType.DIALOG)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/pause_icon.svg")
	set_slot_color_left(0, COLORS["dialog"])
	set_slot_color_right(0, COLORS["dialog"])
	set_slot_custom_icon_left(0, flow_icon)
	set_slot_custom_icon_right(0, flow_icon)


func _get_node_data() -> Dictionary:
	var output_connections: Dictionary = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	return _build_node_data({}, output_connections)
