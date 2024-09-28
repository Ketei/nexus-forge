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
