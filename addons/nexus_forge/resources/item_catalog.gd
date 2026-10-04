@tool
@icon("res://addons/nexus_forge/icons/chest_full.svg")
class_name NFItemCatalog
extends Resource

@export_storage var _categories: Dictionary[StringName, Dictionary] = {}

@export_storage var _items: Dictionary[StringName, Dictionary] = {}

#region Items

## Returns an array with all the registered items.
func items() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_items.keys())
	return ids


## Returns a copy of the item [param item_id] custom data.
func item_data(item_id: StringName) -> Dictionary[StringName, Variant]:
	var item: Variant = _items.get(item_id)
	if typeof(item) != TYPE_DICTIONARY:
		return {}
	
	var c_data: Variant = item.get("custom_data")
	if typeof(c_data) != TYPE_DICTIONARY:
		return {}
	
	var data: Dictionary[StringName, Variant] = {}
	data.assign(c_data)
	return data.duplicate(true)


## Sets the [param data_key] of [param item_id] to [param data]. If [param data]
## is [code]null[/code] then the key is erased instead.
func set_item_data(item_id: StringName, data_key: String, data: Variant) -> void:
	if not _items.has(item_id):
		return
	
	if not _items[item_id].has("custom_data"):
		_items[item_id]["custom_data"] = NFDictUtils.create_typed(TYPE_STRING, TYPE_NIL)
	
	if data == null:
		_items[item_id]["custom_data"].erase(data_key)
	else:
		_items[item_id]["custom_data"][data_key] = data


## Clears the custom data from [param item_id].
func clear_item_data(item_id: StringName) -> void:
	var target: Variant = _items.get(item_id)
	if typeof(target) == TYPE_DICTIONARY:
		target["custom_data"].clear()


## Creates an item with id [param item_id] unless it already exists.[br]
## If [param item_data] isn't null, it'll create the item with the data from it.
func create_item(item_id: StringName, item_name: String, description: String, category: StringName, rarity: int, value: int, flags: PackedInt64Array, data: Dictionary[String, Variant]) -> void:
	if _items.has(item_id):
		return
	
	var new_entry: Dictionary[String, Variant] = {
		"name": item_name,
		"description": description,
		"category": category,
		"rarity": rarity,
		"value": value,
		"flags": flags,
		"custom_data": data}
	
	_items[item_id] = new_entry


## Sets all the [param flags] on [param item_id] to [param enabled].
func set_item_flags(item_id: StringName, flags: Array[NFItemSheet.ItemFlag], enabled: bool) -> void:
	if not _items.has(item_id):
		return
	
	if enabled:
		for flag in flags:
			if not _items[item_id]["flags"].has(flag):
				_items[item_id]["flags"].append(flag)
	else:
		for flag in flags:
			if _items[item_id]["flags"].has(flag):
				_items[item_id]["flags"].erase(flag)


## Returns an array with all the enabled flags of the item [param item_id].
func get_item_flags(item_id: StringName) -> Array[int]:
	var item: Variant = _items.get(item_id)
	if typeof(_items) != TYPE_DICTIONARY:
		return []
	
	var flag_arr: Variant = _items.get("flags")
	# NOTE: If the flags format changes, change this too
	if typeof(flag_arr) != TYPE_PACKED_INT64_ARRAY:
		return []
	var used_flags: Dictionary[int, Variant] = {}
	for flag in flag_arr:
		used_flags[flag] = null
	
	var item_flags: Array[int] = []
	if not used_flags.is_empty():
		item_flags.assign(used_flags.keys())
	
	return item_flags


## Returns true if the [param item_id] has [param flag] enabled.
func item_has_flag(item_id: StringName, flag: NFItemSheet.ItemFlag) -> bool:
	if _items.has(item_id):
		return _items[item_id]["flags"].has(flag)
	return false


## Clears all the flags from [param item_id].
func clear_item_flags(item_id: StringName) -> void:
	if not _items.has(item_id):
		return
	
	_items[item_id]["flags"].clear()



## Sets the name of [param item_id] to [param new_name].
func set_item_name(item_id: StringName, new_name: String) -> void:
	if not _items.has(item_id):
		return
	_items[item_id]["name"] = new_name


## Returns the name of [param item_id] or an empty string if the item doesn't exist.
func get_item_name(item_id: StringName) -> String:
	return NFDictUtils.get_nested_value(
			_items,
			[item_id, "name"],
			"",
			true)


## Returns the description of the [param item_id] or an empty string
## if the item isn't found.
func get_item_description(item_id: StringName) -> String:
	return NFDictUtils.get_nested_value(
			_items,
			[item_id, "description"],
			"",
			true)


## Sets the category of [param item_id] to [param new_category].
func set_item_category(item_id: StringName, new_category: StringName) -> void:
	if not _items.has(item_id):
		return
	
	_items[item_id]["category"] = new_category


## Returns the category of the [param item_id] or an empty stringname
## if the item isn't found.
## [br][br]
## [b]Note:[/b] An empty StringName can also mean that an item isn't
## set to any category.
func get_item_category(item_id: StringName) -> StringName:
	if _items.has(item_id):
		return _items[item_id]["category"]
	return &""


## Sets the rarity of [param item_id] to [param new_rarity].
func set_item_rarity(item_id: StringName, new_rarity: int) -> void:
	if not _items.has(item_id):
		return
	
	_items[item_id]["rarity"] = new_rarity


## Returns the rarity of [param item_id].
func get_item_rarity(item_id: StringName) -> int:
	return NFDictUtils.get_nested_value(
			_items,
			[item_id, "rarity"],
			0,
			true)


## Sets the value of [param item_id] to [param new_value].
func set_item_value(item_id: StringName, new_value: int) -> void:
	if not _items.has(item_id):
		return
	
	_items[item_id]["value"] = maxi(0, new_value)


## Returns the absolute value of [param item_id].
func get_item_value(item_id: StringName) -> int:
	var value = NFDictUtils.get_nested_value(
			_items,
			[item_id, "value"],
			0)
	var type: int = typeof(value)
	if type == TYPE_INT or type == TYPE_FLOAT:
		return value
	else:
		return 0


## Sets the description of [param item_id] to [param new_desc].
func set_item_description(item_id: StringName, new_desc: String) -> void:
	if not _items.has(item_id):
		return
	
	_items[item_id]["description"] = new_desc


## Returns an [NFItemSheet] of the item param item_id.[br]
## Returns [code]null[/code] if the item doesn't exist.
func get_item(item_id: StringName) -> NFItemSheet:
	if not _items.has(item_id):
		return null
	
	var item_sheet := NFItemSheet.new()
	var data: Dictionary = _items[item_id]
	item_sheet.name = data["name"]
	item_sheet.category = data["category"]
	item_sheet.rarity = data["rarity"]
	item_sheet.value = data["value"]
	item_sheet.description = data["description"]
	item_sheet.custom_data.assign(data["custom_data"])
	item_sheet.flags.assign(data["flags"])
	
	return item_sheet


## Returns true if [param item_id] is registered.
func has_item(item_id: StringName) -> bool:
	return _items.has(item_id)


## Erases [param item_id] from the registry.
func erase_item(item_id: StringName) -> void:
	_items.erase(item_id)

#endregion


#region Categories

## Returns an array with all category IDs.
func categories() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_categories.keys())
	return ids


## Creates a category with id [param category_id] unless it exists already.
func create_category(category_id: StringName, category_name: String, parent_category: StringName = &"", custom_data: Dictionary[String, Variant] = {}) -> void:
	if _categories.has(category_id):
		return
	
	var new_cat: Dictionary = {
		"parent_key": parent_category,
		"name": category_name,
		"custom_data": custom_data}
	
	_categories[category_id] = new_cat


## Sets [param category] to be a subcategory of [param parent_category].
func link_category(category: StringName, parent_category: StringName) -> void:
	if _categories.has(category):
		_categories[category]["parent_key"] = parent_category


## Sets the name of [param category_id] to [param category_name].
func set_category_name(category_id: StringName, category_name: String) -> void:
	if _categories.has(category_id):
		_categories[category_id]["name"] = category_name


## Returns the name of [param category_id] or an empty string if the category
## isn't registered.
func get_category_name(category_id: StringName) -> String:
	return NFDictUtils.get_nested_value(
			_categories,
			[category_id, "name"],
			"",
			true)


## Returns the parent category of [param category_id].
func get_category_parent(category_id: StringName) -> StringName:
	return NFDictUtils.get_nested_value(
			_categories,
			[category_id, "parent_key"],
			&"",
			true)


## Sets the custom data on [param data_key] to [param data].[br]
## If [param data] is [code]null[/code] then [param data_key] is erased.
func set_category_data(category_id: StringName, data_key: String, data: Variant) -> void:
	if not _categories.has(category_id):
		return
	
	if not _categories[category_id].has("custom_data"):
		_categories[category_id]["custom_data"] = NFDictUtils.create_typed(TYPE_STRING, TYPE_NIL)
	
	if data == null:
		_categories[category_id]["custom_data"].erase(data_key)
	else:
		_categories[category_id]["custom_data"][data_key] = data


## Clears the custom data from the category [param category_id].
func clear_category_data(category_id: StringName) -> void:
	var target_dict: Variant = _categories.get(category_id)
	if typeof(target_dict) == TYPE_DICTIONARY:
		target_dict["custom_data"].clear()


## Returns the custom data with key [param data_key] from the [param category_id].[br]
## Returns [code]null[/code] if [param category_id] isn't registered
## or [param data_key] doesn't exist.
func get_category_data(category_id: StringName, data_key: String) -> Variant:
	return NFDictUtils.get_nested_value(
			_categories,
			[category_id, "custom_data", data_key])


## Returns the custom data of the [param category_id].
func category_data(category_id: StringName) -> Dictionary[StringName, Variant]:
	var cat: Variant = _categories.get(category_id)
	if typeof(cat) != TYPE_DICTIONARY:
		return {}
	
	var data: Variant = cat.get("custom_data")
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	
	var custom_data: Dictionary[StringName, Variant] = {}
	custom_data.assign(data)
	return custom_data.duplicate(true)


## Returns true if [param category_id] is registered.
func has_category(category_id: StringName) -> bool:
	return _categories.has(category_id)


# Will remove itself from any item that has it. Use with caution
## Erases the category [param category_id] and removes the category from
## any item that has it.
func erase_category(category_id: StringName) -> void:
	if _categories.erase(category_id):
		for item in _items:
			if _items[item]["category"] == category_id:
				_items[item]["category"] = &""


## Returns a dictionary with all the parent categories from [param from_category].[br]
## get_category_structure(&"c") = [code]{&"a": {&"b": {&"c": {}}}[/code]
func get_supercategories_of(from_category: StringName) -> Dictionary[StringName, Dictionary]:
	var category_map: Dictionary[StringName, Dictionary] = {}
	
	if not _categories.has(from_category):
		return category_map
	
	var categories: Array[StringName] = [from_category]
	var current_category: StringName = _categories[from_category]["parent_key"]
	
	while current_category != &"" and not categories.has(current_category):
		categories.append(current_category)
		current_category = _categories[current_category]["parent_key"]
	
	categories.reverse()
	
	var level: Dictionary[StringName, Dictionary] = category_map
	for category in categories:
		var new_level: Dictionary[StringName, Dictionary] = {}
		level[category] = new_level
		level = new_level
	
	return category_map


## Gets all the subcategories of [param from_category] and their respective
## subcategories.
func get_subcategories_of(from_category: StringName) -> Dictionary[StringName, Dictionary]:
	var map: Dictionary[StringName, Dictionary] = {}
	if _categories.has(from_category):
		map[from_category] = _get_subcategories_of(from_category)
	return map


func _get_subcategories_of(from: StringName, exclude: Array[StringName] = [], existing_categories: Array[StringName] = categories()) -> Dictionary[StringName, Dictionary]:
	var map: Dictionary[StringName, Dictionary] = {}
	var required_levels: Array[StringName] = []
	
	for category in existing_categories:
		if category == from or exclude.has(category):
			continue
		if _categories[category]["parent_key"] == from:
			required_levels.append(category)
	
	exclude.append(from)
	for level in required_levels:
		map[level] = _get_subcategories_of(level, exclude.duplicate(), existing_categories)
	
	return map

#endregion
