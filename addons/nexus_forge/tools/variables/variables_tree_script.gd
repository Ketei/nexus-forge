@tool
extends Tree


signal copy_path_pressed(variable_id: String)
signal variable_updated(variable_id: String, value: Variant)
signal variable_renamed(from: String, to: String)
signal variable_created(variable_id: String, value: Variant)
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
	set_column_title(1, "Default Value")
	set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	set_column_expand(0, true)
	set_column_expand(1, true)
	#set_column_expand(2, true)
	set_column_expand_ratio(0, 8)
	#set_column_expand_ratio(1, 1)
	set_column_expand_ratio(1, 7)
	item_edited.connect(_on_item_edited)
	button_clicked.connect(on_button_pressed)


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			copy_path_pressed.emit(item.get_text(0))
		1:
			item.free()


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	match get_edited_column():
		0: # Var name edited
			edited.set_text(0, validate_var_name(edited.get_text(0), edited))
			variable_renamed.emit(edited.get_metadata(0), edited.get_text(0))
			edited.set_metadata(0, edited.get_text(0))
		1: # Var value changed
			variable_updated.emit(edited.get_text(0), get_tree_variant(edited))
	something_changed.emit()


func create_variable(variable_name: String, variable_value: Variant) -> String:
	var new_variable: TreeItem = create_item(root_tree)
	var variable_typeof: int = typeof(variable_value)
	
	# Setting cell modes (and icon)
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	#new_variable.set_cell_mode(1, TreeItem.CELL_MODE_ICON)
	
	match typeof(variable_value): 
		TYPE_INT:
			new_variable.set_icon(0, INT_ICON)
			#new_variable.set_metadata(1, TYPE_INT)
			new_variable.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(1, -VALUE_MAX_RANGE, VALUE_MAX_RANGE, 1.0)
			new_variable.set_range(1, variable_value)
			#if variable_typeof == TYPE_INT or variable_typeof == TYPE_FLOAT:
		TYPE_FLOAT:
			new_variable.set_icon(0, FLOAT_ICON)
			#new_variable.set_metadata(1, TYPE_FLOAT)
			new_variable.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(1, -VALUE_MAX_RANGE, VALUE_MAX_RANGE, FLOAT_STEP)
			new_variable.set_range(1, variable_value)
			#if variable_typeof == TYPE_INT or variable_typeof == TYPE_FLOAT:
		TYPE_BOOL:
			new_variable.set_icon(0, BOOL_ICON)
			#new_variable.set_metadata(1, TYPE_BOOL)
			new_variable.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			new_variable.set_text(1, "Enabled")
			new_variable.set_range(1, variable_value)
			#if variable_typeof == TYPE_BOOL:
		TYPE_STRING:
			new_variable.set_icon(0, STRING_ICON)
			new_variable.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(1, variable_value)
		_:
			new_variable.set_icon(0, STRING_ICON)
			new_variable.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	# ------------------
	
	# Setting editability
	new_variable.set_editable(0, true) # The name
	new_variable.set_editable(1, true) # The value
	# -------------------
	
	# Buttons
	new_variable.add_button(0, COPY_ICON, 0, false, "Copy path to variable")
	new_variable.add_button(1, DELETE_ICON, 1, false, "Delete variable.")
	# -------------
	
	# Setting the initial name
	var unique_name: String = validate_var_name(variable_name, new_variable)
	new_variable.set_text(0, unique_name)
	new_variable.set_metadata(0, unique_name)
	# ------------------------
	
	return unique_name


func clear_variables() -> void:
	for child in root_tree.get_children():
		child.free()


func validate_var_name(var_name: String, skip_tree: TreeItem) -> String:
	var ideal_name: String = "new_variable" if var_name.strip_edges().is_empty() else var_name
	var tweaked_name: String = ideal_name
	var iteration: int = 0
	
	while has_variable(root_tree.get_children(), tweaked_name, skip_tree):
		iteration += 1
		tweaked_name = str(ideal_name, "_", iteration)
	
	return tweaked_name


func has_variable(in_folders:Array[TreeItem], folder_name: String, exception: TreeItem) -> bool:
	for child in in_folders:
		if child == exception:
			continue
		if child.get_text(0) == folder_name:
			return true
	return false


#func on_variable_edited() -> void:
	#var item_edited: TreeItem = get_edited()
	#
	#if get_edited_column() == 0:
		#item_edited.set_text(0, validate_var_name(item_edited.get_text(0), item_edited))
	#
	#something_changed.emit()


func get_variables_as_array() -> Array[Dictionary]:
	var variables_array: Array[Dictionary] = []
	
	for variable in root_tree.get_children():
		variables_array.append({
				"name": variable.get_text(0),
				"type": get_variable_type(variable),
				"variable": get_tree_variant(variable)})
	
	return variables_array


func get_tree_variant(tree_var: TreeItem) -> Variant:
	match tree_var.get_cell_mode(1):
		TreeItem.CELL_MODE_RANGE:
			if tree_var.get_range_config(1)["step"] == 1.0:
				return int(tree_var.get_range(1))
			else:
				return float(tree_var.get_range(1))
		TreeItem.CELL_MODE_CHECK:
			return tree_var.is_checked(1)
		TreeItem.CELL_MODE_STRING:
			return tree_var.get_text(1)
		_:
			return ""


func get_variable_type(variable_cell: TreeItem) -> int:
	match variable_cell.get_cell_mode(1):
		TreeItem.CELL_MODE_STRING:
			return TYPE_STRING
		TreeItem.CELL_MODE_RANGE:
			if variable_cell.get_range_config(0)["step"] == 1.0:
				return TYPE_INT
			else:
				return TYPE_FLOAT
		TreeItem.CELL_MODE_CHECK:
			return TYPE_BOOL
		_:
			return TYPE_STRING


func search_for_var(text_to_search: String) -> void:
	for var_tree in root_tree.get_children():
		var_tree.visible = var_tree.get_text(0).contains(text_to_search)


func show_all_vars() -> void:
	for var_tree in root_tree.get_children():
		var_tree.visible = true
