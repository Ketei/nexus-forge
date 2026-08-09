@tool
extends Tree


signal ingredient_added(index: int)
signal ingredient_moved(from: int, to: int)
signal ingredient_erase_pressed(index: int, on_input: bool)
signal metadata_added(index: int, path: String, data: Variant)
signal metadata_moved(from_ingredient: int, to_ingredient: int, from_path: String, to_path: String, from_child_idx: int, to_child_idx: int)
signal metadata_removed(index: int, path: String, data: Variant)


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
	var original_index: int = dropped_item.get_index() if data["item"] != null else -1
	var from_this_tree: bool = _is_item_local(dropped_item)
	var origin_path: String = ""
	var origin_index: int = -1
	var new_parent: TreeItem = null
	var new_index: int = -1
	
	if data["item"] != null and data["type"] == ItemType.ITEM_DATA and from_this_tree:
		origin_path = get_metadata_path(data["item"])
		origin_index = get_metadata_ingredient(data["item"]).get_index()
	
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
			if new_index < sort_item.get_index():
				new_index -= 1
			sort_item.move_after(new_parent.get_child(new_index))
	
	if data["type"] == ItemType.ITEM_DATA:
		sort_item.set_text(0, data_id)
	
		var ingredient: TreeItem = get_metadata_ingredient(sort_item)
		var new_path: String = get_metadata_path(sort_item)
		
		if from_this_tree:
			metadata_moved.emit(
				origin_index,
				ingredient.get_index(),
				origin_path,
				new_path,
				original_index, # Where it was originally
				sort_item.get_index()) # The new index
		else:
			metadata_added.emit(
				ingredient.get_index(),
				new_path,
				get_data_cell_data(sort_item))
	else:
		if from_this_tree:
			ingredient_moved.emit(original_index, sort_item.get_index())
		else:
			ingredient_added.emit(sort_item.get_index())


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
	
	var is_item: bool = item.get_parent() == get_root()
	
	if id == ButtonID.ERASE:
		if is_item:
			ingredient_erase_pressed.emit(item.get_index(), recipe_mode == RecipeMode.INPUT)
		else:
			var ingredient: TreeItem = get_metadata_ingredient(item)
			var ing_index: int = ingredient.get_index()
			var meta_path: String = get_metadata_path(item)
			var metadata: Variant = get_data_cell_data(item)
			
			item.free()
			metadata_removed.emit(
					ing_index,
					meta_path,
					metadata)
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
	
	var ingredient: TreeItem = null
	
	if data_item.get_parent() == get_root():
		ingredient = data_item
	else:
		ingredient = get_metadata_ingredient(data_item)
	
	var meta_item: TreeItem = _add_data_on(data_item, data_type, data_name)
	
	var index: int = ingredient.get_index()
	var path: String = get_metadata_path(meta_item)
	var data: Variant = get_data_cell_data(meta_item)
	
	data_item = null
	
	metadata_added.emit(index, path, data)


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
	var item_data: Dictionary = {"name": data_name}
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
			item_data["data"] = data
			new_data.set_editable(1, false)
			new_data.set_metadata(1, TYPE_NIL)
	
	new_data.set_editable(0, true)
	new_data.set_metadata(0, item_data)
	
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


func add_item(item_id: StringName, input_amount: int = 1, data: Dictionary = {}) -> void:
	_create_item(item_id, input_amount, data)


func _create_item(item_id: StringName, input_amount: int, data: Dictionary, index: int = -1) -> TreeItem:
	if index != -1:
		var child_count: int = get_root().get_child_count()
		index = clampi(index, -child_count, child_count - 1)
	
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
	
	if index != -1:
		if get_root().get_child(index) != new_item:
			if index == 0:
				new_item.move_before(get_root().get_first_child())
			else:
				var target_index: int = index
				if 0 < new_item.get_index():
					target_index -= 1
				
				new_item.move_after(get_root().get_child(target_index))
	
	return new_item


func remove_item(id: StringName) -> void:
	for ingredient in get_root().get_children():
		if ingredient.get_metadata(0)["id"] == id:
			ingredient.free()


func remove_ingredient(idx: int) -> void:
	if idx < 0 or get_root().get_child_count() <= idx:
		return
	get_root().get_child(idx).free()


func move_ingredient(from: int, to: int) -> void:
	var root: TreeItem = get_root()
	if from == to:
		return
	elif from < 0 or root.get_child_count() <= from:
		return
	elif to < 0 or root.get_child_count() <= to:
		return
	
	var target: TreeItem = root.get_child(from)
	
	if to == 0:
		target.move_before(root.get_first_child())
	else:
		target.move_after(root.get_child(to - 1))


func add_metadata(on: int, path: String, data: Variant) -> void:
	if path.is_empty() or typeof(data) == TYPE_NIL:
		return
	
	var item: TreeItem = get_root().get_child(on)
	
	if item == null:
		return
	
	var slices: PackedStringArray = path.split("/", false)
	var var_name: String = slices[-1]
	var current_level: TreeItem = item
	
	for path_slice in slices.slice(0, -1):
		var found: bool = false
		for data_tree in current_level.get_children():
			if data_tree.get_text(0) == path_slice:
				current_level = data_tree
				found = true
				break
		if not found:
			return
	
	_add_data_on(current_level, data, var_name)


func remove_metadata(on: int, path: String) -> void:
	if path.is_empty():
		return
	
	var item: TreeItem = get_root().get_child(on)
	
	if item == null:
		return
	
	var slices: PackedStringArray = path.split("/", false)
	var var_name: String = slices[-1]
	var current_level: TreeItem = item
	
	for path_slice in slices.slice(0, -1):
		var found: bool = false
		for data_tree in current_level.get_children():
			if data_tree.get_text(0) == path_slice:
				current_level = data_tree
				found = true
				break
		if not found:
			return
	
	for data_tree in current_level.get_children():
		if data_tree.get_text(0) == var_name:
			data_tree.free()
			return


func move_metadata(from_ingredient: int, from_path: String, to_ingredient: int, to_path: String, to_index: int, cancel_if_collides: bool = true) -> void:
	if from_path.is_empty() or to_path.is_empty():
		return

	var root: TreeItem = get_root()
	var origin_item: TreeItem = root.get_child(from_ingredient)
	var target_item: TreeItem = root.get_child(to_ingredient)

	if origin_item == null or target_item == null:
		return

	var to_slices: PackedStringArray = to_path.split("/", false)
	var from_slices: PackedStringArray = from_path.split("/", false)
	var target_name: String = to_slices[-1]

	var origin_tree: TreeItem = null
	var target_parent: TreeItem = null
	var current_level: TreeItem = origin_item

	# 1. Find the origin item
	for slice in from_slices:
		var found: bool = false
		for data_tree in current_level.get_children():
			if data_tree.get_text(0) == slice:
				found = true
				current_level = data_tree
				break
		if not found:
			return
  
	origin_tree = current_level
	current_level = target_item

	# 2. Find the target parent
	for slice in to_slices.slice(0, -1):
		var found: bool = false
		for data_tree in current_level.get_children():
			if data_tree.get_text(0) == slice:
				found = true
				current_level = data_tree
				break
		if not found:
			return
			
	target_parent = current_level

	# 3. Check for collisions (ignoring the item itself)
	var collides: bool = false
	for data_tree in target_parent.get_children():
		if data_tree != origin_tree and data_tree.get_text(0) == target_name:
			collides = true
			break

	if cancel_if_collides and collides:
		return
	elif collides:
		var used_names: Dictionary[String, Variant] = {}
		for data_tree in target_parent.get_children():
			if data_tree != origin_tree:
				used_names[data_tree.get_text(0)] = null

		var base: String = target_name
		var modified: String = target_name
		var trailing_data: Dictionary = StringUtils.get_trailing_integer(target_name)
		var iteration: int = trailing_data["integer"]
		if trailing_data["has_integer"]:
			base = base.trim_suffix(str(iteration))
		
		while used_names.has(modified):
			iteration += 1
			modified = base + str(iteration)
	
		target_name = modified
	
	# 4. Reparent if necessary
	if origin_tree.get_parent() != target_parent:
		origin_tree.get_parent().remove_child(origin_tree)
		target_parent.add_child(origin_tree)
	
	var total_children: int = target_parent.get_child_count()
	var clamped_index: int = clampi(to_index, -total_children, total_children - 1)
	var valid_to_idx: int = wrapi(clamped_index, 0, total_children)
	
	# 5. Apply Visual Sorting
	if origin_tree.get_index() != valid_to_idx:
		if valid_to_idx == 0:
			origin_tree.move_before(target_parent.get_first_child())
		else:
			if valid_to_idx < origin_tree.get_index(): # Account for index shifting
				valid_to_idx -= 1
			
			origin_tree.move_after(target_parent.get_child(valid_to_idx))
	
	# 6. Apply new name
	origin_tree.set_text(0, target_name)
	origin_tree.get_metadata(0)["name"] = target_name


func get_ingredient_data(index: int) -> Dictionary:
	var item: TreeItem = get_root().get_child(index)
	
	if item == null:
		return {}
	
	var metadata: Dictionary[String, Variant] = {}
	
	for meta in item.get_children():
		metadata[meta.get_text(0)] = get_data_cell_data(meta)
	
	var data: Dictionary = {
		"index": index,
		"item_id": item.get_metadata(0)["id"],
		"item_count": int(item.get_range(1)),
		"metadata": metadata}
	
	return data


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


func get_metadata_ingredient(metadata: TreeItem) -> TreeItem:
	var root: TreeItem = get_root()
	var current_item: TreeItem = metadata
	while current_item.get_parent() != root and current_item != null:
		current_item = current_item.get_parent()
	return current_item


func get_metadata_path(metadata: TreeItem) -> String:
	var parts: Array[String] = []
	var current_item: TreeItem = metadata
	var root: TreeItem = get_root()
	
	while current_item.get_parent() != root and current_item != null:
		parts.append(current_item.get_text(0))
		current_item = current_item.get_parent()
	
	parts.reverse()
	
	return StringUtils.make_path(parts)
