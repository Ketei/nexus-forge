@tool
extends Tree


signal category_selected(category_id: StringName)
signal items_recategorized(new_category: StringName, items: Array[StringName])


func _ready() -> void:
	create_item()
	item_selected.connect(_on_item_selected)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has_all(["type", "items"]) or data["type"] != "items_array":
		return false
	
	drop_mode_flags = DROP_MODE_ON_ITEM
	
	var target_node: TreeItem = get_item_at_position(at_position)
	return get_drop_section_at_position(at_position) != -100


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var on_node: TreeItem = get_item_at_position(at_position)
	items_recategorized.emit(
			on_node.get_metadata(0),
			data["items"])


func _on_item_selected() -> void:
	var selected: TreeItem = get_selected()
	category_selected.emit(selected.get_metadata(0))


func add_category(category_id: StringName, on: TreeItem = get_root()) -> TreeItem:
	var new_item: TreeItem = on.create_child()
	new_item.set_text(0, "(unassigned)" if category_id.is_empty() else String(category_id))
	new_item.set_metadata(0, category_id)
	sort_single_item(new_item)
	return new_item


func get_category(category_id: StringName) -> TreeItem:
	return _find_item(category_id)


func _find_item(id: StringName, on: TreeItem = get_root()) -> TreeItem:
	for item in on.get_children():
		if item.get_metadata(0) == id:
			return item
		else:
			var in_child: TreeItem = _find_item(id, item)
			if in_child != null:
				return in_child
	return null


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	
	for child in item.get_parent().get_children():
		if child == item:
			continue # We ignore the item we just added
		
		if String(item.get_metadata(0)).naturalnocasecmp_to(String(child.get_metadata(0))) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != item.get_parent().get_child_count() - 1:
			item.move_after(item.get_parent().get_child(-1))


func clear_categories() -> void:
	for item in get_root().get_children():
		item.free()


func select_no_singal(item: TreeItem) -> void:
	item_selected.disconnect(_on_item_selected)
	item.select(0)
	item_selected.connect(_on_item_selected)
