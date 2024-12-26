@tool
class_name NFItemsRes
extends Resource


enum ItemFlags {
	SELLABLE,
	GIFTABLE
}


const SETTINGS_PATH: String = "nexus_forge/items_resource"

var item_types: Dictionary = {}
var item_materials: Dictionary = {}

@export var _item_data: Dictionary = {
	"a_type": {
		"items": {
			"item_id": {
				"name": "",
				"description": "",
				"stack": 1,
				"value": 0,
				"rarity": 1, #Index on rarities
				"icon": "res://example_icon.png",
				"data": {"is_horny": true, "magic_number": 69}
				}},
		"subtypes": {"subtype": {"items": {}, "subtypes": {}}}
	},
	"another_type": {}}

@export var _rarities: Array[Dictionary] = [
	#{"name": "Commmon", "icon": "res://one_star.png", "data": {}}
]

@export var _currencies: Dictionary = {
	#"gold": {"name": "GC", "value": 1}
}


@export var _items: Dictionary = {}
@export var _recipes: Dictionary = {}

var _currency_sorted: Array[String] = []


func create_rarity(rarity_name: String = "Unnamed Rarity", rarity_idx: int = -1) -> void:
	var rarity_dict: Dictionary = {
		"name": rarity_name,
		"icon": "",
		"color": Color.WHITE,
		"data": {}
		#{"name": "Commmon", "icon": "res://one_star.png", "data": {}}
	}
	if 0 <= rarity_idx:
		_rarities.insert(rarity_idx, rarity_dict)
	else:
		_rarities.append(rarity_dict)


func set_rarity_name(rarity_idx: int, rarity_name: String) -> void:
	_rarities[rarity_idx]["name"] = rarity_name


func get_rarity_name(rarity_idx: int) -> String:
	return _rarities[rarity_idx]["name"]


func remove_rarity(rarity_idx: int) -> void:
	_rarities.remove_at(rarity_idx)


func set_rarity_color(rarity_idx: int, color: Color) -> void:
	_rarities[rarity_idx]["color"] = color


func get_rarity_color(rarity_idx: int) -> Color:
	return _rarities[rarity_idx]["color"]


func set_rarity_icon_path(rarity_idx: int, path: String) -> void:
	_rarities[rarity_idx]["icon"] = path


func get_rarity_icon_path(rarity_idx: int) -> String:
	return _rarities[rarity_idx]["icon"]


func set_rarity_data(rarity_idx: int, data_key: String, data_value: Variant) -> void:
	_rarities[rarity_idx]["data"][data_key] = data_value


func erase_rarity_data(rarity_idx: int, data_key: String) -> void:
	_rarities[rarity_idx]["data"].erase(data_key)


func get_rarity_keys(rarity_idx: int) -> Array[String]:
	return Array(_rarities[rarity_idx]["data"].keys(), TYPE_STRING, &"", null)


func get_rarity_data(ratity_idx: int, data_key: String) -> Variant:
	return _rarities[ratity_idx]["data"][data_key]


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


func set_currency_name(id: String, new_name: String) -> void:
	_currencies[id]["name"] = new_name


func set_currency_value(id: String, new_value: int) -> void:
	_currencies[id]["value"] = new_value


func erase_currency(currency_id: String) -> void:
	_currencies.erase(currency_id)


func clear_currencies() -> void:
	_currencies.clear()


func create_currency(id: String, name: String, value: int) -> void:
	_currencies[id] = {"name": name, "value": maxi(1, value)}


func _sort_currencies(currency_a: String, currency_b: String) -> bool:
	return _currencies[currency_a]["value"] < _currencies[currency_b]["value"]


func create_item(item_key: String, path: String) -> void:
	_items[item_key] = {"path": path, "resource": null}


func get_item_types() -> Array[String]:
	return Array(item_types.keys(), TYPE_STRING, &"", null)


func get_item_subtypes(item_type: String) -> Array[String]:
	return Array(item_types[item_type]["subtypes"].keys(), TYPE_STRING, &"", null)


func get_item_type_name(type_id: String) -> String:
	return item_types[type_id]["name"]


func get_subtype_name(type_id: String, subtype_id: String) -> String:
	return item_types[type_id]["subtypes"][subtype_id]["name"]


func get_materials() -> Array:
	return item_materials.keys()


func get_material_name(material_id: String) -> String:
	return item_materials[material_id]["name"]


func get_item_ids() -> Array[String]:
	return Array(_items.keys(), TYPE_STRING, &"", null)


func create_crafting_station(station_id: String, station_name: String = "") -> void:
	_recipes[station_id] = {"name": "", "recipes": {}}


func set_station_name(station_id: String, station_name: String) -> void:
	_recipes[station_id]["name"] = station_name


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
	
	_recipes[station_id]["recipes"][recipe_id] = {
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


func has_item_file(item_path: String) -> bool:
	for key in _items:
		if _items[key]["path"] == item_path:
			return true
	return false


func remove_item(item_id: String) -> void:
	_items.erase(item_id)


func get_item_definition(item_id: String) -> ItemDefinition:
	return _items[item_id]["resource"]


func get_item_path(item_id: String) -> String:
	return _items[item_id]["path"]


func get_crafting_stations() -> Array[String]:
	return Array(_recipes.keys(), TYPE_STRING, &"", null)


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
