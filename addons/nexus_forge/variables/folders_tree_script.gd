@tool
extends Tree


signal something_changed
signal folder_renamed(from: String, to: String)
signal folder_selected(path_to_folder: String)
signal folder_deleted(path_to_folder: String)
signal folder_created(path_to_folder: String)

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
	var tweaked_name: String = folder_name
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
func get_full_variables_dict(_folder_item: TreeItem = get_root()) -> Dictionary:
	var folder_dict: Dictionary = {}
	
	if _folder_item != get_root():
		folder_dict["variables"] = {}
		folder_dict["subfolders"] = {}
	
		for variable in _folder_item.get_metadata(0)["variables"]:
			folder_dict["variables"][variable["name"]] = variable["variable"]
		
		for subfolder in _folder_item.get_children():
			folder_dict["subfolders"][subfolder.get_text(0)] = get_full_variables_dict(subfolder)
	else:
		for subfolder in _folder_item.get_children():
			folder_dict[subfolder.get_text(0)] = get_full_variables_dict(subfolder)
	
	return folder_dict


func _on_item_selected() -> void:
	folder_selected.emit(get_path_to_folder(get_selected()))
