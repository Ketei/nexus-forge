@tool
extends Tree
#perk_id: String, perk_level: int, stat_id: String, value: int, operator: int


enum StatOperators {
	EQUAL,
	NOT_EQUAL,
	LESS_THAN,
	MORE_THAN,
}

const MAX_STAT: int = 9999

var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()


func validate_name(desired_id: String, omit_tree: TreeItem = null) -> String:
	var ideal_id: String = "new_stat" if desired_id.is_empty() else desired_id.strip_edges()
	var tweaked_id: String = ideal_id
	var iteration: int = 1
	
	while has_id(tweaked_id, omit_tree):
		tweaked_id = str(ideal_id, "_", iteration)
		iteration += 1
	
	return tweaked_id


func has_id(id: String, omit_tree: TreeItem) -> bool:
	for stat in root_tree.get_children():
		if stat == omit_tree:
			continue
		if stat.get_metadata(0) == id:
			return true
	return false


func add_requirement(stat_id: String, stat_value: int, stat_op: float) -> void:
	var new_stat: TreeItem = create_item(root_tree)
	
	new_stat.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_stat.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_stat.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_stat.set_range_config(1, 0, 5, 1.0)
	new_stat.set_text(1, "==,!=,<=,>=,<,>")
	new_stat.set_range_config(2, -MAX_STAT, MAX_STAT, 1.0)
	
	new_stat.set_text(0, stat_id)
	new_stat.set_metadata(0, stat_id)
	new_stat.set_range(1, stat_op)
	new_stat.set_range(2, stat_value)
	
	new_stat.set_editable(0, true)
	new_stat.set_editable(1, true)
	new_stat.set_editable(2, true)


func on_stat_edited() -> void:
	var edited_stat: TreeItem = get_edited()
	
	if edited_stat.get_metadata(0) != edited_stat.get_text(0):
		var new_name: String = validate_name(edited_stat.get_text(0))
		if edited_stat.get_text(0) != new_name:
			edited_stat.set_text(0, new_name)
		edited_stat.set_metadata(0, new_name)


func get_current_stat_data() -> Dictionary:
	var return_dict: Dictionary = {}
	for stat in root_tree.get_children():
		return_dict[stat.get_text(0)] = {
			"value": stat.get_range(2),
			"operator": stat.get_range(1)}
	return return_dict


func clear_stats() -> void:
	for stat in root_tree.get_children():
		stat.free()
