class_name NFRecipeSheet
extends Resource

## The ID of the recipe.
var id: StringName = &"":
	set(i):
		if id.is_empty():
			id = i

## The inputs of the recipe
var input: Array[NFRecipeItem] = []

## The outputs of the recipe
var output: Array[NFRecipeItem] = []

## The custom data of the recipe
var custom_data: Dictionary[StringName, Variant] = {}
