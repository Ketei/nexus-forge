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
@onready var recipe_id_label: Label = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/RecipeIDLabel
@onready var refresh_btn: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/AllItemContainer/HeaderContainer/RefreshBtn
@onready var all_item_craft_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/AllItemContainer/AllItemCraftTree
@onready var in_item_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/PutsContainer/InContainer/InItemTree
@onready var out_item_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/PutsContainer/OutContainer/OutItemTree
@onready var add_station_int: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/ButtonContainer/AddStationInt
@onready var add_station_float: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/ButtonContainer/AddStationFloat
@onready var add_station_bool: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/ButtonContainer/AddStationBool
@onready var add_station_string: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/ButtonContainer/AddStationString
@onready var station_data_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/StationDataTree
@onready var create_recipe_btn: Button = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/HeaderContainer/CreateRecipeBtn
@onready var station_recipes_tree: Tree = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/StationRecipesTree
@onready var search_rcp_item_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/AllItemContainer/HeaderContainer/SearchRcpItemLnEdt
@onready var recipe_container: VBoxContainer = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer
@onready var station_id_label: Label = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/StationsContainer/StationIDLabel
#@onready var recipe_id_label: Label = $MainContainer/ItemsContainer/DataContainer/CraftingContainer/RecipeMargin/RecipeContainer/RecipeIDLabel


func _ready() -> void:
	items_resource = NFItemsRes.new() # Remove after testing
	items_tree.create_item()
	item_data_tree.create_item()
	rarity_data_tree.create_item()
	currency_data_tree.create_item()
	all_item_craft_tree.create_item()
	in_item_tree.create_item()
	out_item_tree.create_item()
	station_data_tree.create_item()
	station_recipes_tree.create_item()
	
	in_item_tree.set_column_expand(1, false)
	in_item_tree.set_column_expand(2, false)
	in_item_tree.set_column_custom_minimum_width(1, 50)
	in_item_tree.set_column_custom_minimum_width(2, 250)
	
	out_item_tree.set_column_expand(1, false)
	out_item_tree.set_column_expand(2, false)
	out_item_tree.set_column_custom_minimum_width(1, 50)
	out_item_tree.set_column_custom_minimum_width(2, 250)
	
	rarities_opt_btn.clear()
	
	for rarity_idx in range(items_resource.get_rarity_count()):
		rarities_opt_btn.add_item(items_resource.get_rarity_name(rarity_idx))
		depot_tree.create_rarity(items_resource.get_rarity_name(rarity_idx))
	
	depot_tree.rarity_created.connect(_on_rarity_created)
	depot_tree.rarity_reindexed.connect(_on_rarity_reindexed)
	depot_tree.rarity_deleted.connect(_on_rarity_deleted)
	depot_tree.rarity_renamed.connect(_on_rarity_renamed)
	#currency_val_spn_bx.value_changed.connect(_on_currency_value_changed)
	currency_val_spn_bx.get_line_edit().text_changed.connect(_on_currency_text_changed)
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
	
	items_tree.item_edited.connect(_on_item_changed)
	items_tree.item_selected.connect(_on_item_selected)
	
	in_item_tree.button_clicked.connect(on_put_recipe_button_clicked)
	out_item_tree.button_clicked.connect(on_put_recipe_button_clicked)
	
	in_item_tree.item_edited.connect(_on_put_item_edited.bind(in_item_tree))
	out_item_tree.item_edited.connect(_on_put_item_edited.bind(out_item_tree))
	
	all_item_craft_tree.button_clicked.connect(_on_craft_all_itm_button_clicked)
	
	refresh_btn.pressed.connect(_on_item_refresh_btn_pressed)
	
	add_item_int_btn.pressed.connect(_on_add_item_data_btn_pressed.bind("new_int", 0))
	add_item_float_btn.pressed.connect(_on_add_item_data_btn_pressed.bind("new_float", 0.0))
	add_item_bool_btn.pressed.connect(_on_add_item_data_btn_pressed.bind("new_bool", false))
	add_item_str_btn.pressed.connect(_on_add_item_data_btn_pressed.bind("new_string", ""))
	
	rarity_data_tree.item_edited.connect(_on_rarity_data_edited)
	
	add_rarity_int_btn.pressed.connect(_on_add_rarity_data_btn_pressed.bind("new_int", 0))
	add_rarity_float_btn.pressed.connect(_on_add_rarity_data_btn_pressed.bind("new_float", 0.0))
	add_rarity_bool_btn.pressed.connect(_on_add_rarity_data_btn_pressed.bind("new_bool", false))
	add_rarity_str_btn.pressed.connect(_on_add_rarity_data_btn_pressed.bind("new_string", ""))
	
	add_crr_int_btn.pressed.connect(_on_add_currency_data_btn_pressed.bind("new_int", 0))
	add_crr_float_btn.pressed.connect(_on_add_currency_data_btn_pressed.bind("new_float", 0.0))
	add_crr_bool_btn.pressed.connect(_on_add_currency_data_btn_pressed.bind("new_bool", false))
	add_crr_str_btn.pressed.connect(_on_add_currency_data_btn_pressed.bind("new_string", ""))
	
	add_station_int.pressed.connect(_on_add_station_data_btn_pressed.bind("new_int", 0))
	add_station_float.pressed.connect(_on_add_station_data_btn_pressed.bind("new_float", 0.0))
	add_station_bool.pressed.connect(_on_add_station_data_btn_pressed.bind("new_bool", false))
	add_station_string.pressed.connect(_on_add_station_data_btn_pressed.bind("new_string", ""))
	
	rarity_name_ln_edt.focus_exited.connect(_on_rarity_name_focus_lost)
	rarity_name_ln_edt.text_submitted.connect(_on_rarity_name_text_submitted)
	
	item_data_tree.item_edited.connect(_on_item_data_id_edited)
	
	create_item_btn.pressed.connect(_on_create_item_button_pressed)
	
	create_recipe_btn.pressed.connect(_on_create_recipe_btn_pressed)
	station_recipes_tree.item_edited.connect(_on_recipe_tree_item_edited)
	station_recipes_tree.item_selected.connect(_on_crafting_recipe_selected)
	station_data_tree.item_edited.connect(_on_station_data_item_edited)
	
	search_rcp_item_ln_edt.text_submitted.connect(_on_search_recipe_text_submitted)
	
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


#signal crafting_station_created(station_id: String)
#signal crafting_station_changed(from: String, to: String)
#signal crafting_station_deleted(station_id: String)
#signal crafting_station_selected(station_id: String)

func _on_crafting_station_created(station_id: String) -> void:
	pass


func _on_crafting_station_changed(from: String, to: String) -> void:
	pass


func _on_crafting_station_deleted(station_id: String) -> void:
	pass


func _on_crafting_station_selected(station_id: String) -> void:
	if not crafting_container.visible:
		set_data_visible(3)
	
	if current_station == station_id:
		return
	
	current_station = station_id
	station_id_label.text = Strings.title_case(station_id.replace("_", " "))
	
	if not current_recipe.is_empty():
		current_recipe = ""
		recipe_container.visible = false


func _on_crafting_recipe_selected() -> void:
	var selected: TreeItem = station_recipes_tree.get_selected()
	current_recipe = selected.get_text(0)
	recipe_container.visible = true


func _on_search_recipe_text_submitted(text: String) -> void:
	var clean_text: String = text.strip_edges()
	for recipe_id in all_item_craft_tree.get_root().get_children():
		recipe_id.visible = clean_text.is_empty() or recipe_id.get_text(0).containsn(clean_text)


func _on_create_recipe_btn_pressed() -> void:
	var new_id: String = get_valid_id(
			station_recipes_tree.get_root(),
			0,
			"new_recipe")
	var new_recipe: TreeItem = station_recipes_tree.get_root().create_child()
	new_recipe.set_text(0, new_id)
	new_recipe.set_metadata(0, {"id": new_id})
	new_recipe.set_editable(0, true)


func _on_recipe_tree_item_edited() -> void:
	var edited: TreeItem = station_recipes_tree.get_edited()
	var new_name: String = get_valid_id(
			station_recipes_tree.get_root(),
			0,
			edited.get_text(0),
			edited,
			"crafting_recipe")
	edited.set_text(0, new_name)
	edited.get_metadata(0)["id"] = new_name


func _on_station_data_item_edited() -> void:
	if station_data_tree.get_edited_column() != 0:
		return
	
	var edited: TreeItem = station_data_tree.get_edited()
	var new_id: String = get_valid_id(
			station_data_tree.get_root(),
			0,
			edited.get_text(0),
			edited,
			"station_data")
	edited.set_text(0, new_id)


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


func _on_craft_all_itm_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var new_craft_itm: TreeItem = null
	
	match id:
		0:
			if has_recipe_input_id(item.get_text(0)):
				return
			new_craft_itm = in_item_tree.get_root().create_child()
		1:
			if has_recipe_output_id(item.get_text(0)):
				return
			new_craft_itm = out_item_tree.get_root().create_child()
	
	new_craft_itm.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_craft_itm.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	#new_craft_itm.set_text(1, "==,!=,<,<=,>,>=")
	new_craft_itm.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	new_craft_itm.set_range_config(2, 1, CRAFTING_MAX_ITEM, 1)
	new_craft_itm.set_range(2, 1)
	
	new_craft_itm
	
	new_craft_itm.set_text(0, item.get_text(0))
	new_craft_itm.add_button(2, ICON_ADD_INT, 0, false, "Add Integer Data")
	new_craft_itm.add_button(2, ICON_ADD_FLOAT, 1, false, "Add Float Data")
	new_craft_itm.add_button(2, ICON_ADD_BOOL, 2, false, "Add Bool Data")
	new_craft_itm.add_button(2, ICON_ADD_STRING, 3, false, "Add String Data")
	new_craft_itm.add_button(2, TRASH_BIN, 4, false, "Delete Item")
	new_craft_itm.set_selectable(0, false)
	new_craft_itm.set_selectable(1, false)
	new_craft_itm.set_editable(1, true)
	new_craft_itm.set_editable(2, true)


func _on_put_item_edited(edited_tree: Tree) -> void:
	if edited_tree.get_edited_column() != 0:
		return
	
	var edited_item: TreeItem = edited_tree.get_edited()
	var new_valid_id: String = get_valid_id(edited_item.get_parent(), 0, edited_item.get_text(0), edited_item, "data")
	edited_item.set_text(0, new_valid_id)


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


func on_put_recipe_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0: # Add Int
			var valid_id: String = get_valid_id(item, 0, "new_int")
			var new_item: TreeItem = item.create_child()
			new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
			new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_item.set_text(0, valid_id)
			new_item.set_text(1, "==,!=,<,<=,>,>=")
			new_item.set_range_config(2, -ITEM_DATA_RANGE, ITEM_DATA_RANGE, 1.0)
			new_item.set_range(2, 0)
			new_item.set_icon(0, ICON_INT)
			new_item.set_editable(0, true)
			new_item.set_editable(1, true)
			new_item.set_editable(2, true)
		1: # Add Float
			var valid_id: String = get_valid_id(item, 0, "new_float")
			var new_item: TreeItem = item.create_child()
			new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
			new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_item.set_text(0, valid_id)
			new_item.set_text(1, "==,!=,<,<=,>,>=")
			new_item.set_range_config(2, -ITEM_DATA_RANGE, ITEM_DATA_RANGE, ITEM_DATA_FLOAT_STEP)
			new_item.set_range(2, 0)
			new_item.set_icon(0, ICON_FLOAT)
			new_item.set_editable(0, true)
			new_item.set_editable(1, true)
			new_item.set_editable(2, true)
		2: # Add Bool
			var valid_id: String = get_valid_id(item, 0, "new_bool")
			
			var new_item: TreeItem = item.create_child()
			new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
			new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_item.set_text(0, valid_id)
			new_item.set_text(1, "==")
			new_item.set_text(2, "Enabled")
			new_item.set_checked(2, false)
			new_item.set_icon(0, ICON_BOOL)
			new_item.set_editable(0, true)
			new_item.set_editable(1, true)
			new_item.set_editable(2, true)
		3: # Add String
			var valid_id: String = get_valid_id(item, 0, "new_string")
			var new_item: TreeItem = item.create_child()
			new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
			new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_item.set_text(0, valid_id)
			new_item.set_text(1, "==, !=")
			new_item.set_text(2, "")
			new_item.set_icon(0, ICON_STRING)
			new_item.set_editable(0, true)
			new_item.set_editable(1, true)
			new_item.set_editable(2, true)
		4: # Delete
			item.free()


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


func _on_item_category_created(category_path: String, category_id: String) -> void:
	items_resource.create_item_category(category_path, category_id)


func _on_currency_id_changed(from: String, to: String) -> void:
	if from == to:
		return
	items_resource._currencies[to] = items_resource._currencies[from]
	items_resource._currencies.erase(from)
	if current_currency == from:
		current_currency = to


func _on_currency_created(currency_id: String) -> void:
	items_resource.create_currency(currency_id)


func _on_rarity_name_text_submitted(_submitted_text: String) -> void:
	rarity_col_pk_btn.grab_focus()


func _on_item_category_renamed(from: String, to: String) -> void:
	var target_category: Dictionary = items_resource._item_data
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


func _on_currency_selected(currency_id: String) -> void:
	if not currency_data_container.visible:
		set_data_visible(1)
	
	if current_currency == currency_id:
		return
	
	if not current_currency.is_empty():
		save_currency_data()
	
	clear_currency_tree()
	
	current_currency = currency_id
	currency_name_ln_edt.text = items_resource.get_currency_name(currency_id)
	for currency_data_key in items_resource.get_currency_data_keys(currency_id):
		add_item_data(
				currency_data_tree.get_root(),
				currency_data_key,
				items_resource.get_currency_data(currency_id, currency_data_key))
	currency_val_spn_bx.set_value_no_signal(items_resource.get_currency_value(currency_id))
	currency_val_spn_bx.get_line_edit().text = str(currency_val_spn_bx.value)


func _on_currency_deleted(currency_id: String) -> void:
	items_resource.erase_currency(currency_id)
	if current_currency == currency_id:
		current_currency = ""
		if currency_data_container.visible:
			set_data_visible(-1)


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
	depot_tree.update_currency_value(current_currency, new_value)


func _on_currency_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		depot_tree.update_currency_value(current_currency, maxi(currency_val_spn_bx.min_value, int(new_text)))
	else:
		depot_tree.update_currency_value(current_currency, currency_val_spn_bx.value)


func _on_rarity_renamed(idx: int, new_name: String) -> void:
	if current_rarity == idx:
		rarity_name_ln_edt.text = new_name
	rarities_opt_btn.set_item_text(idx, new_name)


func _on_rarity_deleted(rarity_idx: int) -> void:
	items_resource.remove_rarity(rarity_idx)
	rarities_opt_btn.remove_item(rarity_idx)
	if current_rarity == rarity_idx:
		current_rarity = -1
		if rarity_container.visible:
			set_data_visible(-1)


func _on_rarity_created(rarity_name: String) -> void:
	items_resource.create_rarity(rarity_name)
	rarities_opt_btn.add_item(rarity_name)


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


func _on_add_item_data_btn_pressed(data_id: String, new_data: Variant) -> void:
	add_item_data(item_data_tree.get_root(), data_id, new_data)


func _on_add_currency_data_btn_pressed(data_id: String, new_data: Variant) -> void:
	add_item_data(currency_data_tree.get_root(), data_id, new_data)


func _on_add_station_data_btn_pressed(data_id: String, new_data: Variant) -> void:
	add_item_data(station_data_tree.get_root(), data_id, new_data)


# This is an almost identical to the one on top. Maybe merging it with extra
# args is better. But for simplicity I'll keep them separate.
func _on_add_rarity_data_btn_pressed(data_id: String, new_data: Variant) -> void:
	add_rarity_data(data_id, new_data)
	items_resource.set_rarity_data(current_rarity, data_id, new_data)


func add_rarity_data(data_id: String, new_data: Variant) -> void:
	var new_item: TreeItem = rarity_data_tree.get_root().create_child()
	var valid_id: String = get_rarity_data_valid_id(data_id)
	
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
		add_rarity_data(
				rarity_key,
				items_resource.get_rarity_data(rarity_idx, rarity_key))


func _on_rarity_data_edited() -> void:
	if rarity_data_tree.get_edited_column() != 0:
		return
	
	var edited: TreeItem = rarity_data_tree.get_edited()
	var new_id: String = get_rarity_data_valid_id(edited.get_text(0), edited)
	
	edited.set_text(0, new_id)
	# Modify in memory
	edited.get_metadata(0)["id"] = new_id


func _on_item_data_id_edited() -> void:
	if item_data_tree.get_edited_column() != 0:
		return
	
	var edited: TreeItem = item_data_tree.get_edited()
	var new_id: String = get_data_valid_id(item_data_tree.get_root(), edited.get_text(0), edited)
	
	edited.set_text(0, new_id)
	# Modify in memory
	edited.get_metadata(0)["id"] = new_id


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
				data = item_data.get_text(0)
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
	#icon_ln_edt.clear()
	clear_item_data_tree()


func clear_item_data_tree() -> void:
	for item in item_data_tree.get_root().get_children():
		item.free()


func clear_rarity_data_tree() -> void:
	for data in rarity_data_tree.get_root().get_children():
		data.free()


func clear_item_tree() -> void:
	for item in items_tree.get_root().get_children():
		item.free()


func clear_currency_tree() -> void:
	for item in currency_data_tree.get_root().get_children():
		item.free()


func _on_create_item_button_pressed() -> void:
	items_resource.create_item(
		current_item_category,
		create_item("new_item"))


func create_item(item_id: String) -> String:
	var valid_id: String = get_valid_id(items_tree.get_root(), 0, "new_item")
	var new_item: TreeItem = items_tree.get_root().create_child()
	new_item.set_metadata(0, {"id": valid_id})
	new_item.set_text(0, valid_id)
	new_item.set_editable(0, true)
	return valid_id


#func _on_item_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	#DisplayServer.clipboard_set(current_item_category + "/" + item.get_text(0))


#func get_valid_item_id(desired_id: String, skip_tree: TreeItem = null) -> String:
	#var cleaned_id: String = desired_id.strip_edges()
	#if cleaned_id.is_empty():
		#cleaned_id = "new_item"
	#var modified_id: String = cleaned_id
	#var iteration: int = 0
	#while has_item_id(modified_id, skip_tree):
		#iteration += 1
		#modified_id = cleaned_id + str(iteration)
	#return modified_id


#func has_item_id(item_id: String, skip_tree: TreeItem) -> bool:
	#for item in items_tree.get_root().get_children():
		#if item == skip_tree:
			#continue
		#if item.get_text(0) == item_id:
			#return true
	#return false


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


#var _current_id: String = ""
#var _current_station: String = ""
#var _current_recipe: String = ""
#var item_memory: Dictionary = {} # ID: Resource
#var loading_item: bool = false
#var unsaved_recipe: bool = false
#var unsaved_item: bool = false
#var resource_loader: FileDialog = null
#var no_resource_panel: PanelContainer = null
#
#@onready var components: Node = $Components
#@onready var item_file_dialog: FileDialog = $Components/ItemFileDialog
#@onready var item_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/ItemTree
#
#@onready var item_name_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/NameContainer/ItemNameLnEdt
#@onready var sprite_path_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/SpriteContainer/PanelContainer/HBoxContainer/SpritePathLnEdt
#@onready var search_item_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/BarPanelContainer/ItemContainer/SearchItemLnEdt
#@onready var search_currency_ln_edit: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/VBoxContainer/PanelContainer/HBoxContainer/CurrencySearchLnEdit
#@onready var search_data_ln_edt: LineEdit = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CustomDataSearchLine
#@onready var search_station_ln_edt: LineEdit = $MainContainer/RecipesContainer/UpperTreeContainer/StationsTreeCont/HBoxContainer2/VBoxContainer/PanelContainer/HBoxContainer/SearchStationLnEdt
#
#@onready var item_type_opt_btn: OptionButton = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/TypeContainer/ItemTypeOptBtn
#@onready var item_subtype_opt_btn: OptionButton = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/SubtypeContainer/ItemSubtypeOptBtn
#
#@onready var item_lvl_spn_btn: SpinBox = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/ValuesContainer/HBoxContainer/ItemLvlSpnBtn
#@onready var item_value_spn_bx: SpinBox = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/ValuesContainer/HBoxContainer2/ItemValueSpnBx
#@onready var output_recipe_spin_box: SpinBox = $MainContainer/RecipesContainer/LowerTreeContainer/OutputTreeContainer/HBoxContainer7/OutputRecipeSpinBox
#@onready var input_recipe_spin_box: SpinBox = $MainContainer/RecipesContainer/LowerTreeContainer/InputTreeContainer/HBoxContainer7/InputRecipeSpinBox
#
#@onready var materials_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/TreesContainer/MaterialsContainer/MaterialsTree
#@onready var item_flag_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/TreesContainer/FlagsCotnainer/ItemFlagTree
#@onready var custom_data_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CustomDataTree
#@onready var stations_tree: Tree = $MainContainer/RecipesContainer/UpperTreeContainer/StationsTreeCont/HBoxContainer2/VBoxContainer/StationsTree
#@onready var input_recipe_tree: Tree = $MainContainer/RecipesContainer/LowerTreeContainer/InputTreeContainer/VBoxContainer/InputRecipeTree
#@onready var output_recipe_tree: Tree = $MainContainer/RecipesContainer/LowerTreeContainer/OutputTreeContainer/VBoxContainer/OutputRecipeTree
#@onready var currencies_tree: Tree = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/VBoxContainer/CurrenciesTree
#
#@onready var create_currency_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/VBoxContainer/PanelContainer/HBoxContainer/CreateCurrencyBtn
#@onready var add_int_button: Button = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddIntButton
#@onready var add_float_button: Button = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddFloatButton
#@onready var add_bool_button: Button = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddBoolButton
#@onready var add_string_button: Button = $MainContainer/ItemsContainer/DataContainer/ItemDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddStringButton
#@onready var add_station_btn: Button = $MainContainer/RecipesContainer/UpperTreeContainer/StationsTreeCont/HBoxContainer2/VBoxContainer/PanelContainer/HBoxContainer/AddStationBtn
#@onready var create_item_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/BarPanelContainer/ItemContainer/CreateItemBtn
#@onready var import_item_btn: Button = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/BarPanelContainer/ItemContainer/ImportItemBtn
#
#@onready var recipe_label: Label = $MainContainer/RecipesContainer/HBoxContainer/RecipeLabel
#
#@onready var main_container: HBoxContainer = $MainContainer
#@onready var save_button: Button = $MainContainer/ItemsContainer/DataContainer/ItemSelectContainer/HBoxContainer/SaveButton
#
#
## Consider freeing from memory as once hidden it isn't used again.
##@onready var no_resource_panel: PanelContainer = $NoResourcePanel
##@onready var create_db_button: Button = $NoResourcePanel/CenterContainer/InfoContainer/ButtonContainer2/CreateDBButton
##@onready var load_db_button: Button = $NoResourcePanel/CenterContainer/InfoContainer/ButtonContainer2/LoadDBButton
#
#
#func _ready() -> void:
	#var res_path: String = ProjectSettings.get_setting(NFItemsRes.SETTINGS_PATH, "")
	#
	#if not res_path.is_empty() and ResourceLoader.exists(res_path):
		#var res_preload: Resource = load(res_path)
		#if res_preload is NFItemsRes:
			#_items_resource = res_preload
	#
	#if _items_resource != null:
		#load_items()
		#load_recipes()
		#load_materials()
		#load_flags()
		#load_types()
		#load_currencies()
		#main_container.visible = true
	#else:
		#main_container.visible = false
		#no_resource_panel = preload("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		#add_child(no_resource_panel)
		#no_resource_panel.set_resource_type("NFItemsRes", "Depot", "Items")
		#no_resource_panel.create_resource_pressed.connect(on_create_resource_pressed)
		#no_resource_panel.load_resource_pressed.connect(on_load_resource_pressed)
	#
	#item_tree.item_id_pressed.connect(on_item_id_pressed)
	#add_int_button.pressed.connect(on_add_variable_button_pressed.bind(0))
	#add_float_button.pressed.connect(on_add_variable_button_pressed.bind(0.0))
	#add_bool_button.pressed.connect(on_add_variable_button_pressed.bind(false))
	#add_string_button.pressed.connect(on_add_variable_button_pressed.bind(""))
	#stations_tree.recipe_selected.connect(on_recipe_selected)
	#input_recipe_spin_box.value_changed.connect(change_recipe_size.bind(input_recipe_tree))
	#output_recipe_spin_box.value_changed.connect(change_recipe_size.bind(output_recipe_tree))
	#stations_tree.station_deleted.connect(on_station_deleted)
	#stations_tree.recipe_deleted.connect(on_recipe_deleted)
	#add_station_btn.pressed.connect(on_add_new_station_pressed)
	#stations_tree.recipe_id_changed.connect(on_recipe_id_changed)
	#stations_tree.station_id_changed.connect(on_station_id_changed)
	#item_file_dialog.file_selected.connect(on_item_file_selected)
	#create_currency_btn.pressed.connect(on_create_currency_pressed)
	#create_item_btn.pressed.connect(on_add_item_pressed)
	#import_item_btn.pressed.connect(on_import_item_pressed)
	#stations_tree.recipe_changed.connect(on_recipe_changed)
	#input_recipe_tree.recipe_changed.connect(on_recipe_changed)
	#output_recipe_tree.recipe_changed.connect(on_recipe_changed)
	#search_item_ln_edt.text_changed.connect(on_search_item.bind(item_tree))
	#search_data_ln_edt.text_changed.connect(on_search_item.bind(custom_data_tree))
	#search_currency_ln_edit.text_changed.connect(on_search_item.bind(currencies_tree))
	#search_station_ln_edt.text_changed.connect(on_search_item.bind(stations_tree))
	#save_button.pressed.connect(on_save)
	#item_tree.id_changed.connect(on_item_id_changed)
	#item_flag_tree.flag_selected.connect(on_item_data_changed)
	#custom_data_tree.variables_changed.connect(on_item_data_changed)
	#
	#item_name_ln_edt.text_changed.connect(on_item_data_changed)
	#sprite_path_ln_edt.text_changed.connect(on_item_data_changed)
	#item_type_opt_btn.item_selected.connect(on_item_data_changed)
	#item_subtype_opt_btn.item_selected.connect(on_item_data_changed)
	#item_lvl_spn_btn.value_changed.connect(on_item_data_changed)
	#item_value_spn_bx.value_changed.connect(on_item_data_changed)
	#materials_tree.material_selected.connect(on_item_data_changed)
	#
	#currencies_tree.currency_created.connect(on_currency_created)
	#currencies_tree.currency_id_changed.connect(on_currency_id_changed)
	#currencies_tree.currency_renamed.connect(on_currency_renamed)
	#currencies_tree.currency_revaluated.connect(on_currency_revaluated)
	#
	#stations_tree.station_created.connect(on_station_created)
	#stations_tree.recipe_created.connect(on_recipe_created)
	#stations_tree.station_renamed.connect(on_station_renamed)
	#
	#item_tree.item_deleted.connect(on_item_deleted)
#
#
#func on_item_data_changed(_ig_arg: Variant = null, _arg_2: Variant = null) -> void:
	#if not unsaved_item and not loading_item:
		#unsaved_item = true
#
#
#func on_search_item(search_str: String, search_node: Tree) -> void:
	#search_node.search_item(search_str)
#
#
#func on_recipe_changed(_dummy_var: Variant = null) -> void:
	#if not unsaved_recipe:
		#unsaved_recipe = true
#
#
#func load_currencies() -> void:
	#currencies_tree.clear_currencies()
	#for currency in _items_resource.get_currencies():
		#currencies_tree.create_currency(
				#currency,
				#_items_resource.get_currency_value(currency),
				#_items_resource.get_currency_name(currency))
#
#
#func on_add_item_pressed() -> void:
	#item_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	#item_file_dialog.show()
#
#
#func on_import_item_pressed() -> void:
	#item_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	#item_file_dialog.show()
#
#
#func on_resource_selected(resource_path: String) -> void:
	#if resource_loader.file_mode == FileDialog.FileMode.FILE_MODE_SAVE_FILE:
		#_items_resource = NFItemsRes.new()
		#ProjectSettings.set_setting(NFItemsRes.SETTINGS_PATH, resource_path)
		#ProjectSettings.save()
		#_items_resource.save()
	#else:
		#var res_preload: Resource = load(resource_path)
		#if res_preload is NFItemsRes:
			#_items_resource = res_preload
			#ProjectSettings.set_setting(NFItemsRes.SETTINGS_PATH, resource_path)
			#ProjectSettings.save()
		#else:
			#printerr("[DEPOT] Resource selected ins't NFItemsRes")
	#
	#if _items_resource != null:
		#resource_loader.queue_free()
		#main_container.visible = true
		#no_resource_panel.visible = false
		#no_resource_panel.queue_free()
		#stations_tree.station_created.disconnect(on_station_created)
		#load_items()
		#load_materials()
		#load_flags()
		#load_types()
		#load_recipes()
		#load_currencies()
		#stations_tree.station_created.connect(on_station_created)
#
#
#func on_create_resource_pressed() -> void:
	#if resource_loader == null:
		#resource_loader = FileDialog.new()
		#resource_loader.add_filter("*.tres", "Resources")
		#resource_loader.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
		#resource_loader.size = Vector2i(500, 350)
		#resource_loader.file_selected.connect(on_resource_selected)
		#components.add_child(resource_loader)
	#resource_loader.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	#resource_loader.show()
#
#
#func on_load_resource_pressed() -> void:
	#if resource_loader == null:
		#resource_loader = FileDialog.new()
		#resource_loader.add_filter("*.tres", "Resources")
		#resource_loader.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
		#resource_loader.size = Vector2i(500, 350)
		#resource_loader.file_selected.connect(on_resource_selected)
		#components.add_child(resource_loader)
	#resource_loader.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	#resource_loader.show()
#
#
#func on_create_currency_pressed() -> void:
	#currencies_tree.create_currency("new_currency")
#
#
#func on_currency_created(id: String, currency_name: String, currency_value: int) -> void:
	#_items_resource.create_currency(id, currency_name, currency_value)
#
#
#func on_currency_id_changed(from: String, to: String) -> void:
	#_items_resource._currencies[to] = _items_resource._currencies[from]
	#_items_resource.erase_currency(from)
#
#
#func on_currency_renamed(id: String, to: String) -> void:
	#_items_resource.set_currency_name(id, to)
#
#
#func on_currency_revaluated(id: String, value: int) -> void:
	#_items_resource.set_currency_value(id, value)
#
#
#func on_add_new_station_pressed() -> void:
	#stations_tree.create_station("new_station", [])
#
#
#func load_types() -> void:
	#item_type_opt_btn.clear()
	#for type in _items_resource.get_item_types():
		#item_type_opt_btn.add_item(type)
	#
	#if 0 < item_type_opt_btn.item_count:
		#item_type_opt_btn.select(0)
		#on_type_selected(0)
#
#
#func on_station_deleted(station_id: String) -> void:
	#_items_resource.erase_station(station_id)
#
#
#func on_recipe_deleted(station_id: String, recipe_id: String) -> void:
	#_items_resource.erase_recipe(station_id, recipe_id)
#
#
#func on_add_variable_button_pressed(variable_val: Variant) -> void:
	#custom_data_tree.add_variable("custom_data", variable_val)
#
#
#func on_type_selected(type_idx: int) -> void:
	#item_subtype_opt_btn.clear()
	#if type_idx == -1:
		#return
	#var type_id: String = item_type_opt_btn.get_item_text(type_idx)
	#for subtype in _items_resource.get_item_subtypes(type_id):
		#item_subtype_opt_btn.add_item(subtype)
#
#
#func load_recipes() -> void:
	#for station in _items_resource.get_crafting_stations():
		#stations_tree.create_station(
				#station,
				#_items_resource.get_recipes_of(station))
#
#
#func save_current_recipe() -> void:
	#_items_resource.set_station_recipe(
		#_current_station,
		#_current_recipe,
		#input_recipe_tree.get_current_recipe(),
		#output_recipe_tree.get_current_recipe())
	#unsaved_recipe = false
#
#
#func on_item_id_changed(from: String, to: String) -> void:
	#current_item_to_memory(true)
	#
	#_items_resource._items[to] = _items_resource._items[from]
	#_items_resource.remove_item(from)
	#
	#item_memory[to] = item_memory[from]
	#item_memory[to].item_id = to
	#item_memory.erase(from)
	#
	#if _current_id == from:
		#_current_id = to
#
#
#func on_recipe_created(station_id: String, recipe_id: String) -> void:
	#_items_resource.set_station_recipe(
		#station_id,
		#recipe_id,
		#[],
		#[])
#
#
#func on_recipe_id_changed(station: String, from: String, to: String) -> void:
	#_items_resource._recipes[station]["recipes"][to] = _items_resource._recipes[station]["recipes"][from]
	#_items_resource.erase_recipe(station, from)
	#
	#if from == _current_recipe:
		#_current_recipe = to
		#recipe_label.text = station + "/" + to
#
#
#func on_station_id_changed(from: String, to: String) -> void:
	#_items_resource._recipes[to] = _items_resource._recipes[from]
	#_items_resource.erase_station(from)
	#
	#if from == _current_station:
		#_current_station = to
		#recipe_label.text = to + "/" + _current_recipe
#
#
#func on_station_created(id: String, station_name: String) -> void:
	#_items_resource.create_crafting_station(
			#id,
			#station_name)
#
#
#func on_station_renamed(id: String, new_name: String) -> void:
	#_items_resource.set_station_name(
		#id,
		#new_name)
#
#
#func on_recipe_selected(station_id: String, recipe_id: String) -> void:
	#if station_id == _current_station and recipe_id == _current_recipe:
		#return
	#
	#if not _current_station.is_empty():
		#if unsaved_recipe or _current_station != station_id or recipe_id != _current_recipe:
			#save_current_recipe()
	#
	#_current_station = station_id
	#_current_recipe = recipe_id
	#
	#recipe_label.text = station_id + "/" + recipe_id
	#
	#if _items_resource.has_recipe(station_id, recipe_id):
		#var input_recipe: Array[Dictionary] = _items_resource.get_recipe_input(
				#station_id,
				#recipe_id)
		#var output_recipe: Array[Dictionary] = _items_resource.get_recipe_output(
				#station_id,
				#recipe_id)
		#
		#var input_size: int = input_recipe.size()
		#var output_size: int = output_recipe.size()
		#
		#input_recipe_spin_box.value = input_size
		#output_recipe_spin_box.value = output_size
		#
		#for input_idx in range(input_size):
			#input_recipe_tree.set_slot_recipe(
					#input_idx, 
					#input_recipe[input_idx]["item"],
					#input_recipe[input_idx]["count"])
		#for output_idx in range(output_size):
			#output_recipe_tree.set_slot_recipe(
					#output_idx, 
					#output_recipe[output_idx]["item"],
					#output_recipe[output_idx]["count"])
	#else:
		#input_recipe_spin_box.value = 0
		#output_recipe_spin_box.value = 0
#
#
#func change_recipe_size(new_size: float, target_tree: Tree) -> void:
	#target_tree.set_slot_count(new_size)
	#on_recipe_changed()
#
#
#func current_item_to_memory(bypass_unsaved: bool = false) -> void:
	#if not unsaved_item and not bypass_unsaved:
		#return
	#
	#if not item_memory.has(_current_id) or item_memory[_current_id] == null:
		#item_memory[_current_id] = ItemDefinition.new()
	#var item_def: ItemDefinition = item_memory[_current_id]
	#
	#item_def.item_id = _current_id
	#item_def.item_name = item_name_ln_edt.text
	#item_def.item_sprite = sprite_path_ln_edt.text
	#item_def.item_type = item_type_opt_btn.get_item_text(item_type_opt_btn.selected)
	#item_def.item_level = item_lvl_spn_btn.value
	#item_def.item_value = item_value_spn_bx.value
	#item_def.item_materials.assign(materials_tree.get_selected_materials())
	#item_def.item_flags = item_flag_tree.get_flags()
	#item_def.custom_data = custom_data_tree.get_custom_data()
	#
	#unsaved_item = false
#
#
#func load_item(item_id: String) -> bool:
	#if item_id == _current_id:
		#return true
	#
	#if not _current_id.is_empty():
		#current_item_to_memory()
	#
	#if item_memory.has(item_id):
		#var memory_item: ItemDefinition = item_memory[item_id]
		#item_name_ln_edt.text = memory_item.item_name
		#sprite_path_ln_edt.text = memory_item.item_sprite
		#select_type(memory_item.item_type)
		#item_lvl_spn_btn.value = memory_item.item_level
		#item_value_spn_bx.value = memory_item.item_value
		#materials_tree.uncheck_materials()
		#materials_tree.select_materials(memory_item.item_materials)
		#item_flag_tree.reset_flags()
		#item_flag_tree.set_flags(memory_item.item_flags)
		#custom_data_tree.clear_variables()
		#for c_data in memory_item.get_custom_data_keys():
			#custom_data_tree.add_variable(
					#c_data,
					#memory_item.get_custom_data(c_data))
		#return true
	#elif ResourceLoader.exists(_items_resource.get_item_path(item_id)):
		#var preload_resource: ItemDefinition = load(_items_resource.get_item_path(item_id))
		#item_name_ln_edt.text = preload_resource.item_name
		#sprite_path_ln_edt.text = preload_resource.item_sprite
		#select_type(preload_resource.item_type)
		#item_lvl_spn_btn.value = preload_resource.item_level
		#item_value_spn_bx.value = preload_resource.item_value
		#materials_tree.uncheck_materials()
		#materials_tree.select_materials(preload_resource.item_materials)
		#item_flag_tree.reset_flags()
		#item_flag_tree.set_flags(preload_resource.item_flags)
		#custom_data_tree.clear_variables()
		#for c_data in preload_resource.get_custom_data_keys():
			#custom_data_tree.add_variable(
					#c_data,
					#preload_resource.get_custom_data(c_data))
		#return true
	#return false
#
#
#func select_type(type_id: String) -> void:
	#if type_id.is_empty():
		#item_type_opt_btn.select(item_type_opt_btn.item_count - 1)
	#else:
		#for idx in range(item_type_opt_btn.item_count):
			#if item_type_opt_btn.get_item_text(idx) == type_id:
				#item_type_opt_btn.select(idx)
				#break
#
#
#func load_items() -> void:
	#item_tree.clear_items()
	#for item in _items_resource.get_item_ids():
		#item_tree.add_item(
				#item,
				#_items_resource.get_item_path(item)
				#)
#
#
#func load_materials() -> void:
	#materials_tree.clear_materials()
	#for mat in _items_resource.get_materials():
		#materials_tree.add_material(mat)
#
#
#func load_flags() -> void:
	#var flag_str: Array = _items_resource.ItemFlags.keys()
	#
	#item_flag_tree.clear_flags()
	#
	#for flag in _items_resource.ItemFlags.values():
		#item_flag_tree.add_flag(flag, Strings.capitalize(flag_str[flag]))
#
#
#func clear_item_fields() -> void:
	#item_name_ln_edt.clear()
	#sprite_path_ln_edt.clear()
	#search_data_ln_edt.clear()
	#item_type_opt_btn.select(item_type_opt_btn.item_count - 1)
	#on_type_selected(item_type_opt_btn.selected)
	#item_subtype_opt_btn.select(item_subtype_opt_btn.item_count - 1)
	#item_lvl_spn_btn.value = 0
	#item_value_spn_bx.value = 0
	#materials_tree.uncheck_materials()
	#item_flag_tree.reset_flags()
	#custom_data_tree.clear_variables()
#
#
#func on_item_id_pressed(item_id: String, item_path: String) -> void:
	#if loading_item:
		#return
	#
	#loading_item = true
	#
	#if load_item(item_id):
		#if not item_tree.is_selected(item_path):
			#item_tree.select_item(item_path)
	#else:
		#item_tree.deselect_all()
	#
	#_current_id = item_id
	#
	#loading_item = false
#
#
#func on_item_deleted(item_id: String, item_path: String) -> void:
	#_items_resource.remove_item(item_id)
	#
	#if _current_id == item_path:
		#clear_item_fields()
#
#
#func on_item_file_selected(file_path: String) -> void:
	#if item_file_dialog.file_mode == FileDialog.FileMode.FILE_MODE_SAVE_FILE: # Creating an new file
		#var new_item := ItemDefinition.new()
		#var file_name: String = file_path.get_file().get_basename()
		#var item_id := Strings.random_string(8, 4) if _items_resource.has_item(file_name) else file_name
		#ResourceSaver.save(new_item, file_path)
		#_items_resource.create_item(
				#item_id,
				#file_path)
		#if item_tree.has_file(file_path):
			#item_tree.select_by_file(file_path)
		#else:
			#item_tree.add_item(item_id, file_path)
			#on_item_id_pressed(item_id, file_path)
	#else: # Adding an existing file
		#if _items_resource.has_item_file(file_path):
			#return
		#
		#var res_preload: Resource = load(file_path)
		#
		#if res_preload is ItemDefinition:
			#var item_id: String = Strings.random_string(8, 4)
			#_items_resource.create_item(item_id, file_path)
			#item_tree.add_item(item_id, file_path)
		#else:
			#push_error("[DEPOT] Selected file isn't an ItemDefinition")
#
#
##func save_currencies() -> void:
	##var currency_dict: Dictionary = currencies_tree.get_currencies()
	##
	##_items_resource.clear_currencies()
	##
	##for currency_id in currency_dict:
		##_items_resource.create_currency(
				##currency_id,
				##currency_dict[currency_id]["name"],
				##currency_dict[currency_id]["value"])
#
#
#func save_items() -> void:
	#if not _current_id.is_empty():
		#current_item_to_memory(true)
	#
	#for item in item_memory:
		#ResourceSaver.save(item_memory[item], _items_resource.get_item_path(item))
	#
	#item_memory.clear()
#
#
#func on_save() -> void:
	#save_items()
	#
	#if not _current_station.is_empty() and not _current_recipe.is_empty():
		#save_current_recipe()
	#
	#_items_resource.save()
