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
