extends Resource
class_name NFSpeciesStatCatalog


@export var entries: Dictionary[StringName, float] = {}
var _mode: int = TYPE_FLOAT:
	set(m):
		if m == TYPE_INT:
			_mode = m
		else:
			_mode = TYPE_FLOAT


func _init(mode: int = TYPE_FLOAT) -> void:
	_mode = mode


func _get(property: StringName) -> Variant:
	if not entries.has(property):
		return 0 if _mode == TYPE_INT else 0.0
	if _mode == TYPE_INT:
		return int(entries[property])
	else:
		return entries[property]


func _set(property: StringName, value: Variant) -> bool:
	var type: int = typeof(value)
	if type == TYPE_INT or type == TYPE_FLOAT:
		entries[property] = value
		return true
	return false


func set_entry(property: StringName, value: float) -> void:
	entries[property] = value


func get_entry(property: StringName) -> float:
	if entries.has(property):
		return entries[property]
	return 0.0


func clear() -> void:
	entries.clear()


func has(property: StringName) -> bool:
	return entries.has(property)


func is_empty() -> bool:
	return entries.is_empty()


func erase(property: StringName) -> bool:
	return entries.erase(property)
