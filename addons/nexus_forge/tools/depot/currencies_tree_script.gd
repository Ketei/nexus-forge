@tool
extends IDTree


const MAX_RANGE: int = 9999


var root_tree: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 3)
	
	item_edited.connect(on_item_edited)


func search_item(currency_search: String) -> void:
	if currency_search.is_valid_int():
		var currency_val: float = float(currency_search)
		for currency in root_tree.get_children():
			for property in currency.get_children():
				if property.get_metadata(0) != 2:
					continue
				currency.visible = property.get_range(1) == currency_val
				break # Visibility changed, we have nothing more to do on this tree
	else:
		for currency in root_tree.get_children():
			if currency_search.is_empty() or currency.get_text(0).containsn(currency_search):
				currency.visible = true
			else:
				for property in currency.get_children():
					if property.get_metadata(0) != 1:
						continue
					currency.visible = property.get_text(0).containsn(currency_search)
					break


func create_currency(currency_id: String, value: int = 1, c_name: String = "New Currency") -> void:
	var new_currency: TreeItem = create_item(root_tree)
	var id: String = validate_id(root_tree, currency_id, new_currency)
	var name_tree: TreeItem = create_item(new_currency)
	var value_tree: TreeItem = create_item(new_currency)
	
	value_tree.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	
	value_tree.set_range_config(1, 1, MAX_RANGE, 1)
	
	value_tree.set_range(1, value)
	
	name_tree.set_editable(1, true)
	value_tree.set_editable(1, true)
	new_currency.set_editable(0, true)
	
	new_currency.set_selectable(1, false)
	name_tree.set_selectable(0, false)
	value_tree.set_selectable(0, false)
	
	new_currency.set_text(0, id)
	name_tree.set_text(0, "Name")
	name_tree.set_text(1, c_name)
	value_tree.set_text(0, "Value")
	
	new_currency.set_metadata(0, 0)
	name_tree.set_metadata(0, 1)
	value_tree.set_metadata(0, 2)
	
	new_currency.collapsed = true


func on_item_edited() -> void:
	var item_edited: TreeItem = get_edited()
	
	match item_edited.get_metadata(0):
		0:
			item_edited.set_text(
					0,
					validate_id(
							root_tree,
							item_edited.get_text(0),
							item_edited))


func get_currencies() -> Dictionary:
	var currency: Dictionary = {}
	
	for curr_tree in root_tree.get_children():
		var current_currency: String = curr_tree.get_text(0)
		currency[current_currency] = {
			"name": "",
			"value": 1}
		
		for curr_data in curr_tree.get_children():
			if curr_data.get_metadata(0) == 0:
				currency[current_currency]["name"] = curr_data.get_text(1)
			elif curr_data.get_metadata(0) == 1:
				currency[current_currency]["value"] = int(curr_data.get_range(1))
	
	return currency


func clear_currencies() -> void:
	for curr in root_tree.get_children():
		curr.free()
