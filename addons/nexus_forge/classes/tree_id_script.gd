@tool
class_name IDTree
extends Tree


@export var default_name: String = "new_item"
var id_cell: int = 0


func _ready() -> void:
	create_item()


func get_unique_id(root_tree: TreeItem, desired_id: String, skip_tree: TreeItem = null) -> String:
	var clean_name: String = desired_id.strip_edges()
	var ideal_name: String = default_name if clean_name.is_empty() else clean_name
	var tweaked_name: String = ideal_name
	var iteration: int = 1
	
	while has_id(root_tree, tweaked_name, skip_tree):
		tweaked_name = str(ideal_name, "_", iteration)
		iteration += 1
	
	return tweaked_name


func has_id(root_tree: TreeItem, id: String, exception: TreeItem) -> bool:
	for child in root_tree.get_children():
		if child == exception:
			continue
		if child.get_text(id_cell) == id:
			return true
	return false


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
