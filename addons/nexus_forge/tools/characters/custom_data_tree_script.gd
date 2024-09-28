extends Tree

const BOOL_ICON = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const FLOAT_ICON = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const INT_ICON = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const STRING_ICON = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
const TRASH_BIN_ICON = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")

const RANGE_LIMIT: float = 9999
const FLOAT_STEP: float = 0.01

const DELETE_DATA_ID: int = 0

var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	
	set_column_custom_minimum_width(1, 32)
	
	button_clicked.connect(on_item_button_pressed)


func create_custom_value(value_type: int) -> TreeItem:
	var new_type: TreeItem = create_item(root_tree)
	new_type.set_text(0, validate_data_id(""))
	new_type.set_editable(0, true)
	new_type.set_editable(2, true)
	new_type.set_cell_mode(1, TreeItem.CELL_MODE_ICON)
	new_type.set_icon_max_width(1, 32)
	new_type.set_selectable(1, false)
	new_type.add_button(2, TRASH_BIN_ICON, DELETE_DATA_ID, false, "Delete Data")
	
	match value_type:
		TYPE_INT:
			new_type.set_icon(1, INT_ICON)
			new_type.set_metadata(1, TYPE_INT)
			new_type.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_type.set_range_config(2, -RANGE_LIMIT, RANGE_LIMIT, 1.0)
		TYPE_FLOAT:
			new_type.set_icon(1, FLOAT_ICON)
			new_type.set_metadata(1, TYPE_FLOAT)
			new_type.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_type.set_range_config(2, -RANGE_LIMIT, RANGE_LIMIT, FLOAT_STEP)
		TYPE_BOOL:
			new_type.set_icon(1, BOOL_ICON)
			new_type.set_metadata(1, TYPE_BOOL)
			new_type.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
		_:
			new_type.set_icon(1, STRING_ICON)
			new_type.set_metadata(1, TYPE_STRING)
			new_type.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
	
	return new_type


func on_item_button_pressed(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	match id:
		0:
			item.free()


func get_custom_data() -> Dictionary:
	var custom_data: Dictionary = {}
	for data in root_tree.get_children():
		match data.get_metadata(1):
			TYPE_FLOAT:
				custom_data[data.get_text(0)] = float(data.get_range(2))
			TYPE_INT:
				custom_data[data.get_text(0)] = int(data.get_range(2))
			TYPE_BOOL:
				custom_data[data.get_text(0)] = data.is_checked(2)
			TYPE_STRING:
				custom_data[data.get_text(0)] = data.get_text(2)
	return custom_data


func set_custom_data(custom_data: Dictionary) -> void:
	clear_custom_data()
	
	for data_id in custom_data:
		var data_type: int = typeof(custom_data[data_id])
		var custom_val: TreeItem = create_custom_value(data_type)
		
		match data_type:
			TYPE_FLOAT:
				custom_val.set_range(2, custom_data[data_id])
			TYPE_INT:
				custom_val.set_range(2, custom_data[data_id])
			TYPE_BOOL:
				custom_val.set_checked(2, custom_data[data_id])
			TYPE_STRING:
				custom_val.set_text(2, custom_data[data_id])


func clear_custom_data() -> void:
	for data in root_tree.get_children():
		data.free()


func validate_data_id(variant_id: String) -> String:
	var desired_id: String = "new_data" if variant_id.is_empty() else variant_id
	var modified_id: String = desired_id
	var iteration_count: int = 1
	while has_id(modified_id):
		modified_id = str(desired_id, "_", iteration_count)
		iteration_count += 1
	return modified_id


func has_id(id_string: String) -> bool:
	for item in root_tree.get_children():
		if item.get_text(0) == id_string:
			return true
	return false
