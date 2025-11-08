@tool
class_name RecipeCatalog
extends Resource


const RECIPE_DEFAULT_DATA: Dictionary[String, Variant] = {}

@export_storage var _recipes: Dictionary = {}
	#&"recipe_id": {
		#"input": Array([{"item_id": &"item", "amount": 1, "data": {}}], TYPE_DICTIONARY, &"", null),
		#"output": [],
		#"data": {}
	#}

#region Crafting Recipes

func recipes() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_recipes.keys())
	return ids


func set_recipe_inputs(recipe_id: StringName, inputs: Array[RecipeItem]) -> void:
	var recipe_inputs: Array[Dictionary] = []
	
	for input in inputs:
		var input_entry: Dictionary[String, Variant] = {
			"item_id": input.id,
			"amount": input.amount,
			"data": input.data.duplicate(true)}
		
		recipe_inputs.append(input_entry)
	
	_recipes[recipe_id]["input"] = recipe_inputs


func set_recipe_outputs(recipe_id: StringName, outputs: Array[RecipeItem]) -> void:
	var recipe_outputs: Array[Dictionary] = []
	
	for output in outputs:
		var output_entry: Dictionary[String, Variant] = {
			"item_id": output.id,
			"amount": output.amount,
			"data": output.data.duplicate(true)}
		
		recipe_outputs.append(output_entry)
	
	_recipes[recipe_id]["output"] = recipe_outputs


func create_recipe(recipe_id: StringName) -> void:
	if recipe_id.is_empty():
		return
	
	var recipe_data: Dictionary[String, Variant] = {}
	recipe_data.assign(RECIPE_DEFAULT_DATA)
	
	var recipe: Dictionary = {
		"input": Array([], TYPE_DICTIONARY, &"", null),
		"output": Array([], TYPE_DICTIONARY, &"", null),
		"data": recipe_data}

	_recipes[recipe_id] = recipe


func set_recipe_data(recipe_id: StringName, data_key: String, data: Variant) -> void:
	if not _recipes.has(recipe_id):
		return
	
	if data == null:
		if _recipes[recipe_id]["data"].has(data_key):
			_recipes[recipe_id]["data"].erase(data_key)
	else:
		_recipes[recipe_id]["data"][data_key] = data


func clear_recipe_data(recipe_id: StringName) -> void:
	if _recipes.has(recipe_id):
		_recipes[recipe_id]["data"].clear()


func get_recipe(recipe_id: StringName) -> RecipeSheet:
	if not _recipes.has(recipe_id):
		return null
	var recipe: RecipeSheet = RecipeSheet.new()
	recipe.id = recipe_id
	
	#{"item_id": &"item", "amount": 1, "data": {}}
	for input:Dictionary in _recipes[recipe_id]["input"]:
		var input_item: RecipeItem = RecipeItem.new()
		input_item.id = input["item_id"]
		input_item.amount = input["amount"]
		input_item.data = input["data"].duplicate(true)
		recipe.input.append(input_item)
	
	for output:Dictionary in _recipes[recipe_id]["output"]:
		var output_item: RecipeItem = RecipeItem.new()
		output_item.id = output["item_id"]
		output_item.amount = output["amount"]
		output_item.data = output["data"].duplicate(true)
		recipe.output.append(output_item)
	
	recipe.data = _recipes[recipe_id]["data"].duplicate(true)
	return recipe


func has_recipe(recipe_id: StringName) -> bool:
	return _recipes.has(recipe_id)


func erase_recipe(recipe_id: StringName) -> void:
	_recipes.erase(recipe_id)
