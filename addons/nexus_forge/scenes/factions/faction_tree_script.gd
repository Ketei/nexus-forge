@tool
extends IDTree


var active_faction: TreeItem
var tree_enabled: bool = true:
	set(is_enabled):
		tree_enabled = is_enabled
		set_tree_enabled(is_enabled)


func _ready() -> void:
	create_item()
	
	set_column_title(0, "Faction")
	set_column_title(1, "Relationship")
	
	set_column_expand(0, true)
	set_column_expand(1, true)
	
	set_column_expand_ratio(0, 3)
	set_column_expand_ratio(1, 2)
	
	tree_enabled = false


func set_tree_enabled(enabled: bool) -> void:
	for faction in get_root().get_children():
		faction.set_editable(1, enabled)


func add_faction(faction_id: String, faction_relation: int = 0) -> void:
	var new_faction: TreeItem = get_root().create_child()
	new_faction.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_faction.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	
	new_faction.set_text(0, faction_id)
	new_faction.set_text(1, "Enemy,Neutral,Ally")
	new_faction.set_range(1, clampi(faction_relation + 1, 0, 2))
	
	new_faction.set_editable(1, tree_enabled)


func set_active_faction(faction_id: String) -> void:
	if faction_id.is_empty():
		if active_faction != null:
			active_faction.visible = true
			active_faction = null
		return
	
	if active_faction != null:
		active_faction.visible = true
	
	for faction in get_root().get_children():
		if faction.get_text(0) == faction_id:
			faction.set_range(1, 2)
			faction.visible = false
			active_faction = faction
			break


func search_faction(search: String) -> void:
	for faction in get_root().get_children():
		if faction == active_faction:
			continue
		faction.visible = search.is_empty() or faction.get_text(0).containsn(search)


func set_faction_relationship(faction_id: String, relationship: int) -> void:
	for faction in get_root().get_children():
		if faction.get_text(0) == faction_id:
			faction.set_range(0, relationship + 1)
			break


func reset_relationships() -> void:
	for faction in get_root().get_children():
		faction.set_range(1, 1)


func remove_faction(faction_id: String) -> void:
	for faction in get_root().get_children():
		if faction.get_text(0) == faction_id:
			if faction == active_faction:
				active_faction = null
			faction.free()
			break


# Neutral relationships will be ommited
func get_faction_relations() -> Dictionary:
	var relations: Dictionary = {}
	
	for faction in get_root().get_children():
		if faction.get_range(1) != 1:
			relations[faction.get_text(0)] = faction.get_range(1) - 1
	
	return relations
