extends DiscourseGraphNode


func _post_init() -> void:
	name = &"OptionSettings"
	custom_id = "OptionSettings"
	title = "Option"
	graph_icon = preload("res://addons/nexus_forge/icons/gear_icon.png")
	node_type = DialogueNodeType.SETTINGS_OPTION
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(180, 170)
	
	var option_connection: Label = Label.new()
	var option_available: Label = Label.new()
	var option_unblocked: Label = Label.new()
	var option_hint: Label = Label.new()
	
	option_connection.text = "Option"
	option_connection.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	option_connection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	option_available.text = "Show"
	option_available.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	option_unblocked.text = "Unlocked"
	option_unblocked.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	option_hint.text = "Locked Hint"
	option_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_field(
			&"connection",
			option_connection,
			false,
			-1,
			SlotConnectionType.SETTINGS_OPTION)
	set_slot_color_right(0, COLORS["setting"])

	add_field(
			&"available",
			option_available,
			false,
			SlotConnectionType.VAR_BOOL,
			-1,
			get_theme_icon("bool", "EditorIcons"))
	set_slot_color_left(1, COLORS["bool"])
	
	add_field(
			&"unblocked",
			option_unblocked,
			false,
			SlotConnectionType.VAR_BOOL,
			-1,
			get_theme_icon("bool", "EditorIcons"))
	set_slot_color_left(2, COLORS["bool"])
	
	add_field(
			&"hint",
			option_hint,
			false,
			SlotConnectionType.VAR_STRING,
			-1,
			get_theme_icon("String", "EditorIcons"))
	set_slot_color_left(3, COLORS["string"])


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["output_connections"] = {
		"option_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	data["input_connections"] = {
		"option_available": get_uuid_and_port_connected_to(PortMode.INPUT, 0),
		"option_locked": get_uuid_and_port_connected_to(PortMode.INPUT, 1),
		"locked_hint": get_uuid_and_port_connected_to(PortMode.INPUT, 2)}
	
	return data
