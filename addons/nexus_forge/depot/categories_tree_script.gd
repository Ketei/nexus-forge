@tool
extends Tree


#signal category_deleted(item: TreeItem)
signal category_id_changed(from: StringName, to: StringName)
#signal category_renamed(id: StringName, new_name: String)
signal category_created(category_id: StringName)
signal category_changed

var erased_categories: Array[StringName] = []
var sort_column: int = 0


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	set_column_title(0, "ID")
	set_column_title(1, "Name")
	create_item()
	item_edited.connect(_on_item_edited)
	button_clicked.connect(_on_button_clicked)
	column_title_clicked.connect(_on_column_title_clicked)


func _get_drag_data(at_position: Vector2) -> Variant:
	var node: TreeItem = get_item_at_position(at_position)
	if node == null:
		return null
	
	var data: Dictionary = {
		"type": "item_category",
		"node": node}
	var preview: Label = Label.new()
	preview.text = "   " + node.get_text(0)
	set_drag_preview(preview)
	return data


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has_all(["type", "node"]) or data["type"] != "item_category":
		return false
	
	drop_mode_flags = DROP_MODE_ON_ITEM
	
	var target_node: TreeItem = get_item_at_position(at_position)
	return target_node != data["node"] and get_drop_section_at_position(at_position) != -100 and not _has_parent(target_node, data["node"]) and not data["node"].get_parent() == target_node


func _has_parent(item: TreeItem, to: TreeItem) -> bool:
	var current_item: TreeItem = item
	while current_item.get_parent() != null:
		if current_item == to:
			return true
		current_item = current_item.get_parent()
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var on_node: TreeItem = get_item_at_position(at_position)
	data["node"].get_parent().remove_child(data["node"])
	on_node.add_child(data["node"])
	sort_single_item(data["node"])


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	if id == 0:
		erased_categories.append(item.get_metadata(0)["original_id"])
		#category_deleted.emit(item)
		category_changed.emit()
		item.free()
	elif id == 1:
		var data: Dictionary[String, Variant] = {}
		var id_text: String = get_valid_id("new_subcategory")
		data.assign(ItemCatalog.ITEM_DEFAULT_DATA)
		create_category(
			id_text,
			"New Subcategory",
			data,
			item)
		category_created.emit(StringName(id_text))
		category_changed.emit()


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var column: int = get_edited_column()
	
	if column == 0:
		var valid_string: String = get_valid_id(edited.get_text(0), edited)
		if edited.get_metadata(0)["id"] == valid_string:
			return
		var old_id: StringName = StringName(edited.get_metadata(0)["id"])
		var new_id: StringName = StringName(valid_string)
		edited.set_text(0, valid_string)
		edited.get_metadata(0)["id"] = valid_string
		if sort_column == 0:
			sort_single_item(edited)
		category_id_changed.emit(old_id, new_id)
		category_changed.emit()
	if column == 1:
		if edited.get_text(1) == edited.get_metadata(0)["name"]:
			return
		edited.get_metadata(0)["name"] = edited.get_text(1)
		if sort_column == 1:
			sort_single_item(edited)
		category_changed.emit()


func create_category(category_id: String, category_name: String, data: Dictionary[String, Variant] = {}, on: TreeItem = get_root()) -> TreeItem:
	var valid_id: String = get_valid_id(category_id)
	var new_category: TreeItem = on.create_child()
	new_category.set_text(0, category_id)
	new_category.set_text(1, category_name)
	new_category.set_metadata(0, {"id": category_id, "original_id": StringName(category_id), "name": category_name, "data": data})
	new_category.add_button(
			1,
			get_theme_icon("New", "EditorIcons"),
			1,
			false,
			"New Subcategory")
	new_category.add_button(
			1,
			get_theme_icon("Remove", "EditorIcons"),
			0,
			false,
			"Erase Category")
	new_category.set_editable(0, true)
	new_category.set_editable(1, true)
	sort_single_item(new_category)
	return new_category


func clear_categories() -> void:
	for item in get_root().get_children():
		item.free()


func get_valid_id(desired: String, skip: TreeItem = null) -> String:
	var modified: String = desired
	var iteration: int = 0
	var all_ids: Array[String] = active_categories()
	
	if skip != null:
		all_ids.erase(skip.get_text(0))
	
	while all_ids.has(modified):
		iteration += 1
		modified = desired + str(iteration)
	
	return modified


#func has_id(id: String, skip: TreeItem = null) -> bool:
	#for item in get_root().get_children():
		#if item == skip:
			#continue
		#if item.get_text(0) == id:
			#return true
	#return false


func active_categories(_from: TreeItem = get_root()) -> Array[String]:
	var all_cats: Array[String] = []
	for item in _from.get_children():
		all_cats.append(item.get_text(0))
		all_cats.append_array(active_categories(item))
	return all_cats


#func get_active_id(category_id)


func _on_column_title_clicked(column: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	sort_column = column
	_sort_items_on(get_root())


func _sort_items_on(item: TreeItem) -> void:
	var all_items: Array[TreeItem] = item.get_children()
	
	for child in all_items:
		_sort_items_on(child)
	
	if all_items.size() <= 1:
		return
	
	all_items.sort_custom(func(a,b): return a.get_text(sort_column).naturalnocasecmp_to(b.get_text(sort_column)) < 0)
	
	all_items[0].move_before(item.get_child(0))
	
	for item_idx in range(1, all_items.size()):
		all_items[item_idx].move_after(all_items[item_idx - 1])


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	
	for child in item.get_parent().get_children():
		if child == item:
			continue # We ignore the item we just added
		
		if item.get_text(sort_column).naturalnocasecmp_to(child.get_text(sort_column)) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != item.get_parent().get_child_count() - 1:
			item.move_after(item.get_parent().get_child(-1))
