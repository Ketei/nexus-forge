@tool
extends Tree


signal item_id_dropped(item_id: StringName)
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
	if recipe_selected:
		return typeof(data) == TYPE_DICTIONARY and data.has_all(["type", "item_id"]) and data["type"] == "item_id"
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_id_dropped.emit(data["item_id"])


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


func add_item(item_id: StringName, input_amount: int = 1, data: Dictionary = {}, select: bool = false, emit_select: bool = true) -> void:
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
