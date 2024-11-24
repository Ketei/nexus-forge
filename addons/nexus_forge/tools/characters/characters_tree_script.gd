@tool
extends IDTree


signal close_requested(character_id: String)
signal character_selected(character_id: String)

const CLOSE_ICON = preload("res://addons/nexus_forge/common_icons/close_icon.svg")

var root_tree: TreeItem = null

func _ready() -> void:
	root_tree = create_item()
	item_selected.connect(on_item_selected)


func add_character(character_id: String) -> String:
	#var character_res: CharacterDefinition = load(character_path)
	var new_character = create_item(root_tree)
	#var character_id: String = validate_id(root_tree, character_res.character_id, new_character)
	new_character.set_text(0, character_id)
	new_character.set_editable(0, false)
	new_character.add_button(0, CLOSE_ICON, 0, false, "Close Character")
	#new_character.set_metadata(0, {"path": character_path, "data": character_res})
	return character_id


func on_item_selected() -> void:
	character_selected.emit(get_selected().get_text(0))


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	close_requested.emit(item.get_text(0))


func get_serialized_data(character_id: String) -> Dictionary:
	for character in root_tree.get_children():
		if character.get_text(0) == character_id:
			return character.get_metadata(0)
	return {"path": "", "data": null}


func get_character_data(character_id: String) -> CharacterDefinition:
	for character in root_tree.get_children():
		if character.get_text(0) == character_id:
			return character.get_metadata(0)["data"]
	return null


func set_character_data(character_id: String, character_data: CharacterDefinition) -> void:
	for character in root_tree.get_children():
		if character.get_text(0) == character_id:
			character.get_metadata(0)["data"] = character_data


func ensure_selected(character_id: String) -> void:
	for character in root_tree.get_children():
		if character.get_text(0) == character_id:
			if not character.is_selected(0):
				character.select(0)
				break
