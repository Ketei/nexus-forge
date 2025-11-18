@tool
extends Tree


signal item_id_dropped(item_id: StringName, on_index: int)
signal item_erased(id: StringName, on_input: bool)
signal items_changed
signal recipe_item_selected(index: int)


enum RecipeMode {
	INPUT,
	OUTPUT}

enum ButtonID {
	RECIPE_ITEM = 0,
	RECIPE_DATA = 1 }

#const BOOL_ICON = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
#const FLOAT_ICON = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
#const INT_ICON = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
#const STRING_ICON = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
#const TRASH_BIN_ICON = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")

@export var recipe_mode: RecipeMode = RecipeMode.INPUT
var recipe_selected: bool = false


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	create_item()
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 1)
	set_column_title(0, "Item ID")
	set_column_title(1, "Amount")
	
	button_clicked.connect(_on_button_clicked)
	item_selected.connect(_on_item_selected)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	
	if not recipe_selected or typeof(data) != TYPE_DICTIONARY or not data.has_all(["type", "item_id", "is_new"]):# and ( data["type"] == "item_id" ):
		return false
	
	drop_mode_flags = DROP_MODE_INBETWEEN
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data["is_new"]:
		var drop_pos: int = get_drop_section_at_position(at_position)
		var on_item: TreeItem = get_item_at_position(at_position)
		
		if drop_pos == 0:
			drop_pos = 1
		
		if drop_pos == -100 or on_item == null:
			item_id_dropped.emit(data["item_id"], get_root().get_child_count())
		elif drop_pos == -1:
			item_id_dropped.emit(data["item_id"], on_item.get_index())
		elif drop_pos == 1:
			item_id_dropped.emit(data["item_id"], on_item.get_index() + 1)
	else:
		var on_item: TreeItem = get_item_at_position(at_position)
		var external: bool = data["item"].get_parent() != get_root()
		if on_item == data["item"]:
			return
		elif on_item == null:
			if data["origin"] == recipe_mode: # Comes from this tree
				var item_count: int = get_root().get_child_count()
				if item_count == 1:
					return
				else:
					if data["item"].get_index() != item_count - 1:
						data["item"].move_after(get_root().get_child(-1))
			else: # Comes from the other tree
				data["item"].get_tree().recipe_item_selected.emit(-1)
				data["item"].get_parent().remove_child(data["item"])
				get_root().add_child(data["item"])
		else:
			if data["origin"] != recipe_mode:
				data["item"].get_tree().recipe_item_selected.emit(-1)
			match get_drop_section_at_position(at_position):
				-1: #Above
					data["item"].move_before(on_item)
				0, 1: # Below
					data["item"].move_after(on_item)
		
		items_changed.emit()


func _get_drag_data(at_position: Vector2) -> Variant:
	var selected: TreeItem = get_item_at_position(at_position)
	if selected == null:
		return null
	var label: Label = Label.new()
	label.text = selected.get_text(0) + " x " + str(int(selected.get_range(1)))
	set_drag_preview(label)
	return {"type": "item_id", "item_id": "", "is_new": false, "item": selected, "origin": recipe_mode}
	


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	if id == ButtonID.RECIPE_ITEM:
		item_erased.emit(item.get_metadata(0), recipe_mode == RecipeMode.INPUT)
	elif id == ButtonID.RECIPE_DATA:
		items_changed.emit()
	item.free()


func _on_item_selected() -> void:
	recipe_item_selected.emit(get_selected().get_index())


func get_recipe_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	
	for item in get_root().get_children():
		var data: Dictionary[String, Variant] = {}
		for data_child in item.get_children():
			data[data_child.get_text(0)] = get_data_cell_data(data_child)
		items.append(
				{
					"item_id": StringName(item.get_text(0)),
					"amount": int(item.get_range(1)),
					"data": data})
	return items


func get_data_cell_data(cell: TreeItem) -> Variant:
	match cell.get_metadata(1):
		TYPE_INT:
			return int(cell.get_range(1))
		TYPE_FLOAT:
			return float(cell.get_range(1))
		TYPE_BOOL:
			return cell.is_checked(1)
		TYPE_STRING:
			return cell.get_text(1)
		TYPE_DICTIONARY:
			var subfolder: Dictionary = {}
			for sub_data in cell.get_children():
				subfolder[sub_data.get_text(0)] = get_data_cell_data(sub_data)
			return subfolder
		TYPE_NIL:
			return cell.get_metadata(0)["data"]
		_:
			return null


func add_item(item_id: StringName, input_amount: int = 1, data: Dictionary = {}, select: bool = false, emit_select: bool = true, index: int = -1) -> void:
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, String(item_id))
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_range_config(1, 1, 9999, 1.0)
	new_item.set_range(1, input_amount)
	new_item.set_editable(1, true)
	new_item.set_metadata(0, item_id)
	
	for data_key in data:
		var new_data: TreeItem = new_item.create_child()
		new_data.set_text(0, data_key)
		new_data.set_editable(0, true)
		
		match typeof(data[data_key]):
			TYPE_INT:
				new_data.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
				new_data.set_range_config(1, -9999, 9999, 1.0)
				new_data.set_range(1, data[data_key])
				new_data.set_icon(0, get_theme_icon("int", "EditorIcons"))
				new_data.set_editable(1, true)
				new_data.set_metadata(1, TYPE_INT)
			TYPE_FLOAT:
				new_data.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
				new_data.set_range_config(1, -9999, 9999, 0.01)
				new_data.set_range(1, data[data_key])
				new_data.set_icon(0, get_theme_icon("float", "EditorIcons"))
				new_data.set_editable(1, true)
				new_data.set_metadata(1, TYPE_FLOAT)
			TYPE_BOOL:
				new_data.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
				new_data.set_checked(1, data[data_key])
				new_data.set_text(1, "Enabled")
				new_data.set_icon(0, get_theme_icon("bool", "EditorIcons"))
				new_data.set_editable(1, true)
				new_data.set_metadata(1, TYPE_BOOL)
			TYPE_STRING:
				new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
				new_data.set_text(1, data[data_key])
				new_data.set_icon(0, get_theme_icon("String", "EditorIcons"))
				new_data.set_editable(1, true)
				new_data.set_metadata(1, TYPE_STRING)
			_:
				new_data.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
				new_data.set_text(1, "Data")
				new_data.set_metadata(0, {"data": data[data_key]})
				new_data.set_editable(1, false)
				new_data.set_metadata(1, TYPE_NIL)
	
	new_item.add_button(1, get_theme_icon("Remove", "EditorIcons"), ButtonID.RECIPE_ITEM, false, "Remove Item")
	
	if -1 < index and new_item.get_index() != index:
		if 0 == index:
			new_item.move_before(get_root().get_first_child())
		elif 0 < index:
			new_item.move_after(get_root().get_child(index - 1))
	
	
	if select:
		if emit_select:
			new_item.select(0)
		else:
			item_selected.disconnect(_on_item_selected)
			new_item.select(0)
			item_selected.connect(_on_item_selected)


func remove_item(id: StringName) -> void:
	for ingredient in get_root().get_children():
		if ingredient.get_metadata(0) == id:
			ingredient.free()
			break


func change_item_id(from: StringName, to: StringName) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0) == from:
			item.set_text(0, String(to))
			item.set_metadata(0, to)


func clear_items() -> void:
	for item in get_root().get_children():
		item.free()
