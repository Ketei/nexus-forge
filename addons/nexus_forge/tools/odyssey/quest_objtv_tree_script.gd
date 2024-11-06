@tool
extends IDTree


signal objective_deleted(objective_id: String)
signal objective_selected(objective_id: String)
signal objective_id_changed(from: String, to: String)
signal objectives_reordered
signal objective_created(objective_id: String)

const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
var root_tree: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	id_cell = 1
	
	set_column_expand(0, false)
	set_column_expand(1, true)
	
	set_column_custom_minimum_width(0, 72)
	
	item_selected.connect(on_item_selected)
	button_clicked.connect(on_button_pressed)
	item_edited.connect(on_item_edited)


func add_item(id: String) -> void:
	var new_objective: TreeItem = create_item(root_tree)
	new_objective.set_cell_mode(0, TreeItem.CELL_MODE_RANGE)
	new_objective.set_editable(0, true)
	new_objective.set_range(0, root_tree.get_child_count() - 1)
	
	recalculate_range_limit()
	
	new_objective.set_text(1, validate_id(root_tree, id, new_objective))
	new_objective.add_button(1, TRASH_BIN, 0, false, "Delete Objective")
	new_objective.set_editable(1, true)
	new_objective.set_metadata(1, new_objective.get_text(1))
	objective_created.emit(new_objective.get_text(1))


func recalculate_range_limit() -> void:
	var new_max = root_tree.get_child_count() - 1
	for child in root_tree.get_children():
		child.set_range_config(0, 0, new_max, 1.0)


func search_item(search: String) -> void:
	for objective in root_tree.get_children():
		objective.visible = search.is_empty() or objective.get_text(1).containsn(search)


func clear_items() -> void:
	for child in root_tree.get_children():
		child.free()


func get_objectives() -> Array:
	var objectives: Array = []
	
	for idx in range(root_tree.get_child_count()):
		objectives.append(root_tree.get_child(idx).get_text(1))
	
	return objectives


func on_item_selected() -> void:
	var selected: TreeItem = get_selected()
	
	if selected != null:
		objective_selected.emit(selected.get_text(1))


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if id == 0:
		objective_deleted.emit(item.get_text(1))
		item.free()
		recalculate_range_limit()


func on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	
	match get_edited_column():
		0:
			if edited.get_range(0) < edited.get_index():
				edited.move_before(root_tree.get_child(edited.get_range(0)))
			else:
				edited.move_after(root_tree.get_child(edited.get_range(0)))
			fix_indexes()
			objectives_reordered.emit()
		1:
			edited.set_text(
					1,
					validate_id(root_tree, edited.get_text(1), edited))
			objective_id_changed.emit(edited.get_metadata(1), edited.get_text(1))
			edited.set_metadata(1, edited.get_text(1))


func fix_indexes() -> void:
	for child in root_tree.get_children():
		child.set_range(0, child.get_index())


func get_obj_index(quest_id: String) -> int:
	for child in root_tree.get_children():
		if child.get_text(0) == quest_id:
			return child.get_index()
	return -1
