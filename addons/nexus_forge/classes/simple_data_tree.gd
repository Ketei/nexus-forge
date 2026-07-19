@tool
extends IDTree


signal item_deleted
signal data_changed
signal data_moved(was_dropped: bool)

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
@export var undo_redo_steps: int = 20:
	set(s):
		undo_redo_steps = maxi(0, s)
		if _undo != null:
			_undo.max_steps = undo_redo_steps

var _undo: UndoRedo = null

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
	
	if 0 < undo_redo_steps:
		_undo = UndoRedo.new()
		_undo.max_steps = undo_redo_steps
	
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
		
		mn.add_theme_constant_override(&"h_separation", -8)
		mn.add_theme_constant_override(&"item_start_padding", 2)
		mn.add_theme_constant_override(&"item_end_padding", 2)
		mn.add_theme_constant_override(&"icon_max_width", 16)
		
		mn.size.x = 28
		
		mn.id_pressed.connect(_on_compact_menu_id_pressed)


func has_undo() -> bool:
	return _undo != null


func get_undo() -> UndoRedo:
	return _undo


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
	
	add_data(data_name, data_type, false, data_item)
	
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
	
	var target: TreeItem = get_item_at_position(at_position)
	var object: TreeItem = data["tree"]
	var origin_tree: Tree = object.get_tree()
	var target_path: String = _get_data_path(target)
	var original_path: String = _get_data_path(object)
	var original_index: int = object.get_index()
	var new_path: String = ""
	var from_this_tree: bool = _is_in_tree(object)
	var log_undo: bool = true
	
	if target == null: # Dropping at root
		var root_count: int = get_root().get_child_count()
		if object.get_parent() == get_root(): # Same parents
			if 0 < root_count - 1 and original_index < root_count - 1:
				object.move_after(get_root().get_child(-1))
			log_undo = false
		else:
			if _tree_has_id(get_root(), object.get_metadata(0)["name"]):
				var new_id: String = get_unique_id(get_root(), object.get_metadata(0)["name"])
				object.set_text(0, new_id)
				object.get_metadata(0)["name"] = new_id
			if 0 < root_count:
				object.move_after(get_root().get_child(-1))
			else:
				object.get_parent().remove_child(object)
				get_root().add_child(object)
			new_path = _get_data_path(object)
	else:
		var different_parents: bool = object.get_parent() != target
		if different_parents:
			log_undo = true
			if _tree_has_id(target, object.get_metadata(0)["name"]):
				var new_name: String = get_unique_id(target, object.get_metadata(0)["name"])
				object.set_text(0, new_name)
				object.get_metadata(0)["name"] = new_name
		else:
			log_undo = false
		
		var drop_position: int = get_drop_section_at_position(at_position)
		match drop_position:
			-1: # Above
				object.move_before(target)
			0: # On
				object.get_parent().remove_child(object)
				target.add_child(object)
			1: # Below
				if target.get_metadata(0)["type"] == ItemType.FOLDER and not target.collapsed and 0 < target.get_child_count():
					object.move_before(target.get_first_child())
				else:
					object.move_after(target)
		
		new_path = _get_data_path(object)
	
	var new_index: int = object.get_index()
	
	if _undo != null and log_undo:
		_undo.create_action("Drop Data")
		if from_this_tree:
			_undo.add_do_method(_do_move_item.bind(original_path, new_path, new_index))
			_undo.add_undo_method(_do_move_item.bind(new_path, original_path, original_index))
		else:
			if origin_tree.get_script() == get_script() and origin_tree.has_undo(): # Same script
				# --- Undo from this tree ---
				var other_tree: WeakRef = weakref(origin_tree)
				_undo.add_undo_method(_weak_call.bind(
						other_tree,
						&"_undo_erase_data",
						[original_path, get_data_cell_data(object), original_index]))
				_undo.add_do_method(
						_weak_call.bind(
								other_tree,
								&"_do_erase_data",
								[original_path]))
				
				# --- Undo from the other tree ---
				var origin_undo: UndoRedo = origin_tree.get_undo()
				origin_undo.create_action("Drag Data")
				origin_undo.add_do_method(origin_tree._do_erase_data.bind(original_path))
				origin_undo.add_do_method(origin_tree._weak_call.bind(
					weakref(self),
					&"_do_add_data",
					[new_path, get_data_cell_data(object), new_index]))
				origin_undo.add_undo_method(
						origin_tree._do_add_data.bind(
								original_path,
								get_data_cell_data(object),
								original_index))
				origin_undo.add_undo_method(origin_tree._weak_call.bind(
						weakref(self),
						&"_do_erase_data",
						[new_path]))
				origin_undo.commit_action(false)
				
				origin_tree.data_moved.emit(false)
			
			_undo.add_do_method(_do_add_data.bind(new_path, get_data_cell_data(object), new_index))
			_undo.add_undo_method(_do_erase_data.bind(new_path))
		_undo.commit_action(false)
		data_moved.emit(true)
	else:
		data_changed.emit()


func _weak_call(target: WeakRef, method: StringName, data: Array) -> void:
	if target.get_ref() == null:
		return
	var tree: Tree = target.get_ref()
	tree.callv(method, data)


func undo() -> void:
	if _undo != null and _undo.has_undo():
		_undo.undo()


func redo() -> void:
	if _undo != null and _undo.has_redo():
		_undo.redo()


func clear_data(clear_undo: bool = true) -> void:
	clear()
	create_item()
	if _undo != null and clear_undo:
		_undo.clear_history()


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


func _do_add_data(data_path: String, data: Variant, index: int = -1) -> void:
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
			_add_data_to_tree(data_id, data, current_item)


func _do_erase_data(data_path: String) -> void:
	var target: TreeItem = _get_data_item(data_path)
	
	if target == null or target == get_root():
		return
	
	target.free()


func _undo_erase_data(data_path: String, data: Variant, index: int) -> void:
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
		_add_data_to_tree(var_id, data.duplicate(true), target, index)
	else:
		_add_data_to_tree(var_id, data, target, index)


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
	
	if new_type != item.get_metadata(1):
		if item.get_metadata(1) == TYPE_DICTIONARY:
			var btn_idx: int = item.get_button_by_id(1, ButtonIds.TYPE_MENU)
			if btn_idx != -1:
				item.erase_button(1, btn_idx)
		match new_type:
			TYPE_INT:
				item.set_icon(0, ICON_INT)
				item.set_metadata(1, TYPE_INT)
				item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
				item.set_range_config(1, -RANGE_MAX, RANGE_MAX, 1.0)
				item.set_range(1, data)
				item.set_editable(1, true)
			TYPE_FLOAT:
				item.set_icon(0, ICON_FLOAT)
				item.set_metadata(1, TYPE_FLOAT)
				item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
				item.set_range_config(1, -RANGE_MAX, RANGE_MAX, RANGE_FLOAT_STEP)
				item.set_range(1, data)
				item.set_editable(1, true)
			TYPE_BOOL:
				item.set_icon(0, ICON_BOOL)
				item.set_metadata(1, TYPE_BOOL)
				item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
				item.set_text(1, "Enabled")
				item.set_checked(1, data)
				item.set_editable(1, true)
			TYPE_STRING:
				item.set_icon(0, ICON_STRING)
				item.set_metadata(1, TYPE_STRING)
				item.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
				item.set_text(1, data)
				item.set_editable(1, true)
			TYPE_DICTIONARY:
				item.set_icon(0, ICON_FOLDER)
				item.set_metadata(1, TYPE_DICTIONARY)
				item.set_selectable(1, false)
				item.set_editable(0, true)
				item.set_editable(1, false)
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
				item.set_metadata(1, TYPE_NIL)
				item.get_metadata(0)["data"] = data
				item.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
				item.set_text(1, type_string(typeof(data)))
				item.set_editable(1, false)
	else:
		match new_type:
			TYPE_INT, TYPE_FLOAT:
				item.set_range(1, data)
			TYPE_BOOL:
				item.set_checked(1, data)
			TYPE_STRING:
				item.set_text(1, data)
			_:
				item.get_metadata(0)["data"] = data
	
	item.get_metadata(0)["value"] = data


func add_data(data_id: String, data: Variant, initial_load: bool = false, on_node: TreeItem = get_root()) -> void:
	var new_name: String = get_unique_id(on_node, data_id)
	if _undo == null or initial_load:
		_add_data_to_tree(
				new_name,
				data,
				on_node)
		return
	
	var data_path: String = _get_data_path(on_node).path_join(new_name)
	var type: int = typeof(data)
	
	_undo.create_action("Add Data")
	if type == TYPE_DICTIONARY or type == TYPE_ARRAY:
		_undo.add_do_method(_do_add_data.bind(
				data_path,
				data.duplicate(true)))
	else:
		_undo.add_do_method(_do_add_data.bind(
				data_path,
				data))
	_undo.add_undo_method(_undo_add_data.bind(data_path))
	_undo.commit_action(false)
	_add_data_to_tree(new_name, data, on_node)


func _add_data_to_tree(new_name: String, data: Variant, on_node: TreeItem = get_root(), index: int = -1) -> void:
	var data_type: int = typeof(data)
	var new_data: TreeItem = on_node.create_child(index)
	var metadata: Dictionary = {"name": new_name, "type": ItemType.DATA, "value": data}
	
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
			new_data.set_metadata(0, metadata)
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
				_add_data_to_tree(subdata, data[subdata], new_data)
		_:
			new_data.set_icon(0, ICON_VARIABLE)
			new_data.set_metadata(1, TYPE_NIL)
			metadata["data"] = data
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_data.set_text(1, type_string(data_type))
			new_data.set_editable(1, false)
	
	new_data.add_button(1, TRASH_BIN, ButtonIds.DELETE, false, "Delete Data")
	if data_type != TYPE_DICTIONARY:
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
			var type: int = typeof(cell.get_metadata(0)["data"])
			if type == TYPE_DICTIONARY or type == TYPE_ARRAY:
				return cell.get_metadata(0)["data"].duplicate(true)
			else:
				return cell.get_metadata(0)["data"]
		_:
			return null


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		ButtonIds.DELETE:
			var path: String = _get_data_path(item)
			if _undo != null:
				_undo.create_action("Delete Data")
				_undo.add_do_method(_do_erase_data.bind(path))
				_undo.add_undo_method(_undo_erase_data.bind(path, get_data_cell_data(item), item.get_index()))
				_undo.commit_action(false)
			item.free()
			item_deleted.emit()
		ButtonIds.INT:
			add_data("new_int", 0, false, item)
		ButtonIds.FLOAT:
			add_data("new_float", 0.0, false, item)
		ButtonIds.BOOL:
			add_data("new_bool", false, false, item)
		ButtonIds.STRING:
			add_data("new_string", "", false, item)
		ButtonIds.LEVEL:
			add_data("new_folder", {}, false, item)
		ButtonIds.TYPE_MENU:
			data_item = item
			mn.position = DisplayServer.mouse_get_position()
			mn.popup()
			return
	data_changed.emit()


func on_data_edited() -> void:
	var edited: TreeItem = get_edited()
	var path: String = _get_data_path(edited)
	
	if get_edited_column() == 1:
		var from = edited.get_metadata(0)["value"]
		var to = get_data_cell_data(edited)
		var log_undo: bool = true
		var emit_update: bool = true
		match edited.get_metadata(1):
			TYPE_INT, TYPE_FLOAT:
				if edited.get_metadata(0)["value"] != int(edited.get_range(1)) if edited.get_metadata(1) == TYPE_INT else edited.get_range(1):
					edited.get_metadata(0)["value"] = to
				else:
					emit_update = false
					log_undo = false
			TYPE_BOOL:
				if edited.get_metadata(0)["value"] != to:
					edited.get_metadata(0)["value"] = to
				else:
					emit_update = false
					log_undo = false
			TYPE_STRING:
				if edited.get_metadata(0)["value"] != to:
					edited.get_metadata(0)["value"] = to
				else:
					emit_update = false
					log_undo = false
			TYPE_NIL:
				log_undo = false
				if typeof(edited.get_metadata(0)["data"]) == typeof(edited.get_metadata(0)["value"]):
					if edited.get_metadata(0)["data"] == edited.get_metadata(0)["value"]:
						emit_update = false
					else:
						edited.get_metadata(0)["value"] = to
		if _undo != null and log_undo:
			_undo.create_action("Update Data")
			_undo.add_do_method(_do_update_item_data.bind(path, to))
			_undo.add_undo_method(_do_update_item_data.bind(path, from))
			_undo.commit_action(false)
		
		if emit_update:
			data_changed.emit()
		return
	
	if edited.get_metadata(0)["name"] == edited.get_text(0):
		return
	
	var old_name: String = edited.get_metadata(0)["name"]
	var new_name: String = get_unique_id(edited.get_parent(), edited.get_text(0), edited)
	
	var parent_path: String = _get_data_path(edited.get_parent())
	var old_path: String = parent_path.path_join(old_name)
	var new_path: String = parent_path.path_join(new_name)
	
	edited.set_text(0, new_name)
	edited.get_metadata(0)["name"] = new_name
	
	if _undo != null:
		_undo.create_action("Rename Item")
		_undo.add_do_method(_do_rename_item.bind(old_path, new_name))
		_undo.add_undo_method(_do_rename_item.bind(new_path, old_name))
		_undo.commit_action(false)
	
	data_changed.emit()


func get_data() -> Dictionary[String, Variant]:
	var rank_data: Dictionary[String, Variant] = {}
	
	for data_item in get_root().get_children():
		rank_data[data_item.get_text(0)] = get_data_cell_data(data_item)
	
	return rank_data


func search_data(data_text: String) -> void:
	if current_search == data_text:
		return
	var is_empty: bool = data_text.is_empty()
	for data in get_root().get_children():
		data.visible = _child_has_data(data, data_text) or is_empty or data.get_text(0).containsn(data_text) or _data_cell_to_string(data).containsn(data_text)
	current_search = data_text


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
	match item.get_cell_mode(1):
		TreeItem.CELL_MODE_STRING:
			return item.get_text(1)
		TreeItem.CELL_MODE_RANGE:
			return str(item.get_range(1))
		TreeItem.CELL_MODE_CHECK:
			return "true" if item.is_checked(1) else "false"
		_:
			return ""


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _undo != null and is_instance_valid(_undo):
			_undo.clear_history()
			_undo.free()
