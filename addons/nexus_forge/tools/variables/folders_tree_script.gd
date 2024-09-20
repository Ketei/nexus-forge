extends Tree


signal delete_folder_request(folder_item: TreeItem)
signal something_changed

const FOLDER_ICON = preload("res://addons/nexus_forge/common_icons/folder_icon.svg")
const NEW_FOLDER_ICON = preload("res://addons/nexus_forge/tools/variables/icons/new_folder.svg")
const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")

const CREATE_FOLDER_ID: int = 0
const DELETE_FOLDER_ID: int = 1

var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	set_column_expand(0, false)
	set_column_expand(1, true)
	
	item_edited.connect(on_folder_edited)
	button_clicked.connect(on_item_button_pressed)


func set_folder_name_data(folder_tree: TreeItem, new_name: String) -> void:
	folder_tree.set_metadata(1, new_name)


func create_root_folder() -> void:
	create_folder(root_tree)


func create_folder(target_tree: TreeItem, folder_name: String = "") -> TreeItem:
	var new_folder: TreeItem = create_item(target_tree)
	var new_name: String = validate_folder_name(target_tree, folder_name, new_folder)
	
	new_folder.set_metadata(0, get_new_folder_structure())
	new_folder.set_metadata(1, new_name)
	
	new_folder.set_cell_mode(0, TreeItem.CELL_MODE_ICON)
	new_folder.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	
	new_folder.set_icon(0, FOLDER_ICON)
	new_folder.set_text(1, new_name)
	
	new_folder.add_button(1, NEW_FOLDER_ICON, 0, false, "Create Subfolder")
	new_folder.add_button(1, TRASH_BIN, 1, false, "Delete Folder")
	
	new_folder.set_editable(0, false)
	new_folder.set_editable(1, true)
	
	something_changed.emit()
	
	return new_folder


func load_folder_data(folder_name: String, top_folder_dict: Dictionary, _folder := root_tree) -> void:
	# {"variables": {}, "subfolders": {}} on loop
	var folder_tree := create_folder(_folder, folder_name)
	
	for variable in top_folder_dict["variables"]:
		var metadata: Dictionary = {
			"name": variable,
			"type": typeof(top_folder_dict["variables"][variable]),
			"variable": top_folder_dict["variables"][variable]}
		
		folder_tree.get_metadata(0)["variables"].append(metadata)
	
	for subfolder in top_folder_dict["subfolders"]:
		load_folder_data(subfolder, top_folder_dict["subfolders"][subfolder], folder_tree)


func on_item_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if column != 1:
		return
	
	match id:
		CREATE_FOLDER_ID:
			create_folder(item)
		DELETE_FOLDER_ID:
			delete_folder_request.emit(item)


func on_folder_edited() -> void:
	var item_edited: TreeItem = get_edited()
	var current_name: String = item_edited.get_text(1)
	var prev_name: String = item_edited.get_metadata(1)
	
	something_changed.emit()
	
	if prev_name == current_name:
		return
	
	var tweaked_name: String = validate_folder_name(item_edited.get_parent(), current_name, item_edited)
	
	if tweaked_name != current_name:
		item_edited.set_text(1, tweaked_name)
	item_edited.set_metadata(1, tweaked_name)


func get_new_folder_structure() -> Dictionary:
	return {"variables": []}


func validate_folder_name(parent_tree: TreeItem, folder_name: String, skip_tree: TreeItem) -> String:
	var ideal_name: String = "new_folder" if folder_name.is_empty() else folder_name
	var tweaked_name: String = ideal_name
	var iteration: int = 1
	var total_folders: Array[TreeItem] = parent_tree.get_children()
	
	while has_folder(total_folders, tweaked_name, skip_tree):
		tweaked_name = str(ideal_name, "_", iteration)
		iteration += 1
	
	return tweaked_name


func has_folder(in_folders:Array[TreeItem], folder_name: String, exception: TreeItem) -> bool:
	for child in in_folders:
		if child == exception:
			continue
		if child.get_text(1) == folder_name:
			return true
	return false


func get_path_to_folder(folder: TreeItem) -> String:
	var folder_path: Array[String] = []
	var folder_step: TreeItem = folder
	
	while folder_step != root_tree:
		folder_path.push_front(folder_step.get_text(1))
		folder_step = folder_step.get_parent()
	
	return "/".join(folder_path)


func search_for_folder(string_to_search: String, _starting_tree := root_tree) -> void:
	for folder in _starting_tree.get_children():
		if folder.get_text(1).contains(string_to_search):
			folder.visible = true
			if not folder.get_parent().visible:
				folder.get_parent().visible = true
		else:
			folder.visible = false
		search_for_folder(string_to_search, folder)


func show_all_folders(_folder_root := root_tree) -> void:
	for folder in _folder_root.get_children():
		folder.visible = true
		show_all_folders(folder)


func get_folder_items() -> Array[TreeItem]:
	return root_tree.get_children()


func get_full_variables_dict(_folder_item := root_tree) -> Dictionary:
	var folder_dict: Dictionary = {}
	
	if _folder_item != root_tree:
		folder_dict["variables"] = {}
		folder_dict["subfolders"] = {}
	
		for variable in _folder_item.get_metadata(0)["variables"]:
			folder_dict["variables"][variable["name"]] = variable["variable"]
		
		for subfolder in _folder_item.get_children():
			folder_dict["subfolders"][subfolder.get_text(1)] = get_full_variables_dict(subfolder)
	else:
		for subfolder in _folder_item.get_children():
			folder_dict[subfolder.get_text(1)] = get_full_variables_dict(subfolder)
	
	return folder_dict
