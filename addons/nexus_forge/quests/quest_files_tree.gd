@tool
extends Tree


signal quest_selected(quest: Quest)
signal quest_close_pressed(quest: Quest, requires_save: bool)


var _active: TreeItem = null


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	create_item()
	
	item_selected.connect(_on_item_selected, CONNECT_DEFERRED)
	button_clicked.connect(_on_button_clicked)


func add_quest(quest: Quest, select: bool = false, emit_select: bool = true) -> void:
	var quest_item: TreeItem = get_root().create_child()
	
	quest_item.set_text(0, quest.resource_path.get_file().get_basename())
	quest_item.set_tooltip_text(0, quest.resource_path)
	quest_item.set_metadata(0, {"resource": quest, "save_required": false})
	
	quest_item.add_button(
			0,
			get_theme_icon("Close", "EditorIcons"),
			0,
			false,
			"Close quest")
	
	if select:
		_active = quest_item
		if emit_select:
			quest_item.select(0)
		else:
			item_selected.disconnect(_on_item_selected)
			quest_item.select(0)
			item_selected.connect(_on_item_selected, CONNECT_DEFERRED)


func set_current_save_required(set_required: bool) -> void:
	if _active == null or _active.get_metadata(0)["save_required"] == set_required:
		return
	
	if set_required:
		_active.set_text(0, _active.get_text(0) + "*")
	else:
		_active.set_text(0, _active.get_text(0).trim_suffix("*"))
	
	_active.get_metadata(0)["save_required"] = set_required


func set_save_required(on_quest: Quest, required: bool) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == on_quest:
			if item.get_metadata(0)["save_required"] == required:
				return
			if required:
				item.set_text(0, item.get_text(0) + "*")
			else:
				item.set_text(0, item.get_text(0).trim_suffix("*"))
			
			item.get_metadata(0)["save_required"] = required
			return


func set_all_saved() -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["save_required"]:
			item.set_text(0, item.get_text(0).trim_suffix("*"))
			item.get_metadata(0)["save_required"] = false


func has_quest(quest: Quest) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == quest:
			return true
	return false


func close_quest(quest: Quest) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == quest:
			if _active == item:
				_active = null
			item.free()
			return


func close_with_path(path: String) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"].resource_path == path:
			if _active == item:
				_active = null
			item.free()
			return


func select_quest(quest: Quest, emit_select: bool = true) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == quest:
			_active = item
			if emit_select:
				item.select(0)
			else:
				item_selected.disconnect(_on_item_selected)
				item.select(0)
				item_selected.connect(_on_item_selected, CONNECT_DEFERRED)
			return


func get_open_quest_paths() -> Array[String]:
	var paths: Array[String] = []
	
	for item in get_root().get_children():
		var path: String = item.get_metadata(0)["resource"].resource_path
		if path.is_empty():
			continue
		paths.append(path)
	
	return paths


func has_unsaved_files() -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["save_required"]:
			return true
	return false


func get_unsaved_files() -> Array[Quest]:
	var files: Array[Quest] = []
	for item in get_root().get_children():
		if item.get_metadata(0)["save_required"]:
			files.append(item.get_metadata(0)["resource"])
	return files


func search_for(text: String) -> void:
	var empty: bool = text.is_empty()
	for item in get_root().get_children():
		item.visible = empty or item.get_metadata(0)["resource"].resource_path.containsn(text)


func _on_item_selected() -> void:
	_active = get_selected()
	quest_selected.emit(_active.get_metadata(0)["resource"])


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		quest_close_pressed.emit(item.get_metadata(0)["resource"], item.get_metadata(0)["save_required"])
