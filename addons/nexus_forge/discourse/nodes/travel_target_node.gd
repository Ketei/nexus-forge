extends DiscourseGraphNode


signal id_changed(uuid: String, old_id: String, new_id: String)

var id_line: LineEdit


func _post_init() -> void:
	set_node_id(&"Waypoint")
	title = "Waypoint"
	node_type = DialogueNodeType.TRAVEL_TARGET
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(200.0, 87.0)
	
	id_line = LineEdit.new()
	id_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	id_line.placeholder_text = "Anchor ID"
	id_line.set_meta(&"old_value", "")
	id_line.editing_toggled.connect(_on_id_edit_toggled)
	
	add_field(
			&"waypoint",
			id_line,
			false,
			-1,
			SlotConnectionType.DIALOG)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/travel_waypoint.svg")
	set_slot_color_right(0, COLORS["dialog"])
	set_slot_custom_icon_right(0, flow_icon)


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if id_line.is_empty():
		issues.append("Error: Waypoint has no set ID.")
	return issues


func _get_node_data() -> Dictionary:
	var metadata: Dictionary = {
		"waypoint_id": id_line.text}
	
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
	
	if metadata.has("waypoint_id") and typeof(metadata["waypoint_id"]) == TYPE_STRING:
		set_waypoint_id(metadata["waypoint_id"])


func _on_id_edit_toggled(is_toggled: bool) -> void:
	if is_toggled:
		return
	
	var old_value: String = id_line.get_meta(&"old_value")
	var new_value: String = id_line.text
	
	if old_value == new_value:
		return
	
	id_line.set_meta(&"old_value", new_value)
	
	id_changed.emit(get_node_uuid(), old_value, new_value)


func set_waypoint_id(new_id: String) -> void:
	id_line.text = new_id
	id_line.set_meta(&"old_value", new_id)


func get_waypoint_id() -> String:
	return id_line.text
