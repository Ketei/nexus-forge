extends DiscourseGraphNode


signal use_code_editor_pressed(target: TextEdit)
signal select_character_pressed(target: LineEdit)

var free_size: Vector2 = Vector2(350.0, 300.0)


func _post_init() -> void:
	set_node_id(&"Dialog")
	title = "Dialog"
	node_type = DialogueNodeType.DIALOG
	parent_mode = PortMode.INPUT
	parent_port = 0
	size = Vector2(350.0, 300.0)
	custom_minimum_size = Vector2(250.0, 270.0)
	resizable = true
	
	var connection_node: Control = Control.new()
	var id_box: HBoxContainer = HBoxContainer.new()
	var dialog_box: VBoxContainer = VBoxContainer.new()
	var char_id_label: Label = Label.new()
	var char_id_ln_edt: LineEdit = LineEdit.new()
	var char_selector_btn: Button = Button.new()
	var dialog_label: Label = Label.new()
	var dialog_settings: Label = Label.new()
	var settings_box: HBoxContainer = HBoxContainer.new()
	var dialog_textedt: TextEdit = load("res://addons/nexus_forge/discourse/textedit_bracket_handler.gd").new()
	var highlighter: NFEditorDialogSyntaxHighlighter = NFEditorDialogSyntaxHighlighter.new()
	var persist_check: CheckBox = CheckBox.new()
	var flags_container: HBoxContainer = HBoxContainer.new()
	var use_code_editor_btn: Button = Button.new()
	
	use_code_editor_btn.name = &"UseCodeEditorBtn"
	connection_node.name = &"Connection"
	id_box.name = &"IDContainer"
	dialog_box.name = &"DialogContainer"
	char_id_label.name = &"IDLabel"
	char_id_ln_edt.name = &"CharIDLnEdt"
	dialog_label.name = &"DialogLabel"
	dialog_textedt.name = &"DialogTxtEdt"
	persist_check.name = &"PersistChkBx"
	char_selector_btn.name = &"SelectCharBtn"
	
	char_selector_btn.custom_minimum_size = Vector2(32.0, 32.0)
	char_selector_btn.flat = true
	char_selector_btn.tooltip_text = "Browse Characters"
	char_selector_btn.pressed.connect(_on_select_character_btn_pressed)
	
	connection_node.custom_minimum_size = Vector2(0.0, 32.0)
	char_id_label.text = "Character"
	char_id_label.custom_minimum_size = Vector2(80.0, 0.0)
	char_id_ln_edt.caret_blink = true
	char_id_ln_edt.placeholder_text = "Character ID"
	char_id_ln_edt.custom_minimum_size = Vector2(0.0, 32.0)
	char_id_ln_edt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_label.text = "Dialog"
	dialog_label.custom_minimum_size = Vector2(0.0, 24.0)
	dialog_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	highlighter.set_use_token("*", false)
	dialog_textedt.placeholder_text = "Character Dialog"
	dialog_textedt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_textedt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_textedt.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	dialog_textedt.caret_blink = true
	dialog_textedt.syntax_highlighter = highlighter
	
	persist_check.size_flags_horizontal = Control.SIZE_EXPAND + Control.SIZE_SHRINK_END
	persist_check.text = "Persist"
	flags_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_settings.text = "Settings"
	dialog_settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	use_code_editor_btn.custom_minimum_size = Vector2(32.0, 32.0)
	use_code_editor_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	use_code_editor_btn.tooltip_text = "Open Focus Editor"
	use_code_editor_btn.flat = true
	use_code_editor_btn.pressed.connect(_on_use_code_editor_pressed)
	
	settings_box.add_child(dialog_settings)
	settings_box.add_child(persist_check)
	
	char_id_ln_edt.text_changed.connect(_on_text_changed)
	dialog_textedt.text_changed.connect(_on_text_changed)
	
	id_box.add_child(char_id_label)
	id_box.add_child(char_id_ln_edt)
	id_box.add_child(char_selector_btn)
	
	flags_container.add_child(dialog_label)
	flags_container.add_child(use_code_editor_btn)
	
	id_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var connection_field: int = add_field(
			&"connection",
			connection_node,
			false,
			SlotConnectionType.DIALOG,
			SlotConnectionType.DIALOG)
	add_field(
			&"character_id",
			id_box,
			false,
			SlotConnectionType.SETTINGS_CHARACTER,
			-1)
	set_slot_color_left(1, COLORS["setting"])
	map_field(&"character_id", &"character_line", char_id_ln_edt)
	
	add_field(
			&"dialog_settings",
			settings_box,
			false,
			SlotConnectionType.SETTINGS_DIALOG,
			-1)
	set_slot_color_left(2, COLORS["setting"])
	
	var flgs_idx: int = add_field(&"flags", flags_container, false, SlotConnectionType.VAR_STRING, -1)
	
	map_field(&"dialog_settings", &"persist_checkbox", persist_check)
	map_field(&"flags", &"code_edit_button", use_code_editor_btn)
	add_field(&"dialog_text", dialog_textedt, true)
	
	set_slot_color_left(connection_field, COLORS["dialog"])
	set_slot_color_right(connection_field, COLORS["dialog"])
	
	set_slot_color_left(flgs_idx, COLORS.string)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/speech_bubble.svg")
	set_slot_custom_icon_left(0, flow_icon)
	set_slot_custom_icon_right(0, flow_icon)
	set_input_connection_icon(&"character_id", preload("res://addons/nexus_forge/icons/gear_icon.png"))
	set_input_connection_icon(&"dialog_settings", preload("res://addons/nexus_forge/icons/gear_icon.png"))
	set_input_connection_icon(&"flags", get_theme_icon("String", "EditorIcons"))
	get_mapped_field(&"flags", &"code_edit_button").icon = get_theme_icon("DistractionFree", "EditorIcons")
	get_field(&"character_id").get_child(2).icon = get_theme_icon("Search", "EditorIcons")


func _on_input_connected(input_port: int, from_node: DiscourseGraphNode, _from_port: int) -> void:
	match input_port:
		0:
			if from_node.node_type == DialogueNodeType.DIALOG and get_mapped_field(&"character_id", &"character_line").text.strip_edges().is_empty():
				var from_character_id: String = from_node.get_mapped_field(&"character_id", &"character_line").text
				if not from_character_id.strip_edges().is_empty():
					get_mapped_field(&"character_id", &"character_line").text = from_character_id
		3:
			free_size = size
			get_field(&"dialog_text").editable = false
			get_mapped_field(&"flags", &"code_edit_button").disabled = true
			get_child(4).visible = false
			custom_minimum_size.y = 160.0
			resizable = false
			set_deferred(&"size", Vector2(size.x, 0))


func _on_input_disconnected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	match input_port:
		3:
			get_field(&"dialog_text").editable = true
			get_mapped_field(&"flags", &"code_edit_button").disabled = false
			get_child(4).visible = true
			custom_minimum_size.y = 270.0
			resizable = true
			set_deferred(&"size", free_size)


func _get_node_data() -> Dictionary:
	var input_connections: Dictionary = {
		"character_settings": get_uuid_and_port_connected_to(PortMode.INPUT, 1),
		"dialog_settings": get_uuid_and_port_connected_to(PortMode.INPUT, 2),
		"dialog_text_source": get_uuid_and_port_connected_to(PortMode.INPUT, 3)}
	var output_connections: Dictionary = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	
	var metadata: Dictionary = {
		"character_id": get_mapped_field(&"character_id", &"character_line").text,
		"persist": get_mapped_field(&"dialog_settings", &"persist_checkbox").button_pressed,
		"size": size,
		"dialog_text": get_field(&"dialog_text").text.strip_edges()}
	
	return _build_node_data(metadata, output_connections, input_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("size") and typeof(metadata["size"]) == TYPE_VECTOR2:
		size = metadata["size"]
	
	if metadata.has("character_id") and typeof(metadata["character_id"]) == TYPE_STRING:
		get_mapped_field(&"character_id", &"character_line").text = metadata["character_id"]
	
	if metadata.has("dialog_text") and typeof(metadata["dialog_text"]) == TYPE_STRING:
		get_field(&"dialog_text").text = metadata["dialog_text"]
	
	if metadata.has("persist") and typeof(metadata["persist"]) == TYPE_BOOL:
		get_mapped_field(&"dialog_settings", &"persist_checkbox").button_pressed = metadata["persist"]
	
	if metadata.has("localized") and typeof(metadata["localized"]) == TYPE_BOOL:
		set_node_localized(metadata["localized"])


func _on_text_changed(_text: String = "") -> void:
	node_updated.emit()


func _on_use_code_editor_pressed() -> void:
	var field: TextEdit = get_field(&"dialog_text")
	use_code_editor_pressed.emit(field)


func _on_select_character_btn_pressed() -> void:
	var field: LineEdit = get_mapped_field(&"character_id", &"character_line")
	select_character_pressed.emit(field)


func set_dialog_text(text: String) -> void:
	get_field(&"dialog_text").text = text


func get_dialog_text() -> String:
	return get_field(&"dialog_text").text.strip_edges()
