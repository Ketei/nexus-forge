@tool
class_name NFItemsRes
extends Resource


enum ItemFlags {
	SELLABLE,
	GIFTABLE
}


const SETTINGS_PATH: String = "nexus_forge/items_resource"

@export var item_types: Dictionary = {
	"weapon": {"name": "armament", "subtypes": {
		"mace": {"name": "mace"}
		}
	}
}
@export var item_materials: Dictionary = {
	"wood": {"name": "Wood"},
	"stone": {"name": "Stone"},
	"iron": {"name": "Iron"},
	"diamond": {"name": "Diamond"}
	}
@export var _currencies: Dictionary = {
	#"gold": {"name": "GC", "value": 1}
}


@export var _items: Dictionary = {}
@export var _recipes: Dictionary = {}

var _currency_sorted: Array[String] = []


## Call to load and sort currencie based on value.
func load_currencies() -> void:
	_currency_sorted.assign(_currencies.keys())
	_currency_sorted.sort_custom(_sort_currencies)


func get_currencies() -> Array:
	return _currencies.keys()


func get_currency_name(currency_id: String) -> String:
	return _currencies[currency_id]["name"]


func get_currency_value(currency_id: String) -> int:
	return _currencies[currency_id]["value"]


func clear_currencies() -> void:
	_currencies.clear()


func create_currency(id: String, name: String, value: int) -> void:
	_currencies[id] = {"name": name, "value": maxi(1, value)}


func _sort_currencies(currency_a: String, currency_b: String) -> bool:
	return _currencies[currency_a]["value"] < _currencies[currency_b]["value"]


func create_item(item_id: String) -> void:
	_items[item_id] = {"path": "", "resource": null}


func get_item_types() -> Array:
	return item_types.keys()


func get_item_subtypes(item_type: String) -> Array:
	return item_types[item_type]["subtypes"].keys()


func get_item_type_name(type_id: String) -> String:
	return item_types[type_id]["name"]


func get_subtype_name(type_id: String, subtype_id: String) -> String:
	return item_types[type_id]["subtypes"][subtype_id]["name"]


func get_materials() -> Array:
	return item_materials.keys()


func get_material_name(material_id: String) -> String:
	return item_materials[material_id]["name"]


func get_items() -> Array:
	return _items.keys()


func create_crafting_station(station_id: String, station_name: String = "") -> void:
	_recipes[station_id] = {"name": "", "recipes": {}}


func erase_station(station_id: String) -> void:
	_recipes.erase(station_id)


func erase_recipe(station_id: String, recipe_id: String) -> void:
	if _recipes.has(station_id):
		_recipes[station_id]["recipes"].erase(recipe_id)


# Input: [{item: item_id, count: 3}, {item: item_id_2, count: 1}]
func set_station_recipe(station_id: String, recipe_id: String, input_ids: Array[Dictionary], output_ids: Array[Dictionary]) -> void:
	var input_array: Array[Dictionary] = []
	var output_array: Array[Dictionary] = []
	var input_size: int = 0
	var output_size: int = 0
	
	for input in input_ids:
		input_array.append({"item": "", "count": 1}.merged(input, true))
		input_size += 1
	
	for output in output_ids:
		output_array.append({"item": "", "count": 1}.merged(output, true))
		output_size += 1
	
	_recipes[station_id][recipe_id]["recipes"] = {
		"input": input_array,
		"input_size": input_size,
		"output": output_array,
		"output_size": output_size}


func get_recipe_id_with_input(station_id: String, input_items: Dictionary) -> String:
	var input_size: int = input_items.size()
	for recipe_id in _recipes[station_id]["recipes"]:
		if _recipes[station_id]["recipes"][recipe_id]["input_size"] != input_size:
			continue
		if input_items == _recipes[station_id]["recipes"][recipe_id]["input"]:
			return recipe_id
	return ""


func has_station(station_id: String) -> bool:
	return _recipes.has(station_id)


func has_recipe(station_id: String, recipe_id: String) -> bool:
	return _recipes.has(station_id) and _recipes[station_id]["recipes"].has(recipe_id)


func has_recipe_with_input(station_id: String, input_items: Dictionary) -> bool:
	var output_count: int = input_items.size()
	for recipe_id in _recipes[station_id]["recipes"]:
		if _recipes[station_id]["recipes"][recipe_id]["input_size"] != output_count:
			continue
		if _recipes[station_id]["recipes"][recipe_id]["input"] == input_items:
			return true
	return false


func has_recipe_with_output(station_id: String, output_items: Dictionary) -> bool:
	var output_count: int = output_items.size()
	for recipe_id in _recipes[station_id]["recipes"]:
		if _recipes[station_id]["recipes"][recipe_id]["output_size"] != output_count:
			continue
		if _recipes[station_id]["recipes"][recipe_id]["output"] == output_items:
			return true
	return false


func get_recipe_id_with_output(station_id: String, output_items: Dictionary) -> String:
	var output_count: int = output_items.size()
	for recipe_id in _recipes[station_id]["recipes"]:
		if _recipes[station_id]["recipes"][recipe_id]["output_size"] != output_count:
			continue
		if _recipes[station_id]["recipes"][recipe_id]["output"] == output_items:
			return recipe_id
	return ""


func get_recipe_input(station_id: String, recipe_id: String) -> Array[Dictionary]:
	return _recipes[station_id]["recipes"][recipe_id]["input"]#.duplicate()


func get_recipe_output(station_id: String, recipe_id: String) -> Array[Dictionary]:
	return _recipes[station_id]["recipes"][recipe_id]["output"]#.duplicate()


func set_item_path(item_id: String, item_path: String) -> void:
	_items[item_id]["path"] = item_path


func clear_items() -> void:
	_items.clear()


func clear_recipes() -> void:
	_recipes.clear()


func has_item(item_id: String) -> bool:
	return _items.has(item_id)


func remove_item(item_id: String) -> void:
	_items.erase(item_id)


func get_item_definition(item_id: String) -> ItemDefinition:
	return _items[item_id]["resource"]


func get_item_path(item_id: String) -> String:
	return _items[item_id]["path"]


func get_crafting_stations() -> Array:
	return _recipes.keys()


func get_recipes_of(station: String) -> Array:
	return _recipes[station]["recipes"].keys()


func save() -> void:
	var path: String = ProjectSettings.get_setting(SETTINGS_PATH, "res://item_database.tres")
	ResourceSaver.save(
			self,
			path)


## Loads all item resources into memory for access.
func load_items() -> void:
	for item in _items.keys():
		if _items[item]["path"].is_empty() or not ResourceLoader.exists(_items[item]["path"]):
			printerr(str("[DEPOT] Item with id \"", item, "\" wasn't found. Removing."))
			_items.erase(item)
		else:
			var res_preload: Resource = load(_items[item]["path"])
			if res_preload is ItemDefinition:
				_items[item]["resource"] = res_preload
			else:
				printerr(str("[DEPOT] Item with id \"", item, "\" isn't ItemDefinition. Removing."))
				_items.erase(item)
