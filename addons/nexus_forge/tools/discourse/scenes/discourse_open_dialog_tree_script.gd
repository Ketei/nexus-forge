@tool
extends Tree


signal conversation_selected(conv_tree: TreeItem)

var file_root: TreeItem = null


func _ready() -> void:
	file_root = create_item()
	item_selected.connect(on_item_selected)


func add_file(file_text) -> TreeItem:
	var new_item = create_item(file_root)
	new_item.set_text(0, file_text)
	return new_item


func get_open_file_count() -> int:
	return file_root.get_child_count()


func get_file_child(child_idx: int) -> TreeItem:
	return file_root.get_child(child_idx)


func get_tree_children() -> Array[TreeItem]:
	return file_root.get_children()


func on_item_selected() -> void:
	conversation_selected.emit(get_selected())
