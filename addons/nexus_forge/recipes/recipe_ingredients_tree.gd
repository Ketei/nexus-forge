@tool
extends Tree


signal items_changed


enum RecipeMode {
	INPUT,
	OUTPUT}

enum ButtonID {
	ERASE,
	ADD_DATA}

enum ItemType {
	RECIPE_ITEM,
	ITEM_DATA}


@export var recipe_mode: RecipeMode = RecipeMode.INPUT
var recipe_selected: bool = false
var data_item: TreeItem = null
var compact_menu: PopupMenu


func ready_plugin() -> void:
	create_item()
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 1)
	set_column_title(0, "Item ID")
	set_column_title(1, "Amount")
	
	compact_menu = PopupMenu.new()
	add_child(compact_menu)
	compact_menu.add_icon_item(
			preload("res://addons/nexus_forge/icons/add_int.svg"),
			"",
			TYPE_INT)
	compact_menu.add_icon_item(
			preload("res://addons/nexus_forge/icons/add_float.svg"),
			"",
			TYPE_FLOAT)
	compact_menu.add_icon_item(
			preload("res://addons/nexus_forge/icons/add_bool.svg"),
			"",
			TYPE_BOOL)
	compact_menu.add_icon_item(
			preload("res://addons/nexus_forge/icons/add_string.svg"),
			"",
			TYPE_STRING)
	compact_menu.add_icon_item(
			get_theme_icon("FolderCreate", "EditorIcons"),
			"",
			TYPE_DICTIONARY)
	
	compact_menu.set_item_tooltip(
			compact_menu.get_item_index(TYPE_INT),
			"Add integer")
	compact_menu.set_item_tooltip(
			compact_menu.get_item_index(TYPE_FLOAT),
			"Add float")
	compact_menu.set_item_tooltip(
			compact_menu.get_item_index(TYPE_BOOL),
			"Add boolean")
	compact_menu.set_item_tooltip(
			compact_menu.get_item_index(TYPE_STRING),
			"Add string")
	compact_menu.set_item_tooltip(
			compact_menu.get_item_index(TYPE_DICTIONARY),
			"Add folder")
	
	compact_menu.add_theme_constant_override(&"h_separation", -8)
	compact_menu.add_theme_constant_override(&"item_start_padding", 2)
	compact_menu.add_theme_constant_override(&"item_end_padding", 2)
	compact_menu.add_theme_constant_override(&"icon_max_width", 16)
	
	compact_menu.size.x = 28
	
	compact_menu.id_pressed.connect(_on_add_data_menu_id_pressed)
	button_clicked.connect(_on_button_clicked)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not recipe_selected or typeof(data) != TYPE_DICTIONARY or not data.has_all(["type", "item"]):
		return false
	
	# If it's data, we can drop anywhere as long as the target isn't null
	
	# If it's recipe item, we can drop as long as the target is a recipe
	# item or null
	
	var target_item: TreeItem = get_item_at_position(at_position)
	var is_target_item: bool = _is_item(target_item)
	if data["item"] == null: # THe item is new
		if not data.has("id") or (target_item != null and not is_target_item):
			drop_mode_flags = DROP_MODE_DISABLED
			return false
	else:
		if target_item == null:
			if data["type"] == ItemType.ITEM_DATA:
				drop_mode_flags = DROP_MODE_DISABLED
				return false
		else:
			if data["type"] == ItemType.RECIPE_ITEM and not is_target_item:
				drop_mode_flags = DROP_MODE_DISABLED
				return false
	
	var section: int = get_drop_section_at_position(at_position)
	
	if data["item"] == null:
		drop_mode_flags = DROP_MODE_INBETWEEN
	elif data["type"] == ItemType.RECIPE_ITEM:
		drop_mode_flags = DROP_MODE_INBETWEEN
	else:
		if is_target_item:
			drop_mode_flags = DROP_MODE_ON_ITEM
		else: # Target is data
			if target_item.get_metadata(1) == TYPE_DICTIONARY:
				drop_mode_flags = DROP_MODE_ON_ITEM + DROP_MODE_INBETWEEN
			else:
				drop_mode_flags = DROP_MODE_INBETWEEN
	
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var drop_target: TreeItem = get_item_at_position(at_position)
	var dropped_item: TreeItem = _create_item(data["id"], 1, {}) if data["item"] == null else data["item"]
	var from_this_tree: bool = _is_item_local(dropped_item)
	var new_parent: TreeItem = null
	var new_index: int = -1
	
	if drop_target == null:
		new_parent = get_root()
		new_index = -1
	else: # Dropping on data or on recipe
		var drop_position: int = get_drop_section_at_position(at_position)
		# We're droping an item, can only exist in root.
		if data["type"] == ItemType.RECIPE_ITEM:
			new_parent = get_root()
			match drop_position:
				-1: # Above
					new_index = drop_target.get_index()
				_: # Below and fallback.
					new_index = drop_target.get_index() + 1
		else: # We're dropping data. Can exist inside items and dictionary data.
			var same_parent_shift: bool = from_this_tree and\
					dropped_item.get_parent() == drop_target.get_parent() and\
					dropped_item.get_index() < drop_target.get_index()
			match drop_position:
				-1: # Above (Dropping on data)
					new_parent = drop_target.get_parent()
					new_index = drop_target.get_index()
					if same_parent_shift:
						new_index -= 1
				0: # On (Droping on dictionary or on item)
					new_index = -1
					new_parent = drop_target
				1: # Below (Dropping on data)
					if drop_target.get_metadata(1) == TYPE_DICTIONARY and not drop_target.collapsed and 0 < drop_target.get_child_count():
						new_index = 0
						new_parent = drop_target
					else:
						new_parent = drop_target.get_parent()
						new_index = drop_target.get_index()
						if not same_parent_shift:
							new_index += 1
	
	# Recipe items can be duplicate, but not data.
	var data_id: String = dropped_item.get_text(0)
	if data["type"] == ItemType.ITEM_DATA and _tree_has_id(new_parent, data_id):
		data_id = validate_id(new_parent, data_id, dropped_item)
	var sort_item: TreeItem = null
	
	if from_this_tree: # We move the data.
		if dropped_item.get_parent() != new_parent:
			dropped_item.get_parent().remove_child(dropped_item)
			new_parent.add_child(dropped_item)
		
		sort_item = dropped_item
	else: # We dragged from the other tree. Copy the data.
		if data["type"] == ItemType.RECIPE_ITEM:
			var item_metadata: Dictionary = {}
			for meta in dropped_item.get_children():
				item_metadata[meta.get_text(0)] = get_data_cell_data(meta)
			sort_item = _create_item(
					dropped_item.get_metadata(0)["id"],
					dropped_item.get_range(1),
					item_metadata)
		else: # It's data
			var cell_data: Variant = get_data_cell_data(dropped_item)
			sort_item = _add_data_on(
					new_parent,
					cell_data,
					dropped_item.get_text(0))
			
	if sort_item != new_parent.get_child(new_index):
		if new_index <= -1:
			sort_item.move_after(new_parent.get_child(-1))
		elif new_index == 0:
			sort_item.move_before(new_parent.get_first_child())
		else:
			sort_item.move_after(new_parent.get_child(new_index - 1))
	
	if data["type"] == ItemType.ITEM_DATA:
		sort_item.set_text(0, data_id)


func _get_drag_data(at_position: Vector2) -> Variant:
	var selected: TreeItem = get_item_at_position(at_position)
	if selected == null:
		return null
	
	var type: int = ItemType.RECIPE_ITEM
	
	if selected.get_parent() != get_root():
		type = ItemType.ITEM_DATA
	
	var data: Dictionary = {
		"type": type,
		"item": selected}
	
	var label: Label = Label.new()
	if _is_item(selected):
		label.text = "   " + selected.get_text(0) + " x " + str(int(selected.get_range(1)))
	else:
		label.text = "   " + selected.get_text(0)
	set_drag_preview(label)
	return data


func _tree_has_id(item: TreeItem, id: String) -> bool:
	for tree in item.get_children():
		if tree.get_text(0) == id:
			return true
	return false


func _is_item(item: TreeItem) -> bool:
	if item == null:
		return false
	elif item.get_tree() == null:
		return false
	else:
		return item.get_parent() == item.get_tree().get_root()


func _is_item_local(item: TreeItem) -> bool:
	if item == null:
		return false
	
	var current_level: TreeItem = item
	var root: TreeItem = get_root()
	
	while current_level != null:
		if current_level == root:
			return true
		current_level = current_level.get_parent()
	
	return false


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == ButtonID.ERASE:
		var is_item: bool = item.get_parent() == get_root()
		item.free()
		items_changed.emit()
	elif id == ButtonID.ADD_DATA:
		data_item = item
		compact_menu.position = DisplayServer.mouse_get_position()
		compact_menu.popup()


func _on_add_data_menu_id_pressed(id: int) -> void:
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
	
	_add_data_on(data_item, data_type, data_name)
	
	data_item = null
	
	items_changed.emit()


func _get_item_id_from_data_tree(item: TreeItem) -> StringName:
	if item == null or item.get_parent() == get_root():
		return &""
	
	var root: TreeItem = get_root()
	var current: TreeItem = item
	
	while current != null:
		if current.get_parent() == root:
			return current.get_metadata(0)["id"]
		current = current.get_parent()
	
	return &""


func _add_data_on(item: TreeItem, data: Variant, data_name: String) -> TreeItem:
	var new_data: TreeItem = item.create_child()
	var data_type: int = typeof(data)
	new_data.set_text(0, data_name)
	
	match data_type:
		TYPE_INT:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(1, -9999, 9999, 1.0)
			new_data.set_range(1, data)
			new_data.set_icon(0, get_theme_icon("int", "EditorIcons"))
			new_data.set_editable(1, true)
			new_data.set_metadata(1, TYPE_INT)
		TYPE_FLOAT:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_data.set_range_config(1, -9999, 9999, 0.01)
			new_data.set_range(1, data)
			new_data.set_icon(0, get_theme_icon("float", "EditorIcons"))
			new_data.set_editable(1, true)
			new_data.set_metadata(1, TYPE_FLOAT)
		TYPE_BOOL:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			new_data.set_checked(1, data)
			new_data.set_text(1, "Enabled")
			new_data.set_icon(0, get_theme_icon("bool", "EditorIcons"))
			new_data.set_editable(1, true)
			new_data.set_metadata(1, TYPE_BOOL)
		TYPE_STRING:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_data.set_text(1, data)
			new_data.set_icon(0, get_theme_icon("String", "EditorIcons"))
			new_data.set_editable(1, true)
			new_data.set_metadata(1, TYPE_STRING)
		TYPE_DICTIONARY:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_data.set_text(1, "")
			new_data.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
			new_data.set_editable(1, false)
			new_data.set_metadata(1, TYPE_DICTIONARY)
			for data_key in data.keys():
				match typeof(data_key):
					TYPE_STRING, TYPE_STRING_NAME:
						_add_data_on(new_data, data[data_key], data_key)
					_:
						NFPluginGameHandler._log_msg(
						"depot - editor",
						"Trying to add data on ingredient '%s' on data '%s' with incompatible key. Skipping" % [_get_item_id_from_data_tree(new_data), data_name],
						NFPluginGameHandler._LogLevel.WARNING)
		_:
			new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_data.set_text(1, "Data")
			new_data.set_metadata(0, {"data": data})
			new_data.set_editable(1, false)
			new_data.set_metadata(1, TYPE_NIL)
	
	new_data.set_editable(0, true)
	
	if data_type == TYPE_DICTIONARY:
		new_data.add_button(
				1,
				load("res://addons/nexus_forge/icons/add_variable_icon.svg"),
				ButtonID.ADD_DATA,
				false,
				"Add Data")
	new_data.add_button(
			1,
			get_theme_icon("Remove", "EditorIcons"),
			ButtonID.ERASE,
			false,
			"Delete Data")
	
	return new_data


func get_recipe_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	
	for item in get_root().get_children():
		var data: Dictionary[String, Variant] = {}
		for data_child in item.get_children():
			data[data_child.get_text(0)] = get_data_cell_data(data_child)
		items.append({
				"item_id": StringName(item.get_text(0)),
				"amount": int(item.get_range(1)),
				"data": data})
	return items


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


func add_item(item_id: StringName, input_amount: int = 1, data: Dictionary = {}, select: bool = false, first_load: bool = false) -> void:
	var new_item: TreeItem = _create_item(item_id, input_amount, data)
	
	if select:
		new_item.select(0)


func _create_item(item_id: StringName, input_amount: int, data: Dictionary) -> TreeItem:
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, String(item_id))
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_range_config(1, 1, 9999, 1.0)
	new_item.set_range(1, input_amount)
	new_item.set_editable(1, true)
	new_item.set_metadata(0, {"id": item_id})
	
	for data_key in data:
		match typeof(data_key):
			TYPE_STRING, TYPE_STRING_NAME:
				_add_data_on(new_item, data[data_key], data_key)
			_:
				NFPluginGameHandler._log_msg(
						"depot - editor",
						"Trying to add data to ingredient '%s' with incompatible key. Skipping" % item_id,
						NFPluginGameHandler._LogLevel.WARNING)
	
	new_item.add_button(
			1,
			load("res://addons/nexus_forge/icons/add_variable_icon.svg"),
			ButtonID.ADD_DATA,
			false,
			"Add Metadata")
	new_item.add_button(
			1,
			get_theme_icon("Remove", "EditorIcons"),
			ButtonID.ERASE,
			false,
			"Remove Item")
	
	return new_item


func remove_item(id: StringName) -> void:
	for ingredient in get_root().get_children():
		if ingredient.get_metadata(0)["id"] == id:
			ingredient.free()


func change_item_id(from: StringName, to: StringName) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0) == from:
			item.set_text(0, String(to))
			item.set_metadata(0, to)


func clear_items() -> void:
	clear()
	create_item()


func validate_id(on_tree: TreeItem, desired_id: String, skip_item: TreeItem = null) -> String:
	var used_ids: Dictionary[String, Variant] = {}
	
	for tree_item in on_tree.get_children():
		if tree_item == skip_item:
			continue
		used_ids[tree_item.get_text(0)] = null
	
	var trailing_data: Dictionary = StringUtils.get_trailing_integer(desired_id)
	var iteration: int = trailing_data["integer"]
	var base: String = desired_id
	var modified: String = desired_id
	if trailing_data["has_integer"]:
		base = base.trim_suffix(str(iteration))
	
	while used_ids.has(modified):
		iteration += 1
		modified = base + str(iteration)
	
	return modified
