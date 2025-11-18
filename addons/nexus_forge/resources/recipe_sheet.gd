class_name RecipeSheet
extends RefCounted

## The ID of the recipe.
var id: StringName = &""

## The inputs of the recipe
var input: Array[RecipeItem] = []

## The outputs of the recipe
var output: Array[RecipeItem] = []

## The custom data of the recipe
var data: Dictionary[String, Variant] = {}
