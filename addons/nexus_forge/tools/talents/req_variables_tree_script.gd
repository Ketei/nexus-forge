@tool
extends IDTree


const ADD_BOOL_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_bool.svg")
const ADD_FLOAT_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_float.svg")
const ADD_INT_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_int.svg")
const ADD_STRING_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_string.svg")
const RANGE_LIMIT: int = 9999
const FLOAT_STEP: float = 0.01

var root_tree: TreeItem = null
var last_variable_created_id: String = ""


func _ready() -> void:
	root_tree = create_item()
	
	set_column_expand(0, true) # ID
	set_column_expand(1, false) # Operator
	set_column_expand(2, false) # Icon
	set_column_expand(3, true) # Value
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(3, 3)
	
	set_column_custom_minimum_width(1, 48)
	set_column_custom_minimum_width(2, 32)
	#set_column_custom_minimum_width(3, 120)


func create_variable(variant: Variant, id: String = "", operator: int = 0) -> void:
	var type: int = typeof(variant)
	var new_variable: TreeItem = create_item(root_tree)
	var new_id: String = validate_id(root_tree, id, new_variable)
	
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variable.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_variable.set_cell_mode(2, TreeItem.CELL_MODE_ICON)
	
	new_variable.set_range_config(1, 0, 5, 1.0)
	
	new_variable.set_text(1, "==,!=,<=,>=,<,>")
	new_variable.set_text(0, new_id)
	new_variable.set_metadata(0, new_id)
	
	new_variable.set_range(1, operator_to_range(operator))
	
	new_variable.set_editable(0, true)
	new_variable.set_editable(1, true)
	new_variable.set_editable(2, false)
	new_variable.set_editable(3, true)
	
	match type:
		TYPE_INT:
			new_variable.set_icon(2, ADD_INT_ICON)
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(3, -RANGE_LIMIT, RANGE_LIMIT, 1.0)
			new_variable.set_metadata(2, TYPE_INT)
			new_variable.set_range(3, variant)
		TYPE_FLOAT:
			new_variable.set_icon(2, ADD_FLOAT_ICON)
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(3, -RANGE_LIMIT, RANGE_LIMIT, FLOAT_STEP)
			new_variable.set_text(0, new_id)
			new_variable.set_metadata(2, TYPE_FLOAT)
			new_variable.set_range(3, variant)
		TYPE_BOOL:
			new_variable.set_icon(2, ADD_BOOL_ICON)
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_CHECK)
			new_variable.set_text(3, "Enabled")
			new_variable.set_text_alignment(3, HORIZONTAL_ALIGNMENT_CENTER)
			new_variable.set_text(0, new_id)
			new_variable.set_metadata(2, TYPE_BOOL)
			new_variable.set_checked(3, variant)
		_: #  TYPE_STRING
			new_variable.set_icon(2, ADD_STRING_ICON)
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(0, new_id)
			new_variable.set_metadata(2, TYPE_STRING)
			if type == TYPE_STRING:
				new_variable.set_text(3, variant)
	
	last_variable_created_id = new_id


func get_variables() -> Dictionary:
	var var_dict: Dictionary = {}
	for variable in root_tree.get_children():
		
		match variable.get_metadata(2):
			TYPE_INT:
				var_dict[variable.get_text(0)] = {
					"value": int(variable.get_range(3)),
					"operator": range_to_operator(variable.get_range(2))}
			TYPE_FLOAT:
				var_dict[variable.get_text(0)] = {
					"value": float(variable.get_range(3)),
					"operator": range_to_operator(variable.get_range(2))}
			TYPE_BOOL:
				var_dict[variable.get_text(0)] = {
					"value": variable.is_checked(3),
					"operator": range_to_operator(variable.get_range(2))}
			TYPE_STRING:
				var_dict[variable.get_text(0)] = {
					"value": variable.get_text(3).strip_edges(),
					"operator": range_to_operator(variable.get_range(2))}
	
	return var_dict


func operator_to_range(range: int) -> int:
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


func on_item_edited() -> void:
	var edited_tree: TreeItem = get_edited()
	
	match get_edited_column():
		0:
			var new_name: String = validate_id(root_tree, edited_tree.get_text(0), edited_tree)
			edited_tree.set_text(0, new_name)
			edited_tree.set_metadata(0, new_name)


func clear_variables() -> void:
	for variable in root_tree.get_children():
		variable.free()
