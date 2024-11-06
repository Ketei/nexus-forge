@tool
extends Tree


signal stat_edited(from: String, to: String)

const RANGE_MIN: int = 0
const RANGE_MAX: int = 9999
const CLOSE_ICON = preload("res://addons/nexus_forge/common_icons/close_icon.svg")

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
	
	item_edited.connect(on_item_edited)
	button_clicked.connect(on_button_pressed)


func create_stat(stat_name: String, stat_min: int = 0, stat_max: int = 1) -> TreeItem:
	var new_stat: TreeItem = create_item(root_tree)
	var fixed_min: int = clampi(stat_min, RANGE_MIN, RANGE_MAX)
	var fixed_max: int = clampi(stat_max, fixed_min, RANGE_MAX)
	
	new_stat.set_text(0, validate_id(stat_name, new_stat))
	new_stat.set_metadata(0, new_stat.get_text(0))
	new_stat.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_stat.set_range_config(1, RANGE_MIN, RANGE_MAX, 1.0)
	new_stat.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	new_stat.set_range_config(2, RANGE_MIN, RANGE_MAX, 1.0)
	
	new_stat.set_range(1, fixed_min)
	new_stat.set_range(2, fixed_max)
	
	new_stat.set_editable(1, true)
	new_stat.set_editable(2, true)
	
	new_stat.add_button(2, CLOSE_ICON, 0, false, "Remove Stat")
	
	return new_stat


func get_stats() -> Dictionary:
	var stats: Dictionary = {}
	for stat in root_tree.get_children():
		stats[stat.get_text(0)] = {"min": stat.get_range(1), "max": stat.get_range(2)}
	return stats


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	item.free()


func on_item_edited() -> void:
	var edited_item: TreeItem = get_edited()
	var edited_column: int = get_edited_column()
	
	match edited_column:
		0: # ID
			var new_id: String = validate_id(edited_item.get_text(0), edited_item)
			var old_id: String = edited_item.get_metadata(0)
			if edited_item.get_text(0) != new_id:
				edited_item.set_text(0, new_id)
				edited_item.set_metadata(0, new_id)
			stat_edited.emit(old_id, new_id)
		1: # Min Range
			if edited_item.get_range(2) < edited_item.get_range(1):
				edited_item.set_range(2, edited_item.get_range(1))
		2: # Max Range
			if edited_item.get_range(2) < edited_item.get_range(1):
				edited_item.set_range(2, edited_item.get_range(1))


func clear_stats() -> void:
	for stat in root_tree.get_children():
		stat.free()


func get_stat_data() -> Dictionary:
	var stat_data: Dictionary = {}
	for stat in root_tree.get_children():
		stat_data[stat.get_text(0)] = {"min": stat.get_range(1), "max": stat.get_range(2)}
	return stat_data


func validate_id(id: String, omit_tree: TreeItem) -> String:
	var desired_id: String = "new_stat" if id.is_empty() else id
	var modified_id: String = desired_id
	var iteration_count: int = 1
	while has_id(modified_id, omit_tree):
		modified_id = str(desired_id, "_", iteration_count)
		iteration_count += 1
	return modified_id


func has_id(id_string: String, omit_tree: TreeItem) -> bool:
	for item in root_tree.get_children():
		if item == omit_tree:
			continue
		if item.get_text(0) == id_string:
			return true
	return false
