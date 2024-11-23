@tool
extends Tree


signal flag_selected(flag_id: int, selected: bool)

var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	item_edited.connect(on_item_edited)


func on_item_edited() -> void:
	var flag: TreeItem = get_edited()
	flag_selected.emit(flag.get_metadata(0), flag.is_checked(0))


func add_flag(flag_id: int, flag_text: String) -> void:
	var new_flag: TreeItem = create_item(root_tree)
	new_flag.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_flag.set_text(0, flag_text)
	new_flag.set_editable(0, true)
	new_flag.set_metadata(0, flag_id)


func reset_flags() -> void:
	for flag in root_tree.get_children():
		if flag.is_checked(0):
			flag.set_checked(0, false)


func set_flags(flags: int) -> void:
	for flag in root_tree.get_children():
		flag.set_checked(
				0,
				(flags & (1 << flag.get_metadata(0))) != 0)


func clear_flags() -> void:
	for flag in root_tree.get_children():
		flag.free()


func get_flags() -> int:
	var flags: int = 0
	
	for flag_tree:TreeItem in root_tree.get_children():
		if not flag_tree.is_checked(0):
			continue
		flags |= 1 << flag_tree.get_metadata(0)
	
	return flags
