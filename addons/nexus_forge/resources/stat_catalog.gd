class_name StatCatalog
extends Resource


signal stat_created(stat_id: StringName)
signal stat_erased(stat_id: StringName)

enum StatType {
	INTEGER,
	FLOAT
}

const _MAX_INDEX: int = 1
const _MIN_INDEX: int = 0

# Custom stats where the value is an integer array holding 2 values [min, max]
@export_storage var _custom_stats: Dictionary[StringName, Array] = {}


func custom_stats() -> Array[StringName]:
	var all_stats: Array[StringName] = []
	all_stats.assign(_custom_stats.keys())
	return all_stats


func custom_stat_exists(stat_id: StringName) -> bool:
	return _custom_stats.has(stat_id)


func create_custom(stat_id: StringName, type: StatType, min_value: float = 0.0, max_value: float = 1.0) -> void:
	if _custom_stats.has(stat_id):
		return
	
	if max_value < min_value:
		max_value = min_value
	
	var stats: Array = []
	stats.resize(2)
	stats[_MIN_INDEX] = min_value
	stats[_MAX_INDEX] = max_value
	
	
	if type == TYPE_INT:
		_custom_stats[stat_id] = Array(stats, TYPE_INT, &"", null)
	else:
		_custom_stats[stat_id] = Array(stats, TYPE_FLOAT, &"", null)
	
	stat_created.emit(stat_id)


func custom_stat_type(stat_id: StringName) -> int:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id].get_typed_builtin()
	return TYPE_NIL


func set_custom_min_value(stat_id: StringName, new_min: float) -> void:
	if not _custom_stats.has(stat_id):
		return
	_custom_stats[stat_id][_MIN_INDEX] = new_min
	
	if _custom_stats[stat_id][_MAX_INDEX] < new_min:
		_custom_stats[stat_id][_MAX_INDEX] = new_min


func set_custom_max_value(stat_id: StringName, new_max: float) -> void:
	if not _custom_stats.has(stat_id):
		return
	
	if new_max < _custom_stats[stat_id][_MIN_INDEX]:
		new_max = _custom_stats[stat_id][_MIN_INDEX]
	_custom_stats[stat_id][_MAX_INDEX] = new_max



func get_custom_min_value(stat_id: StringName) -> float:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id][_MIN_INDEX]
	return 0.0


func get_custom_max_value(stat_id: StringName) -> float:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id][_MAX_INDEX]
	return 0


func erase_custom(stat_id: StringName) -> void:
	if _custom_stats.erase(stat_id):
		stat_erased.emit(stat_id)
