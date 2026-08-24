extends DiscourseGraphNode

signal type_changed(uuid: StringName, from: int, to: int)
signal path_changed(uuid: StringName, from: String, to: String)

var path_line: LineEdit
var type_menu: MenuButton


func _post_init() -> void:
	set_node_id(&"GetVar")
	title = "Get Variable"
	node_type = DialogueNodeType.VARIABLE_GET
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(260.0, 84.0)
	
	var path_container: HBoxContainer = HBoxContainer.new()
	path_line = LineEdit.new()
	type_menu = MenuButton.new()
	var type_popup: PopupMenu = type_menu.get_popup()
	
	path_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_line.placeholder_text = "Variable Path"
	path_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_line.set_meta(&"old_value", "")
	
	type_menu.flat = false
	type_menu.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_menu.custom_minimum_size = Vector2(32.0, 32.0)
	
	type_menu.set_meta(&"current_type", TYPE_INT)
	
	path_container.add_child(path_line)
	path_container.add_child(type_menu)
	
	add_field(
			&"path",
			path_container,
			false,
			-1,
			SlotConnectionType.VAR_INT)
	
	set_slot_color_right(0, COLORS["integer"])
	
	path_line.editing_toggled.connect(_on_var_line_edit_toggled)
	path_line.text_changed.connect(_on_path_line_text_changed)
	type_popup.id_pressed.connect(_on_type_selected)


func _ready() -> void:
	var type_popup: PopupMenu = type_menu.get_popup()
	graph_icon = get_theme_icon("LocalVariable", "EditorIcons")
	
	match type_menu.get_meta(&"current_type", TYPE_INT):
		TYPE_INT:
			type_menu.icon = get_theme_icon("int", "EditorIcons")
		TYPE_FLOAT:
			type_menu.icon = get_theme_icon("float", "EditorIcons")
		TYPE_BOOL:
			type_menu.icon = get_theme_icon("bool", "EditorIcons")
		TYPE_STRING:
			type_menu.icon = get_theme_icon("String", "EditorIcons")
	type_popup.add_icon_item(
			get_theme_icon("int", "EditorIcons"),
			"",
			TYPE_INT)
	type_popup.add_icon_item(
			get_theme_icon("float", "EditorIcons"),
			"",
			TYPE_FLOAT)
	type_popup.add_icon_item(
			get_theme_icon("bool", "EditorIcons"),
			"",
			TYPE_BOOL)
	type_popup.add_icon_item(
			get_theme_icon("String", "EditorIcons"),
			"",
			TYPE_STRING)
	type_popup.add_icon_item(
			get_theme_icon("Variant", "EditorIcons"),
			"",
			TYPE_NIL)


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if has_any_output(0) and path_line.text.strip_edges().is_empty():
		issues.append("Error: Variable is being accessed but no path exists.")
	return issues


func _get_node_data() -> Dictionary:
	var output_connections: Dictionary = {
		"target": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	var metadata: Dictionary = {
		"variable_path": path_line.text.strip_edges(),
		"variable_type": type_menu.get_meta(&"current_type", TYPE_NIL)}
	
	return _build_node_data(metadata, output_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("variable_path") and typeof(metadata["variable_path"]) == TYPE_STRING:
		path_line.text = metadata["variable_path"]
		path_line.set_meta(&"old_value", metadata["variable_path"])
		
		if metadata.has("variable_type") and typeof(metadata["variable_type"]) == TYPE_INT:
			set_node_type(metadata["variable_type"])
		else:
			set_node_type(TYPE_NIL)


func _on_path_line_text_changed(_text: String) -> void:
	node_updated.emit()


func _on_var_line_edit_toggled(is_toggled: bool) -> void:
	if is_toggled:
		return
	
	var new_value: String = path_line.text
	var old_value: String = path_line.get_meta(&"old_value")
	
	if new_value == old_value:
		return
	
	path_line.set_meta(&"old_value", new_value)
	path_line.tooltip_text = path_line.text
	path_changed.emit(
			get_node_uuid(),
			old_value,
			new_value)


func _on_type_selected(item_id: int) -> void:
	var menu: MenuButton = get_field(&"path").get_child(1)
	var old_value: int = menu.get_meta(&"old_value")
	
	if item_id == old_value:
		return
	
	if has_any_output(0):
		var target: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, 0)
		var target_port_type: int = target.get_input_port_type(get_target_port_connected_to_self(PortMode.OUTPUT, 0))
		
		if not is_port_type_value_compatible(target_port_type, item_id):
			disconnect_port(PortMode.OUTPUT, 0)
	
	set_node_type(item_id)
	
	type_changed.emit(
			get_node_uuid(),
			old_value,
			item_id)


func is_port_type_value_compatible(port_type: int, value: int) -> bool:
	if port_type == SlotConnectionType.VAR_ANY:
		return true
	elif port_type == SlotConnectionType.VAR_INT and value == TYPE_INT:
		return true
	elif port_type == SlotConnectionType.VAR_FLOAT and value == TYPE_FLOAT:
		return true
	elif port_type == SlotConnectionType.VAR_BOOL and value == TYPE_BOOL:
		return true
	elif port_type == SlotConnectionType.VAR_STRING and value == TYPE_STRING:
		return true
	else:
		return false


func set_node_type(item_id: int) -> void:
	var menu: MenuButton = get_field(&"path").get_child(1)
	var old_type: int = menu.get_meta(&"old_value")
	
	if old_type == item_id:
		return
	
	match item_id:
		TYPE_INT:
			menu.icon = get_theme_icon("int", "EditorIcons")
			set_slot_color_right(0, COLORS["integer"])
			set_slot_type_right(0, SlotConnectionType.VAR_INT)
			menu.set_meta(&"current_type", TYPE_INT)
			menu.set_meta(&"old_value", TYPE_INT)
		TYPE_FLOAT:
			menu.icon = get_theme_icon("float", "EditorIcons")
			set_slot_color_right(0, COLORS["float"])
			set_slot_type_right(0, SlotConnectionType.VAR_FLOAT)
			menu.set_meta(&"current_type", TYPE_FLOAT)
			menu.set_meta(&"old_value", TYPE_FLOAT)
		TYPE_BOOL:
			menu.icon = get_theme_icon("bool", "EditorIcons")
			set_slot_color_right(0, COLORS["bool"])
			set_slot_type_right(0, SlotConnectionType.VAR_BOOL)
			menu.set_meta(&"current_type", TYPE_BOOL)
			menu.set_meta(&"old_value", TYPE_BOOL)
		TYPE_STRING:
			menu.icon = get_theme_icon("String", "EditorIcons")
			set_slot_color_right(0, COLORS["string"])
			set_slot_type_right(0, SlotConnectionType.VAR_STRING)
			menu.set_meta(&"current_type", TYPE_STRING)
			menu.set_meta(&"old_value", TYPE_STRING)
		_:
			menu.icon = get_theme_icon("Variant", "EditorIcons")
			set_slot_color_right(0, COLORS["any"])
			set_slot_type_right(0, SlotConnectionType.VAR_ANY)
			menu.set_meta(&"current_type", TYPE_NIL)
			menu.set_meta(&"old_value", TYPE_NIL)
