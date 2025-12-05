extends DiscourseGraphNode


func _post_init() -> void:
	name = &"End"
	custom_id = "End"
	title = "End"
	size = Vector2(160.0, 80.0)
	node_type = DialogueNodeType.DIALOG_END
	parent_mode = PortMode.INPUT
	parent_port = 0
	
	var end_label: Label = Label.new()
	end_label.text = "Dialog End"
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end_label.custom_minimum_size.y = 32
	
	add_field(
			&"connection",
			end_label,
			false,
			SlotConnectionType.DIALOG)
	set_slot_color_left(0, COLORS["dialog"])
	set_slot_custom_icon_left(0, flow_icon)


func _ready() -> void:
	graph_icon = get_theme_icon("Stop", "EditorIcons")
