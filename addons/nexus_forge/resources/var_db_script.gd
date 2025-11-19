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

## A dictionary containing all variables and folders. The first level is always
## folders.
@export_storage var _variables: Dictionary[StringName, Dictionary] = {}


func _clean_folder_path(path: String) -> StringName:
	return StringName(path.simplify_path())


## Returns true if a variable exist with the path [param var_path]
func has_variable(folder: String, variable: StringName) -> bool:
	var clean_path: StringName = _clean_folder_path(folder)
	return _variables.has(clean_path) and _variables[clean_path].has(variable)


## Returns true if the folder on [param folder_path] exists. This is different from
## checking if a variable exists.
func has_folder(folder_path: String) -> bool:
	return _variables.has(_clean_folder_path(folder_path))


## Returns a variable on [param variable_path] or null if the variable doesn't exist.
func get_variable(folder: String, variable: StringName) -> Variant:
	var clean_folder: StringName = _clean_folder_path(folder)
	if _variables.has(clean_folder) and _variables[clean_folder].has(variable):
		return _variables[clean_folder][variable]
	else:
		return null


## Returns an array containing the variable keys in
## the specified [param folder_path]
func variables(folder_path: String) -> Array[String]:
	var keys: Array[String] = []
	var clean_path: StringName = _clean_folder_path(folder_path)
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
			if path.get_slice_count("/") == 0:
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
func set_variable(folder_path: String, variable_key: StringName, variable: Variant) -> void:
	var clean_path: StringName = _clean_folder_path(folder_path)
	if variable == null:
		if _variables.has(clean_path) and _variables[clean_path].has(variable_key):
			_variables[clean_path].erase(variable_key)
	else:
		_variables[clean_path][variable_key] = variable


## Creates a folder structure.
func create_folder(folder_path: String) -> void:
	var clean_path: StringName = _clean_folder_path(folder_path)
	var slices: Array[String] = []
	
	var slice_path: StringName = &""
	
	for slice in clean_path.split("/"):
		slice_path += StringName(slice)
		if not _variables.has(slice_path):
			var new_vars: Dictionary[StringName, Variant] = {}
			_variables[slice_path] = new_vars
		slice_path += &"/"


## Deletes a folder in the given path, including all their variables and
## subfolders.
func erase_folder(folder_path: StringName) -> void:
	for folder:StringName in _variables.keys():
		if folder.begins_with(folder_path):
			_variables.erase(folder)


## Returns true if folder in [param folder_oath] is empty or doesn't exist.
func is_folder_empty(folder_path: String) -> bool:
	var clean_path: StringName = _clean_folder_path(folder_path)
	if _variables.has(clean_path):
		return _variables[clean_path].is_empty()
	else:
		return true


## Erases all folders and variables.
func clear() -> void:
	_variables.clear()
