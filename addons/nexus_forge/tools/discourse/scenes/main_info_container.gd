extends Tree


signal center_dialog_pressed(node_ref: DiscourseGraphNode)

var root_node: TreeItem


func _ready() -> void:
	root_node = create_item()
	button_clicked.connect(on_go_to_node_pressed)


func log_item(log_text: String, related_node: DiscourseGraphNode) -> TreeItem:
	var new_log: TreeItem = root_node.create_child()
	new_log.set_text(0, log_text)
	if related_node != null:
		new_log.set_metadata(0, related_node)
		new_log.add_button(
				0,
				load("res://addons/nexus_forge/tools/discourse/icons/go_to.svg"),
				-1,
				false,
				"Go to Node")
	return new_log


func clear_logs() -> void:
	for child in root_node.get_children():
		child.free()


func on_go_to_node_pressed(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	var target_node: DiscourseGraphNode = item.get_metadata(0)
	if target_node != null:
		center_dialog_pressed.emit(item.get_metadata(0))


func get_log_count() -> int:
	return root_node.get_child_count()
