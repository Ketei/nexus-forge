extends DiscourseGraphNode


signal id_changed(uuid: String, new_id: String)

var current_id: String = ""


func _post_init() -> void:
	set_node_id(&"Anchor")
	title = "Anchor"
	node_type = DialogueNodeType.ANCHOR
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(260.0, 87.0)
	
	var anchor_id_lnedt: LineEdit = LineEdit.new()
	anchor_id_lnedt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	anchor_id_lnedt.placeholder_text = "Anchor ID"
	anchor_id_lnedt.focus_exited.connect(_on_id_focus_lost.bind(anchor_id_lnedt))
	anchor_id_lnedt.text_submitted.connect(_on_line_text_submitted.bind(anchor_id_lnedt))
	
	add_field(
			&"anchor",
			anchor_id_lnedt,
			false,
			-1,
			SlotConnectionType.DIALOG)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/dialog_entry.svg")
	set_slot_color_right(0, COLORS["dialog"])
	set_slot_custom_icon_right(0, flow_icon)


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if current_id.is_empty():
		issues.append("Error: Anchor has no set ID.")
	return issues


func _get_node_data() -> Dictionary:
	var metadata: Dictionary = {
		"anchor_id": current_id}
	
	var output_connections: Dictionary = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	
	return _build_node_data(metadata, output_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if not metadata.has("anchor_id") or typeof(metadata["anchor_id"]) != TYPE_STRING:
		return
	
	get_field(&"anchor").text = metadata["anchor_id"]
	if current_id != metadata["anchor_id"]:
		current_id = metadata["anchor_id"]
		id_changed.emit(_uuid, metadata["anchor_id"])


func _on_line_text_submitted(_text: String, line: LineEdit):
	line.release_focus()


func _on_id_focus_lost(line: LineEdit) -> void:
	line.text = line.text.strip_edges()
	
	if current_id == line.text:
		return
	
	current_id = line.text.strip_edges()
	id_changed.emit(_uuid, current_id)


func set_anchor_id(new_id: String) -> void:
	get_field(&"anchor").text = new_id
	current_id = new_id
	id_changed.emit(_uuid, new_id)


func get_anchor_id() -> String:
	return current_id
