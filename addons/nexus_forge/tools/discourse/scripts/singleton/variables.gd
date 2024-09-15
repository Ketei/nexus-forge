class_name GameVariables
extends Node


signal variable_updated


var _variables_map: Dictionary = {}


func set_variable(variable_path: String, variable_value: Variant) -> void:
	var path: PackedStringArray = variable_path.split("/", false)
	if path.is_empty():
		return
	var var_name: String = path[-1]
	var current_dict: Dictionary = _variables_map
	
	path.resize(path.size() - 1)
	
	for path_level in path:
		if not current_dict.has(path_level):
			current_dict[path_level] = {}
		else:
			if typeof(current_dict[path_level]) != TYPE_DICTIONARY:
				print(str("[VARIABLES] Warning. Overriding \"", path_level,  "\" variable type with a dictionary. Path given: ", "/".join(path)))
				current_dict[path_level] = {}
		current_dict = current_dict[path_level]
	current_dict[var_name] = variable_value
	variable_updated.emit()


func get_variable(variable_path: String) -> Variant:
	var levels: PackedStringArray = Strings.split_and_strip(variable_path.simplify_path(), "/")
	var var_name: String = levels[-1]
	var current_level: Dictionary = _variables_map
	var return_variant: Variant = null
	levels.resize(levels.size() - 1)
	for level in levels:
		if not current_level.has(level):
			break
		current_level = current_level[level]
	if current_level.has(var_name):
		return_variant = current_level[var_name]
	return return_variant


func has_variable(variable_path: String) -> bool:
	var levels: PackedStringArray = variable_path.split("/", false)
	var var_name: String = levels[-1]
	var current_level: Dictionary = _variables_map
	levels.resize(levels.size() - 1)
	
	for level in levels:
		if not current_level.has(level):
			return false
		current_level = current_level[level]
	
	return current_level.has(var_name)


func remove_variable(variable_path: String) -> void:
	var levels: PackedStringArray = variable_path.split("/", false)
	var var_name: String = levels[-1]
	var current_level: Dictionary = _variables_map
	levels.resize(levels.size() - 1)
	
	for level in levels:
		if not current_level.has(level):
			return
		current_level = current_level[level]
	
	current_level.erase(var_name)
	variable_updated.emit()


## Gets all the variables in it's path form.
func get_variable_paths() -> Array[String]:
	return _get_variable_keys(_variables_map)


func _get_variable_keys(dictionary: Dictionary, prefix: String = "") -> Array[String]:
	var named_keys: Array[String] = []
	
	for key in dictionary:
		if typeof(dictionary[key]) == TYPE_DICTIONARY:
			named_keys.append_array(
					_get_variable_keys(dictionary[key], prefix + key + "/"))
		else:
			named_keys.append(prefix + key)

	return named_keys
