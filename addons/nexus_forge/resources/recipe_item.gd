class_name NFRecipeItem
extends Resource
## An object representing an item of a recipe


## The item ID this recipe entry represents
@export var id: StringName = &""
## The amount of items required.
@export var amount: int = 1:
	set(a):
		amount = maxi(0, a)
## Custom data of this recipe item entry.
@export var custom_data: Dictionary[String, Variant] = {}
