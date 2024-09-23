extends Tree

const RANGE_MIN: int = 0
const RANGE_MAX: int = 9999
const RANGE_FLOAT_STEP: float = 0.01

var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "Stat")
	set_column_title(1, "Min")
	set_column_title(2, "Max")
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, false)
	
	set_column_custom_minimum_width(1, 75)
	set_column_custom_minimum_width(2, 75)


func create_stat(stat_name: String, is_int: bool) -> TreeItem:
	var new_stat: TreeItem = create_item(root_tree)
	var step: float = 1.0 if is_int else RANGE_FLOAT_STEP
	new_stat.set_text(0, stat_name)
	new_stat.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_stat.set_range_config(1, RANGE_MIN, RANGE_MAX, step)
	new_stat.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	new_stat.set_range_config(2, RANGE_MIN, RANGE_MAX, step)
	
	new_stat.set_range(1, 0)
	new_stat.set_range(2, 1)
	
	new_stat.set_editable(1, true)
	new_stat.set_editable(2, true)
	
	return new_stat


func clear_stats() -> void:
	for stat in root_tree.get_children():
		stat.free()


func get_stat_data() -> Dictionary:
	var stat_data: Dictionary = {}
	for stat in root_tree.get_children():
		stat_data[stat.get_text(0)] = {"min": stat.get_range(1), "max": stat.get_range(2)}
	return stat_data
