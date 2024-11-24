@tool
extends Tree


const PERK_LVL_LIMIT: int = 9999
var root_tree: TreeItem
var perks_enabled: bool = true : set = set_perks_enabled


func _ready() -> void:
	root_tree = create_item()
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, false)
	
	set_column_custom_minimum_width(1, 48)
	set_column_custom_minimum_width(2, 80)
	
	perks_enabled = false


func set_perks_enabled(is_enabled: bool) -> void:
	perks_enabled = is_enabled
	
	for perk in root_tree.get_children():
		perk.set_editable(0, is_enabled)
		perk.set_editable(1, is_enabled)
		perk.set_editable(2, is_enabled)


func add_perk(perk_id: String) -> void:
	var new_perk: TreeItem = create_item(root_tree)
	
	new_perk.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_perk.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_perk.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_perk.set_text(0, perk_id)
	new_perk.set_text(1, "==,!=,<=,>=,<,>")
	
	new_perk.set_range_config(1, 0, 5, 1.0)
	new_perk.set_range_config(2, 0, PERK_LVL_LIMIT, 1.0)
	
	new_perk.set_editable(0, perks_enabled)
	new_perk.set_editable(1, perks_enabled)
	new_perk.set_editable(2, perks_enabled)
	new_perk.set_metadata(0, {"force_hide": false})


func rename_perk(from: String, to: String) -> void:
	for perk in root_tree.get_children():
		if perk.get_text(0) == from:
			perk.set_text(0, to)
			break


func set_perk_hidden(perk_id: String) -> void:
	for perk in root_tree.get_children():
		if perk.get_text(0) == perk_id:
			perk.get_metadata(0)["force_hide"] = true
			perk.visible = false


func search_perk(perk_name: String) -> void:
	for perk in root_tree.get_children():
		perk.visible = not perk.get_metadata(0)["force_hide"] and (perk_name.is_empty() or Strings.nocasecmp_equal(perk_name, perk.get_text(0)))


func get_selected_perks() -> Dictionary:
	var selected: Dictionary = {}
	
	for perk in root_tree.get_children():
		if perk.is_checked(0):
			selected[perk.get_text(0)] = {
				"level": perk.get_range(2),
				"operator": range_to_operator(perk.get_range(1))}
	
	return selected


func range_to_operator(range: int) -> int:
	match range:
		0:
			return OP_EQUAL
		1:
			return OP_NOT_EQUAL
		2:
			return OP_LESS_EQUAL
		3:
			return OP_GREATER_EQUAL
		4:
			return OP_LESS
		5:
			return OP_GREATER
		_:
			return OP_EQUAL


func operator_to_range(operator: int) -> int:
	match range:
		OP_EQUAL:
			return 0
		OP_NOT_EQUAL:
			return 1
		OP_LESS_EQUAL:
			return 2
		OP_GREATER_EQUAL:
			return 3
		OP_LESS:
			return 4
		OP_GREATER:
			return 5
		_:
			return 0


func set_perk(perk_id: String, perk_level: int, perk_operator: int) -> void:
	for perk in root_tree.get_children():
		if perk.get_text(0) == perk_id:
			perk.set_checked(0, true)
			perk.set_range(1, operator_to_range(perk_operator))
			perk.set_range(2, perk_level)


func clear_checks() -> void:
	for perk in root_tree.get_children():
		if perk.is_checked(0):
			perk.set_checked(0, false)


func reset_perks() -> void:
	for perk in root_tree.get_children():
		if perk.is_checked(0):
			perk.set_checked(0, false)
		if perk.get_metadata(0)["force_hide"]:
			perk.get_metadata(0)["force_hide"] = false
		perk.set_range(1, 0)
		perk.set_range(2, 0)
		perk.visible = true


func clear_perks() -> void:
	for perk in root_tree.get_children():
		perk.free()


func remove_perk(perk_id: String) -> void:
	for perk in root_tree.get_children():
		if perk.get_text(0) == perk_id:
			perk.free()
