class_name DictUtils
extends RefCounted


static func has_nested_path(dict: Dictionary, keys: Array) -> bool:
	var current: = dict
	
	for next_key in keys:
		if typeof(current) != TYPE_DICTIONARY or not current.has(next_key):
			return false
		current = current[next_key]
	
	return true


static func get_nested_value(from: Dictionary, keys: Array, default = null) -> Variant:
	var current: = from
	
	for key_value in keys:
		if typeof(current) == TYPE_DICTIONARY and current.has(key_value):
			current = current[key_value]
		else:
			return default
	
	return current


## Returns [code]true[/code] if it was able to set the value, otherwise returns
## [code]false[/code]. By default it'll create dictionaries as needed, but
## if [param create_dictionaries] is set to [code]false[/code] it'll
## only set a value if the nesting already exists.
static func set_nested_value(on: Dictionary, keys: Array, value, create_dictionaries: bool = true) -> bool:
	if keys.is_empty():
		return false
	
	var current: Dictionary = on
	
	for idx in range(keys.size() - 1):
		if not current.has(keys[idx]): # The key doesn't exist
			if not create_dictionaries:
				return false
			var new_dict: Dictionary = {}
			current[keys[idx]] = new_dict
			current = new_dict
		elif typeof(current[keys[idx]]) != TYPE_DICTIONARY: # The key exists but it isn't a dictionary.
			return false
		else: # THe key exists and it is a dictionary
			current = current[keys[idx]]
	
	current[keys[-1]] = value
	
	return true
