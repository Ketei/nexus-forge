@tool
extends IDTree


signal data_created(path: String, index: int , data: Variant, operator: int)
signal data_moved(from_path: String, from_index: int, to_path: String, to_index: int)
signal data_renamed(parent_path: String, old_name: String, new_name: String)
signal data_updated(path: String, old_value: Variant, new_value: Variant)
signal data_erased(path: String, index: int, data: Variant, operator: int)
signal data_operator_changed(path: String, old_operator: int, new_operator: int)

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

const RANGE_CEIL: int = 9999
const RANGE_FLOOR: int = -9999
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
	
	var path: String = add_data(data_name, data_type, false, data_item)
	
	data_item = null
	
	data_created.emit(path, -1, data_type)


func _get_drag_data(at_position: Vector2) -> Variant:
	if not allow_drag_and_drop:
		return null
	var item: TreeItem = get_item_at_position(at_position)
	if item == null:
		return null
	var preview: Label = Label.new()
	preview.text = "    " + item.get_text(0)
	set_drag_preview(preview)
	return {"tree": item, "type": item.get_metadata(0)["type"], "source": "req_objective_tree"}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not allow_drag_and_drop or not enabled:
		return false
	
	if typeof(data) != TYPE_DICTIONARY:
		drop_mode_flags = DROP_MODE_DISABLED
		return false
	
	if data.has_all(["tree", "type", "source"]) and typeof(data["source"]) == TYPE_STRING and data["source"] == "req_objective_tree":
		var target_node: TreeItem = get_item_at_position(at_position)
		if target_node == data["tree"] or (data["type"] == ItemType.FOLDER and _is_item_child_of(target_node, data["tree"])):
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


func _do_move_item(from: String, to: String, index: int) -> void:
	var target: TreeItem = null
	var new_parent: TreeItem = null
	var current_folder: TreeItem = get_root()
	
	var to_slice: PackedStringArray = to.split("/", false)
	var from_slice: PackedStringArray = from.split("/", false)
	
	if to_slice.is_empty() or from_slice.is_empty():
		return
	
	var new_name: String = to_slice[-1]
	
	for slice in to_slice.slice(0, -1):
		var found: bool = false
		for item in current_folder.get_children():
			if item.get_metadata(0)["name"] == slice:
				if item.get_metadata(0)["type"] == ItemType.FOLDER:
					current_folder = item
					found = true
				break
		if not found:
			return
	
	new_parent = current_folder
	
	if new_parent != get_root() and new_parent.get_metadata(0)["type"] != ItemType.FOLDER:
		return
	
	for item in new_parent.get_children():
		if item.get_metadata(0)["name"] == new_name:
			return
	
	current_folder = get_root()
	
	for slice in from_slice:
		var found: bool = false
		for item in current_folder.get_children():
			if item.get_metadata(0)["name"] == slice:
				current_folder = item
				found = true
				break
		if not found:
			return
	
	target = current_folder
	
	target.set_text(0, new_name)
	target.get_metadata(0)["name"] = new_name
	
	if target.get_parent() != new_parent:
		target.get_parent().remove_child(target)
		new_parent.add_child(target)
		if -1 < index and target.get_index() != index:
			if new_parent.get_child_count() <= 1:
				return
			if index == 0:
				target.move_before(new_parent.get_first_child())
			else:
				target.move_after(new_parent.get_child(index - 1))


func _is_in_tree(item: TreeItem) -> bool:
	var current_level: TreeItem = item
	var root: TreeItem = get_root()
	
	while current_level != null:
		current_level = current_level.get_parent()
		if current_level == get_root():
			return true
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not allow_drag_and_drop:
		return
	
	var object: TreeItem = data["tree"]
	var drop_target: TreeItem = get_item_at_position(at_position)
	var new_parent: TreeItem = null
	var from_this_tree: bool = _is_in_tree(object)
	var original_index: int = object.get_index()
	var original_path: String = _get_data_path(object)
	var new_index: int = -1
	
	if drop_target == null:
		new_parent = get_root()
		new_index = -1
	else:
		var same_parent_shift: bool = from_this_tree and\
				object.get_parent() == drop_target.get_parent() and\
				object.get_index() < drop_target.get_index()
		var drop_position: int = get_drop_section_at_position(at_position)
		match drop_position:
			-1: # Above
				new_parent = drop_target.get_parent()
				new_index = drop_target.get_index()
				if same_parent_shift:
					new_index -= 1
			0: # On
				new_index = -1
				new_parent = drop_target
			1: # Below
				if drop_target.get_metadata(0)["type"] == ItemType.FOLDER and not drop_target.collapsed and 0 < drop_target.get_child_count():
					new_index = 0
					new_parent = drop_target
				else:
					new_parent = drop_target.get_parent()
					new_index = drop_target.get_index()
					if not same_parent_shift:
						new_index += 1
	
	var drop_id: String = object.get_metadata(0)["name"]
	if _tree_has_id(new_parent, drop_id):
		drop_id = get_unique_id(new_parent, drop_id, object)
	var drop_path: String = _get_data_path(new_parent).path_join(drop_id)
	
	if from_this_tree: # Data moved
		if object.get_parent() != new_parent:
			object.get_parent().remove_child(object)
			new_parent.add_child(object)
		if drop_id != object.get_metadata(0)["name"]:
			object.set_text(0, drop_id)
			object.get_metadata(0)["name"] = drop_id
		
		if new_parent.get_child(new_index) != object:
			if new_index <= -1:
				object.move_after(new_parent.get_child(-1))
			elif new_index == 0:
				object.move_before(new_parent.get_first_child())
			else:
				object.move_after(new_parent.get_child(new_index - 1))
		
		data_moved.emit(original_path, original_index, drop_path, new_index)
	else: # Data created
		data_created.emit(
				drop_path,
				new_index,
				get_data_cell_data(object))


func clear_data() -> void:
	clear()
	create_item()


func _get_data_path(item: TreeItem) -> String:
	if item == null or item == get_root():
		return ""
	
	var path: String = ""
	
	var items: Array[String] = []
	
	var current_item: TreeItem = item
	var root: TreeItem = get_root()
	
	while current_item != root and current_item != null:
		items.append(current_item.get_text(0))
		current_item = current_item.get_parent()
	
	items.reverse()
	
	return StringUtils.make_path(items)


func _get_data_item(path: String) -> TreeItem:
	var parts: PackedStringArray = path.split("/", false)
	if parts.is_empty():
		return get_root()
	
	var current_item: TreeItem = get_root()
	
	for slice in parts:
		var found: bool = false
		for item in current_item.get_children():
			if item.get_metadata(0)["name"] == slice:
				found = true
				current_item = item
				break
		if not found:
			return null
	
	return current_item


func _do_add_data(data_path: String, data: Variant, operator: int, index: int = -1) -> void:
	var parts: PackedStringArray = data_path.split("/", false)
	if parts.is_empty():
		return
	var data_id: String = parts[-1]
	if data_id.is_empty():
		return
	
	var current_item: TreeItem = get_root()
	for slice in parts.slice(0, -1):
		var found: bool = false
		for item in current_item.get_children():
			if item.get_metadata(0)["name"] == slice:
				current_item = item
				found = true
				break
		if not found:
			return
	
	if current_item == get_root() or current_item.get_metadata(0)["type"] == ItemType.FOLDER:
		var can_add: bool = true
		for item in current_item.get_children():
			if item.get_metadata(0)["name"] == data_id:
				can_add = false
				break
		if can_add:
			_add_data_to_tree(data_id, data, operator, current_item)


func _do_erase_data(data_path: String) -> void:
	var target: TreeItem = _get_data_item(data_path)
	
	if target == null or target == get_root():
		return
	
	target.free()


func _undo_erase_data(data_path: String, data: Variant, operator: int, index: int) -> void:
	var parts: PackedStringArray = data_path.rsplit("/", false)
	if parts.is_empty():
		NFPluginGameHandler._log_msg(
				"editor - data tree",
				"Failed to undo data erasure on empty path.",
				NFPluginGameHandler._LogLevel.WARNING)
		return
	
	var var_id: String = parts[-1]
	var target: TreeItem = get_root()
	
	for path_slice in parts.slice(0, -1):
		for item in target.get_children():
			if item.get_metadata(0)["name"] == path_slice:
				if item.get_metadata(0)["type"] != ItemType.FOLDER:
					return
				target = item
				break
	
	for item in target.get_children():
		if item.get_metadata(0)["name"] == var_id:
			NFPluginGameHandler._log_msg(
				"editor - data tree",
				"Failed to undo data erasure. ID '%s' already used on path '%s'." % [var_id, _get_data_path(item.get_parent())],
				NFPluginGameHandler._LogLevel.WARNING)
			return
	
	
	var data_type: int = typeof(data)
	if data_type == TYPE_DICTIONARY or data_type == TYPE_ARRAY:
		_add_data_to_tree(var_id, data.duplicate(true), operator, target, index)
	else:
		_add_data_to_tree(var_id, data, operator, target, index)


func _undo_add_data(data_path: String) -> void:
	var target: TreeItem = _get_data_item(data_path)
	
	if target != null and target != get_root():
		target.free()


func _do_rename_item(path: String, new_name: String) -> void:
	var item: TreeItem = _get_data_item(path)
	if item != null and item != get_root():
		item.set_text(0, new_name)
		item.get_metadata(0)["name"] = new_name


func _data_type_to_internal(type: int) -> int:
	match type:
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING:
			return type
		_:
			return TYPE_NIL


func _do_update_item_data(path: String, data: Variant) -> void:
	var item: TreeItem = _get_data_item(path)
	
	if item == null or item == get_root() or item.get_metadata(0)["type"] == ItemType.FOLDER:
		return
	
	var new_type: int = _data_type_to_internal(typeof(data))
	
	if new_type != item.get_metadata(2):
		match new_type:
			TYPE_INT:
				item.set_icon(0, ICON_INT)
				item.set_metadata(2, TYPE_INT)
				item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
				item.set_range_config(2, RANGE_FLOOR, RANGE_CEIL, 1.0)
				item.set_range(2, data)
				item.set_editable(2, true)
			TYPE_FLOAT:
				item.set_icon(0, ICON_FLOAT)
				item.set_metadata(2, TYPE_FLOAT)
				item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
				item.set_range_config(2, RANGE_FLOOR, RANGE_CEIL, RANGE_FLOAT_STEP)
				item.set_range(2, data)
				item.set_editable(2, true)
			TYPE_BOOL:
				item.set_icon(0, ICON_BOOL)
				item.set_metadata(2, TYPE_BOOL)
				item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
				item.set_text(2, "Enabled")
				item.set_checked(2, data)
				item.set_editable(2, true)
			TYPE_STRING:
				item.set_icon(0, ICON_STRING)
				item.set_metadata(2, TYPE_STRING)
				item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
				item.set_text(2, data)
				item.set_editable(2, true)
			TYPE_DICTIONARY:
				item.set_icon(0, ICON_FOLDER)
				item.set_metadata(2, TYPE_DICTIONARY)
				item.set_selectable(2, false)
				item.set_editable(2, false)
				item.get_metadata(0)["type"] = ItemType.FOLDER
				if compact_mode:
					item.add_button(
							1,
							preload("res://addons/nexus_forge/icons/add_variable_icon.svg"),
							ButtonIds.TYPE_MENU,
							false,
							"Add data")
				else:
					item.add_button(1, preload("res://addons/nexus_forge/icons/add_int.svg"), ButtonIds.INT, false, "Add Integer")
					item.add_button(1, preload("res://addons/nexus_forge/icons/add_float.svg"), ButtonIds.FLOAT, false, "Add Float")
					item.add_button(1, preload("res://addons/nexus_forge/icons/add_bool.svg"), ButtonIds.BOOL, false, "Add Bool")
					item.add_button(1, preload("res://addons/nexus_forge/icons/add_string.svg"), ButtonIds.STRING, false, "Add String")
					item.add_button(1, get_theme_icon("FolderCreate", "EditorIcons"), ButtonIds.LEVEL, false, "Add Level")
				for subdata in data:
					add_data(subdata, data[subdata], false, item)
			_:
				item.set_icon(0, ICON_VARIABLE)
				item.set_metadata(2, TYPE_NIL)
				item.get_metadata(0)["data"] = data
				item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
				item.set_text(2, type_string(typeof(data)))
				item.set_editable(2, false)
	else:
		match new_type:
			TYPE_INT, TYPE_FLOAT:
				item.set_range(2, data)
			TYPE_BOOL:
				item.set_checked(2, data)
			TYPE_STRING:
				item.set_text(2, data)
			_:
				item.get_metadata(0)["data"] = data
	
	item.get_metadata(0)["value"] = data


func add_data(data_id: String, data: Variant, operator: int = OP_EQUAL, on_node: TreeItem = get_root()) -> String:
	var new_name: String = get_unique_id(on_node, data_id)
	var data_path: String = _get_data_path(on_node).path_join(new_name)
	
	var type: int = typeof(data)
	
	_add_data_to_tree(new_name, data, operator, on_node)
	
	return data_path


func _add_data_to_tree(new_name: String, data: Variant, operator: int, on_node: TreeItem = get_root(), index: int = -1) -> TreeItem:
	var data_type: int = typeof(data)
	var new_data: TreeItem = on_node.create_child(index)
	var metadata: Dictionary = {"name": new_name, "type": ItemType.DATA, "value": data}
	if data_type != TYPE_DICTIONARY:
		metadata["value"] = data
	
	new_data.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_data.set_text(0, new_name)
	new_data.set_editable(0, true)
	
	match data_type:
		TYPE_INT:
			new_data.set_icon(0, ICON_INT)
			new_data.set_metadata(2, TYPE_INT)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(2, RANGE_FLOOR, RANGE_CEIL, 1.0)
			new_data.set_range(2, data)
			new_data.set_editable(2, true)
		TYPE_FLOAT:
			new_data.set_icon(0, ICON_FLOAT)
			new_data.set_metadata(2, TYPE_FLOAT)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(2, RANGE_FLOOR, RANGE_CEIL, RANGE_FLOAT_STEP)
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
			new_data.set_metadata(0, metadata)
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
			for subdata in data:
				_add_data_to_tree(subdata, data[subdata], OP_EQUAL, new_data)
		_:
			new_data.set_icon(0, ICON_VARIABLE)
			new_data.set_metadata(2, TYPE_NIL)
			new_data.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_data.set_text(2, type_string(data_type))
			new_data.set_editable(2, false)
	
	new_data.add_button(1, TRASH_BIN, ButtonIds.DELETE, false, "Delete Data")
	
	if data_type != TYPE_DICTIONARY:
		new_data.set_metadata(0, metadata)
		new_data.set_metadata(1, operator)
		new_data.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
		
		if data_type == TYPE_INT or data_type == TYPE_FLOAT:
			new_data.set_range_config(1, 0, 5, 1)
			new_data.set_text(1, "==,!=,<,<=,>,>=")
		else:
			new_data.set_range_config(1, 0, 1, 1)
			new_data.set_text(1, "==,!=")
		new_data.set_range(1, operator_to_range(operator))
		new_data.set_editable(1, true)
	else:
		new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
		new_data.set_editable(1, false)
	
	return new_data


func get_data_cell_data(cell: TreeItem) -> Variant:
	match cell.get_metadata(2):
		TYPE_INT:
			return int(cell.get_range(2))
		TYPE_FLOAT:
			return float(cell.get_range(2))
		TYPE_BOOL:
			return cell.is_checked(2)
		TYPE_STRING:
			return cell.get_text(2)
		TYPE_DICTIONARY:
			var subfolder: Dictionary = {}
			for sub_data in cell.get_children():
				subfolder[sub_data.get_text(0)] = get_data_cell_data(sub_data)
			return subfolder
		TYPE_NIL:
			var type: int = typeof(cell.get_metadata(0)["data"])
			if type == TYPE_DICTIONARY or type == TYPE_ARRAY:
				return cell.get_metadata(0)["data"].duplicate(true)
			else:
				return cell.get_metadata(0)["data"]
		_:
			return null


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var data_path: String = ""
	var data_copy: Variant = null
	match id:
		ButtonIds.DELETE:
			var path: String = _get_data_path(item)
			var data: Variant = get_data_cell_data(item)
			var index: int = item.get_index()
			
			item.free()
			data_erased.emit(path, index, data)
			return
		ButtonIds.INT:
			data_copy = 0
			data_path = add_data("new_int", 0, OP_EQUAL, item)
		ButtonIds.FLOAT:
			data_copy = 0.0
			data_path = add_data("new_float", 0.0, OP_EQUAL, item)
		ButtonIds.BOOL:
			data_copy = false
			data_path = add_data("new_bool", false, OP_EQUAL, item)
		ButtonIds.STRING:
			data_copy = ""
			data_path = add_data("new_string", "", OP_EQUAL, item)
		ButtonIds.LEVEL:
			data_copy = {}
			data_path = add_data("new_folder", {}, OP_EQUAL, item)
		ButtonIds.TYPE_MENU:
			data_item = item
			mn.position = DisplayServer.mouse_get_position()
			mn.popup()
			return
	data_created.emit(
			data_path,
			-1,
			data_copy)


func on_data_edited() -> void:
	var edited: TreeItem = get_edited()
	var path: String = _get_data_path(edited)
	var column: int = get_edited_column()
	
	if column == 0: # --- ID updated ---
		if edited.get_metadata(0)["name"] == edited.get_text(0):
			return
		
		var old_name: String = edited.get_metadata(0)["name"]
		var new_name: String = get_unique_id(edited.get_parent(), edited.get_text(0), edited)
		
		var parent_path: String = _get_data_path(edited.get_parent())
		var old_path: String = parent_path.path_join(old_name)
		var new_path: String = parent_path.path_join(new_name)
		
		edited.set_text(0, new_name)
		edited.get_metadata(0)["name"] = new_name
		
		data_renamed.emit(
				parent_path,
				old_name,
				new_name)
	elif column == 1: # Operator
		var old_value: int = edited.get_metadata(1)
		var new_value: int = range_to_operator(edited.get_range(1))
		
		if new_value == old_value:
			return
		
		edited.set_metadata(1, new_value)
		data_operator_changed.emit(
				path,
				old_value,
				new_value)
	elif column == 2: # Value
		var from = edited.get_metadata(0)["value"]
		var to = get_data_cell_data(edited)
		var emit_update: bool = true
		
		match edited.get_metadata(2):
			TYPE_INT, TYPE_FLOAT:
				var current_val = int(edited.get_range(2)) if edited.get_metadata(2) == TYPE_INT else edited.get_range(2)
				if edited.get_metadata(0)["value"] != current_val:
					edited.get_metadata(0)["value"] = to
				else:
					emit_update = false
			TYPE_BOOL:
				if edited.get_metadata(0)["value"] != to:
					edited.get_metadata(0)["value"] = to
				else:
					emit_update = false
			TYPE_STRING:
				if edited.get_metadata(0)["value"] != to:
					edited.get_metadata(0)["value"] = to
				else:
					emit_update = false
			TYPE_NIL:
				if typeof(edited.get_metadata(0)["data"]) == typeof(edited.get_metadata(0)["value"]):
					if edited.get_metadata(0)["data"] == edited.get_metadata(0)["value"]:
						emit_update = false
					else:
						edited.get_metadata(0)["value"] = to
		
		if emit_update:
			data_updated.emit(
					path,
					from,
					to)


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


func set_data(flat_data: Dictionary[String, Dictionary]) -> void:
	clear_data()
	# This dictionary will store our created folder TreeItems.
	# Key: "folder/path", Value: TreeItem reference
	var folder_cache: Dictionary = {}
	
	var root_node: TreeItem = get_root()
	
	for full_path in flat_data.keys():
		var item_data: Dictionary = flat_data[full_path]
		
		var segments: Array[String] = ArrayUtils.create_typed(TYPE_STRING, Array(full_path.split("/")))
		
		var item_name: String = segments.pop_back()
		
		var current_parent: TreeItem = root_node
		var running_path: String = ""
		
		# 1. Reconstruct the folder hierarchy
		for segment in segments:
			# Build the cumulative path to check our cache
			running_path = running_path.path_join(segment)
			
			# If we haven't created this folder yet, make it and cache it
			if not folder_cache.has(running_path):
				var new_folder: TreeItem = _add_data_to_tree(segment, {}, OP_EQUAL, current_parent)
				folder_cache[running_path] = new_folder
			# Step down into the folder for the next iteration
			current_parent = folder_cache[running_path]
		
		# 2. Add the actual data item
		# We safely extract the value and operator, providing fallbacks just in case
		var val: Variant = item_data.get("value")
		var op: int = item_data.get("operator", OP_EQUAL)
		
		add_data(item_name, val, op, current_parent)


func search_data(data_text: String) -> void:
	if current_search == data_text:
		return
	var is_empty: bool = data_text.is_empty()
	for data in get_root().get_children():
		data.visible = _child_has_data(data, data_text) or is_empty or data.get_text(0).containsn(data_text) or _data_cell_to_string(data).containsn(data_text)
	current_search = data_text


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
		TYPE_NIL:
			return {"operator": range_to_operator(cell.get_range(1)), "value": cell.get_metadata(0)["value"]}
		_:
			return {}


func set_data_operator(path: String, operator: int) -> void:
	var target: TreeItem = _get_data_item(path)
	if target != null:
		target.set_range(1, operator_to_range(operator))
		target.set_metadata(1, operator)


func _tree_has_id(item: TreeItem, id: String) -> bool:
	for tree in item.get_children():
		if tree.get_metadata(0)["name"] == id:
			return true
	return false


func _child_has_data(item: TreeItem, text: String) -> bool:
	var is_empty: bool = text.is_empty()
	var result_visible: bool = false
	for child in item.get_children():
		child.visible = _child_has_data(child, text) or is_empty or child.get_text(0).containsn(text) or _data_cell_to_string(child).containsn(text)
		if result_visible == false and child.visible:
			result_visible = true
	return result_visible


func _data_cell_to_string(item: TreeItem) -> String:
	match item.get_cell_mode(2):
		TreeItem.CELL_MODE_STRING:
			return item.get_text(2)
		TreeItem.CELL_MODE_RANGE:
			return str(item.get_range(2))
		TreeItem.CELL_MODE_CHECK:
			return "true" if item.is_checked(2) else "false"
		_:
			return ""
