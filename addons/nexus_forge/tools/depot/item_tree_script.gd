@tool
extends IDTree


signal item_id_pressed(item_id: String, item_path: String)
signal item_deleted(item_id: String, item_path: String)
signal id_changed(from: String, to: String)

const BIN_ICON = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const COPY_ICON = preload("res://addons/nexus_forge/common_icons/copy_icon.svg")

var root_tree: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	button_clicked.connect(on_button_pressed)
	item_selected.connect(on_item_selected)
	item_edited.connect(on_item_edited)
	
	set_column_expand(0, true)


func is_selected(item_path: String) -> bool:
	var selected_item: TreeItem = get_selected()
	
	return selected_item != null and selected_item.get_metadata(0)["path"] == item_path


func select_item(item_path: String) -> void:
	for item in root_tree.get_children():
		if item.get_metadata(0)["path"] == item_path:
			item.select(0)
			break


func get_items_serialized() -> Array[Dictionary]:
	var item_array: Array[Dictionary] = []
	for item in root_tree.get_children():
		item_array.append(
			{
				"key": item.get_text(0),
				"file": item.get_metadata(0)["path"]
			}
		)
	return item_array


func clear_items() -> void:
	for item in root_tree.get_children():
		item.free()


func add_item(item_key: String, item_path: String) -> String:
	var new_item: TreeItem = create_item(root_tree)
	
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	
	new_item.set_text(0, validate_id(root_tree, item_key, new_item))
	new_item.set_metadata(0, {"id": item_key, "path": item_path})
	
	new_item.set_editable(0, true)
	
	new_item.add_button(0, COPY_ICON, 1, false, "Copy ID")
	new_item.add_button(0, BIN_ICON, 0, false, "Remove Item")
	
	return new_item.get_text(0)


func on_item_edited() -> void:
	var edited_item: TreeItem = get_edited()
	var original_id: String = edited_item.get_metadata(0)["id"]
	var new_id: String = validate_id(root_tree, edited_item.get_text(0), edited_item)
	edited_item.set_text(0, new_id)
	id_changed.emit(original_id, new_id)
	edited_item.get_metadata(0)["id"] = new_id


func match_ids() -> void:
	for item in root_tree.get_children():
		item.get_metadata(0)["id"] = item.get_text(0)


func has_item(id: String) -> bool:
	for item in root_tree.get_children():
		if item.get_text(0) == id:
			return true
	return false


func select_by_file(file_path: String) -> void:
	var simplified_path: String = file_path.simplify_path()
	for item in root_tree.get_children():
		if item.get_metadata(0).simplify_path() == file_path:
			item_id_pressed.emit(item.get_text(0), item.get_metadata(0)["path"])


func has_file(file: String) -> TreeItem:
	var simplified_path: String = file.simplify_path()
	for item in root_tree.get_children():
		if item.get_metadata(0).simplify_path() == file:
			return item
	return null


func on_item_selected() -> void:
	var item_selected: TreeItem = get_selected()
	item_id_pressed.emit(item_selected.get_text(0), item_selected.get_metadata(0)["path"])


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if id == 0: #Delete Pressed
		item_deleted.emit(item.get_text(0), item.get_metadata(0)["path"])
		item.free()
	elif id == 1: # Copy ID pressed
		DisplayServer.clipboard_set(item.get_text(0))


func search_item(search_value: String) -> void:
	var search_id: int = -1 if not search_value.is_valid_int() else int(search_value)
	
	for item in root_tree.get_children():
		item.visible = search_value.is_empty() or item.get_text(1).containsn(search_value) or item.get_range(0) == search_id
