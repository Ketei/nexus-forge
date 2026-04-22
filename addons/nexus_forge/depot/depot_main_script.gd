@tool
extends PanelContainer


signal items_loaded

var id_changed: Dictionary[StringName, StringName] = {}

var _unsaved: bool = false:
	get():
		return items_container._unsaved

@onready var edit_categories_btn: Button = $ItemsContainer/ItemsPanel/ItemsContainer/TreeContainer/VBoxContainer/HBoxContainer/EditCategoriesBtn
@onready var finish_cat_btn: Button = $CategoriesContainer/DataContainer/FinishCatBtn
@onready var items_container: HBoxContainer = $ItemsContainer
@onready var categories_container: HBoxContainer = $CategoriesContainer
@onready var categories_tree: Tree = $CategoriesContainer/DataContainer/CategoriesTree


func ready_plugin() -> void:
	items_container.ready_plugin()
	categories_container.ready_plugin()
	
	items_container.visible = true
	categories_container.visible = false
	
	edit_categories_btn.icon = get_theme_icon("Edit", "EditorIcons")
	items_container.resource_loaded.connect(_on_resource_loaded)
	edit_categories_btn.pressed.connect(_on_category_edit_pressed)
	finish_cat_btn.pressed.connect(_on_categories_done_pressed)
	categories_tree.category_id_changed.connect(_on_category_id_changed)
	
	if items_container.item_link.items == null:
		edit_categories_btn.disabled = true
	else:
		_on_resource_loaded()


func _on_category_id_changed(from: StringName, to: StringName) -> void:
	if from == to:
		return
	
	var items: ItemCatalog = items_container.item_link.items
	
	if not items.has_category(from):
		return
	
	items._categories[to] = items._categories[from]
	items._categories.erase(from)
	
	for item_id in items.items():
		if items._items[item_id]["category"] == from:
			items._items[item_id]["category"] = to
	
	if items_container.current_category == from:
		items_container.current_category = to
	#if items_container.category_opt_btn.selected != -1:
		#if items_container.category_opt_btn.get_item_metadata(items_container.category_opt_btn.selected) == from:
			#items_container.category_opt_btn.set_item_metadata(items_container.category_opt_btn.selected, to)


func _on_resource_loaded() -> void:
	var res: ItemCatalog = items_container.item_link.items
	
	#for category in res.categories():
		#categories_container.categories_tree.create_category(
			#String(category),
			#res.get_category_name(category),
			#res._categories[category]["data"].duplicate(true))
	categories_container.reload_categories(res)
	edit_categories_btn.disabled = false
	items_loaded.emit()


func _on_category_edit_pressed() -> void:
	items_container.visible = false
	categories_container.visible = true
	categories_container.clean()


func _on_categories_done_pressed() -> void:
	categories_container.save_category_data(items_container.item_link.items)
	#if items_container.loaded_item != &"":
		#items_container.save_current_item()
	items_container.reload_categories(true)
	if categories_container._unsaved:
		items_container._unsaved = true
	
	items_container.visible = true
	categories_container.visible = false


func save() -> void:
	if items_container.item_link.items != null:
		if items_container.loaded_item != &"":
			items_container.save_current_item()
		ResourceSaver.save(items_container.item_link.items)
		
	if items_container.currency_resource != null:
		if items_container.loaded_currency != &"":
			items_container.save_current_currency()
		ResourceSaver.save(items_container.currency_resource)
	
	items_container._unsaved = false
