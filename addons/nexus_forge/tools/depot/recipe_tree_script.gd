@tool
extends Tree


signal recipe_changed

const MAX_ITEM_COUNT: int = 9999
var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "Slot")
	set_column_title(1, "Item")
	set_column_title(2, "Amount")
	
	set_column_expand(0, false)
	set_column_expand(1, true)
	set_column_expand(2, false)
	
	set_column_custom_minimum_width(0, 50)
	set_column_custom_minimum_width(2, 92)
	item_edited.connect(on_item_edited)


func on_item_edited() -> void:
	recipe_changed.emit()


func create_item_slot() -> void:
	var new_slot: TreeItem = create_item(root_tree)
	
	new_slot.set_cell_mode(0, TreeItem.CELL_MODE_RANGE)
	new_slot.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	new_slot.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_slot.set_range_config(0, 0, 100_000, 1.0)
	new_slot.set_range_config(2, 0, MAX_ITEM_COUNT, 1.0)
	
	new_slot.set_range(0, new_slot.get_index())
	
	new_slot.set_selectable(0, false)
	new_slot.set_editable(0, false)
	new_slot.set_editable(1, true)
	new_slot.set_editable(2, true)


func set_slot_recipe(recipe_slot: int, recipe_item: String, count: int) -> void:
	var recipe_tree: TreeItem = root_tree.get_child(recipe_slot)
	
	recipe_tree.set_text(1, recipe_item)
	recipe_tree.set_range(2, count)


func get_current_recipe() -> Array[Dictionary]:
	var recipe: Array[Dictionary] = []
	
	for input in root_tree.get_children():
		recipe.append({
			"item": input.get_text(1),
			"count": int(input.get_range(2))
		})
	
	return recipe


func set_slot_count(slot_count: int) -> void:
	var target_count: int = maxi(0, slot_count)
	var current_count: int = root_tree.get_child_count()
	
	if target_count < current_count:
		var current_children: Array[TreeItem] = root_tree.get_children()
		for extra_slot in range(target_count, current_count):
			current_children[extra_slot].free()
		recipe_changed.emit()
	elif current_count < target_count:
		for new_idx in range(target_count - current_count):
			create_item_slot()
		recipe_changed.emit()


func reset_slots() -> void:
	for slot in root_tree.get_children():
		slot.set_text(1, "")
		slot.set_range(2, 0)


func clear_item_slots() -> void:
	for item_slot in root_tree.get_children():
		item_slot.free()
