@tool
@icon("res://addons/nexus_forge/icons/bluepring_fill.svg")
class_name RecipeCatalog
extends Resource


@export_storage var _recipes: Dictionary = {}

#region Crafting Recipes

## Returns an array containing the IDs of the recipes.
func recipes() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_recipes.keys())
	return ids


## Overwrites the inputs for [param recipe_id] with [param inputs].
func set_recipe_inputs(recipe_id: StringName, inputs: Array[RecipeItem]) -> void:
	if not _recipes.has(recipe_id):
		return
	
	var recipe_inputs: Array[Dictionary] = []
	
	for input in inputs:
		var input_entry: Dictionary[String, Variant] = {
			"item_id": input.id,
			"amount": input.amount,
			"custom_data": input.custom_data.duplicate(true)}
		
		recipe_inputs.append(input_entry)
	
	_recipes[recipe_id]["input"] = recipe_inputs


## Overwrites the outputs for [param recipe_id] with [param outputs].
func set_recipe_outputs(recipe_id: StringName, outputs: Array[RecipeItem]) -> void:
	if not _recipes.has(recipe_id):
		return
	
	var recipe_outputs: Array[Dictionary] = []
	
	for output in outputs:
		var output_entry: Dictionary[String, Variant] = {
			"item_id": output.id,
			"amount": output.amount,
			"custom_data": output.custom_data.duplicate(true)}
		
		recipe_outputs.append(output_entry)
	
	_recipes[recipe_id]["output"] = recipe_outputs


## Creates a recipe with param recipe_id unless it already exists.
func create_recipe(recipe_id: StringName) -> void:
	if _recipes.has(recipe_id):
		return
	
	var inputs: Array[Dictionary] = []
	var outputs: Array[Dictionary] = []
	
	var recipe: Dictionary = {
		"input": inputs,
		"output": outputs,
		"custom_data": DictUtils.create_typed(TYPE_STRING, TYPE_NIL)}

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
	if ingredient_idx < 0 or not _recipes.has(recipe_id) or not ingredient_idx < _recipes[recipe_id]["input"].size():
		return
	
	if data == null:
		_recipes[recipe_id]["input"][ingredient_idx]["custom_data"].erase(data_key)
	else:
		_recipes[recipe_id]["input"][ingredient_idx]["custom_data"][data_key] = data


## Sets the custom data of an output ingredient in the [param recipe_id]
## to [param data]. If param data is [code]null[/code] then the key is erased.
func set_recipe_output_item_data(recipe_id: StringName, ingredient_idx: int, data_key: String, data: Variant) -> void:
	if ingredient_idx < 0 or not _recipes.has(recipe_id) or not ingredient_idx < _recipes[recipe_id]["output"].size():
		return
	
	if data == null:
		_recipes[recipe_id]["output"][ingredient_idx]["custom_data"].erase(data_key)
	else:
		_recipes[recipe_id]["output"][ingredient_idx]["custom_data"][data_key] = data


## Clears the custom data from the input ingredient with index [param ingredient_idx]
## on [param recipe_id].
func clear_recipe_input_item_data(recipe_id: StringName, ingredient_idx: int) -> void:
	if ingredient_idx < 0 or not _recipes.has(recipe_id) or not ingredient_idx < _recipes[recipe_id]["input"].size():
		return
	_recipes[recipe_id]["input"][ingredient_idx]["custom_data"].clear()


## Clears the custom data from the output ingredient with index [param ingredient_idx]
## on [param recipe_id].
func clear_recipe_output_item_data(recipe_id: StringName, ingredient_idx: int) -> void:
	if ingredient_idx < 0 or not _recipes.has(recipe_id) or not ingredient_idx < _recipes[recipe_id]["input"].size():
		return
	_recipes[recipe_id]["output"][ingredient_idx]["custom_data"].clear()


## Clears the custom data of [param recipe_id].
func clear_recipe_data(recipe_id: StringName) -> void:
	if _recipes.has(recipe_id):
		_recipes[recipe_id]["custom_data"].clear()


## Returns a [RecipeSheet] of the [param recipe_id] or [code]null[/code]
## if the recipe doesn't exist.
func get_recipe(recipe_id: StringName) -> RecipeSheet:
	if not _recipes.has(recipe_id):
		return null
	
	var recipe: RecipeSheet = RecipeSheet.new()
	recipe.id = recipe_id
	recipe.input.assign(get_recipe_inputs(recipe_id))
	recipe.output.assign(get_recipe_outputs(recipe_id))
	
	recipe.custom_data.assign(get_recipe_custom_data(recipe_id))
	return recipe


func get_recipe_custom_data(recipe_id: StringName) -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = {}
	data.assign(DictUtils.get_nested_value(
			_recipes,
			[recipe_id, "custom_data"],
			{},
			true))
	return data


func get_recipe_inputs(recipe_id: StringName) -> Array[RecipeItem]:
	var inp: Array[RecipeItem] = []
	if not _recipes.has(recipe_id):
		return inp
	
	var inputs: Array = DictUtils.get_nested_value(
			_recipes,
			[recipe_id, "input"],
			[],
			true)
	
	for input in inputs:
		if typeof(input) != TYPE_DICTIONARY or not input.has("item_id"):
			continue
		var amount_data = DictUtils.get_nested_value(input, ["amount"], 0)
		var amount_type: int = typeof(amount_data)
		var input_item: RecipeItem = RecipeItem.new()
		
		input_item.id = input["item_id"]
		if amount_type != TYPE_INT and amount_type != TYPE_FLOAT:
			input_item.amount = 1
		else:
			input_item.amount = amount_data
		input_item.amount = input["amount"]
		input_item.custom_data.assign(DictUtils.get_nested_value(
				input,
				["custom_data"],
				{},
				true))
		inp.append(input_item)
	
	return inp


func get_recipe_outputs(recipe_id: StringName) -> Array[RecipeItem]:
	var inp: Array[RecipeItem] = []
	if not _recipes.has(recipe_id):
		return inp
	
	var outputs: Array = DictUtils.get_nested_value(
			_recipes,
			[recipe_id, "output"],
			[],
			true)
	
	for input in outputs:
		if typeof(input) != TYPE_DICTIONARY or not input.has("item_id"):
			continue
		var amount_data = DictUtils.get_nested_value(input, ["amount"], 0)
		var amount_type: int = typeof(amount_data)
		var input_item: RecipeItem = RecipeItem.new()
		
		input_item.id = input["item_id"]
		if amount_type != TYPE_INT and amount_type != TYPE_FLOAT:
			input_item.amount = 1
		else:
			input_item.amount = amount_data
		input_item.amount = input["amount"]
		input_item.custom_data.assign(DictUtils.get_nested_value(
				input,
				["custom_data"],
				{},
				true))
		inp.append(input_item)
	
	return inp


## Returns [code]true[/code] if param recipe_id is registered.
func has_recipe(recipe_id: StringName) -> bool:
	return _recipes.has(recipe_id)


## Erases the recipe with id [param recipe_id].
func erase_recipe(recipe_id: StringName) -> void:
	_recipes.erase(recipe_id)
