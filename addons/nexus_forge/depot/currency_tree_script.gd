@tool
extends IDTree


signal currency_selected(currency: StringName)
signal currency_id_changed(from: StringName, to: StringName)
signal currency_deleted(currency_id: StringName)


var currencies: Dictionary[StringName, TreeItem] = {}


func ready_plugin() -> void:
	create_item()
	
	item_mouse_selected.connect(_on_item_selected)
	item_edited.connect(_on_item_edited)
	button_clicked.connect(_on_button_clicked)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		var curr_id: StringName = item.get_metadata(0)
		erase_currency(curr_id)
		currency_deleted.emit(curr_id)


func erase_currency(currency_id: StringName) -> void:
	if currencies.has(currency_id):
		var target: TreeItem = currencies[currency_id]
		currencies.erase(currency_id)
		target.free()


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


func _on_item_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var selected: TreeItem = get_selected()
	if selected == null:
		return
	currency_selected.emit(selected.get_metadata(0))


func change_currency_id(from: StringName, to: StringName) -> void:
	if not currencies.has(from) or currencies.has(to):
		return
	
	var target: TreeItem = currencies[from]
	currencies[to] = currencies[from]
	currencies.erase(from)
	target.set_text(0, String(to))
	target.set_metadata(0, to)


func add_currency(currency_id: StringName, select: bool = false, emit_selected: bool = true) -> void:
	var new_id: StringName = StringName(get_unique_id(get_root(), String(currency_id)))
	_add_currency_to_tree(new_id)
	
	if select:
		currencies[new_id].select(0)
		if emit_selected:
			currency_selected.emit(new_id)


func _add_currency_to_tree(currency_id: StringName) -> bool:
	if currencies.has(currency_id):
		return false
	
	var new_cr: TreeItem = get_root().create_child()
	
	new_cr.set_text(0, String(currency_id))
	new_cr.set_metadata(0, currency_id)
	
	new_cr.set_editable(0, true)
	
	new_cr.add_button(
			0,
			get_theme_icon("Remove", "EditorIcons"),
			0,
			false,
			"Erase currency")
	
	sort_single_item(new_cr)
	
	currencies[currency_id] = new_cr
	
	return true


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


func select_currency(currency_id: StringName, emit_selected: bool = true) -> void:
	for tree in get_root().get_children():
		if tree.get_metadata(0) == currency_id:
			tree.select(0)
			if emit_selected:
				currency_selected.emit(currency_id)


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
