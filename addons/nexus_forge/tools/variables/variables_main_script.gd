extends Control


# Idea

# The main root will consist of a dictionary. Subfolders will consist of the
# same structure.

# {folder_name: "", "variables": {}, "subfolders": []}

# "variable_key": 
const RES_PATH_SETTING: String = "nexus_forge/variables/resource_path"

var _variables_resource: NexusForgeVariables = null
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

var _unsaved: bool = false:
	set(is_unsaved):
		_unsaved = is_unsaved
		unsaved_label.visible = _unsaved


@onready var main_split: HSplitContainer = $MainSplit
@onready var no_db_container: PanelContainer = $NoDBContainer

@onready var folder_search_line: LineEdit = $MainSplit/VBoxContainer/FoldersPanel/FoldersContainer/TitleContainer/FolderSearchLine
@onready var var_search_line: LineEdit = $MainSplit/VariablesPanel/VariablesContainer/TitleContainer/VarSearchLine

@onready var folders_tree: Tree = $MainSplit/VBoxContainer/FoldersPanel/FoldersContainer/FoldersTree
@onready var variables_tree: Tree = $MainSplit/VariablesPanel/VariablesContainer/VariablesTree

@onready var add_folder_button: Button = $MainSplit/VBoxContainer/FoldersPanel/FoldersContainer/TitleContainer/FolderButtons/AddFolderButton
@onready var add_int_button: Button = $MainSplit/VariablesPanel/VariablesContainer/TitleContainer/AddButtonsContainer/AddIntButton
@onready var add_float_button: Button = $MainSplit/VariablesPanel/VariablesContainer/TitleContainer/AddButtonsContainer/AddFloatButton
@onready var add_bool_button: Button = $MainSplit/VariablesPanel/VariablesContainer/TitleContainer/AddButtonsContainer/AddBoolButton
@onready var add_string_button: Button = $MainSplit/VariablesPanel/VariablesContainer/TitleContainer/AddButtonsContainer/AddStringButton

@onready var create_db_button: Button = $NoDBContainer/CenterContainer/InfoContainer/ButtonsContainer/CreateDBButton
@onready var load_db_button: Button = $NoDBContainer/CenterContainer/InfoContainer/ButtonsContainer/LoadDBButton

@onready var confirmation_dialog: ConfirmationDialog = $PopUps/ConfirmationDialog
@onready var data_select_dialog: FileDialog = $PopUps/DataSelectDialog

@onready var title_label: Label = $MainSplit/VBoxContainer/HBoxContainer/TitleLabel
@onready var unsaved_label: Label = $MainSplit/VBoxContainer/HBoxContainer/UnsavedLabel


func _ready() -> void:
	var res_path: String = ProjectSettings.get_setting(RES_PATH_SETTING, "")
	
	if res_path.is_empty() or not ResourceLoader.exists(res_path):
		no_db_container.visible = true
		main_split.visible = false
	else:
		var res_load: Resource = load(res_path)
		if res_load is NexusForgeVariables:
			_variables_resource = res_load
			_load_variables(_variables_resource.variables)
			no_db_container.visible = false
			main_split.visible = true
		else:
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
	
	data_select_dialog.file_selected.connect(on_data_select_file_selected)
	
	#test_save_button.pressed.connect(test_save_pressed)
	create_db_button.pressed.connect(on_create_resource_pressed)
	load_db_button.pressed.connect(on_load_resource_pressed)


func on_something_changed() -> void:
	if _switching_tree or _unsaved:
		return
	_unsaved = true


func save_variables() -> void:
	var save_path: String = ProjectSettings.get_setting(RES_PATH_SETTING, "")
	if save_path.is_empty():
		return
	_variables_resource.variables = build_variable_dictionary()
	ResourceSaver.save(_variables_resource, save_path)


func on_create_resource_pressed() -> void:
	data_select_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	data_select_dialog.show()


func on_load_resource_pressed() -> void:
	data_select_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	data_select_dialog.show()


func on_data_select_file_selected(path: String) -> void:
	var load_success: bool = true
	if data_select_dialog.file_mode == FileDialog.FileMode.FILE_MODE_SAVE_FILE:
		var new_var_db := NexusForgeVariables.new()
		_variables_resource = new_var_db
	else: # We are in load mode
		var resource = load(path)
		if resource is NexusForgeVariables:
			_variables_resource = resource
			_load_variables(_variables_resource.variables)
		else:
			load_success = false
	
	if load_success:
		ProjectSettings.set_setting(RES_PATH_SETTING, path)
		ProjectSettings.save()
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
