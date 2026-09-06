@tool
extends DiscourseGraphNode


signal text_changed(uuid: StringName, old_value: String, new_value: String)


var localized_text_edt: TextEdit


func _post_init() -> void:
	set_node_id(&"LocalizedText")
	title = "Localized Text"
	node_type = DialogueNodeType.LOCALIZED_TEXT
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(250.0, 120.0)
	custom_minimum_size = Vector2(250.0, 120.0)
	resizable = true
	localized_text_edt = load("res://addons/nexus_forge/discourse/textedit_bracket_handler.gd").new()
	var highlighter: NFEditorDialogSyntaxHighlighter = NFEditorDialogSyntaxHighlighter.new()
	highlighter.set_use_token("*", false)
	localized_text_edt.syntax_highlighter = highlighter
	localized_text_edt.set_meta(&"old_value", "")
	var connection: Label = Label.new()
	
	connection.text = "Text"
	connection.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	connection.custom_minimum_size.y = 24
	connection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	localized_text_edt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	localized_text_edt.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	
	var style: StyleBox = localized_text_edt.get_theme_stylebox("normal")
	var margin_top: float = style.get_margin(SIDE_TOP)
	var margin_bottom: float = style.get_margin(SIDE_BOTTOM)
	
	var line_height: int = localized_text_edt.get_line_height()
	var line_spacing: int = localized_text_edt.get_theme_constant("line_spacing")
	var total_height: float = margin_top + margin_bottom + line_height
	
	localized_text_edt.custom_minimum_size.y = total_height
	
	localized_text_edt.focus_exited.connect(_on_text_focus_exited)
	
	add_field(
			&"connection",
			connection,
			false,
			-1,
			SlotConnectionType.VAR_STRING)
	add_field(
			&"localized_text",
			localized_text_edt,
			true)
	set_slot_color_right(0, COLORS["string"])


func _ready() -> void:
	graph_icon = get_theme_icon("Translation", "EditorIcons")
	set_output_connection_icon(&"connection", get_theme_icon("String", "EditorIcons"))


func _get_node_data() -> Dictionary:
	var metadata: Dictionary = {"text": get_field(&"localized_text").text.strip_edges()}
	return _build_node_data(metadata)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("text") and typeof(metadata["text"]) == TYPE_STRING:
		set_text(metadata["text"])


func is_node_localized() -> bool:
	return true


func set_text(new_text: String) -> void:
	localized_text_edt.text = new_text
	localized_text_edt.set_meta(&"old_value", new_text)


func get_text() -> String:
	return get_field(&"localized_text").text


func _on_text_focus_exited() -> void:
	var field: TextEdit = get_field(&"localized_text")
	var old_value: String = field.get_meta(&"old_value", "")
	var new_value: String = field.text
	
	if new_value == old_value:
		return
	
	field.set_meta(&"old_value", new_value)
	text_changed.emit(
			get_node_uuid(),
			old_value,
			new_value)
