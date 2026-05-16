extends DiscourseGraphNode


func _post_init() -> void:
	name = &"DialogSettings"
	title = "Dialog"
	graph_icon = preload("res://addons/nexus_forge/icons/gear_icon.png")
	node_type = DialogueNodeType.SETTINGS_DIALOG
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(180, 170)
	
	var dialog_connection: Label = Label.new()
	var font_resource: Label = Label.new()
	var scene_origin: Label = Label.new()
	var text_speed: Label = Label.new()
	var metadata_label: Label = Label.new()
	
	dialog_connection.text = "Dialog"
	dialog_connection.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialog_connection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	font_resource.text = "Font"
	font_resource.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	scene_origin.text = "Scene"
	scene_origin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	text_speed.text = "Speed"
	text_speed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	metadata_label.text = "Metadata"
	
	add_field(
			&"connection",
			dialog_connection,
			false,
			-1,
			SlotConnectionType.SETTINGS_DIALOG)
	set_slot_color_right(0, COLORS["setting"])

	add_field(
			&"font",
			font_resource,
			false,
			SlotConnectionType.RESOURCE,
			-1)
	set_slot_color_left(1, COLORS["object"])
	
	add_field(
			&"scene",
			scene_origin,
			false,
			SlotConnectionType.RESOURCE,
			-1)
	set_slot_color_left(2, COLORS["object"])
	
	add_field(
			&"text_speed",
			text_speed,
			false,
			SlotConnectionType.VAR_INT,
			-1)
	set_slot_color_left(3, COLORS["integer"])
	
	add_field(
			&"dialog_metadata",
			metadata_label,
			false,
			SlotConnectionType.METADATA)


func _ready() -> void:
	set_input_connection_icon(&"font", get_theme_icon("Object", "EditorIcons"))
	set_input_connection_icon(&"scene", get_theme_icon("PackedScene", "EditorIcons"))
	set_input_connection_icon(&"text_speed", get_theme_icon("int", "EditorIcons"))
	set_input_connection_icon(&"dialog_metadata", preload("res://addons/nexus_forge/icons/metadata_icon.svg"))
	set_slot_color_left(4, COLORS["metadata"])


func _get_node_data() -> Dictionary:
	var output_connections: Dictionary = {
		"dialog_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	var input_connections: Dictionary = {
		"font_resource": get_uuid_and_port_connected_to(PortMode.INPUT, 0),
		"dialog_scene": get_uuid_and_port_connected_to(PortMode.INPUT, 1),
		"dialog_speed": get_uuid_and_port_connected_to(PortMode.INPUT, 2)}
	
	return _build_node_data({}, output_connections, input_connections)
