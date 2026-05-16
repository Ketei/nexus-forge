@tool
extends PanelContainer


const ResourceFileDialog = preload("res://addons/nexus_forge/classes/resource_file_dialog.gd")

var _variables_resource: BlackboardData = null
var _switching_tree: bool = false
var _current_folder: String = "":
	set(new_tree):
		_current_folder = new_tree
		current_folder_label.text = String(new_tree)
		var set_disabled: bool = _current_folder.is_empty()
		add_int_button.disabled = set_disabled
		add_float_button.disabled = set_disabled
		add_bool_button.disabled = set_disabled
		add_string_button.disabled = set_disabled
var _unsaved: bool = false

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

@onready var title_label: Label = $MainSplit/VBoxContainer/HBoxContainer/TitleLabel
@onready var current_folder_label: Label = $MainSplit/VBoxContainer2/TitleContainer/FolderPathContainer/CurrentFolderLabel


func ready_plugin() -> void:
	folders_tree.ready_plugin()
	variables_tree.ready_plugin()
	
	reload_resource(true)
	
	add_folder_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	folder_search_line.right_icon = get_theme_icon("Search", "EditorIcons")
	var_search_line.right_icon = get_theme_icon("Search", "EditorIcons")
	
	folders_tree.folder_selected.connect(_on_folder_selected)
	folders_tree.something_changed.connect(on_something_changed)
	folders_tree.folder_created.connect(_on_folder_created)
	folders_tree.folder_moved.connect(_on_folder_moved)
	folders_tree.variable_dropped.connect(_on_variable_dropped)
	variables_tree.something_changed.connect(on_something_changed)
	variables_tree.variable_updated.connect(_on_variable_updated)
	variables_tree.variable_renamed.connect(_on_variable_renamed)
	
	add_int_button.pressed.connect(on_add_var_int_pressed)
	add_float_button.pressed.connect(on_add_var_float_pressed)
	add_bool_button.pressed.connect(on_add_var_bool_pressed)
	add_string_button.pressed.connect(on_add_var_str_pressed)
	
	add_folder_button.pressed.connect(_on_add_root_folder_pressed)
	variables_tree.copy_path_pressed.connect(on_variable_cpath_button_pressed)
	
	folder_search_line.text_changed.connect(on_search_folder_changed)
	var_search_line.text_changed.connect(_on_search_var_changed)
	
	folders_tree.folder_deleted.connect(_on_folder_deleted)
	folders_tree.folder_renamed.connect(_on_folder_renamed)


func reload_resource(first_load: bool = false) -> void:
	var was_null: bool = _variables_resource == null
	_variables_resource = null
	
	folders_tree.clear_folders()
	variables_tree.clear_variables()
	
	var res_path: String = ProjectSettings.get_setting(
				EditorNFPlugin.get_project_settings_path("variables"),
				"")
	
	if not res_path.is_empty() and ResourceLoader.exists(res_path):
		var res_load: Resource = load(res_path)
		if res_load is BlackboardData:
			if res_load is BlackboardData:
				_variables_resource = res_load
	
	if _variables_resource != null:
		load_variable_resource()
		main_split.visible = true
	else:
		if first_load or not was_null:
			var no_db_container: Control = preload("res://addons/nexus_forge/no_db_container.tscn").instantiate()
			no_db_container.name = &"NoVarResContainer"
			add_child(no_db_container)
			no_db_container.message_minimum_size.x = 550
			no_db_container.set_resource_type("BlackboardData", "Variables", "Variables")
			no_db_container.create_resource_pressed.connect(on_create_resource_pressed)
			no_db_container.load_resource_pressed.connect(on_load_resource_pressed)
			no_db_container.resource_dropped.connect(_on_resource_dropped.bind(no_db_container))
			no_db_container.visible = true
			main_split.visible = false


func _on_folder_created(path_to_folder: String) -> void:
	_variables_resource.create_folder(path_to_folder)


func _on_variable_renamed(from: String, to: String) -> void:
	if from == to:
		return
	var folder_id: StringName = StringName(_current_folder)
	var from_id: StringName = StringName(from)
	var to_id: StringName = StringName(to)
	_variables_resource._variables[folder_id][to_id] = _variables_resource._variables[folder_id][from_id]
	_variables_resource._variables[folder_id].erase(from_id)


func _on_variable_updated(variable_id: String, value: Variant) -> void:
	_variables_resource.set_variable(
			_current_folder,
			variable_id,
			value)


func _on_folder_renamed(from: String, to: String) -> void:
	var from_id: StringName = StringName(from)
	var to_id: StringName = StringName(to)
	
	for folder_key:StringName in _variables_resource._variables.keys():
		if _is_folder_or_subfolder(folder_key, from):
			var new_key: StringName = to_id + folder_key.trim_prefix(from_id)
			_variables_resource._variables[new_key] = _variables_resource._variables[folder_key]
			_variables_resource._variables.erase(folder_key)
	
	if _current_folder == from:
		_current_folder = to


func _is_folder_or_subfolder(this: String, from: String) -> bool:
	if this == from:
		return true
	elif this.begins_with(from + "/"):
		return true
	else:
		return false


func on_something_changed() -> void:
	if _switching_tree or _unsaved:
		return
	_unsaved = true


func save() -> void:
	_unsaved = false
	if _variables_resource == null:
		return
	ResourceSaver.save(
			_variables_resource,
			ProjectSettings.get_setting(
					EditorNFPlugin.get_project_settings_path("variables"),
					_variables_resource.resource_path))


func on_create_resource_pressed() -> void:
	var new_dialog := ResourceFileDialog.get_file_browser()
	new_dialog.file_mode = new_dialog.FILE_MODE_SAVE_FILE
	add_child(new_dialog)
	new_dialog.show()
	
	var result = await new_dialog.dialog_finished
	
	if result[0]:
		_variables_resource = BlackboardData.new()
		_variables_resource.resource_path = result[1]
		ResourceSaver.save(_variables_resource, result[1])
		ProjectSettings.set_setting(
				EditorNFPlugin.get_project_settings_path("variables"),
				result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		main_split.visible = true
		var no_db_container = get_node(^"NoVarResContainer")
		no_db_container.visible = false
		no_db_container.queue_free()
	
	new_dialog.queue_free()


func _on_resource_dropped(resource: Resource, panel: Control) -> void:
	_variables_resource = resource
	ProjectSettings.set_setting(
			EditorNFPlugin.get_project_settings_path("variables"),
			resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	main_split.visible = true
	load_variable_resource()


func on_load_resource_pressed() -> void:
	var new_dialog := ResourceFileDialog.get_file_browser()
	new_dialog.file_mode = new_dialog.FILE_MODE_OPEN_FILE
	add_child(new_dialog)
	new_dialog.show()
	
	var result = await new_dialog.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre is BlackboardData:
			_variables_resource = res_pre
			ProjectSettings.set_setting(
					EditorNFPlugin.get_project_settings_path("variables"),
					result[1])
			if Engine.is_editor_hint():
				ProjectSettings.save()
			main_split.visible = true
			var no_db_container = get_node(^"NoVarResContainer")
			no_db_container.visible = false
			no_db_container.queue_free()
			load_variable_resource()
		else:
			push_error("Selected resource is not BlackboardData")
	
	new_dialog.queue_free()


func _on_folder_deleted(folder_path: String) -> void:
	_variables_resource.erase_folder(folder_path)
	if _current_folder == folder_path:
		_current_folder = ""
		variables_tree.clear_variables()
		var_search_line.text = ""


func load_variable_resource() -> void:
	var tree_map: Dictionary = {}
	
	var all_paths: Array[String] = []
	all_paths.assign(_variables_resource._variables.keys())
	
	for folder_path: String in all_paths:
		var current_level: Dictionary = tree_map
		for folder: String in folder_path.split("/", false):
			if not current_level.has(folder):
				current_level[folder] = {}
			current_level = current_level[folder]
	
	_switching_tree = true
	folders_tree.clear_folders()
	folders_tree.load_folder_structure(tree_map)
	
	folders_tree.collapse_folders()
	_switching_tree = false


func on_search_folder_changed(new_text: String) -> void:
	var stripped_text: String = new_text.strip_edges()
	
	if stripped_text.is_empty():
		folders_tree.show_all_folders()
	else:
		folders_tree.search_for_folder(stripped_text)


func _on_search_var_changed(var_search: String) -> void:
	var stripped_text: String = var_search.strip_edges()
	variables_tree.search_for_pattern(stripped_text)


func _on_add_root_folder_pressed() -> void:
	var folder_id: String = folders_tree.create_root_folder()
	_variables_resource.create_folder(folder_id)


func on_add_var_int_pressed() -> void:
	var variable_key: StringName = StringName(variables_tree.create_variable(0))
	_variables_resource.set_variable(
			_current_folder,
			variable_key,
			0)
	on_something_changed()


func on_add_var_float_pressed() -> void:
	var variable_key: StringName = StringName(variables_tree.create_variable(0.0))
	_variables_resource.set_variable(
			_current_folder,
			variable_key,
			0.0)
	on_something_changed()


func on_add_var_bool_pressed() -> void:
	var variable_key: StringName = StringName(variables_tree.create_variable(false))
	_variables_resource.set_variable(
			_current_folder,
			variable_key,
			false)
	on_something_changed()


func on_add_var_str_pressed() -> void:
	var variable_key: StringName = StringName(variables_tree.create_variable(""))
	_variables_resource.set_variable(
			_current_folder,
			variable_key,
			"")
	on_something_changed()


func _on_folder_selected(path_to_folder: String) -> void:
	var variables: Array[String] = _variables_resource.variables(path_to_folder)
	
	variables_tree.clear_variables()
	var_search_line.clear()
	
	variables_tree.current_folder = path_to_folder
	
	for variable_id in variables:
		variables_tree.create_variable(
				_variables_resource.get_variable(path_to_folder, variable_id),
				variable_id)
	
	_current_folder = path_to_folder


func on_variable_cpath_button_pressed(var_id: String) -> void:
	DisplayServer.clipboard_set(str(_current_folder, "/", var_id))


func has_unsaved_changes() -> bool:
	return _unsaved


func get_folder_layout() -> Dictionary:
	return folders_tree.get_folder_order()


func set_folder_layout(layout_data: Dictionary) -> void:
	if not layout_data.is_empty() and folders_tree.get_root() != null:
		folders_tree.set_folder_order(layout_data)


func _on_folder_moved(original_path: String, new_path: String) -> void:
	if original_path == new_path:
		return
	
	var original_key: StringName = StringName(original_path)
	var start_path: String = original_path + "/"
	var new_prefix: String = new_path + "/"
	_variables_resource._variables[StringName(new_path)] = _variables_resource._variables[original_key]
	_variables_resource._variables.erase(original_key)
	
	for folder_key:StringName in _variables_resource._variables.keys():
		if folder_key.begins_with(start_path):
			var new_folder_path: StringName = StringName(new_prefix + folder_key.trim_prefix(start_path))
			_variables_resource._variables[new_folder_path] = _variables_resource._variables[folder_key]
			_variables_resource._variables.erase(folder_key)
	
	if original_path == _current_folder:
		_current_folder = new_path
	on_something_changed()


func _on_variable_dropped(var_folder: String, variable: String, new_folder: String) -> void:
	_variables_resource.set_variable(new_folder, variable, _variables_resource.get_variable(var_folder, variable))
	_variables_resource.set_variable(var_folder, variable, null)
	variables_tree.remove_variable(variable)
	on_something_changed()


func set_sorting_column(column: int) -> void:
	variables_tree.sorting_column = clampi(column, 0, 1)


func get_sorting_column() -> int:
	return variables_tree.sorting_column
