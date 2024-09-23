class_name NexusForgeVariables
extends Resource


## A dictionary containing all variables and folders. The first level is always
## folders.
@export var variables: Dictionary = {}
@export_flags("fire", "watur") var flags

## Returns true if a variable exist with the path [param var_path]
func has_variable(var_path: String) -> bool:
	var _level_mem: Dictionary = variables
	var path_levels: Array = var_path.split("/", false)
	var var_name: String = path_levels.pop_back()
	
	for level in path_levels:
		if _level_mem.has(level):
			_level_mem = _level_mem[level]["subfolders"]
		else:
			return false
	
	return _level_mem["variables"].has(var_name)


## Returns true if the folder on [param folder_path] exists. This is different from
## checking if a variable exists.
func has_folder(folder_path: String) -> bool:
	var _level_mem: Dictionary = variables
	var path_levels: Array = folder_path.split("/", false)
	var folder_name: String = path_levels.pop_back()
	
	for level in path_levels:
		if _level_mem.has(level):
			_level_mem = _level_mem[level]["subfolders"]
		else:
			return false
	
	return _level_mem["subfolders"].has(folder_name)


## Returns a variable on [param variable_path] or null if the variable doesn't exist.
func get_variable(variable_path: String) -> Variant:
	var _level_mem: Dictionary = variables
	var path_levels: Array = variable_path.split("/", false)
	var var_name: String = path_levels.pop_back()
	
	for level in path_levels:
		if _level_mem["subfolders"].has(level):
			_level_mem = _level_mem[level]["subfolders"]
		else:
			return null
	
	if _level_mem["variables"].has(var_name):
		return _level_mem["variables"][var_name]
	else:
		return null


## Will set a variable with the given path. It'll also create "folders" recursively
## to create the variable.
func set_variable(variable_path: String, variable: Variant) -> void:
	var path: Array = variable_path.split("/", false)
	var var_name: String = path.pop_back()
	var level_memory: Dictionary = variables
	
	for folder in path:
		if not level_memory.has(folder):
			level_memory[folder] = {"variables": {}, "subfolders": {}}
		level_memory = level_memory[folder]["subfolders"]
	
	level_memory[var_name] = variable


## Deletes a variable at the given path.
func delete_variable(variable_path: String) -> void:
	var path: Array = variable_path.split("/", false)
	var var_name: String = path.pop_back()
	var level_memory: Dictionary = variables
	
	for folder in path:
		if level_memory.has(folder):
			level_memory = level_memory[folder]["subfolders"]
		else:
			return
	
	if level_memory["variables"].has(var_name):
		level_memory["variables"].erase(var_name)


## Deletes a folder in the given path, including all their variables.
func delete_folder(folder_path: String) -> void:
	var _level_mem: Dictionary = variables
	var path_levels: Array = folder_path.split("/", false)
	var folder_name: String = path_levels.pop_back()
	
	for level in path_levels:
		if _level_mem.has(level):
			_level_mem = _level_mem[level]["subfolders"]
		else:
			return
	
	if _level_mem.has(folder_path):
		_level_mem.erase(folder_name)


## Returns true if a folder doesn't cointain subfolders or variables. Check
## if a folder exists first with [member has_folder] first.
func is_folder_empty(folder_path: String) -> bool:
	var _level_mem: Dictionary = variables
	var path_levels: Array = folder_path.split("/", false)
	var folder_name: String = path_levels.pop_back()
	
	for level in path_levels:
		_level_mem = _level_mem[level]["subfolders"]
	
	return _level_mem[folder_name]["subfolders"].is_empty() and _level_mem[folder_name]["variables"].is_empty()
