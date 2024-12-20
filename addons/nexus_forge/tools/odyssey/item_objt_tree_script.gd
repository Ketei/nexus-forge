@tool
extends IDTree

const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const RANGE_MAX: int = 9999
var root_tree: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	set_column_expand(3, false)
	
	set_column_expand_ratio(0, 3)
	set_column_expand_ratio(2, 2)
	
	set_column_custom_minimum_width(1, 48)
	set_column_custom_minimum_width(3, 120)


func clear_items() -> void:
	for child in root_tree.get_children():
		child.free()


func add_item(item_id: String, item_count: int = 1, eval: int = 0, is_unique: bool = false) -> void:
	var new_req: TreeItem = create_item(root_tree)
	
	new_req.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_req.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_req.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	new_req.set_cell_mode(3, TreeItem.CELL_MODE_CHECK)
	
	new_req.set_range_config(1, 0, 5, 1.0)
	new_req.set_range_config(2, 0, RANGE_MAX, 1.0)
	
	new_req.set_text(0, item_id)
	new_req.set_text(1, "==,!=,<,>,<=,>=")
	new_req.set_range(1, eval)
	new_req.set_range(2, item_count)
	new_req.set_checked(3, is_unique)
	new_req.set_text(3, "Unique")
	
	new_req.set_editable(0, true)
	new_req.set_editable(1, true)
	new_req.set_editable(2, true)
	new_req.set_editable(3, true)
	
	new_req.add_button(3, TRASH_BIN, 0, false, "Delete Item")


func search_item(search: String) -> void:
	for item in root_tree.get_children():
		item.visible = search.is_empty() or item.get_text(0).containsn(search)


func value_to_operator(value: int) -> int:
	match value:
		0:
			return OP_EQUAL
		1:
			return OP_NOT_EQUAL
		2:
			return OP_LESS
		3:
			return OP_GREATER
		4:
			return OP_LESS_EQUAL
		5:
			return OP_GREATER_EQUAL
		_:
			return OP_EQUAL


func get_data() -> Dictionary:
	var item_dict: Dictionary = {}
	for item in root_tree.get_children():
		item_dict[item.get_text(0)] = {"exact": item.is_checked(3), "amount": int(item.get_range(2)), "match": int(item.get_range(1))}
	return item_dict


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if id == 0:
		item.free()
