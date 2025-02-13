@tool
class_name NFItemsRes
extends Resource


enum ItemFlags {
	SELLABLE,
	GIFTABLE
}


const SETTINGS_PATH: String = "nexus_forge/items_resource"

# Items be stored here
@export var _items: Dictionary = {
	#"a_type": {
		#"items": {
			#"item_id": {
				#"name": "",
				#"description": "",
				#"stack": 1,
				#"value": 0,
				#"rarity": 1, #Index on rarities
				#"icon": "res://example_icon.png",
				#"data": {"is_horny": true, "magic_number": 69}
				#}},
		#"subtypes": {"subtype": {"items": {}, "subtypes": {}}}
	#},
	#"another_type": {}
	}

@export var _rarities: Array[Dictionary] = [
	#{"name": "Commmon", "icon": "res://one_star.png", "data": {}}
]

@export var _currencies: Dictionary = {
	"copper": {"name": "CP", "value": 1, "data": {}},
	"silver": {"name": "SP", "value": 10, "data": {}},
	"electrum": {"name": "EP", "value": 50, "data": {}},
	"gold": {"name": "GP", "value": 100, "data": {}},
	"platinum": {"name": "PP", "value": 1000, "data": {}}
}

@export var _crafting: Dictionary = {
	#"station_id": {
		#"name": ":3",
		#"data": {},
		#"recipes": {
			#"recipe_id": {
				#"name": "",
				#"data": {},
				#"input": [{"item": "item_id", "amount": 0, "data": {"data_id": {"value": 0, "operator": OP_EQUAL}}}], # Array Dictionary
				#"output": []
			#}
		#}
	#}
}

var _currency_sorted: Array[String] = []


func _sort_currencies(currency_a: String, currency_b: String) -> bool:
	return _currencies[currency_a]["value"] < _currencies[currency_b]["value"]


## Call to load and sort currencies based on value.
func load_currencies() -> void:
	_currency_sorted.assign(_currencies.keys())
	_currency_sorted.sort_custom(_sort_currencies)


#region Crafting Stations

func create_crafting_station(station_id: String) -> void:
	_crafting[station_id] = {
		"name": "",
		"data": {},
		"recipes": {}}


func erase_crafting_station(station_id: String) -> void:
	_crafting.erase(station_id)


func get_crafting_station_name(station_id: String) -> String:
	return _crafting[station_id]["name"]


func set_crafting_station_name(station_id: String, new_name: String) -> void:
	_crafting[station_id]["name"] = new_name


func get_crafting_station_recipe_keys(station_id: String) -> Array[String]:
	return Array(
			_crafting[station_id]["recipes"].keys(),
			TYPE_STRING,
			&"",
			null)


func set_crafting_station_data(station_id: String, data_key: String, data_value: Variant) -> void:
	_crafting[station_id]["data"][data_key] = data_value


func get_crafting_station_data(station_id: String, data_key: String) -> Variant:
	return _crafting[station_id]["data"][data_key]


func get_crafting_station_data_keys(station_id: String) -> Array[String]:
	return Array(
			_crafting[station_id]["data"].keys(),
			TYPE_STRING,
			&"",
			null)



func erase_crafting_station_data(station_id: String, data_key: String) -> void:
	_crafting[station_id]["data"].erase(data_key)

#endregion

#region Crafting Recipes

func create_recipe(on_station: String, recipe_id: String) -> void:
	_crafting[on_station]["recipes"][recipe_id] = {
		"name": "",
		"data": {},
		"input": Array([], TYPE_DICTIONARY, &"", null),
		"output": Array([], TYPE_DICTIONARY, &"", null)}


func erase_recipe(on_station: String, recipe_id: String) -> void:
	_crafting[on_station]["recipes"].erase(recipe_id)


func set_recipe_name(station_id: String, recipe_id: String, new_name: String) -> void:
	_crafting[station_id]["recipes"][recipe_id]["name"] = new_name


func get_recipe_name(station_id: String, recipe_id: String) -> String:
	return _crafting[station_id]["recipes"][recipe_id]["name"]


func get_recipe_input(station_id: String, recipe_id: String) -> Array[Dictionary]:
	return _crafting[station_id]["recipes"][recipe_id]["input"].duplicate(true)


func get_recipe_output(station_id: String, recipe_id: String) -> Array[Dictionary]:
	return _crafting[station_id]["recipes"][recipe_id]["output"].duplicate(true)


func add_crafting_station_recipe_input(station_id: String, recipe_id: String, item_id: String, amount: int, item_data: Dictionary) -> void:
	_crafting[station_id]["recipes"][recipe_id]["input"].append({"item": item_id, "amount": amount, "data": item_data})


func add_crafting_station_recipe_output(station_id: String, recipe_id: String, item_id: String, amount: int, item_data: Dictionary) -> void:
	_crafting[station_id]["recipes"][recipe_id]["output"].append({"item": item_id, "amount": amount, "data": item_data})


func remove_recipe_input(station_id: String, recipe_id: String, item_id: String) -> void:
	var idx: int = -1
	for item in _crafting[station_id]["recipes"][recipe_id]["input"]:
		idx += 1
		if item["item"] == item_id:
			_crafting[station_id]["recipes"][recipe_id]["input"].remove_at(idx)
			break


func remove_recipe_output(station_id: String, recipe_id: String, item_id: String) -> void:
	var idx: int = -1
	for item in _crafting[station_id]["recipes"][recipe_id]["output"]:
		idx += 1
		if item["item"] == item_id:
			_crafting[station_id]["recipes"][recipe_id]["output"].remove_at(idx)
			break


func get_recipe_data_keys(station_id: String, recipe_id: String) -> Array[String]:
	return Array(
			_crafting[station_id]["recipes"][recipe_id]["data"].keys(),
			TYPE_STRING,
			&"",
			null)


func get_recipe_data(station_id: String, recipe_id: String, data_key: String) -> Variant:
	return _crafting[station_id]["recipes"][recipe_id]["data"][data_key]


func set_recipe_data(station_id: String, recipe_id: String, data_key: String, data_value: Variant) -> void:
	_crafting[station_id]["recipes"][recipe_id]["data"][data_key] = data_value


#func get_recipe_data_operator(station_id: String, recipe_id: String, data_key: String) -> int:
	#return _crafting[station_id]["recipes"][recipe_id]["data"][data_key]["operator"]
#
#
#func set_recipe_data_operator(station_id: String, recipe_id: String, data_key: String, operator: int) -> void:
	#_crafting[station_id]["recipes"][recipe_id]["data"][data_key]["operator"] = operator


func erase_recipe_data(station_id: String, recipe_id: String, data_key: String) -> void:
	_crafting[station_id]["recipes"][recipe_id]["data"].erase(data_key)

#endregion

#region Rarities

func create_rarity(rarity_name: String = "Unnamed Rarity", rarity_idx: int = -1) -> void:
	var rarity_dict: Dictionary = {
		"name": rarity_name,
		"color": Color.WHITE,
		"data": {}
		#{"name": "Commmon", "icon": "res://one_star.png", "data": {}}
	}
	if 0 <= rarity_idx:
		_rarities.insert(rarity_idx, rarity_dict)
	else:
		_rarities.append(rarity_dict)


func remove_rarity(rarity_idx: int) -> void:
	_rarities.remove_at(rarity_idx)


func get_rarity_count() -> int:
	return _rarities.size()


func set_rarity_name(rarity_idx: int, rarity_name: String) -> void:
	_rarities[rarity_idx]["name"] = rarity_name


func get_rarity_name(rarity_idx: int) -> String:
	return _rarities[rarity_idx]["name"]


func set_rarity_color(rarity_idx: int, color: Color) -> void:
	_rarities[rarity_idx]["color"] = color


func get_rarity_color(rarity_idx: int) -> Color:
	return _rarities[rarity_idx]["color"]


func set_rarity_data(rarity_idx: int, data_key: String, data_value: Variant) -> void:
	_rarities[rarity_idx]["data"][data_key] = data_value


func get_rarity_data(ratity_idx: int, data_key: String) -> Variant:
	return _rarities[ratity_idx]["data"][data_key]


func erase_rarity_data(rarity_idx: int, data_key: String) -> void:
	_rarities[rarity_idx]["data"].erase(data_key)


func get_rarity_keys(rarity_idx: int) -> Array[String]:
	return Array(_rarities[rarity_idx]["data"].keys(), TYPE_STRING, &"", null)

#endregion

#region Items

# --- Item Categories ---
func create_item_category(category_path: String, category_id: String) -> void:
	var target_category: Dictionary = _items
	
	for subcat in category_path.split("/", false):
		target_category = target_category[subcat]["subcategories"]
	
	target_category[category_id] = {
		"items": {},
		"subcategories": {},
		"name": "",
		"description": ""
		}


func erase_item_category(category_path: String) -> void:
	var path_array: PackedStringArray = category_path.split("/", false)
	var category_key: String = path_array[-1]
	var target_category: Dictionary = _items
	path_array.resize(path_array.size() - 1)
	
	for subcat in path_array:
		target_category = target_category[subcat]["subcategories"]
	
	target_category.erase(category_key)


func get_category_name(category_path: String) -> String:
	return get_item_category_dict(category_path)["name"]


func set_category_name(category_path: String, category_name: String) -> void:
	get_item_category_dict(category_path)["name"] = category_name


func set_category_description(category_path: String, category_desc: String) -> void:
	get_item_category_dict(category_path)["description"] = category_desc


func get_category_description(category_path: String) -> String:
	return get_item_category_dict(category_path)["description"]


func get_category_item_keys(category_path: String) -> Array[String]:
	return Array(
		get_item_category_dict(category_path)["items"].keys(),
		TYPE_STRING,
		&"",
		null)


func get_item_data_keys(category_path: String, item_key: String) -> Array[String]:
	return Array(
			get_item_category_dict(category_path)["items"][item_key]["data"].keys(),
			TYPE_STRING,
			&"",
			null)


func get_item_category_dict(category_path: String) -> Dictionary:
	var path: PackedStringArray = category_path.split("/", false)
	
	if path.size() == 0:
		return {}
	
	var target_category: Dictionary = _items
	var target_folder: String = path[-1]
	path.resize(path.size() - 1)
	
	for subcat in path:
		target_category = target_category[subcat]["subcategories"]
	
	return target_category[target_folder]

# -----------------------
# --- Items ---

func create_item(category_path: String, item_id: String) -> void:
	get_item_category_dict(category_path)["items"][item_id] = {
		"name": "",
		"description": "",
		"stack": 1,
		"value": 0,
		"rarity": -1  if _rarities.is_empty() else 0,
		"data": {}}


func erase_item(category_path: String, item_id: String) -> void:
	get_item_category_dict(category_path)["items"].erase(item_id)


func set_item_name(category_path: String, item_id: String, new_name: String) -> void:
	get_item_category_dict(category_path)["items"][item_id]["name"] = new_name


func get_item_name(category_path: String, item_id: String) -> String:
	return get_item_category_dict(category_path)["items"][item_id]["name"]


func set_item_description(category_path: String, item_id: String, description: String) -> void:
	get_item_category_dict(category_path)["items"][item_id]["description"] = description


func get_item_description(category_path: String, item_id: String) -> String:
	return get_item_category_dict(category_path)["items"][item_id]["description"]


func set_item_stack(category_path: String, item_id: String, stack: int) -> void:
	get_item_category_dict(category_path)["items"][item_id]["stack"] = stack


func get_item_stack(category_path: String, item_id: String) -> int:
	return get_item_category_dict(category_path)["items"][item_id]["stack"]


func set_item_value(category_path: String, item_id: String, value: int) -> void:
	get_item_category_dict(category_path)["items"][item_id]["value"] = value


func get_item_value(category_path: String, item_id: String) -> int:
	return get_item_category_dict(category_path)["items"][item_id]["value"]


func set_item_rarity(category_path: String, item_id: String, rarity: int) -> void:
	get_item_category_dict(category_path)["items"][item_id]["rarity"] = rarity


func get_item_rarity(category_path: String, item_id: String) -> int:
	return get_item_category_dict(category_path)["items"][item_id]["rarity"]


func set_item_data(category_path: String, item_id: String, data_key: String, data_value: Variant) -> void:
	get_item_category_dict(category_path)["items"][item_id]["data"][data_key] = data_value


func get_item_data(category_path: String, item_id: String, data_key: String) -> Variant:
	return get_item_category_dict(category_path)["items"][item_id]["data"][data_key]


func erase_item_data(category_path: String, item_id: String, data_key: String) -> void:
	get_item_category_dict(category_path)["items"][item_id]["data"].erase(data_key)

# -------------

#endregion

#region Currencies

func create_currency(id: String, name: String = "", value: int = 1) -> void:
	_currencies[id] = {"name": name, "data": {}, "value": maxi(1, value)}


func erase_currency(currency_id: String) -> void:
	_currencies.erase(currency_id)


func get_currencies() -> Array[String]:
	return Array(
			_currencies.keys(),
			TYPE_STRING,
			&"",
			null)


func get_currency_name(currency_id: String) -> String:
	return _currencies[currency_id]["name"]


func get_currency_value(currency_id: String) -> int:
	return _currencies[currency_id]["value"]


func set_currency_name(id: String, new_name: String) -> void:
	_currencies[id]["name"] = new_name


func set_currency_value(id: String, new_value: int) -> void:
	_currencies[id]["value"] = maxi(1, new_value)


func set_currency_data(id: String, data_key: String, data_value: Variant) -> void:
	_currencies[id]["data"][data_key] = data_value


func get_currency_data(id: String, data_key: String) -> Variant:
	return _currencies[id]["data"][data_key]


func get_currency_data_keys(id: String) -> Array[String]:
	return Array(
			_currencies[id]["data"].keys(),
			TYPE_STRING,
			&"",
			null
			)


func convert_currency(from: String, to: String, amount: int) -> Dictionary:
	if not _currencies.has_all([from, to]):
		printerr("Invalid currency names.")
		return {from: amount, to: 0}

	var from_value: int = _currencies[from]["value"]
	var to_value: int = _currencies[to]["value"]

	var converted_amount: int = floori((amount * from_value) / to_value)
	var remainder: int = floori( ( (amount * from_value) - (converted_amount * to_value) ) / from_value )

	var result: Dictionary = {from: remainder, to: converted_amount}
	
	return result


func maximize_currency(currency_type: String, amount: int) -> Dictionary:
	if not _currencies.has(currency_type):
		printerr("Invalid currency type.")
		return {currency_type: amount}
	
	var denominations: Array[String] = []
	var input_value: int = _currencies[currency_type]["value"]
	
	# Extract denominations and sort in descending order (important for maximizing)
	for key in _currencies:
		# We skip lower or equally denominated currencies.
		if _currencies[key]["value"] <= input_value:
			continue
		denominations.append(key)

	denominations.sort_custom(func(a, b): return _currencies[b]["value"] < _currencies[a]["value"]) # Sort descending

	var result: Dictionary = {}
	var current_amount: int = amount # Start with the initial amount

	for denom in denominations:
		var denom_value: int = _currencies[denom]["value"]
		var exchangeable_amount: int = floori(float(current_amount * input_value) / denom_value)

		if 0 < exchangeable_amount:
			result[denom] = exchangeable_amount
			current_amount -= floori((exchangeable_amount * denom_value) / input_value)
	
	if 0 < current_amount:
		result[currency_type] = current_amount

	return result


func minimize_currency(currency_type: String, amount: int) -> Dictionary:
	if not _currencies.has(currency_type):
		printerr("Invalid currency type.")
		return {currency_type: amount}

	var denominations: Array[String] = []
	var input_value: int = _currencies[currency_type]["value"]

	# Extract denominations and sort in ascending order (important for minimizing)
	for key in _currencies:
		# We skip higher or equally denominated currencies.
		if input_value <= _currencies[key]["value"]:
			continue
		denominations.append(key)

	denominations.sort_custom(func(a, b): return _currencies[a]["value"] < _currencies[b]["value"]) # Sort ascending

	var result: Dictionary = {}  # Start with the initial amount
	var current_amount: int = amount

	for denom in denominations:
		var denom_value: int = _currencies[denom]["value"]
		var exchangeable_amount: int = floori(float(current_amount * input_value) / denom_value)

		if 0 < exchangeable_amount:
			result[denom] = exchangeable_amount
			current_amount -= floori( (exchangeable_amount * denom_value) / input_value )
	
	if 0 < current_amount:
		result[currency_type] = current_amount
	
	return result


#endregion


func save() -> void:
	ResourceSaver.save(
			self,
			ProjectSettings.get_setting(SETTINGS_PATH, "res://item_database.tres"))
