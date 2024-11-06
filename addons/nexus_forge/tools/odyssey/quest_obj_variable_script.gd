@tool
extends IDTree


const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const BOOL_ICON = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const FLOAT_ICON = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const INT_ICON = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const STRING_ICON = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
const RANGE_LIMIT: int = 9999
const FLOAT_STEP: float = 0.01
var root_tree: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, false)
	set_column_expand(3, true)
	
	set_column_custom_minimum_width(1, 48)
	set_column_custom_minimum_width(2, 32)


func get_data() -> Dictionary:
	var dict_var: Dictionary = {}
	for variable in root_tree.get_children():
		dict_var[variable.get_text(0)] = {
			"value": get_value(variable.get_metadata(2), variable),
			"match": int(variable.get_range(1))}
	return dict_var


func get_value(type: int, value: TreeItem) -> Variant:
	if type == TYPE_INT:
		return int(value.get_range(3))
	elif type == TYPE_FLOAT:
		return float(value.get_range(3))
	elif type == TYPE_BOOL:
		return value.is_checked(3)
	else:
		return value.get_text(3)


func on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	
	if get_edited_column() == 0:
		edited.set_text(0, validate_id(root_tree, edited.get_text(0), edited))


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if id == 0:
		item.free()


func search_item(search: String) -> void:
	for item in root_tree.get_children():
		item.visible = search.is_empty() or item.get_text(0).containsn(search)

func clear_items() -> void:
	for child in root_tree.get_children():
		child.free()


func add_item(id: String, value: Variant, eval: int = 0) -> void:
	var type: int = typeof(value)
	var new_variable: TreeItem = create_item(root_tree)
	
	new_variable.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_variable.set_cell_mode(2, TreeItem.CELL_MODE_ICON)
	
	new_variable.set_text(0, id)
	
	new_variable.set_range_config(1, 0, 5, 1.0)
	new_variable.set_text(1, "==,!=,<,>,<=,>=")
	new_variable.set_range(1, eval)
	
	new_variable.add_button(3, TRASH_BIN, 0, false, "Delete variable")
	
	new_variable.set_editable(0, true)
	new_variable.set_editable(1, true)
	new_variable.set_editable(2, false)
	new_variable.set_editable(3, true)
	
	new_variable.set_selectable(2, false)
	
	match type:
		TYPE_INT:
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(3, -RANGE_LIMIT, RANGE_LIMIT, 1.0)
			new_variable.set_range(3, value)
			new_variable.set_icon(2, INT_ICON)
			new_variable.set_metadata(2, TYPE_INT)
		TYPE_FLOAT:
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(3, -RANGE_LIMIT, RANGE_LIMIT, FLOAT_STEP)
			new_variable.set_range(3, value)
			new_variable.set_icon(2, FLOAT_ICON)
			new_variable.set_metadata(2, TYPE_FLOAT)
		TYPE_BOOL:
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_CHECK)
			new_variable.set_text(3, "Enabled")
			new_variable.set_checked(3, value)
			new_variable.set_icon(2, BOOL_ICON)
			new_variable.set_metadata(2, TYPE_BOOL)
		_:
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_STRING)
			new_variable.set_icon(2, STRING_ICON)
			new_variable.set_metadata(2, TYPE_STRING)
			if type == TYPE_STRING:
				new_variable.set_text(3, value)
	
