@tool
extends IDTree

#signal currencies_updated
signal currency_selected(currency: StringName)
signal currency_id_changed(from: StringName, to: StringName)
signal currency_deleted(currency_id: StringName)
#signal currency_name_changed(id: StringName, new_name: String)
#signal currency_value_changed(id: StringName, value: int)


func ready_plugin() -> void:
	create_item()
	
	item_selected.connect(_on_item_selected)
	item_edited.connect(_on_item_edited)
	button_clicked.connect(_on_button_clicked)
	#column_title_clicked.connect(_on_column_title_clicked)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		currency_deleted.emit(item.get_metadata(0))
		item.free()


#func _on_column_title_clicked(column: int, mouse_button_index: int) -> void:
	#if mouse_button_index != MOUSE_BUTTON_LEFT:
		#return
	#
	#sorting_column = column
	#var all_items: Array[TreeItem] = get_root().get_children()
	#
	#if all_items.size() <= 1:
		#return
	#
	#all_items.sort_custom(_sort_items)
	#
	#all_items[0].move_before(get_root().get_first_child())
	#
	#for idx in range(1, all_items.size()):
		#all_items[idx].move_after(all_items[idx - 1])


#func _sort_items(a: TreeItem, b: TreeItem) -> bool:
	#return a.get_text(0).naturalnocasecmp_to(b.get_text(0)) < 0


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var column: int = get_edited_column()
	
	if column == 0: # ID
		var valid_id: String = get_unique_id(get_root(),edited.get_text(0),edited)
		if valid_id == String(edited.get_metadata(0)):
			return
		var old_id: StringName = edited.get_metadata(0)
		var new_id: StringName = StringName(valid_id)
		edited.set_metadata(0, new_id)
		sort_single_item(edited)
		currency_id_changed.emit(old_id, new_id)


func _on_item_selected() -> void:
	var selected: TreeItem = get_selected()
	if selected == null:
		return
	currency_selected.emit(selected.get_metadata(0))


func add_currency(currency_id: StringName, select: bool = false, emit_signal: bool = true) -> void:
	var new_id: String = get_unique_id(get_root(), String(currency_id))
	var new_cr: TreeItem = get_root().create_child()
	
	new_cr.set_text(0, new_id)
	new_cr.set_metadata(0, StringName(new_id))
	
	new_cr.set_editable(0, true)
	
	new_cr.add_button(
			0,
			get_theme_icon("Remove", "EditorIcons"),
			0,
			false,
			"Erase currency")
	
	sort_single_item(new_cr)
	
	if select:
		if emit_signal:
			new_cr.select(0)
		else:
			item_selected.disconnect(_on_item_selected)
			new_cr.select(0)
			item_selected.connect(_on_item_selected)


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	
	for child in get_root().get_children():
		if child == item:
			continue # We ignore the item we just added
		if item.get_text(0).naturalnocasecmp_to(child.get_text(0)) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != get_root().get_child_count() - 1:
			item.move_after(get_root().get_child(-1))


func get_currencies() -> Array[String]:
	var all_currencies: Array[String] = []
	for item in get_root().get_children():
		all_currencies.append(item.get_text(0))
	return all_currencies


func select_currency(currency_id: StringName, emit_select: bool = true) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0) == currency_id:
			if emit_select:
				item.select(0)
			else:
				item_selected.disconnect(_on_item_selected)
				item.select(0)
				item_selected.connect(_on_item_selected)


func get_currency_data() -> Dictionary:
	var all_data: Dictionary = {}
	
	for currency in get_root().get_children():
		all_data[currency.get_metadata(0)] = {
			"name": currency.get_text(1).strip_edges(),
			"value": int(currency.get_range(2))}
	
	return all_data


func clear_currencies() -> void:
	for item in get_root().get_children():
		item.free()


func search_for(text: String) -> void:
	var empty: bool = text.is_empty()
	for item in get_root().get_children():
		item.visible = empty or item.get_text(0).containsn(text)
