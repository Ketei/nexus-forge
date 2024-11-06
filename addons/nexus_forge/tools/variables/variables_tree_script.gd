@tool
extends Tree


signal copy_path_pressed(variable_tree: TreeItem)
signal something_changed

const INT_ICON = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const FLOAT_ICON = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const BOOL_ICON = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const STRING_ICON = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
const DELETE_ICON = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const COPY_ICON = preload("res://addons/nexus_forge/common_icons/copy_icon.svg")

const VALUE_MAX_RANGE: int = 9999
const FLOAT_STEP: float = 0.01
var root_tree: TreeItem
var _current_selected: TreeItem = null

func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "Name")
	set_column_title(2, "Default Value")
	set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	set_column_title_alignment(2, HORIZONTAL_ALIGNMENT_LEFT)
	set_column_expand(0, true)
	set_column_expand(1, true)
	set_column_expand(2, true)
	set_column_expand_ratio(0, 8)
	set_column_expand_ratio(1, 1)
	set_column_expand_ratio(2, 7)
	item_edited.connect(on_variable_edited)
	button_clicked.connect(on_button_pressed)


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match column:
		0:
			copy_path_pressed.emit(item)
		2:
			item.free()


func create_variable(variable_name: String, variable_type: Variant.Type, variable_value: Variant) -> TreeItem:
	var new_variable: TreeItem = create_item(root_tree)
	var variable_typeof: int = typeof(variable_value)
	
	# Setting cell modes (and icon)
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variable.set_cell_mode(1, TreeItem.CELL_MODE_ICON)
	
	match variable_type: 
		TYPE_INT:
			new_variable.set_icon(1, INT_ICON)
			new_variable.set_metadata(1, TYPE_INT)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VALUE_MAX_RANGE, VALUE_MAX_RANGE, 1.0)
			if variable_typeof == TYPE_INT or variable_typeof == TYPE_FLOAT:
				new_variable.set_range(2, variable_value)
		TYPE_FLOAT:
			new_variable.set_icon(1, FLOAT_ICON)
			new_variable.set_metadata(1, TYPE_FLOAT)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VALUE_MAX_RANGE, VALUE_MAX_RANGE, FLOAT_STEP)
			if variable_typeof == TYPE_INT or variable_typeof == TYPE_FLOAT:
				new_variable.set_range(2, variable_value)
		TYPE_BOOL:
			new_variable.set_icon(1, BOOL_ICON)
			new_variable.set_metadata(1, TYPE_BOOL)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_variable.set_text(2, "Enabled")
			if variable_typeof == TYPE_BOOL:
				new_variable.set_range(2, variable_value)
		_:
			new_variable.set_icon(1, STRING_ICON)
			new_variable.set_metadata(1, TYPE_STRING)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			if variable_typeof == TYPE_STRING:
				new_variable.set_text(2, variable_value)
	# ------------------
	
	# Setting editability
	new_variable.set_editable(0, true) # The name
	new_variable.set_editable(2, true) # The value
	# -------------------
	
	# Buttons
	new_variable.add_button(0, COPY_ICON, -1, false, "Copy path to variable")
	new_variable.add_button(2, DELETE_ICON, -1, false, "Delete variable.")
	# -------------
	
	# Setting the initial name
	var unique_name: String = validate_var_name(variable_name, new_variable)
	new_variable.set_text(0, unique_name)
	new_variable.set_metadata(0, unique_name)
	# ------------------------
	
	new_variable.set_selectable(1, false)
	
	something_changed.emit()
	
	return new_variable


func clear_variables() -> void:
	for child in root_tree.get_children():
		child.free()


func validate_var_name(var_name: String, skip_tree: TreeItem) -> String:
	var ideal_name: String = "new_variable" if var_name.strip_edges().is_empty() else var_name
	var tweaked_name: String = ideal_name
	var iteration: int = 1
	
	while has_variable(root_tree.get_children(), tweaked_name, skip_tree):
		tweaked_name = str(ideal_name, "_", iteration)
		iteration += 1
	
	return tweaked_name


func has_variable(in_folders:Array[TreeItem], folder_name: String, exception: TreeItem) -> bool:
	for child in in_folders:
		if child == exception:
			continue
		if child.get_text(0) == folder_name:
			return true
	return false


func on_variable_edited() -> void:
	var item_edited: TreeItem = get_edited()
	var current_name: String = item_edited.get_text(0)
	var prev_name: String = item_edited.get_metadata(0)
	
	something_changed.emit()
	
	if prev_name == current_name:
		return
	
	var tweaked_name: String = validate_var_name(current_name, item_edited)
	
	if tweaked_name != current_name:
		item_edited.set_text(0, tweaked_name)
	item_edited.set_metadata(0, tweaked_name)


func get_variables_as_array() -> Array[Dictionary]:
	var variables_array: Array[Dictionary] = []
	
	for variable in root_tree.get_children():
		var new_dict: Dictionary = get_variable_structure()
		new_dict["name"] = variable.get_text(0)
		new_dict["type"] = variable.get_metadata(1)
		new_dict["variable"] = get_tree_variant(variable)
		variables_array.append(new_dict)
	
	return variables_array


func get_tree_variant(tree_var: TreeItem) -> Variant:
	match tree_var.get_metadata(1):
		TYPE_INT:
			return int(tree_var.get_range(2))
		TYPE_FLOAT:
			return float(tree_var.get_range(2))
		TYPE_BOOL:
			return tree_var.is_checked(2)
		TYPE_STRING:
			return tree_var.get_text(2)
		_:
			return ""


func get_variable_structure() -> Dictionary:
	return {
		"name":"",
		"type": TYPE_STRING,
		"variable": ""
	} 


func search_for_var(text_to_search: String) -> void:
	for var_tree in root_tree.get_children():
		var_tree.visible = var_tree.get_text(0).contains(text_to_search)


func show_all_vars() -> void:
	for var_tree in root_tree.get_children():
		var_tree.visible = true
