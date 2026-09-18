@tool
extends Tree


signal character_selected(res_id: int)
signal character_closed(res_id: int)

var root: TreeItem = null


func ready_plugin() -> void:
	root = create_item()
	
	button_clicked.connect(_on_button_clicked)
	item_mouse_selected.connect(_on_item_mouse_selected)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		var meta: Dictionary = item.get_metadata(0)
		character_closed.emit(meta["id"])


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var data: Dictionary = get_selected().get_metadata(0)
	character_selected.emit(data["id"])


func set_all_saved() -> void:
	for item in root.get_children():
		if item.get_metadata(0)["unsaved"]:
			item.set_text(0, item.get_text(0).trim_suffix("*"))
		item.get_metadata(0)["unsaved"] = false


func clear_characters() -> void:
	for characer in root.get_children():
		characer.free()


func select_character(resource_id: int, emit_selected: bool = true) -> void:
	for item in root.get_children():
		if item.get_metadata(0)["id"] == resource_id:
			item.select(0)
			if emit_selected:
				character_selected.emit(resource_id)


func create_character(resource: NFCharacterSheet, select: bool = false, emit_select: bool = true) -> void:
	var new_item: TreeItem = root.create_child()
	new_item.set_text(0, resource.resource_path.get_file().get_basename())
	new_item.set_tooltip_text(0, resource.resource_path)
	new_item.set_metadata(0, {"id": resource.get_instance_id(), "unsaved": false})
	new_item.add_button(
			0,
			get_theme_icon("Close", "EditorIcons"),
			0,
			false,
			"Close")
	
	sort_single_item(new_item)
	
	if select:
		new_item.select(0)
		if emit_select:
			character_selected.emit(resource.get_instance_id())


func set_unsaved(res_id: int, unsaved: bool) -> void:
	for item in root.get_children():
		if item.get_metadata(0)["id"] == res_id:
			if unsaved:
				if not item.get_metadata(0)["unsaved"]:
					item.set_text(0, item.get_text(0) + "*")
			else:
				if item.get_metadata(0)["unsaved"]:
					item.set_text(0, item.get_text(0).trim_suffix("*"))
			item.get_metadata(0)["unsaved"] = unsaved
			return


func remove_character(char_id: int) -> void:
	for item in root.get_children():
		if item.get_metadata(0)["id"] == char_id:
			item.free()
			return


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	
	for child in root.get_children():
		if child == item:
			continue # We ignore the item we just added
		
		if item.get_text(0).naturalnocasecmp_to(child.get_text(0)) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != root.get_child_count() - 1:
			item.move_after(root.get_child(-1))
