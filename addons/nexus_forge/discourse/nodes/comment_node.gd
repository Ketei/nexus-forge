extends DiscourseGraphNode


func _post_init() -> void:
	name = &"Comment"
	custom_id = "Comment"
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
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["comment"] = get_field(&"comment").text.strip_edges()
	return data


func _set_node_data(data: Dictionary) -> void:
	position_offset = data["position"]
	get_field(&"comment").text = data["comment"]
