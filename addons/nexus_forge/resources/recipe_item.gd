class_name RecipeItem
extends RefCounted

const RECIPE_ITEM_DEFAULT_DATA: Dictionary[String, Variant] = {}
#{"item_id": &"item", "amount": 1, "data": {}}
var id: StringName
var amount: int
var data: Dictionary[String, Variant]


func _init() -> void:
	data.assign(RECIPE_ITEM_DEFAULT_DATA)
