class_name RecipeItem
extends Resource
## An object representing an item of a recipe


var id: StringName = &""
var amount: int = 1
var custom_data: Dictionary[String, Variant] = {}


func _set(property: StringName, value: Variant) -> bool:
	if custom_data.has(property):
		if typeof(value) == TYPE_NIL:
			custom_data.erase(property)
		else:
			custom_data[property] = value
		return true
	return false


func _get(property: StringName) -> Variant:
	if custom_data.has(property):
		return custom_data[property]
	return null
