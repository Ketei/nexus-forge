@tool
class_name NFEditorItemRecipeLink
extends RefCounted
## An object used to sync the Depot and the Blueprints module.

## Emits when an item was created.
signal item_created(id: StringName, name: String)
## Emits when an item was renamed.
signal item_renamed(id: StringName, new_name: String)
## Emits when the ID of an item changed.
signal item_id_changed(from: StringName, to: StringName)
## Emits when an item was erased.
signal item_erased(item_id: StringName)

## A pointer to the currenlty loaded [NFItemCatalog].
var items: NFItemCatalog = null
## A pointer to the currently loaded [NFRecipeCatalog].
var recipes: NFRecipeCatalog = null


## Creates an item on the item catalog and emits the relevant signal.
func create_item(id: StringName) -> void:
	if items == null:
		return
	if not items._items.has(id):
		items.create_item(id, "", "", &"", 0, 0, [], {})
		item_created.emit(id, "New Item")


## Sets the name of item [param id] to [param new_name] and then
## emits relevant signals.
func set_item_name(id: StringName, new_name: StringName) -> void:
	if items._items.has(id):
		items.set_item_name(id, new_name)
		item_renamed.emit(id, new_name)


## Changes the ID of the item [param from] to [param to]. If
## a recipe pointer is loaded, it'll also change the ID of the matching
## item recipes. After that emits relevan signals.
## [br][br]
## [b]Note:[/b] Signal only emits if a [member recipes] pointer
## is loaded.
func change_item_id(from: StringName, to: StringName) -> void:
	if items._items.has(from) == false:
		return
	
	items._items[to] = items._items[from]
	items._items.erase(from)
	
	if recipes == null:
		return
	
	for recipe in recipes.recipes():
		for input in recipes._recipes[recipe]["input"]:
			if input["item_id"] == from:
				input["item_id"] = to
		
		for output in recipes._recipes[recipe]["output"]:
			if output["item_id"] == from:
				output["item_id"] = to
	
	item_id_changed.emit(from, to)


## Erases the item [param item_id]. Then, if [member recipes] is
## loaded, removes [param item_id] from all recipes. After it emits
## relevant signals.
func erase_item(item_id: StringName) -> void:
	if items == null:
		return
	
	if items._items.has(item_id):
		items.erase_item(item_id)
	
	if recipes != null:
		_remove_from_recipes(item_id)
	
	item_erased.emit(item_id)


func _remove_from_recipes(item_id: StringName) -> void:
	for recipe_id in recipes.recipes():
		var idx: int = -1
		for input: Dictionary in recipes._recipes[recipe_id]["input"].duplicate():
			idx += 1
			if input["item_id"] == item_id:
				recipes._recipes[recipe_id]["input"].erase(input)
		idx = -1
		for output:Dictionary in recipes._recipes[recipe_id]["output"].duplicate():
			idx += 1
			if output["item_id"] == item_id:
				recipes._recipes[recipe_id]["output"].erase(output)
