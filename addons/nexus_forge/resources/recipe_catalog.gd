@tool
@icon("res://addons/nexus_forge/icons/bluepring_fill.svg")
class_name NFRecipeCatalog
extends Resource


@export_storage var _recipes: Dictionary[String, Dictionary] = {}

#region Crafting Recipes

## Returns an array containing the IDs of the recipes.
func recipes() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_recipes.keys())
	return ids


## Overwrites the inputs for [param recipe_id] with [param inputs].
func set_recipe_inputs(recipe_id: StringName, inputs: Array[NFRecipeItem]) -> void:
	if not _recipes.has(recipe_id):
		return
	
	var recipe_inputs: Array[NFRecipeItem] = []
	
	for input in inputs:
		var new_input: NFRecipeItem = input.duplicate(true)
		recipe_inputs.append(new_input)
	
	_recipes[recipe_id]["input"] = recipe_inputs


## Overwrites the outputs for [param recipe_id] with [param outputs].
func set_recipe_outputs(recipe_id: StringName, outputs: Array[NFRecipeItem]) -> void:
	if not _recipes.has(recipe_id):
		return
	
	var recipe_outputs: Array[NFRecipeItem] = []
	
	for output in outputs:
		var new_output: NFRecipeItem = output.duplicate(true)
		recipe_outputs.append(new_output)
	
	_recipes[recipe_id]["output"] = recipe_outputs


## Creates a recipe with param recipe_id unless it already exists.
func create_recipe(recipe_id: StringName) -> void:
	if _recipes.has(recipe_id):
		return
	
	var inputs: Array[NFRecipeItem] = []
	var outputs: Array[NFRecipeItem] = []
	
	var recipe: Dictionary[String, Variant] = {
		"input": inputs,
		"output": outputs,
		"custom_data": NFDictUtils.create_typed(TYPE_STRING, TYPE_NIL)}

	_recipes[recipe_id] = recipe


## Sets the custom data of [param recipe_id] with key [param data_key]
## to [param data]. If param data is [code]null[/code] then the key is erased.
func set_recipe_data(recipe_id: StringName, data_key: String, data: Variant) -> void:
	if not _recipes.has(recipe_id):
		return
	
	if data == null:
		if _recipes[recipe_id]["custom_data"].has(data_key):
			_recipes[recipe_id]["custom_data"].erase(data_key)
	else:
		_recipes[recipe_id]["custom_data"][data_key] = data


## Sets the custom data of an input ingredient in the [param recipe_id]
## to [param data]. If param data is [code]null[/code] then the key is erased.
func set_recipe_input_item_data(recipe_id: StringName, ingredient_idx: int, data_key: String, data: Variant) -> void:
	if not _recipes.has(recipe_id):
		return
	
	var target: Array[NFRecipeItem] = _recipes[recipe_id]["input"]
	if not NFArrayUtils.is_index_valid(target, ingredient_idx):
		return
	
	if data == null:
		target[ingredient_idx].custom_data.erase(data_key)
	else:
		target[ingredient_idx].custom_data[data_key] = data


## Sets the custom data of an output ingredient in the [param recipe_id]
## to [param data]. If param data is [code]null[/code] then the key is erased.
func set_recipe_output_item_data(recipe_id: StringName, ingredient_idx: int, data_key: String, data: Variant) -> void:
	if not _recipes.has(recipe_id):
		return
	
	var target: Array[NFRecipeItem] = _recipes[recipe_id]["output"]
	if not NFArrayUtils.is_index_valid(target, ingredient_idx):
		return
	
	if data == null:
		target[ingredient_idx].custom_data.erase(data_key)
	else:
		target[ingredient_idx].custom_data[data_key] = data


## Clears the custom data from the input ingredient with index [param ingredient_idx]
## on [param recipe_id].
func clear_recipe_input_item_data(recipe_id: StringName, ingredient_idx: int) -> void:
	if not _recipes.has(recipe_id):
		return
	
	var target: Array[NFRecipeItem] = _recipes[recipe_id]["input"]
	if NFArrayUtils.is_index_valid(target, ingredient_idx):
		target[ingredient_idx].custom_data.clear()


## Clears the custom data from the output ingredient with index [param ingredient_idx]
## on [param recipe_id].
func clear_recipe_output_item_data(recipe_id: StringName, ingredient_idx: int) -> void:
	if not _recipes.has(recipe_id):
		return
	
	var target: Array[NFRecipeItem] = _recipes[recipe_id]["output"]
	if NFArrayUtils.is_index_valid(target, ingredient_idx):
		target[ingredient_idx].custom_data.clear()


## Clears the custom data of [param recipe_id].
func clear_recipe_data(recipe_id: StringName) -> void:
	if _recipes.has(recipe_id):
		_recipes[recipe_id]["custom_data"].clear()


## Returns a [NFRecipeSheet] of the [param recipe_id] or [code]null[/code]
## if the recipe doesn't exist.
func get_recipe(recipe_id: StringName) -> NFRecipeSheet:
	if not _recipes.has(recipe_id):
		return null
	
	var recipe: NFRecipeSheet = NFRecipeSheet.new()
	recipe.id = recipe_id
	recipe.input.assign(get_recipe_inputs(recipe_id))
	recipe.output.assign(get_recipe_outputs(recipe_id))
	recipe.custom_data.assign(get_recipe_custom_data(recipe_id))
	
	return recipe


func get_recipe_custom_data(recipe_id: StringName) -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = {}
	if _recipes.has(recipe_id):
		data.assign(_recipes[recipe_id].get("custom_data").duplicate(true))
	return data


func get_recipe_inputs(recipe_id: StringName) -> Array[NFRecipeItem]:
	var inp: Array[NFRecipeItem] = []
	
	if not _recipes.has(recipe_id):
		return inp
	
	var inputs: Array[NFRecipeItem] = _recipes[recipe_id]["input"]
	
	for input in inputs:
		inp.append(input.duplicate(true))
	
	return inp


func get_recipe_outputs(recipe_id: StringName) -> Array[NFRecipeItem]:
	var out: Array[NFRecipeItem] = []
	if not _recipes.has(recipe_id):
		return out
	
	var outputs: Array[NFRecipeItem] = _recipes[recipe_id]["output"]
	
	for output in outputs:
		out.append(output.duplicate(true))
	
	return out


## Returns [code]true[/code] if param recipe_id is registered.
func has_recipe(recipe_id: StringName) -> bool:
	return _recipes.has(recipe_id)


## Erases the recipe with id [param recipe_id].
func erase_recipe(recipe_id: StringName) -> void:
	_recipes.erase(recipe_id)
