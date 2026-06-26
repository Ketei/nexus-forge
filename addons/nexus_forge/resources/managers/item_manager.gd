class_name NFItemManager
extends RefCounted
## An object that holds items as [ItemSheet] resources.
##
## This object provides several utilities, such as a custom getter
## for accessing registered items directly by their ID, eg. [code]Items.stick[/code]
## and when an item is modified through this, the signal [Resource.changed] is
## called on the specific item.


## Emits when an item is created.
signal item_created(item_id: StringName)
## Emits when an item is removed.
signal item_erased(item_id: StringName)
## Emits when a category is created.
signal category_created(category_id: StringName)
## Emits when a category is removed.
signal category_erased(category_id: StringName)


var _categories: Dictionary[StringName, Dictionary] = {}

var _items: Dictionary[StringName, ItemSheet] = {}


func _get(property: StringName) -> Variant:
	if _items.has(property):
		return _items[property]
	return null


## Loads an [ItemCatalog] into this object. If [param clear_items] is
## [code]true[/code] then the previous registered items will be cleared.
func load_catalog(catalog: ItemCatalog, clear_items: bool = true) -> void:
	if clear_items:
		_items.clear()
		_categories.clear()
	
	for category_id in catalog.categories():
		var category: Dictionary[String, Variant] = {
			"parent_key": catalog.get_category_parent(category_id),
			"name": catalog.get_category_name(category_id),
			"custom_data": catalog.category_data(category_id)}
		_categories[category_id] = category
	
	for item_id in catalog.items():
		var new_item: ItemSheet = ItemSheet.new()
		new_item.name = catalog.get_item_name(item_id)
		new_item.description = catalog.get_item_description(item_id)
		new_item.category = catalog.get_item_category(item_id)
		new_item.rarity = catalog.get_item_rarity(item_id)
		new_item.value = catalog.get_item_value(item_id)
		new_item.flags.assign(catalog.get_item_flags(item_id))
		new_item.custom_data.assign(catalog.item_data(item_id))
		_items[item_id] = new_item


#region Items

## Returns an array with all the registered items.
func items() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_items.keys())
	return ids


## Sets the [param data_key] of [param item_id] to [param data]. If [param data]
## is [code]null[/code] then the key is erased instead.
func set_item_data(item_id: StringName, data_key: String, data: Variant) -> void:
	if not _items.has(item_id):
		return
	
	var update: bool = true
	
	if data == null:
		update = _items[item_id].custom_data.erase(data_key)
	else:
		_items[item_id].custom_data[data_key] = data
	
	if update:
		_items[item_id].emit_changed()


## Clears the custom data from [param item_id].
func clear_item_data(item_id: StringName) -> void:
	if not _items.has(item_id) or _items[item_id].custom_data.is_empty():
		return
	
	_items[item_id].custom_data.clear()
	_items[item_id].emit_changed()


## Registers the [param item_sheet] as an item unless [member ItemSheet.item_id]
## it uses already exists or is empty.[br]
## Note: Items are passed by reference, and [param item_sheet] will be
## stored AS the reference.
func register_item(item_sheet: ItemSheet = null) -> void:
	if item_sheet.item_id.is_empty() or _items.has(item_sheet.item_id):
		return
	
	_items[item_sheet.item_id] = item_sheet
	
	item_created.emit(item_sheet.item_id)


## Sets the [param flag] on [param item_id] to [param enabled].
func set_item_flag(item_id: StringName, flag: ItemSheet.ItemFlag, enabled: bool) -> void:
	if not _items.has(item_id):
		return
	
	var has: bool = _items[item_id].flags.has(flag)
	
	if enabled and not has:
		_items[item_id].flags.append(flag)
		_items[item_id].emit_changed()
	elif not enabled and has:
		_items[item_id].flags.erase(flag)
		_items[item_id].emit_changed()


## Sets all the [param flags] on [param item_id] to [param enabled].
func set_item_flags(item_id: StringName, flags: Array[ItemSheet.ItemFlag], enabled: bool) -> void:
	if not _items.has(item_id):
		return
	
	if enabled and not ArrayUtils.has_all(_items[item_id]["flags"], flags):
		for flag in flags:
			if not _items[item_id].flags.has(flag):
				_items[item_id].flags.append(flag)
		_items[item_id].emit_changed()
	elif not enabled and ArrayUtils.has_any(_items[item_id].flags, flags):
		for flag in flags:
			if _items[item_id]["flags"].has(flag):
				_items[item_id]["flags"].erase(flag)
		_items[item_id].emit_changed()


## Returns true if the [param item_id] has [param flag] enabled.
func item_has_flag(item_id: StringName, flag: ItemSheet.ItemFlag) -> bool:
	if _items.has(item_id):
		return _items[item_id].flags.has(flag)
	return false


## Clears all the flags from [param item_id].
func clear_item_flags(item_id: StringName) -> void:
	if not _items.has(item_id) or _items[item_id].flags.is_empty():
		return
	
	_items[item_id].flags.clear()
	_items[item_id].emit_changed()


## Sets the name of [param item_id] to [param new_name].
func set_item_name(item_id: StringName, new_name: String) -> void:
	if not _items.has(item_id) or _items[item_id].name == new_name:
		return
	
	_items[item_id].name = new_name
	_items[item_id].emit_changed()


## Returns the name of [param item_id] or an empty string if the item doesn't exist.
func get_item_name(item_id: StringName) -> String:
	if _items.has(item_id):
		return _items[item_id].name
	return ""


## Sets the category of [param item_id] to [param new_category].
func set_item_category(item_id: StringName, new_category: StringName) -> void:
	if not _items.has(item_id) or _items[item_id].category == new_category or not ( _categories.has(new_category) or new_category.is_empty() ):
		return
	
	_items[item_id].category = new_category
	_items[item_id].emit_changed()


## Sets the rarity of [param item_id] to [param new_rarity].
func set_item_rarity(item_id: StringName, new_rarity: ItemSheet.Rarity) -> void:
	if not _items.has(item_id) or _items[item_id].rarity == new_rarity:
		return
	
	_items[item_id].rarity = new_rarity
	_items[item_id].emit_changed()


## Sets the value of [param item_id] to [param new_value].
func set_item_value(item_id: StringName, new_value: int) -> void:
	if not _items.has(item_id) or _items[item_id].value == new_value:
		return
	
	_items[item_id].value = maxi(0, new_value)
	_items[item_id].emit_changed()


## Sets the description of [param item_id] to [param new_desc].
func set_item_description(item_id: StringName, new_desc: String) -> void:
	if not _items.has(item_id) or _items[item_id].description == new_desc:
		return
	
	_items[item_id]["description"] = new_desc
	_items[item_id].emit_changed()


## Returns an [ItemSheet] of the item param item_id.[br]
## Returns [code]null[/code] if the item doesn't exist.
func get_item(item_id: StringName) -> ItemSheet:
	if not _items.has(item_id):
		return null
	
	return _items[item_id]


## Returns true if [param item_id] is registered.
func has_item(item_id: StringName) -> bool:
	return _items.has(item_id)


## Erases [param item_id] from the registry.
func erase_item(item_id: StringName) -> void:
	if _items.erase(item_id):
		item_erased.emit(item_id)

#endregion


#region Categories

## Returns an array with all category IDs.
func categories() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_categories.keys())
	return ids


## Creates a category with id [param category_id] unless it exists already.
func create_category(category_id: StringName) -> void:
	if _categories.has(category_id):
		return
	
	var cat: Dictionary[String, Variant] = {
		"parent_key": &"",
		"name": &"",
		"custom_data": DictUtils.create_typed(TYPE_STRING_NAME, TYPE_NIL)}
	
	_categories[category_id] = cat
	
	category_created.emit(category_id)


## Sets [param category] to be a subcategory of [param parent_category].
func link_category(category: StringName, parent_category: StringName) -> void:
	if _categories.has(category) and ( _categories.has(parent_category) or parent_category.is_empty() ):
		_categories[category]["parent_key"] = parent_category


## Sets the name of [param category_id] to [param category_name].
func set_category_name(category_id: StringName, category_name: String) -> void:
	if _categories.has(category_id):
		_categories[category_id]["name"] = category_name


## Returns the name of [param category_id] or an empty string if the category
## isn't registered.
func get_category_name(category_id: StringName) -> String:
	if _categories.has(category_id):
		return _categories[category_id]["name"]
	return ""


## Sets the custom data on [param data_key] to [param data].[br]
## If [param data] is [code]null[/code] then [param data_key] is erased.
func set_category_data(category_id: StringName, data_key: String, data: Variant) -> void:
	if not _categories.has(category_id):
		return
	
	if data == null:
		_categories[category_id]["custom_data"].erase(data_key)
	else:
		_categories[category_id]["custom_data"][data_key] = data


## Clears the custom data from the category [param category_id].
func clear_category_data(category_id: StringName) -> void:
	if _categories.has(category_id):
		_categories[category_id]["custom_data"].clear()


## Returns the custom data with key [param data_key] from the [param category_id].[br]
## Returns [code]null[/code] if [param category_id] isn't registered
## or [param data_key] doesn't exist.
func get_category_data(category_id: StringName, data_key: String) -> Variant:
	if _categories.has(category_id) and _categories[category_id]["custom_data"].has(data_key):
		return _categories[category_id]["custom_data"][data_key]
	return null


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
		category_erased.emit(category_id)


## Returns a dictionary with all the parent categories from [param from_category].[br]
## get_category_structure(&"c") = [code]{&"a": {&"b": {&"c": {}}}[/code]
func get_supercategories_of(from_category: StringName) -> Dictionary[StringName, Dictionary]:
	var category_map: Dictionary[StringName, Dictionary] = {}
	var explored_categories: Array[StringName] = [from_category]
	var current_category: StringName = _categories[from_category]["parent_key"]
	
	while current_category != &"" and not explored_categories.has(current_category):
		explored_categories.append(current_category)
		current_category = _categories[current_category]["parent_key"]
	
	explored_categories.reverse()
	
	var level: Dictionary[StringName, Dictionary] = category_map
	for category in explored_categories:
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
