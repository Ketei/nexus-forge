extends Resource
class_name NFSpeciesStatCatalog
## A resource used for storing stat/skil/trait data on [NFSpeciesSheet]s.


## A dictionary containing a species defined stats.
@export var entries: Dictionary[StringName, float] = {}


## Sets a new stat as [param property] and assigns it a [param value].
func set_entry(property: StringName, value: float) -> void:
	entries[property] = value


## Returns a species [param property]. Returns [code]0.0[/code] if
## the [param property] isn't found.
## [br][br]
## [b]Note:[/b] A returned value of 0.0 does NOT mean that the
## [param property] does not exist.
func get_entry(property: StringName) -> float:
	return entries.get(property, 0.0)


## Clears all the property entries.
func clear() -> void:
	entries.clear()


## Returns whether the species has a defined [param property] or not.
func has(property: StringName) -> bool:
	return entries.has(property)


## Returns [code]true[/code] if no properties have been defined.
func is_empty() -> bool:
	return entries.is_empty()


## Erases a [param property]. Returns [code]true[/code] if the
## property existed and was erased.
func erase(property: StringName) -> bool:
	return entries.erase(property)
