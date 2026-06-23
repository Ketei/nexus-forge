@tool
@icon("res://addons/nexus_forge/icons/stat_catalog.svg")
class_name StatCatalog
extends Resource
## A resource containing custom stats and its data.
##
## Custom stats will be included in all [StatBlock]'s custom stats instantiated
## with [method StatBlock.new_stat_block].


# Custom stats where the value is an integer array holding 2 values [min, max]
# &"health": {"name": "Health", "description": "Life!", "allow_*": true, "*_value": 0, "data": {}}
@export_storage var _stat_data: Dictionary[StringName, Dictionary] = {}


## Returns an array containing all registered stats.
func stats() -> Array[StringName]:
	return ArrayUtils.create_typed(TYPE_STRING_NAME, _stat_data.keys())


## Returns ture if a stat [param stat_id] is registered.
func has_stat(stat_id: StringName) -> bool:
	return _stat_data.has(stat_id)


## Returns the built-in type of a stat.
func stat_type(stat_id: StringName) -> int:
	var type: int = DictUtils.get_nested_value(
			_stat_data,
			[stat_id, "type"],
			TYPE_FLOAT,
			true)
	
	if type != TYPE_INT and type != TYPE_FLOAT:
		return TYPE_FLOAT
	else:
		return type


func set_stat_name(stat_id: StringName, new_name: String) -> void:
	if not _stat_data.has(stat_id):
		return
	
	_stat_data[stat_id]["name"] = new_name


func set_stat_description(stat_id: StringName, description: String) -> void:
	if not _stat_data.has(stat_id):
		return
	
	_stat_data[stat_id]["description"] = description


func get_stat_name(stat_id: StringName) -> String:
	return DictUtils.get_nested_value(
			_stat_data,
			[stat_id, "name"],
			"",
			true)


func get_stat_description(stat_id: StringName) -> String:
	return DictUtils.get_nested_value(
			_stat_data,
			[stat_id, "description"],
			"",
			true)


func set_stat_data(stat_id: StringName, data_key: StringName, data) -> void:
	if not _stat_data.has(stat_id):
		return
	
	if data == null:
		_stat_data[stat_id]["custom_data"].erase(data_key)
	else:
		_stat_data[stat_id]["custom_data"][data_key] = data


func get_stat_data(stat_id: StringName, data_key: String) -> Variant:
	if _stat_data.has(stat_id) and _stat_data[stat_id]["custom_data"].has(data_key):
		return _stat_data[stat_id]["custom_data"][data_key]
	return null


func stat_data(stat_id: StringName) -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = {}
	data.assign(DictUtils.get_nested_value(
			_stat_data,
			[stat_id, "custom_data"],
			{},
			true))
	return data


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
	return DictUtils.get_nested_value(
			_stat_data,
			[stat_id, "allow_lesser"],
			true,
			true)


## Returns true if the custom stat [param stat_id] allows for greater values or
## the stat doesn't exists.
func allows_greater(stat_id: StringName) -> bool:
	return DictUtils.get_nested_value(
			_stat_data,
			[stat_id, "allow_greater"],
			true,
			true)


## Returns the minumum value of [param stat_id] or 0.0 if it doesn't exist.
func get_min_value(stat_id: StringName) -> float:
	var data = DictUtils.get_nested_value(
			_stat_data,
			[stat_id, "min_value"],
			0.0)
	var type: int = typeof(data)
	
	if type == TYPE_INT or type == TYPE_FLOAT:
		return type
	else:
		return 0.0


## Returns the maximum value of [param stat_id] or 0.0 if it doesn't exist.
func get_max_value(stat_id: StringName) -> float:
	var data = DictUtils.get_nested_value(
			_stat_data,
			[stat_id, "max_value"],
			0.0)
	var type: int = typeof(data)
	
	if type == TYPE_INT or type == TYPE_FLOAT:
		return type
	else:
		return 0.0


## Erases the custom stat [param stat_id] if it exists.[br]
## Erasing a stat WON'T erase it from existing [StatBlock]s, but will prevent
## new ones from having the custom stat in them.
func erase_stat(stat_id: StringName) -> void:
	_stat_data.erase(stat_id)
