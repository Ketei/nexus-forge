@tool
extends IDTree


const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const RANGE_MAX: int = 9999
var root_tree: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	
	set_column_custom_minimum_width(1, 48)


func clear_items() -> void:
	for child in root_tree.get_children():
		child.free()


func add_item(trigger_id: String, trigger_count: int = 1, eval: int = 0) -> void:
	var new_trigger: TreeItem = create_item(root_tree)
	
	new_trigger.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_trigger.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_trigger.set_range_config(1, 0, 5, 1.0)
	new_trigger.set_range_config(2, 0, RANGE_MAX, 1.0)
	
	new_trigger.set_text(1, "==,!=,<,>,<=,>=")
	new_trigger.set_text(0, validate_id(root_tree, trigger_id, new_trigger))
	new_trigger.set_range(2, trigger_count)
	new_trigger.set_range(1, eval)
	
	new_trigger.add_button(2, TRASH_BIN, 0, false, "Delete trigger")
	
	new_trigger.set_editable(0, true)
	new_trigger.set_editable(1, true)
	new_trigger.set_editable(2, true)


func get_data() -> Dictionary:
	var data_dict: Dictionary = {}
	for trigger in root_tree.get_children():
		data_dict[trigger.get_text(0)] = {
			"amount": int(trigger.get_range(2)),
			"match": int(trigger.get_range(1))}
	return data_dict


func search_item(search: String) -> void:
	for item in root_tree.get_children():
		item.visible = search.is_empty() or item.get_text(0).containsn(search)


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if id == 0:
		item.free()


func on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	match get_edited_column():
		0:
			edited.set_text(0, validate_id(root_tree, edited.get_text(0), edited))
