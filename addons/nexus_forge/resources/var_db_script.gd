@tool
class_name NFVariablesRes
extends Resource
## A resource used to hold variables in a structured manner.
##
## The resource is able to keep track of folders and variables. Names
## of variables must be exclusive to each other, and same for folders
## but a variable and a folder can share the same name.


const SETTINGS_PATH = "nexus_forge/variables_resource"

## A dictionary containing all variables and folders. The first level is always
## folders.
@export var variables: Dictionary = {}
## A dictionary containing all the shortcuts.
var shortcuts: Dictionary = {}

## Creates a shortcut with [param shortcut_id] to a folder's variables for
## quicker access.[br]
## Setting and getting a variable via a shortcut skips the regular validation of
## [method get_variable] and [method set_variable]. Instead it only does
## a single hash check.[br]
## Returns [code]null[/code] if the shortcut was not created.[br]
## Shortcuts are passed by reference.
func create_shortcut(shortcut_id: String, to_folder: String) -> NFVariablesShortcut:
	if shortcuts.has(shortcut_id) or not has_folder(to_folder):
		return null
	
	var path_levels: PackedStringArray = to_folder.split("/")
	
	if path_levels.size() == 1:
		var root_shortcut := NFVariablesShortcut.new()
		root_shortcut._dictionary = variables[path_levels[0]]["variables"]
		root_shortcut._path = to_folder
		shortcuts[shortcut_id] = root_shortcut
		return root_shortcut
	
	var dict_level: Dictionary = variables[path_levels[0]]["subfolders"]
	var target_folder: String = path_levels[-1]
	
	path_levels.remove_at(0)
	path_levels.resize(path_levels.size() - 1)
	
	for level in path_levels:
		dict_level = dict_level[level]["subfolders"]
	
	var shortcut := NFVariablesShortcut.new()
	shortcut._dictionary = dict_level[target_folder]["variables"]
	shortcut._path = to_folder
	
	shortcuts[shortcut_id] = shortcut
	
	return shortcut


## Updates a shortcut to point to a new folder. Returns [code]true[/code]
## if the update was successful.
func update_shortcut(shortcut_id: String, to_folder: String) -> bool:
	if not shortcuts.has(shortcut_id) or not has_folder(to_folder):
		return false
	
	var path_levels: PackedStringArray = to_folder.split("/")
	
	if path_levels.size() == 1:
		shortcuts[shortcut_id]._dictionary = variables[path_levels[0]]["variables"]
		shortcuts[shortcut_id]._path = to_folder
		return true
	
	var dict_level: Dictionary = variables
	var target_folder: String = path_levels[-1]
	
	path_levels.resize(path_levels.size() - 1)
	
	for level in path_levels:
		dict_level = dict_level[level]["subfolders"]
	
	shortcuts[shortcut_id]._dictionary = dict_level[target_folder]["variables"]
	shortcuts[shortcut_id]._path = to_folder
	
	return true


## Returns [code]true[/code] if a shortcut with [param shortcut_id] exists.
func has_shortcut(shortcut_id: String) -> bool:
	return shortcuts.has(shortcut_id)


## Deletes a [param shortcut_id] if it exists. The resource will be
## freed at idle time.
func erase_shortcut(shortcut_id: String) -> void:
	if shortcuts.has(shortcut_id):
		shortcuts[shortcut_id]._dictionary = {}
		shortcuts[shortcut_id]._path = ""
		shortcuts[shortcut_id].free.call_deferred()
		shortcuts.erase(shortcut_id)


## Returns the shortcut assigned to [param shortcut_id].[br]
## Returns [code]null[/code] if there is no [param shortcut_id] registered.
func get_shortcut(shortcut_id: String) -> NFVariablesShortcut:
	if shortcuts.has(shortcut_id):
		return shortcuts[shortcut_id]
	return null


## Returns true if a variable exist with the path [param var_path]
func has_variable(var_path: String) -> bool:
	var path_levels: PackedStringArray = var_path.split("/", false)
	
	if path_levels.size() <= 1:
		return false
	
	var _level_mem: Dictionary = variables
	var var_name: String = path_levels[-1]
	var target_folder: String = path_levels[-2]
	
	path_levels.resize(path_levels.size() - 2)
	
	for level in path_levels:
		if _level_mem.has(level):
			_level_mem = _level_mem[level]["subfolders"]
		else:
			return false
	
	return _level_mem[target_folder]["variables"].has(var_name)


## Returns true if the folder on [param folder_path] exists. This is different from
## checking if a variable exists.
func has_folder(folder_path: String) -> bool:
	var path_levels: PackedStringArray = folder_path.split("/", false)
	
	if path_levels.is_empty():
		return false
	
	if path_levels.size() == 1:
		return variables.has(path_levels[0])
	
	var _level_mem: Dictionary = variables
	
	for level in path_levels:
		if _level_mem.has(level):
			_level_mem = _level_mem[level]["subfolders"]
		else:
			return false
	
	return true


## Returns a variable on [param variable_path] or null if the variable doesn't exist.
func get_variable(variable_path: String) -> Variant:
	var path_levels: PackedStringArray = variable_path.split("/", false)
	if path_levels.size() <= 1:
		return null
	
	var _level_mem: Dictionary = variables
	var var_name: String = path_levels[-1]
	var target_folder: String = path_levels[-2]
	
	path_levels.resize(path_levels.size() - 2)
	
	for level in path_levels:
		if _level_mem.has(level):
			_level_mem = _level_mem[level]["subfolders"]
		else:
			return null
	
	if _level_mem[target_folder]["variables"].has(var_name):
		return _level_mem[target_folder]["variables"][var_name]
	else:
		return null


## Returns an array with the variable id's in the folder [param folder_path].
func get_variables_in_folder(folder_path: String) -> PackedStringArray:
	var levels: PackedStringArray = folder_path.split("/", false)
	
	if levels.is_empty():
		return PackedStringArray()
	
	var current_level: Dictionary = variables[levels[0]]
	
	levels.remove_at(0)
	
	for level in levels:
		if not current_level["subfolders"].has(level):
			return PackedStringArray()
		
		current_level = current_level["subfolders"][level]
	
	return PackedStringArray(current_level["variables"].keys())


## Returns the dictionary containing the variables in
## the specified [param folder_path]
func get_variables(folder_path: String) -> Dictionary:
	var levels: PackedStringArray = folder_path.split("/", false)
	
	if levels.is_empty():
		return {}
	
	var current_level: Dictionary = variables
	var target_folder: String = levels[-1]
	
	levels.resize(levels.size() - 1)
	
	for level in levels:
		if not current_level.has(level):
			return {}
		
		current_level = current_level[level]["subfolders"]
	
	return current_level[target_folder]["variables"]


## Will set a variable with the given path. Returns [code]true[/code] if
## the variable was properly set.
func set_variable(variable_path: String, variable: Variant) -> bool:
	var path: PackedStringArray = variable_path.split("/", false)
	if path.size() <= 1:
		return false
	
	var level_memory: Dictionary = variables
	var var_name: String = path[-1]
	var target_folder: String = path[-2]
	
	path.resize(path.size() - 2)
	
	for folder in path:
		if not level_memory.has(folder):
			return false
		level_memory = level_memory[folder]["subfolders"]
	
	level_memory[target_folder]["variables"][var_name] = variable
	return true


func set_variables(folder_path: String, set_variables: Dictionary) -> void:
	var path: PackedStringArray = folder_path.split("/", false)
	if path.size() <= 1:
		return
	
	var level_memory: Dictionary = variables
	var target_folder: String = path[-1]
	
	path.resize(path.size() - 1)
	
	for folder in path:
		if not level_memory.has(folder):
			return
		level_memory = level_memory[folder]["subfolders"]
	
	level_memory[target_folder]["variables"].merge(set_variables, true)


## Creates a folder at the given path. It'll recursively create folders
## until [param folder_path] is reached.
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
	
	for shortcut: String in shortcuts:
		if shortcuts[shortcut].get_folder_path().begins_with(folder_path):
			erase_shortcut(shortcut)


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


## A shortcut poiting to a variables folder on a [NFVariablesRes] instance.
class NFVariablesShortcut extends RefCounted:
	var _path: String = ""
	var _dictionary: Dictionary = {}
	
	
	## Returns a variable value or null if variable doesn't exist.
	func get_variable(variable_id: String) -> Variant:
		if _dictionary.has(variable_id):
			return _dictionary[variable_id]
		return null
	
	
	## Sets a variable.
	func set_variable(variable_id: String, variable: Variant) -> void:
		_dictionary[variable_id] = variable
	
	
	## Erases variable_id. Returns true if successful
	func erase_variable(variable_id: String) -> bool:
		return _dictionary.erase(variable_id)
	
	
	## Returns true if the folder has variable_id.
	func has_variable(variable_id: String) -> bool:
		return _dictionary.has(variable_id) 
	
	
	## Returns all the variables stored in the folder.
	func get_variable_ids() -> PackedStringArray:
		return PackedStringArray(_dictionary.keys())
	
	
	## Returns the variables folder path this shortcut is pointing at.
	func get_folder_path() -> String:
		return _path
