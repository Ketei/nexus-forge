class_name RecipeItem
extends RefCounted
## An object representing an item of a recipe

## The default data a recipe item will have.
const RECIPE_ITEM_DEFAULT_DATA: Dictionary[String, Variant] = {}

var id: StringName = &""
var amount: int = 1
var data: Dictionary[String, Variant] = {}


func _init() -> void:
	data.merge(RECIPE_ITEM_DEFAULT_DATA.duplicate(true))
