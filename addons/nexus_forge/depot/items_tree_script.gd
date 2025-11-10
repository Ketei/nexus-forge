@tool
extends Tree


signal item_id_selected(item_id: StringName)
signal item_id_changed(from: StringName, to: StringName)
signal item_erased(item_id: StringName)


var current_search: String = ""


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	create_item()
	
	item_selected.connect(_on_item_selected)
	item_edited.connect(_on_item_edited)
	button_clicked.connect(_on_button_clicked)


func _get_drag_data(at_position: Vector2) -> Variant:
	var node: TreeItem = get_item_at_position(at_position)
	if node == null:
		return null
	
	var items_selected: Array[StringName] = [node.get_metadata(0)]
	var selected: TreeItem = get_next_selected(null)
	
	while selected != null:
		if selected == node:
			selected = get_next_selected(selected)
			continue
		items_selected.append(selected.get_metadata(0))
		selected = get_next_selected(selected)
	
	var data: Dictionary = {
		"type": "items_array",
		"items": items_selected}
	var preview: Label = Label.new()
	preview.text = "   " + str(items_selected.size()) + " item" + ("" if items_selected.size() == 1 else "s")
	set_drag_preview(preview)
	return data


func add_item(item_id: StringName, select: bool = false, with_signal: bool = true) -> void:
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, String(item_id))
	new_item.set_metadata(0, item_id)
	new_item.set_editable(0, true)
	new_item.add_button(
			0,
			get_theme_icon("Remove", "EditorIcons"),
			0,
			false,
			"Erase Item")
	
	sort_single_item(new_item)
	
	if select:
		if with_signal:
			new_item.select(0)
		else:
			select_item_no_signal(new_item)


func select_item_no_signal(item: TreeItem) -> void:
	item_selected.disconnect(_on_item_selected)
	item.select(0)
	item_selected.connect(_on_item_selected)


func remove_items(items: Array[StringName]) -> void:
	for item in get_root().get_children():
		if items.has(item.get_metadata(0)):
			item.free()


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		item_erased.emit(item.get_metadata(0))
		item.free()


func _on_item_selected() -> void:
	var selected: TreeItem = get_selected()
	item_id_selected.emit(selected.get_metadata(0))


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var new_text: String = get_valid_id(edited.get_text(0), edited)
	
	if new_text == String(edited.get_metadata(0)):
		return
	
	var old_id: StringName = edited.get_metadata(0)
	var new_id: StringName = StringName(new_text)
	
	edited.set_text(0, new_text)
	edited.set_metadata(0, new_id)
	
	item_id_changed.emit(old_id, new_id)


func get_valid_id(desired: String, skip: TreeItem = null) -> String:
	var modified: String = desired
	var iteration: int = 0
	
	while has_id(desired, skip):
		iteration += 1
		modified = desired + str(iteration)
	
	return modified


func has_id(id: String, skip: TreeItem = null) -> bool:
	for item in get_root().get_children():
		if item == skip:
			continue
		if item.get_text(0) == id:
			return true
	return false


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	
	for child in get_root().get_children():
		if child == item:
			continue # We ignore the item we just added
		if item.get_text(0).naturalnocasecmp_to(child.get_text(0)) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != get_root().get_child_count() - 1:
			item.move_after(get_root().get_child(-1))


func get_items() -> Array[String]:
	var all_items: Array[String] = []
	for item in get_root().get_children():
		all_items.append(item.get_text(0))
	return all_items


func clear_items() -> void:
	for item in get_root().get_children():
		item.free()


func search_for(text: String) -> void:
	if current_search == text:
		return
	
	for item in get_root().get_children():
		item.visible = text.is_empty() or item.get_text(0).containsn(text)
	
	current_search = text
