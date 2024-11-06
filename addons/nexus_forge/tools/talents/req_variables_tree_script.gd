@tool
extends Tree


const ADD_BOOL_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_bool.svg")
const ADD_FLOAT_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_float.svg")
const ADD_INT_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_int.svg")
const ADD_STRING_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_string.svg")
const RANGE_LIMIT: int = 9999
const FLOAT_STEP: float = 0.01

var root_tree: TreeItem = null

func _ready() -> void:
	root_tree = create_item()
	
	set_column_expand(0, true) # ID
	set_column_expand(1, false) # Operator
	set_column_expand(2, false) # Icon
	set_column_expand(3, true) # Value
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(3, 3)
	
	set_column_custom_minimum_width(1, 24)
	set_column_custom_minimum_width(2, 32)


func create_variable(variant: Variant, id: String = "", operator: int = 0) -> void:
	var type: int = typeof(variant)
	var new_variable: TreeItem = create_item(root_tree)
	
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variable.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_variable.set_cell_mode(2, TreeItem.CELL_MODE_ICON)
	
	new_variable.set_range_config(1, 0, 5, 1.0)
	
	new_variable.set_text(1, "==,!=,<=,>=,<,>")
	
	new_variable.set_range(1, operator)
	
	new_variable.set_editable(0, true)
	new_variable.set_editable(1, true)
	new_variable.set_editable(2, false)
	new_variable.set_editable(3, true)
	
	match type:
		TYPE_INT:
			new_variable.set_icon(2, ADD_INT_ICON)
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(3, -RANGE_LIMIT, RANGE_LIMIT, 1.0)
			new_variable.set_text(0, validate_name("new_int" if id.is_empty() else id, new_variable))
			new_variable.set_metadata(0, new_variable.get_text(0))
			new_variable.set_metadata(2, TYPE_INT)
			new_variable.set_range(3, variant)
		TYPE_FLOAT:
			new_variable.set_icon(2, ADD_FLOAT_ICON)
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(3, -RANGE_LIMIT, RANGE_LIMIT, FLOAT_STEP)
			new_variable.set_text(0, validate_name("new_float" if id.is_empty() else id, new_variable))
			new_variable.set_metadata(0, new_variable.get_text(0))
			new_variable.set_metadata(2, TYPE_FLOAT)
			new_variable.set_range(3, variant)
		TYPE_BOOL:
			new_variable.set_icon(2, ADD_BOOL_ICON)
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_CHECK)
			new_variable.set_text(0, validate_name("new_bool" if id.is_empty() else id, new_variable))
			new_variable.set_metadata(0, new_variable.get_text(0))
			new_variable.set_metadata(2, TYPE_BOOL)
			new_variable.set_checked(3, variant)
		_: #  TYPE_STRING
			new_variable.set_icon(2, ADD_STRING_ICON)
			new_variable.set_cell_mode(3, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(0, validate_name("new_string" if id.is_empty() else id, new_variable))
			new_variable.set_metadata(0, new_variable.get_text(0))
			new_variable.set_metadata(2, TYPE_STRING)
			if type == TYPE_STRING:
				new_variable.set_text(3, variant)


func get_variables() -> Dictionary:
	var var_dict: Dictionary = {}
	for variable in root_tree.get_children():
		match variable.get_metadata(1):
			TYPE_INT:
				var_dict[variable.get_text(0)] = {
					"value": int(variable.get_range(3)),
					"operator": variable.get_range(2)}
			TYPE_FLOAT:
				var_dict[variable.get_text(0)] = {
					"value": float(variable.get_range(3)),
					"operator": variable.get_range(2)}
			TYPE_BOOL:
				var_dict[variable.get_text(0)] = {
					"value": variable.is_checked(3),
					"operator": variable.get_range(2)}
			TYPE_STRING:
				var_dict[variable.get_text(0)] = {
					"value": variable.get_text(3).strip_edges(),
					"operator": variable.get_range(2)}
	return var_dict


func on_item_edited() -> void:
	var edited_tree: TreeItem = get_edited()
	
	if edited_tree.get_metadata(0) != edited_tree.get_text(0):
		var new_name: String = validate_name(edited_tree.get_text(0), edited_tree)
		
		if edited_tree.get_text(0) != new_name:
			edited_tree.set_text(0, new_name)
		edited_tree.set_metadata(0, new_name)


func validate_name(id_string: String, omit_tree: TreeItem = null) -> String:
	var ideal_id: String = "new_variable" if id_string.is_empty() else id_string.strip_edges()
	var tweaked_id: String = ideal_id
	var iteration: int = 1
	while has_id(tweaked_id, omit_tree):
		tweaked_id = str(ideal_id, "_", iteration)
		iteration += 1
	return tweaked_id


func has_id(id_string: String, omit_tree: TreeItem = null) -> bool:
	for variable in root_tree.get_children():
		if variable == omit_tree:
			continue
		if variable.get_metadata(0) == id_string:
			return true
	return false


func clear_variables() -> void:
	for variable in root_tree.get_children():
		variable.free()
