@tool
extends HBoxContainer


signal resource_loaded
signal item_created(item_id: StringName, item_name: String)
signal item_renamed(item_id: StringName, new_name: String)
signal item_deleted(item_id: StringName)


var item_link: EditorItemRecipeLink = EditorItemRecipeLink.new():
	set(new_link):
		new_link.items = item_link.items
		item_link.items = null
		item_link = new_link
var currency_resource: CurrencyCatalog = null

var items_ui_enabled: bool = true
var currency_ui_enabled: bool = true
var loaded_item: StringName = &""
var current_category: StringName = &""
var loaded_currency: StringName = &""
var noncategory_loaded: bool = false

var _items_unsaved: bool = false
var _currency_unsaved: bool = false

@onready var search_item_container: LineEdit = $ItemsPanel/ItemsContainer/TreeContainer/ItemSearchContainer/SearchItemContainer
@onready var new_item_btn: Button = $ItemsPanel/ItemsContainer/TreeContainer/ItemSearchContainer/NewItemBtn
@onready var items_tree: Tree = $ItemsPanel/ItemsContainer/TreeContainer/ItemsTree
@onready var item_name_ln_edt: LineEdit = $ItemsPanel/ItemsContainer/DataContainer/NameContainer/ItemNameLnEdt
@onready var rarity_opt_btn: OptionButton = $ItemsPanel/ItemsContainer/DataContainer/RarityContainer/RarityContainer/RarityOptBtn
@onready var item_val_spn_bx: SpinBox = $ItemsPanel/ItemsContainer/DataContainer/ValueContainer/ItemValSpnBx
@onready var item_desc_txt_edt: TextEdit = $ItemsPanel/ItemsContainer/DataContainer/DescContainer/ItemDescTxtEdt
@onready var add_item_fldr_btn: Button = $ItemsPanel/ItemsContainer/DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddItemFldrBtn
@onready var add_item_int_btn: Button = $ItemsPanel/ItemsContainer/DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddItemIntBtn
@onready var add_item_float_btn: Button = $ItemsPanel/ItemsContainer/DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddItemFloatBtn
@onready var add_item_bool_btn: Button = $ItemsPanel/ItemsContainer/DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddItemBoolBtn
@onready var add_item_str_btn: Button = $ItemsPanel/ItemsContainer/DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddItemStrBtn
@onready var item_data_tree: Tree = $ItemsPanel/ItemsContainer/DataContainer/CustomDataContainer/ItemDataTree
@onready var items_flags_container: VBoxContainer = $ItemsPanel/ItemsContainer/FlagsContainer/ScrollContainer/ItemsFlagsContainer
@onready var categories_tree: Tree = $ItemsPanel/ItemsContainer/TreeContainer/VBoxContainer/CategoriesTree
@onready var category_srch_ln_edt: LineEdit = $ItemsPanel/ItemsContainer/TreeContainer/VBoxContainer/HBoxContainer/CategorySrchLnEdt
@onready var edit_rarities_btn: Button = $ItemsPanel/ItemsContainer/DataContainer/RarityContainer/RarityContainer/EditRaritiesBtn
@onready var edit_flags_btn: Button = $ItemsPanel/ItemsContainer/FlagsContainer/TitleVContainer/Label/EditFlagsBtn


# ------- Currencies -------
@onready var search_curr_ln_edt: LineEdit = $CurrencyPanel/CurrencyContainer/TreeContainer/HeaderContainer/SearchCurrLnEdt
@onready var create_currency_btn: Button = $CurrencyPanel/CurrencyContainer/TreeContainer/HeaderContainer/CreateCurrencyBtn
@onready var currency_tree: Tree = $CurrencyPanel/CurrencyContainer/TreeContainer/CurrencyTree
@onready var currency_name_ln_edt: LineEdit = $CurrencyPanel/CurrencyContainer/HBoxContainer/CurrencyNameLnEdt
@onready var currency_value_spn_bx: SpinBox = $CurrencyPanel/CurrencyContainer/HBoxContainer2/CurrencyValueSpnBx
@onready var add_curr_int_btn: Button = $CurrencyPanel/CurrencyContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCurrIntBtn
@onready var add_curr_flt_btn: Button = $CurrencyPanel/CurrencyContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCurrFltBtn
@onready var add_curr_bool_btn: Button = $CurrencyPanel/CurrencyContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCurrBoolBtn
@onready var add_curr_str_btn: Button = $CurrencyPanel/CurrencyContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCurrStrBtn
@onready var add_curr_dict_button: Button = $CurrencyPanel/CurrencyContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddDictButton
@onready var currency_custom_data_tree: Tree = $CurrencyPanel/CurrencyContainer/CustomDataContainer/CurrencyCustomDataTree

@onready var currencies_tee: Tree = $CurrencyPanel/CurrencyCalc/CurrenciesTee
@onready var reset_calculator_btn: Button = $CurrencyPanel/CurrencyCalc/HBoxContainer/ResetCalculatorBtn
@onready var value_ln_edt: LineEdit = $CurrencyPanel/CurrencyCalc/InfoContainer/ValueLnEdt
@onready var copy_val_btn: Button = $CurrencyPanel/CurrencyCalc/InfoContainer/CopyValBtn
@onready var return_currency_btn: Button = $CurrencyPanel/CurrencyCalc/ReturnCurrencyBtn
@onready var go_to_calc_btn: Button = $CurrencyPanel/CurrencyContainer/GoToCalcBtn

# --------------------------


func ready_plugin(use_items: bool, use_currencies: bool) -> void:
	category_srch_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	search_curr_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	edit_rarities_btn.icon = get_theme_icon("Edit", "EditorIcons")
	edit_flags_btn.icon = get_theme_icon("Edit", "EditorIcons")
	
	add_item_fldr_btn.icon = get_theme_icon("FolderCreate", "EditorIcons")
	add_curr_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	reset_calculator_btn.icon = get_theme_icon("Reload", "EditorIcons")
	copy_val_btn.icon = get_theme_icon("ActionCopy", "EditorIcons")
	
	
	if use_items:
		categories_tree.ready_plugin()
		items_tree.ready_plugin()
		item_data_tree.ready_plugin()
		reload_item_resource(true)
	if use_currencies:
		currency_tree.ready_plugin()
		currency_custom_data_tree.ready_plugin()
		currencies_tee.ready_plugin()
		reload_currency_resource(true)
	
	search_item_container.text_changed.connect(_on_search_item_text_changed)
	new_item_btn.pressed.connect(_on_create_item_pressed)
	items_tree.item_id_selected.connect(_on_item_selected, CONNECT_DEFERRED)
	items_tree.item_id_changed.connect(_on_item_id_changed, CONNECT_DEFERRED)
	items_tree.item_erased.connect(_on_item_erased, CONNECT_DEFERRED)
	item_name_ln_edt.text_changed.connect(_on_items_changed)
	rarity_opt_btn.item_selected.connect(_on_items_changed)
	item_val_spn_bx.value_changed.connect(_on_items_changed)
	item_desc_txt_edt.text_changed.connect(_on_items_changed)
	item_data_tree.data_changed.connect(_on_items_changed)
	categories_tree.category_selected.connect(_on_category_selected, CONNECT_DEFERRED)
	categories_tree.items_recategorized.connect(_on_items_recategorized, CONNECT_DEFERRED)
	item_name_ln_edt.focus_exited.connect(_on_item_name_focus_lost, CONNECT_DEFERRED)
	add_item_int_btn.pressed.connect(add_item_data.bind("new_int", 0))
	add_item_float_btn.pressed.connect(add_item_data.bind("new_float", 0.0))
	add_item_bool_btn.pressed.connect(add_item_data.bind("new_bool", false))
	add_item_str_btn.pressed.connect(add_item_data.bind("new_string", ""))
	add_item_fldr_btn.pressed.connect(add_item_data.bind("new_folder", {}))
	
	create_currency_btn.pressed.connect(_on_create_currency_pressed)
	currency_tree.currency_selected.connect(_on_currency_selected, CONNECT_DEFERRED)
	currency_tree.currency_id_changed.connect(_on_currency_id_changed)
	currency_tree.currency_deleted.connect(_on_currency_deleted)
	currency_name_ln_edt.text_changed.connect(_on_currency_changed)
	currency_value_spn_bx.value_changed.connect(_on_currency_value_changed, CONNECT_DEFERRED)
	
	add_curr_int_btn.pressed.connect(add_currency_data.bind("new_int", 0))
	add_curr_flt_btn.pressed.connect(add_currency_data.bind("new_float", 0.0))
	add_curr_bool_btn.pressed.connect(add_currency_data.bind("new_bool", false))
	add_curr_str_btn.pressed.connect(add_currency_data.bind("new_string", ""))
	add_curr_dict_button.pressed.connect(add_currency_data.bind("new_folder", {}))
	
	category_srch_ln_edt.text_changed.connect(_on_category_search_text_changed)
	search_curr_ln_edt.text_changed.connect(_on_currency_search_text_changed)
	edit_flags_btn.pressed.connect(_on_edit_flags_pressed)
	edit_rarities_btn.pressed.connect(_on_edit_rarities_pressed)
	
	currencies_tee.calculation_updated.connect(_on_calculation_updated)
	copy_val_btn.pressed.connect(_on_copy_value_button_pressed, CONNECT_DEFERRED)
	reset_calculator_btn.pressed.connect(_on_reset_calculator_pressed)
	return_currency_btn.pressed.connect(_on_return_calculator_button_pressed)
	go_to_calc_btn.pressed.connect(_on_go_to_calculator_pressed)


func _on_edit_rarities_pressed() -> void:
	var item_script: Script = ItemSheet.new().get_script()
	var source_code: String = item_script.source_code
	
	if source_code.is_empty():
		return
	
	var pattern: String = "enum\\s+Rarity\\s*\\{[^}]*\\}"
	var regex: RegEx = RegEx.new()
	regex.compile(pattern)
	
	var regex_match: RegExMatch = regex.search(source_code)
	
	if regex_match == null:
		return
	
	var match_start: int = regex_match.get_start()
	var match_string: String = regex_match.get_string()
	var brace_open_idx: int = match_start + match_string.find("{")
	var brace_close_index: int = regex_match.get_end() - 1
	
	var inner_length: int = brace_close_index - brace_open_idx - 1
	var inner_text: String = source_code.substr(brace_open_idx + 1, inner_length)
	var stripped_text: String = inner_text.strip_edges(false)
	
	var target_idx: int = brace_open_idx + stripped_text.length() + 1
	var text_before_target: String = source_code.substr(0, target_idx)
	
	var line: int  = text_before_target.count("\n") + 1
	var last_newline_idx: int = text_before_target.rfind("\n")
	var column: int = text_before_target.length() - last_newline_idx
	EditorInterface.edit_script(item_script, line, column)
	
	if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
		EditorInterface.set_main_screen_editor("Script")


func _on_edit_flags_pressed() -> void:
	var item_script: Script = ItemSheet.new().get_script()
	var source_code: String = item_script.source_code
	
	if source_code.is_empty():
		return
	
	var pattern: String = "enum\\s+ItemFlag\\s*\\{[^}]*\\}"
	var regex: RegEx = RegEx.new()
	regex.compile(pattern)
	
	var regex_match: RegExMatch = regex.search(source_code)
	
	if regex_match == null:
		return
	
	var match_start: int = regex_match.get_start()
	var match_string: String = regex_match.get_string()
	var brace_open_idx: int = match_start + match_string.find("{")
	var brace_close_index: int = regex_match.get_end() - 1
	
	var inner_length: int = brace_close_index - brace_open_idx - 1
	var inner_text: String = source_code.substr(brace_open_idx + 1, inner_length)
	var stripped_text: String = inner_text.strip_edges(false)
	
	var target_idx: int = brace_open_idx + stripped_text.length() + 1
	var text_before_target: String = source_code.substr(0, target_idx)
	
	var line: int  = text_before_target.count("\n") + 1
	var last_newline_idx: int = text_before_target.rfind("\n")
	var column: int = text_before_target.length() - last_newline_idx
	EditorInterface.edit_script(item_script, line, column)
	
	if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
		EditorInterface.set_main_screen_editor("Script")


#region Currencies

func _on_currency_search_text_changed(text: String) -> void:
	currency_tree.search_for(text.strip_edges())


func _on_create_currency_database_pressed(node: Control) -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_SAVE_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		currency_resource = CurrencyCatalog.new()
		currency_resource.resource_path = result[1]
		ResourceSaver.save(currency_resource, result[1])
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("currency"),
				result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		reload_categories()
		$CurrencyPanel/CurrencyContainer.visible = true
		node.visible = false
		node.queue_free()
	
	database_creator.queue_free()


func _on_load_currency_database_pressed(node: Control) -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_OPEN_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is CurrencyCatalog:
			currency_resource = res_pre
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("currency"),
					result[1])
			if Engine.is_editor_hint():
				ProjectSettings.save()
			reload_currency_resource()
			$CurrencyPanel/CurrencyContainer.visible = true
			node.visible = false
			node.queue_free()
	
	database_creator.queue_free()


func _on_currency_resource_dropped(resource: Resource, panel: Control) -> void:
	currency_resource = resource
	ProjectSettings.set_setting(
			NFPluginGameHandler.get_setting_path("currency"),
			resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	$CurrencyPanel/CurrencyContainer.visible = true
	reload_currency_resource()


func _on_create_currency_pressed() -> void:
	var id_creator := preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
	id_creator.line_placeholder_text = "Currency ID"
	id_creator.allow_empty = false
	id_creator.use_blacklist = true
	id_creator.character_blacklist.append(" ")
	id_creator.text_blacklist.assign(currency_tree.get_currencies())
	id_creator.title = "Create Currency"
	id_creator.ok_button_text = "Create"
	add_child(id_creator)
	id_creator.show()
	id_creator.grab_text_focus()
	
	var result = await id_creator.dialog_finished
	
	if result[0]:
		if not loaded_currency.is_empty():
			save_current_currency()
		
		var currency_id: StringName = StringName(result[1])
		currency_resource.create_currency(currency_id, 0, "New Currency")
		currency_tree.add_currency(currency_id, true, false)
		currencies_tee.add_currency(currency_id, "New Currency", 0)
		load_currency(currency_id)
		loaded_currency = currency_id
		set_currency_ui_enabled(true)
		_on_currency_changed()
	id_creator.queue_free()


func _on_currency_value_changed(new_value: int) -> void:
	if loaded_currency.is_empty():
		return
	
	currencies_tee.update_currency_value(loaded_currency, new_value)
	_on_currency_changed()


func _on_currency_deleted(currency_id: StringName) -> void:
	currency_resource.erase_currency(currency_id)
	
	if loaded_currency == currency_id:
		loaded_currency = &""
		currency_name_ln_edt.text = ""
		currency_value_spn_bx.set_value_no_signal(0)
		currency_custom_data_tree.clear_data()
		set_currency_ui_enabled(false)
	
	_on_currency_changed()


func _on_currency_id_changed(from: StringName, to: StringName) -> void:
	currency_resource._currencies[to] = currency_resource._currencies[from]
	currency_resource._currencies.erase(from)
	
	if loaded_currency == from:
		loaded_currency = to
	
	_on_currency_changed()


func _on_currency_selected(currency_id: StringName) -> void:
	if not loaded_currency.is_empty():
		save_current_currency()
	
	load_currency(currency_id)
	loaded_currency = currency_id
	set_currency_ui_enabled(true)


func reload_currency_resource(first_launch: bool = false) -> void:
	var was_null: bool = currency_resource == null
	currency_resource = null # Release
	#currency_resource = CurrencyCatalog.new() # Debug
	
	clear_currency_section()
	
	var currency_path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("currency"),
			"")
	
	if currency_path != "" and FileAccess.file_exists(currency_path):
		var res_pre: Resource = load(currency_path)
		if res_pre is CurrencyCatalog:
			currency_resource = res_pre
	
	$CurrencyPanel/CurrencyContainer.visible = currency_resource != null
	
	set_currency_ui_enabled(false)
	
	if currency_resource == null:
		if not was_null or first_launch:
			var no_db := preload("res://addons/nexus_forge/no_db_container.tscn").instantiate()
			$CurrencyPanel.add_child(no_db)
			no_db.message_minimum_size.x = 250.0
			no_db.set_resource_type("CurrencyCatalog", "Currency", "Currencies")
			no_db.create_resource_pressed.connect(_on_create_currency_database_pressed.bind(no_db))
			no_db.load_resource_pressed.connect(_on_load_currency_database_pressed.bind(no_db))
			no_db.resource_dropped.connect(_on_currency_resource_dropped.bind(no_db))
	else:
		for currency in currency_resource.currencies():
			currency_tree.add_currency(currency)
			currencies_tee.add_currency(
					currency,
					currency_resource.get_currency_name(currency),
					currency_resource.get_currency_value(currency))


func clear_currency_section() -> void:
	currency_tree.clear_currencies()
	currency_name_ln_edt.text = ""
	currency_value_spn_bx.set_value_no_signal(0)
	currency_custom_data_tree.clear_data()


func add_currency_data(data_key: String, data: Variant) -> void:
	currency_custom_data_tree.add_data(data_key, data)


func set_currency_ui_enabled(enabled: bool) -> void:
	if currency_ui_enabled == enabled:
		return
	var disabled: bool = not enabled
	currency_name_ln_edt.editable = enabled
	currency_value_spn_bx.editable = enabled
	
	add_curr_int_btn.disabled = disabled
	add_curr_flt_btn.disabled = disabled
	add_curr_bool_btn.disabled = disabled
	add_curr_str_btn.disabled = disabled
	add_curr_dict_button.disabled = disabled
	currency_custom_data_tree.enabled = enabled
	
	currency_ui_enabled = enabled


func load_currency(currency_id: StringName) -> void:
	currency_name_ln_edt.text = currency_resource.get_currency_name(currency_id)
	currency_value_spn_bx.set_value_no_signal(currency_resource.get_currency_value(currency_id))
	currency_custom_data_tree.clear_data()
	
	for data_key in currency_resource.currency_data_keys(currency_id):
		currency_custom_data_tree.add_data(
				data_key,
				currency_resource.get_currency_data(currency_id, data_key))


func save_current_currency() -> void:
	currency_resource.set_currency_name(
			loaded_currency,
			currency_name_ln_edt.text.strip_edges())
	currency_resource.set_currency_value(
			loaded_currency,
			int(currency_value_spn_bx.value))
	
	currency_resource.clear_currency_data(loaded_currency)
	
	var data: Dictionary[StringName, Variant] = {}
	data.assign(currency_custom_data_tree.get_data())
	
	for data_key in data.keys():
		currency_resource.set_currency_data(
				loaded_currency,
				data_key,
				data[data_key])

#endregion



func _on_go_to_calculator_pressed() -> void:
	$CurrencyPanel/CurrencyContainer.visible = false
	$CurrencyPanel/CurrencyCalc.visible = true


func _on_return_calculator_button_pressed() -> void:
	$CurrencyPanel/CurrencyContainer.visible = true
	$CurrencyPanel/CurrencyCalc.visible = false


func _on_reset_calculator_pressed() -> void:
	currencies_tee.reset_table()


func _on_calculation_updated(new_value: int) -> void:
	value_ln_edt.text = str(new_value)


func _on_copy_value_button_pressed() -> void:
	DisplayServer.clipboard_set(value_ln_edt.text)


func _on_category_search_text_changed(text: String) -> void:
	categories_tree.search_pattern(text.strip_edges())


func _on_item_name_focus_lost() -> void:
	var new_name: String = item_name_ln_edt.text.strip_edges()
	if loaded_item.is_empty() or item_link.items.get_item_name(loaded_item) == new_name:
		return
	item_link.item_renamed.emit(loaded_item, new_name)


func _on_items_recategorized(new_category: StringName, items: Array[StringName]):
	if new_category == current_category:
		return
	var clean: bool = false
	
	if loaded_item in items:
		save_current_item()
		clean = true
	
	for item in items:
		item_link.items.set_item_category(item, new_category)
	
	items_tree.remove_items(items)
	
	if clean:
		loaded_item = &""
		item_name_ln_edt.text = ""
		rarity_opt_btn.select(0 if 0 < rarity_opt_btn.item_count else -1)
		item_val_spn_bx.set_value_no_signal(0)
		item_desc_txt_edt.text = ""
		item_data_tree.clear_data()
		reset_flags()
		set_items_ui_enabled(false)


func _on_category_selected(category: StringName) -> void:
	if noncategory_loaded if category.is_empty() else current_category == category:
		return
	if not loaded_item.is_empty():
		save_current_item()
	clear_all_fields()
	loaded_item = &""
	current_category = category
	noncategory_loaded = category.is_empty()
	new_item_btn.disabled = false
	
	for item in item_link.items.items():
		if item_link.items.get_item_category(item) == category:
			items_tree.add_item(item)
	set_items_ui_enabled(false)


func _on_item_id_changed(from: StringName, to: StringName) -> void:
	if from == to:
		return
	item_link.change_item_id(from, to)
	if loaded_item == from:
		loaded_item = to


func _on_search_item_text_changed(text: String) -> void:
	items_tree.search_for(text.strip_edges())


func _on_create_database_pressed(node: Control) -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_SAVE_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		var item_resource: ItemCatalog = ItemCatalog.new()
		ResourceSaver.save(item_resource, result[1])
		item_resource.resource_path = result[1]
		item_link.items = item_resource
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("items"),
				result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		reload_categories()
		$ItemsPanel/ItemsContainer.visible = true
		node.visible = false
		node.queue_free()
		resource_loaded.emit()
	
	database_creator.queue_free()


func _on_load_database_pressed(node: Control) -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_OPEN_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is ItemCatalog:
			item_link.items = res_pre
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("items"),
					result[1])
			if Engine.is_editor_hint():
				ProjectSettings.save()
			reload_categories()
			$ItemsPanel/ItemsContainer.visible = true
			node.visible = false
			node.queue_free()
			resource_loaded.emit()
	
	database_creator.queue_free()


func _on_items_resource_dropped(resource: Resource, panel: Control) -> void:
	item_link.items = resource
	ProjectSettings.set_setting(
			NFPluginGameHandler.get_setting_path("items"),
			resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	$ItemsPanel/ItemsContainer.visible = true
	reload_categories()
	resource_loaded.emit()



func _on_item_selected(item_id: StringName) -> void:
	if loaded_item == item_id:
		return
	if not loaded_item.is_empty():
		save_current_item()
	load_item(item_id)
	loaded_item = item_id
	set_items_ui_enabled(true)


func _on_item_erased(item_id: StringName) -> void:
	item_link.erase_item(item_id)
	if loaded_item == item_id:
		loaded_item = &""
		item_name_ln_edt.text = ""
		item_desc_txt_edt.text = ""
		rarity_opt_btn.select(0 if 0 < rarity_opt_btn.item_count else -1)
		item_val_spn_bx.set_value_no_signal(0)
		item_data_tree.clear_data()
		reset_flags()
		set_items_ui_enabled(false)
	item_deleted.emit(item_id)
	_on_items_changed()


func _on_create_item_pressed() -> void:
	var id_creator := preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
	id_creator.line_placeholder_text = "Item ID"
	id_creator.allow_empty = false
	id_creator.use_blacklist = true
	id_creator.character_blacklist.append(" ")
	id_creator.text_blacklist.assign(item_link.items.items())
	id_creator.title = "Create Item"
	id_creator.ok_button_text = "Create"
	id_creator.error_line_blacklist_word_msg = "ID already used."
	id_creator.error_line_blacklist_character_msg = "Spaces disallowed"
	id_creator.error_line_empty_msg = "ID can't be empty"
	
	add_child(id_creator)
	id_creator.show()
	id_creator.grab_text_focus()
	
	var result = await id_creator.dialog_finished
	
	if result[0]:
		if not loaded_item.is_empty():
			save_current_item()
		
		var item_id: StringName = StringName(result[1])
		#item_resource.create_item(item_id)
		item_link.create_item(item_id)
		item_link.set_item_name(item_id, "New Item")
		items_tree.add_item(item_id, true, false)
		load_item(item_id)
		loaded_item = item_id
		set_items_ui_enabled(true)
		item_created.emit(item_id, "New Item")
		_on_items_changed()
	id_creator.queue_free()


func add_item_data(data_key: String, data: Variant) -> void:
	item_data_tree.add_data(data_key, data)


func set_items_ui_enabled(enabled: bool) -> void:
	if enabled == items_ui_enabled:
		return
	var disabled: bool = not enabled
	item_name_ln_edt.editable = enabled
	rarity_opt_btn.disabled = disabled
	item_val_spn_bx.editable = enabled
	item_desc_txt_edt.editable = enabled
	
	add_item_int_btn.disabled = disabled
	add_item_float_btn.disabled = disabled
	add_item_bool_btn.disabled = disabled
	add_item_str_btn.disabled = disabled
	add_item_fldr_btn.disabled = disabled
	item_data_tree.enabled = enabled
	
	for flag:CheckBox in items_flags_container.get_children():
		flag.disabled = disabled
	
	items_ui_enabled = enabled


func clear_all_fields() -> void:
	items_tree.clear_items()
	item_name_ln_edt.text = ""
	rarity_opt_btn.select(0 if 0 < rarity_opt_btn.item_count else -1)
	item_val_spn_bx.set_value_no_signal(0)
	item_desc_txt_edt.text = ""
	item_data_tree.clear_data()
	reset_flags()


func save_current_item() -> void:
	item_link.set_item_name(loaded_item, item_name_ln_edt.text.strip_edges())
	item_link.items.set_item_description(loaded_item, item_desc_txt_edt.text.strip_edges())
	item_link.items.set_item_category(loaded_item, current_category)
	if -1 < rarity_opt_btn.selected:
		item_link.items.set_item_rarity(loaded_item,  rarity_opt_btn.get_selected_metadata())
	else:
		item_link.items.set_item_rarity(loaded_item, 0)
	
	item_link.items.set_item_value(loaded_item, int(item_val_spn_bx.value))
	
	item_link.items.clear_item_data(loaded_item)
	
	var data: Dictionary[StringName, Variant] = {}
	data.assign(item_data_tree.get_data())
	
	for item_key in data.keys():
		item_link.items.set_item_data(loaded_item, item_key, data[item_key])
	
	var flags: Array[ItemSheet.ItemFlag] = []
	
	for flag:CheckBox in items_flags_container.get_children():
		if flag.button_pressed:
			flags.append(flag.get_meta(&"flag_value"))
	
	item_link.items.clear_item_flags(loaded_item)
	item_link.items.set_item_flags(loaded_item, flags, true)


func load_item(item_id: StringName) -> void:
	var item: ItemSheet = item_link.items.get_item(item_id)
	
	if item == null:
		printerr("[NexusForge] Depot: An error ocourred while trying to load item: ", item_id)
	
	item_name_ln_edt.text = item.name
	select_rarity(item.rarity)
	item_val_spn_bx.set_value_no_signal(item.value)
	item_desc_txt_edt.text = item.description
	
	item_data_tree.clear_data()
	
	for data_key in item.data.keys():
		item_data_tree.add_data(data_key, item.data[data_key])
	
	for flag:CheckBox in items_flags_container.get_children():
		flag.set_pressed_no_signal(
				item.flags.has(
						flag.get_meta(&"flag_value")))


func select_rarity(rarity: ItemSheet.Rarity) -> void:
	for item_idx in range(rarity_opt_btn.item_count):
		if rarity_opt_btn.get_item_metadata(item_idx) == rarity:
			rarity_opt_btn.select(item_idx)
			break


func _add_category_map(categories: Dictionary[StringName, Dictionary], target: TreeItem = categories_tree.get_root()) -> void:
	for top_category in categories.keys():
		var new_target: TreeItem = categories_tree.add_category(top_category, target)
		_add_category_map(categories[top_category], new_target)


func reload_item_resource(first_launch: bool = false) -> void:
	var was_null: bool = item_link.items == null
	item_link.items = null # Release
	item_name_ln_edt.text = ""
	item_desc_txt_edt.text = ""
	item_val_spn_bx.set_value_no_signal(0.0)
	item_data_tree.clear_data()
	
	var item_path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("items"),
			"")
	
	if item_path != "" and FileAccess.file_exists(item_path):
		var res_pre: Resource = load(item_path)
		if res_pre is ItemCatalog:
			item_link.items = res_pre
	
	$ItemsPanel/ItemsContainer.visible = item_link.items != null
	
	reload_fields()
	set_items_ui_enabled(false)
	
	if item_link.items == null:
		if not was_null or first_launch:
			var no_db := preload("res://addons/nexus_forge/no_db_container.tscn").instantiate()
			$ItemsPanel.add_child(no_db)
			no_db.message_minimum_size.x = 450.0
			no_db.set_resource_type("ItemCatalog", "Depot", "Items")
			no_db.create_resource_pressed.connect(_on_create_database_pressed.bind(no_db))
			no_db.load_resource_pressed.connect(_on_load_database_pressed.bind(no_db))
			no_db.resource_dropped.connect(_on_items_resource_dropped.bind(no_db))
			new_item_btn.disabled = true
	else:
		reload_categories()
		resource_loaded.emit()


func reload_categories(reselect: bool = false) -> void:
	var item_selected: bool = categories_tree.get_selected() != null
	
	categories_tree.clear_categories()
	
	var top_level_categories: Array[StringName] = []
	
	for category in item_link.items.categories():
		if item_link.items.get_category_parent(category) == &"":
			top_level_categories.append(category)
	
	for category in top_level_categories:
		var subcategories: Dictionary[StringName, Dictionary] = item_link.items.get_subcategories_of(category)
		
		_add_category_map(subcategories)
	
	categories_tree.add_category(&"")
	var new_selection: TreeItem = categories_tree.get_category(current_category) if item_selected else null
	
	if reselect and new_selection != null:
		categories_tree.select_no_singal(new_selection)
	else:
		current_category = &""
		clear_all_fields()
		new_item_btn.disabled = true


func reload_fields() -> void:
	var constant_map: Dictionary = ItemSheet.new().get_script().get_script_constant_map()
	
	if constant_map.has(&"Rarity"):
		var rarities: Dictionary = constant_map[&"Rarity"]
		var selected_rarity: int = -1 if rarity_opt_btn.selected == -1 else rarity_opt_btn.get_selected_metadata()
		var new_index: int = -1
		rarity_opt_btn.clear()
		var idx: int = -1
		for rarity:String in rarities.keys():
			idx += 1
			rarity_opt_btn.add_item(rarity.capitalize())
			rarity_opt_btn.set_item_metadata(-1, rarities[rarity])
			if selected_rarity == rarities[rarity]:
				new_index = idx
		
		if new_index != -1:
			rarity_opt_btn.select(new_index)
	else:
		rarity_opt_btn.clear()
	
	rarity_opt_btn.disabled = rarity_opt_btn.item_count == 0 or not items_ui_enabled
	
	if constant_map.has(&"ItemFlag"):
		var item_flags: Dictionary = constant_map[&"ItemFlag"]
		var sorted_flags: Array = item_flags.keys()
		sorted_flags.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
		
		var existing_flags: Dictionary[String, CheckBox] = {}
		
		for existing_flag in items_flags_container.get_children():
			if sorted_flags.has(existing_flag.get_meta(&"flag_id")):
				existing_flags[existing_flag.get_meta(&"flag_id")] = existing_flag
				items_flags_container.remove_child(existing_flag)
			else:
				items_flags_container.remove_child(existing_flag)
				existing_flag.queue_free()
			
		for flag in sorted_flags:
			if existing_flags.has(flag):
				items_flags_container.add_child(existing_flags[flag])
				existing_flags.erase(flag)
			else:
				items_flags_container.add_child(
						create_flag_item(flag, item_flags[flag]))
		
		for remaining_flag in existing_flags.keys():
			existing_flags[remaining_flag].queue_free()


func _on_items_changed(arg = null) -> void:
	if _items_unsaved:
		return
	_items_unsaved = true


func _on_currency_changed(arg = null) -> void:
	if _currency_unsaved:
		return
	_currency_unsaved = true


func create_flag_item(flag_id: String, flag_value: ItemSheet.ItemFlag) -> CheckBox:
	var new_flag: CheckBox = CheckBox.new()
	new_flag.text = flag_id.capitalize()
	new_flag.set_meta(&"flag_value", flag_value)
	new_flag.set_meta(&"flag_id", flag_id)
	new_flag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	new_flag.tooltip_text = new_flag.text
	new_flag.custom_minimum_size.y = 32.0
	new_flag.disabled = not items_ui_enabled
	new_flag.toggled.connect(_on_items_changed)
	
	return new_flag


func reset_flags() -> void:
	for item:CheckBox in items_flags_container.get_children():
		item.set_pressed_no_signal(false)
