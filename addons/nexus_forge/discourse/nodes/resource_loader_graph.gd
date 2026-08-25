extends DiscourseGraphNode


signal resource_path_changed(uuid: StringName, from: String, to: String)

var res_line: LineEdit


func _post_init() -> void:
	set_node_id(&"Resource")
	title = "Resource"
	node_type = DialogueNodeType.RESOURCE
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(260, 83)
	
	res_line = LineEdit.new()
	res_line.set_meta(&"old_value", "")
	
	res_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_line.placeholder_text = "Resource Path"
	res_line.custom_minimum_size.y = 32
	res_line.set_drag_forwarding(Callable(), _can_line_drop_data, _drop_line_data)
	res_line.text_changed.connect(node_updated.emit)
	res_line.editing_toggled.connect(_on_res_line_edit_toggled)
	
	add_field(
		&"res_path",
		res_line,
		false,
		-1,
		SlotConnectionType.RESOURCE)


func _ready() -> void:
	graph_icon = get_theme_icon("ResourcePreloader", "EditorIcons")
	set_slot_color_right(0, COLORS["object"])
	set_output_connection_icon(&"res_path", get_theme_icon("Object", "EditorIcons"))


func _get_node_data() -> Dictionary:
	var metadata: Dictionary = {
		"resource_path": res_line.text.strip_edges()}
	var output_connections: Dictionary = {
		"resource_target": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	
	return _build_node_data(metadata, output_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("resource_path") and typeof(metadata["resource_path"]) == TYPE_STRING:
		set_resource_path(metadata["resource_path"])


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	var res_line: LineEdit = get_field(&"res_path")
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if not ResourceLoader.exists(res_line.text.strip_edges()):
		issues.append("Warning: Provided resource '%s' does not exist" % res_line.text.strip_edges())
	return issues


func set_resource_path(path: String) -> void:
	res_line.text = path
	res_line.set_meta(&"old_value", path)


func _on_res_line_edit_toggled(is_toggled: bool) -> void:
	if is_toggled:
		return
	
	res_line.text = res_line.text.strip_edges()
	var old_value: String = res_line.get_meta(&"old_value")
	var new_value: String = res_line.text
	
	if new_value == old_value:
		return
	
	res_line.set_meta(&"old_value", new_value)
	
	resource_path_changed.emit(
			get_node_uuid(),
			old_value,
			new_value)


func _can_line_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has_all(["type", "files"]) and typeof(data["files"]) == TYPE_ARRAY and data["files"].size() == 1


func _drop_line_data(_at_position: Vector2, data: Variant) -> void:
	res_line.text = data["files"][0].strip_edges()
	var old_value: String = res_line.get_meta(&"old_value")
	var new_value: String = res_line.text
	
	if new_value == old_value:
		return
	
	res_line.set_meta(&"old_value", new_value)
	
	resource_path_changed.emit(
			get_node_uuid(),
			old_value,
			new_value)
