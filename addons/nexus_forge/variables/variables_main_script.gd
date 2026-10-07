@tool
extends PanelContainer


const UNDO_MAX_STEPS: int = 50

var _variables_resource: NFBlackboardData = null
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
var undo: UndoRedo = null

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

@onready var current_folder_label: Label = $MainSplit/VBoxContainer2/TitleContainer/FolderPathContainer/CurrentFolderLabel


func ready_plugin() -> void:
	folders_tree.ready_plugin()
	variables_tree.ready_plugin()
	undo = UndoRedo.new()
	undo.max_steps = UNDO_MAX_STEPS
	
	reload_resource(true)
	
	add_folder_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	folder_search_line.right_icon = get_theme_icon("Search", "EditorIcons")
	var_search_line.right_icon = get_theme_icon("Search", "EditorIcons")
	
	folders_tree.folder_selected.connect(_on_folder_selected, CONNECT_DEFERRED)
	folders_tree.something_changed.connect(on_something_changed)
	folders_tree.folder_created.connect(_on_folder_created)
	folders_tree.folder_moved.connect(_on_folder_moved)
	folders_tree.variable_dropped.connect(_on_variable_dropped)
	variables_tree.something_changed.connect(on_something_changed)
	variables_tree.variable_updated.connect(_on_variable_updated)
	variables_tree.variable_renamed.connect(_on_variable_renamed)
	
	add_int_button.pressed.connect(_on_add_variable_pressed.bind(0))
	add_float_button.pressed.connect(_on_add_variable_pressed.bind(0.0))
	add_bool_button.pressed.connect(_on_add_variable_pressed.bind(false))
	add_string_button.pressed.connect(_on_add_variable_pressed.bind(""))
	
	add_folder_button.pressed.connect(_on_add_root_folder_pressed)
	variables_tree.copy_path_pressed.connect(on_variable_cpath_button_pressed)
	
	folder_search_line.text_changed.connect(on_search_folder_changed)
	var_search_line.text_changed.connect(_on_search_var_changed)
	
	folders_tree.folder_deleted.connect(_on_folder_deleted)
	folders_tree.folder_renamed.connect(_on_folder_renamed)


func can_undo() -> bool:
	if is_instance_valid(undo):
		return undo.has_undo()
	return false


func can_redo() -> bool:
	if is_instance_valid(undo):
		return undo.has_redo()
	return false


func do_undo() -> void:
	var action_name: String = undo.get_current_action_name()
	undo.undo()
	NFPluginGameHandler._log_msg(
			"",
			"Undo: " + action_name,
			NFPluginGameHandler._LogLevel.EDITOR)
	on_something_changed()


func do_redo() -> void:
	var action_name: String = undo.get_action_name(undo.get_current_action() + 1)
	undo.redo()
	NFPluginGameHandler._log_msg(
			"",
			"Redo: " + action_name,
			NFPluginGameHandler._LogLevel.EDITOR)
	on_something_changed()



func reload_resource(first_load: bool = false) -> void:
	var was_null: bool = _variables_resource == null
	_variables_resource = null
	
	folders_tree.clear_folders()
	variables_tree.clear_variables()
	
	var res_path: String = ProjectSettings.get_setting(
		NFPluginGameHandler.get_setting_path("variables"),
		"")
	
	if not res_path.is_empty() and ResourceLoader.exists(res_path):
		var res_load: Resource = load(res_path)
		if res_load is NFBlackboardData:
			if res_load is NFBlackboardData:
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
	create_folder(path_to_folder)


func _on_variable_renamed(from: String, to: String) -> void:
	var folder = _variables_resource._variables.get(StringName(_current_folder))
	if folder == null or not folder.has(StringName(from)):
		return
	
	undo.create_action("Rename Variable")
	undo.add_do_method(_apply_variable_rename.bind(_current_folder, from, to, false))
	undo.add_undo_method(_apply_variable_rename.bind(_current_folder, to, from, false))
	undo.commit_action(false)
	_apply_variable_rename(_current_folder, from, to, true)


func _apply_variable_rename(folder: String, old_name: String, new_name: String, first_action: bool = false) -> void:
	var folder_key: StringName = StringName(folder)
	if not _variables_resource._variables.has(folder_key) or old_name == new_name:
		return
	var old_key: StringName = StringName(old_name)
	var new_key: StringName = StringName(new_name)
	
	_variables_resource._variables[folder_key][new_key] = _variables_resource._variables[folder_key][old_key]
	_variables_resource._variables[folder_key].erase(old_key)
	
	if first_action or _current_folder != folder:
		return
	
	if not variables_tree.rename_variable(old_name, new_name):
		NFPluginGameHandler._log_msg(
				"blackboard - editor",
				"Couldn't rename variable '%s' to '%s'",
				NFPluginGameHandler._LogLevel.ERROR)


func _on_variable_updated(variable_id: String, value: Variant) -> void:
	var folder_strn: StringName = StringName(_current_folder)
	var var_strn: StringName = StringName(variable_id)
	var old_value: Variant = _variables_resource._variables.get(folder_strn, {}).get(var_strn)
	var type: int = typeof(old_value)
	
	if type == TYPE_DICTIONARY or type == TYPE_ARRAY:
		old_value = old_value.duplicate()
	
	if typeof(value) == type and value == old_value:
		return
	
	var action_name: String = ""
	
	if type == TYPE_NIL:
		action_name = "Delete Variable '%s'" % variable_id
	else:
		action_name = "Update Variable '%s'" % variable_id
	
	undo.create_action(action_name)
	undo.add_do_method(_apply_variable_update.bind(_current_folder, variable_id, value))
	undo.add_undo_method(_apply_variable_update.bind(_current_folder, variable_id, old_value))
	undo.commit_action(false)
	_apply_variable_update(_current_folder, variable_id, value, true)


func _apply_variable_update(folder: String, variable: String, target_value: Variant, is_first_run: bool = false) -> void:
	set_resource_variable(folder, variable, target_value)
	
	if is_first_run:
		return
	
	if _current_folder == folder:
		if target_value == null:
			variables_tree.remove_variable(variable)
		else:
			if not variables_tree.update_variable(variable, target_value):
				variables_tree.create_variable(target_value, variable)


func _on_folder_renamed(from: String, to: String) -> void:
	undo.create_action("Rename Folder")
	undo.add_do_method(_apply_folder_rename.bind(from, to, false))
	undo.add_undo_method(_apply_folder_rename.bind(to, from, false))
	undo.commit_action(false)
	_apply_folder_rename(from, to, true)


func _apply_folder_rename(from_path: String, to_path: String, is_first_run: bool = false) -> void:
	var from_length: int = from_path.length()
	for folder_key in _variables_resource._variables.keys():
		if _is_folder_or_subfolder(folder_key, from_path):
			var old_path_str: String = String(folder_key)
			
			var extra_path: String = old_path_str.substr(from_length)
			var new_path_str: String = to_path
			if not extra_path.is_empty():
				new_path_str = to_path.path_join(extra_path)
			var new_key: StringName = StringName(new_path_str)
			
			if not _variables_resource._variables.has(new_key):
				_variables_resource._variables[new_key] = _variables_resource._variables[folder_key]
				_variables_resource._variables.erase(folder_key)
			else:
				NFPluginGameHandler._log_msg(
						"blackboard - editor",
						"Attempted to rename folder '%s' to '%s', but folder '%s' already exists. Aborting backend change." % [folder_key, new_key, new_key],
						NFPluginGameHandler._LogLevel.WARNING)
	
	if _current_folder == from_path:
		_current_folder = to_path
	elif _current_folder.begins_with(from_path + "/"):
		_current_folder = to_path.path_join(_current_folder.substr(from_path.length()))
	
	if is_first_run or not folders_tree.has_folder(from_path):
		return
	
	folders_tree.rename_folder(
		from_path,
		to_path.get_file())


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
	
	ResourceSaver.save(_variables_resource)


func save_layout() -> void:
	var layout_data: Array[Dictionary] = folders_tree.get_folder_state()
	
	var layout_cfg: ConfigFile = ConfigFile.new()
	layout_cfg.set_value(
		"State",
		"folder_order",
		layout_data)
	
	
	var absolute_path: String = ProjectSettings.globalize_path("res://.godot/editor/nexus_forge_blackboard_layout.cfg")
	
	if layout_cfg.save(absolute_path) != OK:
		NFPluginGameHandler._log_msg(
			"blackboard - editor",
			"Failed saving layout.",
			NFPluginGameHandler._LogLevel.WARNING)


func restore_layout() -> void:
	var absolute_path: String = ProjectSettings.globalize_path("res://.godot/editor/nexus_forge_blackboard_layout.cfg")
	
	if not FileAccess.file_exists(absolute_path):
		return
	
	var layout_cfg: ConfigFile = ConfigFile.new()
	
	if layout_cfg.load(absolute_path) != OK:
		return
	
	if not layout_cfg.has_section_key("State", "folder_order"):
		return
	
	var data = layout_cfg.get_value("State", "folder_order", [])
	
	if typeof(data) != TYPE_ARRAY or data.is_empty():
		return
	
	var valid_data: Array[Dictionary] = []
	
	for item in data:
		if typeof(item) != TYPE_DICTIONARY or not item.has_all(["collapsed", "index", "path"]):
			continue
		valid_data.append(item)
	
	folders_tree.set_folder_state(valid_data)


func on_create_resource_pressed() -> void:
	var new_dialog: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	new_dialog.file_mode = new_dialog.FILE_MODE_SAVE_FILE
	
	EditorInterface.popup_dialog_centered(new_dialog)
	var result = await new_dialog.dialog_finished
	new_dialog.queue_free()
	
	if not result[0]:
		return
	
	_variables_resource = NFBlackboardData.new()
	_variables_resource.resource_path = result[1]
	ResourceSaver.save(_variables_resource, result[1])
	ProjectSettings.set_setting(
		NFPluginGameHandler.get_setting_path("variables"),
		result[1])
	if Engine.is_editor_hint():
		ProjectSettings.save()
	main_split.visible = true
	var no_db_container = get_node(^"NoVarResContainer")
	no_db_container.visible = false
	no_db_container.queue_free()


func _on_resource_dropped(resource: Resource, panel: Control) -> void:
	_variables_resource = resource
	ProjectSettings.set_setting(
		NFPluginGameHandler.get_setting_path("variables"),
		resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	main_split.visible = true
	load_variable_resource()


func on_load_resource_pressed() -> void:
	var new_dialog: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	new_dialog.file_mode = new_dialog.FILE_MODE_OPEN_FILE
	
	EditorInterface.popup_dialog_centered(new_dialog)
	var result = await new_dialog.dialog_finished
	new_dialog.queue_free()
	
	if not result[0]:
		return
	
	var res_pre: Resource = load(result[1])
	if res_pre is NFBlackboardData:
		_variables_resource = res_pre
		ProjectSettings.set_setting(
			NFPluginGameHandler.get_setting_path("variables"),
			result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		main_split.visible = true
		var no_db_container = get_node(^"NoVarResContainer")
		no_db_container.visible = false
		no_db_container.queue_free()
		load_variable_resource()
	else:
		NFPluginGameHandler._log_msg(
			"blackboard - editor",
			"Selected resource is not BlackboardData.",
			NFPluginGameHandler._LogLevel.INFO)


func _on_folder_deleted(folder_path: String) -> void:
	if not _variables_resource._variables.has(StringName(folder_path)): # Backend check
		return
	
	var folder_data: Dictionary[StringName, Dictionary] = get_folder_deletion_data(folder_path)
	
	undo.create_action("Delete Folder '%s'" % folder_path)
	undo.add_do_method(_do_folder_delete.bind(folder_path))
	undo.add_undo_method(_undo_folder_delete.bind(folder_data, folder_path))
	undo.commit_action(false)
	_do_folder_delete(folder_path, false)


func _undo_folder_delete(folder_data: Dictionary[StringName, Dictionary], folder_path: String) -> void:
	for path_id in folder_data:
		_variables_resource._variables[path_id] = folder_data[path_id].duplicate(true)
		var path_string: String = String(path_id)
		folders_tree.create_folder(path_string, true, false)
	
	folders_tree.select_folder_no_signal(folder_path)
	display_variables_of(folder_path)
	variables_tree.current_folder = folder_path
	_current_folder = folder_path


func _do_folder_delete(folder_path: String, remove_tree: bool = true) -> void:
	erase_folder(folder_path)
	if _current_folder == folder_path:
		_current_folder = ""
		variables_tree.clear_variables()
		var_search_line.text = ""
	if remove_tree:
		folders_tree.remove_folder(folder_path) # Safe. If node doesn't exist, just doesn't do nothing


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
	create_folder(folder_id)


# --- Used for undo/redo ---
func get_folder_deletion_data(folder_path: String) -> Dictionary[StringName, Dictionary]:
	folder_path = folder_path.simplify_path()
	var folder_data: Dictionary[StringName, Dictionary] = {}
	var path_id: StringName = StringName(folder_path)
	
	if not _variables_resource._variables.has(path_id):
		return folder_data
	
	var descendant_prefix: String = folder_path + "/"
	
	# Saving the data for the redo.
	for folder in _variables_resource._variables.keys():
		if folder.begins_with(descendant_prefix) or folder == path_id:
			folder_data[folder] = _variables_resource._variables[folder].duplicate(true)
	
	return folder_data


func rename_folder(path: String, new_path: String) -> void:
	folders_tree.rename_folder(path, new_path.rsplit("/", false, 1)[-1])


func create_variable(value: Variant, val_name: String) -> void:
	if variables_tree.has_variable(val_name):
		var msg: String = "ried to create a variable '%s' but the variable already existed. Type mismatch." % val_name
		var level: NFPluginGameHandler._LogLevel = NFPluginGameHandler._LogLevel.ERROR
		if typeof(value) == variables_tree.get_variable_type(val_name):
			if value == variables_tree.get_variable(val_name):
				msg = "Tried to create a variable '%s' but the variable already existed." % val_name
				level = NFPluginGameHandler._LogLevel.INFO
		NFPluginGameHandler._log_msg(
			"blackboard - editor",
			msg,
			level)
		return
	
	variables_tree.create_variable(value, val_name)


func remove_variable(variable: String) -> void:
	variables_tree.remove_variable(variable)


func _on_add_variable_pressed(data: Variant) -> void:
	var valid_id: String = variables_tree.create_variable(data)
	var path: String = _current_folder.path_join(valid_id)
	var type: int = typeof(data)
	var can_dupe: bool = type == TYPE_DICTIONARY or type == TYPE_ARRAY
	
	set_resource_variable(_current_folder, valid_id, data)
	
	undo.create_action("Create Data")
	undo.add_do_method(_do_add_variable.bind(
			_current_folder,
			valid_id,
			data.duplicate(true) if can_dupe else data))
	undo.add_undo_method(_undo_add_variable.bind(
			_current_folder,
			valid_id))
	undo.commit_action(false)
	
	on_something_changed()


func _undo_add_variable(on_folder: String, data_id: String) -> void:
	var folder_key: StringName = StringName(on_folder)
	erase_variable(on_folder, data_id)
	if _current_folder == on_folder:
		variables_tree.remove_variable(data_id)


func _do_add_variable(on_folder: String, data_id: String, value: Variant) -> void:
	var folder_key: StringName = StringName(on_folder)
	if not _variables_resource._variables.has(folder_key) or _variables_resource._variables[folder_key].has(data_id):
		return
	
	_variables_resource._variables[folder_key][data_id] = value
	
	if _current_folder == on_folder:
		variables_tree.create_variable(value, data_id)


func _on_folder_selected(path_to_folder: String) -> void:
	display_variables_of(path_to_folder)
	variables_tree.current_folder = path_to_folder
	_current_folder = path_to_folder


func refresh_current_variable_folder() -> void:
	if not _variables_resource._variables.has(_current_folder):
		return
	
	var folder: Dictionary = _variables_resource._variables[_current_folder]
	variables_tree.clear_variables()
	for variable_id in folder:
		variables_tree.create_variable(
				folder[variable_id],
				String(variable_id))
	
	var search_prompt: String = var_search_line.text.strip_edges()
	if not search_prompt.is_empty():
		variables_tree.search_for_pattern(search_prompt)


func display_variables_of(folder_path: String) -> void:
	var path_strn: StringName = StringName(folder_path)
	var variables: Array[StringName] = []
	variables.assign(
			_variables_resource._variables.get(
					path_strn, NFDictUtils.EMPTY_DICT).keys())
	
	variables_tree.clear_variables()
	var_search_line.clear()
	
	for variable_id in variables:
		variables_tree.create_variable(
			_variables_resource._variables[path_strn][variable_id],
			variable_id)


func on_variable_cpath_button_pressed(var_id: String) -> void:
	DisplayServer.clipboard_set("%s/%s" % [_current_folder, var_id])


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
	
	undo.create_action("Move Folder")
	undo.add_do_method(_apply_folder_move.bind(original_path, new_path, false))
	undo.add_undo_method(_apply_folder_move.bind(new_path, original_path, false))
	undo.commit_action(false)
	_apply_folder_move(original_path, new_path, true)


func _apply_folder_move(original_path: String, new_path: String, is_first_run: bool = false) -> void:
	var original_key: StringName = StringName(original_path)
	var from_prefix: String = original_path + "/"
	var to_prefix: String = new_path + "/"
	
	if _variables_resource._variables.has(original_key):
		_variables_resource._variables[StringName(new_path)] = _variables_resource._variables[original_key]
		_variables_resource._variables.erase(original_key)
	
	for folder_key:StringName in _variables_resource._variables.keys():
		var folder_str: String = String(folder_key)
		if folder_str.begins_with(from_prefix):
			var new_folder_str: String = to_prefix.path_join(folder_str.trim_prefix(from_prefix))
			var new_key: StringName = StringName(new_folder_str)
			_variables_resource._variables[new_key] = _variables_resource._variables[folder_key]
			_variables_resource._variables.erase(folder_key)
	
	if _current_folder == original_path:
		_current_folder = new_path
	elif _current_folder.begins_with(from_prefix):
		_current_folder = to_prefix.path_join(_current_folder.trim_prefix(from_prefix))
	
	if is_first_run:
		on_something_changed()
		return
	
	var success: bool = folders_tree.move_folder(original_path, new_path)
	
	if not success:
		NFPluginGameHandler._log_msg(
				"blackboard - editor",
				"Failed to move folder in UI from '%s' to '%s'" % [original_path, new_path],
				NFPluginGameHandler._LogLevel.ERROR)
	
	on_something_changed()


func _on_variable_dropped(origin_folder: String, variable: String, new_folder: String) -> void:
	if origin_folder == new_folder or new_folder.is_empty():
		return
	
	var strn_origin_folder: StringName = StringName(origin_folder)
	var strn_destination_folder: StringName = StringName(new_folder)
	var strn_original_var_name: StringName = StringName(variable)
	var strn_new_var_name: StringName = strn_original_var_name
	
	if not _variables_resource._variables.get(
				strn_origin_folder, NFDictUtils.EMPTY_DICT).has(
						strn_original_var_name):
		return
	
	var source_value: Variant = _variables_resource._variables[strn_origin_folder][strn_original_var_name]
	var is_replacing: bool = false
	var overwritten_value: Variant = null
	
	if _variables_resource._variables.get(strn_destination_folder, NFDictUtils.EMPTY_DICT).has(strn_new_var_name):
		var ren_rep_dialog: ConfirmationDialog = load("res://addons/nexus_forge/dialogs/three_option_dialog.gd").new()
		ren_rep_dialog.mid_button_text = "Rename"
		ren_rep_dialog.ok_button_text = "Replace"
		ren_rep_dialog.cancel_button_text = "Cancel"
		ren_rep_dialog.title = "Rename or skip variable"
		ren_rep_dialog.dialog_text = "Folder already has a variable '%s'" % variable
		
		EditorInterface.popup_dialog_centered(ren_rep_dialog)
		var result: Array = await ren_rep_dialog.dialog_finished
		ren_rep_dialog.hide()
		ren_rep_dialog.queue_free()
		
		if not result[0]:
			return
		
		var op_result: int = result[1]
		if op_result == 0:
			is_replacing = true
			overwritten_value = _variables_resource._variables[strn_destination_folder][strn_new_var_name]
		
		elif op_result == 1:
			var rename_dialog: ConfirmationDialog = load("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
			rename_dialog.title = "Rename"
			rename_dialog.ok_button_text = "Accept"
			rename_dialog.cancel_button_text = "Cancel"
			rename_dialog.use_blacklist = true
			
			for existing_variable in _variables_resource._variables[strn_destination_folder].keys():
				rename_dialog.text_blacklist.append(String(existing_variable))
			
			rename_dialog.allow_empty = false
			rename_dialog.error_line_blacklist_word_msg = "Variable name already used"
			
			EditorInterface.popup_dialog_centered(rename_dialog)
			rename_dialog.set_line_text(variable)
			rename_dialog.select_all_text()
			var rename_result: Array = await rename_dialog.dialog_finished
			rename_dialog.hide()
			rename_dialog.queue_free()
			
			if not rename_result[0]:
				return
			
			var picked_variable: String = rename_result[1]
			strn_new_var_name = StringName(picked_variable)
	
	undo.create_action("Move Variable")
	undo.add_do_method(_do_move_variable.bind(strn_origin_folder, strn_original_var_name, strn_destination_folder, strn_new_var_name, source_value))
	
	if is_replacing:
		undo.add_undo_method(_undo_replace_variable.bind(strn_origin_folder, strn_original_var_name, strn_destination_folder, strn_new_var_name, source_value, overwritten_value))
	else:
		undo.add_undo_method(_do_move_variable.bind(strn_destination_folder, strn_new_var_name, strn_origin_folder, strn_original_var_name, source_value))
		
	undo.commit_action()
	
	on_something_changed()


func set_sorting_column(column: int) -> void:
	variables_tree.sorting_column = clampi(column, 0, 1)


func get_sorting_column() -> int:
	return variables_tree.sorting_column


func set_resource_variable(folder: StringName, variable: StringName, data: Variant) -> void:
	if typeof(data) == TYPE_NIL:
		# Storing Nil variables isn't allowed for now.
		erase_variable(folder, variable)
		return
	
	if not _variables_resource._variables.has(folder):
		var new_folder: Dictionary[StringName, Variant] = {}
		_variables_resource._variables[folder] = new_folder
		NFPluginGameHandler._log_msg(
				"blackboard - editor",
				"Variable setter had to create folder. Folder '%s' didn't exist previously" % folder,
				NFPluginGameHandler._LogLevel.WARNING)
	
	_variables_resource._variables[folder][variable] = data


func erase_variable(folder: StringName, variable: StringName) -> void:
	_variables_resource._variables.get(folder, {}).erase(variable)


func create_folder(path: String, recursive: bool = true) -> void:
	if path.is_empty():
		return
	
	var strn_path: StringName = StringName(path)
	
	if recursive:
		var crumbs_path: String = ""
		var parts: PackedStringArray = path.split("/")
		for path_idx in range(parts.size() - 1):
			crumbs_path += parts[path_idx]
			var folder: StringName = StringName(crumbs_path)
			if not _variables_resource._variables.has(folder):
				_variables_resource._variables[folder] = NFDictUtils.create_typed(
						TYPE_STRING_NAME,
						TYPE_NIL)
			crumbs_path += "/"
	
	if not _variables_resource._variables.has(strn_path):
		_variables_resource._variables[strn_path] = NFDictUtils.create_typed(
				TYPE_STRING_NAME,
				TYPE_NIL)


func erase_folder(path: String) -> void:
	var prefix: String = path
	if not prefix.ends_with("/"):
		prefix += "/"
	
	_variables_resource._variables.erase(StringName(path))
	for folder_path:StringName in _variables_resource._variables.keys():
		if folder_path.begins_with(prefix):
			_variables_resource._variables.erase(folder_path)


func _do_move_variable(from_folder: StringName, from_var: StringName, to_folder: StringName, to_var: StringName, value: Variant) -> void:
	erase_variable(from_folder, from_var)
	set_resource_variable(to_folder, to_var, value)
	
	if String(from_folder) == _current_folder or String(to_folder) == _current_folder:
		refresh_current_variable_folder()


func _undo_replace_variable(from_folder: StringName, from_var: StringName, to_folder: StringName, to_var: StringName, source_value: Variant, overwritten_value: Variant) -> void:
	erase_variable(to_folder, to_var)
	set_resource_variable(from_folder, from_var, source_value)
	
	set_resource_variable(to_folder, to_var, overwritten_value)
	
	if String(from_folder) == _current_folder or String(to_folder) == _current_folder:
		refresh_current_variable_folder()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(undo):
			undo.clear_history()
			undo.free()
			undo = null
