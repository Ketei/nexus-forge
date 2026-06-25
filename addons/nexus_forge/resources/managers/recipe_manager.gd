class_name NFRecipeManager
extends RefCounted
## An object that holds [RecipeSheet] resources.
##
## This object provides several utilities, such as a custom getter
## for accessing registered items directly by their ID, eg. [code]Recipes.wood[/code]
## and when a recipe is modified through this, the signal [Resource.changed] is
## called on the specific resource.

## Emmited when a recipe is created.
signal recipe_created(recipe_id: StringName)
## Emmited when a recipe is erased.
signal recipe_erased(recipe_id: StringName)


var _recipe_sheets: Dictionary[StringName, RecipeSheet] = {}


func _get(property: StringName) -> Variant:
	if _recipe_sheets.has(property):
		return _recipe_sheets[property]
	return null


## Loads a [param catalog] of recipes into this object. If [param clear_recipes]
## is [code]true[/code] then the previous recipes are cleared.
func load_catalog(catalog: RecipeCatalog, clear_recipes: bool = true) -> void:
	if clear_recipes:
		_recipe_sheets.clear()
	
	for id in catalog.recipes():
		_recipe_sheets[id] = catalog.get_recipe(id)


## Returns an array containing the IDs of the recipes.
func recipes() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_recipe_sheets.keys())
	return ids


## Overwrites the inputs for [param recipe_id] with [param inputs].
func set_recipe_inputs(recipe_id: StringName, inputs: Array[RecipeItem]) -> void:
	if not _recipe_sheets.has(recipe_id):
		return
	
	_recipe_sheets[recipe_id].input.assign(inputs)
	_recipe_sheets[recipe_id].emit_changed()


## Overwrites the outputs for [param recipe_id] with [param outputs].
func set_recipe_outputs(recipe_id: StringName, outputs: Array[RecipeItem]) -> void:
	if not _recipe_sheets.has(recipe_id):
		return
	
	_recipe_sheets[recipe_id].output.assign(outputs)
	_recipe_sheets[recipe_id].emit_changed()


## Creates a recipe with param recipe_id unless it already exists.
func register_recipe(recipe_sheet: RecipeSheet) -> void:
	if recipe_sheet.id.is_empty() or _recipe_sheets.has(recipe_sheet.id):
		return
	
	recipe_sheet[recipe_sheet.id] = recipe_sheet
	recipe_created.emit(recipe_sheet.id)


## Sets the custom data of [param recipe_id] with key [param data_key]
## to [param data]. If param data is [code]null[/code] then the key is erased.
func set_recipe_data(recipe_id: StringName, data_key: StringName, data: Variant) -> void:
	if not _recipe_sheets.has(recipe_id):
		return
	
	if typeof(data) == TYPE_NIL:
		_recipe_sheets[recipe_id].custom_data.erase(data_key)
	else:
		_recipe_sheets[recipe_id].custom_data[data_key] = data


## Sets the custom data of an input ingredient in the [param recipe_id]
## to [param data]. If param data is [code]null[/code] then the key is erased.
func set_recipe_input_item_data(recipe_id: StringName, ingredient_idx: int, data_key: String, data: Variant) -> void:
	if not _recipe_sheets.has(recipe_id):
		return
	
	if ingredient_idx < 0 or not _recipe_sheets[recipe_id].input.size() <= ingredient_idx:
		return
	
	if typeof(data) == TYPE_NIL:
		_recipe_sheets[recipe_id].input[ingredient_idx].custom_data.erase(data_key)
	else:
		_recipe_sheets[recipe_id].input[ingredient_idx].custom_data[data_key] = data


## Sets the custom data of an output ingredient in the [param recipe_id]
## to [param data]. If param data is [code]null[/code] then the key is erased.
func set_recipe_output_item_data(recipe_id: StringName, ingredient_idx: int, data_key: String, data: Variant) -> void:
	if not _recipe_sheets.has(recipe_id):
		return
	
	if ingredient_idx < 0 or not _recipe_sheets[recipe_id].output.size() <= ingredient_idx:
		return
	
	if typeof(data) == TYPE_NIL:
		_recipe_sheets[recipe_id].output[ingredient_idx].custom_data.erase(data_key)
	else:
		_recipe_sheets[recipe_id].output[ingredient_idx].custom_data[data_key] = data


## Clears the custom data from the input ingredient with index [param ingredient_idx]
## on [param recipe_id].
func clear_recipe_input_item_data(recipe_id: StringName, ingredient_idx: int) -> void:
	if not _recipe_sheets.has(recipe_id):
		return
	
	if ingredient_idx < 0 or not _recipe_sheets[recipe_id].input.size() <= ingredient_idx:
		return
	
	_recipe_sheets[recipe_id].input[ingredient_idx].custom_data.clear()


## Clears the custom data from the output ingredient with index [param ingredient_idx]
## on [param recipe_id].
func clear_recipe_output_item_data(recipe_id: StringName, ingredient_idx: int) -> void:
	if not _recipe_sheets.has(recipe_id):
		return
	
	if ingredient_idx < 0 or not _recipe_sheets[recipe_id].output.size() <= ingredient_idx:
		return
	
	_recipe_sheets[recipe_id].output[ingredient_idx].custom_data.clear()


## Clears the custom data of [param recipe_id].
func clear_recipe_data(recipe_id: StringName) -> void:
	if _recipe_sheets.has(recipe_id):
		_recipe_sheets[recipe_id].custom_data.clear()


## Returns a [RecipeSheet] of the [param recipe_id] or [code]null[/code]
## if the recipe doesn't exist.
func get_recipe(recipe_id: StringName) -> RecipeSheet:
	if _recipe_sheets.has(recipe_id):
		return _recipe_sheets[recipe_id]
	return null


## Returns [code]true[/code] if param recipe_id is registered.
func has_recipe(recipe_id: StringName) -> bool:
	return _recipe_sheets.has(recipe_id)


## Erases the recipe with id [param recipe_id].
func erase_recipe(recipe_id: StringName) -> void:
	_recipe_sheets.erase(recipe_id)
