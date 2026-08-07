@tool
extends Tree

signal category_id_changed(from: StringName, to: StringName)
signal category_name_changed(id: StringName, from: String, to: String)
signal category_moved(category_id: String, new_parent: String)
signal category_created(category_id: StringName)
signal erase_category_pressed(category_id: String)
signal category_selected(category_id: StringName)

var sort_column: int = 0
var categories: Dictionary[StringName, TreeItem] = {}


func ready_plugin() -> void:
	set_column_title(0, "ID")
	set_column_title(1, "Name")
	create_item()
	item_edited.connect(_on_item_edited)
	button_clicked.connect(_on_button_clicked)
	column_title_clicked.connect(_on_column_title_clicked)
	item_mouse_selected.connect(_on_item_mouse_selected)


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var item: TreeItem = get_selected()
	category_selected.emit(StringName(item.get_metadata(0)["id"]))


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
	
	
	var target_node: TreeItem = get_item_at_position(at_position)
	
	if target_node == null:
		drop_mode_flags = DROP_MODE_ON_ITEM
		return true
	elif _has_parent(target_node, data["node"]):
		drop_mode_flags = DROP_MODE_DISABLED
		return false
	elif data["node"] == target_node:
		drop_mode_flags = DROP_MODE_DISABLED
		return false
	
	drop_mode_flags = DROP_MODE_ON_ITEM
	
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var on_node: TreeItem = get_item_at_position(at_position)
	
	if on_node == null:
		on_node = get_root()
	
	if data["node"].get_parent() == on_node:
		return
	
	data["node"].get_parent().remove_child(data["node"])
	on_node.add_child(data["node"])
	sort_single_item(data["node"])
	category_moved.emit(data["node"].get_text(0), "" if on_node == get_root() else on_node.get_text(0))


func _has_parent(item: TreeItem, to: TreeItem) -> bool:
	var current_item: TreeItem = item
	while current_item.get_parent() != null:
		if current_item == to:
			return true
		current_item = current_item.get_parent()
	return false


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0: # Erase
		erase_category_pressed.emit(item.get_text(0))
	elif id == 1: # New Subcategory
		var id_text: String = get_valid_id("new_subcategory")
		create_category(
			id_text,
			"New Subcategory",
			item.get_text(0))
		category_created.emit(id_text)


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var column: int = get_edited_column()
	
	if column == 0:
		var valid_string: String = get_valid_id(edited.get_text(0), edited)
		if edited.get_metadata(0)["id"] == valid_string:
			return
		var old_id: String = edited.get_metadata(0)["id"]
		var new_id: String = valid_string
		edited.set_text(0, new_id)
		edited.get_metadata(0)["id"] = new_id
		categories[new_id] = categories[old_id]
		categories.erase(old_id)
		if sort_column == 0:
			sort_single_item(edited)
		category_id_changed.emit(old_id, new_id)
	elif column == 1:
		if edited.get_text(1) == edited.get_metadata(0)["name"]:
			return
		var old_name: String = edited.get_metadata(0)["name"]
		edited.get_metadata(0)["name"] = edited.get_text(1)
		if sort_column == 1:
			sort_single_item(edited)
		category_name_changed.emit(StringName(edited.get_metadata(0)["id"]), old_name, edited.get_text(1))


func create_category(category_id: String, category_name: String, on: String) -> void:
	var valid_id: String = get_valid_id(category_id)
	
	if not on.is_empty() and not categories.has(on):
		return
	
	_add_category(StringName(valid_id), category_name, on)


func select_category(category_id: StringName, emit_select: bool = true) -> void:
	if not categories.has(category_id):
		return
	
	var target: TreeItem = categories[category_id]
	target.select(0)
	if emit_select:
		category_selected.emit(StringName(target.get_metadata(0)["id"]))


func set_category_id(of: StringName, new_id: StringName) -> void:
	if not has_category(of) or has_category(new_id):
		return
	var new_string: String = String(new_id)
	var target: TreeItem = categories[of]
	categories[new_id] = categories[of]
	categories.erase(of)
	target.set_text(0, new_string)
	target.get_metadata(0)["id"] = new_string
	if sort_column == 0:
		sort_single_item(target)


func set_category_name(id: StringName, new_name: String) -> void:
	if has_category(id):
		categories[id].set_text(1, new_name)
		categories[id].get_metadata(0)["name"] = new_name


func get_category_map(category_id: StringName) -> Dictionary[StringName, Dictionary]:
	var data: Dictionary[StringName, Dictionary] = {}
	
	if not has_category(category_id):
		return data
	
	return _get_map_of(categories[category_id])


func get_subcategories_of(category: StringName) -> Array[StringName]:
	var subcats: Array[StringName] = []
	if not has_category(category):
		return subcats
	_get_subcategories(_get_category(category), subcats)
	return subcats


func _get_subcategories(item: TreeItem, on: Array[StringName]) -> void:
	for child in item.get_children():
		on.append(StringName(child.get_metadata(0)["id"]))
		_get_subcategories(child, on)


func _restore_categories(on_category: StringName, map: Dictionary[StringName, Dictionary]) -> void:
	if not on_category.is_empty() and not has_category(on_category):
		NFPluginGameHandler._log_msg(
				"depot - editor",
				"Trying to restore category on '%s', but the category doesn't exist." % on_category,
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	for category_id in map:
		if has_category(category_id):
			NFPluginGameHandler._log_msg(
					"depot - editor",
					"Trying to restore category '%s', but it already exists." % category_id,
					NFPluginGameHandler._LogLevel.ERROR)
			continue
		_add_category(
			category_id,
			map[category_id]["name"],
			on_category)
	
		for subcategory_id in map["subcategories"]:
			_restore_subcategory_on(
					category_id,
					subcategory_id,
					map[subcategory_id]["name"],
					map[subcategory_id]["subcategories"])


func _restore_subcategory_on(on: String, subcategory_id: String, subcategory_name: String, subcategories: Dictionary[String, Dictionary]) -> void:
	if not has_category(on):
		return
	
	if has_category(subcategory_id):
		NFPluginGameHandler._log_msg(
				"depot - editor",
				"Trying to restore category '%s', but it already exists." % subcategory_id,
				NFPluginGameHandler._LogLevel.ERROR)
		return
		
	_add_category(subcategory_id, subcategory_name, on)
	
	for sub_id in subcategories:
		_restore_subcategory_on(
				subcategory_id,
				sub_id,
				subcategories[sub_id]["name"],
				subcategories[sub_id]["subcategories"])


func _get_map_of(item: TreeItem) -> Dictionary[StringName, Dictionary]:
	var data: Dictionary[StringName, Dictionary] = {}
	for child in item.get_children():
		data[StringName(child.get_metadata(0)["id"])] = {
			"name": child.get_text(1),
			"subcategories": _get_map_of(child)}
	return data


func _add_category(category_id: StringName, category_name: String, on: StringName) -> bool:
	if categories.has(category_id) or (not on.is_empty() and not categories.has(on)):
		return false
	var category_parent: TreeItem = get_root() if on.is_empty() else categories[on]
	
	var new_category: TreeItem = category_parent.create_child()
	var id_name: String = String(category_id)
	new_category.set_text(0, category_id)
	new_category.set_text(1, category_name)
	new_category.set_metadata(0, {"id": category_id, "name": category_name})
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
	
	categories[category_id] = new_category
	return true


func _get_category(category_id: StringName) -> TreeItem:
	if categories.has(category_id):
		return categories[category_id]
	return null


func erase_category(category_id: StringName) -> void:
	if has_category(category_id):
		var target: TreeItem = categories[category_id]
		_remove_category(category_id)
		target.free()


func _remove_category(category_id: StringName) -> void:
	var target: TreeItem = categories[category_id]
	for category in target.get_children():
		_remove_category(StringName(category.get_metadata(0)["id"]))
	categories.erase(category_id)


func get_category_name(category: StringName) -> String:
	if has_category(category):
		return categories[category].get_text(1)
	return ""


func get_category_parent(category: StringName) -> StringName:
	if categories.has(category):
		var target: TreeItem = categories[category]
		if target.get_parent() == get_root():
			return &""
		else:
			return StringName(target.get_parent().get_metadata(0)["id"])
	return &""


func move_category(category: StringName, under: StringName = &"") -> void:
	if category.is_empty() or not has_category(category) or (not under.is_empty() and not categories.has(under)):
		return
	
	var source: TreeItem = categories[category]
	var to_target: TreeItem = null
	
	if under.is_empty():
		to_target = get_root()
	else:
		to_target = categories[under]
	
	if source.get_parent() != to_target:
		source.get_parent().remove_child(source)
		to_target.add_child(source)
		sort_single_item(source)


func has_category(category_id: StringName) -> bool:
	return categories.has(category_id)


func clear_categories() -> void:
	clear()
	create_item()
	categories.clear()


func get_valid_id(desired: String, skip: TreeItem = null) -> String:
	var all_ids: Dictionary[String, Variant] = {}
	var base: String = desired
	var modified: String = desired
	var trailing_data: Dictionary = StringUtils.get_trailing_integer(desired)
	var iteration: int = trailing_data["integer"]
	if trailing_data["has_integer"]:
		base = desired.trim_suffix(str(iteration))
	
	for category_id in categories:
		if categories[category_id] == skip:
			continue
		all_ids[String(category_id)] = null
	
	while all_ids.has(modified):
		iteration += 1
		modified = base + str(iteration)
	
	return modified


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


func search_for(text: String) -> void:
	var is_empty: bool = text.is_empty()
	for top_category in get_root().get_children():
		top_category.visible = _search_on_children(top_category, text) or is_empty or top_category.get_text(0).containsn(text)


func _search_on_children(from: TreeItem, text: String) -> bool:
	var empty: bool = text.is_empty()
	var pattern_found: bool = false
	for item in from.get_children():
		item.visible = _search_on_children(item, text) or empty or item.get_text(0).containsn(text)
		if not pattern_found and item.visible:
			pattern_found = true
	return pattern_found
