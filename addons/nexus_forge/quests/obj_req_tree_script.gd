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
var enabled: bool = false

var mn: PopupMenu = null
var data_item: TreeItem = null


func ready_plugin() -> void:
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
	set_column_title(2, "Data Value")
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(2, 3)
	
	set_column_custom_minimum_width(1, 60)
	
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
		
		mn.add_theme_constant_override(&"h_separation", -8)
		mn.add_theme_constant_override(&"item_start_padding", 2)
		mn.add_theme_constant_override(&"item_end_padding", 2)
		mn.add_theme_constant_override(&"icon_max_width", 16)
		
		mn.size.x = 28
		
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
	
	add_data(data_name, data_type, OP_EQUAL, data_item)
	
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
	return {"tree": item, "type": item.get_metadata(0)["type"], "source": "data_tree"}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not allow_drag_and_drop or not enabled:
		return false
	
	if typeof(data) != TYPE_DICTIONARY:
		drop_mode_flags = DROP_MODE_DISABLED
		return false
	
	if data.has_all(["tree", "type", "source"]) and typeof(data["source"]) == TYPE_STRING and data["source"] == "data_tree":
		var target_node: TreeItem = get_item_at_position(at_position)
		if target_node == data["tree"] or (data["type"] == ItemType.FOLDER and _is_item_child_of(target_node, data["tree"])): #target_node.get_parent() == data["tree"]):
			drop_mode_flags = DROP_MODE_DISABLED
			return false
		
		if target_node == null:
			return true
		
		if target_node.get_metadata(0)["type"] == ItemType.FOLDER:
			drop_mode_flags = DROP_MODE_ON_ITEM + DROP_MODE_INBETWEEN
		else:
			drop_mode_flags = DROP_MODE_INBETWEEN
		return true
	else: 
		drop_mode_flags = DROP_MODE_DISABLED
		return false


func _is_item_child_of(item: TreeItem, parent: TreeItem) -> bool:
	if item == null or parent == null:
		return false
	elif item == parent:
		return true
	var next_parent: TreeItem = item.get_parent()
	while next_parent != null:
		if next_parent == parent:
			return true
		next_parent = next_parent.get_parent()
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not allow_drag_and_drop:
		return
	
	var target: TreeItem = get_item_at_position(at_position)
	var object: TreeItem = data["tree"]
	
	if target == null:
		var root_count: int = get_root().get_child_count()
		if object.get_parent() == get_root():
			if 0 < root_count - 1 and object.get_index() < root_count - 1:
				object.move_after(get_root().get_child(-1))
		else:
			if 0 < root_count:
				object.move_after(get_root().get_child(-1))
			else:
				object.get_parent().remove_child(object)
				get_root().add_child(object)
	else:
		var drop_position: int = get_drop_section_at_position(at_position)
		
		match drop_position:
			-1: # Above
				object.move_before(target)
			0: # On
				object.get_parent().remove_child(object)
				target.add_child(object)
			1: # Below
				object.move_after(target)
	data_changed.emit()


func clear_data() -> void:
	clear()
	create_item()


func add_data(data_id: String, data: Variant, operator: int = OP_EQUAL, on_node: TreeItem = get_root()) -> TreeItem:
	var data_type: int = typeof(data)
	var new_name: String = get_unique_id(on_node, data_id)
	var new_data: TreeItem = on_node.create_child()
	var metadata: Dictionary = {"name": new_name, "type": ItemType.DATA, "operator": OP_EQUAL}
	
	new_data.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_data.set_text(0, new_name)
	new_data.set_editable(0, true)
	
	match data_type:
		TYPE_INT:
			new_data.set_icon(0, ICON_INT)
			new_data.set_metadata(2, TYPE_INT)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(2, -RANGE_MAX, RANGE_MAX, 1.0)
			new_data.set_range(2, data)
			new_data.set_editable(2, true)
		TYPE_FLOAT:
			new_data.set_icon(0, ICON_FLOAT)
			new_data.set_metadata(2, TYPE_FLOAT)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(2, -RANGE_MAX, RANGE_MAX, RANGE_FLOAT_STEP)
			new_data.set_range(2, data)
			new_data.set_editable(2, true)
		TYPE_BOOL:
			new_data.set_icon(0, ICON_BOOL)
			new_data.set_metadata(2, TYPE_BOOL)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_data.set_text(2, "Enabled")
			new_data.set_checked(2, data)
			new_data.set_editable(2, true)
		TYPE_STRING:
			new_data.set_icon(0, ICON_STRING)
			new_data.set_metadata(2, TYPE_STRING)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_data.set_text(2, data)
			new_data.set_editable(2, true)
		TYPE_DICTIONARY:
			new_data.set_icon(0, ICON_FOLDER)
			new_data.set_metadata(2, TYPE_DICTIONARY)
			new_data.set_selectable(2, false)
			new_data.set_editable(0, true)
			new_data.set_editable(2, false)
			metadata["type"] = ItemType.FOLDER
			if compact_mode:
				new_data.add_button(
						2,
						preload("res://addons/nexus_forge/icons/add_variable_icon.svg"),
						ButtonIds.TYPE_MENU,
						false,
						"Add data")
			else:
				new_data.add_button(2, preload("res://addons/nexus_forge/icons/add_int.svg"), ButtonIds.INT, false, "Add Integer")
				new_data.add_button(2, preload("res://addons/nexus_forge/icons/add_float.svg"), ButtonIds.FLOAT, false, "Add Float")
				new_data.add_button(2, preload("res://addons/nexus_forge/icons/add_bool.svg"), ButtonIds.BOOL, false, "Add Bool")
				new_data.add_button(2, preload("res://addons/nexus_forge/icons/add_string.svg"), ButtonIds.STRING, false, "Add String")
				new_data.add_button(2, get_theme_icon("FolderCreate", "EditorIcons"), ButtonIds.LEVEL, false, "Add Level")
			for subdata in data.keys():
				add_data(subdata, data[subdata], OP_EQUAL, new_data)
		_:
			new_data.set_icon(0, ICON_VARIABLE)
			new_data.set_metadata(2, TYPE_NIL)
			metadata["data"] = data
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_data.set_text(2, type_string(data_type))
			new_data.set_editable(2, false)
	
	if data_type != TYPE_DICTIONARY:
		new_data.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
		if data_type == TYPE_BOOL or data_type == TYPE_STRING:
			new_data.set_range_config(1, 0, 1, 1)
			new_data.set_text(1, "==,!=")
		else:
			new_data.set_range_config(1, 0, 5, 1)
			new_data.set_text(1, "==,!=,<,<=,>,>=")
		new_data.set_range(1, operator_to_range(operator))
		new_data.set_editable(1, true)
	else:
		new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
		new_data.set_editable(1, false)
	
	new_data.add_button(2, TRASH_BIN, ButtonIds.DELETE, false, "Delete Data")
	
	new_data.set_metadata(0, metadata)
	
	return new_data


func range_to_operator(range: int) -> int:
	match range:
		0:
			return OP_EQUAL
		1:
			return OP_NOT_EQUAL
		2:
			return OP_LESS
		3:
			return OP_LESS_EQUAL
		4:
			return OP_GREATER
		5:
			return OP_GREATER_EQUAL
		_:
			return OP_EQUAL


func operator_to_range(operator: int) -> int:
	match operator:
		OP_EQUAL:
			return 0
		OP_NOT_EQUAL:
			return 1
		OP_LESS:
			return 2
		OP_LESS_EQUAL:
			return 3
		OP_GREATER:
			return 4
		OP_GREATER_EQUAL:
			return 5
		_:
			return 0


func get_cell_value(cell: TreeItem) -> Dictionary:
	match cell.get_metadata(2):
		TYPE_INT:
			return {"operator": range_to_operator(cell.get_range(1)) , "value": int(cell.get_range(2))}
		TYPE_FLOAT:
			return {"operator": range_to_operator(cell.get_range(1)), "value": float(cell.get_range(2))}
		TYPE_BOOL:
			return {"operator": range_to_operator(cell.get_range(1)), "value": cell.is_checked(2)}
		TYPE_STRING:
			return {"operator": range_to_operator(cell.get_range(1)), "value": cell.get_text(2)}
		#TYPE_DICTIONARY:
			#var subfolder: Dictionary = {}
			#for sub_data in cell.get_children():
				#subfolder[sub_data.get_text(0)] = get_data_cell_data(sub_data)
			#return subfolder
		#TYPE_NIL:
			#return cell.get_metadata(0)["data"]
		_:
			return {}


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		ButtonIds.DELETE:
			item.free()
			item_deleted.emit()
		ButtonIds.INT:
			add_data("new_int", 0, OP_EQUAL, item)
		ButtonIds.FLOAT:
			add_data("new_float", 0.0, OP_EQUAL, item)
		ButtonIds.BOOL:
			add_data("new_bool", false, OP_EQUAL, item)
		ButtonIds.STRING:
			add_data("new_string", "", OP_EQUAL, item)
		ButtonIds.LEVEL:
			add_data("new_folder", {}, OP_EQUAL, item)
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


func set_data(flat_data: Dictionary[String, Dictionary]) -> void:
	clear_data()
	# This dictionary will store our created folder TreeItems.
	# Key: "folder/path", Value: TreeItem reference
	var folder_cache: Dictionary = {}
	
	# Assuming get_root() is accessible in this script scope
	var root_node: TreeItem = get_root()
	
	for full_path in flat_data.keys():
		var item_data: Dictionary = flat_data[full_path]
		
		var segments: Array[String] = ArrayUtils.create_array_typed(TYPE_STRING, Array(full_path.split("/")))
		
		var item_name: String = segments.pop_back()
		
		var current_parent: TreeItem = root_node
		var running_path: String = ""
		
		# 1. Reconstruct the folder hierarchy
		for segment in segments:
			# Build the cumulative path to check our cache
			running_path = running_path.path_join(segment)
			
			# If we haven't created this folder yet, make it and cache it
			if not folder_cache.has(running_path):
				# Pass an empty {} to force add_data to just create the folder node
				var new_folder: TreeItem = add_data(segment, {}, OP_EQUAL, current_parent)
				folder_cache[running_path] = new_folder
			# Step down into the folder for the next iteration
			current_parent = folder_cache[running_path]
		
		# 2. Add the actual data item
		# We safely extract the value and operator, providing fallbacks just in case
		var val: Variant = item_data.get("value")
		var op: int = item_data.get("operator", OP_EQUAL)
		
		add_data(item_name, val, op, current_parent)


func get_data() -> Dictionary[String, Dictionary]:
	var result_dict: Dictionary[String, Dictionary] = {}
	
	for item in get_root().get_children():
		_traverse_and_collect(item, result_dict)
		
	return result_dict


func _traverse_and_collect(item: TreeItem, result_dict: Dictionary) -> void:
	var meta: Dictionary = item.get_metadata(0)
	
	if meta == null or typeof(meta) != TYPE_DICTIONARY or not meta.has("type"):
		return
	
	if meta["type"] == ItemType.DATA:
		# 1. Get the path using your method
		var item_path: String = get_path_from(item)
		
		# 2. Directly assign the dictionary from your custom getter
		# This automatically includes both "value" and "operator" keys
		result_dict[item_path] = get_cell_value(item)
		
	elif meta["type"] == ItemType.FOLDER:
		# Recursively process folder children
		for child in item.get_children(): # Calling get_children() on a TreeItem returns an Array[TreeItem] with all containing children.
			_traverse_and_collect(child, result_dict)


func get_path_from(item: TreeItem) -> String:
	var path_items: Array[String] = []
	
	var level: TreeItem = item
	var root: TreeItem = get_root()
	
	while level != root and level != null:
		path_items.append(level.get_text(0))
		level = level.get_parent()
	
	path_items.reverse()
	
	if path_items.is_empty():
		return ""
	else:
		return StringUtils.make_path(path_items)


func search_data(data_text: String) -> void:
	if current_search == data_text:
		return
	var is_empty: bool = data_text.is_empty()
	for data in get_root().get_children():
		data.visible = _child_has_data(data, data_text) or is_empty or data.get_text(0).containsn(data_text) or _data_cell_to_string(data).containsn(data_text)
	current_search = data_text


func _child_has_data(item: TreeItem, text: String) -> bool:
	var is_empty: bool = text.is_empty()
	var result_visible: bool = false
	for child in item.get_children():
		child.visible = _child_has_data(child, text) or is_empty or child.get_text(0).containsn(text) or _data_cell_to_string(child).containsn(text)
		if result_visible == false and child.visible:
			result_visible = true
	return result_visible


func _data_cell_to_string(item: TreeItem) -> String:
	match item.get_cell_mode(1):
		TreeItem.CELL_MODE_STRING:
			return item.get_text(1)
		TreeItem.CELL_MODE_RANGE:
			return str(item.get_range(1))
		TreeItem.CELL_MODE_CHECK:
			return "true" if item.is_checked(1) else "false"
		_:
			return ""
	
