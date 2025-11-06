extends DiscourseGraphNode


var free_size: Vector2 = Vector2(400.0, 300.0)


func _post_init() -> void:
	name = &"Dialog"
	custom_id = "Dialog"
	title = "Dialog"
	node_type = DialogueNodeType.DIALOG
	parent_mode = PortMode.INPUT
	parent_port = 0
	size = Vector2(400.0, 340.0)
	custom_minimum_size = Vector2(400.0, 340.0)
	resizable = true
	
	var connection_node: Control = Control.new()
	var id_box: HBoxContainer = HBoxContainer.new()
	var dialog_box: VBoxContainer = VBoxContainer.new()
	var char_id_label: Label = Label.new()
	var char_id_ln_edt: LineEdit = LineEdit.new()
	var dialog_label: Label = Label.new()
	var dialog_settings: Label = Label.new()
	var dialog_textedt: TextEdit = TextEdit.new()
	var persist_check: CheckBox = CheckBox.new()
	var flags_container: HBoxContainer = HBoxContainer.new()
	
	connection_node.name = &"Connection"
	id_box.name = &"IDContainer"
	dialog_box.name = &"DialogContainer"
	char_id_label.name = &"IDLabel"
	char_id_ln_edt.name = &"CharIDLnEdt"
	dialog_label.name = &"DialogLabel"
	dialog_textedt.name = &"DialogTxtEdt"
	persist_check.name = &"PersistChkBx"
	
	connection_node.custom_minimum_size = Vector2(0.0, 24.0)
	char_id_label.text = "Character"
	char_id_label.custom_minimum_size = Vector2(80.0, 0.0)
	char_id_ln_edt.caret_blink = true
	char_id_ln_edt.placeholder_text = "Character ID"
	char_id_ln_edt.custom_minimum_size = Vector2(0.0, 32.0)
	char_id_ln_edt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_label.text = "Dialog"
	dialog_label.custom_minimum_size = Vector2(0.0, 24.0)
	dialog_textedt.placeholder_text = "Character Dialog"
	dialog_textedt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_textedt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_textedt.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	dialog_textedt.caret_blink = true
	persist_check.size_flags_horizontal = Control.SIZE_EXPAND + Control.SIZE_SHRINK_END
	persist_check.text = "Persist"
	flags_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_settings.text = "Settings"
	dialog_settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	char_id_ln_edt.text_changed.connect(_on_text_changed)
	dialog_textedt.text_changed.connect(_on_text_changed)
	
	id_box.add_child(char_id_label)
	id_box.add_child(char_id_ln_edt)
	
	flags_container.add_child(dialog_label)
	flags_container.add_child(persist_check)
	
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
			-1,
			preload("res://addons/nexus_forge/icons/gear_icon.png"))
	set_slot_color_left(1, COLORS["setting"])
	map_field(&"character_id", "character_line", char_id_ln_edt)
	
	add_field(
			&"dialog_settings",
			dialog_settings,
			false,
			SlotConnectionType.SETTINGS_DIALOG,
			-1,
			preload("res://addons/nexus_forge/icons/gear_icon.png"))
	set_slot_color_left(2, COLORS["setting"])
	
	var flgs_idx: int = add_field(&"flags", flags_container, false, SlotConnectionType.VAR_STRING, -1, get_theme_icon("String", "EditorIcons"))
	map_field(&"flags", "persist_checkbox", persist_check)
	add_field(&"dialog_text", dialog_textedt, true)
	
	set_slot_color_left(connection_field, COLORS["dialog"])
	set_slot_color_right(connection_field, COLORS["dialog"])
	
	set_slot_custom_icon_left(connection_field, flow_icon)
	set_slot_custom_icon_right(connection_field, flow_icon)
	set_slot_color_left(flgs_idx, COLORS.string)


func _on_input_connected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	match input_port:
		3:
			free_size = size
			get_field(&"dialog_text").editable = false
			get_child(4).visible = false
			custom_minimum_size.y = 160.0
			resizable = false
			set_deferred(&"size", Vector2(400.0, 190.0))


func _on_input_disconnected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	match input_port:
		3:
			get_field(&"dialog_text").editable = true
			get_child(4).visible = true
			custom_minimum_size.y = 340.0
			resizable = true
			set_deferred(&"size", free_size)


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["size"] = size
	data["character_id"] = get_mapped_field(&"character_id", "character_line").text
	data["dialog_text"] = get_field(&"dialog_text").text.strip_edges()
	data["persist"] = get_mapped_field(&"flags", "persist_checkbox").button_pressed
	data["input_connections"] = {
		"character_settings": get_uuid_and_port_connected_to(PortMode.INPUT, 1),
		"dialog_settings": get_uuid_and_port_connected_to(PortMode.INPUT, 2),
		"dialog_text_source": get_uuid_and_port_connected_to(PortMode.INPUT, 3)}
	data["output_connections"] = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	
	return data


func _set_node_data(data: Dictionary) -> void:
	get_mapped_field(&"character_id", "character_line").text = data["character_id"]
	get_field(&"dialog_text").text = data["dialog_text"]
	position_offset = data["position"]
	size = data["size"]
	get_mapped_field(&"flags", "persist_checkbox").button_pressed = data["persist"]


func _on_text_changed(_text: String = "") -> void:
	node_updated.emit()


#func _clone() -> DiscourseGraphNode:
	#var titlebox: HBoxContainer = get_titlebar_hbox().get_child(-1)
	#var new_node: DiscourseGraphNode = get_script().new(
			#"",
			#theme_type_variation,
			#titlebox.has_node(^"DuplicateBtn"),
			#titlebox.has_node(^"CloseBtn"),
			#titlebox.has_node(^"EditIdBtn"),
			#titlebox.has_node(^"LocalizeBtn"))
	#var data: Dictionary = _get_node_data()
	#data["dialog_text"] = get_field(&"dialog_text").text
	#new_node._set_node_data(data)
	#
	#return new_node


func set_dialog_text(text: String) -> void:
	get_field(&"dialog_text").text = text


func get_dialog_text() -> String:
	return get_field(&"dialog_text").text.strip_edges()
