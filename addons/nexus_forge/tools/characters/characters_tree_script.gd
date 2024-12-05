@tool
extends IDTree


signal character_removed(character_id: String)
signal character_selected(character_id: String)
signal character_id_changed(from: String, to: String)

const CHAR_REMOVE_CONFIRM = preload("res://addons/nexus_forge/tools/characters/char_remove_confirm.tscn")
const CLOSE_ICON = preload("res://addons/nexus_forge/common_icons/close_icon.svg")

var root_tree: TreeItem = null

func _ready() -> void:
	root_tree = create_item()
	item_selected.connect(on_item_selected)
	item_edited.connect(on_item_edited)


func add_character(character_id: String) -> void:
	var new_character = create_item(root_tree)
	new_character.set_text(0, character_id)
	new_character.set_metadata(0, character_id)
	new_character.set_editable(0, true)
	new_character.add_button(0, CLOSE_ICON, 0, false, "Remove Character")


func clear_characters() -> void:
	for character in root_tree.get_children():
		character.free()


func get_valid_character_id(desired_id: String) -> String:
	return validate_id(root_tree, desired_id, null)


func on_item_edited() -> void:
	var edited := get_edited()
	match get_edited_column():
		0:
			edited.set_text(0, validate_id(root_tree, edited.get_text(0), edited))
			character_id_changed.emit(edited.get_metadata(0), edited.get_text(0))
			edited.set_metadata(0, edited.get_text(0))


func on_item_selected() -> void:
	character_selected.emit(get_selected().get_text(0))


func on_button_pressed(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	match id:
		0:
			var confirm_remove := CHAR_REMOVE_CONFIRM.instantiate()
			confirm_remove.character_id = item.get_text(0)
			add_child(confirm_remove)
			confirm_remove.show()
			if await confirm_remove.dialog_finished:
				character_removed.emit(item.get_text(0))
				item.free()
			confirm_remove.queue_free()


func get_serialized_data(character_id: String) -> Dictionary:
	for character in root_tree.get_children():
		if character.get_text(0) == character_id:
			return character.get_metadata(0)
	return {"path": "", "data": null}


func ensure_selected(character_id: String) -> void:
	for character in root_tree.get_children():
		if character.get_text(0) == character_id:
			if not character.is_selected(0):
				character.select(0)
				break
