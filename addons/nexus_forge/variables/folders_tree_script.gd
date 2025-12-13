@tool
extends Tree


signal something_changed
signal folder_renamed(from: String, to: String)
signal folder_selected(path_to_folder: String)
signal folder_deleted(path_to_folder: String)
signal folder_created(path_to_folder: String)
signal folder_moved(original_path: String, target_folder: String)
signal variable_dropped(var_folder: String, variable: String, new_folder: String)

#var FOLDER_ICON = preload("res://addons/nexus_forge/common_icons/folder_icon.svg")
#var NEW_FOLDER_ICON = preload("res://addons/nexus_forge/common_icons/new_folder.svg")
#var TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")

const CREATE_FOLDER_ID: int = 0
const DELETE_FOLDER_ID: int = 1


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	#FOLDER_ICON = get_theme_icon("Folder", "EditorIcons")
	#NEW_FOLDER_ICON = get_theme_icon("FolderCreate", "EditorIcons")
	#TRASH_BIN = get_theme_icon("Remove", "EditorIcons")
	
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
			var parent_folder: TreeItem = item.get_parent()
			if not parent_folder.collapsed and 0 < parent_folder.get_child_count():
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
				if not parent.collapsed and 0 < parent.get_child_count():
					data["item"].move_before(parent.get_first_child())
				else:
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


func create_root_folder() -> String:
	return create_folder(get_root()).get_text(0)


func select_folder_no_signal(folder_path: String) -> void:
	var path_names: PackedStringArray = folder_path.split("/", false)
	var current_folder: TreeItem = get_root()
	
	item_selected.disconnect(_on_item_selected)
	
	var folder_found: bool = false
	for level in path_names:
		folder_found = false
		for child in current_folder.get_children():
			if child.get_text(0) == level:
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


func create_folder(target_tree: TreeItem = null, folder_name: String = "") -> TreeItem:
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
	
	return new_folder


func load_folder_structure(folder_structure: Dictionary, _target_tree: TreeItem = null) -> void:
	if _target_tree == null: # The target is a top-level folder.
		_target_tree = get_root()
	
	for folder_name: String in folder_structure.keys():
	 	# We create the top folder
		#var new_folder: TreeItem = _target_tree.create_child()
		var new_folder: TreeItem = create_folder(_target_tree, folder_name)
		#new_folder.set_text(0, folder_name) # Name the folder
		# Call this to ceate subfolders with the top folder as target
		load_folder_structure(
				folder_structure[folder_name],
				new_folder)


func _on_item_button_pressed(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	match id:
		CREATE_FOLDER_ID:
			folder_created.emit(get_path_to_folder(create_folder(item)))
		DELETE_FOLDER_ID:
			var confirmation := preload("res://addons/nexus_forge/dialogs/confirmation.gd").new()
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
	
	if item_edited.get_metadata(0)["id"] == item_edited.get_text(0):
		return
	
	var tweaked_name: String = validate_folder_name(item_edited.get_parent(), item_edited.get_text(0), item_edited)
	var prev_name: String = item_edited.get_metadata(0)["id"]
	var path_to: String = get_path_to_folder(item_edited.get_parent())
	
	if not path_to.is_empty():
		path_to += "/"
	
	item_edited.set_text(0, tweaked_name)
	item_edited.get_metadata(0)["id"] = tweaked_name
	
	folder_renamed.emit(
		path_to + prev_name, path_to + tweaked_name)
	something_changed.emit()


func collapse_folders(collapsed: bool = true) -> void:
	for top_folder in get_root().get_children():
		top_folder.set_collapsed_recursive(collapsed)


func validate_folder_name(parent_tree: TreeItem, folder_name: String = "new_folder", skip_tree: TreeItem = null) -> String:
	if folder_name.is_empty():
		folder_name = "new_folder"
	var tweaked_name: String = folder_name.replace("/", "_")
	var iteration: int = 1
	var total_folders: Array[TreeItem] = parent_tree.get_children()
	
	while has_folder(parent_tree, tweaked_name, skip_tree):
		tweaked_name = str(folder_name, "_", iteration)
		iteration += 1
	
	return tweaked_name


func has_folder(parent_folder: TreeItem, folder_name: String, exception: TreeItem) -> bool:
	for subfolder in parent_folder.get_children():
		if subfolder == exception:
			continue
		if subfolder.get_text(0) == folder_name:
			return true
	return false


func get_path_to_folder(folder: TreeItem) -> String:
	var folder_path: Array[String] = []
	var folder_step: TreeItem = folder
	var root: TreeItem = get_root()
	
	while folder_step != root: # Prevent going to a level we're not supposed to
		folder_path.append(folder_step.get_text(0))
		folder_step = folder_step.get_parent()
	
	folder_path.reverse()
	return "/".join(folder_path)


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


#func get_folder_items() -> Array[TreeItem]:
	#return root_tree.get_children()


# Should no longer be necessary
#func get_full_variables_dict(_folder_item: TreeItem = get_root()) -> Dictionary:
	#var folder_dict: Dictionary = {}
	#
	#if _folder_item != get_root():
		#folder_dict["variables"] = {}
		#folder_dict["subfolders"] = {}
	#
		#for variable in _folder_item.get_metadata(0)["variables"]:
			#folder_dict["variables"][variable["name"]] = variable["variable"]
		#
		#for subfolder in _folder_item.get_children():
			#folder_dict["subfolders"][subfolder.get_text(0)] = get_full_variables_dict(subfolder)
	#else:
		#for subfolder in _folder_item.get_children():
			#folder_dict[subfolder.get_text(0)] = get_full_variables_dict(subfolder)
	#
	#return folder_dict


func _on_item_selected() -> void:
	folder_selected.emit(get_path_to_folder(get_selected()))


func set_folder_order(order: Dictionary) -> void:
	_set_order_of_folder(get_root(), order)


func _set_order_of_folder(folder: TreeItem, folder_structure: Dictionary) -> void:
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
	return _get_order_of_folder(get_root())


func _get_order_of_folder(folder: TreeItem) -> Dictionary:
	var order: Array[String] = []
	var subfolders: Dictionary = {}
	
	for item in folder.get_children():
		order.append(item.get_text(0))
		subfolders[item.get_text(0)] = _get_order_of_folder(item)
	return {"order": order, "subfolders": subfolders}
