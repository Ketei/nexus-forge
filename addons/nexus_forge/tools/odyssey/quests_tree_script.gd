@tool
extends IDTree


signal quest_deleted(quest_id: String)
signal quest_selected(quest_id: String)
signal quest_created(quest_id: String)
signal quest_renamed(from: String, to: String)

const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
var root_tree: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	item_edited.connect(on_item_edited)
	button_clicked.connect(on_button_pressed)
	item_selected.connect(on_item_selected)


func on_item_selected() -> void:
	var selected: TreeItem = get_selected()
	
	if selected != null:
		quest_selected.emit(selected.get_text(0))


func add_item(quest_id: String) -> void:
	var new_quest: TreeItem = create_item(root_tree)
	new_quest.set_text(0, validate_id(root_tree, quest_id, new_quest))
	new_quest.add_button(0, TRASH_BIN, 0, false, "Delete quest")
	new_quest.set_metadata(0, new_quest.get_text(0))
	new_quest.set_editable(0, true)
	quest_created.emit(new_quest.get_text(0))


func clear_items() -> void:
	for child in root_tree.get_children():
		child.free()


func on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	
	edited.set_text(0, validate_id(root_tree, edited.get_text(0), edited))
	quest_renamed.emit(edited.get_metadata(0), edited.get_text(0))
	edited.set_metadata(0, edited.get_text(0))


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if id == 0:
		quest_deleted.emit(item.get_text(0))
		item.free()


func search_item(search: String) -> void:
	for quest in root_tree.get_children():
		quest.visible = search.is_empty() or quest.get_text(0).containsn(search)


func get_quests() -> Array:
	var quests: Array = []
	for quest in root_tree.get_children():
		quests.append(quest.get_text(0))
	return quests
