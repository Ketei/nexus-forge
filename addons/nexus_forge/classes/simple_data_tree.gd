@tool
extends IDTree


signal item_deleted

const RANGE_MAX: int = 9999
const RANGE_FLOAT_STEP: float = 0.01

const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")

const ICON_BOOL = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const ICON_FLOAT = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const ICON_INT = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const ICON_STRING = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
const ICON_VARIABLE = preload("res://addons/nexus_forge/common_icons/variables/variable_icon.svg")

func _ready() -> void:
	id_cell = 0
	create_item()
	
	set_column_expand(0, true)
	set_column_expand(1, true)
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 3)
	
	button_clicked.connect(on_button_pressed)


func clear_data() -> void:
	for data in get_root().get_children():
		data.free()


func add_data(data_id: String, data: Variant) -> void:
	var new_name: String = get_unique_id(get_root(), data_id)
	var new_data: TreeItem = get_root().create_child()
	var data_type: int = typeof(data)
	var metadata: Dictionary = {"name": new_name}
	
	new_data.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_data.set_text(0, new_name)
	new_data.set_editable(0, true)
	
	match data_type:
		TYPE_INT:
			new_data.set_icon(0, ICON_INT)
			new_data.set_metadata(1, TYPE_INT)
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(1, -RANGE_MAX, RANGE_MAX, 1.0)
			new_data.set_range(1, data)
			new_data.set_editable(1, true)
		TYPE_FLOAT:
			new_data.set_icon(0, ICON_FLOAT)
			new_data.set_metadata(1, TYPE_FLOAT)
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(1, -RANGE_MAX, RANGE_MAX, RANGE_FLOAT_STEP)
			new_data.set_range(1, data)
			new_data.set_editable(1, true)
		TYPE_BOOL:
			new_data.set_icon(0, ICON_BOOL)
			new_data.set_metadata(1, TYPE_BOOL)
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			new_data.set_text(1, "Enabled")
			new_data.set_checked(1, data)
			new_data.set_editable(1, true)
		TYPE_STRING:
			new_data.set_icon(0, ICON_STRING)
			new_data.set_metadata(1, TYPE_STRING)
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_data.set_text(1, data)
			new_data.set_editable(1, true)
		_:
			new_data.set_icon(0, ICON_VARIABLE)
			new_data.set_metadata(1, TYPE_NIL)
			metadata["data"] = data
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_data.set_text(1, type_string(data_type))
			new_data.set_editable(1, false)
	
	new_data.add_button(1, TRASH_BIN, 0, false, "Delete Data")
	
	new_data.set_metadata(0, metadata)


func get_data_cell_data(cell: TreeItem) -> Variant:
	match cell.get_metadata(1):
		TYPE_INT:
			return int(cell.get_range(1))
		TYPE_FLOAT:
			return float(cell.get_range(1))
		TYPE_BOOL:
			return cell.is_checked(1)
		TYPE_STRING:
			return cell.get_text(1)
		TYPE_NIL:
			return cell.get_metadata(0)["data"]
		_:
			return null


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			item.free()
			item_deleted.emit()


func on_data_edited() -> void:
	if get_edited_column() != 0:
		return
	
	var edited: TreeItem = get_edited()
	
	if edited.get_metadata(0)["name"] == edited.get_text(0):
		return
	
	var new_name: String = get_unique_id(get_root(), edited.get_text(0), edited)
	
	edited.set_text(0, new_name)
	edited.get_metadata(0)["name"] = new_name


func get_data() -> Dictionary:
	var rank_data: Dictionary = {}
	
	for data_item in get_root().get_children():
		rank_data[data_item.get_text(0)] = get_data_cell_data(data_item)
	
	return rank_data


func search_data(data_text: String) -> void:
	for data in get_root().get_children():
		data.visible = data_text.is_empty() or data.get_text(0).containsn(data_text) or (data.get_cell_mode(1) == TreeItem.CELL_MODE_STRING and data.get_text(1).containsn(data_text))
