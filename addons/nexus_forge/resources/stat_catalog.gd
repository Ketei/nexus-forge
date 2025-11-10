@tool
@icon("res://addons/nexus_forge/icons/stat_catalog.svg")
class_name StatCatalog
extends Resource
## A resource containing custom stats and its data.
##
## Custom stats will be included in all [StatBlock]'s custom stats instantiated
## with [method StatBlock.new_stat_block].

## Emmited when a stat is created.
signal stat_created(stat_id: StringName)
## Emmited when a stat is erased.
signal stat_erased(stat_id: StringName)
## Emits when the value of a stat that doesn't allow lesser values is changed.
signal stat_min_range_changed(stat_id: StringName, new_min: float)
## Emits when the value of a stat that doesn't allow greater values is changed.
signal stat_max_range_changed(stat_id: StringName, new_max: float)

enum StatType {
	INTEGER,
	FLOAT
}

const _MIN_INDEX: int = 0
const _MAX_INDEX: int = 1
const _USE_MIN_INDEX: int = 2
const _USE_MAX_INDEX: int = 3

# Custom stats where the value is an integer array holding 2 values [min, max]
var _custom_stats: Dictionary[StringName, Array] = {}


## Returns an array containing all custom stats.
func custom_stats() -> Array[StringName]:
	var all_stats: Array[StringName] = []
	all_stats.assign(_custom_stats.keys())
	return all_stats


## Returns ture if a stat [param stat_id] is registered.
func custom_stat_exists(stat_id: StringName) -> bool:
	return _custom_stats.has(stat_id)


## Registers a custom stat with [param stat_id] of type [param type] unless
## it already exists.[br]
## Registering a new stat will also add them to all existing [StatBlock]s and
## include them on newly instantiated ones done through [method StatBlock.new_stat_block]
func create_custom(stat_id: StringName, type: StatType, use_min_range: bool = false, use_max_range: bool = false, min_value: float = 0.0, max_value: float = 1.0) -> void:
	if _custom_stats.has(stat_id):
		return
	
	if max_value < min_value:
		max_value = min_value
	
	var stats: Array = []
	stats.resize(4)
	stats[_MIN_INDEX] = min_value
	stats[_MAX_INDEX] = max_value
	stats[_USE_MIN_INDEX] = int(use_min_range)
	stats[_USE_MAX_INDEX] = int(use_max_range)
	
	if type == TYPE_INT:
		_custom_stats[stat_id] = Array(stats, TYPE_INT, &"", null)
	else:
		_custom_stats[stat_id] = Array(stats, TYPE_FLOAT, &"", null)
	
	stat_created.emit(stat_id)


## Returns the built-in type of a stat. Either [code]TYPE_INT[/code] or
## [code]TYPE_FLOAT[/code].[br]
## Returns [code]TYPE_NIL[/code] if the stat doesn't exist.
func custom_stat_type(stat_id: StringName) -> int:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id].get_typed_builtin()
	return TYPE_NIL


## Sets a new minimum value of custom stat [param stat_id] to [param new_min].
func set_custom_min_value(stat_id: StringName, new_min: float) -> void:
	if not _custom_stats.has(stat_id) or _custom_stats[stat_id][_MIN_INDEX] == new_min:
		return
	_custom_stats[stat_id][_MIN_INDEX] = new_min
	
	if _custom_stats[stat_id][_MAX_INDEX] < new_min:
		_custom_stats[stat_id][_MAX_INDEX] = new_min
	
	if bool(_custom_stats[stat_id][_USE_MIN_INDEX]):
		stat_min_range_changed.emit(stat_id, new_min)


## Sets a new maximum value of custom stat [param stat_id] to [param new_min].
func set_custom_max_value(stat_id: StringName, new_max: float) -> void:
	if not _custom_stats.has(stat_id) or _custom_stats[stat_id][_MAX_INDEX] == new_max:
		return
	
	if new_max < _custom_stats[stat_id][_MIN_INDEX]:
		new_max = _custom_stats[stat_id][_MIN_INDEX]
	_custom_stats[stat_id][_MAX_INDEX] = new_max
	if bool(_custom_stats[stat_id][_USE_MAX_INDEX]):
		stat_max_range_changed.emit(stat_id, new_max)


## Returns true if the custom stat [param stat_id] allows for lesser values or
## the stat doesn't exists.
func custom_allows_lesser(stat_id: StringName) -> bool:
	if _custom_stats.has(stat_id):
		return not bool(_custom_stats[stat_id][_USE_MIN_INDEX])
	return true


## Returns true if the custom stat [param stat_id] allows for greater values or
## the stat doesn't exists.
func custom_allows_greater(stat_id: StringName) -> bool:
	if _custom_stats.has(stat_id):
		return not bool(_custom_stats[stat_id][_USE_MAX_INDEX])
	return true


## Returns the minumum value of [param stat_id] or 0.0 if it doesn't exist.
func get_custom_min_value(stat_id: StringName) -> float:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id][_MIN_INDEX]
	return 0.0


## Returns the maximum value of [param stat_id] or 0.0 if it doesn't exist.
func get_custom_max_value(stat_id: StringName) -> float:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id][_MAX_INDEX]
	return 0


## Erases the custom stat [param stat_id] if it exists.[br]
## Erasing a stat WON'T erase it from existing [StatBlock]s, but will prevent
## new ones from having the custom stat in them.
func erase_custom(stat_id: StringName) -> void:
	if _custom_stats.erase(stat_id):
		stat_erased.emit(stat_id)
