class_name StatCatalog
extends Resource


signal stat_created(stat_id: StringName, default_value: int)
signal stat_erased(stat_id: StringName)


@export var _custom_stats: Dictionary[StringName, int] = {}


func custom_stats() -> Array[StringName]:
	var all_stats: Array[StringName] = []
	all_stats.assign(_custom_stats.keys())
	return all_stats


func custom_stat_exists(stat_id: StringName) -> bool:
	return _custom_stats.has(stat_id)


func create_custom(stat_id: StringName, default_value: int = 0) -> void:
	if _custom_stats.has(stat_id):
		return
	_custom_stats[stat_id] = default_value
	stat_created.emit(stat_id, default_value)


func set_custom_default_value(stat_id: StringName, new_default: int) -> void:
	if _custom_stats.has(stat_id):
		_custom_stats[stat_id] = new_default


func get_custom_default_value(stat_id: StringName) -> int:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id]
	return -1


func erase_custom(stat_id: StringName) -> void:
	if _custom_stats.erase(stat_id):
		stat_erased.emit(stat_id)
