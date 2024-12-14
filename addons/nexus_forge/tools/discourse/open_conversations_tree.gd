@tool
extends Tree


signal conversation_selected(selected_idx: int)


var root_tree: TreeItem


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	root_tree = create_item()
	item_selected.connect(_on_item_selected)


func get_open_conv_id() -> int:
	var selected: TreeItem = get_selected()
	if selected != null:
		return selected.get_index()
	return -1


func get_nearest_conv_id(from: int) -> int:
	var child_count: int = root_tree.get_child_count()
	if 0 < child_count:
		return clampi(
			from - 1 if 0 < from else from + 1,
			0,
			child_count - 1)
	return -1


func add_conversation(conversation_name: String) -> void:
	var new_conv: TreeItem = root_tree.create_child()
	new_conv.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_conv.set_text(0, conversation_name)


func remove_conversation(idx: int) -> void:
	root_tree.get_child(idx).free()


func select_no_signal(idx: int) -> void:
	item_selected.disconnect(_on_item_selected)
	root_tree.get_child(idx).select(0)
	item_selected.connect(_on_item_selected)


func select(idx: int) -> void:
	root_tree.get_child(idx).select(0)
	#item_selected.connect(_on_item_selected)


func clear_conversations() -> void:
	for conv in root_tree.get_children():
		conv.free()


func _on_item_selected() -> void:
	conversation_selected.emit(get_selected().get_index())
	
