class_name RecipeSheet
extends Resource

## The ID of the recipe.
var id: StringName = &"":
	set(i):
		if id.is_empty():
			id = i

## The inputs of the recipe
var input: Array[RecipeItem] = []

## The outputs of the recipe
var output: Array[RecipeItem] = []

## The custom data of the recipe
var custom_data: Dictionary[StringName, Variant] = {}


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
