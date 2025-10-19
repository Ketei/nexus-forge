extends Tree


signal character_selected(character_sheet: CharacterSheet, unsaved: bool)
signal character_closed(resource: CharacterSheet, unsaved: bool)
signal character_id_changed(from: StringName, to: StringName)


func _ready() -> void:
	create_item()
	
	button_clicked.connect(_on_button_clicked)
	item_edited.connect(_on_item_edited)
	item_selected.connect(_on_item_selected)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		var meta: Dictionary = item.get_metadata(0)
		character_closed.emit(meta["resource"], meta["unsaved"])


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	
	if edited.get_text(0) == edited.get_metadata(0):
		return
	
	var new_string: String = get_valid_id(edited.get_text(0), edited)
	var old_id: StringName = StringName(edited.get_metadata(0))
	var new_id: StringName = StringName(new_string)
	
	edited.set_text(0, new_string)
	edited.set_metadata(0, new_string)
	
	sort_single_item(edited)
	
	character_id_changed.emit(old_id, new_id)


func _on_item_selected() -> void:
	var data: Dictionary = get_selected().get_metadata(0)
	character_selected.emit(
			data["resource"],
			data["unsaved"])


func is_any_unsaved() -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["unsaved"]:
			return true
	return false


func set_all_saved() -> void:
	for item in get_root().get_children():
		item.get_metadata(0)["unsaved"] = false


func clear_characters() -> void:
	for characer in get_root().get_children():
		characer.free()


func create_character(resource: CharacterSheet, select: bool = false, emit_select: bool = true) -> void:
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, resource.resource_path.get_file())
	new_item.set_metadata(0, {"id": resource.id, "resource": resource, "unsaved": false})
	new_item.add_button(
			0,
			get_theme_icon("Close", "EditorIcons"),
			0,
			false,
			"Close")
	
	sort_single_item(new_item)
	
	if select:
		if emit_select:
			new_item.select(0)
		else:
			item_selected.disconnect(_on_item_selected)
			new_item.select(0)
			item_selected.connect(_on_item_selected)


func set_unsaved(character_id: StringName, unsaved: bool) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == character_id:
			item.get_metadata(0)["unsaved"] = unsaved
			return


func get_unsaved() -> Array[CharacterSheet]:
	var unsaved: Array[CharacterSheet] = []
	for item in get_root().get_children():
		if item.get_metadata(0)["unsaved"]:
			unsaved.append(item.get_metadata(0)["resource"])
	return unsaved


func remove_character(character_id: StringName) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"].id == character_id:
			item.free()
			return


func get_valid_id(desired: StringName, skip: TreeItem = null) -> String:
	var modified: String = desired
	var iteration: int = 0
	
	while has_id(modified, skip):
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
