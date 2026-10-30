@tool
@icon("res://addons/nexus_forge/icons/variable_icon.svg")
class_name NFBlackboardData
extends Resource
## A resource used to hold variables in a structured manner.
##
## The resource is able to keep track of folders and variables. Names
## of variables must be exclusive to each other, and same for folders
## but a variable and a folder can share the same name. All folder paths
## are simplified using [method String.simplify_path].


## Emmited when data is set via [method BlackboardData.set_variable].
signal data_set(variable_path: String)
## Emmited when data is erased via [method BlackboardData.set_variable].
signal data_erased(variable_path: String)
## Emmited only when a folder is created via [method BlackboardData.create_folder].
## If this function is called but no folder is created the signal won't be emmited.
signal folder_created(folder_path: String)
## Emmited when a folder is erased.
signal folder_erased(folder_path: String)


@export_storage var _variables: Dictionary[String, Dictionary] = {}

var _active_variables: Dictionary[String, Dictionary] = {}


func _get_folder_parts(path: String) -> Dictionary[String, Variant]:
	path = path.simplify_path()
	
	var parts: Dictionary[String, Variant] = {
		"folder": "",
		"variable": "",
		"path": path,
		"parsed": false}
	
	var slash_index: int = path.rfind("/")
	
	if 0 < slash_index and slash_index < path.length() - 1:
		parts["folder"] = path.substr(0, slash_index)
		parts["variable"] = path.substr(slash_index + 1)
		parts["parsed"] = true
	
	return parts


## Returns true if a variable exist with the path [param path]
func has_variable(path: String) -> bool:
	var parts: Dictionary[String, Variant] = _get_folder_parts(path)
	
	if not parts["parsed"]:
		return false
	
	var folder_path: String = parts["folder"]
	var variable_name: String = parts["variable"]
	
	var base_folder: Dictionary = _variables.get(folder_path, NFDictUtils.EMPTY_DICT)
	var active_folder: Dictionary = _active_variables.get(folder_path, NFDictUtils.EMPTY_DICT)
	
	return base_folder.has(variable_name) or active_folder.has(variable_name)


## Returns true if the folder on [param folder_path] exists. This is different from
## checking if a variable exists.
func has_folder(folder_path: String) -> bool:
	var path: String = folder_path.simplify_path()
	return _active_variables.has(path) or _variables.has(path)


## Returns a variable on [param variable_path] or null if the variable doesn't exist.
func get_variable(path: String, fallback: Variant = null) -> Variant:
	var parts: Dictionary[String, Variant] = _get_folder_parts(path)
	if not parts["parsed"]:
		return fallback
	
	var folder: String = parts["folder"]
	var variable: String = parts["variable"]
	
	var active_folder: Dictionary = _active_variables.get(folder, NFDictUtils.EMPTY_DICT)
	var base_folder: Dictionary = _variables.get(folder, NFDictUtils.EMPTY_DICT)
	
	if active_folder.has(variable):
		return active_folder[variable]
	return base_folder.get(variable, fallback)


## Returns an array containing the variable keys in
## the specified [param folder_path]
func variables(folder_path: String) -> Array[String]:
	var keys: Array[String] = []
	var keys_dict: Dictionary[String, Variant] = {}
	var clean_path: String = folder_path.simplify_path()
	
	for var_key in _active_variables.get(clean_path, NFDictUtils.EMPTY_DICT):
		keys_dict[var_key] = null

	for var_key in _variables.get(clean_path, NFDictUtils.EMPTY_DICT):
		keys_dict[var_key] = null
	
	if not keys_dict.is_empty():
		keys.assign(keys_dict.keys())
	
	return keys


## Returns a list of folders at [param level]. If empty it'll return all
## folders on the top level.
func folders(at: String = "") -> Array[String]:
	var clean_level: String = at.simplify_path()
	
	var all_folders: Array[String] = []
	var all_folder_entries: Dictionary[String, Variant] = {}
	
	if clean_level.is_empty():
		for folder:String in _variables:
			var path: String = folder
			if path.get_slice_count("/") == 1:
				all_folder_entries[path] = null
		for folder:String in _active_variables:
			var path: String = folder
			if path.get_slice_count("/") == 1:
				all_folder_entries[path] = null
	else:
		var prefix: String = clean_level + "/"
		var target_slice_count: int = clean_level.get_slice_count("/") + 1
		
		for folder:String in _variables:
			var path: String = folder
			if path.begins_with(prefix) and path.get_slice_count("/") == target_slice_count:
				all_folder_entries[path] = null
		
		for folder:String in _active_variables:
			var path: String = folder
			if path.begins_with(prefix) and path.get_slice_count("/") == target_slice_count:
				all_folder_entries[path] = null
	
	all_folders.assign(all_folder_entries.keys())
	return all_folders


## Will set a variable with the given path. Setting a variable to [code]null[/code]
## will erase the variable if it exists.[br]
## Returns [code]true[/code] if the value was set correctly
func set_variable(variable_path: String, value: Variant) -> bool:
	var parts: Dictionary[String, Variant] = _get_folder_parts(variable_path)
	var folder_path: String = parts["folder"]
	var on_active: bool = _active_variables.has(folder_path)
	
	if not parts["parsed"] or not (on_active or _variables.has(folder_path)):
		NFPluginGameHandler._log_msg(
				"blackboard",
				"Tried to set variable with value '%s' on an invalid or inexistent path: '%s'. Ignoring." % [var_to_str(value), parts["path"]],
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	if value == null:
		if on_active and _active_variables[folder_path].erase(parts["variable"]):
			data_erased.emit(parts["path"])
	else:
		if not _active_variables.has(folder_path):
			_active_variables[folder_path] = NFDictUtils.create_typed(
					TYPE_STRING,
					TYPE_NIL)
		_active_variables[folder_path][parts["variable"]] = value
		data_set.emit(parts["path"])
	return true


## Creates a directory recursively.
func create_folder(folder_path: String) -> void:
	var clean_path: String = folder_path.simplify_path()
	var exists: bool = _active_variables.has(clean_path) or _variables.has(clean_path)
	
	var slice_path: String = ""
	
	for slice in clean_path.split("/"):
		slice_path += slice
		if not _active_variables.has(slice_path):
			_active_variables[slice_path] = NFDictUtils.create_typed(
					TYPE_STRING, TYPE_NIL)
		slice_path += "/"
	
	if not exists:
		folder_created.emit(clean_path)


## Deletes a folder at the given [param folder_path], including all of its
## variables and subfolders.
## [br][br][b]Note:[/b] This operation only affects runtime data by erasing
## all active overrides, effectively resetting the folder and its contents
## back to their factory defaults.
## [br]Programmatically created folders and programmatically
## created variables inside of them will be completely erased.
func erase_folder(folder_path: String) -> void:
	var clean_path: String = folder_path.simplify_path()
	var subfolder_path: String = clean_path + "/"
	var initial_size: int = _active_variables.size()
	
	_active_variables.erase(clean_path)
	
	for folder:String in _active_variables.keys():
		if folder.begins_with(subfolder_path):
			_active_variables.erase(folder)
	if _active_variables.size() != initial_size:
		folder_erased.emit(clean_path)


## Returns true if folder in [param folder_path] is empty or doesn't exist.
func is_folder_empty(folder_path: String) -> bool:
	var clean_path: String = folder_path.simplify_path()
	
	var active_folder: Dictionary = _active_variables.get(clean_path, NFDictUtils.EMPTY_DICT)
	var base_folder: Dictionary = _variables.get(clean_path, NFDictUtils.EMPTY_DICT)
	
	return active_folder.is_empty() and base_folder.is_empty()


## Resets a variable to its default value. Returns whether a variable was
## reset or not.[br]
## [b]Note:[/b] Calling this on a programmatically created variable will erase
## it instead.
func reset_variable(variable_path: String) -> bool:
	var parts: Dictionary[String, Variant] = _get_folder_parts(variable_path)
	if not parts["parsed"]:
		return false
	
	if _active_variables.has(parts["folder"]):
		var erased: bool = _active_variables[parts["folder"]].erase(parts["variable"])
		if erased:
			data_erased.emit(parts["path"])
		return erased
	return false


## Resets the object's data to the default state.
func reset_data() -> void:
	_active_variables.clear()


## Returns a dictionary containing the changed data on this object. If
## [param deep_copy] is [code]true[/code] it'll return a copy of the entire state
## including the default parameters.
func get_state(deep_copy: bool = false) -> Dictionary[String, Dictionary]:
	var current_state: Dictionary[String, Dictionary] = {}
	
	if deep_copy:
		current_state.merge(_variables.duplicate(true))
	
	for folder:String in _active_variables:
		var active_folder_data: Dictionary[String, Variant] = _active_variables[folder].duplicate(true)
		
		if current_state.has(folder):
			current_state[folder].merge(active_folder_data, true)
		else:
			current_state[folder] = active_folder_data
	
	return current_state


## Restores a state based on a dictionary.[br]
## If [param clear_state] is [code]true[/code], then the current
## state will be cleared before loading the new [param state]
## similar to calling [method NFBlackboardData.reset_data].
func set_state(state: Dictionary, clear_state: bool = false) -> void:
	if clear_state:
		_active_variables.clear()
	
	for key in state:
		var type: int = typeof(key)
		if type != TYPE_STRING and type != TYPE_STRING_NAME:
			continue
		var val_type: int = typeof(state[key])
		if val_type != TYPE_DICTIONARY:
			continue
		
		var clean_path: String = String(key).simplify_path()
		var slice_path: String = ""
		
		for slice in clean_path.split("/"):
			slice_path += slice
			if not _active_variables.has(slice_path):
				_active_variables[slice_path] = NFDictUtils.create_typed(
						TYPE_STRING,
						TYPE_NIL)
			slice_path += "/"
		
		var folder_dict: Dictionary = _active_variables[clean_path]
		
		for sub_key in state[key]:
			var sub_key_type: int = typeof(sub_key)
			if sub_key_type != TYPE_STRING and sub_key_type != TYPE_STRING_NAME:
				continue
			
			var final_key: String = String(sub_key)
			var final_value: Variant = state[key][sub_key]
			if _matches_base(clean_path, final_key, final_value):
				folder_dict.erase(final_key)
				continue
			
			var var_val_type: int = typeof(final_value)
			var can_dupe: bool = var_val_type == TYPE_DICTIONARY or var_val_type == TYPE_ARRAY
			
			if can_dupe:
				folder_dict[final_key] = final_value.duplicate(true)
			else:
				folder_dict[final_key] =final_value
	
	# Cleaning empty folders created by create_folder but whose state matched
	# the default.
	for folder in _active_variables.keys():
		if _variables.has(folder) and _active_variables[folder].is_empty():
			_active_variables.erase(folder)


func _matches_base(path: String, var_id: String, what: Variant) -> bool:
	var what_type: int = typeof(what)
	return _variables.has(path) and\
			_variables[path].has(var_id) and\
			typeof(_variables[path][var_id]) == what_type and\
			_variables[path][var_id] == what
