@tool
extends Tree


var root_tree: TreeItem
var editable: bool = false


func _ready() -> void:
	root_tree = create_item()
	reload_flags()


func reload_flags() -> void:
	clear_flags()
	var perk_flags_val: Array = NFTalentsRes.PerkFlags.values()
	var perk_flags_names: Array = NFTalentsRes.PerkFlags.keys() 
	
	for flag_idx in range(perk_flags_names.size()):
		var new_flag: TreeItem = create_item(root_tree)
		
		new_flag.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		
		new_flag.set_text(0, Strings.title_case(perk_flags_names[flag_idx].replace("_", " ")))
		new_flag.set_metadata(0, perk_flags_val[flag_idx])
		
		new_flag.set_editable(0, editable)


func get_flags() -> int:
	var flags: int = 0
	
	for flag in root_tree.get_children():
		if flag.is_checked(0):
			flags |= 1 << flag.get_metadata(0)
	
	return flags


func set_flags(flags: int) -> void:
	for flag in root_tree.get_children():
		flag.set_checked(
			0,
			flags & (1 << flag.get_metadata(0)) != 0) 


func clear_checks() -> void:
	for flag in root_tree.get_children():
		if flag.is_checked(0):
			flag.set_checked(0, false)


func set_editable(is_editable: bool) -> void:
	editable = is_editable
	for flag in root_tree.get_children():
		flag.set_editable(0, is_editable)


func clear_flags() -> void:
	for flag in root_tree.get_children():
		flag.free()
