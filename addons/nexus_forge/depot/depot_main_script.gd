@tool
extends PanelContainer


signal items_loaded

const MAX_UNDO_STEPS: int = 50

var _unsaved: bool = false:
	get():
		return items_container._unsaved

@onready var edit_categories_btn: Button = $ItemsContainer/ItemsPanel/ItemsContainer/DataContainer/CategoryContainer/OptBtnContainer/EditCategoriesBtn
@onready var finish_cat_btn: Button = $CategoriesContainer/DataContainer/FinishCatBtn
@onready var items_container: HBoxContainer = $ItemsContainer
@onready var categories_container: HBoxContainer = $CategoriesContainer
@onready var categories_tree: Tree = $CategoriesContainer/DataContainer/CategoriesTree


func _ready() -> void:
	set_process_input(false)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	if event is InputEventKey:
		if event.echo or not event.pressed:
			return
		
		if event.keycode == KEY_DELETE and not event.shift_pressed and not event.ctrl_pressed:
			if items_container.visible:
				if not items_container.loaded_item.is_empty():
					var item_id: StringName = items_container.loaded_item
					items_container.items_tree._erase_item(item_id)
					items_container._on_item_erased(item_id)
			elif categories_container.visible:
				var category_id: StringName = categories_container.selected_category
				categories_container._on_erase_category_pressed(category_id)
			get_viewport().set_input_as_handled()
			return
		
		if not event.ctrl_pressed:
			return
		
		var current_focus: Control = get_viewport().gui_get_focus_owner()
		
		if current_focus != null:
			if current_focus is LineEdit:
				if current_focus.is_editing():
					return
			elif current_focus is TextEdit:
				return
		
		var target_undo: UndoRedo = null
		
		if items_container.visible:
			target_undo = items_container.undo
		elif categories_container.visible:
			target_undo = categories_container.category_undo
		
		if target_undo == null:
			get_viewport().set_input_as_handled()
			return
		
		if event.keycode == KEY_Z:
			if event.shift_pressed:
				if target_undo.has_redo():
					var action_name: String = target_undo.get_action_name(target_undo.get_current_action() + 1)
					target_undo.redo()
					NFPluginGameHandler._log_msg(
						"",
						"Redo: " + action_name,
						NFPluginGameHandler._LogLevel.EDITOR)
			else:
				if target_undo.has_undo():
					var action_name: String = target_undo.get_current_action_name()
					target_undo.undo()
					NFPluginGameHandler._log_msg(
						"",
						"Undo: " + action_name,
						NFPluginGameHandler._LogLevel.EDITOR)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Y and not event.shift_pressed:
			if target_undo.has_redo():
				var action_name: String = target_undo.get_action_name(target_undo.get_current_action() + 1)
				target_undo.redo()
				NFPluginGameHandler._log_msg(
						"",
						"Redo: " + action_name,
						NFPluginGameHandler._LogLevel.EDITOR)
			get_viewport().set_input_as_handled()


func ready_plugin(use_items: bool, use_currencies: bool) -> void:
	set_process_input(true)
	items_container.ready_plugin(use_items, use_currencies, MAX_UNDO_STEPS)
	if use_items:
		if items_container.item_link.items != null:
			categories_container.items_resource = items_container.item_link.items
		categories_container.ready_plugin(MAX_UNDO_STEPS)
	
	items_container.visible = true
	categories_container.visible = false
	
	$ItemsContainer/ItemsPanel.visible = use_items
	$ItemsContainer/CurrencyPanel.visible = use_currencies
	$ItemsContainer/VSeparator. visible = use_items and use_currencies
	
	edit_categories_btn.icon = get_theme_icon("Edit", "EditorIcons")
	items_container.resource_loaded.connect(_on_resource_loaded)
	edit_categories_btn.pressed.connect(_on_category_edit_pressed)
	finish_cat_btn.pressed.connect(_on_categories_done_pressed)
	categories_container.category_id_changed.connect(_on_category_id_updated)
	
	if items_container.item_link.items == null:
		edit_categories_btn.disabled = true
	else:
		_on_resource_loaded()


func _on_category_id_updated(from: StringName, to: StringName) -> void:
	items_container.update_category_id(from, to)


func _on_resource_loaded() -> void:
	var res: ItemCatalog = items_container.item_link.items
	
	categories_container.items_resource = res
	categories_container.reload_categories()
	edit_categories_btn.disabled = false
	items_loaded.emit()


func _on_category_edit_pressed() -> void:
	items_container.visible = false
	categories_container.visible = true


func _on_categories_done_pressed() -> void:
	if categories_container.categories_edited:
		items_container.reload_categories(true)
		items_container._items_unsaved = true
		categories_container.categories_edited = false
	
	items_container.visible = true
	categories_container.visible = false


func has_unsaved_changes() -> bool:
	return items_container._items_unsaved or items_container._currency_unsaved or categories_container.categories_edited


func save() -> void:
	if items_container._items_unsaved or categories_container.categories_edited:
		if categories_container.categories_edited:
			categories_container.save_current_category()
		
		if items_container.item_link.items != null and not items_container.loaded_item.is_empty():
			items_container.save_current_item()
		ResourceSaver.save(items_container.item_link.items)
	
	if items_container._currency_unsaved:
		if items_container.currency_resource != null and not items_container.loaded_currency.is_empty():
			items_container.save_current_currency()
		ResourceSaver.save(items_container.currency_resource)
	
	items_container._items_unsaved = false
	items_container._currency_unsaved = false
	categories_container.categories_edited = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(categories_container) and is_instance_valid(categories_container.category_undo):
			categories_container.category_undo.clear_history()
			categories_container.category_undo.free()
			categories_container.category_undo = null
		if is_instance_valid(items_container) and is_instance_valid(items_container.undo):
			items_container.undo.clear_history()
			items_container.undo.free()
			items_container.undo = null
