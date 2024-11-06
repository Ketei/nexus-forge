@tool
extends Tree


const FACTION_MAX_RANK: int = 9999
var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "ID")
	set_column_title(1, "Name")
	set_column_title(2, "Rank")
	
	set_column_expand(0, true)
	set_column_expand(1, true)
	set_column_expand(2, true)
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 3)
	set_column_expand_ratio(2, 3)


func add_faction(faction_id: String, faction_name: String) -> void:
	var new_faction: TreeItem = create_item(root_tree)
	
	new_faction.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_faction.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	new_faction.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_faction.set_editable(0, true)
	new_faction.set_editable(1, false)
	new_faction.set_editable(2, true)
	
	new_faction.set_range_config(2, 0, FACTION_MAX_RANK, 1.0)
	
	new_faction.set_text(0, faction_id)
	new_faction.set_text(1, faction_name)


func clear_checks() -> void:
	for faction in root_tree.get_children():
		if faction.is_checked(0):
			faction.set_checked(0, false)


func clear_factions() -> void:
	for faction in root_tree.get_children():
		faction.free()


func set_faction(faction_id: String, checked: bool, rank: int = 0) -> void:
	for faction in root_tree.get_children():
		if faction.get_text(0) == faction_id:
			faction.set_checked(0, checked)
			faction.set_range(2, rank)
			break


func get_factions() -> Dictionary:
	var enabled_factions: Dictionary = {}
	for faction in root_tree.get_children():
		if faction.is_checked(0):
			enabled_factions[faction.get_text(0)] = {"rank": faction.get_range(2)}
	return enabled_factions
