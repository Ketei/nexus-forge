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


@export_storage var _variables: Dictionary[StringName, Dictionary] = {}

var _active_variables: Dictionary[StringName, Dictionary] = {}


func _get_folder_parts(path: String) -> Dictionary[String, Variant]:
	path = path.simplify_path()
	var pieces: PackedStringArray = path.rsplit("/", false, 1)
	var parts: Dictionary[String, Variant] = {
		"folder": &"",
		"variable": &"",
		"path": path,
		"parsed": false}
	
	if pieces.size() != 2:
		return parts
	
	parts["folder"] = StringName(pieces[0])
	parts["variable"] = StringName(pieces[1])
	parts["parsed"] = true
	
	return parts


## Returns true if a variable exist with the path [param path]
func has_variable(path: StringName) -> bool:
	var parts: Dictionary[String, Variant] = _get_folder_parts(path)
	
	if not parts["parsed"]:
		return false
	
	if _active_variables.has(parts["folder"]) and _active_variables[parts["folder"]].has(parts["variable"]):
		return true
	
	return _variables.has(parts["folder"]) and _variables[parts["folder"]].has(parts["variable"])


## Returns true if the folder on [param folder_path] exists. This is different from
## checking if a variable exists.
func has_folder(folder_path: String) -> bool:
	var path: StringName = StringName(folder_path.simplify_path())
	return _active_variables.has(path) or _variables.has(path)


## Returns a variable on [param variable_path] or null if the variable doesn't exist.
func get_variable(path: String, fallback: Variant = null) -> Variant:
	var parts: Dictionary[String, Variant] = _get_folder_parts(path)
	if not parts["parsed"]:
		return fallback
	
	if _active_variables.has(parts["folder"]) and _active_variables[parts["folder"]].has(parts["variable"]):
		return _active_variables[parts["folder"]][parts["variable"]]
	elif _variables.has(parts["folder"]) and _variables[parts["folder"]].has(parts["variable"]):
		return _variables[parts["folder"]][parts["variable"]]
	else:
		return fallback


## Returns an array containing the variable keys in
## the specified [param folder_path]
func variables(folder_path: String) -> Array[String]:
	var keys: Array[String] = []
	var keys_dict: Dictionary[StringName, Variant] = {}
	var clean_path: StringName = StringName(folder_path.simplify_path())
	
	if _active_variables.has(clean_path):
		for var_key in _active_variables[clean_path]:
			keys_dict[var_key] = null
	if _variables.has(clean_path):
		for var_key in _variables[clean_path]:
			keys_dict[var_key] = null
	
	keys.assign(keys_dict.keys())
	return keys


## Returns a list of folders at [param level]. If empty it'll return all
## folders on the top level.
func folders(at: String = "") -> Array[String]:
	var clean_level: String = at.simplify_path()
	
	var all_folders: Array[String] = []
	var all_folder_entries: Dictionary[String, Variant] = {}
	var slice_count: int = clean_level.get_slice_count("/")
	
	if clean_level.is_empty():
		for folder:StringName in _variables:
			var path: String = String(folder)
			if path.get_slice_count("/") == 1:
				all_folder_entries[path] = null
		for folder:StringName in _active_variables:
			var path: String = String(folder)
			if path.get_slice_count("/") == 1:
				all_folder_entries[path] = null
	else:
		for folder:StringName in _variables:
			var path: String = String(folder)
			var path_slice_count: int = path.get_slice_count("/")
			if path.begins_with(clean_level) and slice_count + 1 == path_slice_count:
				all_folder_entries[clean_level + "/" + path.get_slice("/", 2)] = null
		for folder:StringName in _active_variables:
			var path: String = String(folder)
			var path_slice_count: int = path.get_slice_count("/")
			if path.begins_with(clean_level) and slice_count + 1 == path_slice_count:
				all_folder_entries[clean_level + "/" + path.get_slice("/", 2)] = null
	
	all_folders.assign(all_folder_entries.keys())
	return all_folders


## Will set a variable with the given path. Setting a variable to [code]null[/code]
## will erase the variable if it exists.[br]
## Returns [code]true[/code] if the value was set correctly
func set_variable(variable_path: String, value: Variant) -> bool:
	var parts: Dictionary[String, Variant] = _get_folder_parts(variable_path)
	var on_active: bool = _active_variables.has(parts["folder"])
	
	if not parts["parsed"] or not (on_active or _variables.has(parts["folder"])):
		NFPluginGameHandler._log_msg(
				"blackboard",
				"Tried to set variable with value '%s' on an invalid or inexistent path: '%s'. Ignoring." % [var_to_str(value), parts["path"]],
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	if value == null:
		if on_active and _active_variables[parts["folder"]].erase(parts["variable"]):
			data_erased.emit(parts["path"])
	else:
		if not _active_variables.has(parts["folder"]):
			_active_variables[parts["folder"]] = DictUtils.create_typed(
					TYPE_STRING_NAME,
					TYPE_NIL)
		_active_variables[parts["folder"]][parts["variable"]] = value
		data_set.emit(parts["path"])
	return true


## Creates a directory recursively.
func create_folder(folder_path: String) -> void:
	var clean_path: StringName = folder_path.simplify_path()
	var exists: bool = _variables.has(clean_path)
	var slices: Array[String] = []
	
	var slice_path: StringName = &""
	
	for slice in clean_path.split("/"):
		slice_path += StringName(slice)
		if not _active_variables.has(slice_path):
			_active_variables[slice_path] = DictUtils.create_typed(
					TYPE_STRING_NAME, TYPE_NIL)
		slice_path += &"/"
	
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
	
	_active_variables.erase(StringName(clean_path))
	
	for folder:StringName in _active_variables.keys():
		if folder.begins_with(subfolder_path):
			_active_variables.erase(folder)
	if _active_variables.size() != initial_size:
		folder_erased.emit(clean_path)


## Returns true if folder in [param folder_path] is empty or doesn't exist.
func is_folder_empty(folder_path: String) -> bool:
	var clean_path: StringName = StringName(folder_path.simplify_path())
	if _active_variables.has(clean_path) and not _active_variables[clean_path].is_empty():
		return false
	
	if _variables.has(clean_path):
		return _variables[clean_path].is_empty()
	
	return true


## Resets a variable to its default value. Returns whether a variable was
## deleted or not.[br]
## [b]Note:[/b] Calling this on a programmatically created variable will erase
## it instead.
func reset_variable(variable_path: String) -> bool:
	var parts: Dictionary[String, Variant] = _get_folder_parts(variable_path)
	if not parts["parsed"]:
		return false
	
	if _active_variables.has(parts["folder"]):
		return _active_variables[parts["folder"]].erase(parts["variable"])
	return false


## Resets the object's data to the default state.
func reset_data() -> void:
	_active_variables.clear()


## Returns a dictionary containing the changed data on this object. If
## [param deep_copy] is [code]true[/code] it'll return a copy of the entire state
## including the default parameters.
func get_state(deep_copy: bool = false) -> Dictionary[StringName, Dictionary]:
	var current_state: Dictionary[StringName, Dictionary] = {}
	
	if deep_copy:
		current_state.merge(_variables.duplicate(true))
	
	current_state.merge(_active_variables.duplicate(true), true)
	
	return current_state


## Restores a state based on a dictionary.
func set_state(state: Dictionary) -> void:
	for key in state:
		var type: int = typeof(key)
		if type != TYPE_STRING_NAME and type != TYPE_STRING:
			continue
		var val_type: int = typeof(state[key])
		if val_type != TYPE_DICTIONARY:
			continue
		var clean_path: String = key.simplify_path()
		create_folder(clean_path)
		for sub_key in state[key]:
			var sub_key_type: int = typeof(sub_key)
			if sub_key_type != TYPE_STRING_NAME and sub_key_type != TYPE_STRING:
				continue
			
			if _matches_base(clean_path, sub_key, state[key][sub_key]):
				continue
			
			var var_val_type: int = typeof(state[key][sub_key])
			var can_dupe: bool = var_val_type == TYPE_DICTIONARY or var_val_type == TYPE_ARRAY
			
			if can_dupe:
				_active_variables[clean_path][StringName(sub_key)] = state[key][sub_key].duplicate(true)
			else:
				_active_variables[clean_path][StringName(sub_key)] = state[key][sub_key]
	
	# Cleaning empty folders created by create_folder but whose state matched
	# the default.
	for folder in _active_variables.keys():
		if _active_variables[folder].is_empty():
			_active_variables.erase(folder)


func _matches_base(path: StringName, var_id: StringName, what: Variant) -> bool:
	var what_type: int = typeof(what)
	return _variables.has(path) and\
			_variables[path].has(var_id) and\
			typeof(_variables[path][var_id]) == what_type and\
			_variables[path][var_id] == what
