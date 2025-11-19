extends DiscourseGraphNode


func _post_init() -> void:
	name = &"LocalizedText"
	custom_id = "LocalizedText"
	title = "Localized Text"
	node_type = DialogueNodeType.LOCALIZED_TEXT
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(250.0, 120.0)
	custom_minimum_size = Vector2(250.0, 120.0)
	resizable = true
	var localized_text: TextEdit = TextEdit.new()
	var connection: Label = Label.new()
	
	connection.text = "Text"
	connection.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	connection.custom_minimum_size.y = 24
	connection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	localized_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	localized_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	add_field(
			&"connection",
			connection,
			false,
			-1,
			SlotConnectionType.VAR_STRING)
	add_field(
			&"localized_text",
			localized_text,
			true)
	set_slot_color_right(0, COLORS["string"])


func _ready() -> void:
	graph_icon = get_theme_icon("Translation", "EditorIcons")
	set_output_connection_icon(&"connection", get_theme_icon("String", "EditorIcons"))


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["text"] = get_field(&"localized_text").text.strip_edges()
	return data


func _set_node_data(data: Dictionary) -> void:
	position_offset = data["position"]
	get_field(&"localized_text").text = data["text"]


func set_text(new_text: String) -> void:
	get_field(&"localized_text").text = new_text


func get_text() -> String:
	return get_field(&"localized_text").text
