@tool
extends IDTree


signal rank_renamed(from: String, to: String)

const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")

var root_tree: TreeItem = null


func _ready() -> void:
	id_cell = 1
	root_tree = create_item()
	item_edited.connect(on_rank_edited)
	
	set_column_title(0, "Rank")
	set_column_title(1, "ID")
	set_column_title(2, "Title")
	
	set_column_expand(0, false)
	set_column_expand(1, true)
	set_column_expand(2, true)
	
	set_column_custom_minimum_width(0, 75)
	
	button_clicked.connect(on_button_pressed)


func clear_ranks() -> void:
	for rank in root_tree.get_children():
		rank.free()


func add_rank(rank_idx: int, rank_id: String, rank_name: String) -> String:
	var new_rank: TreeItem = create_item(root_tree)
	var max_index: int = root_tree.get_child_count() - 1
	
	new_rank.set_cell_mode(0, TreeItem.CELL_MODE_RANGE)
	new_rank.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	new_rank.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
	
	update_rank_range()
	
	new_rank.set_editable(0, true)
	new_rank.set_editable(1, true)
	new_rank.set_editable(2, true)
	
	if rank_idx != -1 and rank_idx < max_index:
		new_rank.move_before(root_tree.get_child(rank_idx))
		sort_and_fix_ranks()
	else:
		new_rank.set_range(0, new_rank.get_index())
	
	new_rank.set_text(1, validate_id(root_tree, rank_id, new_rank))
	new_rank.set_metadata(1, new_rank.get_text(1))
	new_rank.set_text(2, rank_name)
	
	new_rank.add_button(2, TRASH_BIN, 0, false, "Delete Rank")
	
	return new_rank.get_text(1)


func search_rank(rank_search: String) -> void:
	if rank_search.is_valid_int():
		var rank_level: float = float(rank_search)
		for rank in root_tree.get_children():
			rank.visible = rank.get_range(0) == rank_level
	else:
		for rank in root_tree.get_children():
			rank.visible = rank_search.is_empty() or rank.get_text(1).containsn(rank_search) or rank.get_text(2).containsn(rank_search)



func get_rank_count() -> int:
	return root_tree.get_child_count()


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			item.free()
			update_rank_range()
			sort_and_fix_ranks()


func update_rank_range() -> void:
	var max_range: int = root_tree.get_child_count() - 1
	for rank in root_tree.get_children():
		rank.set_range_config(0, 0, max_range, 1.0)


func sort_and_fix_ranks() -> void:
	for rank in root_tree.get_children():
		rank.set_range(0, rank.get_index())


func on_rank_edited() -> void:
	var edited_rank: TreeItem = get_edited()
	
	match get_edited_column():
		0: 
			if edited_rank.get_range(0) < edited_rank.get_index():
				edited_rank.move_before(root_tree.get_child(edited_rank.get_range(0)))
			else:
				edited_rank.move_after(root_tree.get_child(edited_rank.get_range(0)))
		1:
			edited_rank.set_text(1, validate_id(root_tree, edited_rank.get_text(1), edited_rank))
			rank_renamed.emit(edited_rank.get_metadata(1), edited_rank.get_text(1))
			edited_rank.set_metadata(1, edited_rank.get_text(1))
		
	sort_and_fix_ranks()


func get_ranks() -> Array:
	var rank_dict: Array = []
	for rank_idx in range(root_tree.get_child_count()):
		var tree: TreeItem = root_tree.get_child(rank_idx)
		rank_dict.append(
				{"name": tree.get_text(2),
				"id": tree.get_text(1)})
	return rank_dict
