@tool
extends Tree

signal calculation_updated(new_value: int)


func ready_plugin() -> void:
	create_item()
	set_column_title(0, "Currency")
	set_column_title(1, "Amount")
	item_edited.connect(_on_item_edited)


func add_currency(id: StringName, title: String, value: int) -> void:
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, title)
	new_item.set_tooltip_text(0, String(id))
	new_item.set_metadata(1, {"value": value, "id": id})
	
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_range_config(1, 0, 1_000_000, 1.0)
	new_item.set_range(0, 1.0)
	new_item.set_editable(1, true)
	new_item.set_editable(0, false)
	
	sort_currency_item(new_item)


func update_currency_value(id: StringName, value: int) -> void:
	for item in get_root().get_children():
		if item.get_metadata(1)["id"] != id:
			continue
		item.get_metadata(1)["value"] = value
		_on_item_edited.call_deferred()
		return


func remove_currency(id: StringName) -> void:
	for item in get_root().get_children():
		if item.get_metadata(1)["id"] != id:
			continue
		item.free()
		_on_item_edited.call_deferred()
		break


func sort_currency_item(new_item: TreeItem) -> void:
	var new_val: int = _get_currency_value(new_item)
	
	for sibling in get_root().get_children():
		if sibling == new_item:
			continue
		
		var sibling_val: int = _get_currency_value(sibling)
		
		if sibling_val < new_val:
			new_item.move_before(sibling)
			return


func reset_table() -> void:
	for item in get_root().get_children():
		item.set_range(1, 0)
	update_calculation()


func update_calculation() -> void:
	var new_value: int = 0
	for item in get_root().get_children():
		new_value += _get_currency_value(item) * item.get_range(1)
	calculation_updated.emit(new_value)


func _get_currency_value(item: TreeItem) -> int:
	var meta = item.get_metadata(1)
	
	if typeof(meta) == TYPE_DICTIONARY and meta.has("value") and typeof(meta["value"]) == TYPE_INT:
		return meta["value"]
	return 0


func _on_item_edited() -> void:
	update_calculation()
