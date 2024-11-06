@tool
extends Tree


var root_tree: TreeItem = null
var _flags_editable: bool = false

func _ready() -> void:
	root_tree = create_item()
	
	var flags_string = NFFactionRes.FactionFlags.keys()
	var flags_values = NFFactionRes.FactionFlags.values()
	
	for flag_value in flags_values:
		var new_flag = create_item(root_tree)
		new_flag.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		new_flag.set_text(0, Strings.title_case(flags_string[flag_value].replace("_", " ")))
		new_flag.set_editable(0, _flags_editable)
		new_flag.set_metadata(0, flag_value)


func get_flags() -> int:
	var flags: int = 0
	for flag in root_tree.get_children():
		if flag.is_checked(0):
			flags |= 1 << flag.get_metadata(0)
	return flags
	

func search_flags(flag_text: String) -> void:
	if flag_text.is_valid_int():
		var flag_val: int = int(flag_text)
		for flag in root_tree.get_children():
			flag.visible = flag.get_metadata(0) == flag_val
	else:
		for flag in root_tree.get_children():
			flag.visible = flag_text.is_empty() or flag.get_text(0).containsn(flag_text)


func set_flags(flags: int) -> void:
	for flag in root_tree.get_children():
		flag.set_checked(
				0,
				(flags & (1 << flag.get_metadata(0))) != 0)


func clear_flags() -> void:
	for flag in root_tree.get_children():
		flag.set_checked(0, false)


func set_editable(is_editable: bool) -> void:
	_flags_editable = is_editable
	for flag in root_tree.get_children():
		flag.set_editable(0, is_editable)
