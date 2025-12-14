@tool
extends Tree


signal quest_id_changed(from: String, to: String)
signal quest_erased(id: String)
signal quest_selected(id: String)
signal quest_updated

@export var quest_tree_id: String = ""
@export var tree_item_name: String = ""

func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	create_item()
	
	button_clicked.connect(_on_button_clicked)
	item_edited.connect(_on_item_edited)
	item_selected.connect(_on_item_selected)


func _get_drag_data(at_position: Vector2) -> Variant:
	var node: TreeItem = get_item_at_position(at_position)
	if node == null:
		return null
	
	var data: Dictionary = {
		"source": quest_tree_id,
		"node": node}
	var preview: Label = Label.new()
	preview.text = "   " + node.get_text(0)
	set_drag_preview(preview)
	return data


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has_all(["source", "node"]) or typeof(data["source"]) != TYPE_STRING or data["source"] != quest_tree_id or typeof(data["node"]) != TYPE_OBJECT:
		return false
	
	drop_mode_flags = DROP_MODE_INBETWEEN
	
	var item: TreeItem = get_item_at_position(at_position)
	var section: int = get_drop_section_at_position(at_position)
	
	if item == null or data["node"] is not TreeItem or item == data["node"] or section == -100:
		return false
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var drop_position: int = get_drop_section_at_position(at_position)
	
	if drop_position == -1:
		data["node"].move_before(get_item_at_position(at_position))
	elif drop_position == 1:
		data["node"].move_after(get_item_at_position(at_position))
	quest_updated.emit()


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	
	if edited.get_text(0) == edited.get_metadata(0):
		return
	
	var new_id: String = get_unique_id(edited.get_text(0), edited)
	quest_id_changed.emit(edited.get_metadata(0), new_id)
	edited.set_text(0, new_id)
	edited.set_metadata(0, new_id)


func _on_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	if id != 0:
		return
	quest_erased.emit(item.get_text(0))
	item.free()


func _on_item_selected() -> void:
	var selected: TreeItem = get_selected()
	
	if selected == null:
		return
	
	quest_selected.emit(selected.get_text(0))


func create_quest(id: String, select: bool = false) -> void:
	var new_id: String = get_unique_id(id)
	
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, new_id)
	new_item.set_metadata(0, new_id)
	
	new_item.set_editable(0, true)
	
	new_item.add_button(
			0,
			get_theme_icon("Remove", "EditorIcons"),
			0,
			false,
			"Erase " + tree_item_name)
	
	if select:
		new_item.select(0)


func get_unique_id(desired: String, ignore: TreeItem = null) -> String:
	var modified: String = desired
	var iteration: int = -1
	
	while has_id(modified, ignore):
		iteration += 1
		modified = desired + str(iteration)
	
	return modified


func has_id(id: String, ignore: TreeItem = null) -> bool:
	for child in get_root().get_children():
		if child == ignore:
			continue
		if child.get_text(0) == id:
			return true
	return false


func clear_quests() -> void:
	clear()
	create_item()


func get_quests() -> Array[StringName]:
	var quests: Array[StringName] = []
	for child in get_root().get_children():
		quests.append(child.get_metadata(0))
	return quests


func search_quest(text: String) -> void:
	for item in get_root().get_children():
		item.visible = text.is_empty() or item.get_text(0).containsn(text)
