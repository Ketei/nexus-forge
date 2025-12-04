@tool
extends IDTree


signal item_deleted
signal data_changed

enum ItemType {
	DATA,
	FOLDER,
}

enum ButtonIds {
	DELETE,
	INT,
	FLOAT,
	BOOL,
	STRING,
	LEVEL,
	TYPE_MENU,
}

const RANGE_MAX: int = 9999
const RANGE_FLOAT_STEP: float = 0.01

@export var allow_drag_and_drop: bool = false
@export var compact_mode: bool = false

var TRASH_BIN: Texture2D = null

var ICON_BOOL: Texture2D = null
var ICON_FLOAT: Texture2D = null
var ICON_INT: Texture2D = null
var ICON_STRING: Texture2D = null
var ICON_VARIABLE: Texture2D = null
var ICON_FOLDER: Texture2D = null

var current_search: String = ""

var mn: PopupMenu = null
var data_item: TreeItem = null


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	
	TRASH_BIN = get_theme_icon("Remove", "EditorIcons")
	ICON_BOOL = get_theme_icon("bool", "EditorIcons")
	ICON_FLOAT = get_theme_icon("float", "EditorIcons")
	ICON_INT = get_theme_icon("int", "EditorIcons")
	ICON_STRING = get_theme_icon("String", "EditorIcons")
	ICON_FOLDER = get_theme_icon("Folder", "EditorIcons")
	ICON_VARIABLE = get_theme_icon("Variant", "EditorIcons")
	id_cell = 0
	
	create_item()
	set_column_title(0, "Data ID")
	set_column_title(1, "Data Value")
	
	set_column_expand(0, true)
	set_column_expand(1, true)
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 3)
	
	item_edited.connect(on_data_edited)
	
	button_clicked.connect(_on_button_clicked)
	
	if compact_mode:
		mn = PopupMenu.new()
		add_child(mn)
		mn.add_icon_item(
				preload("res://addons/nexus_forge/icons/add_int.svg"),
				"",
				TYPE_INT)
		mn.add_icon_item(
				preload("res://addons/nexus_forge/icons/add_float.svg"),
				"",
				TYPE_FLOAT)
		mn.add_icon_item(
				preload("res://addons/nexus_forge/icons/add_bool.svg"),
				"",
				TYPE_BOOL)
		mn.add_icon_item(
				preload("res://addons/nexus_forge/icons/add_string.svg"),
				"",
				TYPE_STRING)
		mn.add_icon_item(
				get_theme_icon("FolderCreate", "EditorIcons"),
				"",
				TYPE_DICTIONARY)
		
		mn.set_item_tooltip(mn.get_item_index(TYPE_INT), "Add integer")
		mn.set_item_tooltip(mn.get_item_index(TYPE_FLOAT), "Add float")
		mn.set_item_tooltip(mn.get_item_index(TYPE_BOOL), "Add boolean")
		mn.set_item_tooltip(mn.get_item_index(TYPE_STRING), "Add string")
		mn.set_item_tooltip(mn.get_item_index(TYPE_DICTIONARY), "Add folder")
		
		mn.size.x = 24
		
		mn.id_pressed.connect(_on_compact_menu_id_pressed)


func _on_compact_menu_id_pressed(id: int) -> void:
	if data_item == null:
		return
	
	var data_name: String = "new_"
	var data_type = null
	
	if id == TYPE_INT:
		data_name += "int"
		data_type = 0
	elif id == TYPE_FLOAT:
		data_name += "float"
		data_type = 0.0
	elif id == TYPE_BOOL:
		data_name += "bool"
		data_type = false
	elif id == TYPE_STRING:
		data_name += "string"
		data_type = ""
	elif id == TYPE_DICTIONARY:
		data_name += "folder"
		data_type = {}
	else:
		data_name += "data"
	
	add_data(data_name, data_type, data_item)
	
	data_item = null
	
	data_changed.emit()


func _get_drag_data(at_position: Vector2) -> Variant:
	if not allow_drag_and_drop:
		return null
	var item: TreeItem = get_item_at_position(at_position)
	if item == null:
		return null
	var preview: Label = Label.new()
	preview.text = "    " + item.get_text(0)
	set_drag_preview(preview)
	return {"tree": item, "type": item.get_metadata(0)["type"]}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not allow_drag_and_drop:
		return false
	
	if typeof(data) != TYPE_DICTIONARY:
		drop_mode_flags = DROP_MODE_DISABLED
		return false
	
	if data.has_all(["tree", "type"]) and data["tree"] is TreeItem and data["type"] is ItemType:
		var target_node: TreeItem = get_item_at_position(at_position.round())
		if target_node == null or target_node == data["tree"] or (data["type"] == ItemType.FOLDER and target_node.get_parent() == data["tree"]):
			drop_mode_flags = DROP_MODE_DISABLED
			return false
		
		if target_node.get_metadata(0)["type"] == ItemType.FOLDER:
			if data["type"] == ItemType.FOLDER:
				drop_mode_flags = DROP_MODE_ON_ITEM + DROP_MODE_INBETWEEN
			else:
				drop_mode_flags = DROP_MODE_ON_ITEM
		else:
			drop_mode_flags = DROP_MODE_INBETWEEN
		return true
	else: 
		drop_mode_flags = DROP_MODE_DISABLED
		return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not allow_drag_and_drop:
		return
	
	var target: TreeItem = get_item_at_position(at_position)
	var drop_position: int = get_drop_section_at_position(at_position)
	var object: TreeItem = data["tree"]
	
	match drop_position:
		-1: # Above
			object.move_before(target)
		0: # On
			object.get_parent().remove_child(object)
			target.add_child(object)
		1: # Below
			object.move_after(target)


func clear_data() -> void:
	for data in get_root().get_children():
		data.free()


func add_data(data_id: String, data: Variant, on_node: TreeItem = get_root()) -> void:
	var data_type: int = typeof(data)
	var new_name: String = get_unique_id(on_node, data_id)
	var new_data: TreeItem = on_node.create_child()
	var metadata: Dictionary = {"name": new_name, "type": ItemType.DATA}
	
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
		TYPE_DICTIONARY:
			new_data.set_icon(0, ICON_FOLDER)
			new_data.set_metadata(1, TYPE_DICTIONARY)
			new_data.set_selectable(1, false)
			new_data.set_editable(0, true)
			new_data.set_editable(1, false)
			metadata["type"] = ItemType.FOLDER
			if compact_mode:
				new_data.add_button(
						1,
						preload("res://addons/nexus_forge/icons/add_variable_icon.svg"),
						ButtonIds.TYPE_MENU,
						false,
						"Add data")
			else:
				new_data.add_button(1, preload("res://addons/nexus_forge/icons/add_int.svg"), ButtonIds.INT, false, "Add Integer")
				new_data.add_button(1, preload("res://addons/nexus_forge/icons/add_float.svg"), ButtonIds.FLOAT, false, "Add Float")
				new_data.add_button(1, preload("res://addons/nexus_forge/icons/add_bool.svg"), ButtonIds.BOOL, false, "Add Bool")
				new_data.add_button(1, preload("res://addons/nexus_forge/icons/add_string.svg"), ButtonIds.STRING, false, "Add String")
				new_data.add_button(1, get_theme_icon("FolderCreate", "EditorIcons"), ButtonIds.LEVEL, false, "Add Level")
			for subdata in data:
				add_data(subdata, data[subdata], new_data)
		_:
			new_data.set_icon(0, ICON_VARIABLE)
			new_data.set_metadata(1, TYPE_NIL)
			metadata["data"] = data
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_data.set_text(1, type_string(data_type))
			new_data.set_editable(1, false)
	new_data.add_button(1, TRASH_BIN, ButtonIds.DELETE, false, "Delete Data")
	
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
		TYPE_DICTIONARY:
			var subfolder: Dictionary = {}
			for sub_data in cell.get_children():
				subfolder[sub_data.get_text(0)] = get_data_cell_data(sub_data)
			return subfolder
		TYPE_NIL:
			return cell.get_metadata(0)["data"]
		_:
			return null


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		ButtonIds.DELETE:
			item.free()
			item_deleted.emit()
		ButtonIds.INT:
			add_data("new_int", 0, item)
		ButtonIds.FLOAT:
			add_data("new_float", 0.0, item)
		ButtonIds.BOOL:
			add_data("new_bool", false, item)
		ButtonIds.STRING:
			add_data("new_string", "", item)
		ButtonIds.LEVEL:
			add_data("new_folder", {}, item)
		ButtonIds.TYPE_MENU:
			data_item = item
			mn.position = DisplayServer.mouse_get_position()
			mn.popup()
			return
	data_changed.emit()


func on_data_edited() -> void:
	if get_edited_column() != 0:
		data_changed.emit()
		return
	
	var edited: TreeItem = get_edited()
	
	if edited.get_metadata(0)["name"] == edited.get_text(0):
		return
	
	var new_name: String = get_unique_id(edited.get_parent(), edited.get_text(0), edited)
	
	edited.set_text(0, new_name)
	edited.get_metadata(0)["name"] = new_name
	data_changed.emit()


func get_data() -> Dictionary[String, Variant]:
	var rank_data: Dictionary[String, Variant] = {}
	
	for data_item in get_root().get_children():
		rank_data[data_item.get_text(0)] = get_data_cell_data(data_item)
	
	return rank_data


func search_data(data_text: String) -> void:
	if current_search == data_text:
		return
	for data in get_root().get_children():
		data.visible = data_text.is_empty() or data.get_text(0).containsn(data_text) or (data.get_cell_mode(1) == TreeItem.CELL_MODE_STRING and data.get_text(1).containsn(data_text))
	current_search = data_text
