@tool
class_name ItemCatalog
extends Resource


const ITEM_DEFAULT_DATA: Dictionary[String, Variant] = {}
const CATEGORY_DEFAULT_DATA: Dictionary[String, Variant] = {}


@export var _categories: Dictionary[StringName, Dictionary] = {}

# Items be stored here
@export var _items: Dictionary[StringName, Dictionary] = {
	#&"test_item": {
		#"name": "Test Item",
		#"category": &"second_class",
		#"rarity": Rarity.COMMON,
		#"value": 25,
		#"description": "This is a test item",
		#"flags": [ItemFlag.SELLABLE],
		#"custom_data": null}
		}


#region Items

func items() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_items.keys())
	return ids


func set_item_data(item_id: StringName, data_key: String, data: Variant) -> void:
	if data == null:
		if _items[item_id]["data"].has(data_key):
			_items[item_id]["data"].erase(data_key)
	else:
		_items[item_id]["data"][data_key] = data


func clear_item_data(item_id: StringName) -> void:
	_items[item_id]["data"].clear()


func create_item(item_id: StringName) -> void:
	if _items.has(item_id):
		return
	
	var item_custom_data: Dictionary[String, Variant] = {}
	var flags: Array[ItemSheet.ItemFlag] = []
	item_custom_data.assign(ITEM_DEFAULT_DATA)
	
	var new_entry: Dictionary = {
		"name": "",
		"category": &"",
		"rarity": ItemSheet.Rarity.COMMON,
		"value": 0,
		"description": "",
		"flags": flags,
		"data": item_custom_data}
	
	_items[item_id] = new_entry


func set_item_flag(item_id: StringName, flag: ItemSheet.ItemFlag, enabled: bool) -> void:
	if not _items.has(item_id):
		return
	var has: bool = _items[item_id]["flags"].has(flag)
	if enabled:
		if not has:
			_items[item_id]["flags"].append(flag)
	else:
		if has:
			_items[item_id]["flags"].erase(flag)


func set_item_flags(item_id: StringName, flags: Array[ItemSheet.ItemFlag]) -> void:
	if not _items.has(item_id):
		return
	_items[item_id]["flags"].clear()
	_items[item_id]["flags"].assign(flags)


func item_has_flag(item_id: StringName, flag: ItemSheet.ItemFlag) -> bool:
	if _items.has(item_id):
		return _items[item_id]["flags"].has(flag)
	return false


func clear_item_flags(item_id: StringName) -> void:
	if _items.has(item_id):
		_items[item_id]["flags"].clear()


func set_item_name(item_id: StringName, new_name: String) -> void:
	if _items.has(item_id):
		_items[item_id]["name"] = new_name


func get_item_name(item_id: StringName) -> String:
	if _items.has(item_id):
		return _items[item_id]["name"]
	return ""


func set_item_category(item_id: StringName, new_category: StringName) -> void:
	if _items.has(item_id) and ( _categories.has(new_category) or new_category.is_empty() ):
		_items[item_id]["category"] = new_category


func set_item_rarity(item_id: StringName, new_rarity: ItemSheet.Rarity) -> void:
	if _items.has(item_id):
		_items[item_id]["rarity"] = new_rarity


func set_item_value(item_id: StringName, new_value: int) -> void:
	if _items.has(item_id):
		_items[item_id]["value"] = maxi(0, new_value)


func set_item_description(item_id: StringName, new_desc: String) -> void:
	if _items.has(item_id):
		_items[item_id]["description"] = new_desc


func get_item(item_id: StringName) -> ItemSheet:
	if not _items.has(item_id):
		return null
	
	var item_sheet := ItemSheet.new()
	var data: Dictionary = _items[item_id]
	item_sheet.name = data["name"]
	item_sheet.category = data["category"]
	item_sheet.rarity = data["rarity"]
	item_sheet.value = data["value"]
	item_sheet.description = data["description"]
	item_sheet.data = data["data"].duplicate(true)
	item_sheet.flags.assign(data["flags"])
	
	return item_sheet


func has_item(item_id: StringName) -> bool:
	return _items.has(item_id)


func erase_item(item_id: StringName) -> void:
	if _items.has(item_id):
		_items.erase(item_id)

#endregion


#region Categories

func categories() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_categories.keys())
	return ids


func create_category(category_id: StringName) -> void:
	if _categories.has(category_id):
		return
	
	var category_data: Dictionary[String, Variant] = {}
	category_data.assign(CATEGORY_DEFAULT_DATA)
	var types: Dictionary[StringName, Dictionary] = {}
	
	var new_cat: Dictionary = {
		"parent_key": &"",
		"name": "",
		"data": category_data}
	
	_categories[category_id] = new_cat


func link_category(category: StringName, subcategory: StringName) -> void:
	if _categories.has(subcategory) and ( _categories.has(category) or category.is_empty() ):
		print(subcategory, " is a subcategory of ", category)
		_categories[subcategory]["parent_key"] = category
	else:
		print("Something failed")


func set_category_name(category_id: StringName, category_name: String) -> void:
	if _categories.has(category_id):
		_categories[category_id]["name"] = category_name


func get_category_name(category_id: StringName) -> String:
	if _categories.has(category_id):
		return _categories[category_id]["name"]
	return ""


func set_category_data(category_id: StringName, data_key: String, data: Variant) -> void:
	if not _categories.has(category_id):
		return
	
	if data == null:
		if _categories[category_id]["data"].has(data_key):
			_categories[category_id]["data"].erase(data_key)
	else:
		_categories[category_id]["data"][data_key] = data


func clear_category_data(category_id: StringName) -> void:
	if _categories.has(category_id):
		_categories[category_id]["data"].clear()


func get_category_data(category_id: StringName, data_key: String) -> Variant:
	if _categories.has(category_id) and _categories[category_id]["data"].has(data_key):
		return _categories[category_id]["data"][data_key]
	return null


func has_category(category_id: StringName) -> bool:
	return _categories.has(category_id)


# Will remove itself from any item that has it. Use with caution
func erase_category(category_id: StringName) -> void:
	if _categories.erase(category_id):
		for item in _items:
			if _items[item]["category"] == category_id:
				_items[item]["category"] = &""


## Returns a dictionary with all the parent categories from [param from_category].[br]
## get_category_structure(&"c") = {&"a": {&"b": {&"c": {}}}
func get_supercategories_of(from_category: StringName) -> Dictionary[StringName, Dictionary]:
	var category_map: Dictionary[StringName, Dictionary] = {}
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


func save() -> void:
	ResourceSaver.save(
			self,
			ProjectSettings.get_setting(
					EditorNFPlugin.get_project_settings_path("items"),
					"res://item_catalog_resource.tres"))
