extends DiscourseGraphNode


func _post_init() -> void:
	set_node_id(&"CharacterSettings")
	title = "Character"
	graph_icon = preload("res://addons/nexus_forge/icons/gear_icon.png")
	node_type = DialogueNodeType.SETTINGS_CHARACTER
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(240, 140)
	
	var connect_label: Label = Label.new()
	var display_name_lbl: Label = Label.new()
	var portrait_id_lbl: Label = Label.new()
	
	connect_label.text = "Character"
	connect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	connect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	display_name_lbl.text = "Display Name"
	display_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	portrait_id_lbl.text = "Portrait ID"
	portrait_id_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_field(
			&"connection",
			connect_label,
			false,
			-1,
			SlotConnectionType.SETTINGS_CHARACTER)
	
	add_field(
			&"name",
			display_name_lbl,
			false,
			SlotConnectionType.VAR_STRING,
			-1)
	
	add_field(
			&"portrait",
			portrait_id_lbl,
			false,
			SlotConnectionType.VAR_STRING,
			-1)
	set_slot_color_right(0, COLORS["setting"])
	set_slot_color_left(1, COLORS["string"])
	set_slot_color_left(2, COLORS["string"])


func _ready() -> void:
	set_input_connection_icon(
			&"name",
			get_theme_icon("String", "EditorIcons"))
	set_input_connection_icon(
			&"portrait",
			get_theme_icon("String", "EditorIcons"))


func _get_node_data() -> Dictionary:
	var output_conn: Dictionary = {
		"dialog_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	var input_conn: Dictionary = {
		"display_name": get_uuid_and_port_connected_to(PortMode.INPUT, 0),
		"portrait_id": get_uuid_and_port_connected_to(PortMode.INPUT, 1)}
	
	return _build_node_data({}, output_conn, input_conn)
