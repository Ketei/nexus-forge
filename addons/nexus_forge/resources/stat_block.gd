class_name StatBlock
extends Resource


@export var health: int = 100


@export var _custom_stats: Dictionary[StringName, int] = {}


func _init() -> void:
	for custom_stat in NexusForge.Stats.custom_stats():
		if _custom_stats.has(custom_stat):
			continue
		_custom_stats[custom_stat] = NexusForge.Stats.get_custom_default_value(custom_stat)
	
	NexusForge.Stats.stat_created.connect(_on_custom_stat_created)
	NexusForge.Stats.stat_erased.connect(_on_custom_stat_erased)


func _on_custom_stat_created(stat_id: StringName, default_value: int) -> void:
	if _custom_stats.has(stat_id):
		return
	_custom_stats[stat_id] = default_value


func _on_custom_stat_erased(stat_id: StringName) -> void:
	if _custom_stats.has(stat_id):
		_custom_stats.erase(stat_id)


## Returns all the stats in the statblock. This does NOT include custom stats.
func stats() -> Array[StringName]:
	var all_stats: Array[StringName]  = []
	var data: Array[Dictionary] = get_script().get_script_property_list()
	
	for item in data:
		if item["type"] != TYPE_INT or item["usage"] != PROPERTY_USAGE_SCRIPT_VARIABLE + PROPERTY_USAGE_EDITOR + PROPERTY_USAGE_STORAGE:
			continue
		if item["name"] == "_custom_stats":
			continue
		all_stats.append(StringName(item["name"]))
	
	return all_stats


## Returns all stats used in the statblock
func custom_stats() -> Array[StringName]:
	var all_stats: Array[StringName] = []
	all_stats.assign(_custom_stats.keys())
	return all_stats


## Adds a custom [param stat] to the stat block.
func create_custom(stat_id: StringName) -> void:
	if _custom_stats.has(stat_id):
		return
	_custom_stats[stat_id] = 0


## Gets the value of the custom [param stat_id]. Returns [code]0[/code]
## if the stat doesn't exist.
func get_custom(stat_id: StringName) -> int:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id]
	return 0


func has_custom(stat_id: StringName) -> bool:
	return _custom_stats.has(stat_id)
