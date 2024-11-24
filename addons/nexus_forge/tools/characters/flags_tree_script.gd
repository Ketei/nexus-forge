@tool
extends Tree


var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	set_column_expand(0, true)
	
	load_flags()


func load_flags() -> void:
	var flag_strings = NFRacesRes.Flags.keys()
	for flag in NFRacesRes.Flags.values():
		var new_flag: TreeItem = create_item(root_tree)
		new_flag.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		new_flag.set_text(0, Strings.title_case(flag_strings[flag].replace("_", " ")))
		new_flag.set_metadata(0, flag)
		
		new_flag.set_selectable(0, false)
		
		new_flag.set_editable(0, true)


func set_flag(flag_index: NFRacesRes.Flags, set_checked: bool) -> void:
	var target_flag: TreeItem = null
	for flag in root_tree.get_children():
		if flag.get_metadata(0) == flag_index:
			target_flag = flag
			break
	if target_flag == null:
		printerr("Something went wrong when looking to switch a flag")
		return
	
	target_flag.set_checked(0, set_checked)


func set_flags(flags: int) -> void:
	for flag in root_tree.get_children():
		flag.set_checked(
				0,
				(flags & (1 << flag.get_metadata(0))) != 0)


func clear_flags() -> void:
	for flag_tree:TreeItem in root_tree.get_children():
		flag_tree.free()


func reset_flags() -> void:
	for flag_tree:TreeItem in root_tree.get_children():
		if flag_tree.is_checked(0):
			flag_tree.set_checked(0, false)


func get_flags() -> int:
	var flags: int = 0
	
	for flag_tree:TreeItem in root_tree.get_children():
		if not flag_tree.is_checked(0):
			continue
		flags |= 1 << flag_tree.get_metadata(0)
	
	return flags
