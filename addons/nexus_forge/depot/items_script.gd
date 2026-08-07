@tool
extends HBoxContainer


signal resource_loaded
signal item_created(item_id: StringName, item_name: String)
signal item_renamed(item_id: StringName, new_name: String)
signal item_deleted(item_id: StringName)


const PAGE_LABEL_STRING: String = "%d / %d"

var item_link: EditorItemRecipeLink = EditorItemRecipeLink.new():
	set(new_link):
		new_link.items = item_link.items
		item_link.items = null
		item_link = new_link
var currency_resource: CurrencyCatalog = null

var items_ui_enabled: bool = true
var currency_ui_enabled: bool = true
var loaded_item: StringName = &"":
	set(i):
		loaded_item = i
		item_id_label.text = String(i)
		item_id_label.tooltip_text = item_id_label.text
var loaded_currency: StringName = &""
var noncategory_loaded: bool = false

var undo: UndoRedo
var exp_parser: Expression = null

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
@onready var edit_rarities_btn: Button = $ItemsPanel/ItemsContainer/DataContainer/RarityContainer/RarityContainer/EditRaritiesBtn
@onready var edit_flags_btn: Button = $ItemsPanel/ItemsContainer/FlagsContainer/TitleVContainer/Label/EditFlagsBtn

@onready var item_page_container: HBoxContainer = $ItemsPanel/ItemsContainer/TreeContainer/ItemPageContainer
@onready var category_opt_btn: OptionButton = $ItemsPanel/ItemsContainer/DataContainer/CategoryContainer/OptBtnContainer/CategoryOptBtn
@onready var edit_categories_btn: Button = $ItemsPanel/ItemsContainer/DataContainer/CategoryContainer/OptBtnContainer/EditCategoriesBtn
@onready var item_search_debounce: Timer = $ItemSearchDebounce
@onready var prev_item_page_btn: Button = $ItemsPanel/ItemsContainer/TreeContainer/ItemPageContainer/PrevItemPageBtn
@onready var item_page_lbl: Label = $ItemsPanel/ItemsContainer/TreeContainer/ItemPageContainer/ItemPageLbl
@onready var next_item_page_btn: Button = $ItemsPanel/ItemsContainer/TreeContainer/ItemPageContainer/NextItemPageBtn
@onready var item_id_label: Label = $ItemsPanel/ItemsContainer/DataContainer/ItemIDLabel


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

@onready var currencies_calculator_tree: Tree = $CurrencyPanel/CurrencyCalc/CurrenciesTee
@onready var reset_calculator_btn: Button = $CurrencyPanel/CurrencyCalc/HBoxContainer/ResetCalculatorBtn
@onready var value_ln_edt: LineEdit = $CurrencyPanel/CurrencyCalc/InfoContainer/ValueLnEdt
@onready var copy_val_btn: Button = $CurrencyPanel/CurrencyCalc/InfoContainer/CopyValBtn
@onready var return_currency_btn: Button = $CurrencyPanel/CurrencyCalc/ReturnCurrencyBtn
@onready var go_to_calc_btn: Button = $CurrencyPanel/CurrencyContainer/GoToCalcBtn

# --------------------------


func ready_plugin(use_items: bool, use_currencies: bool, max_undo_steps: int) -> void:
	exp_parser = Expression.new()
	
	search_curr_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	edit_rarities_btn.icon = get_theme_icon("Edit", "EditorIcons")
	edit_flags_btn.icon = get_theme_icon("Edit", "EditorIcons")
	
	add_item_fldr_btn.icon = get_theme_icon("FolderCreate", "EditorIcons")
	add_curr_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	reset_calculator_btn.icon = get_theme_icon("Reload", "EditorIcons")
	copy_val_btn.icon = get_theme_icon("ActionCopy", "EditorIcons")
	
	next_item_page_btn.icon = get_theme_icon("Forward", "EditorIcons")
	prev_item_page_btn.icon = get_theme_icon("Back", "EditorIcons")
	
	if use_items:
		new_item_btn.disabled = false
		items_tree.ready_plugin()
		item_data_tree.ready_plugin()
		reload_item_resource(true)
	if use_currencies:
		undo = UndoRedo.new()
		currency_tree.ready_plugin()
		currency_custom_data_tree.ready_plugin()
		currencies_calculator_tree.ready_plugin()
		reload_currency_resource(true)
	
	item_search_debounce.timeout.connect(_on_search_item_debounce_timeout)
	prev_item_page_btn.pressed.connect(_on_prev_page_btn_pressed)
	next_item_page_btn.pressed.connect(_on_next_page_btn_pressed)
	search_item_container.text_changed.connect(_on_search_item_text_changed)
	new_item_btn.pressed.connect(_on_create_item_pressed)
	items_tree.pagination_changed.connect(_on_tree_pagination_changed)
	items_tree.item_id_selected.connect(_on_item_selected, CONNECT_DEFERRED)
	items_tree.item_id_changed.connect(_on_item_id_changed, CONNECT_DEFERRED)
	items_tree.item_erased.connect(_on_item_erased, CONNECT_DEFERRED)
	item_name_ln_edt.text_changed.connect(_on_items_changed)
	item_name_ln_edt.editing_toggled.connect(_on_item_name_edit_toggled)
	rarity_opt_btn.item_selected.connect(_on_rarity_selected)
	item_val_spn_bx.value_changed.connect(_on_item_value_changed)
	item_val_spn_bx.set_drag_forwarding(Callable(), _item_val_can_drop_data, _on_item_val_drop_data)
	item_desc_txt_edt.text_changed.connect(_on_items_changed)
	item_desc_txt_edt.focus_exited.connect(_on_item_description_focus_exited)
	
	category_opt_btn.item_selected.connect(_on_new_category_selected)
	
	currency_custom_data_tree.data_changed.connect(_on_currency_data_changed)
	item_data_tree.data_changed.connect(_on_item_data_changed)
	
	add_item_int_btn.pressed.connect(add_item_data.bind("new_int", 0))
	add_item_float_btn.pressed.connect(add_item_data.bind("new_float", 0.0))
	add_item_bool_btn.pressed.connect(add_item_data.bind("new_bool", false))
	add_item_str_btn.pressed.connect(add_item_data.bind("new_string", ""))
	add_item_fldr_btn.pressed.connect(add_item_data.bind("new_folder", {}))
	
	currency_name_ln_edt.editing_toggled.connect(_on_currency_name_edit_toggled)
	
	create_currency_btn.pressed.connect(_on_create_currency_pressed)
	currency_tree.currency_selected.connect(_on_currency_selected, CONNECT_DEFERRED)
	currency_tree.currency_id_changed.connect(_on_currency_id_changed)
	currency_tree.currency_deleted.connect(_on_currency_deleted)
	currency_name_ln_edt.text_changed.connect(_on_currency_changed)
	currency_value_spn_bx.value_changed.connect(_on_currency_value_changed)
	
	add_curr_int_btn.pressed.connect(add_currency_data.bind("new_int", 0))
	add_curr_flt_btn.pressed.connect(add_currency_data.bind("new_float", 0.0))
	add_curr_bool_btn.pressed.connect(add_currency_data.bind("new_bool", false))
	add_curr_str_btn.pressed.connect(add_currency_data.bind("new_string", ""))
	add_curr_dict_button.pressed.connect(add_currency_data.bind("new_folder", {}))
	
	search_curr_ln_edt.text_changed.connect(_on_currency_search_text_changed)
	edit_flags_btn.pressed.connect(_on_edit_flags_pressed)
	edit_rarities_btn.pressed.connect(_on_edit_rarities_pressed)
	currencies_calculator_tree.calculation_updated.connect(_on_calculation_updated)
	copy_val_btn.pressed.connect(_on_copy_value_button_pressed, CONNECT_DEFERRED)
	copy_val_btn.set_drag_forwarding(_get_copy_button_drag_data, Callable(), Callable())
	reset_calculator_btn.pressed.connect(_on_reset_calculator_pressed)
	return_currency_btn.pressed.connect(_on_return_calculator_button_pressed)
	go_to_calc_btn.pressed.connect(_on_go_to_calculator_pressed, CONNECT_DEFERRED)
	
	value_ln_edt.set_drag_forwarding(_get_copy_button_drag_data, Callable(), Callable())


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


func _on_next_page_btn_pressed() -> void:
	if item_search_debounce.is_stopped() and items_tree.has_next_page():
		items_tree.next_page()
		update_page_buttons()
		update_page_label()


func _on_prev_page_btn_pressed() -> void:
	if item_search_debounce.is_stopped() and items_tree.has_previous_page():
		items_tree.previous_page()
		update_page_buttons()
		update_page_label()


func _on_tree_pagination_changed() -> void:
	if 1 < items_tree.last_page:
		if not item_page_container.visible:
			item_page_container.visible = true
		update_page_label()
		update_page_buttons()
	else:
		item_page_container.visible = false



func update_page_label() -> void:
	if not item_search_debounce.is_stopped():
		await item_search_debounce.timeout
	item_page_lbl.text = PAGE_LABEL_STRING % [items_tree.current_page, items_tree.last_page]


func update_category_id(from: StringName, to: StringName) -> void:
	for idx in range(category_opt_btn.item_count):
		if category_opt_btn.get_item_metadata(idx) == from:
			category_opt_btn.set_item_metadata(idx, to)
			category_opt_btn.set_item_text(idx, String(to).capitalize())
			break


func update_page_buttons() -> void:
	if not item_search_debounce.is_stopped():
		await item_search_debounce.timeout
	prev_item_page_btn.disabled = not items_tree.has_previous_page()
	next_item_page_btn.disabled = not items_tree.has_next_page()


#region Currencies

func _on_currency_search_text_changed(text: String) -> void:
	currency_tree.search_for(text.strip_edges())


func _on_create_currency_database_pressed(node: Control) -> void:
	var database_creator: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
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
	var database_creator: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
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
		currencies_calculator_tree.add_currency(currency_id, "New Currency", 0)
		load_currency(currency_id)
		loaded_currency = currency_id
		set_currency_ui_enabled(true)
		_on_currency_changed()
	id_creator.queue_free()


func _on_currency_value_changed(new_value: int) -> void:
	if loaded_currency.is_empty():
		return
	
	var old_value: int = currency_value_spn_bx.get_meta(&"old_value")
	
	currency_value_spn_bx.set_meta(&"old_value", new_value)
	
	undo.create_action("Set '%s' Currency Value" % loaded_currency)
	undo.add_do_method(_do_update_currency_value.bind(loaded_currency, new_value))
	undo.add_undo_method(_do_update_currency_value.bind(loaded_currency, old_value))
	undo.commit_action(false)
	
	_on_currency_changed()


func _do_update_currency_value(currency_id: StringName, new_value: int) -> void:
	if loaded_currency != currency_id:
		currency_tree.select_currency(currency_id, false)
		switch_to_currency(currency_id)
	currency_value_spn_bx.set_value_no_signal(new_value)
	currency_value_spn_bx.set_meta(&"old_value", new_value)


func _on_currency_deleted(currency_id: StringName) -> void:
	var current: bool = loaded_currency == currency_id
	var curr_name: String = currency_name_ln_edt.text.strip_edges() if current else currency_resource.get_currency_name(currency_id)
	var curr_val: int = _parse_value(currency_value_spn_bx.get_line_edit().text, currency_value_spn_bx.value) if current else currency_resource.get_currency_value(currency_id)
	var curr_data: Dictionary[String, Variant] = currency_custom_data_tree.get_data() if current else currency_resource._currencies[currency_id]["custom_data"].duplicate(true)
	
	var currency_data: Dictionary = {
		"name": curr_name,
		"value": curr_val,
		"metadata": curr_data}
	
	currency_resource.erase_currency(currency_id)
	currencies_calculator_tree.remove_currency(currency_id)
	
	if loaded_currency == currency_id:
		loaded_currency = &""
		currency_name_ln_edt.text = ""
		currency_value_spn_bx.set_value_no_signal(0)
		currency_custom_data_tree.clear_data(false)
		set_currency_ui_enabled(false)
	
	undo.create_action("Erase '%s' Currency" % currency_id)
	undo.add_do_method(_do_erase_currency.bind(currency_id))
	undo.add_undo_method(_undo_erase_currency.bind(currency_id, currency_data))
	undo.commit_action(false)
	
	_on_currency_changed()


func _undo_erase_currency(currency_id: StringName, currency_data: Dictionary) -> void:
	currency_resource.create_currency(
			currency_id,
			currency_data["value"],
			currency_data["name"])
	currency_resource._currencies[currency_id]["custom_data"].assign(
			currency_data["metadata"].duplicate(true))
	
	if currency_tree._add_currency_to_tree(currency_id):
		currencies_calculator_tree.add_currency(
				currency_id,
				currency_data["name"],
				currency_data["value"])
	else:
		NFPluginGameHandler._log_msg(
				"depot - editor",
				"Couldn't restore currency '%s' on editor." % currency_id,
				NFPluginGameHandler._LogLevel.ERROR)


func _do_erase_currency(currency_id: StringName) -> void:
	currency_resource.erase_currency(currency_id)
	currency_tree.erase_currency(currency_id)
	currencies_calculator_tree.remove_currency(currency_id)
	if loaded_currency == currency_id:
		loaded_currency = &""
		currency_name_ln_edt.text = ""
		currency_value_spn_bx.set_value_no_signal(0)
		currency_custom_data_tree.clear_data(false)
		set_currency_ui_enabled(false)


func _on_currency_id_changed(from: StringName, to: StringName) -> void:
	currency_resource._currencies[to] = currency_resource._currencies[from]
	currency_resource._currencies.erase(from)
	
	if loaded_currency == from:
		loaded_currency = to
	
	undo.create_action("Set Currency ID")
	undo.add_do_method(_do_change_currency_id.bind(from, to))
	undo.add_undo_method(_do_change_currency_id.bind(to, from))
	undo.commit_action(false)
	
	_on_currency_changed()


func _do_change_currency_id(from: StringName, to: StringName) -> void:
	currency_resource._currencies[to] = currency_resource._currencies[from]
	currency_resource._currencies.erase(from)
	if loaded_currency == from:
		loaded_currency = to
	currency_tree.change_currency_id(from, to)
	


func _on_currency_selected(currency_id: StringName) -> void:
	if not loaded_currency.is_empty():
		save_current_currency()
	switch_to_currency(currency_id)


func switch_to_currency(currency_id: StringName) -> void:
	load_currency(currency_id)
	loaded_currency = currency_id
	set_currency_ui_enabled(true)


func reload_currency_resource(first_launch: bool = false) -> void:
	var was_null: bool = currency_resource == null
	currency_resource = null
	
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
			currencies_calculator_tree.add_currency(
					currency,
					currency_resource.get_currency_name(currency),
					currency_resource.get_currency_value(currency))


func clear_currency_section() -> void:
	currency_tree.clear_currencies()
	currency_name_ln_edt.text = ""
	currency_value_spn_bx.set_value_no_signal(0)
	currency_custom_data_tree.clear_data(false)


func add_currency_data(data_key: String, data: Variant) -> void:
	currency_custom_data_tree.add_data(data_key, data)
	_on_currency_changed()


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
	var currency_value: int = currency_resource.get_currency_value(currency_id)
	currency_name_ln_edt.text = currency_resource.get_currency_name(currency_id)
	currency_value_spn_bx.set_value_no_signal(currency_value)
	currency_value_spn_bx.set_meta(&"old_value", currency_value)
	currency_custom_data_tree.clear_data(false)
	
	for data_key in currency_resource.currency_data_keys(currency_id):
		currency_custom_data_tree.add_data(
				data_key,
				currency_resource.get_currency_data(currency_id, data_key),
				true)


func save_current_currency() -> void:
	var value: int = _parse_value(
			currency_value_spn_bx.get_line_edit().text,
			currency_value_spn_bx.value)
	currency_resource.set_currency_name(
			loaded_currency,
			currency_name_ln_edt.text.strip_edges())
	currency_resource.set_currency_value(
			loaded_currency,
			value)
	
	currency_resource.clear_currency_data(loaded_currency)
	
	var data: Dictionary[StringName, Variant] = {}
	data.assign(currency_custom_data_tree.get_data())
	
	for data_key in data.keys():
		currency_resource.set_currency_data(
				loaded_currency,
				data_key,
				data[data_key])

#endregion


func sync_calculator_currencies() -> void:
	if not loaded_currency.is_empty():
		save_current_currency()
	for currency_id in currency_resource.currencies():
		currencies_calculator_tree.set_currency(
				currency_id,
				currency_resource.get_currency_name(currency_id),
				currency_resource.get_currency_value(currency_id))


func _on_go_to_calculator_pressed() -> void:
	sync_calculator_currencies()
	$CurrencyPanel/CurrencyContainer.visible = false
	$CurrencyPanel/CurrencyCalc.visible = true


func _on_return_calculator_button_pressed() -> void:
	$CurrencyPanel/CurrencyContainer.visible = true
	$CurrencyPanel/CurrencyCalc.visible = false


func _on_reset_calculator_pressed() -> void:
	currencies_calculator_tree.reset_table()


func _on_calculation_updated(new_value: int) -> void:
	value_ln_edt.text = str(new_value)


func _get_copy_button_drag_data(_at_position: Vector2) -> Variant:
	var val_label: Label = Label.new()
	val_label.text = "   " + value_ln_edt.text
	set_drag_preview(val_label)
	return value_ln_edt.text.to_int()


func _on_item_val_drop_data(at_position: Vector2, data: Variant) -> void:
	item_val_spn_bx.value = data


func _item_val_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not item_val_spn_bx.editable:
		return false
	match typeof(data):
		TYPE_INT, TYPE_FLOAT:
			return true
		_:
			return false


func _on_copy_value_button_pressed() -> void:
	DisplayServer.clipboard_set(value_ln_edt.text)


func _on_item_name_edit_toggled(is_toggled: bool) -> void:
	if is_toggled:
		return
	
	var old_name: String = item_name_ln_edt.get_meta(&"old_value")
	var new_name: String = item_name_ln_edt.text.strip_edges()
	
	if new_name == old_name:
		return
	
	undo.create_action("Set '%s' Item Name" % loaded_item)
	undo.add_do_method(_do_update_item_name.bind(loaded_item, new_name))
	undo.add_undo_method(_do_update_item_name.bind(loaded_item, old_name))
	undo.commit_action(false)
	
	item_link.item_renamed.emit(loaded_item, new_name)
	_on_items_changed()


func _do_update_item_name(item_id: StringName, new_name: String) -> void:
	if loaded_item != item_id:
		items_tree.select_item(item_id, false)
		switch_to_item(item_id)
	item_name_ln_edt.text = new_name
	item_name_ln_edt.set_meta(&"old_value", new_name)
	item_link.item_renamed.emit(item_id, new_name)


func _on_currency_name_edit_toggled(is_toggled: bool) -> void:
	if is_toggled:
		return
	
	var old_name: String = currency_name_ln_edt.get_meta(&"old_value")
	var new_name: String = currency_name_ln_edt.text.strip_edges()
	
	if new_name == old_name:
		return
	
	currency_name_ln_edt.set_meta(&"old_value", new_name)
	
	undo.create_action("Set '%s' Currency Name" % loaded_currency)
	undo.add_do_method(_do_rename_currency.bind(loaded_currency, new_name))
	undo.add_undo_method(_do_rename_currency.bind(loaded_currency, old_name))
	undo.commit_action(false)
	_on_currency_changed()


func _do_rename_currency(currency_id: StringName, new_name: String) -> void:
	if currency_id != loaded_currency:
		currency_tree.select_currency(currency_id, false)
		switch_to_currency(currency_id)
	
	currency_name_ln_edt.text = new_name
	currency_name_ln_edt.set_meta(&"old_value", new_name)


func _on_item_description_focus_exited() -> void:
	var old_desc: String = item_desc_txt_edt.get_meta(&"old_value")
	
	if item_desc_txt_edt.text == old_desc:
		return
	var new_desc: String = item_desc_txt_edt.text
	
	item_desc_txt_edt.set_meta(&"old_value", new_desc)
	
	undo.create_action("Set '%s' Item Description" % loaded_item)
	undo.add_do_method(_do_update_description.bind(loaded_item, new_desc))
	undo.add_undo_method(_do_update_description.bind(loaded_item, old_desc))
	undo.commit_action(false)
	
	_on_items_changed()


func _do_update_description(item_id: StringName, new_desc: String) -> void:
	if loaded_item != item_id:
		switch_to_item(item_id)
		items_tree.select_item(item_id, false)
	item_desc_txt_edt.text = new_desc
	item_desc_txt_edt.set_meta(&"old_value", new_desc)


func _on_new_category_selected(idx: int) -> void:
	var new_value: StringName = category_opt_btn.get_item_metadata(idx)
	var old_value: StringName = category_opt_btn.get_meta(&"old_value")
	
	if new_value == old_value:
		return
	
	category_opt_btn.set_meta(&"old_value", new_value)
	
	undo.create_action("Set '%s' Item Category" % loaded_item)
	undo.add_do_method(_do_update_category.bind(loaded_item, new_value))
	undo.add_undo_method(_do_update_category.bind(loaded_item, old_value))
	undo.commit_action(false)
	
	_on_items_changed()


func _do_update_category(item_id: StringName, category: StringName) -> void:
	if loaded_item != item_id:
		switch_to_item(item_id)
		items_tree.select_item(item_id, false)
	
	if not select_category(category, true):
		NFPluginGameHandler._log_msg(
				"depot - editor",
				"Tried to undo select to a non-existing category '%s'. Selecting (uncategorized)" % category,
				NFPluginGameHandler._LogLevel.EDITOR)


func _on_rarity_selected(idx: int) -> void:
	var old_value: int = rarity_opt_btn.get_meta(&"old_value")
	var new_value: int = rarity_opt_btn.get_item_metadata(idx)
	
	if new_value == old_value:
		return
	
	rarity_opt_btn.set_meta(&"old_value", new_value)
	
	undo.create_action("Set '%s' Item Rarity" % loaded_item)
	undo.add_do_method(_do_update_rarity.bind(loaded_item, new_value))
	undo.add_undo_method(_do_update_rarity.bind(loaded_item, old_value))
	undo.commit_action(false)
	
	_on_items_changed()


func _do_update_rarity(item_id: StringName, rarity: int) -> void:
	if loaded_item != item_id:
		switch_to_item(item_id)
		items_tree.select_item(item_id, false)
	select_rarity(rarity)


func _on_item_value_changed(new_value: int) -> void:
	var old_value: int = item_val_spn_bx.get_meta(&"old_value")
	
	item_val_spn_bx.set_meta(&"old_value", new_value)
	
	undo.create_action("Set '%s' Item Value" % loaded_item)
	undo.add_do_method(_do_update_item_value.bind(loaded_item, new_value))
	undo.add_undo_method(_do_update_item_value.bind(loaded_item, old_value))
	undo.commit_action(false)
	
	_on_items_changed()


func _do_update_item_value(item_id: StringName, new_value: int) -> void:
	if loaded_item != item_id:
		switch_to_item(item_id)
		items_tree.select_item(item_id, false)
	item_val_spn_bx.set_value_no_signal(new_value)
	item_val_spn_bx.set_meta(&"old_value", new_value)


func _on_item_data_changed() -> void:
	if item_data_tree.has_undo():
		undo.create_action("Item Data Changed")
		undo.add_do_method(_do_update_item_data.bind(loaded_item, false))
		undo.add_undo_method(_do_update_item_data.bind(loaded_item, true))
		undo.commit_action(false)
	_on_items_changed()


func _do_update_item_data(item_id: StringName, is_undo: bool) -> void:
	if loaded_item != item_id:
		items_tree.select_item(item_id, false)
		switch_to_item(item_id)
	
	if is_undo:
		item_data_tree.undo()
	else:
		item_data_tree.redo()


func _on_item_id_changed(from: StringName, to: StringName) -> void:
	if from == to:
		return
	item_link.change_item_id(from, to)
	if loaded_item == from:
		loaded_item = to


func _on_search_item_text_changed(text: String) -> void:
	item_search_debounce.start()


func _on_search_item_debounce_timeout() -> void:
	var result: Dictionary = _parse_search_query(search_item_container.text)
	items_tree.search_for(result["text"], result["category"])


func _parse_search_query(query: String) -> Dictionary:
	var result = {
		"text": "",
		"category": ""}
	
	var name_prefix: String = "name:"
	var category_prefix: String = "category:"
	
	var cat_idx: int = query.find(category_prefix)
	if cat_idx == -1:
		cat_idx = query.find("c:")
		category_prefix = "c:"
	var name_idx: int = query.find(name_prefix)
	if name_idx == -1:
		name_idx = query.find("n:")
		name_prefix = "n:"
	
	# If neither tag is present, the whole query is just the item text.
	if cat_idx == -1 and name_idx == -1:
		result["text"] = query.strip_edges()
	elif cat_idx == -1:
		result["text"] = query.substr(name_idx, -1).trim_prefix(name_prefix).strip_edges()
	elif name_idx == -1:
		if 0 < cat_idx:
			result["text"] = query.substr(0, cat_idx).strip_edges()
		result["category"] = query.substr(cat_idx, -1).trim_prefix(category_prefix).strip_edges()
	else:
		if cat_idx < name_idx:
			result["category"] = query.substr(cat_idx, name_idx - cat_idx).trim_prefix(category_prefix).strip_edges()
			result["text"] = query.substr(name_idx, -1).trim_prefix(name_prefix).strip_edges()
		else:
			result["text"] = query.substr(name_idx, cat_idx - name_idx).trim_prefix(name_prefix).strip_edges()
			result["category"] = query.substr(cat_idx, -1).trim_prefix(category_prefix).strip_edges()
	
	return result


func _on_create_database_pressed(node: Control) -> void:
	var database_creator: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
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
	var database_creator: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
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
	switch_to_item(item_id)


func switch_to_item(item_id: StringName) -> void:
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
		item_data_tree.clear_data(false)
		reset_flags()
		set_items_ui_enabled(false)
	update_page_label()
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
	id_creator.popup_centered()
	id_creator.grab_text_focus()
	
	var result = await id_creator.dialog_finished
	
	id_creator.queue_free()
	
	if not result[0]:
		return
	
	if not loaded_item.is_empty():
		save_current_item()
	
	var item_id: StringName = StringName(result[1])
	
	item_link.create_item(item_id)
	item_link.set_item_name(item_id, "New Item")
	items_tree.add_item(item_id)
	items_tree.select_item(item_id, false)
	load_item(item_id)
	loaded_item = item_id
	set_items_ui_enabled(true)
	item_created.emit(item_id, "New Item")
	_on_items_changed()


func add_item_data(data_key: String, data: Variant) -> void:
	item_data_tree.add_data(data_key, data)
	_on_items_changed()


func set_items_ui_enabled(enabled: bool) -> void:
	if enabled == items_ui_enabled:
		return
	var disabled: bool = not enabled
	item_name_ln_edt.editable = enabled
	rarity_opt_btn.disabled = disabled
	item_val_spn_bx.editable = enabled
	item_desc_txt_edt.editable = enabled
	category_opt_btn.disabled = disabled
	
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
	item_data_tree.clear_data(false)
	reset_flags()


func save_current_item() -> void:
	item_link.set_item_name(loaded_item, item_name_ln_edt.text.strip_edges())
	item_link.items.set_item_description(loaded_item, item_desc_txt_edt.text.strip_edges())
	item_link.items.set_item_category(loaded_item, category_opt_btn.get_selected_metadata())
	items_tree.set_item_category(loaded_item, category_opt_btn.get_selected_metadata())
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
		NFPluginGameHandler._log_msg(
			"items - editor",
			"An error occurred while trying to load item '%s'" % item_id,
			NFPluginGameHandler._LogLevel.ERROR)
		return
	
	item_name_ln_edt.text = item.name
	item_name_ln_edt.set_meta(&"old_value", item.name)
	select_category(item.category)
	select_rarity(item.rarity)
	item_val_spn_bx.set_value_no_signal(item.value)
	item_val_spn_bx.set_meta(&"old_value", item.value)
	item_desc_txt_edt.text = item.description
	item_desc_txt_edt.set_meta(&"old_value", item.description)
	
	item_data_tree.clear_data(false)
	
	for data_key in item.custom_data.keys():
		item_data_tree.add_data(data_key, item.custom_data[data_key], true)
	
	for flag:CheckBox in items_flags_container.get_children():
		flag.set_pressed_no_signal(
				item.flags.has(
						flag.get_meta(&"flag_value")))


func select_rarity(rarity: ItemSheet.Rarity) -> void:
	for item_idx in range(rarity_opt_btn.item_count):
		if rarity_opt_btn.get_item_metadata(item_idx) == rarity:
			rarity_opt_btn.select(item_idx)
			rarity_opt_btn.set_meta(&"old_value", rarity)
			break


func reload_item_resource(first_launch: bool = false) -> void:
	var was_null: bool = item_link.items == null
	item_link.items = null
	item_name_ln_edt.text = ""
	item_desc_txt_edt.text = ""
	item_val_spn_bx.set_value_no_signal(0.0)
	item_data_tree.clear_data(false)
	
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
		items_tree.clear_entries()
		
		for item in item_link.items.items():
			items_tree.register_item(item, item_link.items.get_item_category(item))
		items_tree.sort_registered_items()
		
		if 1 < items_tree.last_page:
			item_page_container.visible = true
			update_page_label()
			next_item_page_btn.disabled = not items_tree.has_next_page()
			prev_item_page_btn.disabled = not items_tree.has_previous_page()
		else:
			item_page_container.visible = false
		resource_loaded.emit()


func reload_categories(reselect: bool = false) -> void:
	var can_reselect: bool = -1 < category_opt_btn.selected if reselect else false
	var selected: StringName = category_opt_btn.get_item_metadata(category_opt_btn.selected) if can_reselect else &""
	
	category_opt_btn.clear()
	category_opt_btn.add_item("(unassigned)")
	category_opt_btn.set_item_metadata(0, &"")
	
	var categories: Dictionary[StringName, String] = {}
	var category_ids: Array[StringName] = []
	
	for category in item_link.items.categories():
		categories[category] = String(category).capitalize()
	
	category_ids.assign(categories.keys())
	
	category_ids.sort_custom(func(a,b): return categories[a] < categories[b])
	
	for category_id in category_ids:
		category_opt_btn.add_item(categories[category_id])
		category_opt_btn.set_item_metadata(-1, category_id)
	
	if can_reselect:
		select_category(selected)


func select_category(category_id: StringName, uncategorized_if_not_found: bool = false) -> bool:
	for idx in range(category_opt_btn.item_count):
		if category_opt_btn.get_item_metadata(idx) == category_id:
			category_opt_btn.select(idx)
			category_opt_btn.set_meta(&"old_value", category_id)
			return true
	
	if uncategorized_if_not_found:
		category_opt_btn.select(0)
	return false


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


func _on_currency_data_changed() -> void:
	if currency_custom_data_tree.has_undo():
		undo.create_action("Currency Data Changed")
		undo.add_do_method(_do_update_currency_data.bind(loaded_currency, false))
		undo.add_undo_method(_do_update_currency_data.bind(loaded_currency, true))
		undo.commit_action(false)
	_on_currency_changed()


func _do_update_currency_data(currency_id: StringName, is_undo: bool) -> void:
	if loaded_currency != currency_id:
		currency_tree.select_currency(currency_id, false)
		switch_to_currency(currency_id)
	if currency_custom_data_tree.has_undo():
		if is_undo:
			currency_custom_data_tree.undo()
		else:
			currency_custom_data_tree.redo()


func _on_items_changed(arg = null) -> void:
	if _items_unsaved:
		return
	_items_unsaved = true


func _on_currency_changed(arg = null) -> void:
	if _currency_unsaved:
		return
	_currency_unsaved = true


func _parse_value(value: String, fallback: float) -> float:
	var error: int = exp_parser.parse(value)

	if error != OK:
		return fallback
		
	var result: Variant = exp_parser.execute([], null, false)
	
	if exp_parser.has_execute_failed():
		return fallback
	
	var type: int = typeof(result)
	if type == TYPE_INT or type == TYPE_FLOAT:
		return result
	return fallback


func _on_flag_toggled(toggled: bool, flag_id: String) -> void:
	undo.create_action("Set '%s' Item Flag" % loaded_item)
	undo.add_do_method(_do_update_flag_toggled.bind(flag_id, toggled))
	undo.add_undo_method(_do_update_flag_toggled.bind(flag_id, not toggled))
	undo.commit_action(false)
	
	_on_items_changed()


func _do_update_flag_toggled(flag_id: String, set_pressed: bool) -> void:
	for item:CheckBox in items_flags_container.get_children():
		if item.get_meta(&"flag_id") != flag_id:
			continue
		item.set_pressed_no_signal(set_pressed)
		return
	
	NFPluginGameHandler._log_msg(
			"depot - editor",
			"UndoRedo couldn't apply action on inexistent flag '%s'" % flag_id,
			NFPluginGameHandler._LogLevel.EDITOR)


func create_flag_item(flag_id: String, flag_value: ItemSheet.ItemFlag) -> CheckBox:
	var new_flag: CheckBox = CheckBox.new()
	new_flag.text = flag_id.capitalize()
	new_flag.set_meta(&"flag_value", flag_value)
	new_flag.set_meta(&"flag_id", flag_id)
	new_flag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	new_flag.tooltip_text = new_flag.text
	new_flag.custom_minimum_size.y = 32.0
	new_flag.disabled = not items_ui_enabled
	new_flag.toggled.connect(_on_flag_toggled.bind(flag_id))
	
	return new_flag


func reset_flags() -> void:
	for item:CheckBox in items_flags_container.get_children():
		item.set_pressed_no_signal(false)
