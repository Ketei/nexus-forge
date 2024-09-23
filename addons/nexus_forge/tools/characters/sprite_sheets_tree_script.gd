extends Tree


const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")

var root_tree: TreeItem = null

func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "ID")
	set_column_title(1, "Path")
	
	set_column_expand(0, true)
	set_column_expand(1, true)
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 3)


func create_sheet_path() -> void:
	var new_sheet: TreeItem = create_item(root_tree)
	new_sheet.set_text(0, validate_sprite_id("new_sprite_sheet"))
	new_sheet.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	
	new_sheet.add_button(1, TRASH_BIN, -1, false, "Remove SpriteSheet")
	
	new_sheet.set_editable(0, true)
	new_sheet.set_editable(1, true)


func validate_sprite_id(variant_id: String) -> String:
	var desired_id: String = "new_variant" if variant_id.is_empty() else variant_id
	var modified_id: String = desired_id
	var iteration_count: int = 1
	while has_id(modified_id):
		modified_id = str(desired_id, "_", iteration_count)
		iteration_count += 1
	return modified_id


func has_id(id_string: String) -> bool:
	for item in root_tree.get_children():
		if item.get_text(0) == id_string:
			return true
	return false


func clear_sprite_sheets() -> void:
	for child in root_tree.get_children():
		child.free()


func get_sprites_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for alt in root_tree.get_children():
		data.append({"id": alt.get_text(0), "path": alt.get_text(1)})
	return data
