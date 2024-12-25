extends Tree


signal rarity_created(rarity_name: String)
signal rarity_reindexed(from: int, to: int)
signal rarity_deleted(rarity_idx: int)
signal rarity_renamed(idx: int, new_name: String)
signal currency_created(currency_id: String)
signal currency_id_changed(from: String, to: String)
signal currency_selected(currency_id: String)
signal item_category_created(catgory_id: String)
signal item_category_renamed(from: String, to: String)
signal item_category_selected(category_id: String)


const PLUS_ICON = preload("res://addons/nexus_forge/common_icons/plus_icon.svg")
const DOWN_ARROW = preload("res://addons/nexus_forge/common_icons/down_arrow.svg")
const UP_ARROW = preload("res://addons/nexus_forge/common_icons/up_arrow.svg")

enum ButtonIDs {
	CREATE_CATEGORY,
	CREATE_RARITY,
	SORT_UP,
	SORT_DOWN,
	DELETE_RARITY,
	CREATE_CURRENCY,
}

#const CREATE_CATEGORY_BTN: int = 0
#const CREATE_ITEM_BTN: int = 1
#const CREATE_RARITY_BTN: int = 
#const SORT_UP_BTN: int = 2
#const SORT_DOWN_BTN: int = 3
#const DELETE_RARITY_BTN: int = 4

enum CellIDs {
	ITEM_CATEGORY,
	CURRENCY,
	RARITY
	
}

var root_tree: TreeItem = null
var items_category: TreeItem = null
var rarity_category: TreeItem = null
var crafting_category: TreeItem = null
var currency_category: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	
	items_category = root_tree.create_child()
	crafting_category = root_tree.create_child()
	rarity_category= root_tree.create_child()
	currency_category = root_tree.create_child()
	
	items_category.set_text(0, "Item Categories")
	crafting_category.set_text(0, "Crafting")
	currency_category.set_text(0, "Currency")
	rarity_category.set_text(0, "Rarity")
	
	items_category.set_selectable(0, false)
	crafting_category.set_selectable(0, false)
	currency_category.set_selectable(0, false)
	rarity_category.set_selectable(0, false)
	
	rarity_category.set_tooltip_text(0, "Higher = less rare.\nLower = more Rare")
	
	items_category.add_button(0, PLUS_ICON, ButtonIDs.CREATE_CATEGORY, false, "Create Item Category")
	rarity_category.add_button(0, PLUS_ICON, ButtonIDs.CREATE_RARITY, false, "Create Rarity")
	currency_category.add_button(0, PLUS_ICON, ButtonIDs.CREATE_CURRENCY, false, "Create Currency")
	
	button_clicked.connect(_on_button_clicked)
	item_edited.connect(_on_item_edited)
	item_selected.connect(_on_item_selected)


func create_category(on_tree: TreeItem, category_name: String, items: Array[String] = []) -> TreeItem:
	var category: TreeItem = on_tree.create_child()
	category.set_text(0, category_name)
	category.add_button(0, PLUS_ICON, ButtonIDs.CREATE_CATEGORY, false, "Create Category")
	category.set_metadata(0, {"row_id": CellIDs.ITEM_CATEGORY, "name": category_name})
	category.set_editable(0, true)
	return category


#func add_item(on_tree: TreeItem, item_id: String = "new_item") -> void:
	#var new_item: TreeItem = on_tree.create_child()
	#new_item.set_text(0, item_id)
	#new_item.set_metadata(0, {"id": CellIDs.ITEM})


func create_rarity(rarity_name: String) -> void:
	var new_rarity: TreeItem = rarity_category.create_child()
	new_rarity.set_text(0, rarity_name)
	new_rarity.add_button(0, UP_ARROW, ButtonIDs.SORT_UP, new_rarity.get_index() == 0, "Less Rare")
	new_rarity.add_button(0, DOWN_ARROW, ButtonIDs.SORT_DOWN, new_rarity.get_index() == rarity_category.get_child_count() - 1, "More Rare")
	new_rarity.set_editable(0, true)
	if 0 < new_rarity.get_index():
		var prev_rarity: TreeItem = rarity_category.get_child(new_rarity.get_index() - 1)
		prev_rarity.set_button_disabled(0, 1, false)
	new_rarity.set_metadata(0, {"row_id": CellIDs.RARITY})


func create_currency(currency_id: String, currency_value: int = 1) -> void:
	var insert_idx: int = 0
	for currency in currency_category.get_children():
		if currency_value <= currency.get_metadata(0)["value"]:
			break
		insert_idx += 1
	var new_currency: TreeItem = currency_category.create_child(insert_idx)
	new_currency.set_text(0, currency_id)
	new_currency.set_metadata(0, {"row_id": CellIDs.CURRENCY, "id": currency_id, "value": currency_value})
	new_currency.set_editable(0, true)


func get_valid_currency_id(desired_id: String = "", skip_tree: TreeItem = null) -> String:
	var cleaned_id: String = desired_id.strip_edges()
	if cleaned_id.is_empty():
		cleaned_id = "new_currency_id"
	var modified_id: String = cleaned_id
	var iteration: int = 0
	
	while has_id(currency_category, modified_id, skip_tree):
		iteration += 1
		modified_id = cleaned_id + str(iteration)
	return modified_id


func get_valid_category_id(on_tree: TreeItem, desired_name: String, skip_tree: TreeItem = null) -> String:
	var clean_string: String = desired_name.strip_edges()
	if clean_string.is_empty():
		clean_string = "new_category"
	var modified_id: String = clean_string
	var iteration: int = 0
	while has_id(on_tree, modified_id, skip_tree):
		iteration += 1
		modified_id = clean_string + str(iteration)
	return modified_id


func has_id(on_tree: TreeItem, id_string: String, skip_tree: TreeItem) -> bool:
	for child in on_tree.get_children():
		if child == skip_tree:
			continue
		if child.get_text(0) == id_string:
			return true
	return false


#func has_currency(currency_id: String, skip_tree: TreeItem) -> bool:
	#for currency in currency_category.get_children():
		#if currency == skip_tree:
			#continue
		#if currency.get_text(0) == currency_id:
			#return true
	#return false


# Sorts the currency depending on it's value
func sort_currencies():
	var currencies: Array[TreeItem] = currency_category.get_children()
	
	if currencies.size() == 0:
		return
	
	currencies.sort_custom(_sort_custom_currency_tree)
	var current_idx: int = -1
	for currency in currencies:
		current_idx += 1
		if current_idx == 0:
			currency.move_before(currency_category.get_first_child())
			continue
		currency.move_after(currencies[current_idx - 1])


func update_currency_value(currency_id: String, new_value: int) -> void:
	for currency in currency_category.get_children():
		if currency.get_text(0) == currency_id:
			var meta = currency.get_metadata(0)
			currency.get_metadata(0)["value"] = new_value
			sort_currencies()
			break


func _sort_custom_currency_tree(a: TreeItem, b: TreeItem) -> bool:
	return a.get_metadata(0)["value"] < b.get_metadata(0)["value"]


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		ButtonIDs.SORT_UP:
			var up_child: TreeItem = item.get_parent().get_child(item.get_index() - 1)
			item.move_before(up_child)
			up_child.set_button_disabled(0, 0, up_child.get_index() == 0)
			up_child.set_button_disabled(0, 1, up_child.get_index() == rarity_category.get_child_count() - 1)
			item.set_button_disabled(0, 0, item.get_index() == 0)
			item.set_button_disabled(0, 1, item.get_index() == rarity_category.get_child_count() - 1)
			rarity_reindexed.emit(up_child.get_index(), item.get_index())
		ButtonIDs.SORT_DOWN:
			var down_child: TreeItem = item.get_parent().get_child(item.get_index() + 1)
			item.move_after(down_child)
			down_child.set_button_disabled(0, 0, down_child.get_index() == 0)
			down_child.set_button_disabled(0, 1, down_child.get_index() == rarity_category.get_child_count() - 1)
			item.set_button_disabled(0, 0, item.get_index() == 0)
			item.set_button_disabled(0, 1, item.get_index() == rarity_category.get_child_count() - 1)
			rarity_reindexed.emit(down_child.get_index(), item.get_index())
		ButtonIDs.CREATE_RARITY:
			create_rarity("New Rarity")
			rarity_created.emit("New Rarity")
		ButtonIDs.DELETE_RARITY:
			rarity_deleted.emit(item.get_index())
			item.free()
		ButtonIDs.CREATE_CURRENCY:
			var currency_id: String = get_valid_currency_id()
			create_currency(currency_id)
			currency_created.emit(currency_id)
		ButtonIDs.CREATE_CATEGORY:
			var new_cat_id: String = get_valid_category_id(item, "new_category")
			create_category(item, new_cat_id)
			item_category_created.emit(new_cat_id)


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	
	if edited.get_parent() == rarity_category:
		rarity_renamed.emit(edited.get_index(), edited.get_text(0))
	elif edited.get_parent() == currency_category:
		var new_name := get_valid_currency_id(edited.get_text(0), edited)
		edited.set_text(0, new_name)
		currency_id_changed.emit(edited.get_metadata(0)["id"], new_name)
		edited.get_metadata(0)["id"] = new_name
	elif edited.get_metadata(0)["row_id"] == CellIDs.ITEM_CATEGORY:
		var new_id: String = get_valid_category_id(edited.get_parent(), edited.get_text(0), edited)
		item_category_renamed.emit(edited.get_metadata(0)["name"], new_id)
		edited.set_text(0, new_id)
		edited.get_metadata(0)["name"] = new_id


func _on_item_selected() -> void:
	var selected: TreeItem = get_selected()
	match selected.get_metadata(0)["row_id"]:
		CellIDs.CURRENCY:
			currency_selected.emit(selected.get_text(0))
		CellIDs.ITEM_CATEGORY:
			item_category_selected.emit(selected.get_text(0))
		CellIDs.RARITY:
			pass
