@tool
extends IDTree


var sort_column: int = 0

var current_search: String = ""

func ready_plugin() -> void:
	create_item()
	set_column_title(0, "Item ID")
	set_column_title(1, "Item Name")
	column_title_clicked.connect(_on_column_title_clicked)


func _get_drag_data(at_position: Vector2) -> Variant:
	var node: TreeItem = get_item_at_position(at_position)
	if node == null:
		return null
	
	var item_label := Label.new()
	item_label.text = "   " + node.get_text(0)
	set_drag_preview(item_label)
	
	return {"type": "item_id", "is_new": true, "item_id": StringName(node.get_text(0))}


func _on_column_title_clicked(column: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT or column == sort_column:
		return
	
	sort_column = column
	
	var items: Array[TreeItem] = get_root().get_children()
	var item_count: int = items.size()
	
	if item_count < 2:
		return
	
	items.sort_custom(
			func(a:TreeItem,b:TreeItem): 
				return a.get_text(column).naturalnocasecmp_to( b.get_text(column)) < 0 )
	
	if items[0].get_index() != 0:
		items[0].move_before(get_root().get_first_child())
	
	for item_idx in range(1, item_count):
		items[item_idx].move_after(items[item_idx - 1])


func add_item(item_id: StringName, item_name: String) -> void:
	var item: TreeItem = get_root().create_child()
	item.set_text(0, String(item_id))
	item.set_text(1, item_name)
	item.set_metadata(0, item_id)
	sort_single_item(item)


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	
	for child in get_root().get_children():
		if child == item:
			continue # We ignore the item we just added
		if item.get_text(sort_column).naturalnocasecmp_to(child.get_text(sort_column)) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != get_root().get_child_count() - 1:
			item.move_after(get_root().get_child(-1))


func clear_items() -> void:
	for item in get_root().get_children():
		item.free()


func change_name(from: StringName, to: String) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0) == from:
			item.set_text(1, to)
			break


func change_id(from: StringName, to: StringName) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0) == from:
			item.set_text(0, String(to))
			item.set_metadata(0, to)
			break


func remove_item(id: StringName) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0) == id:
			item.free()
			break


func search_for(text: String) -> void:
	if text == current_search:
		return
	for item in get_root().get_children():
		item.visible = text.is_empty() or item.get_text(0).containsn(text) or item.get_text(1).containsn(text)
	current_search = text
