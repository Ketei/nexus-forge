extends IDTree


signal recipe_selected(recipe_id: String)
signal recipe_deleted(recipe_id: String)

const TRASH_ICON = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")

var root_tree: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	
	button_clicked.connect(on_button_pressed)
	item_edited.connect(on_item_edited)
	
	create_recipe("wood_to_charcoal")
	create_recipe("wood_to_charcoal")


func create_recipe(recipe_id: String) -> void:
	var new_recipe: TreeItem = create_item(root_tree)
	var new_id: String = validate_id(root_tree, recipe_id, new_recipe)
	
	new_recipe.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_recipe.set_editable(0, true)
	
	new_recipe.add_button(0, TRASH_ICON, 0, false, "Delete Recipe")
	
	new_recipe.set_text(0, new_id)


func on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	edited.set_text(0, validate_id(root_tree, edited.get_text(0), edited))


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	recipe_deleted.emit(item.get_text(0))
	item.free()


func search_item(search_value: String) -> void:
	for variable in root_tree.get_children():
		variable.visible = search_value.is_empty() or variable.get_text(0).containsn(search_value)
