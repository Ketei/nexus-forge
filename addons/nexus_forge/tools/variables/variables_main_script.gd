@tool
extends Control

const SAVE_FILE_ICON = preload("res://addons/nexus_forge/common_icons/save_file.svg")
const ADD_BOOL_ICON = preload("res://addons/nexus_forge/common_icons/variables/add_bool.svg")
const ADD_FLOAT_ICON = preload("res://addons/nexus_forge/common_icons/variables/add_float.svg")
const ADD_INT_ICON = preload("res://addons/nexus_forge/common_icons/variables/add_int.svg")
const ADD_STRING_ICON = preload("res://addons/nexus_forge/common_icons/variables/add_string.svg")
const NEW_FOLDER_ICON = preload("res://addons/nexus_forge/common_icons/new_folder.svg")

var _variables_resource: NFVariablesRes = null
var _switching_tree: bool = false
#var _switching_variable: bool = false
var _current_folder: String = "":
	set(new_tree):
		_current_folder = new_tree
		current_folder_label.text = new_tree
		var set_disabled: bool = _current_folder.is_empty()
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

@onready var variables_mn_btn: MenuButton = $MainSplit/VBoxContainer/HBoxContainer/MenuContainer/VariablesMnBtn


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
	
	folders_tree.folder_selected.connect(_on_folder_selected)
	folders_tree.something_changed.connect(on_something_changed)
	folders_tree.folder_created.connect(_on_folder_created)
	variables_tree.something_changed.connect(on_something_changed)
	variables_tree.variable_updated.connect(_on_variable_updated)
	variables_tree.variable_renamed.connect(_on_variable_renamed)
	variables_tree.variable_created.connect(_on_variable_created)
	
	add_int_button.pressed.connect(on_add_var_int_pressed)
	add_float_button.pressed.connect(on_add_var_float_pressed)
	add_bool_button.pressed.connect(on_add_var_bool_pressed)
	add_string_button.pressed.connect(on_add_var_str_pressed)
	
	add_folder_button.pressed.connect(on_add_root_folder_pressed)
	variables_tree.copy_path_pressed.connect(on_variable_cpath_button_pressed)
	
	folder_search_line.text_changed.connect(on_search_folder_changed)
	var_search_line.text_changed.connect(on_search_var_changed)
	
	folders_tree.folder_deleted.connect(_on_folder_deleted)
	folders_tree.folder_renamed.connect(on_folder_renamed)
	
	data_select_dialog.file_selected.connect(on_data_select_file_selected)
	
	menu_button.id_pressed.connect(on_menu_button_pressed)
	main_submenu.id_pressed.connect(on_create_variable_pressed)


func _on_variable_created(variable_id: String, value: Variant) -> void:
	_variables_resource.set_variable(
			_current_folder + "/" + variable_id,
			value)


func _on_folder_created(path_to_folder: String) -> void:
	_variables_resource.create_folder(path_to_folder)


func _on_variable_renamed(from: String, to: String) -> void:
	var variable_path: String = _current_folder + "/"
	_variables_resource.set_variable(
			variable_path + to,
			_variables_resource.get_variable(variable_path + from))
	_variables_resource.delete_variable(variable_path + from)


func _on_variable_updated(variable_id: String, value: Variant) -> void:
	_variables_resource.set_variable(
			_current_folder + "/" + variable_id,
			value)


func on_folder_renamed(path: String, from: String, to: String) -> void:
	var path_array: PackedStringArray = path.split("/", false)
	#var from_folder: String = path_array[-1]
	var current_level: Dictionary = _variables_resource.variables
	var top_skip: bool = false
	#path_array.resize(path_array.size() - 1)
	
	for path_next in path_array:
		if not top_skip:
			current_level = current_level[path_next]["subfolders"]
			top_skip = true
			continue
		current_level = current_level[path]["subfolders"]
	
	current_level[to] = current_level[from]
	current_level.erase(from)
	
	var final_path: String = path
	if not path.is_empty():
		final_path += "/"
	#final_path += from
	
	if _current_folder == final_path + from:
		_current_folder = final_path + to


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
			save()
		2:
			on_add_root_folder_pressed()


func on_something_changed() -> void:
	if _switching_tree or _unsaved:
		return
	_unsaved = true


func save() -> void:
	#_variables_resource.variables = build_variable_dictionary()
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


#func build_variable_dictionary() -> Dictionary:
	#if _current_folder != null:
		#_current_folder.get_metadata(0)["variables"] = variables_tree.get_variables_as_array()
	#
	#return folders_tree.get_full_variables_dict()


func _on_folder_deleted(folder_path: String) -> void:
	_variables_resource.delete_folder(folder_path)


#func on_folder_delete_request(folder: TreeItem) -> void:
	#if _current_folder == folder:
		#_current_folder.get_metadata(0)["variables"] = variables_tree.get_variables_as_array()
	#
	#var delete_folder: bool = true
	#
	#if not folder.get_metadata(0)["variables"].is_empty():
		#delete_folder = await confirmation_dialog.confirm_action().action_taken
	#
	#if delete_folder:
		#if folder == _current_folder:
			#variables_tree.clear_variables()
			#_current_folder = null
		#folder.free()
		#on_something_changed()


func _load_variables(folder_dict: Dictionary) -> void:
	folders_tree.clear_folders()
	_switching_tree = true
	for folder in folder_dict:
		folders_tree.load_folder_data(folder, folder_dict[folder])
	folders_tree.collapse_folders()
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
	_variables_resource.create_folder(folders_tree.create_root_folder())


func on_add_var_int_pressed() -> void:
	_variables_resource.set_variable(
			_current_folder + "/" + variables_tree.create_variable("", 0),
			0)
	on_something_changed()


func on_add_var_float_pressed() -> void:
	#variables_tree.create_variable("", 0.0, true)
	_variables_resource.set_variable(
			_current_folder + "/" + variables_tree.create_variable("", 0.0),
			0.0)
	on_something_changed()


func on_add_var_bool_pressed() -> void:
	#variables_tree.create_variable("", false, true)
	_variables_resource.set_variable(
			_current_folder + "/" + variables_tree.create_variable("", false),
			false)
	on_something_changed()


func on_add_var_str_pressed() -> void:
	#variables_tree.create_variable("", "", true)
	_variables_resource.set_variable(
			_current_folder + "/" + variables_tree.create_variable("", ""),
			"")
	on_something_changed()


func _on_folder_selected(path_to_folder: String) -> void:
	var variables: Dictionary = _variables_resource.get_variables_in_folder(path_to_folder)
	
	variables_tree.clear_variables()
	var_search_line.clear()
	
	for variable in variables:
		variables_tree.create_variable(variable, variables[variable])

	#current_folder_label.text = path_to_folder
	_current_folder = path_to_folder
	
	folders_tree.select_folder_no_signal(path_to_folder)


#func on_folder_clicked() -> void:
	#if _switching_tree:
		#return
	#
	#var target: TreeItem = folders_tree.get_selected()
	#
	#if _current_folder != null:
		#_current_folder.get_metadata(0)["variables"] = variables_tree.get_variables_as_array()
		#
	#_switching_tree = true
	#
	#var_search_line.text = ""
	#variables_tree.clear_variables()
	#
	#var variables: Array = target.get_metadata(0)["variables"]
	#
	#for variable_dict in variables:
		#variables_tree.create_variable(variable_dict["name"], variable_dict["variable"])
	#
	#if not target.is_selected(1):
		#target.select(1)
	#
	#_current_folder = target
	#current_folder_label.text = folders_tree.get_path_to_folder(target)
	#
	#_switching_tree = false


func on_variable_cpath_button_pressed(var_id: String) -> void:
	DisplayServer.clipboard_set(str(_current_folder, "/", var_id))


func has_unsaved_changes() -> bool:
	return _unsaved
