@tool
extends HBoxContainer

signal category_id_changed(from: StringName, to: StringName)

var selected_category: StringName = &""

var categories_edited: bool = false
var items_resource: ItemCatalog
var category_undo: UndoRedo

@onready var search_cat_ln_edt: LineEdit = $DataContainer/SearchContainer/SearchCatLnEdt
@onready var new_category_btn: Button = $DataContainer/SearchContainer/NewCategoryBtn
@onready var categories_tree: Tree = $DataContainer/CategoriesTree
@onready var add_cat_fldr_btn: Button = $DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCatFldrBtn
@onready var add_cat_int_btn: Button = $DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCatIntBtn
@onready var add_cat_float_btn: Button = $DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCatFloatBtn
@onready var add_cat_bool_btn: Button = $DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCatBoolBtn
@onready var add_cat_str_btn: Button = $DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCatStrBtn
@onready var item_data_tree: Tree = $DataContainer/CustomDataContainer/ItemDataTree


func ready_plugin(max_undo_steps: int) -> void:
	category_undo = UndoRedo.new()
	
	item_data_tree.undo_redo_steps = max_undo_steps
	
	categories_tree.ready_plugin()
	item_data_tree.ready_plugin()
	
	item_data_tree.enabled = true
	new_category_btn.icon = get_theme_icon("Add", "EditorIcons")
	add_cat_fldr_btn.icon = get_theme_icon("FolderCreate", "EditorIcons")
	
	categories_tree.category_selected.connect(_on_category_selected)
	categories_tree.erase_category_pressed.connect(_on_erase_category_pressed, CONNECT_DEFERRED)
	categories_tree.category_id_changed.connect(_on_category_id_changed)
	categories_tree.category_name_changed.connect(_on_category_name_changed)
	categories_tree.category_moved.connect(_on_category_moved)
	categories_tree.category_created.connect(_on_subcategory_created)
	
	item_data_tree.data_changed.connect(_on_category_data_changed)
	new_category_btn.pressed.connect(_on_new_category_pressed)
	
	add_cat_int_btn.pressed.connect(add_data.bind("new_int", 0))
	add_cat_float_btn.pressed.connect(add_data.bind("new_float", 0.0))
	add_cat_bool_btn.pressed.connect(add_data.bind("new_bool", false))
	add_cat_str_btn.pressed.connect(add_data.bind("new_string", ""))
	add_cat_fldr_btn.pressed.connect(add_data.bind("new_folder", {}))
	
	search_cat_ln_edt.text_changed.connect(_on_search_categories_text_changed)


func _on_search_categories_text_changed(text: String) -> void:
	categories_tree.search_for(text.strip_edges())


func _on_category_changed() -> void:
	if categories_edited:
		return
	categories_edited = true


func _on_new_category_pressed() -> void:
	var id_creator := preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
	id_creator.line_placeholder_text = "Category ID"
	id_creator.allow_empty = false
	id_creator.use_blacklist = true
	id_creator.character_blacklist.append(" ")
	id_creator.text_blacklist.assign(items_resource.categories())
	id_creator.title = "Create Category"
	id_creator.ok_button_text = "Create"
	add_child(id_creator)
	id_creator.show()
	id_creator.grab_text_focus()
	
	var result = await id_creator.dialog_finished
	id_creator.queue_free()
	
	if not result[0]:
		return
	
	if not selected_category.is_empty():
		save_current_category()
	
	var category_id: StringName = StringName(result[1])
	
	category_undo.create_action("Create Category")
	category_undo.add_do_method(_do_create_category.bind(category_id, "New Category", &""))
	category_undo.add_undo_method(_undo_create_category.bind(category_id))
	category_undo.commit_action()
	
	categories_tree.select_category(category_id, false)
	
	selected_category = category_id
	add_cat_int_btn.disabled = false
	add_cat_float_btn.disabled = false
	add_cat_bool_btn.disabled = false
	add_cat_str_btn.disabled = false
	add_cat_fldr_btn.disabled = false
	item_data_tree.clear_data()
	
	_on_category_changed()


func _do_create_category(category_id: StringName, category_name: String, under: StringName) -> void:
	items_resource.create_category(category_id, category_name, under)
	if not categories_tree._add_category(category_id, category_name, under):
		NFPluginGameHandler._log_msg(
				"depot - editor",
				"Failed to create category '%s' on the editor." % category_id,
				NFPluginGameHandler._LogLevel.ERROR)


func _undo_create_category(category_id: StringName) -> void:
	items_resource._categories.erase(category_id)
	categories_tree.erase_category(category_id)
	if selected_category == category_id:
		add_cat_int_btn.disabled = false
		add_cat_float_btn.disabled = false
		add_cat_bool_btn.disabled = false
		add_cat_str_btn.disabled = false
		add_cat_fldr_btn.disabled = false


func add_data(data_key: String, data: Variant) -> void:
	item_data_tree.add_data(data_key, data)
	if item_data_tree.has_undo():
		category_undo.create_action("Data Changed")
		category_undo.add_do_method(item_data_tree.redo)
		category_undo.add_undo_method(item_data_tree.undo)
		category_undo.commit_action(false)


func _on_category_selected(category_id: StringName) -> void:
	switch_to_category(category_id)


func switch_to_category(category_id: StringName) -> void: 
	if not selected_category.is_empty():
		save_current_category()
	
	item_data_tree.clear_data(false)
	
	var data: Dictionary = items_resource._categories[category_id]["custom_data"]
	
	for data_key in data.keys():
		item_data_tree.add_data(data_key, data[data_key], true)
	
	add_cat_int_btn.disabled = false
	add_cat_float_btn.disabled = false
	add_cat_bool_btn.disabled = false
	add_cat_str_btn.disabled = false
	add_cat_fldr_btn.disabled = false
	
	selected_category = category_id


func reload_categories() -> void:
	var item_selected: bool = categories_tree.get_selected() != null
	
	categories_tree.clear_categories()
	
	var top_level_categories: Array[StringName] = []
	
	for category in items_resource.categories():
		if items_resource._categories[category]["parent_key"] == &"":
			top_level_categories.append(category)
	
	for category in top_level_categories:
		var subcategories: Dictionary[StringName, Dictionary] = items_resource.get_subcategories_of(category)
		_add_category_map(subcategories)


func _add_category_map(categories: Dictionary[StringName, Dictionary], target: StringName = &"") -> void:
	for category_id in categories.keys():
		categories_tree.create_category(
				category_id,
				items_resource._categories[category_id]["name"],
				target)
		_add_category_map(categories[category_id], category_id)


func _on_erase_category_pressed(category: String) -> void:
	categories_edited = true
	
	var cat_id: StringName = StringName(category)
	var parent_category: StringName = items_resource.get_category_parent(cat_id)
	var tree_map: Dictionary[String, Dictionary] = {
		category: categories_tree.get_category_map(category)}
	
	# ItemID: Category
	var items_changed: Dictionary[StringName, StringName] = {}
	# Resource data
	var categories_erased: Dictionary[StringName, Dictionary] = {}
	var all_categories_erased: Array[StringName] = []
	
	for subcat in categories_tree.get_subcategories_of(category):
		categories_erased[subcat] = items_resource._categories[subcat].duplicate(true)
	
	categories_erased[cat_id] = {
		"name": items_resource.get_category_name(cat_id),
		"custom_data": items_resource._categories[cat_id]["custom_data"].duplicate(true),
		"parent_key": parent_category}
	
	all_categories_erased.assign(categories_erased.keys())
	
	for item_id:StringName in items_resource.items():
		var item_cat: StringName = items_resource.get_item_category(item_id)
		if categories_erased.has(item_cat):
			items_changed[item_id] = item_cat
			items_resource.set_item_category(item_id, &"")
	
	for category_id in categories_erased:
		items_resource.erase_category(category_id)
	
	categories_tree.erase_category(cat_id)
	
	category_undo.create_action("Erase Category")
	category_undo.add_do_method(_do_erase_category.bind(cat_id, all_categories_erased))
	category_undo.add_undo_method(_undo_erase_category.bind(parent_category, categories_erased, tree_map, items_changed))
	category_undo.commit_action(false)
	
	_on_category_changed()


func _do_erase_category(category_id: StringName, cats_to_erase: Array[StringName]) -> void:
	categories_tree.erase_category(category_id)
	
	var cat_dict: Dictionary[StringName, Variant] = {}
	
	for category in cats_to_erase:
		if items_resource._categories.erase(category):
			cat_dict[category] = null
	
	for item_id in items_resource.items():
		if cat_dict.has(items_resource.get_item_category(item_id)):
			items_resource.set_item_category(item_id, &"")


func _undo_erase_category(parent_category: StringName, categories_snapshot: Dictionary[StringName, Dictionary], tree_snapshot: Dictionary[String, Dictionary], items_snapshot: Dictionary[StringName, StringName]) -> void:
	categories_tree._restore_categories(parent_category, tree_snapshot)
	
	for category_id in categories_snapshot:
		items_resource._categories[category_id] = categories_snapshot[category_id].duplicate(true)
	
	for item_id in items_snapshot:
		items_resource.set_item_category(item_id, items_snapshot[item_id])


func _on_category_name_changed(id: StringName, from: String, to: String) -> void:
	items_resource.set_category_name(id, to)
	
	category_undo.create_action("Set Category Name")
	category_undo.add_do_method(_do_rename_category.bind(id, to))
	category_undo.add_undo_method(_do_rename_category.bind(id, from))
	category_undo.commit_action(false)
	
	_on_category_changed()


func _do_rename_category(id: StringName, to: String) -> void:
	if items_resource != null:
		items_resource.set_category_name(id, to)
	categories_tree.set_category_name(id, to)


func _on_category_id_changed(from: StringName, to: StringName) -> void:
	items_resource._categories[to] = items_resource._categories[from]
	items_resource._categories.erase(from)
	
	for item_id in items_resource.items():
		if items_resource.get_item_category(item_id) == from:
			items_resource.set_item_category(item_id, to)
	
	category_undo.create_action("Set Category ID")
	category_undo.add_do_method(_do_update_category_id.bind(from, to))
	category_undo.add_undo_method(_do_update_category_id.bind(to, from))
	category_undo.commit_action(false)
	
	_on_category_changed()
	
	category_id_changed.emit(from, to)


func _do_update_category_id(from: StringName, to: StringName) -> void:
	if items_resource != null and items_resource._categories.has(from):
		items_resource._categories[to] = items_resource._categories[from]
		items_resource._categories.erase(from)
		for item_id in items_resource.items():
			if items_resource.get_item_category(item_id) == from:
				items_resource.set_item_category(item_id, to)
	categories_tree.set_category_id(from, to)
	category_id_changed.emit(from, to)


func _on_category_moved(category_id: String, new_parent: String) -> void:
	var old_parent: StringName = items_resource.get_category_parent(category_id)
	items_resource.link_category(category_id, new_parent)
	category_undo.create_action("Move Category")
	category_undo.add_do_method(_do_move_category.bind(category_id, new_parent))
	category_undo.add_undo_method(_do_move_category.bind(category_id, old_parent))
	category_undo.commit_action(false)
	_on_category_changed()


func _do_move_category(category_id: String, new_parent: String) -> void:
	if items_resource != null and items_resource.has_category(category_id):
		items_resource.link_category(category_id, new_parent)
	categories_tree.move_category(category_id, new_parent)


func _on_subcategory_created(category_id: StringName) -> void:
	var cat_name: String = categories_tree.get_category_name(category_id)
	var cat_parent: StringName = categories_tree.get_category_parent(category_id)
	items_resource.create_category(
			category_id,
			cat_name,
			cat_parent)
	
	category_undo.create_action("Create Subcategory")
	category_undo.add_do_method(
			_do_create_category.bind(category_id, cat_name, cat_parent))
	category_undo.add_undo_method(_undo_create_category.bind(category_id))
	category_undo.commit_action(false)
	_on_category_changed()


func _on_category_data_changed() -> void:
	if item_data_tree.has_undo():
		category_undo.create_action("Data Changed")
		category_undo.add_do_method(_do_update_data_change.bind(selected_category, false))
		category_undo.add_undo_method(_do_update_data_change.bind(selected_category, true))
		category_undo.commit_action(false)
	_on_category_changed()


func _do_update_data_change(category_id: StringName, is_undo: bool) -> void:
	if selected_category != category_id:
		switch_to_category(category_id)
		categories_tree.select_category(category_id, true, false)
	if is_undo:
		item_data_tree.undo()
	else:
		item_data_tree.redo()


func save_current_category() -> void:
	if selected_category.is_empty():
		return
	elif not items_resource.has_category(selected_category):
		return
	
	var cat_str: String = String(selected_category)
	items_resource._categories[selected_category]["parent_key"] = StringName(categories_tree.get_category_parent(cat_str))
	items_resource._categories[selected_category]["name"] = categories_tree.get_category_name(cat_str)
	items_resource._categories[selected_category]["custom_data"].assign(item_data_tree.get_data())
