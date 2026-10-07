@tool
class_name NFIDTree
extends Tree
## A custom [Tree] node designed to manage unique IDs and
## provide basic filtering functionality for its entries.


## The default name for every new entry.
@export var default_name: String = "new_item"
## What column the ID is at.
var id_cell: int = 0


## Generates a unique ID based on [param desired_id]. 
## If the ID is already taken by a child of [param root_tree],
## it appends a numeric suffix (e.g., "_1", "_2").[br]
## The [param skip_tree] item is ignored during validation,
## which is useful when renaming an existing item.
func get_unique_id(root_tree: TreeItem, desired_id: String, skip_tree: TreeItem = null) -> String:
	var clean_name: String = _sanitize_id(desired_id)
	var ideal_name: String = default_name if clean_name.is_empty() else clean_name
	var base_name: String = ideal_name
	var tweaked_name: String = ideal_name
	var iteration_data: Dictionary = NFStringUtils.get_trailing_integer(ideal_name)
	var iteration: int = iteration_data["integer"]
	if iteration_data["has_integer"]:
		# We remove the integer and the las _ if it has one
		base_name = base_name.trim_suffix(str(iteration)).trim_suffix("_")
	
	while has_id(root_tree, tweaked_name, skip_tree):
		iteration += 1
		tweaked_name = "%s_%d" % [base_name, iteration]
	
	return tweaked_name


## Returns [code]true[/code] if any direct child of [param root_tree]
## has the given [param id] in the [member id_cell] column.[br]
## The [param exception] item is ignored during the check.
func has_id(root_tree: TreeItem, id: String, exception: TreeItem) -> bool:
	for child in root_tree.get_children():
		if child == exception:
			continue
		if child.get_text(id_cell) == id:
			return true
	return false


## Sets the visibility of the root's direct children based on whether
## their content matches [param pattern] (case-insensitive).[br]
## Only the columns specified in [param on_columns] are evaluated.
## If [param pattern] is empty, all children are made visible.
func search_pattern(pattern: String, on_columns: Array[int]) -> void:
	for cell in get_root().get_children():
		if pattern.is_empty():
			cell.visible = true
			continue
		
		var contains: bool = false
		for column in on_columns:
			var search_line: String = ""
			match cell.get_cell_mode(column):
				TreeItem.CELL_MODE_STRING:
					search_line = cell.get_text(column)
				TreeItem.CELL_MODE_RANGE:
					search_line = str(cell.get_range(column))
				TreeItem.CELL_MODE_CHECK:
					search_line = "true" if cell.is_checked(column) else "false"
				_:
					continue
			if search_line.containsn(pattern):
				contains = true
				break
		cell.visible = contains


func _sanitize_id(id_text: String) -> String:
	return id_text.replace("/", "_").replace("\\", "_")
