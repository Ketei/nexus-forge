@tool
extends Tree


const FACTION_MAX_RANK: int = 9999
var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "ID")
	set_column_title(1, "Rank")
	
	set_column_expand(0, true)
	set_column_expand(1, true)
	
	set_column_expand_ratio(0, 3)
	set_column_expand_ratio(1, 2)


func add_faction(faction_id: String, max_rank: int) -> void:
	var new_faction: TreeItem = create_item(root_tree)
	
	new_faction.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_faction.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	
	new_faction.set_editable(0, true)
	new_faction.set_editable(1, true)
	
	new_faction.set_range_config(1, 0, max_rank, 1.0)
	
	new_faction.set_text(0, faction_id)
	new_faction.set_range(1, 0)


func reset_factions() -> void:
	for faction in root_tree.get_children():
		if faction.is_checked(0):
			faction.set_checked(0, false)
		faction.set_range(1, 0)


func clear_factions() -> void:
	for faction in root_tree.get_children():
		faction.free()


func set_faction(faction_id: String, checked: bool, rank: int = 0) -> void:
	for faction in root_tree.get_children():
		if faction.get_text(0) == faction_id:
			faction.set_checked(0, checked)
			faction.set_range(1, rank)
			break


func get_factions() -> Dictionary:
	var enabled_factions: Dictionary = {}
	for faction in root_tree.get_children():
		if faction.is_checked(0):
			enabled_factions[faction.get_text(0)] = {"rank": faction.get_range(1)}
	return enabled_factions
