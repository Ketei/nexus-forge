@tool
extends Control


var _items_resource: NFItemsRes = null
var _current_id: String = ""
var _current_station: String = ""
var _current_recipe: String = ""
var item_memory: Dictionary = {}
var recipe_memory: Dictionary = {}
var loading_item: bool = false
var unsaved_recipe: bool = false
var resource_loader: FileDialog = null
var no_resource_panel: PanelContainer = null

@onready var components: Node = $Components
@onready var item_file_dialog: FileDialog = $Components/ItemFileDialog
@onready var item_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/ItemTree

@onready var item_name_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/NameContainer/ItemNameLnEdt
@onready var sprite_path_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/SpriteContainer/PanelContainer/HBoxContainer/SpritePathLnEdt
@onready var search_item_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/BarPanelContainer/ItemContainer/SearchItemLnEdt
@onready var search_currency_ln_edit: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/VBoxContainer/PanelContainer/HBoxContainer/CurrencySearchLnEdit
@onready var search_data_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CustomDataSearchLine
@onready var search_station_ln_edt: LineEdit = $MainContainer/RecipesContainer/UpperTreeContainer/StationsTreeCont/HBoxContainer2/VBoxContainer/PanelContainer/HBoxContainer/SearchStationLnEdt

@onready var item_type_opt_btn: OptionButton = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/TypeContainer/ItemTypeOptBtn
@onready var item_subtype_opt_btn: OptionButton = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/SubtypeContainer/ItemSubtypeOptBtn

@onready var item_lvl_spn_btn: SpinBox = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/ValuesContainer/HBoxContainer/ItemLvlSpnBtn
@onready var item_value_spn_bx: SpinBox = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/ValuesContainer/HBoxContainer2/ItemValueSpnBx
@onready var output_recipe_spin_box: SpinBox = $MainContainer/RecipesContainer/LowerTreeContainer/OutputTreeContainer/HBoxContainer7/OutputRecipeSpinBox
@onready var input_recipe_spin_box: SpinBox = $MainContainer/RecipesContainer/LowerTreeContainer/InputTreeContainer/HBoxContainer7/InputRecipeSpinBox

@onready var materials_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/TreesContainer/MaterialsContainer/MaterialsTree
@onready var item_flag_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/TreesContainer/FlagsCotnainer/ItemFlagTree
@onready var custom_data_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CustomDataTree
@onready var stations_tree: Tree = $MainContainer/RecipesContainer/UpperTreeContainer/StationsTreeCont/HBoxContainer2/VBoxContainer/StationsTree
@onready var input_recipe_tree: Tree = $MainContainer/RecipesContainer/LowerTreeContainer/InputTreeContainer/VBoxContainer/InputRecipeTree
@onready var output_recipe_tree: Tree = $MainContainer/RecipesContainer/LowerTreeContainer/OutputTreeContainer/VBoxContainer/OutputRecipeTree
@onready var currencies_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/VBoxContainer/CurrenciesTree

@onready var create_currency_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/VBoxContainer/PanelContainer/HBoxContainer/CreateCurrencyBtn
@onready var add_int_button: Button = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddIntButton
@onready var add_float_button: Button = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddFloatButton
@onready var add_bool_button: Button = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddBoolButton
@onready var add_string_button: Button = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddStringButton
@onready var add_station_btn: Button = $MainContainer/RecipesContainer/UpperTreeContainer/StationsTreeCont/HBoxContainer2/VBoxContainer/PanelContainer/HBoxContainer/AddStationBtn
@onready var create_item_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/BarPanelContainer/ItemContainer/CreateItemBtn
@onready var import_item_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/BarPanelContainer/ItemContainer/ImportItemBtn

@onready var recipe_label: Label = $MainContainer/RecipesContainer/HBoxContainer/RecipeLabel

@onready var main_container: HBoxContainer = $MainContainer

# Consider freeing from memory as once hidden it isn't used again.
#@onready var no_resource_panel: PanelContainer = $NoResourcePanel
#@onready var create_db_button: Button = $NoResourcePanel/CenterContainer/InfoContainer/ButtonContainer2/CreateDBButton
#@onready var load_db_button: Button = $NoResourcePanel/CenterContainer/InfoContainer/ButtonContainer2/LoadDBButton


func _ready() -> void:
	var res_path: String = ProjectSettings.get_setting(NFItemsRes.SETTINGS_PATH, "")
	
	if not res_path.is_empty() and ResourceLoader.exists(res_path):
		var res_preload: Resource = load(res_path)
		if res_preload is NFItemsRes:
			_items_resource = res_preload
	
	item_tree.item_id_pressed.connect(on_item_id_pressed)
	add_int_button.pressed.connect(on_add_variable_button_pressed.bind(0))
	add_float_button.pressed.connect(on_add_variable_button_pressed.bind(0.0))
	add_bool_button.pressed.connect(on_add_variable_button_pressed.bind(false))
	add_string_button.pressed.connect(on_add_variable_button_pressed.bind(""))
	stations_tree.recipe_selected.connect(on_recipe_selected)
	input_recipe_spin_box.value_changed.connect(change_recipe_size.bind(input_recipe_tree))
	output_recipe_spin_box.value_changed.connect(change_recipe_size.bind(output_recipe_tree))
	stations_tree.station_deleted.connect(on_station_deleted)
	stations_tree.recipe_deleted.connect(on_recipe_deleted)
	add_station_btn.pressed.connect(on_add_new_station_pressed)
	stations_tree.recipe_id_changed.connect(on_recipe_id_changed)
	stations_tree.station_id_changed.connect(on_station_id_changed)
	item_file_dialog.file_selected.connect(on_item_file_selected)
	create_currency_btn.pressed.connect(on_create_currency_pressed)
	create_item_btn.pressed.connect(on_add_item_pressed)
	import_item_btn.pressed.connect(on_import_item_pressed)
	stations_tree.recipe_changed.connect(on_recipe_changed)
	input_recipe_tree.recipe_changed.connect(on_recipe_changed)
	output_recipe_tree.recipe_changed.connect(on_recipe_changed)
	search_item_ln_edt.text_changed.connect(on_search_item.bind(item_tree))
	search_data_ln_edt.text_changed.connect(on_search_item.bind(custom_data_tree))
	search_currency_ln_edit.text_changed.connect(on_search_item.bind(currencies_tree))
	search_station_ln_edt.text_changed.connect(on_search_item.bind(stations_tree))
	
	if _items_resource != null:
		load_items()
		load_materials()
		load_flags()
		load_types()
		load_recipes()
		load_currencies()
		main_container.visible = true
	else:
		main_container.visible = false
		no_resource_panel = preload("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		add_child(no_resource_panel)
		no_resource_panel.set_resource_type("NFItemsRes", "Depot", "Items")
		no_resource_panel.create_resource_pressed.connect(on_create_resource_pressed)
		no_resource_panel.load_resource_pressed.connect(on_load_resource_pressed)


func on_search_item(search_str: String, search_node: Tree) -> void:
	search_node.search_item(search_str)


func on_recipe_changed(_dummy_var: Variant = null) -> void:
	if not unsaved_recipe:
		unsaved_recipe = true


func load_currencies() -> void:
	currencies_tree.clear_currencies()
	for currency in _items_resource.get_currencies():
		currencies_tree.create_currency(
				currency,
				_items_resource.get_currency_value(currency),
				_items_resource.get_currency_name(currency))


func on_add_item_pressed() -> void:
	item_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	item_file_dialog.show()


func on_import_item_pressed() -> void:
	item_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	item_file_dialog.show()


func on_resource_selected(resource_path: String) -> void:
	if resource_loader.file_mode == FileDialog.FileMode.FILE_MODE_SAVE_FILE:
		_items_resource = NFItemsRes.new()
		ProjectSettings.set_setting(NFItemsRes.SETTINGS_PATH, resource_path)
		ProjectSettings.save()
		_items_resource.save()
	else:
		var res_preload: Resource = load(resource_path)
		if res_preload is NFItemsRes:
			_items_resource = res_preload
			ProjectSettings.set_setting(NFItemsRes.SETTINGS_PATH, resource_path)
			ProjectSettings.save()
		else:
			printerr("[DEPOT] Resource selected ins't NFItemsRes")
	
	if _items_resource != null:
		resource_loader.queue_free()
		main_container.visible = true
		no_resource_panel.visible = false
		no_resource_panel.queue_free()
		load_items()
		load_materials()
		load_flags()
		load_types()
		load_recipes()
		load_currencies()


func on_create_resource_pressed() -> void:
	if resource_loader == null:
		resource_loader = FileDialog.new()
		resource_loader.add_filter("*.tres", "Resources")
		resource_loader.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
		resource_loader.size = Vector2i(500, 350)
		resource_loader.file_selected.connect(on_resource_selected)
		components.add_child(resource_loader)
	resource_loader.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	resource_loader.show()


func on_load_resource_pressed() -> void:
	if resource_loader == null:
		resource_loader = FileDialog.new()
		resource_loader.add_filter("*.tres", "Resources")
		resource_loader.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
		resource_loader.size = Vector2i(500, 350)
		resource_loader.file_selected.connect(on_resource_selected)
		components.add_child(resource_loader)
	resource_loader.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	resource_loader.show()


func on_create_currency_pressed() -> void:
	currencies_tree.create_currency("new_currency")


func on_add_new_station_pressed() -> void:
	stations_tree.create_station("new_station", [])


func load_types() -> void:
	item_type_opt_btn.clear()
	for type in _items_resource.get_item_types():
		item_type_opt_btn.add_item(type)
	
	if 0 < item_type_opt_btn.item_count:
		item_type_opt_btn.select(0)
		on_type_selected(0)


func on_station_deleted(station_id: String) -> void:
	if recipe_memory.has(station_id):
		recipe_memory.erase(station_id)
	

func on_recipe_deleted(station_id: String, recipe_id: String) -> void:
	if recipe_memory.has(station_id) and recipe_memory[station_id].has(recipe_id):
		recipe_memory[station_id].erase(recipe_id)


func on_add_variable_button_pressed(variable_val: Variant) -> void:
	custom_data_tree.add_variable("custom_data", variable_val)


func on_type_selected(type_idx: int) -> void:
	var type_id: String = item_type_opt_btn.get_item_text(type_idx)
	item_subtype_opt_btn.clear()
	for subtype in _items_resource.get_item_subtypes(type_id):
		item_subtype_opt_btn.add_item(subtype)


func load_recipes() -> void:
	for station in _items_resource.get_crafting_stations():
		stations_tree.create_station(
				station,
				_items_resource.get_recipes_of(station))


func save_current_recipe() -> void:
	if not recipe_memory.has(_current_station):
				recipe_memory[_current_station] = {}
			
	recipe_memory[_current_station][_current_recipe] = {
			"input": input_recipe_tree.get_current_recipe(),
			"output": output_recipe_tree.get_current_recipe()}


func on_recipe_id_changed(from: String, to: String) -> void:
	if from == _current_recipe:
		_current_recipe = to
		recipe_label.text = _current_station + "/" + to


func on_station_id_changed(from: String, to: String) -> void:
	if from == _current_station:
		_current_station = to
		recipe_label.text = to + "/" + _current_recipe


func on_recipe_selected(station_id: String, recipe_id: String) -> void:
	if station_id == _current_station and recipe_id == _current_recipe:
		return
	
	if not _current_station.is_empty():
		if _current_station != station_id or recipe_id != _current_recipe:
			save_current_recipe()
	
	_current_station = station_id
	_current_recipe = recipe_id
	
	recipe_label.text = station_id + "/" + recipe_id
	
	if recipe_memory.has(station_id) and recipe_memory[station_id].has(recipe_id):
		var input_size: int = recipe_memory[station_id][recipe_id]["input"].size()
		var output_size: int = recipe_memory[station_id][recipe_id]["output"].size()
		
		input_recipe_spin_box.value = input_size
		output_recipe_spin_box.value = output_size
		
		for input_idx in range(input_size):
			input_recipe_tree.set_slot_recipe(
					input_idx, 
					recipe_memory[station_id][recipe_id]["input"][input_idx]["item"],
					recipe_memory[station_id][recipe_id]["input"][input_idx]["count"])
		for output_idx in range(output_size):
			output_recipe_tree.set_slot_recipe(
					output_idx, 
					recipe_memory[station_id][recipe_id]["output"][output_idx]["item"],
					recipe_memory[station_id][recipe_id]["output"][output_idx]["count"])
	elif _items_resource.has_recipe(station_id, recipe_id):
		var input_recipe: Array[Dictionary] = _items_resource.get_recipe_input(
				station_id,
				recipe_id)
		var output_recipe: Array[Dictionary] = _items_resource.get_recipe_output(
				station_id,
				recipe_id)
		
		var input_size: int = input_recipe.size()
		var output_size: int = output_recipe.size()
		
		input_recipe_spin_box.value = input_size
		output_recipe_spin_box.value = output_size
		
		for input_idx in range(input_size):
			input_recipe_tree.set_slot_recipe(
					input_idx, 
					input_recipe[input_idx]["item"],
					input_recipe[input_idx]["count"])
		for output_idx in range(output_size):
			output_recipe_tree.set_slot_recipe(
					output_idx, 
					output_recipe[output_idx]["item"],
					output_recipe[output_idx]["count"])
	else:
		input_recipe_spin_box.value = 0
		output_recipe_spin_box.value = 0


func change_recipe_size(new_size: float, target_tree: Tree) -> void:
	target_tree.set_slot_count(new_size)
	on_recipe_changed()


func current_item_to_memory() -> void:
	item_memory[_current_id] = {
		"item_name": item_name_ln_edt.text,
		"item_sprite": sprite_path_ln_edt.text,
		"item_type": item_type_opt_btn.get_item_text(item_type_opt_btn.selected),
		"item_level": item_lvl_spn_btn.value,
		"item_value": item_value_spn_bx.value,
		"item_materials": materials_tree.get_selected_materials(),
		"item_flags": item_flag_tree.get_flags(),
		"custom_data": custom_data_tree.get_custom_data()}


func load_item(item_path: String, item_id: String) -> bool:
	if item_path == _current_id:
		return true
	
	if not _current_id.is_empty():
		current_item_to_memory()
	
	if item_memory.has(item_path):
		item_name_ln_edt.text = item_memory[item_path]["item_name"]
		sprite_path_ln_edt.text = item_memory[item_path]["item_sprite"]
		select_type(item_memory[item_path]["item_type"])
		item_lvl_spn_btn.value = item_memory[item_path]["item_level"]
		item_value_spn_bx.value = item_memory[item_path]["item_value"]
		materials_tree.uncheck_materials()
		materials_tree.select_materials(item_memory[item_path]["item_materials"])
		item_flag_tree.reset_flags()
		item_flag_tree.set_flags(item_memory[item_path]["item_flags"])
		custom_data_tree.clear_variables()
		for c_data in item_memory[item_path]["custom_data"]:
			custom_data_tree.add_variable(
					c_data,
					item_memory[item_path]["custom_data"][c_data])
		return true
	elif not item_path.is_empty() and ResourceLoader.exists(item_path):
		var preload_resource: Resource = load(item_path)
		if preload_resource is ItemDefinition:
			item_name_ln_edt.text = preload_resource.item_name
			sprite_path_ln_edt.text = preload_resource.item_sprite
			select_type(preload_resource.item_type)
			item_lvl_spn_btn.value = preload_resource.item_level
			item_value_spn_bx.value = preload_resource.item_value
			materials_tree.uncheck_materials()
			materials_tree.select_materials(preload_resource.item_materials)
			item_flag_tree.reset_flags()
			item_flag_tree.set_flags(preload_resource.item_flags)
			custom_data_tree.clear_variables()
			for c_data in preload_resource.get_custom_data_keys():
				custom_data_tree.add_variable(
						c_data,
						preload_resource.get_custom_data(c_data))
			return true
		else:
			printerr("[DEPOT] Item with path " + item_path + " is not ItemDefinition.")
			clear_fields()
	return false


func select_type(type_id: String) -> void:
	if type_id.is_empty():
		item_type_opt_btn.select(item_type_opt_btn.item_count - 1)
	else:
		for idx in range(item_type_opt_btn.item_count):
			if item_type_opt_btn.get_item_text(idx) == type_id:
				item_type_opt_btn.select(idx)
				break


func load_items() -> void:
	item_tree.clear_items()
	for item in _items_resource.get_items():
		item_tree.add_item(item, _items_resource.get_item_path(item))


func load_materials() -> void:
	materials_tree.clear_materials()
	for mat in _items_resource.get_materials():
		materials_tree.add_material(mat)


func load_flags() -> void:
	var flag_str: Array = _items_resource.ItemFlags.keys()
	
	item_flag_tree.clear_flags()
	
	for flag in _items_resource.ItemFlags.values():
		item_flag_tree.add_flag(flag, Strings.capitalize(flag_str[flag]))


func clear_fields() -> void:
	pass


func on_item_id_pressed(item_id: String, item_path: String) -> void:
	if loading_item:
		return
	
	loading_item = true
	
	if load_item(item_path, item_id):
		if not item_tree.is_selected(item_path):
			item_tree.select_item(item_path)
	else:
		item_tree.deselect_all()
	
	loading_item = false


func on_item_deleted(item_id: String, item_path: String) -> void:
	if item_memory.has(item_path):
		item_memory.erase(item_path)
	
	if _current_id == item_path:
		clear_fields()


func on_item_file_selected(file_path: String) -> void:
	if item_file_dialog.file_mode == FileDialog.FileMode.FILE_MODE_SAVE_FILE: # Creating an existing file
		var new_item := ItemDefinition.new()
		new_item.item_id = file_path.get_file().get_basename()
		ResourceSaver.save(new_item, file_path)
		item_tree.add_item(new_item.item_id, file_path)
		on_item_id_pressed(new_item.item_id, file_path)
	else: # Adding an existing file
		var res_preload: Resource = load(file_path)
		if res_preload is ItemDefinition:
			if item_tree.has_item(res_preload.item_id):
				push_warning("[DEPOT] An item with id " + res_preload.item_id + " already exists. It'll be renamed.")
			item_tree.add_item(res_preload.item_id, file_path)
		else:
			push_error("[DEPOT] Selected file isn't an ItemDefinition")


func save_currencies() -> void:
	var currency_dict: Dictionary = currencies_tree.get_currencies()
	
	_items_resource.clear_currencies()
	
	for currency_id in currency_dict:
		_items_resource.create_currency(
				currency_id,
				currency_dict[currency_id]["name"],
				currency_dict[currency_id]["value"])


func save_items() -> void:
	var items: Array[Dictionary] = item_tree.get_items_serialized()
	
	_items_resource.clear_items()
	
	current_item_to_memory()
	
	for item_dict in items:
		if item_dict["file"].is_empty():
			printerr("[DEPOT] Item with id {0} has empty path. Skipping".format([item_dict["id"]]))
			continue
		
		var new_item := ItemDefinition.new()
		
		# It means we changed it and need to update it
		if item_memory.has(item_dict["file"]):
			new_item.item_id = item_dict["id"]
			new_item.item_name = item_memory["item_name"]
			new_item.item_sprite = item_memory["item_sprite"]
			new_item.item_type = item_memory["item_type"]
			new_item.item_materials = item_memory["item_materials"]
			new_item.item_flags = item_memory["item_flags"]
			new_item.item_level = item_memory["item_level"]
			new_item.item_value = item_memory["item_value"]
			new_item.custom_data = item_memory["custom_data"]
			ResourceSaver.save(new_item, item_dict["file"])
		
		_items_resource.create_item(item_dict["id"])
		_items_resource.set_item_path(item_dict["id"], item_dict["file"])
	item_memory.clear()


func save_recipes() -> void:
	if not _current_station.is_empty():
		save_current_recipe()
	
	var new_recipes: Dictionary = {}
	
	# We grab all the existing recipes and stations
	
	var stations_recipes: Dictionary = stations_tree.get_stations_and_recipes()
	
	for station in stations_recipes:
		if not recipe_memory.has(station):
			recipe_memory[station] = {}
		for recipe in stations_recipes[station]:
			if not recipe_memory[station].has(recipe):
				if _items_resource.has_recipe(station, recipe):
					recipe_memory[station][recipe] = {
						"input": _items_resource.get_recipe_input(station, recipe),
						"output": _items_resource.get_recipe_output(station, recipe)}
				else:
					recipe_memory[station][recipe] = {
						"input": [],
						"output": []}
	
	_items_resource.clear_recipes()
	
	for station_id in recipe_memory:
		_items_resource.create_crafting_station(station_id, stations_recipes[station_id]["name"])
		for recipe_id in recipe_memory[station_id]:
			_items_resource.set_station_recipe(
					station_id,
					recipe_id,
					recipe_memory[station_id][recipe_id]["input"],
					recipe_memory[station_id][recipe_id]["output"])
	
	recipe_memory.clear()


func on_save() -> void:
	save_items()
	save_recipes()
	save_currencies()
	_items_resource.save()
