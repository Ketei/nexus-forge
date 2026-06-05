@tool
@icon("res://addons/nexus_forge/icons/variable_icon.svg")
class_name BlackboardData
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
	return parts["parsed"] and _variables.has(parts["folder"]) and _variables[parts["folder"]].has(parts["variable"])


## Returns true if the folder on [param folder_path] exists. This is different from
## checking if a variable exists.
func has_folder(folder_path: String) -> bool:
	var path: StringName = StringName(folder_path.simplify_path())
	return _variables.has(path)


## Returns a variable on [param variable_path] or null if the variable doesn't exist.
func get_variable(path: String, fallback: Variant = null) -> Variant:
	var parts: Dictionary[String, Variant] = _get_folder_parts(path)
	if parts["parsed"] and _variables.has(parts["folder"]) and _variables[parts["folder"]].has(parts["variable"]):
		return _variables[parts["folder"]][parts["variable"]]
	else:
		return fallback


## Returns an array containing the variable keys in
## the specified [param folder_path]
func variables(folder_path: String) -> Array[String]:
	var keys: Array[String] = []
	var clean_path: StringName = StringName(folder_path.simplify_path())
	if _variables.has(clean_path):
		keys.assign(_variables[clean_path].keys())
	return keys


## Returns a list of folders at [param level]. If empty it'll return all
## folders on the top level.
func folders(at: String = "") -> Array[String]:
	var clean_level: String = at.simplify_path()
	
	var all_folders: Array[String] = []
	var slice_count: int = clean_level.get_slice_count("/")
	
	if clean_level.is_empty():
		for folder:StringName in _variables.keys():
			var path: String = String(folder)
			if path.get_slice_count("/") == 1:
				all_folders.append(path)
	else:
		for folder:StringName in _variables.keys():
			var path: String = String(folder)
			var path_slice_count: int = path.get_slice_count("/")
			if path.begins_with(clean_level) and slice_count + 1 == path_slice_count:
				all_folders.append(clean_level + "/" + path.get_slice("/", 2))
	
	return all_folders


## Will set a variable with the given path. Setting a variable to [code]null[/code]
## will erase the variable if it exists
func set_variable(variable_path: String, value: Variant) -> void:
	var parts: Dictionary[String, Variant] = _get_folder_parts(variable_path)
	
	if not parts["parsed"] or not _variables.has(parts["folder"]):
		push_error("[NEXUS FORGE] Blackboard - Tried to set variable with (", value, ") in an invalid or inexistent path:\" ", parts["path"], "\"")
		return
	
	if value == null:
		if _variables[parts["folder"]].erase(parts["variable"]):
			data_erased.emit(parts["path"])
	else:
		_variables[parts["folder"]][parts["variable"]] = value
		data_set.emit(parts["path"])


## Creates a directory recursively.
func create_folder(folder_path: String) -> void:
	var clean_path: StringName = folder_path.simplify_path()
	var exists: bool = _variables.has(clean_path)
	var slices: Array[String] = []
	
	var slice_path: StringName = &""
	
	for slice in clean_path.split("/"):
		slice_path += StringName(slice)
		if not _variables.has(slice_path):
			var new_vars: Dictionary[StringName, Variant] = {}
			_variables[slice_path] = new_vars
		slice_path += &"/"
	
	if not exists:
		folder_created.emit(clean_path)


## Deletes a folder in the given path, including all their variables and
## subfolders.
func erase_folder(folder_path: String) -> void:
	var clean_path: String = folder_path.simplify_path()
	var exists: bool = _variables.has(StringName(clean_path))
	if not exists:
		return
	for folder:StringName in _variables.keys():
		if folder.begins_with(clean_path):
			_variables.erase(folder)
	folder_erased.emit(clean_path)


## Returns true if folder in [param folder_oath] is empty or doesn't exist.
func is_folder_empty(folder_path: String) -> bool:
	var clean_path: StringName = StringName(folder_path.simplify_path())
	if _variables.has(clean_path):
		return _variables[clean_path].is_empty()
	else:
		return true


## Erases all folders and variables.
func clear() -> void:
	_variables.clear()
