@tool
extends DiscourseGraphNode


## Runs once the initiation is done. Used to set up the visual part of the node.
func _post_init() -> void:
	set_node_id(&"TravelBack")
	title = "Travel Back"
	size = Vector2(200.0, 90.0)
	node_type = DialogueNodeType.TRAVEL_BACK
	parent_mode = PortMode.INPUT
	parent_port = 0
	var continue_label: Label = Label.new()
	continue_label.text = "Return"
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	continue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	continue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_field(
			&"connection",
			continue_label,
			true,
			SlotConnectionType.DIALOG)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/travel_back.svg")
	set_slot_color_left(0, COLORS["dialog"])
	set_slot_custom_icon_left(0, flow_icon)
