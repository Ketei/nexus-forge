@tool
extends HBoxContainer


var active_category_item: TreeItem = null
var listen_category_selected: bool = true

var _unsaved: bool = false

@onready var search_cat_ln_edt: LineEdit = $DataContainer/SearchContainer/SearchCatLnEdt
@onready var new_category_btn: Button = $DataContainer/SearchContainer/NewCategoryBtn
@onready var categories_tree: Tree = $DataContainer/CategoriesTree
@onready var add_cat_fldr_btn: Button = $DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCatFldrBtn
@onready var add_cat_int_btn: Button = $DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCatIntBtn
@onready var add_cat_float_btn: Button = $DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCatFloatBtn
@onready var add_cat_bool_btn: Button = $DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCatBoolBtn
@onready var add_cat_str_btn: Button = $DataContainer/CustomDataContainer/CustomDataHeader/ButtonContainer/AddCatStrBtn
@onready var item_data_tree: Tree = $DataContainer/CustomDataContainer/ItemDataTree


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	
	new_category_btn.icon = get_theme_icon("Add", "EditorIcons")
	
	categories_tree.item_selected.connect(_on_category_item_selected)
	new_category_btn.pressed.connect(_on_new_category_pressed)
	categories_tree.category_changed.connect(_on_category_changed)
	item_data_tree.data_changed.connect(_on_category_changed)
	
	add_cat_int_btn.pressed.connect(add_data.bind("new_int", 0))
	add_cat_float_btn.pressed.connect(add_data.bind("new_float", 0.0))
	add_cat_bool_btn.pressed.connect(add_data.bind("new_bool", false))
	add_cat_str_btn.pressed.connect(add_data.bind("new_string", ""))
	add_cat_fldr_btn.pressed.connect(add_data.bind("new_level", {}))


func _on_category_changed() -> void:
	if _unsaved:
		return
	_unsaved = true


func _on_new_category_pressed() -> void:
	var id_creator := preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
	id_creator.line_placeholder_text = "Category ID"
	id_creator.allow_empty = false
	id_creator.use_blacklist = true
	id_creator.character_blacklist.append(" ")
	id_creator.text_blacklist.assign(categories_tree.active_categories())
	id_creator.title = "Create Category"
	id_creator.ok_button_text = "Create"
	add_child(id_creator)
	id_creator.show()
	id_creator.grab_text_focus()
	
	var result = await id_creator.dialog_finished
	
	if result[0]:
		listen_category_selected = false
		if active_category_item != null:
			active_category_item.get_metadata(0)["data"] = item_data_tree.get_data()
		
		var data: Dictionary[String, Variant] = {}
		data.assign(ItemCatalog.ITEM_DEFAULT_DATA)
		var item: TreeItem = categories_tree.create_category(result[1], "New Category", data)
		item.select(0)
		active_category_item = item
		add_cat_int_btn.disabled = false
		add_cat_float_btn.disabled = false
		add_cat_bool_btn.disabled = false
		add_cat_str_btn.disabled = false
		add_cat_fldr_btn.disabled = false
		item_data_tree.clear_data()
		
		for data_key in data.keys():
			categories_tree.add_data(data_key, data[data_key])
		listen_category_selected = true
		_on_category_changed()
	id_creator.queue_free()


func _update_keys(item_res: ItemCatalog, from: TreeItem) -> void:
	var parent_category: StringName = StringName(from.get_text(0))
	
	if not item_res.has_category(parent_category):
		item_res.create_category(parent_category)
	
	for cat_item in from.get_children():
		var set_id: StringName = StringName(cat_item.get_text(0))
		
		if not item_res.has_category(set_id):
			item_res.create_category(set_id)
			
		item_res.link_category(parent_category, set_id)
		item_res.set_category_name(set_id, cat_item.get_text(1).strip_edges())
		
		item_res.clear_category_data(set_id)
		var data: Dictionary[String, Variant] = cat_item.get_metadata(0)["data"]
		for data_key in data.keys():
			item_res.set_category_data(set_id, data_key, data[data_key])
		
		_update_keys(item_res, cat_item)


func add_data(data_key: String, data: Variant) -> void:
	item_data_tree.add_data(data_key, data)


func save_category_data(item_resource: ItemCatalog) -> void:
	for erased_category:StringName in categories_tree.erased_categories:
		item_resource.erase_category(erased_category)
	
	for cat_item in categories_tree.get_root().get_children():
		_update_keys(item_resource, cat_item)
	
		#item_resource.set_category_name(category_id, cat_item.get_text(0).strip_edges())
		#item_resource.clear_category_data(category_id)
		#for data_key in data["data"].keys():
			#item_resource.set_category_data(category_id, data_key, data["data"][data_key])


func _on_category_item_selected() -> void:
	if not listen_category_selected:
		return
	if active_category_item != null:
		active_category_item.get_metadata(0)["data"] = item_data_tree.get_data()
	active_category_item = categories_tree.get_selected()
	item_data_tree.clear_data()
	var data: Dictionary = active_category_item.get_metadata(0)["data"]
	
	for data_key in data.keys():
		item_data_tree.add_data(data_key, data[data_key])
	
	add_cat_int_btn.disabled = false
	add_cat_float_btn.disabled = false
	add_cat_bool_btn.disabled = false
	add_cat_str_btn.disabled = false
	add_cat_fldr_btn.disabled = false


func _on_category_deleted(item: TreeItem) -> void:
	if active_category_item == item:
		active_category_item = null
		add_cat_int_btn.disabled = true
		add_cat_float_btn.disabled = true
		add_cat_bool_btn.disabled = true
		add_cat_str_btn.disabled = true
		add_cat_fldr_btn.disabled = true
		item_data_tree.clear_data()
	_on_category_changed()


func clean() -> void:
	categories_tree.erased_categories.clear()
	_unsaved = false
