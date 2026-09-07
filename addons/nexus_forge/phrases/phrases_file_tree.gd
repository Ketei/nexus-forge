@tool
extends Tree


signal map_close_pressed(map: int, save_required: bool)
signal map_resource_selected(map: int)


func ready_plugin() -> void:
	create_item()
	button_clicked.connect(_on_button_clicked)
	item_mouse_selected.connect(_on_resource_selected)


func _on_resource_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	map_resource_selected.emit(
			get_selected().get_metadata(0)["id"])


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		var meta: Dictionary = item.get_metadata(0)
		map_close_pressed.emit(
			meta["id"],
			meta["save_required"])


func add_map(resource: PhraseMap, select: bool = false, emit_select: bool = true) -> void:
	var new_map: TreeItem = get_root().create_child()
	new_map.set_text(0, resource.resource_path.get_file().get_basename())
	new_map.set_tooltip_text(0, resource.resource_path)
	new_map.set_metadata(0, {"id": resource.get_instance_id(), "save_required": false})
	new_map.add_button(0, get_theme_icon("GuiClose", "EditorIcons"), 0, false, "Close file")
	
	if select:
		new_map.select(0)
		if emit_select:
			map_resource_selected.emit(resource.get_instance_id())


func has_map(map: int) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == map:
			return true
	return false


func remove_map(resource: int) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == resource:
			item.free()
			return


func select_map(id: int, emit_select: bool = true) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == id:
			item.select(0)
			if emit_select:
				map_resource_selected.emit(id)
			return


func set_save_required(resource: int, save_required: bool) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == resource:
			if save_required != item.get_metadata(0)["save_required"]:
				if save_required:
					item.set_text(0, item.get_text(0) + "*")
				else:
					item.set_text(0, item.get_text(0).trim_suffix("*"))
				item.get_metadata(0)["save_required"] = save_required
			return


func set_save_required_all(save_required: bool) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["save_required"] == save_required:
			continue
		if save_required:
			item.set_text(0, item.get_text(0) + "*")
		else:
			item.set_text(0, item.get_text(0).trim_suffix("*"))
		item.get_metadata(0)["save_required"] = save_required
