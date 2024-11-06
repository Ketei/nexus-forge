@tool
extends Tree


signal data_changed

const BOOL_ICON = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const FLOAT_ICON = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const INT_ICON = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const STRING_ICON = preload("res://addons/nexus_forge/common_icons/variables/string.svg")

const RANGE_LIMIT: float = 9999
const FLOAT_STEP: float = 0.01

var root_tree: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "Data ID")
	set_column_title(2, "Data Value")
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	
	set_column_custom_minimum_width(1, 32)
	
	item_edited.connect(on_item_edited)


func create_custom_data(data_key: String, data_variant: Variant) -> void:
	var data_type: int = typeof(data_variant)
	
	if data_type != TYPE_INT and data_type != TYPE_FLOAT and data_type != TYPE_BOOL and data_type != TYPE_STRING:
		return
	
	var new_data: TreeItem = create_item(root_tree)
	var valid_id: String = validate_id(data_key)
	
	new_data.set_text(0, valid_id)
	new_data.set_metadata(0, valid_id)
	new_data.set_cell_mode(1, TreeItem.CELL_MODE_ICON)
	
	new_data.set_editable(0, true)
	new_data.set_editable(2, true)
	
	match data_type:
		TYPE_INT:
			new_data.set_icon(1, INT_ICON)
			new_data.set_metadata(1, TYPE_INT)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(2, -RANGE_LIMIT, RANGE_LIMIT, 1)
			new_data.set_range(2, data_variant)
		TYPE_FLOAT:
			new_data.set_icon(1, FLOAT_ICON)
			new_data.set_metadata(1, TYPE_FLOAT)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(2, -RANGE_LIMIT, RANGE_LIMIT, FLOAT_STEP)
			new_data.set_range(2, data_variant)
		TYPE_BOOL:
			new_data.set_icon(1, BOOL_ICON)
			new_data.set_metadata(1, TYPE_BOOL)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_data.set_checked(2, data_variant)
		TYPE_STRING:
			new_data.set_icon(1, STRING_ICON)
			new_data.set_metadata(1, TYPE_STRING)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_data.set_text(2, data_variant)
	
	data_changed.emit()


func get_custom_data_dict() -> Dictionary:
	var data_entries: Dictionary = {}
	for entry in root_tree.get_children():
		match entry.get_metadata(1):
			TYPE_INT:
				data_entries[entry.get_text(0)] = int(entry.get_range(2))
			TYPE_FLOAT:
				data_entries[entry.get_text(0)] = float(entry.get_range(2))
			TYPE_BOOL:
				data_entries[entry.get_text(0)] = entry.is_checked(2)
			TYPE_STRING:
				data_entries[entry.get_text(0)] = entry.get_text(2)
	return data_entries
	


func clear_custom_data() -> void:
	for data in root_tree.get_children():
		data.free()


func on_item_edited() -> void:
	var edited_tree: TreeItem = get_edited()
	
	data_changed.emit()
	
	if edited_tree.get_metadata(0) == edited_tree.get_text(0):
		return
	
	var new_id: String = validate_id(edited_tree.get_text(0))
	
	if edited_tree.get_text(0) != new_id:
		edited_tree.set_text(0, new_id)
	
	edited_tree.set_metadata(0, new_id)


func validate_id(desired_id: String) -> String:
	var ideal_id: String = "new_data" if desired_id.is_empty() else desired_id
	var tweaked_id: String = ideal_id
	var iteration_count: int = 1
	while has_id(tweaked_id):
		tweaked_id = str(ideal_id, "_", iteration_count)
		iteration_count += 1
	return tweaked_id


func has_id(id_to_check: String) -> bool:
	for data_tree in root_tree.get_children():
		if data_tree.get_metadata(0) == id_to_check:
			return true
	return false


func search_data(data_id: String) -> void:
	var data_str: String = data_id.strip_edges()
	if data_str.is_empty():
		for data in root_tree.get_children():
			data.visible = true
	else:
		for data in root_tree.get_children():
			data.visible = data.get_text(0).containsn(data_str)
