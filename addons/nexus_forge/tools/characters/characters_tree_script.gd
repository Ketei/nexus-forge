extends Tree


const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
var root_tree: TreeItem = null

func _ready() -> void:
	root_tree = create_item()


func add_character(char_name: String, character_path: String) -> void:
	var new_character = create_item(root_tree)
	new_character.set_text(0, char_name)
	new_character.set_editable(0, false)
	new_character.add_button(0, TRASH_BIN, -1, false, "Remove Character")
	new_character.set_metadata(0, {"path": character_path, "data": {}})
