extends Tree


signal quest_erased(quest_id: StringName)
signal quest_id_changed(from: StringName, to: StringName)


var current_search: String = ""


func _ready() -> void:
	create_item()
	item_edited.connect(_on_item_edited)
	button_clicked.connect(_on_button_clicked)


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	
	if edited.get_text(0) == String(edited.get_metadata(0)):
		return
	
	var new_valid_name: String = get_valid_id(edited.get_text(0), edited)
	var old_id: StringName = edited.get_metadata(0)
	var new_id: StringName = StringName(new_valid_name)
	
	edited.set_metadata(0, new_id)
	quest_id_changed.emit(old_id, new_id)


func add_quest(quest_id: StringName, select: bool = false) -> void:
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, String(quest_id))
	new_item.set_metadata(0, quest_id)
	new_item.add_button(
			0,
			get_theme_icon("Remove", "EditorIcons"),
			0,
			false,
			"Erase quest")
	new_item.set_editable(0, true)
	sort_single_item(new_item)
	
	if select:
		new_item.select(0)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		quest_erased.emit(item.get_metadata(0))
		item.free()


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


func search_item(text: String) -> void:
	if text == current_search:
		return
	for item in get_root().get_children():
		item.visible = text.is_empty() or item.get_text(0).containsn(text)
	current_search = text
