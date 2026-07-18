@tool
extends Tree


signal something_changed
signal folder_renamed(from: String, to: String)
signal folder_selected(path_to_folder: String)
signal folder_moved(original_path: String, target_folder: String)
signal variable_dropped(var_folder: String, variable: String, new_folder: String)
signal folder_created(path_to_folder: String)
signal folder_deleted(path_to_folder: String)


const CREATE_FOLDER_ID: int = 0
const DELETE_FOLDER_ID: int = 1

@export var default_folder_name: String = "new_folder"


func ready_plugin() -> void:
	create_item()
	
	item_edited.connect(_on_folder_edited)
	button_clicked.connect(_on_item_button_pressed, CONNECT_DEFERRED)
	item_selected.connect(_on_item_selected, CONNECT_DEFERRED)


func _get_drag_data(at_position: Vector2) -> Variant:
	var item: TreeItem = get_item_at_position(at_position)
	if item == null:
		return null
	var preview: Label = Label.new()
	preview.text = "  Folder: " + item.get_text(0)
	set_drag_preview(preview)
	return {"type": "blackboard_item", "class": "folder", "original_path": get_path_to_folder(item), "item": item}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has_all(["class", "type", "item"]) or data["type"] != "blackboard_item":
		return false
	
	drop_mode_flags = DROP_MODE_ON_ITEM
	if data["class"] == "folder":
		drop_mode_flags += DROP_MODE_INBETWEEN
	
	if get_drop_section_at_position(at_position) == -100:
		return true
	
	var target_folder: TreeItem = get_item_at_position(at_position)
	
	if data["class"] == "folder":
		return not _is_item_child_of(target_folder, data["item"])
	else:
		if target_folder != null:
			var folder_path: String = get_path_to_folder(target_folder)
			return data["folder"] != folder_path
			
		return target_folder != null


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item: TreeItem = get_item_at_position(at_position)
	var section: int = get_drop_section_at_position(at_position)
	
	if data["class"] == "folder":
		if item == null:
			if data["item"].get_parent() == get_root():
				if data["item"].get_index() < get_root().get_child_count() - 1:
					data["item"].move_after(get_root().get_child(-1))
				return
			else:
				data["item"].move_after(get_root().get_child(-1))
				folder_moved.emit(
					data["original_path"],
					data["item"].get_text(0))
				return
		
		var target: String = ""
		
		if section == 0:
			target = get_path_to_folder(item)
		elif section == 1: # Below
			if not item.collapsed and 0 < item.get_child_count():
				target = get_path_to_folder(item)
			else:
				target = get_path_to_folder(item.get_parent())
		else:
			target = get_path_to_folder(item.get_parent())
		
		if target == get_path_to_folder(data["item"].get_parent()):
			var parent: TreeItem = data["item"].get_parent()
			if section == -1:
				data["item"].move_before(item)
			elif section == 1:
				data["item"].move_after(item)
		else:
			if section == 0:
				data["item"].get_parent().remove_child(data["item"])
				item.add_child(data["item"])
			elif section == -1:
				data["item"].move_before(item)
			else:
				if not item.collapsed and 0 < item.get_child_count():
					data["item"].move_before(item.get_first_child())
				else:
					data["item"].move_after(item)
			
			if not target.is_empty():
				target += "/"
			
			folder_moved.emit(
					data["original_path"],
					target + data["item"].get_text(0))
	else:
		variable_dropped.emit(
			data["folder"],
			data["item"].get_text(0),
			get_path_to_folder(item))


func _is_item_child_of(item: TreeItem, parent: TreeItem) -> bool:
	if item == parent:
		return true
	
	var next_parent: TreeItem = item.get_parent()
	
	while next_parent != null:
		if next_parent == parent:
			return true
		next_parent = next_parent.get_parent()
	return false


# Creates a folder recursively.
func create_folder(path: String, expand: bool = true, select: bool = false) -> void:
	var path_parts: PackedStringArray = path.simplify_path().split("/")
	
	if path_parts.is_empty():
		return
	
	var folder_name: String = path_parts[-1]
	var current_level: TreeItem = get_root()
	var create: bool = true
	
	for folder in path_parts.slice(0, -1):
		var no_match: bool = true
		for folder_tree in current_level.get_children():
			if folder_tree.get_metadata(0)["id"] == folder:
				current_level = folder_tree
				break
		if no_match:
			current_level = _create_folder(current_level, folder, expand, false)
	
	for tree in current_level.get_children():
		if tree.get_metadata(0)["id"] == folder_name:
			create = false
			tree.collapsed = not expand
			if select:
				tree.select(0)
			break
	
	if create:
		_create_folder(current_level, folder_name, expand, select)


# Removes a folder and all it's subfolders along with it.
func remove_folder(path: String) -> void:
	var path_parts: PackedStringArray = path.simplify_path().split("/")
	
	if path_parts.is_empty():
		return
	
	var folder_name: String = path_parts[-1]
	var current_level: TreeItem = get_root()
	var erase: bool = true
	
	for path_slice in path_parts.slice(0, -1):
		var found: bool = false
		for item in current_level.get_children():
			if item.get_metadata(0)["id"] == path_slice:
				found = true
				current_level = item
				break
		if not found:
			erase = false
			break
	
	if erase:
		current_level.free()


# Renames a folder
func rename_folder(path: String, to: String) -> bool:
	var folder_parts: PackedStringArray = path.simplify_path().split("/")
	if folder_parts.is_empty():
		return false
	var target_folder: String = folder_parts[0]
	var current_folder: TreeItem = get_root()
	var rename: bool = true
	
	for slice in folder_parts:
		var found: bool = false
		for tree in current_folder.get_children():
			if tree.get_metadata(0)["id"] == slice:
				current_folder = tree
				found = true
				break
		if not found:
			rename = false
			break
	
	if not rename:
		return false
	
	var valid_name: String = validate_folder_name(current_folder.get_parent(), to, current_folder)
	var success: bool = true
	
	if valid_name != to:
		NFPluginGameHandler._log_msg(
				"blackboard - editor",
				"Tried to rename folder to '%s' but name is already taken or invalid. Using '%s' instead.",
				NFPluginGameHandler._LogLevel.WARNING)
		to = valid_name
		success = false
	
	current_folder.set_text(0, to)
	current_folder.get_metadata(0)["id"] = to
	return success


func move_folder(from: String, to: String) -> bool:
	var target: TreeItem = null
	var new_parent: TreeItem = null
	var current_folder: TreeItem = get_root()
	
	var to_slice: PackedStringArray = to.split("/", false)
	var from_slice: PackedStringArray = from.split("/", false)
	
	if to_slice.is_empty() or from_slice.is_empty():
		return false
	
	var new_name: String = to_slice[-1]
	
	for slice in to_slice.slice(0, -1):
		var found: bool = false
		for item in current_folder.get_children():
			if item.get_metadata(0)["id"] == slice:
				current_folder = item
				found = true
				break
		if not found:
			return false
	
	new_parent = current_folder
	current_folder = get_root()
	
	for slice in from_slice:
		var found: bool = false
		for item in current_folder.get_children():
			if item.get_metadata(0)["id"] == slice:
				current_folder = item
				found = true
				break
		if not found:
			return false
	
	target = current_folder
	
	if _has_folder(new_parent, new_name, target) or validate_folder_name(new_parent, new_name, target) != new_name:
		return false
	
	target.set_text(0, new_name)
	target.get_metadata(0)["id"] = new_name
	
	if target.get_parent() != new_parent:
		target.get_parent().remove_child(target)
		new_parent.add_child(target)
		sort_single_item(target)
	
	return true


func create_root_folder() -> String:
	return _create_folder(get_root()).get_text(0)


func select_folder_no_signal(folder_path: String) -> void:
	var path_names: PackedStringArray = folder_path.split("/", false)
	var current_folder: TreeItem = get_root()
	
	item_selected.disconnect(_on_item_selected)
	
	var folder_found: bool = false
	for level in path_names:
		folder_found = false
		for child in current_folder.get_children():
			if child.get_metadata(0)["id"] == level:
				current_folder = child
				folder_found = true
				break
		if not folder_found:
			item_selected.connect(_on_item_selected)
			return
	
	if current_folder != get_root():
		current_folder.select(0)
	
	item_selected.connect(_on_item_selected)


func clear_folders() -> void:
	for folder in get_root().get_children():
		folder.free()


func _create_folder(target_tree: TreeItem = null, folder_name: String = default_folder_name, expand: bool = false, select: bool = false) -> TreeItem:
	if target_tree == null:
		target_tree = get_root()
	
	var new_name: String = validate_folder_name(target_tree, folder_name)
	var new_folder: TreeItem = create_item(target_tree)
	
	new_folder.set_metadata(0, {"id": new_name})
	
	new_folder.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	
	new_folder.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
	new_folder.set_text(0, new_name)
	
	new_folder.add_button(0, get_theme_icon("FolderCreate", "EditorIcons"), 0, false, "Create Subfolder")
	new_folder.add_button(0, get_theme_icon("Remove", "EditorIcons"), 1, false, "Delete Folder")
	
	new_folder.set_editable(0, true)
	
	if expand and target_tree.collapsed:
		target_tree.collapsed = false
	
	if select:
		new_folder.select(0)
		ensure_cursor_is_visible()
	
	return new_folder


func load_folder_structure(folder_structure: Dictionary, _target_tree: TreeItem = null) -> void:
	if _target_tree == null: # The target is a top-level folder.
		_target_tree = get_root()
	
	for folder_name: String in folder_structure.keys():
	 	# We create the top folder
		var new_folder: TreeItem = _create_folder(_target_tree, folder_name)
		# Call this to ceate subfolders with the top folder as target
		load_folder_structure(
				folder_structure[folder_name],
				new_folder)


func _on_item_button_pressed(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	match id:
		CREATE_FOLDER_ID:
			folder_created.emit(get_path_to_folder(_create_folder(item, "", true, true)))
		DELETE_FOLDER_ID:
			var confirmation: ConfirmationDialog = load("res://addons/nexus_forge/dialogs/confirmation.gd").new()
			confirmation.title = "Erase folder..."
			confirmation.dialog_text = "Erase " + item.get_text(0) + " and all subfolders?"
			confirmation.ok_button_text = "Erase"
			confirmation.cancel_button_text = "Cancel"
			confirmation.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
			add_child(confirmation)
			confirmation.show()
			var erase: bool = await confirmation.dialog_finished
			if not erase:
				confirmation.queue_free()
				return
			var path: String = get_path_to_folder(item)
			confirmation.queue_free()
			item.free()
			folder_deleted.emit(path)
	something_changed.emit()


func _on_folder_edited() -> void:
	var item_edited: TreeItem = get_edited()
	
	item_edited.set_text(0, item_edited.get_text(0).strip_edges())
	
	if item_edited.get_metadata(0)["id"] == item_edited.get_text(0):
		return
	
	var tweaked_name: String = validate_folder_name(item_edited.get_parent(), item_edited.get_text(0), item_edited)
	var prev_name: String = item_edited.get_metadata(0)["id"]
	var path_to: String = get_path_to_folder(item_edited.get_parent())
	
	item_edited.set_text(0, tweaked_name)
	item_edited.get_metadata(0)["id"] = tweaked_name
	
	folder_renamed.emit(
		path_to.path_join(prev_name), path_to.path_join(tweaked_name))
	something_changed.emit()


func collapse_folders(collapsed: bool = true) -> void:
	for top_folder in get_root().get_children():
		top_folder.set_collapsed_recursive(collapsed)


func validate_folder_name(parent_tree: TreeItem, folder_name: String = default_folder_name, skip_tree: TreeItem = null) -> String:
	if folder_name.strip_edges().is_empty():
		folder_name = "new_folder"
	var tweaked_name: String = folder_name.replace("/", "_")
	var trailing_int: Dictionary = StringUtils.get_trailing_integer(tweaked_name)
	var iteration: int = trailing_int["integer"]
	var modified_name = tweaked_name
	if trailing_int["has_integer"]:
		tweaked_name = tweaked_name.trim_suffix(str(iteration))
	var total_folders: Array[TreeItem] = parent_tree.get_children()
	
	while _has_folder(parent_tree, modified_name, skip_tree):
		iteration += 1
		modified_name = str(tweaked_name, "_", iteration)
	
	return tweaked_name


func _has_folder(parent_folder: TreeItem, folder_name: String, exception: TreeItem) -> bool:
	for subfolder in parent_folder.get_children():
		if subfolder == exception:
			continue
		if subfolder.get_metadata(0)["id"] == folder_name:
			return true
	return false


func has_folder(folder_path: String) -> bool:
	var slices: PackedStringArray = folder_path.split("/", false)
	
	if slices.is_empty():
		return false
	
	var current_folder: TreeItem = get_root()
	
	for slice in slices:
		var found = false
		for item in current_folder.get_children():
			if item.get_metadata(0)["id"] == slice:
				found = true
				current_folder = item
				break
		if not found:
			return false
	
	return true


func get_path_to_folder(folder: TreeItem) -> String:
	var folder_path: Array[String] = []
	var folder_step: TreeItem = folder
	var root: TreeItem = get_root()
	
	while folder_step != root and folder_step != null: # Prevent going to a level we're not supposed to
		folder_path.append(folder_step.get_text(0))
		folder_step = folder_step.get_parent()
	
	folder_path.reverse()
	return StringUtils.make_path(folder_path)


func get_state_path_to_folder(folder: TreeItem) -> String:
	var folder_path: Array[String] = []
	var folder_step: TreeItem = folder
	var root: TreeItem = get_root()
	
	while folder_step != root and folder_step != null: # Prevent going to a level we're not supposed to
		folder_path.append(folder_step.get_text(0))
		folder_step = folder_step.get_parent()
	
	folder_path.append("root")
	folder_path.reverse()
	return "/".join(folder_path)


func get_folder_state() -> Array[Dictionary]:
	var state: Array[Dictionary] = []
	var folders: Dictionary[String, TreeItem] = get_folder_items()
	for item_path in folders.keys():
		state.append({
			"path": item_path,
			"collapsed": folders[item_path].collapsed,
			"index": folders[item_path].get_index()})
	return state


func set_folder_state(state: Array[Dictionary]) -> void:
	var folders: Dictionary[String, TreeItem] = get_folder_items()
	var processed_items: Dictionary[String, Variant] = {}
	var indexes: Dictionary[String, int] = {}
	
	# We don't need a deep copy as we're only going to change the indexes
	var sorted_state: Array[Dictionary] = state.duplicate(false)
	sorted_state.sort_custom(_sort_custom_state_folders)
	
	for state_data in sorted_state:
		var index_path: String = state_data["path"].substr(0, state_data["path"].rfind("/"))
		if not indexes.has(index_path):
			indexes[index_path] = -1
		
		if not folders.has(state_data["path"]):
			continue
		
		processed_items[state_data["path"]] = null
		indexes[index_path] += 1
		
		var idx: int = indexes[index_path]
		var item: TreeItem = folders[state_data["path"]]
		
		if state_data.has("collapsed"):
			item.collapsed = state_data["collapsed"]
		
		if item.get_index() == idx: # We don't need to move
			continue
		
		if idx == 0:
			item.move_before(item.get_parent().get_first_child())
		else:
			item.move_after(item.get_parent().get_child(idx - 1))
	
	# Sorting last items
	for path in folders.keys():
		if processed_items.has(path):
			continue
		sort_single_item(folders[path])


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	
	for child in item.get_parent().get_children():
		if child == item:
			continue # We ignore the item we want to sort
		
		if item.get_text(0) < child.get_text(0):
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != item.get_parent().get_child_count() - 1:
			item.move_after(item.get_parent().get_child(-1))


func _sort_custom_state_folders(a: Dictionary, b: Dictionary) -> bool:
	var parent_a: String = a["path"].substr(0, a["path"].rfind("/"))
	var parent_b: String = b["path"].substr(0, b["path"].rfind("/"))
	if parent_a == parent_b:
		return a["index"] < b["index"]
	else:
		return a["path"] < b["path"]


func get_folder_items() -> Dictionary[String, TreeItem]:
	var items: Dictionary[String, TreeItem] = {}
	for top_item in get_root().get_children():
		items[get_state_path_to_folder(top_item)] = top_item
		_set_subfolder_items_of(top_item, items)
	return items


func _set_subfolder_items_of(folder: TreeItem, on: Dictionary[String, TreeItem]) -> void:
	for subfolder in folder.get_children():
		on[get_state_path_to_folder(subfolder)] = subfolder
		_set_subfolder_items_of(subfolder, on)


func search_for_folder(string_to_search: String, _starting_tree: TreeItem = get_root()) -> void:
	for folder in _starting_tree.get_children():
		if folder.get_text(0).containsn(string_to_search):
			folder.visible = true
			if not folder.get_parent().visible:
				folder.get_parent().visible = true
		else:
			folder.visible = false
		search_for_folder(string_to_search, folder)


func show_all_folders(_folder_root: TreeItem = get_root()) -> void:
	for folder in _folder_root.get_children():
		folder.visible = true
		show_all_folders(folder)


func _on_item_selected() -> void:
	folder_selected.emit(get_path_to_folder(get_selected()))


func set_folder_order(order: Dictionary) -> void:
	_set_order_of_folder(get_root(), order)


func _set_order_of_folder(folder: TreeItem, folder_structure: Dictionary) -> void:
	if folder_structure.has("folder"):
		var order: Array = folder_structure["order"]
		var items: Array[TreeItem] = folder.get_children()
		var items_size: int = items.size()
		
		if 1 < items_size:
			items.sort_custom(
					func(a:TreeItem,b:TreeItem):
							var idx_a: int = order.find(a.get_text(0))
							var idx_b: int = order.find(b.get_text(0))
							
							if idx_a == -1:
								return false
							elif idx_b == -1:
								return true
							else:
								return idx_a < idx_b)
			if items[0].get_index() != 0:
				items[0].move_before(folder.get_first_child())
			
			for item_idx in range(1, items_size):
				items[item_idx].move_after(items[item_idx - 1])
	
	for subfolder in folder.get_children():
		if folder_structure["subfolders"].has(subfolder.get_text(0)):
			_set_order_of_folder(subfolder, folder_structure["subfolders"][subfolder.get_text(0)])


func get_folder_order() -> Dictionary:
	if get_root() == null:
		return {"order": {}, "subfolders": Array([], TYPE_STRING, &"", null)}
	return _get_order_of_folder(get_root())


func _get_order_of_folder(folder: TreeItem) -> Dictionary:
	var order: Array[String] = []
	var subfolders: Dictionary = {}
	
	for item in folder.get_children():
		order.append(item.get_text(0))
		subfolders[item.get_text(0)] = _get_order_of_folder(item)
	
	return {"order": order, "subfolders": subfolders}
