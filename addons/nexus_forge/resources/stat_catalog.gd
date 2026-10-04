@tool
@icon("res://addons/nexus_forge/icons/stat_catalog.svg")
class_name NFStatCatalog
extends Resource
## A resource containing custom stats and its data.
##
## Custom stats will be included in all [NFStatBlock]'s custom stats instantiated
## with [method NFStatBlock.new_stat_block].


# Custom stats where the value is an integer array holding 2 values [min, max]
# &"health": {"name": "Health", "description": "Life!", "allow_*": true, "*_value": 0, "data": {}}
@export_storage var _stat_data: Dictionary[StringName, Dictionary] = {}


## Returns an array containing all registered stats.
func stats() -> Array[StringName]:
	return NFArrayUtils.create_typed(TYPE_STRING_NAME, _stat_data.keys())


## Returns ture if a stat [param stat_id] is registered.
func has_stat(stat_id: StringName) -> bool:
	return _stat_data.has(stat_id)


## Returns the built-in type of a stat.
func stat_type(stat_id: StringName) -> int:
	var type: int = NFDictUtils.get_nested_value(
			_stat_data,
			[stat_id, "type"],
			TYPE_FLOAT,
			true)
	
	if type != TYPE_INT and type != TYPE_FLOAT:
		return TYPE_FLOAT
	else:
		return type


## Sets the name of the [param stat_id] to [param new_name].
func set_stat_name(stat_id: StringName, new_name: String) -> void:
	if not _stat_data.has(stat_id):
		return
	
	_stat_data[stat_id]["name"] = new_name


## Sets the name of the [param stat_id] to [param description].
func set_stat_description(stat_id: StringName, description: String) -> void:
	if not _stat_data.has(stat_id):
		return
	
	_stat_data[stat_id]["description"] = description


## Gets the name of [param stat_id] or an empty string if not found.
func get_stat_name(stat_id: StringName) -> String:
	return _stat_data.get(stat_id, {}).get("name", "")


## Gets the name of [param stat_id] or an empty string if not found.
func get_stat_description(stat_id: StringName) -> String:
	return _stat_data.get(stat_id, {}).get("name", "")


## Sets the [param stat_id] custom data of key [param data_key] to
## [param data]. If param data is [code]null[/code] the entry is erased.
func set_stat_data(stat_id: StringName, data_key: StringName, data) -> void:
	if not _stat_data.has(stat_id):
		return
	
	if data == null:
		_stat_data[stat_id]["custom_data"].erase(data_key)
	else:
		_stat_data[stat_id]["custom_data"][data_key] = data


## Returns the custom data of [param stat_id] on key [param data_key].
## Returns [code]null[/code] if the entry is not found.
func get_stat_data(stat_id: StringName, data_key: String) -> Variant:
	var entry: Variant = _stat_data.get(stat_id)
	if typeof(entry) != TYPE_DICTIONARY:
		return null
	
	var data: Variant = entry.get("custom_data")
	if typeof(data) != TYPE_DICTIONARY:
		return null
	
	return data.get(data_key)


## Returns a copy of the custom data of the stat [param stat_id].
func stat_data(stat_id: StringName) -> Dictionary[StringName, Variant]:
	var entry: Variant = _stat_data.get(stat_id)
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	
	var data: Variant = entry.get("custom_data")
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	
	var custom_data: Dictionary[StringName, Variant] = {}
	custom_data.assign(data)
	return custom_data.duplicate(true)


## Clears the custom data of the stat [param stat_id].
func clear_data(stat_id: StringName) -> void:
	if _stat_data.has(stat_id):
		_stat_data[stat_id]["custom_data"].clear()


## Sets a new minimum value of custom stat [param stat_id] to [param new_min].
func set_stat_min(stat_id: StringName, new_min: float) -> void:
	if not _stat_data.has(stat_id):
		return
	
	_stat_data[stat_id]["min_value"] = new_min


## Sets a new maximum value of custom stat [param stat_id] to [param new_min].
func set_stat_max(stat_id: StringName, new_max: float) -> void:
	if not _stat_data.has(stat_id):
		return
	
	_stat_data[stat_id]["max_value"] = new_max


## Returns true if the custom stat [param stat_id] allows for lesser values or
## the stat doesn't exists.
func allows_lesser(stat_id: StringName) -> bool:
	return _stat_data.get(stat_id, {}).get("allow_lesser", true)


## Returns true if the custom stat [param stat_id] allows for greater values or
## the stat doesn't exists.
func allows_greater(stat_id: StringName) -> bool:
	return _stat_data.get(stat_id, {}).get("allow_greater", true)


## Returns the minumum value of [param stat_id] or 0.0 if it doesn't exist.
func get_min_value(stat_id: StringName) -> float:
	return _stat_data.get(stat_id, {}).get("min_value", 0.0)


## Returns the maximum value of [param stat_id] or 0.0 if it doesn't exist.
func get_max_value(stat_id: StringName) -> float:
	return _stat_data.get(stat_id, {}).get("max_value", 0.0)


## Erases the custom stat [param stat_id] if it exists.[br]
## Erasing a stat WON'T erase it from existing [NFStatBlock]s, but will prevent
## new ones from having the custom stat in them.
func erase_stat(stat_id: StringName) -> void:
	_stat_data.erase(stat_id)
