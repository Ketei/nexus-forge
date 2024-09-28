extends Tree


signal item_checked

var root_tree: TreeItem
var _editable_status: bool = false


func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "ID")
	set_column_title(1, "Name")
	
	set_column_expand(0, true)
	set_column_expand(1, true)
	
	set_column_expand_ratio(0, 1)
	set_column_expand_ratio(1, 3)
	
	for stat in NFRacesRes.STATS:
		create_stat(stat)


func create_stat(stat_id: String) -> void:
	var new_stat: TreeItem = create_item(root_tree)
	
	new_stat.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_stat.set_metadata(0, false)
	new_stat.set_text(0, stat_id)
	new_stat.set_text(1, Strings.capitalize(NFRacesRes.get_stat_name(stat_id)))
	
	new_stat.set_editable(0, _editable_status)
	
	new_stat.set_selectable(1, false)


func on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	if edited.get_metadata(0) != edited.is_checked(0):
		edited.set_metadata(0, edited.is_checked(0))


func set_stat_checked(stat_id: String, set_checked: bool) -> void:
	for stat in root_tree.get_children():
		if stat.get_text(0) == stat_id:
			stat.set_checked(0, set_checked)
			break


func clear_stat_checks() -> void:
	for stat in root_tree.get_children():
		if stat.is_checked(0):
			stat.set_checked(0, false)


func get_selected_stats() -> Array:
	var enabled_stats: Array = []
	for stat in root_tree.get_children():
		if stat.is_checked(0):
			enabled_stats.append(stat.get_text(0))
	return enabled_stats


func set_editable(is_editable: bool) -> void:
	_editable_status = is_editable
	for stat in root_tree.get_children():
		stat.set_editable(0, is_editable)


func search_stat(name_id: String) -> void:
	if name_id.is_empty():
		for stat in root_tree.get_children():
			stat.visible = true
	else:
		for stat in root_tree.get_children():
			stat.visible = stat.get_text(0).containsn(name_id) or stat.get_text(1).containsn(name_id)
