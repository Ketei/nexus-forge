@tool
extends Tree


signal quest_selected(quest_id: int)
signal quest_close_pressed(quest_id: int, requires_save: bool, structure: Array[Dictionary])


func ready_plugin() -> void:
	create_item()
	
	item_mouse_selected.connect(_on_item_mouse_selected)
	button_clicked.connect(_on_button_clicked)


func add_quest(quest_id: int, resource_path: String, select: bool = false, emit_select: bool = true) -> void:
	var quest_item: TreeItem = get_root().create_child()
	
	quest_item.set_text(0, resource_path.get_file().get_basename())
	quest_item.set_tooltip_text(0, resource_path)
	quest_item.set_metadata(0, {"id": quest_id, "path": resource_path, "save_required": false, "structure": ArrayUtils.create_typed(TYPE_DICTIONARY)})
	
	quest_item.add_button(
			0,
			get_theme_icon("Close", "EditorIcons"),
			0,
			false,
			"Close quest")
	
	if select:
		quest_item.select(0)
		if emit_select:
			quest_selected.emit(quest_id)


func set_current_save_required(set_required: bool) -> void:
	var active_file: TreeItem = get_selected()
	if active_file == null or active_file.get_metadata(0)["save_required"] == set_required:
		return
	
	if set_required:
		active_file.set_text(0, active_file.get_text(0) + "*")
	else:
		active_file.set_text(0, active_file.get_text(0).trim_suffix("*"))
	
	active_file.get_metadata(0)["save_required"] = set_required


func update_quest_id(old_id: int, new_id: int) -> void:
	for item in get_root().get_children():
			if item.get_metadata(0)["id"] == old_id:
				item.get_metadata(0)["id"] = new_id
				return


func set_save_required(on_quest: int, required: bool) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == on_quest:
			if item.get_metadata(0)["save_required"] == required:
				return
			if required:
				item.set_text(0, item.get_text(0) + "*")
			else:
				item.set_text(0, item.get_text(0).trim_suffix("*"))
			
			item.get_metadata(0)["save_required"] = required
			return


func update_path_on(on_quest: int, new_path: String) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == on_quest:
			item.set_tooltip_text(0, new_path)
			item.get_metadata(0)["path"] = new_path


func set_all_saved() -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["save_required"]:
			item.set_text(0, item.get_text(0).trim_suffix("*"))
			item.get_metadata(0)["save_required"] = false


func has_quest_id(quest_id: int) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == quest_id:
			return true
	return false


func has_quest_file(quest_path: String) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["path"] == quest_path:
			return true
	return false


func remove_quest(quest_id: int) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == quest_id:
			item.free()
			return


func close_with_path(path: String) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["path"] == path:
			item.free()
			return


func select_quest(quest_id: int, emit_select: bool = true) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == quest_id:
			item.select(0)
			if emit_select:
				quest_selected.emit(quest_id)
			return


func has_unsaved_files() -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["save_required"]:
			return true
	return false


func get_unsaved_files() -> Array[Dictionary]:
	var files: Array[Dictionary] = []
	for item in get_root().get_children():
		if item.get_metadata(0)["save_required"]:
			var metadata: Dictionary = item.get_metadata(0)
			files.append({"id": metadata["id"], "structure": metadata["structure"]})
	return files


func search_for(text: String) -> void:
	var empty: bool = text.is_empty()
	for item in get_root().get_children():
		item.visible = empty or item.get_metadata(0)["path"].containsn(text)


func set_quest_structure(quest_id: int, structure: Array[Dictionary]) -> void:
	for item in get_root().get_children():
		var metadata: Dictionary = item.get_metadata(0)
		if metadata["id"] == quest_id:
			metadata["structure"].assign(structure)
			return


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	var selected: TreeItem = get_selected()
	
	quest_selected.emit(selected.get_metadata(0)["id"], selected.get_metadata(0)["structure"])


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		quest_close_pressed.emit(item.get_metadata(0)["id"], item.get_metadata(0)["save_required"], item.get_metadata(0)["structure"])
