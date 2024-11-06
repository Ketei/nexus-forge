@tool
extends IDTree


signal material_removed(material_id: String)
const BIN_ICON = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()


func add_material(material_id: String) -> void:
	var new_material: TreeItem = create_item(root_tree)
	
	new_material.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	
	new_material.set_editable(0, true)
	
	new_material.set_text(0, Strings.capitalize(material_id))
	new_material.set_metadata(0, material_id)


func get_selected_materials() -> Array:
	var selected: Array = []
	for mat in root_tree.get_children():
		if mat.is_checked(0):
			selected.append(mat.get_text(0))
	return selected


func select_material(material_id: String) -> void:
	for mat in root_tree.get_children():
		if mat.get_metadata(0) == material_id:
			mat.set_checked(0, true)


func select_materials(materials: Array) -> void:
	for item_material in materials:
		select_material(item_material)


func uncheck_materials() -> void:
	for mat in root_tree.get_children():
		mat.set_checked(0, false)


func clear_materials() -> void:
	for mat in root_tree.get_children():
		mat.free()
