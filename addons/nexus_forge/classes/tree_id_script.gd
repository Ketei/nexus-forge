class_name IDTree
extends Tree


@export var default_name: String = "new_item"
var id_cell: int = 0


func validate_id(root_tree: TreeItem, id: String, skip_tree: TreeItem) -> String:
	var clean_name: String = id.strip_edges()
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
