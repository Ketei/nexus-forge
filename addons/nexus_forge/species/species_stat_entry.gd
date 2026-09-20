extends Resource
class_name NFSpeciesStatCatalog
## A resource used for storing stat/skil/trait data on [NFSpeciesSheet]s.


@export var entries: Dictionary[StringName, float] = {}


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
