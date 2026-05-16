@tool
extends Tree


signal map_close_pressed(map: PhraseMap, save_required: bool)
signal map_resource_selected(map: PhraseMap)


func ready_plugin() -> void:
	create_item()
	button_clicked.connect(_on_button_clicked)
	item_selected.connect(_on_resource_selected)


func _on_resource_selected() -> void:
	map_resource_selected.emit(
			get_selected().get_metadata(0)["resource"])


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		var meta: Dictionary = item.get_metadata(0)
		map_close_pressed.emit(
			meta["resource"],
			meta["save_required"])


func get_open_files() -> Array[String]:
	var paths: Array[String] = []
	
	if get_root() == null:
		return paths
	
	for item in get_root().get_children():
		paths.append(item.get_metadata(0)["resource"].resource_path)
	return paths


func add_map(resource: PhraseMap, select: bool = false, emit_select: bool = true) -> void:
	var new_map: TreeItem = get_root().create_child()
	new_map.set_text(0, resource.resource_path.get_file().get_basename())
	new_map.set_tooltip_text(0, resource.resource_path)
	new_map.set_metadata(0, {"resource": resource, "save_required": false})
	new_map.add_button(0, get_theme_icon("GuiClose", "EditorIcons"), 0, false, "Close file")
	
	if select:
		if emit_select:
			new_map.select(0)
		else:
			item_selected.disconnect(_on_resource_selected)
			new_map.select(0)
			item_selected.connect(_on_resource_selected)


func has_map(map: PhraseMap) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == map:
			return true
	return false


func remove_map(resource: PhraseMap) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == resource:
			item.free()
			return


func select_map(resource: PhraseMap, emit_select: bool = true) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == resource:
			if emit_select:
				item.select(0)
			else:
				item_selected.disconnect(_on_resource_selected)
				item.select(0)
				item_selected.connect(_on_resource_selected)
			return


func requires_save(resource: PhraseMap) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == resource:
			return item.get_metadata(0)["save_required"]
	return false


func set_save_required(resource: PhraseMap, save_required: bool) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == resource:
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


func get_unsaved_resources() -> Array[PhraseMap]:
	var unsaved_resources: Array[PhraseMap] = []
	for item in get_root().get_children():
		if item.get_metadata(0)["save_required"]:
			unsaved_resources.append(item.get_metadata(0)["resource"])
	return unsaved_resources


func has_unsaved() -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["save_required"]:
			return true
	return false
