extends Tree

const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const MAX_RANKS: int = 100

var root_tree: TreeItem = null
var _rank_range: int = 0

func _ready() -> void:
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


func add_rank(rank_idx: int, rank_id: String, rank_name: String) -> void:
	var new_rank: TreeItem = create_item(root_tree)
	
	new_rank.set_cell_mode(0, TreeItem.CELL_MODE_RANGE)
	new_rank.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	new_rank.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
	
	new_rank.set_range_config(0, 0, MAX_RANKS, 1.0)
	
	new_rank.set_editable(0, true)
	new_rank.set_editable(1, false)
	new_rank.set_editable(2, true)
	
	new_rank.set_metadata(0, rank_idx)
	
	new_rank.set_range(0, rank_idx)
	new_rank.set_text(1, rank_id)
	new_rank.set_text(2, rank_name)
	
	new_rank.add_button(2, TRASH_BIN, 0, false, "Delete Rank")
	
	update_rank_range()


func get_rank_count() -> int:
	return root_tree.get_child_count()


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			item.free()
			sort_and_fix_ranks()


func update_rank_range() -> void:
	_rank_range = root_tree.get_child_count() - 1
	var max_range: int = maxi(_rank_range, 0)
	for rank in root_tree.get_children():
		rank.set_range_config(0, 0, max_range, 1.0)


func sort_and_fix_ranks() -> void:
	var ranks: Array = root_tree.get_children()
	ranks.sort_custom(sort_custom_rank)
	
	for rank_idx in range(ranks.size()):
		ranks[rank_idx].set_range(0, rank_idx)
		ranks[rank_idx].set_metadata(0, rank_idx)


func sort_custom_rank(rank_a: TreeItem, rank_b: TreeItem) -> bool:
	return rank_a.get_range(0) < rank_a.get_range(0)


func on_rank_edited() -> void:
	var edited_rank: TreeItem = get_edited()
	
	if edited_rank.get_metadata(0) != edited_rank.get_range(0):
		edited_rank.move_before(root_tree.get_child(edited_rank.get_range(0)))
		sort_and_fix_ranks()
