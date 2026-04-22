@tool
extends IDTree


signal recipe_selected(id: StringName)
signal recipe_id_changed(from: StringName, to: StringName)
signal recipe_erased(id: StringName)


var current_search: String = ""


func ready_plugin() -> void:
	create_item()
	
	item_selected.connect(_on_item_selected)
	item_edited.connect(_on_item_edited)
	button_clicked.connect(_on_button_clicked)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		recipe_erased.emit(item.get_metadata(0))
		item.free()


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var valid_id: String = get_unique_id(
			get_root(),
			edited.get_text(0),
			edited)
	
	if valid_id == String(edited.get_metadata(0)):
		return
	
	var old_id: StringName = edited.get_metadata(0)
	var new_id: StringName = StringName(valid_id)
	
	edited.set_text(0, valid_id)
	edited.set_metadata(0, new_id)
	
	recipe_id_changed.emit(old_id, new_id)


func _on_item_selected() -> void:
	recipe_selected.emit(
			get_selected().get_metadata(0))


func add_recipe(recipe_id: StringName, select: bool = false, emit_signal: bool = true) -> void:
	var new_rcp: TreeItem = get_root().create_child()
	new_rcp.set_text(0, String(recipe_id))
	new_rcp.set_metadata(0, recipe_id)
	new_rcp.set_editable(0, true)
	new_rcp.add_button(
			0,
			get_theme_icon("Remove", "EditorIcons"),
			0,
			false,
			"Erase recipe")
	
	if select:
		if emit_signal:
			new_rcp.select(0)
		else:
			item_selected.disconnect(_on_item_selected)
			new_rcp.select(0)
			item_selected.connect(_on_item_selected)


func clear_recipes() -> void:
	for item in get_root().get_children():
		item.free()


func recipes() -> Array[String]:
	var all_recipes: Array[String] = []
	for item in get_root().get_children():
		all_recipes.append(item.get_text(0))
	return all_recipes


func search_text(text: String) -> void:
	if text == current_search:
		return
	for item in get_root().get_children():
		item.visible = text.is_empty() or item.get_text(0).containsn(text)
	current_search = text
	
