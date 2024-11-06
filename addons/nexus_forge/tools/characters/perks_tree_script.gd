@tool
extends Tree


const PERK_MAX_LEVEL: int = 9999
var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "ID")
	set_column_title(1, "Level")


func add_perk(perk_id: String, perk_level: int) -> void:
	var new_perk: TreeItem = create_item(root_tree)
	
	new_perk.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_perk.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	
	new_perk.set_editable(0, true)
	new_perk.set_editable(1, true)
	
	new_perk.set_text(0, perk_id)
	new_perk.set_range_config(1, 0, perk_level, 1.0)


func set_perk(perk_id: String, perk_checked: bool, perk_level: int) -> void:
	for perk in root_tree.get_children():
		if perk.get_text(0) == perk_id:
			perk.set_checked(0, perk_checked)
			perk.set_range(1, clampi(perk_level, 0, PERK_MAX_LEVEL))
			break


func get_selected_perks() -> Dictionary:
	var perks: Dictionary = {}
	
	for perk in root_tree.get_children():
		if perk.is_checked(0):
			perks[perk.get_text(0)] = {"level": perk.get_range(1)}
	return perks


func clear_checks() -> void:
	for perk in root_tree.get_children():
		if perk.is_checked(0):
			perk.set_checked(0, false)


func clear_perks() -> void:
	for perk in root_tree.get_children():
		perk.free()
	
