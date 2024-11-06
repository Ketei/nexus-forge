@tool
extends IDTree


signal faction_selected(faction_id: String)


var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	item_edited.connect(on_faction_edited)


func add_faction(faction_id: String) -> void:
	var new_faction: TreeItem = create_item(root_tree)
	new_faction.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_faction.set_text(0, faction_id)
	new_faction.set_editable(0, true)


func set_current_faction(active_faction: String) -> void:
	for faction in root_tree.get_children():
		var is_match: bool = faction.get_text(0) == active_faction
		if is_match:
			faction.set_checked(0, false)
		faction.set_editable(0, not is_match)


func search_faction(search: String) -> void:
	for faction in root_tree.get_children():
		faction.visible = search.is_empty() or faction.get_text(0).containsn(search)


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


func get_enabled_factions() -> Array:
	var allied_factions: Array = []
	for faction in root_tree.get_children():
		if faction.is_checked(0):
			allied_factions.append(faction.get_text(0))
	return allied_factions


func on_faction_edited() -> void:
	var edited: TreeItem = get_edited()
	if edited.is_checked(0):
		faction_selected.emit(edited.get_text(0))
