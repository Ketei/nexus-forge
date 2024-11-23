@tool
extends IDTree


signal variables_changed

const BOOL_ICON = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const FLOAT_ICON = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const INT_ICON = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const STRING_ICON = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
const BIN_ICON = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const RANGE_MAX: int = 9999
const FLOAT_STEP: float = 0.01

var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	
	set_column_expand_ratio(0, 3)
	set_column_expand_ratio(2, 2)
	
	set_column_custom_minimum_width(1, 32)
	
	item_edited.connect(on_item_edited)
	button_clicked.connect(on_button_pressed)


func on_item_edited() -> void:
	var edited_item: TreeItem = get_edited()
	
	if get_edited_column() == 0:
		edited_item.set_text(0, validate_id(root_tree, edited_item.get_text(0), edited_item))
	variables_changed.emit()


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	item.free()


func add_variable(variable_id: String, variable_value: Variant) -> void:
	var variant_type: int = typeof(variable_value)
	var new_variable: TreeItem = create_item(root_tree)
	
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variable.set_cell_mode(1, TreeItem.CELL_MODE_ICON)
	
	new_variable.set_text(0, validate_id(root_tree, variable_id, new_variable))
	
	new_variable.add_button(2, BIN_ICON, 0, false, "Delete Variable")
	
	new_variable.set_editable(0, true)
	new_variable.set_editable(2, true)
	
	new_variable.set_selectable(1, false)
	
	match variant_type:
		TYPE_INT:
			new_variable.set_icon(1, INT_ICON)
			new_variable.set_metadata(1, TYPE_INT)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -RANGE_MAX, RANGE_MAX, 1.0)
			new_variable.set_range(2, variable_value)
		TYPE_FLOAT:
			new_variable.set_icon(1, FLOAT_ICON)
			new_variable.set_metadata(1, TYPE_FLOAT)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -RANGE_MAX, RANGE_MAX, FLOAT_STEP)
			new_variable.set_range(2, variable_value)
		TYPE_BOOL:
			new_variable.set_icon(1, BOOL_ICON)
			new_variable.set_metadata(1, TYPE_BOOL)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_variable.set_checked(2, variable_value)
			new_variable.set_text(2, "Enabled")
		_:
			new_variable.set_icon(1, STRING_ICON)
			new_variable.set_metadata(1, TYPE_STRING)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			if variant_type == TYPE_STRING:
				new_variable.set_text(2, variable_value)


func get_custom_data() -> Dictionary:
	var data_dict: Dictionary = {}
	for variable in root_tree.get_children():
		if variable.get_metadata(1) == TYPE_INT:
			data_dict[variable.get_text(0)] = int(variable.get_range(2))
		elif variable.get_metadata(1) == TYPE_FLOAT:
			data_dict[variable.get_text(0)] = float(variable.get_range(2))
		elif variable.get_metadata(1) == TYPE_BOOL:
			data_dict[variable.get_text(0)] = variable.is_checked(2)
		else:
			data_dict[variable.get_text(0)] = variable.get_text(2)
	return data_dict


func clear_variables() -> void:
	for variable in root_tree.get_children():
		variable.free()


func search_item(search_value: String) -> void:
	for variable in root_tree.get_children():
		var value_text: String = ""
		
		match variable.get_metadata(1):
			TYPE_INT:
				value_text = str(int(variable.get_range(2)))
			TYPE_FLOAT:
				value_text = str(float(variable.get_range(2)))
			TYPE_BOOL:
				value_text = str(variable.is_checked(2))
			_:
				value_text = variable.get_text(2)
		
		variable.visible = search_value.is_empty() or variable.get_text(0).containsn(search_value) or value_text.contains(search_value)
