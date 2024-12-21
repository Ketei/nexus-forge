@tool
class_name NFVariablesRes
extends Resource


const SETTINGS_PATH = "nexus_forge/variables_resource"

## A dictionary containing all variables and folders. The first level is always
## folders.
@export var variables: Dictionary = {}


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
	var path_levels: Array = variable_path.split("/", false)
	var _level_mem: Dictionary = variables
	var var_name: String = path_levels.pop_back()
	var top_skip: bool = false
	
	for level in path_levels:
		if not top_skip:
			_level_mem = _level_mem[level]
			top_skip = true
			continue
		if _level_mem["subfolders"].has(level):
			_level_mem = _level_mem["subfolders"][level]
		else:
			return null
	
	if _level_mem["variables"].has(var_name):
		return _level_mem["variables"][var_name]
	else:
		return null


func get_variables_in_folder(folder_path: String) -> Dictionary:
	var levels: PackedStringArray = folder_path.split("/", false)
	var current_level: Dictionary = variables[levels[0]]
	var root_skipped: bool = false
	
	for level in levels:
		if not root_skipped:
			root_skipped = true
			continue
		current_level = current_level["subfolders"][level]
	
	return current_level["variables"].duplicate()


## Will set a variable with the given path. It'll also create "folders" recursively
## to create the variable.
func set_variable(variable_path: String, variable: Variant) -> void:
	var path: PackedStringArray = variable_path.split("/", false)
	var level_memory: Dictionary = variables[path[0]]
	var var_name: String = path[-1]
	path.resize(path.size() - 1)
	var front_skip: bool = false
	
	for folder in path:
		if not front_skip:
			front_skip = true
			continue
		level_memory = level_memory["subfolders"][folder]
	
	level_memory["variables"][var_name] = variable


## Creates a folder at the given path. It'll recursively create folders
## until [param folder_path] is reached
func create_folder(folder_path: String) -> void:
	var path: PackedStringArray = folder_path.split("/", false)
	
	if not variables.has(path[0]):
		variables[path[0]] = {"variables": {}, "subfolders": {}}
	
	var level_memory: Dictionary = variables[path[0]]
	var front_skip: bool = false
	
	for folder in path:
		if not front_skip:
			front_skip = true
			continue
		if not level_memory["subfolders"].has(folder):
			level_memory["subfolders"][folder] = {"variables": {}, "subfolders": {}}
		level_memory = level_memory["subfolders"][folder]


## Deletes a variable at the given path.
func delete_variable(variable_path: String) -> void:
	var path: PackedStringArray = variable_path.split("/", false)
	var var_name: String = path[-1]
	path.resize(path.size() -1)
	var level_memory: Dictionary = variables
	var front_skip: bool = false
	
	for folder in path:
		if not front_skip:
			level_memory = level_memory[folder]
			front_skip = true
			continue
		if level_memory["subfolders"].has(folder):
			level_memory = level_memory["subfolders"][folder]
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


func save() -> void:
	ResourceSaver.save(
		self,
		ProjectSettings.get_setting(SETTINGS_PATH, "res://variables_resource.tres"))
