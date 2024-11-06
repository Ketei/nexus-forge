@tool
extends Control

const SAVE_FILE_ICON = preload("res://addons/nexus_forge/common_icons/save_file.svg")
const ADD_BOOL_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_bool.svg")
const ADD_FLOAT_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_float.svg")
const ADD_INT_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_int.svg")
const ADD_STRING_ICON = preload("res://addons/nexus_forge/tools/variables/icons/add_string.svg")
const NEW_FOLDER_ICON = preload("res://addons/nexus_forge/tools/variables/icons/new_folder.svg")

var _variables_resource: NFVariablesRes = null
var _switching_tree: bool = false
var _switching_variable: bool = false
var _current_folder: TreeItem = null:
	set(new_tree):
		_current_folder = new_tree
		var set_disabled: bool = _current_folder == null
		add_int_button.disabled = set_disabled
		add_float_button.disabled = set_disabled
		add_bool_button.disabled = set_disabled
		add_string_button.disabled = set_disabled
		variables_mn_btn.get_popup().set_item_disabled(1, set_disabled)
var no_db_container: PanelContainer = null
var _unsaved: bool = false
var main_submenu: PopupMenu = null

@onready var main_split: HSplitContainer = $MainSplit

@onready var folder_search_line: LineEdit = $MainSplit/VBoxContainer/FoldersPanel/FoldersContainer/TitleContainer/FolderSearchLine
@onready var var_search_line: LineEdit = $MainSplit/VBoxContainer2/TitleContainer/VarSearchLine

@onready var folders_tree: Tree = $MainSplit/VBoxContainer/FoldersPanel/FoldersContainer/FoldersTree
@onready var variables_tree: Tree = $MainSplit/VBoxContainer2/VariablesPanel/VariablesTree

@onready var add_folder_button: Button = $MainSplit/VBoxContainer/FoldersPanel/FoldersContainer/TitleContainer/FolderButtons/AddFolderButton
@onready var add_int_button: Button = $MainSplit/VBoxContainer2/TitleContainer/AddButtonsContainer/AddIntButton
@onready var add_float_button: Button = $MainSplit/VBoxContainer2/TitleContainer/AddButtonsContainer/AddFloatButton
@onready var add_bool_button: Button = $MainSplit/VBoxContainer2/TitleContainer/AddButtonsContainer/AddBoolButton
@onready var add_string_button: Button = $MainSplit/VBoxContainer2/TitleContainer/AddButtonsContainer/AddStringButton


@onready var confirmation_dialog: ConfirmationDialog = $PopUps/ConfirmationDialog
@onready var data_select_dialog: FileDialog = $PopUps/DataSelectDialog

@onready var title_label: Label = $MainSplit/VBoxContainer/HBoxContainer/TitleLabel
@onready var current_folder_label: Label = $MainSplit/VBoxContainer2/TitleContainer/FolderPathContainer/CurrentFolderLabel

@onready var variables_mn_btn: MenuButton = $MainSplit/VBoxContainer2/TitleContainer/MenuContainer/VariablesMnBtn


func _ready() -> void:
	var res_path: String = ProjectSettings.get_setting(NFVariablesRes.SETTINGS_PATH, "")
	var menu_button: PopupMenu = variables_mn_btn.get_popup()
	
	if main_submenu == null:
		main_submenu = PopupMenu.new()
	else:
		main_submenu.clear()
	
	main_submenu.add_icon_item(ADD_INT_ICON, "Create Integer", 0)
	main_submenu.add_icon_item(ADD_FLOAT_ICON, "Create Float", 1)
	main_submenu.add_icon_item(ADD_BOOL_ICON, "Create Boolean", 2)
	main_submenu.add_icon_item(ADD_STRING_ICON, "Create String", 3)
	
	menu_button.set_item_submenu_node(1, main_submenu)
	
	menu_button.set_item_disabled(1, true)
	
	if not res_path.is_empty() and ResourceLoader.exists(res_path):
		var res_load: Resource = load(res_path)
		if res_load is NFVariablesRes:
			if res_load is NFVariablesRes:
				_variables_resource = res_load
	
	if _variables_resource != null:
		_load_variables(_variables_resource.variables)
		main_split.visible = true
	else:
		no_db_container = preload("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		add_child(no_db_container)
		no_db_container.set_resource_type("NFVariablesRes", "Variables", "Variables")
		no_db_container.create_resource_pressed.connect(on_create_resource_pressed)
		no_db_container.load_resource_pressed.connect(on_load_resource_pressed)
		no_db_container.visible = true
		main_split.visible = false
	
	folders_tree.item_selected.connect(on_folder_clicked)
	folders_tree.something_changed.connect(on_something_changed)
	variables_tree.something_changed.connect(on_something_changed)
	
	add_int_button.pressed.connect(on_add_var_int_pressed)
	add_float_button.pressed.connect(on_add_var_float_pressed)
	add_bool_button.pressed.connect(on_add_var_bool_pressed)
	add_string_button.pressed.connect(on_add_var_str_pressed)
	
	add_folder_button.pressed.connect(on_add_root_folder_pressed)
	variables_tree.copy_path_pressed.connect(on_variable_cpath_button_pressed)
	
	folder_search_line.text_changed.connect(on_search_folder_changed)
	var_search_line.text_changed.connect(on_search_var_changed)
	
	folders_tree.delete_folder_request.connect(on_folder_delete_request)
	folders_tree.folder_renamed.connect(on_folder_renamed)
	
	data_select_dialog.file_selected.connect(on_data_select_file_selected)
	
	menu_button.id_pressed.connect(on_menu_button_pressed)
	main_submenu.id_pressed.connect(on_create_variable_pressed)


func on_folder_renamed(from: String, to: String, folder: TreeItem) -> void:
	if folder == _current_folder:
		current_folder_label.text = folders_tree.get_path_to_folder(folder)


func on_create_variable_pressed(id: int) -> void:
	match id:
		0:
			on_add_var_int_pressed()
		1:
			on_add_var_float_pressed()
		2:
			on_add_var_bool_pressed()
		3:
			on_add_var_str_pressed()


func on_menu_button_pressed(id: int) -> void:
	match id:
		0:
			save_variables()
		2:
			on_add_root_folder_pressed()


func on_something_changed() -> void:
	if _switching_tree or _unsaved:
		return
	_unsaved = true


func save_variables() -> void:
	_variables_resource.variables = build_variable_dictionary()
	_variables_resource.save()
	_unsaved = false


func on_create_resource_pressed() -> void:
	data_select_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	data_select_dialog.show()


func on_load_resource_pressed() -> void:
	data_select_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	data_select_dialog.show()


func on_data_select_file_selected(path: String) -> void:
	var load_success: bool = true
	if data_select_dialog.file_mode == FileDialog.FileMode.FILE_MODE_SAVE_FILE:
		var new_var_db := NFVariablesRes.new()
		_variables_resource = new_var_db
		ProjectSettings.set_setting(NFVariablesRes.SETTINGS_PATH, path)
		ProjectSettings.save()
		_variables_resource.save()
	else: # We are in load mode
		var resource = load(path)
		if resource is NFVariablesRes:
			_variables_resource = resource
			ProjectSettings.set_setting(NFVariablesRes.SETTINGS_PATH, path)
			ProjectSettings.save()
			_load_variables(_variables_resource.variables)
		else:
			load_success = false
	
	if load_success:
		main_split.visible = true
		no_db_container.visible = false


func build_variable_dictionary() -> Dictionary:
	if _current_folder != null:
		_current_folder.get_metadata(0)["variables"] = variables_tree.get_variables_as_array()
	
	return folders_tree.get_full_variables_dict()


func on_folder_delete_request(folder: TreeItem) -> void:
	if _current_folder == folder:
		_current_folder.get_metadata(0)["variables"] = variables_tree.get_variables_as_array()
	
	var delete_folder: bool = true
	
	if not folder.get_metadata(0)["variables"].is_empty():
		delete_folder = await confirmation_dialog.confirm_action().action_taken
	
	if delete_folder:
		if folder == _current_folder:
			variables_tree.clear_variables()
			_current_folder = null
		folder.free()
		on_something_changed()


func _load_variables(folder_dict: Dictionary) -> void:
	folders_tree.clear_folders()
	_switching_tree = true
	for folder in folder_dict:
		folders_tree.load_folder_data(folder, folder_dict[folder])
	_switching_tree = false


func on_search_folder_changed(new_text: String) -> void:
	var stripped_text: String = new_text.strip_edges().to_lower()
	if stripped_text.is_empty():
		folders_tree.show_all_folders()
	else:
		folders_tree.search_for_folder(stripped_text)


func on_search_var_changed(var_search: String) -> void:
	var stripped_text: String = var_search.strip_edges().to_lower()
	
	if stripped_text.is_empty():
		variables_tree.show_all_vars()
	else:
		variables_tree.search_for_var(stripped_text)


func on_add_root_folder_pressed() -> void:
	folders_tree.create_root_folder()


func on_add_var_int_pressed() -> void:
	variables_tree.create_variable("", TYPE_INT, 0)


func on_add_var_float_pressed() -> void:
	variables_tree.create_variable("", TYPE_FLOAT, 0.0)


func on_add_var_bool_pressed() -> void:
	variables_tree.create_variable("", TYPE_BOOL, false)


func on_add_var_str_pressed() -> void:
	variables_tree.create_variable("", TYPE_STRING, "")


func on_folder_clicked() -> void:
	if _switching_tree:
		return
	
	var target: TreeItem = folders_tree.get_selected()
	
	if _current_folder != null:
		_current_folder.get_metadata(0)["variables"] = variables_tree.get_variables_as_array()
		
	_switching_tree = true
	
	var_search_line.text = ""
	variables_tree.clear_variables()
	
	var variables: Array = target.get_metadata(0)["variables"]
	
	for variable_dict in variables:
		variables_tree.create_variable(variable_dict["name"], variable_dict["type"], variable_dict["variable"])
	
	if not target.is_selected(1):
		target.select(1)
	
	_current_folder = target
	current_folder_label.text = folders_tree.get_path_to_folder(target)
	
	_switching_tree = false


func on_variable_cpath_button_pressed(item: TreeItem) -> void:
	var full_path: String = str(folders_tree.get_path_to_folder(_current_folder),"/", item.get_text(0))
	
	DisplayServer.clipboard_set(full_path)


func get_int_variable_paths() -> Array[String]:
	return _get_variables(folders_tree.root_tree, TYPE_INT)


func get_float_variable_paths() -> Array[String]:
	return _get_variables(folders_tree.root_tree, TYPE_FLOAT)


func get_bool_variable_paths() -> Array[String]:
	return _get_variables(folders_tree.root_tree, TYPE_BOOL)


func get_string_variable_paths() -> Array[String]:
	return _get_variables(folders_tree.root_tree, TYPE_STRING)


func _get_variables(tree_folder: TreeItem, type_of: int) -> Array[String]:
	var var_paths: Array[String] = []
	
	if _current_folder != null:
		_current_folder.get_metadata(0)["variables"] = variables_tree.get_variables_as_array()
	
	for folder:TreeItem in folders_tree.get_folder_items():
		var folder_path: String = folders_tree.get_path_to_folder(folder)
		for variable:Dictionary in folder.get_metadata(0)["variables"]:
			if variable["type"] == type_of:
				var_paths.append(str(folder_path, "/", variable["name"]))
		var_paths.append_array(_get_variables(folder, type_of))
	
	return var_paths
