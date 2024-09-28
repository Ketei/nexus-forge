extends Tree


var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()


func add_faction(faction_id: String) -> void:
	var new_faction: TreeItem = create_item(root_tree)
	new_faction.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_faction.set_text(0, faction_id)
	new_faction.set_editable(0, true)


func set_faction_checked(faction_id: String, is_checked: bool) -> void:
	for faction in root_tree.get_children():
		if faction.get_text(0) == faction_id:
			faction.set_checked(0, is_checked)
			break


func clear_checks() -> void:
	for faction in root_tree.get_children():
		faction.set_checked(0, false)


func remove_faction(faction_id: String) -> void:
	for faction in root_tree.get_children():
		if faction.get_text(0) == faction_id:
			faction.free()
			break
