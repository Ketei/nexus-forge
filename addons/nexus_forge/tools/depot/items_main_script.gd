@tool
extends Control


const ICON_BOOL = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const ICON_FLOAT = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const ICON_INT = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const ICON_STRING = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
const ICON_ADD_BOOL = preload("res://addons/nexus_forge/common_icons/variables/add_bool.svg")
const ICON_ADD_FLOAT = preload("res://addons/nexus_forge/common_icons/variables/add_float.svg")
const ICON_ADD_INT = preload("res://addons/nexus_forge/common_icons/variables/add_int.svg")
const ICON_ADD_STRING = preload("res://addons/nexus_forge/common_icons/variables/add_string.svg")
const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const RECIPE_INPUT_ICON = preload("res://addons/nexus_forge/common_icons/recipe_input_icon.svg")
const RECIPE_OUTPUT_ICON = preload("res://addons/nexus_forge/common_icons/recipe_output_icon.svg")

const ITEM_DATA_RANGE: int = 9999
const ITEM_DATA_FLOAT_STEP: float = 0.01
const CRAFTING_MAX_ITEM: int = 999

var current_rarity: int = -1
var current_currency: String = ""
var current_item_category: String = ""
var current_item: String = ""
var current_station: String = ""
var current_recipe: String = ""
var items_resource: NFItemsRes = null
var _switching: bool = false
var _unsaved: bool = false
var _no_resource_panel: Control = null

@onready var main_container: HBoxContainer = $MainContainer

@onready var rarities_opt_btn: OptionButton = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/RarityContainer/RaritiesOptBtn
@onready var depot_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/DepotTree

@onready var item_data_container: VBoxContainer = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer
@onready var currency_data_container: VBoxContainer = $MainContainer/ItemsContainer/DataContainer/CurrencyDataContainer
@onready var item_description: TextEdit = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/DescContainer/ItemDescription
@onready var stack_size_spn_bx: SpinBox = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/StackContainer/StackSizeSpnBx
@onready var item_name_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/NameContainer/ItemNameLnEdt

@onready var currency_name_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/CurrencyDataContainer/NameContainer/CurrencyNameLnEdt
#@onready var currency_desc_text_edit: TextEdit = $MainContainer/ItemsContainer/DataContainer/CurrencyDataContainer/DescContainer/CurrencyDescTextEdit
@onready var currency_val_spn_bx: SpinBox = $MainContainer/ItemsContainer/DataContainer/CurrencyDataContainer/ValueContainer/CurrencyValSpnBx

@onready var item_cat_name_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/CategoryDataContainer/CatDescContainer/ItemCatNameLnEdt
@onready var item_cat_txt_edt: TextEdit = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/CategoryDataContainer/CatDescContainer/ItemCatTxtEdt
@onready var items_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/CategoryDataContainer/CategoryItemsContainer/ItemsTree

@onready var category_data_container: VBoxContainer = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/CategoryDataContainer
#@onready var item_data_container: VBoxContainer = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer
@onready var items_container: HBoxContainer = $MainContainer/ItemsContainer/DataContainer/ItemsContainer
@onready var category_id_label: Label = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/CategoryDataContainer/CatDescContainer/CategoryIDLabel
@onready var create_item_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/CategoryDataContainer/CategoryItemsContainer/ItemHeaderContainer/CreateItemBtn
@onready var item_id_label: Label = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/ItemIDLabel

@onready var item_val_spn_bx: SpinBox = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/ValueContainer/ItemValSpnBx
#@onready var icon_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/IconContainer/IconLnEdt
#@onready var browse_icon_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/IconContainer/BrowseIconBtn
@onready var add_item_int_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddIntBtn
@onready var add_item_float_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddFloatBtn
@onready var add_item_bool_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddBoolBtn
@onready var add_item_str_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddStrBtn
@onready var item_data_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemsContainer/ItemMargin/ItemDataContainer/CustomDataContainer/ItemDataTree

@onready var rarity_name_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/RarityContainer/RarityNameContainer/RarityNameLnEdt
@onready var rarity_col_pk_btn: ColorPickerButton = $MainContainer/ItemsContainer/DataContainer/RarityContainer/RarityColContainer/RarityColPkBtn
#@onready var rarity_icon_path_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/RarityContainer/RarityIconPathContainer/IconPathLnEdt
#@onready var browse_rarity_icon_btn: Button = $MainContainer/ItemsContainer/DataContainer/RarityContainer/RarityIconPathContainer/BrowseRarityIconBtn
@onready var add_rarity_int_btn: Button = $MainContainer/ItemsContainer/DataContainer/RarityContainer/CustomDataContainer/DataHeader/ButtonContainer/AddRarityIntBtn
@onready var add_rarity_float_btn: Button = $MainContainer/ItemsContainer/DataContainer/RarityContainer/CustomDataContainer/DataHeader/ButtonContainer/AddRarityFloatBtn
@onready var add_rarity_bool_btn: Button = $MainContainer/ItemsContainer/DataContainer/RarityContainer/CustomDataContainer/DataHeader/ButtonContainer/AddRarityBoolBtn
@onready var add_rarity_str_btn: Button = $MainContainer/ItemsContainer/DataContainer/RarityContainer/CustomDataContainer/DataHeader/ButtonContainer/AddRarityStrBtn
@onready var rarity_data_tree: Tree = $MainContainer/ItemsContainer/DataContainer/RarityContainer/CustomDataContainer/RarityDataTree
@onready var rarity_container: VBoxContainer = $MainContainer/ItemsContainer/DataContainer/RarityContainer

# --- Currency ---
@onready var add_crr_int_btn: Button = $MainContainer/ItemsContainer/DataContainer/CurrencyDataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCrrIntBtn
@onready var add_crr_float_btn: Button = $MainContainer/ItemsContainer/DataContainer/CurrencyDataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCrrFloatBtn
@onready var add_crr_bool_btn: Button = $MainContainer/ItemsContainer/DataContainer/CurrencyDataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCrrBoolBtn
@onready var add_crr_str_btn: Button = $MainContainer/ItemsContainer/DataContainer/CurrencyDataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCrrStrBtn
@onready var currency_data_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CurrencyDataContainer/CustomDataContainer/CurrencyDataTree

# --- Crafting ---
@onready var crafting_container: HBoxContainer = $MainContainer/ItemsContainer/DataContainer/CraftingContainer
@onready var search_rcp_item_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/CraftingMargin/CraftingContainer/AllItemContainer/HeaderContainer/SearchRcpItemLnEdt
@onready var refresh_btn: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/CraftingMargin/CraftingContainer/AllItemContainer/HeaderContainer/RefreshBtn
@onready var all_item_craft_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/CraftingMargin/CraftingContainer/AllItemContainer/AllItemCraftTree
@onready var in_item_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/CraftingMargin/CraftingContainer/PutsContainer/InContainer/InItemTree
@onready var out_item_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/CraftingMargin/CraftingContainer/PutsContainer/OutContainer/OutItemTree
@onready var add_station_int: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/ButtonContainer/AddStationInt
@onready var add_station_float: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/ButtonContainer/AddStationFloat
@onready var add_station_bool: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/ButtonContainer/AddStationBool
@onready var add_station_string: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/ButtonContainer/AddStationString
@onready var station_data_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/StationDataTree
@onready var create_recipe_btn: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/HeaderContainer/CreateRecipeBtn
@onready var station_recipes_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/StationRecipesTree
@onready var recipe_container: VBoxContainer = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer
@onready var station_id_label: Label = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/StationIDLabel
@onready var recipe_id_label: Label = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/HeaderContainer/RecipeIDLabel
@onready var recipe_tab_bar: TabBar = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/HeaderContainer/RecipeTabBar
@onready var recipe_name_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/DataMargin/RecipeData/NameContainer/RecipeNameLnEdt
@onready var add_recipe_data_int_btn: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/DataMargin/RecipeData/DataContainer/HeaderContainer/ButtonContainer/AddRecipeDataIntBtn
@onready var add_recipe_data_flt_btn: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/DataMargin/RecipeData/DataContainer/HeaderContainer/ButtonContainer/AddRecipeDataFltBtn
@onready var add_recipe_data_bool_btn: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/DataMargin/RecipeData/DataContainer/HeaderContainer/ButtonContainer/AddRecipeDataBoolBtn
@onready var add_recipe_data_str_btn: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/DataMargin/RecipeData/DataContainer/HeaderContainer/ButtonContainer/AddRecipeDataStrBtn
@onready var recipe_data_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/DataMargin/RecipeData/DataContainer/RecipeDataTree
@onready var station_name_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/StationNameLnEdt

@onready var search_depot_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/SearchDepotLnEdt


func _ready() -> void:
	items_tree.create_item()
	item_data_tree.create_item()
	rarity_data_tree.create_item()
	currency_data_tree.create_item()
	all_item_craft_tree.create_item()
	in_item_tree.create_item()
	out_item_tree.create_item()
	station_data_tree.create_item()
	station_recipes_tree.create_item()
	recipe_data_tree.create_item()
	
	in_item_tree.set_column_expand(1, false)
	in_item_tree.set_column_expand(2, false)
	in_item_tree.set_column_custom_minimum_width(1, 50)
	in_item_tree.set_column_custom_minimum_width(2, 250)
	
	out_item_tree.set_column_expand(1, false)
	out_item_tree.set_column_expand(2, false)
	out_item_tree.set_column_custom_minimum_width(1, 50)
	out_item_tree.set_column_custom_minimum_width(2, 250)
	
	rarities_opt_btn.clear()
	
	if items_resource != null:
		main_container.visible = true
		for rarity_idx in range(items_resource.get_rarity_count()):
			rarities_opt_btn.add_item(items_resource.get_rarity_name(rarity_idx))
			depot_tree.create_rarity(items_resource.get_rarity_name(rarity_idx))
	else:
		main_container.visible = false
		_no_resource_panel = load("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		add_child(_no_resource_panel)
		_no_resource_panel.load_resource_pressed.connect(_on_load_resource_pressed)
		_no_resource_panel.create_resource_pressed.connect(_on_create_resource_pressed)
		_no_resource_panel.set_resource_type("NFItemsRes", "Items", "Items")
	
	recipe_tab_bar.current_tab = 0
	_on_recipe_tab_bar_tab_changed(0)
	
	depot_tree.rarity_created.connect(_on_rarity_created)
	depot_tree.rarity_reindexed.connect(_on_rarity_reindexed)
	depot_tree.rarity_deleted.connect(_on_rarity_deleted)
	depot_tree.rarity_renamed.connect(_on_rarity_renamed)
	currency_val_spn_bx.value_changed.connect(_on_currency_value_changed)
	depot_tree.currency_selected.connect(_on_currency_selected)
	depot_tree.currency_created.connect(_on_currency_created)
	depot_tree.currency_id_changed.connect(_on_currency_id_changed)
	depot_tree.item_category_selected.connect(_on_item_category_selected)
	depot_tree.item_category_renamed.connect(_on_item_category_renamed)
	depot_tree.rarity_selected.connect(_on_rarity_selected)
	depot_tree.item_category_created.connect(_on_item_category_created)
	depot_tree.item_category_deleted.connect(_on_item_category_deleted)
	depot_tree.currency_deleted.connect(_on_currency_deleted)
	depot_tree.crafting_station_selected.connect(_on_crafting_station_selected)
	depot_tree.crafting_station_changed.connect(_on_crafting_station_changed)
	depot_tree.crafting_station_created.connect(_on_crafting_station_created)
	depot_tree.crafting_station_deleted.connect(_on_crafting_station_deleted)
	
	items_tree.item_edited.connect(_on_item_changed)
	items_tree.item_selected.connect(_on_item_selected)
	items_tree.button_clicked.connect(_on_item_tree_button_clicked)
	
	in_item_tree.button_clicked.connect(on_put_recipe_button_clicked)
	out_item_tree.button_clicked.connect(on_put_recipe_button_clicked)
	
	in_item_tree.item_edited.connect(_on_put_item_edited.bind(in_item_tree))
	out_item_tree.item_edited.connect(_on_put_item_edited.bind(out_item_tree))
	
	all_item_craft_tree.button_clicked.connect(_on_craft_all_itm_button_clicked)
	
	refresh_btn.pressed.connect(_on_item_refresh_btn_pressed)
	
	add_item_int_btn.pressed.connect(_on_add_item_data_pressed.bind("new_int", 0))
	add_item_float_btn.pressed.connect(_on_add_item_data_pressed.bind("new_float", 0.0))
	add_item_bool_btn.pressed.connect(_on_add_item_data_pressed.bind("new_bool", false))
	add_item_str_btn.pressed.connect(_on_add_item_data_pressed.bind("new_string", ""))
	
	rarity_data_tree.item_edited.connect(_on_rarity_data_edited)
	
	currency_data_tree.item_edited.connect(_on_currency_data_edited)
	
	add_rarity_int_btn.pressed.connect(_on_add_rarity_data_btn_pressed.bind("new_int", 0))
	add_rarity_float_btn.pressed.connect(_on_add_rarity_data_btn_pressed.bind("new_float", 0.0))
	add_rarity_bool_btn.pressed.connect(_on_add_rarity_data_btn_pressed.bind("new_bool", false))
	add_rarity_str_btn.pressed.connect(_on_add_rarity_data_btn_pressed.bind("new_string", ""))
	
	add_crr_int_btn.pressed.connect(_on_add_currency_data_pressed.bind("new_int", 0))
	add_crr_float_btn.pressed.connect(_on_add_currency_data_pressed.bind("new_float", 0.0))
	add_crr_bool_btn.pressed.connect(_on_add_currency_data_pressed.bind("new_bool", false))
	add_crr_str_btn.pressed.connect(_on_add_currency_data_pressed.bind("new_string", ""))
	
	add_station_int.pressed.connect(_on_add_station_data_pressed.bind("new_int", 0))
	add_station_float.pressed.connect(_on_add_station_data_pressed.bind("new_float", 0.0))
	add_station_bool.pressed.connect(_on_add_station_data_pressed.bind("new_bool", false))
	add_station_string.pressed.connect(_on_add_station_data_pressed.bind("new_string", ""))
	
	rarity_name_ln_edt.focus_exited.connect(_on_rarity_name_focus_lost)
	rarity_name_ln_edt.text_submitted.connect(_on_rarity_name_text_submitted)
	rarity_name_ln_edt.text_changed.connect(something_changed)
	rarity_col_pk_btn.color_changed.connect(something_changed)
	
	add_recipe_data_int_btn.pressed.connect(_on_add_recipe_data_pressed.bind("new_int", 0))
	add_recipe_data_flt_btn.pressed.connect(_on_add_recipe_data_pressed.bind("new_float", 0.0))
	add_recipe_data_bool_btn.pressed.connect(_on_add_recipe_data_pressed.bind("new_bool", false))
	add_recipe_data_str_btn.pressed.connect(_on_add_recipe_data_pressed.bind("new_string", ""))
	
	recipe_data_tree.item_edited.connect(_on_recipe_item_edited)
	
	create_item_btn.pressed.connect(_on_create_item_button_pressed)
	
	create_recipe_btn.pressed.connect(_on_create_recipe_btn_pressed)
	
	station_recipes_tree.item_edited.connect(_on_recipe_tree_item_edited)
	station_recipes_tree.item_selected.connect(_on_crafting_recipe_selected)
	station_recipes_tree.button_clicked.connect(_on_station_recipes_button_clicked)
	
	search_rcp_item_ln_edt.text_submitted.connect(_on_search_recipe_text_submitted)
	
	recipe_tab_bar.tab_changed.connect(_on_recipe_tab_bar_tab_changed)
	
	search_depot_ln_edt.text_changed.connect(_on_search_depot_text_changed)
	
	set_data_visible(-1)
	recipe_container.visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEventKey and event.is_action_pressed(&"ui_focus_next"):
		if item_description.has_focus():
			if event.shift_pressed:
				item_name_ln_edt.grab_focus()
			else:
				stack_size_spn_bx.get_line_edit().grab_focus()
			get_viewport().set_input_as_handled()
		#elif currency_desc_text_edit.has_focus():
			#if event.shift_pressed:
				#currency_name_ln_edt.grab_focus()
			#else:
				#currency_val_spn_bx.get_line_edit().grab_focus()
			#get_viewport().set_input_as_handled()
		elif item_cat_txt_edt.has_focus():
			if event.shift_pressed:
				item_cat_name_ln_edt.grab_focus()
			else:
				create_item_btn.grab_focus()
			get_viewport().set_input_as_handled()


func _on_add_item_data_pressed(data_name: String, data: Variant) -> void:
	item_data_tree.add_data(data_name, data)
	something_changed()


func _on_add_currency_data_pressed(data_name: String, data: Variant) -> void:
	currency_data_tree.add_data(data_name, data)
	something_changed()


func _on_add_station_data_pressed(data_name: String, data: Variant) -> void:
	station_data_tree.add_data(data_name, data)
	something_changed()


func _on_add_recipe_data_pressed(data_name: String, data: Variant) -> void:
	recipe_data_tree.add_data(data_name, data)
	something_changed()


func _on_search_depot_text_changed(new_text: String) -> void:
	depot_tree.search_item(new_text)


func _on_recipe_tab_bar_tab_changed(tab: int) -> void:
	$MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/DataMargin.visible = tab == 0
	$MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/MainContainer/CraftingMargin.visible = tab == 1


func _on_recipe_item_edited() -> void:
	if recipe_data_tree.get_edited_column() != 0:
		return
	
	var edited: TreeItem = recipe_data_tree.get_edited()
	var new_id: String = get_data_valid_id(
			recipe_data_tree.get_root(),
			edited.get_text(0),
			edited)
	
	edited.set_text(0, new_id)
	edited.get_metadata(0)["id"] = new_id
	something_changed()


func _on_crafting_station_created(station_id: String) -> void:
	items_resource.create_crafting_station(station_id)
	something_changed()


func _on_crafting_station_changed(from: String, to: String) -> void:
	items_resource._crafting[to] = items_resource._crafting[from]
	items_resource._crafting.erase(from)
	
	if current_station == from:
		current_station = to
		station_id_label.text = Strings.title_case(to.replace("_", " "))
	something_changed()


func _on_crafting_station_deleted(station_id: String) -> void:
	items_resource.erase_crafting_station(station_id)
	if current_station == station_id:
		current_station = ""
		current_recipe = ""
		set_data_visible(-1)
	something_changed()


func _on_crafting_station_selected(station_id: String) -> void:
	if not crafting_container.visible:
		set_data_visible(3)
	
	if current_station == station_id:
		return
	
	if not current_station.is_empty():
		save_crafting_station_data()
	
	if not current_recipe.is_empty():
		save_current_recipe()
	
	current_station = station_id
	station_id_label.text = Strings.title_case(station_id.replace("_", " "))
	
	current_recipe = ""
	recipe_tab_bar.current_tab = 0
	_on_recipe_tab_bar_tab_changed(0)
	recipe_container.visible = false
	
	station_name_ln_edt.text = items_resource.get_crafting_station_name(station_id)
	clear_station_recipes()
	clear_station_data()
	
	for station_recipe in items_resource.get_crafting_station_recipe_keys(station_id):
		add_recipe(station_recipe)
	
	for data_id in items_resource.get_crafting_station_data_keys(station_id):
		add_item_data(
			station_data_tree.get_root(),
			data_id,
			items_resource.get_crafting_station_data(station_id, data_id))



func _on_create_resource_pressed() -> void:
	var res_loader := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").new()
	res_loader.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	res_loader.title = "Create Items"
	res_loader.ok_button_text = "Save"
	add_child(res_loader)
	res_loader.show()
	
	var result = await res_loader.dialog_finished
	
	if result[0]:
		items_resource = NFItemsRes.new()
		ResourceSaver.save(items_resource, result[1])
		ProjectSettings.set_setting(NFTalentsRes.SETTINGS_PATH, result[1])
		ProjectSettings.save()
		main_container.visible = true
		_no_resource_panel.queue_free()
		_no_resource_panel.visible = false
	
	res_loader.queue_free()


func _on_load_resource_pressed() -> void:
	var res_loader := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").new()
	res_loader.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	res_loader.title = "Open Items"
	res_loader.ok_button_text = "Load"
	add_child(res_loader)
	res_loader.show()
	
	var result = await res_loader.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is NFTalentsRes:
			items_resource = res_pre
			ProjectSettings.set_setting(NFTalentsRes.SETTINGS_PATH, result[1])
			ProjectSettings.save()
			main_container.visible = true
			_no_resource_panel.visible = false
			_no_resource_panel.queue_free()
	
	res_loader.queue_free()




func save_current_recipe() -> void:
	var recipe_data: Dictionary = {}
	var input_items: Array[Dictionary] = []
	var output_items: Array[Dictionary] = []
	
	for data in recipe_data_tree.get_root().get_children():
		var variant_data: Variant = null
		match data.get_cell_mode(1):
			TreeItem.CELL_MODE_RANGE:
				if data.get_icon(0) == ICON_INT:
					variant_data = int(data.get_range(1))
				else:
					variant_data = float(data.get_range(1))
			TreeItem.CELL_MODE_CHECK:
				variant_data = data.is_checked(1)
			TreeItem.CELL_MODE_STRING:
				variant_data = data.get_text(1)
		recipe_data[data.get_text(0)] = variant_data 
	
	for in_item in in_item_tree.get_root().get_children():
		var item_data: Dictionary = {}
		for data_item in in_item.get_children():
			var variant_data: Variant = null
			match data_item.get_cell_mode(2):
				TreeItem.CELL_MODE_RANGE:
					if data_item.get_icon(0) == ICON_INT:
						variant_data = int(data_item.get_range(2))
					else:
						variant_data = float(data_item.get_range(2))
				TreeItem.CELL_MODE_CHECK:
					variant_data = data_item.is_checked(2)
				TreeItem.CELL_MODE_STRING:
					variant_data = data_item.get_text(2)
			item_data[data_item.get_text(0)] = {"value": variant_data, "operator": range_to_operator(data_item.get_range(1))}
		
		input_items.append({
			"item": in_item.get_text(0),
			"amount": int(in_item.get_range(2)),
			"data": item_data})
	
	for out_item in out_item_tree.get_root().get_children():
		var item_data: Dictionary = {}
		
		for data_item in out_item.get_children():
			var variant_data: Variant = null
			match data_item.get_cell_mode(2):
				TreeItem.CELL_MODE_RANGE:
					if data_item.get_icon(0) == ICON_INT:
						variant_data = int(data_item.get_range(2))
					else:
						variant_data = float(data_item.get_range(2))
				TreeItem.CELL_MODE_CHECK:
					variant_data = data_item.is_checked(2)
				TreeItem.CELL_MODE_STRING:
					variant_data = data_item.get_text(2)
			item_data[data_item.get_text(0)] = {"value": variant_data, "operator": range_to_operator(data_item.get_range(1))}
		output_items.append({
			"item": out_item.get_text(0),
			"amount": int(out_item.get_range(2)),
			"data": item_data})
	
	items_resource.set_recipe_name(
			current_station,
			current_recipe,
			recipe_name_ln_edt.text.strip_edges())
	items_resource._crafting[current_station]["recipes"][current_recipe]["data"] = recipe_data
	items_resource._crafting[current_station]["recipes"][current_recipe]["input"] = input_items
	items_resource._crafting[current_station]["recipes"][current_recipe]["output"] = output_items


func _on_crafting_recipe_selected() -> void:
	var selected: TreeItem = station_recipes_tree.get_selected()
	var recipe_id: String = selected.get_text(0)
	
	if current_recipe == recipe_id:
		return
	
	if not current_recipe.is_empty():
		save_current_recipe()
	
	recipe_id_label.text = Strings.title_case(recipe_id.replace("_", " "))
	current_recipe = recipe_id
	
	clear_recipe_fields()
	
	recipe_name_ln_edt.text = items_resource.get_recipe_name(current_station, recipe_id)
	
	for data_id in items_resource.get_recipe_data_keys(current_station, recipe_id):
		add_item_data(
			recipe_data_tree.get_root(),
			data_id,
			items_resource.get_recipe_data(current_station, recipe_id, data_id))
	
	for input_dict in items_resource.get_recipe_input(current_station, recipe_id):
		add_input_recipe_item(
			input_dict["item"],
			input_dict["amount"],
			input_dict["data"])
	
	for output_dict in items_resource.get_recipe_output(current_station, recipe_id):
		add_output_recipe_item(
			output_dict["item"],
			output_dict["amount"],
			output_dict["data"])
	
	recipe_container.visible = true


func _on_search_recipe_text_submitted(text: String) -> void:
	var clean_text: String = text.strip_edges()
	for recipe_id in all_item_craft_tree.get_root().get_children():
		recipe_id.visible = clean_text.is_empty() or recipe_id.get_text(0).containsn(clean_text)


func add_recipe(recipe_id: String) -> void:
	var new_recipe: TreeItem = station_recipes_tree.get_root().create_child()
	new_recipe.set_text(0, recipe_id)
	new_recipe.set_metadata(0, {"id": recipe_id})
	new_recipe.set_editable(0, true)
	new_recipe.add_button(0, TRASH_BIN, 0, false, "Delete Recipe")


func _on_station_recipes_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			items_resource.erase_recipe(current_station, item.get_text(0))
			item.free()
			something_changed()


func _on_create_recipe_btn_pressed() -> void:
	var new_id: String = get_valid_id(
			station_recipes_tree.get_root(),
			0,
			"new_recipe")
	add_recipe(new_id)
	items_resource.create_recipe(current_station, new_id)
	something_changed()


func _on_recipe_tree_item_edited() -> void:
	var edited: TreeItem = station_recipes_tree.get_edited()
	var old_id: String = edited.get_metadata(0)["id"]
	var new_name: String = get_valid_id(
			station_recipes_tree.get_root(),
			0,
			edited.get_text(0),
			edited,
			"crafting_recipe")
	
	if old_id == current_recipe:
		current_recipe = new_name
		recipe_id_label.text = Strings.title_case(new_name.replace("_", " "))
	
	items_resource._crafting[current_station]["recipes"][new_name] = items_resource._crafting[current_station]["recipes"][old_id]
	items_resource._crafting[current_station]["recipes"].erase(old_id)
	
	edited.set_text(0, new_name)
	edited.get_metadata(0)["id"] = new_name
	something_changed()


func _on_item_refresh_btn_pressed() -> void:
	var items: TreeItem = all_item_craft_tree.get_root()
	
	for itm in items.get_children():
		itm.free()
	
	for cat_path in depot_tree.get_all_item_categories():
		for item_id in items_resource.get_category_item_keys(cat_path):
			var new_item: TreeItem = items.create_child()
			
			new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
			new_item.set_text(0, cat_path + "/" + item_id)
			new_item.add_button(0, RECIPE_INPUT_ICON, 0, false, "Add to Input")
			new_item.add_button(0, RECIPE_OUTPUT_ICON, 1, false, "Add to Output")


func something_changed(_arg: Variant = null) -> void:
	if not _unsaved:
		_unsaved = true


func add_input_recipe_item(item_id: String, item_count: int, data: Dictionary = {}) -> void:
	var new_craft_itm: TreeItem = in_item_tree.get_root().create_child()
	new_craft_itm.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_craft_itm.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	new_craft_itm.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	new_craft_itm.set_range_config(2, 1, CRAFTING_MAX_ITEM, 1)
	new_craft_itm.set_range(2, item_count)
	
	new_craft_itm.set_text(0, item_id)
	new_craft_itm.add_button(2, ICON_ADD_INT, 0, false, "Add Integer Data")
	new_craft_itm.add_button(2, ICON_ADD_FLOAT, 1, false, "Add Float Data")
	new_craft_itm.add_button(2, ICON_ADD_BOOL, 2, false, "Add Bool Data")
	new_craft_itm.add_button(2, ICON_ADD_STRING, 3, false, "Add String Data")
	new_craft_itm.add_button(2, TRASH_BIN, 4, false, "Delete Item")
	new_craft_itm.set_selectable(0, false)
	new_craft_itm.set_selectable(1, false)
	new_craft_itm.set_editable(1, true)
	new_craft_itm.set_editable(2, true)
	
	for data_key in data:
		add_recipe_item_data(new_craft_itm, data_key, data[data_key]["value"], data[data_key]["operator"])


func add_output_recipe_item(item_id: String, item_count: int, data: Dictionary = {}) -> void:
	var new_craft_itm: TreeItem = out_item_tree.get_root().create_child()
	new_craft_itm.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_craft_itm.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	new_craft_itm.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	new_craft_itm.set_range_config(2, 1, CRAFTING_MAX_ITEM, 1)
	new_craft_itm.set_range(2, item_count)
	
	new_craft_itm.set_text(0, item_id)
	new_craft_itm.add_button(2, ICON_ADD_INT, 0, false, "Add Integer Data")
	new_craft_itm.add_button(2, ICON_ADD_FLOAT, 1, false, "Add Float Data")
	new_craft_itm.add_button(2, ICON_ADD_BOOL, 2, false, "Add Bool Data")
	new_craft_itm.add_button(2, ICON_ADD_STRING, 3, false, "Add String Data")
	new_craft_itm.add_button(2, TRASH_BIN, 4, false, "Delete Item")
	new_craft_itm.set_selectable(0, false)
	new_craft_itm.set_selectable(1, false)
	new_craft_itm.set_editable(1, true)
	new_craft_itm.set_editable(2, true)
	
	for data_key in data:
		add_recipe_item_data(new_craft_itm, data_key, data[data_key]["value"], data[data_key]["operator"])


func _on_craft_all_itm_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var new_craft_itm: TreeItem = null
	
	match id:
		0:
			if not has_recipe_input_id(item.get_text(0)):
				add_input_recipe_item(item.get_text(0), 1)
		1:
			if not has_recipe_output_id(item.get_text(0)):
				add_output_recipe_item(item.get_text(0), 1)
	something_changed()


func _on_put_item_edited(edited_tree: Tree) -> void:
	if edited_tree.get_edited_column() != 0:
		return
	
	var edited_item: TreeItem = edited_tree.get_edited()
	var new_valid_id: String = get_valid_id(edited_item.get_parent(), 0, edited_item.get_text(0), edited_item, "data")
	edited_item.set_text(0, new_valid_id)
	something_changed()


func save_crafting_station_data() -> void:
	var station_data: Dictionary = {}
	
	for data in station_data_tree.get_root().get_children():
		var data_variant: Variant = null
		match data.get_cell_mode(1):
			TreeItem.CELL_MODE_RANGE:
				if data.get_icon(0) == ICON_INT:
					data_variant = int(data.get_range(1))
				else:
					data_variant = float(data.get_range(1))
			TreeItem.CELL_MODE_CHECK:
				data_variant = data.is_checked(1)
			TreeItem.CELL_MODE_STRING:
				data_variant = data.get_text(0)
		station_data[data.get_text(0)] = data_variant
	
	items_resource.set_crafting_station_name(current_station, station_name_ln_edt.text.strip_edges())
	items_resource._crafting[current_station]["data"] = station_data


func get_valid_id(on_item: TreeItem, id_cell: int, desired_id: String, ignore_tree: TreeItem = null, default_id: String = "new_item") -> String:
	var clean_id: String = desired_id.strip_edges()
	var iteration: int = 0
	if clean_id.is_empty():
		clean_id = default_id
	var modified_id: String = clean_id
	while has_tree_id(on_item, id_cell, modified_id, ignore_tree):
		iteration += 1
		modified_id = clean_id + str(iteration)
	return modified_id


func has_tree_id(on_item: TreeItem, on_cell: int, id: String, ignore_tree: TreeItem = null) -> bool:
	for child in on_item.get_children():
		if child == ignore_tree:
			continue
		if child.get_text(on_cell) == id:
			return true
	return false


func add_recipe_item_data(on_item: TreeItem, data_key: String, data_value: Variant, operator: int = OP_EQUAL) -> void:
	var new_item: TreeItem = on_item.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_text(0, data_key)
	
	match typeof(data_value):
		TYPE_BOOL:
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_item.set_icon(0, ICON_BOOL)
			new_item.set_text(1, "==")
			new_item.set_checked(2, data_value)
		TYPE_STRING:
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_item.set_icon(0, ICON_STRING)
			new_item.set_text(1, "==,!=")
			new_item.set_text(2, data_value)
		TYPE_INT:
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_item.set_icon(0, ICON_INT)
			new_item.set_text(1, "==,!=,<,<=,>,>=")
			new_item.set_range_config(2, -ITEM_DATA_RANGE, ITEM_DATA_RANGE, 1.0)
			new_item.set_range(2, data_value)
		TYPE_FLOAT:
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_item.set_icon(0, ICON_FLOAT)
			new_item.set_text(1, "==,!=,<,<=,>,>=")
			new_item.set_range_config(2, -ITEM_DATA_RANGE, ITEM_DATA_RANGE, 1.0)
			new_item.set_range(2, data_value)
	new_item.set_range(1, operator_to_range(operator))
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)
	new_item.add_button(2, TRASH_BIN, 4, false, "Delete Data")


func operator_to_range(operator: int) -> int:
	match operator:
		OP_EQUAL:
			return 0
		OP_NOT_EQUAL:
			return 1
		OP_LESS:
			return 2
		OP_LESS_EQUAL:
			return 3
		OP_GREATER:
			return 4
		OP_GREATER_EQUAL:
			return 5
		_:
			return 0


func range_to_operator(operator: int) -> int:
	match operator:
		0:
			return OP_EQUAL
		1:
			return OP_NOT_EQUAL
		2:
			return OP_LESS
		3:
			return OP_LESS_EQUAL
		4:
			return OP_GREATER
		5:
			return OP_GREATER_EQUAL
		_:
			return OP_EQUAL


func on_put_recipe_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0: # Add Int
			var valid_id: String = get_valid_id(item, 0, "new_int")
			add_recipe_item_data(item, valid_id, 0)
		1: # Add Float
			var valid_id: String = get_valid_id(item, 0, "new_float")
			add_recipe_item_data(item, valid_id, 0.0)
		2: # Add Bool
			var valid_id: String = get_valid_id(item, 0, "new_bool")
			add_recipe_item_data(item, valid_id, false)
		3: # Add String
			var valid_id: String = get_valid_id(item, 0, "new_string")
			add_recipe_item_data(item, valid_id, "")
		4: # Delete
			item.free()
	something_changed()


func has_recipe_input_id(item_id: String) -> bool:
	for in_item in in_item_tree.get_root().get_children():
		if in_item.get_text(0) == item_id:
			return true
	return false


func has_recipe_output_id(item_id: String) -> bool:
	for in_item in out_item_tree.get_root().get_children():
		if in_item.get_text(0) == item_id:
			return true
	return false


func _on_item_category_deleted(category_id: String) -> void:
	items_resource.erase_item_category(category_id)
	if category_id == current_item_category:
		current_item_category = ""
		current_item = ""
		if items_container.visible:
			set_data_visible(-1)
	something_changed()


func _on_item_category_created(category_path: String, category_id: String) -> void:
	items_resource.create_item_category(category_path, category_id)
	something_changed()


func _on_currency_id_changed(from: String, to: String) -> void:
	if from == to:
		return
	items_resource._currencies[to] = items_resource._currencies[from]
	items_resource._currencies.erase(from)
	if current_currency == from:
		current_currency = to
	something_changed()


func _on_currency_created(currency_id: String) -> void:
	items_resource.create_currency(currency_id)
	something_changed()


func _on_rarity_name_text_submitted(_submitted_text: String) -> void:
	rarity_col_pk_btn.grab_focus()


func _on_item_category_renamed(from: String, to: String) -> void:
	var target_category: Dictionary = items_resource._items
	var from_path: PackedStringArray = from.split("/", false)
	var to_key: String = to.split("/", false)[-1]
	var from_key: String = from_path[-1]
	from_path.resize(from_path.size() - 1)
	
	for subcat in from_path:
		target_category = target_category[subcat]["subcategories"]
	
	target_category[to_key] = target_category[from_key]
	target_category.erase(from_key)
	
	if current_item_category == from:
		current_item_category = to
		category_id_label.text = Strings.title_case(to.split("/", false)[-1].replace("_", " "))
	something_changed()


func _on_currency_selected(currency_id: String) -> void:
	if not currency_data_container.visible:
		set_data_visible(1)
	if current_currency == currency_id:
		return
	
	if _switching:
		return
	_switching = true
	
	if not current_currency.is_empty():
		save_currency_data()
	
	clear_currency_tree()
	
	current_currency = currency_id
	currency_name_ln_edt.text = items_resource.get_currency_name(currency_id)
	
	for currency_data_key in items_resource.get_currency_data_keys(currency_id):
		add_item_data(
				currency_data_tree.get_root(),
				currency_data_key,
				currency_val_spn_bx.value)
				#items_resource.get_currency_data(currency_id, currency_data_key))
	currency_val_spn_bx.set_value_no_signal(items_resource.get_currency_value(currency_id))
	currency_val_spn_bx.get_line_edit().text = str(currency_val_spn_bx.value)
	_switching = false


func _on_currency_deleted(currency_id: String) -> void:
	items_resource.erase_currency(currency_id)
	if current_currency == currency_id:
		current_currency = ""
		if currency_data_container.visible:
			set_data_visible(-1)
	something_changed()


func _on_item_category_selected(category_id: String) -> void:
	if not items_container.visible:
		set_data_visible(0)
		
	if current_item_category == category_id:
		return
	
	if not current_item_category.is_empty():
		save_item_category_data()
		if not current_item.is_empty():
			save_item_data()
	
	current_item_category = category_id
	current_item = ""
	
	clear_item_tree()
	
	item_cat_name_ln_edt.text = items_resource.get_category_name(category_id)
	item_cat_txt_edt.text = items_resource.get_category_description(category_id)
	
	for item in items_resource.get_category_item_keys(category_id):
		create_item(item)
	
	category_data_container.visible = true
	item_data_container.visible = false
	category_id_label.text = Strings.title_case(category_id.split("/", false)[-1].replace("_", " "))


func set_data_visible(id: int) -> void:
	items_container.visible = id == 0
	currency_data_container.visible = id == 1
	rarity_container.visible = id == 2
	crafting_container.visible = id == 3


func _on_currency_value_changed(new_value: int) -> void:
	if _switching:
		return
	depot_tree.update_currency_value(current_currency, new_value)
	something_changed()


func _on_rarity_renamed(idx: int, new_name: String) -> void:
	if current_rarity == idx:
		rarity_name_ln_edt.text = new_name
	rarities_opt_btn.set_item_text(idx, new_name)
	something_changed()


func _on_rarity_deleted(rarity_idx: int) -> void:
	items_resource.remove_rarity(rarity_idx)
	rarities_opt_btn.remove_item(rarity_idx)
	if current_rarity == rarity_idx:
		current_rarity = -1
		if rarity_container.visible:
			set_data_visible(-1)
	something_changed()


func _on_rarity_created(rarity_name: String) -> void:
	items_resource.create_rarity(rarity_name)
	rarities_opt_btn.add_item(rarity_name)
	something_changed()


func _on_rarity_reindexed(from: int, to: int) -> void:
	var rarity_list: Array[String] = []
	var current_selected: int = rarities_opt_btn.selected
	for rarity in range(rarities_opt_btn.item_count):
		rarity_list.append(rarities_opt_btn.get_item_text(rarity))
	rarities_opt_btn.clear()
	Arrays.switch_indexes(from, to, rarity_list)
	for rarity in rarity_list:
		rarities_opt_btn.add_item(rarity)
	rarities_opt_btn.selected = current_selected
	something_changed()


func clear_recipe_fields() -> void:
	recipe_name_ln_edt.clear()
	search_rcp_item_ln_edt.clear()
	_on_search_recipe_text_submitted("")
	for item in recipe_data_tree.get_root().get_children():
		item.free()
	for item in in_item_tree.get_root().get_children():
		item.free()
	for item in out_item_tree.get_root().get_children():
		item.free()


func add_item_data(on_tree: TreeItem, data_id: String, new_data: Variant) -> void:
	var new_item: TreeItem = on_tree.create_child()
	var valid_id: String = get_data_valid_id(on_tree, data_id)
	
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_text(0, valid_id)
	new_item.set_metadata(0, {"id": valid_id})
	
	match typeof(new_data):
		TYPE_INT:
			new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_item.set_range_config(1, -ITEM_DATA_RANGE, ITEM_DATA_RANGE, 1.0)
			new_item.set_range(1, new_data)
			new_item.set_icon(0, ICON_INT)
		TYPE_FLOAT:
			new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_item.set_range_config(1, -ITEM_DATA_RANGE, ITEM_DATA_RANGE, ITEM_DATA_FLOAT_STEP)
			new_item.set_range(1, new_data)
			new_item.set_icon(0, ICON_FLOAT)
		TYPE_BOOL:
			new_item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			new_item.set_text(1, "Enabled")
			new_item.set_checked(1, new_data)
			new_item.set_icon(0, ICON_BOOL)
		TYPE_STRING:
			new_item.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
			new_item.set_text(1, new_data)
			new_item.set_icon(0, ICON_STRING)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.add_button(1, TRASH_BIN, 0, false, "Remove Data")


# This is an almost identical to the one on top. Maybe merging it with extra
# args is better. But for simplicity I'll keep them separate.
func _on_add_rarity_data_btn_pressed(data_id: String, new_data: Variant) -> void:
	add_item_data(rarity_data_tree.get_root(), data_id, new_data)
	something_changed()


func _on_rarity_name_focus_lost() -> void:
	var rarity_name: String = rarity_name_ln_edt.text.strip_edges()
	
	if current_rarity < 0 or rarity_name == depot_tree.get_rarity_name(current_rarity):
		return
	
	rarity_name_ln_edt.text = rarity_name
	depot_tree.set_rarity_name(current_rarity, rarity_name)
	items_resource.set_rarity_name(current_rarity, rarity_name)
	rarities_opt_btn.set_item_text(current_rarity, rarity_name)


func _on_rarity_selected(rarity_idx: int) -> void:
	if not rarity_container.visible:
		set_data_visible(2)
	
	if current_rarity == rarity_idx:
		return
	
	if current_rarity != -1:
		save_rarity_data()
		# We're ensuring that the name is properly updated in case that the
		# pressed signal was emitted faster than the focus lost signal.
		if depot_tree.get_rarity_name(current_rarity) != rarity_name_ln_edt.text.strip_edges():
			depot_tree.set_rarity_name(current_rarity, rarity_name_ln_edt.text.strip_edges())
	
	current_rarity = rarity_idx
	
	clear_rarity_data_tree()
	
	rarity_name_ln_edt.text = items_resource.get_rarity_name(rarity_idx)
	rarity_col_pk_btn.color = items_resource.get_rarity_color(rarity_idx)
	
	for rarity_key in items_resource.get_rarity_keys(rarity_idx):
		add_item_data(
				rarity_data_tree.get_root(),
				rarity_key,
				items_resource.get_rarity_data(rarity_idx, rarity_key))


func _on_rarity_data_edited() -> void:
	if rarity_data_tree.get_edited_column() != 0:
		return
	
	var edited: TreeItem = rarity_data_tree.get_edited()
	var new_id: String = get_rarity_data_valid_id(edited.get_text(0), edited)
	
	edited.set_text(0, new_id)
	edited.get_metadata(0)["id"] = new_id
	something_changed()


func _on_currency_data_edited() -> void:
	if currency_data_tree.get_edited_column() != 0:
		return
	
	var edited: TreeItem = currency_data_tree.get_edited()
	var new_id: String = get_valid_id(currency_data_tree.get_root(), 0, edited.get_text(0), edited)
	
	edited.set_text(0, new_id)
	edited.get_metadata(0)["id"] = new_id
	something_changed()


#func _on_item_data_id_edited() -> void:
	#if item_data_tree.get_edited_column() != 0:
		#return
	#
	#var edited: TreeItem = item_data_tree.get_edited()
	#var new_id: String = get_data_valid_id(item_data_tree.get_root(), edited.get_text(0), edited)
	#
	#edited.set_text(0, new_id)
	
	#edited.get_metadata(0)["id"] = new_id


func save_item_data() -> void:
	items_resource.set_item_name(
			current_item_category,
			current_item,
			item_name_ln_edt.text.strip_edges())
	items_resource.set_item_description(
			current_item_category,
			current_item,
			item_description.text.strip_edges())
	items_resource.set_item_stack(
			current_item_category,
			current_item,
			stack_size_spn_bx.value)
	items_resource.set_item_value(
			current_item_category,
			current_item,
			item_val_spn_bx.value)
	items_resource.set_item_rarity(
			current_item_category,
			current_item,
			rarities_opt_btn.selected)
	
	var item_data_dict: Dictionary = {}
	
	for item_data in item_data_tree.get_root().get_children():
		var data: Variant = null
		match item_data.get_cell_mode(1):
			TreeItem.CELL_MODE_RANGE:
				if item_data.get_icon(0) == ICON_INT:
					data = int(item_data.get_range(1))
				else:
					data = float(item_data.get_range(1))
			TreeItem.CELL_MODE_CHECK:
				data = item_data.is_checked(1)
			TreeItem.CELL_MODE_STRING:
				data = item_data.get_text(1)
		item_data_dict[item_data.get_text(0)] = data
	
	items_resource.get_item_category_dict(current_item_category)["items"][current_item]["data"] = item_data_dict


func save_item_category_data() -> void:
	items_resource.set_category_name(
			current_item_category,
			item_cat_name_ln_edt.text.strip_edges())
	items_resource.set_category_description(
			current_item_category,
			item_cat_txt_edt.text.strip_edges())


func save_currency_data() -> void:
	items_resource.set_currency_name(current_currency, currency_name_ln_edt.text.strip_edges())
	items_resource.set_currency_value(current_currency, depot_tree.get_currency_value(current_currency))#currency_val_spn_bx.value)
	
	var currency_data: Dictionary = {}
	
	for curr_tree in currency_data_tree.get_root().get_children():
		var tree_data: Variant = null
		match curr_tree.get_cell_mode(1):
			TreeItem.CELL_MODE_RANGE:
				if curr_tree.get_icon(0) == ICON_INT:
					tree_data = int(curr_tree.get_range(1))
				else:
					tree_data = float(curr_tree.get_range(1))
			TreeItem.CELL_MODE_CHECK:
				tree_data = curr_tree.is_checked(1)
			TreeItem.CELL_MODE_STRING:
				tree_data = curr_tree.get_text(1)
		currency_data[curr_tree.get_text(0)] = tree_data
	
	items_resource._currencies[current_currency]["data"] = currency_data


func save_rarity_data() -> void:
	var r_data: Dictionary = {}
	
	for rar_tree in rarity_data_tree.get_root().get_children():
		var tree_data: Variant = null
		match rar_tree.get_cell_mode(1):
			TreeItem.CELL_MODE_RANGE:
				if rar_tree.get_icon(0) == ICON_INT:
					tree_data = int(rar_tree.get_range(1))
				else:
					tree_data = float(rar_tree.get_range(1))
			TreeItem.CELL_MODE_CHECK:
				tree_data = rar_tree.is_checked(1)
			TreeItem.CELL_MODE_STRING:
				tree_data = rar_tree.get_text(1)
		r_data[rar_tree.get_text(0)] = tree_data
	
	items_resource.set_rarity_name(current_rarity, rarity_name_ln_edt.text.strip_edges())
	items_resource.set_rarity_color(current_rarity, rarity_col_pk_btn.color)
	items_resource._rarities[current_rarity]["data"] = r_data


func get_data_valid_id(on_tree: TreeItem, desired_id: String, skip_tree: TreeItem = null) -> String:
	var clean_id: String = desired_id.strip_edges()
	if clean_id.is_empty():
		clean_id = "item_data"
	var modified_id: String = clean_id
	var iteration: int = 0
	
	while has_item_data_id(on_tree, modified_id, skip_tree):
		iteration += 1
		modified_id = clean_id + str(iteration)
	
	return modified_id


func get_rarity_data_valid_id(desired_id: String, skip_tree: TreeItem = null) -> String:
	var clean_id: String = desired_id.strip_edges()
	if clean_id.is_empty():
		clean_id = "rarity_data"
	var modified_id: String = clean_id
	var iteration: int = 0
	
	while has_rarity_data_id(modified_id, skip_tree):
		iteration += 1
		modified_id = clean_id + str(iteration)
	
	return modified_id


func has_item_data_id(on_tree: TreeItem, id: String, skip: TreeItem = null) -> bool:
	for data in on_tree.get_children():
		if data == skip:
			continue
		if data.get_text(0) == id:
			return true
	return false


func has_rarity_data_id(id: String, skip: TreeItem = null) -> bool:
	for data in rarity_data_tree.get_root().get_children():
		if data == skip:
			continue
		if data.get_text(0) == id:
			return true
	return false


func clear_item_data() -> void:
	item_name_ln_edt.clear()
	item_description.clear()
	stack_size_spn_bx.value = stack_size_spn_bx.min_value
	item_val_spn_bx.value = 0
	rarities_opt_btn.select(rarities_opt_btn.item_count - 1)
	item_data_tree.clear_data()


#func clear_item_data_tree() -> void:
	#for item in item_data_tree.get_root().get_children():
		#item.free()


func clear_rarity_data_tree() -> void:
	for data in rarity_data_tree.get_root().get_children():
		data.free()


func clear_item_tree() -> void:
	for item in items_tree.get_root().get_children():
		item.free()


func clear_currency_tree() -> void:
	for item in currency_data_tree.get_root().get_children():
		item.free()


func clear_station_recipes() -> void:
	for item in station_recipes_tree.get_root().get_children():
		item.free()


func clear_station_data() -> void:
	for item in station_data_tree.get_root().get_children():
		item.free()


func _on_create_item_button_pressed() -> void:
	var valid_id: String = get_valid_id(items_tree.get_root(), 0, "new_item")
	create_item(valid_id)
	items_resource.create_item(current_item_category, valid_id)
	something_changed()


func create_item(item_id: String) -> void:
	var new_item: TreeItem = items_tree.get_root().create_child()
	new_item.set_metadata(0, {"id": item_id})
	new_item.set_text(0, item_id)
	new_item.set_editable(0, true)
	new_item.add_button(0, TRASH_BIN, 0, false, "Delete Item")


func _on_item_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0: # Delete Item
			items_resource.erase_item(current_item_category, item.get_text(0))
			item.free()
			something_changed()


func _on_item_changed() -> void:
	var edited: TreeItem = items_tree.get_edited()
	var new_id: String = get_valid_id(items_tree.get_root(), 0, edited.get_text(0), edited, "item")
	var old_id: String = edited.get_metadata(0)["id"]
	var res_dict: Dictionary = items_resource.get_item_category_dict(current_item_category)["items"]
	res_dict[new_id] = res_dict[old_id]
	items_resource.get_item_category_dict(current_item_category)["items"].erase(old_id)
	
	if edited.get_metadata(0)["id"] == current_item:
		current_item = new_id
		item_id_label.text = Strings.title_case(new_id.replace("_", " "))
	
	edited.set_text(0, new_id)
	edited.get_metadata(0)["id"] = new_id
	something_changed()


func _on_item_selected() -> void:
	var select: TreeItem = items_tree.get_selected()
	
	if not current_item.is_empty():
		save_item_data()
	
	clear_item_data()
	
	current_item = select.get_text(0)
	
	item_id_label.text = Strings.title_case(current_item.replace("_", " "))
	item_name_ln_edt.text = items_resource.get_item_name(
			current_item_category,
			current_item)
	item_description.text = items_resource.get_item_description(
			current_item_category,
			current_item)
	
	stack_size_spn_bx.value = items_resource.get_item_stack(
			current_item_category,
			current_item)
	stack_size_spn_bx.get_line_edit().text = str(stack_size_spn_bx.value)
	
	item_val_spn_bx.value = items_resource.get_item_value(
			current_item_category,
			current_item)
	item_val_spn_bx.get_line_edit().text = str(item_val_spn_bx.value)
	
	rarities_opt_btn.select(
			mini(
					rarities_opt_btn.item_count - 1,
					items_resource.get_item_rarity(
							current_item_category,
							current_item)))
	
	for data_key in items_resource.get_item_data_keys(current_item_category, current_item):
		add_item_data(
				item_data_tree.get_root(),
				data_key,
				items_resource.get_item_data(
						current_item_category,
						current_item,
						data_key))
	
	item_data_container.visible = true


func has_unsaved_changes() -> bool:
	return _unsaved


func save() -> void:
	if not current_item_category.is_empty():
		save_item_category_data()
		if not current_item.is_empty():
			save_item_data()
	if not current_currency.is_empty():
		save_currency_data()
	if not current_rarity == -1:
		save_rarity_data()
	if not current_station.is_empty():
		save_crafting_station_data()
		if not current_recipe.is_empty():
			save_current_recipe()
	
	items_resource.save()
	_unsaved = false
