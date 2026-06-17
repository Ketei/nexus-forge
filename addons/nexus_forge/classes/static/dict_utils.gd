class_name DictUtils
extends RefCounted
## A collection of static utility methods for changing, validating and getting
## values from dictionaries.

## Returns [code]true[/code] if the [param dict] has any of the [param keys] given.
static func has_any(dict: Dictionary, keys: Array) -> bool:
	for key in keys:
		if dict.has(key):
			return true
	return false


## Returns [code]true[/code] if the [param dict] has nested keys in the order provided
## on [param keys].
## [codeblock]
## var dict = { "top": { "middle": {"bottom": true} } }
## DictUtils.has_nested_path(dict, ["top", "middle", "bottom"]) # Returns true
## DictUtils.has_nested_path(dict, ["top", "middle"]) # Returns true
## DictUtils.has_nested_path(dict, ["top", "bottom", "middle"]) # Returns false
## [/codeblock]
static func has_nested_path(dict: Dictionary, keys: Array) -> bool:
	var current = dict
	
	for next_key in keys:
		if typeof(current) != TYPE_DICTIONARY or not current.has(next_key):
			return false
		current = current[next_key]
	
	return true


## Returns the value of a key from a path of nested dictionaries in [param from].
## The keys path follows the order in [param keys]. And if the path doesn't
## exist, or there is no value for the last key then [param default] is returned.[br]
## If match_default_type is set to [code]true[/code] then the data type of the value
## must match that of [param default] to be returned, if not [param default] will
## be returned instead.[br]
## [codeblock]
## var dict = { "fruits": { "orange": {"amount": 621} } }
## DictUtils.get_nested_value(dict, ["fruits", "orange", "amount"]) # Returns 621
## DictUtils.get_nested_value(dict, ["fruits", "orange", "count"]) # Returns null
## DictUtils.get_nested_value(dict, ["fruits", "apples"], 10) # Returns 10
## DictUtils.get_nested_value(dict, ["fruits", "apples"], Vector2i(0,0)) # Returns Vector2i(0,0)
## [/codeblock]
static func get_nested_value(from: Dictionary, keys: Array, default = null, match_default_type: bool = false) -> Variant:
	var current = from
	
	for key_value in keys:
		if typeof(current) == TYPE_DICTIONARY and current.has(key_value):
			current = current[key_value]
		else:
			return default
	
	if match_default_type:
		return current if typeof(current) == typeof(default) else default
	else:
		return current


## Returns [code]true[/code] if it was able to set the value, otherwise returns
## [code]false[/code]. By default it'll create dictionaries as needed, but
## if [param create_dictionaries] is set to [code]false[/code] it'll
## only set a value if the nesting already exists.[br]
## [codeblock]
## var dict = { "inventory": { "potions": {"blue": 0} } }
## DictUtils.set_nested_value(dict, ["inventory", "potions", "blue"], 10) # Returns true
## print(dict) # Prints { "inventory": { "potions": {"blue": 10} } }
## DictUtils.set_nested_value(dict, ["inventory", "food", "kiwi"], 2, false) # Returns false
## print(dict) # Prints { "inventory": { "potions": {"blue": 10} } }
## DictUtils.set_nested_value(dict, ["inventory", "food", "kiwi"], 2) # Returns true
## print(dict) # Prints { "inventory": { "potions": {"blue": 10} }, "food": { "kiwi": 2 } }
## [/codeblock]
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


## Costructor for a dictionary with default parameters set.
static func create_typed(key_type: int, value_type: int, base: Dictionary = {}, key_class_name: StringName = &"", key_script: Variant = null, value_class_name: StringName = &"", value_script: Variant = null) -> Dictionary:
	return Dictionary(base, key_type, key_class_name, key_script, value_type, value_class_name, value_script)
