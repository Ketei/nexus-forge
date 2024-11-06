@tool
extends Tree


const PERK_LVL_LIMIT: int = 9999
var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()


func add_perk(perk_id: String) -> void:
	var new_perk: TreeItem = create_item(root_tree)
	
	new_perk.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_perk.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_perk.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_perk.set_text(0, perk_id)
	new_perk.set_text(1, "==,!=,<=,>=,<,>")
	
	new_perk.set_range_config(1, 0, 5, 1.0)
	new_perk.set_range_config(2, 0, PERK_LVL_LIMIT, 1.0)
	
	new_perk.set_editable(0, true)
	new_perk.set_editable(1, true)
	new_perk.set_editable(2, true)


func get_selected_perks() -> Dictionary:
	var selected: Dictionary = {}
	
	for perk in root_tree.get_children():
		if perk.is_checked(0):
			selected[perk.get_text(0)] = {
				"level": perk.get_range(2),
				"operator": perk.get_range(1)}
	
	return selected


func set_perk(perk_id: String, perk_level: int, perk_operator: float) -> void:
	for perk in root_tree.get_children():
		if perk.get_text(0) == perk_id:
			perk.set_checked(0, true)
			perk.set_range(1, perk_operator)
			perk.set_range(2, perk_level)


func clear_checks() -> void:
	for perk in root_tree.get_children():
		if perk.is_checked(0):
			perk.set_checked(0, false)


func remove_perk(perk_id: String) -> void:
	for perk in root_tree.get_children():
		if perk.get_text(0) == perk_id:
			perk.free()
