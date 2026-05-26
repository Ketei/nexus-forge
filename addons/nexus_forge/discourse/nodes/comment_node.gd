extends DiscourseGraphNode


func _post_init() -> void:
	set_node_id(&"Comment")
	title = "Comment"
	size = Vector2(300.0, 180.0)
	custom_minimum_size = Vector2(300.0, 180.0)
	node_type = DialogueNodeType.COMMENT
	parent_mode = PortMode.NONE
	resizable = true
	
	var comment_box: TextEdit = TextEdit.new()
	comment_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	comment_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	comment_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_field(
			&"comment",
			comment_box,
			true)


func _get_node_data() -> Dictionary:
	var meta: Dictionary = {"comment": get_field(&"comment").text.strip_edges()}
	return _build_node_data(meta)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name"):
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	
	var meta: Dictionary = data["metadata"]
	
	if meta.has("position") and typeof(meta["position"]) == TYPE_VECTOR2:
		position_offset = meta["position"]
	
	if meta.has("comment") and typeof(meta["comment"]) == TYPE_STRING:
		get_field(&"comment").text = meta["comment"]
