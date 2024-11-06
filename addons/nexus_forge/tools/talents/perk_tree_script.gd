@tool
extends IDTree


signal perk_max_level_changed(perk: String, new_level: int)
signal id_edited(from: String, to: String)
signal perk_deleted(perk_id: String)
signal perk_selected(perk_id: String)
signal perk_created(perk_id: String)


const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const MAX_PERK_LEVEL: int = 1000
var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "ID")
	set_column_title(1, "Name")
	set_column_title(2, "Max Level")
	
	set_column_expand(0, true)
	set_column_expand(1, true)
	set_column_expand(2, false)
	
	set_column_custom_minimum_width(2, 75)
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 3)
	
	item_selected.connect(on_item_selected)
	button_clicked.connect(on_button_pressed)
	item_edited.connect(on_perk_edited)


func add_perk(perk_id: String, perk_name: String, max_level: int, select_on_create: bool = false) -> void:
	var new_perk: TreeItem = create_item(root_tree)
	
	new_perk.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_perk.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	new_perk.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_perk.set_editable(0, true)
	new_perk.set_editable(1, true)
	new_perk.set_editable(2, true)
	
	new_perk.set_range_config(2, 1, MAX_PERK_LEVEL, 1.0)
	
	new_perk.set_text(0, validate_id(root_tree, perk_id, new_perk))
	new_perk.set_metadata(0, new_perk.get_text(0))
	new_perk.set_text(1, perk_name)
	
	new_perk.set_range(2, max_level)
	new_perk.set_metadata(2, 1)
	
	new_perk.add_button(2, TRASH_BIN, 0, false, "Delete Perk")
	perk_created.emit(new_perk.get_text(0))
	
	if select_on_create:
		new_perk.select(0)


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			perk_deleted.emit(item.get_text(0))
			item.free()


func on_item_selected() -> void:
	perk_selected.emit(get_selected().get_text(0))


func on_perk_edited() -> void:
	var perk_edited: TreeItem = get_edited()
	
	if perk_edited != get_selected():
		return
	
	match get_edited_column():
		0: # ID
			perk_edited.set_text(0, validate_id(root_tree, perk_edited.get_text(0), perk_edited))
			id_edited.emit(perk_edited.get_metadata(0), perk_edited.get_text(0))
			perk_edited.set_metadata(0, perk_edited.get_text(0))
		2: # Level
			perk_max_level_changed.emit(perk_edited.get_text(0), perk_edited.get_range(2))


func get_selected_id() -> String:
	return get_selected().get_text(0)


func get_selected_name() -> String:
	return get_selected().get_text(1)


func get_selected_level() -> float:
	return get_selected().get_range(2)


func any_perk_selected() -> bool:
	return get_selected() != null


func perk_count() -> int:
	return root_tree.get_child_count()


func clear_perks() -> void:
	for perk in root_tree.get_children():
		perk.free()


func remove_perk(perk_id: String) -> void:
	for perk in root_tree.get_children():
		if perk.get_text(0) == perk_id:
			perk.free()


func find_perk(perk_text: String) -> void:
	var perk_fixed: String = perk_text.strip_edges().to_lower()
	for perk in root_tree.get_children():
		perk.visible = perk_fixed.is_empty() or perk.get_text(0).containsn(perk_fixed) or perk.get_text(1).containsn(perk_fixed)


func get_perk_data() -> Dictionary:
	var perk_data: Dictionary = {}
	for perk in root_tree.get_children():
		perk_data[perk.get_text(0)] = {
			"name": perk.get_text(1),
			"level": int(perk.get_range(2))}
	return perk_data


func get_perk_ids() -> Array[String]:
	var ids: Array[String] = []
	for perk in root_tree.get_children():
		ids.append(perk.get_text(0))
	return ids
