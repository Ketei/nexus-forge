class_name NFRecipeSheet
extends Resource

## The ID of the recipe.
@export var id: StringName = &"":
	set(i):
		if id.is_empty():
			id = i

## The inputs of the recipe
@export var input: Array[NFRecipeItem] = []

## The outputs of the recipe
@export var output: Array[NFRecipeItem] = []

## The custom data of the recipe
@export var custom_data: Dictionary[StringName, Variant] = {}
