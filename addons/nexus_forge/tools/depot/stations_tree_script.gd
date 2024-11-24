@tool
extends IDTree


signal station_deleted(station_id: String)
signal recipe_deleted(station_id: String, recipe_id: String)
signal recipe_selected(station_id: String, recipe_id: String)
signal recipe_created(station_id: String, recipe_id: String)
signal recipe_id_changed(station: String, from: String, to: String)
signal station_id_changed(from: String, to: String)
signal recipe_changed()
signal station_created(id: String, station_name: String)
signal station_renamed(id: String, new_name: String)


const TRASH_BIN_ICON = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const OPEN_ICON = preload("res://addons/nexus_forge/common_icons/open_file.svg")
const PLUS_ICON = preload("res://addons/nexus_forge/common_icons/plus_icon.svg")
const MAX_RECIPE_SLOTS: int = 9999

var root_tree: TreeItem = null



func _ready() -> void:
	root_tree = create_item()
	set_column_expand(0, true)
	set_column_expand(1, true)
	item_edited.connect(on_item_edited)
	button_clicked.connect(on_button_pressed)


func get_stations_and_recipes() -> Dictionary:
	var stations: Dictionary = {}
	
	for station in root_tree.get_children():
		var sation_id: String = station.get_text(0)
		stations[sation_id] = {"name": "", "recipes": []}
		for tree in station.get_children():
			if tree.get_metadata(0) == 1:
				stations[sation_id]["name"] = tree.get_text(1)
			elif tree.get_metadata(0) == 2:
				for recipe in tree.get_children():
					stations[sation_id]["recipes"].append(recipe.get_text(0))
	
	return stations


func create_station(station_id: String, recipes: Array) -> void:
	var new_station: TreeItem = create_item(root_tree)
	var new_id: String = validate_id(root_tree, station_id, new_station)
	var name_cell: TreeItem = create_item(new_station)
	var recipes_cell: TreeItem = create_item(new_station)
	
	new_station.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	name_cell.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	recipes_cell.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	
	new_station.set_metadata(0, {"idx": 0, "id": new_id})
	name_cell.set_metadata(0, {"idx": 1})
	recipes_cell.set_metadata(0, {"idx": 2})
	
	name_cell.set_cell_mode(1, TreeItem.CELL_MODE_STRING)
	
	name_cell.set_text(0, "Name")
	name_cell.set_text(1, "New Station")
	recipes_cell.set_text(0, "Recipes")
	new_station.set_text(0, new_id)
	
	new_station.set_editable(0, true)
	name_cell.set_editable(1, true)
	recipes_cell.set_editable(0, false)
	recipes_cell.set_editable(1, false)
	recipes_cell.set_selectable(0, false)
	new_station.set_selectable(1, false)
	name_cell.set_selectable(0, false)
	
	for recipe in recipes:
		var new_recipe: TreeItem = create_item(recipes_cell)
		new_recipe.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
		
		new_recipe.set_text(0, recipe)
		new_recipe.set_metadata(0, {"idx": 3, "id": recipe})
		
		new_recipe.add_button(1, OPEN_ICON, 1, false, "Edit Recipe")
		new_recipe.add_button(1, TRASH_BIN_ICON, 0, false, "Delete Recipe")
		
		new_recipe.set_selectable(0, true)
		new_recipe.set_selectable(1, false)
		
		new_recipe.set_editable(0, true)
	
	recipes_cell.add_button(1, PLUS_ICON, 2, false, "Create Recipe")
	
	new_station.add_button(
			1,
			TRASH_BIN_ICON,
			0,
			false,
			"Delete Station")
	
	new_station.set_collapsed_recursive(true)
	
	station_created.emit(new_id, "New Station")


func on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var cell_id: int = item.get_metadata(0)["idx"]
	match id:
		0: # Delete Button
			if cell_id == 0:
				station_deleted.emit(item.get_text(0))
			elif cell_id == 3:
				var station_id: String = item.get_parent().get_parent().get_text(0)
				recipe_deleted.emit(station_id, item.get_text(0))
			item.free()
		1: # Edit Recipe
			var station_id: String = item.get_parent().get_parent().get_text(0)
			recipe_selected.emit(station_id, item.get_text(0))
		2: # Add new recipe
			if item.collapsed:
				item.collapsed = false
			recipe_created.emit(item.get_parent().get_metadata(0)["id"], create_recipe(item))


func create_recipe(tree_item: TreeItem) -> String:
	var new_item: TreeItem = create_item(tree_item)
	var new_recipe_id: String = validate_id(tree_item, "new_recipe", new_item)
	new_item.set_text(0, new_recipe_id)
	new_item.set_metadata(0, {"idx": 3, "id": new_recipe_id})
	new_item.set_metadata(1, new_recipe_id)
	new_item.add_button(1, OPEN_ICON, 1, false, "Edit Recipe")
	new_item.add_button(1, TRASH_BIN_ICON, 0, false, "Delete Recipe")
	new_item.set_selectable(0, true)
	new_item.set_selectable(1, false)
	new_item.set_editable(0, true)
	return new_recipe_id


func on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var edited_meta: Dictionary = edited.get_metadata(0)
	var edited_id: int = edited_meta["idx"]
	var edited_cell: int = get_edited_column()
	
	if edited_id == 0: # Station ID changed
		var new_id: String = validate_id(root_tree, edited.get_text(0), edited)
		station_id_changed.emit(edited_meta["id"], new_id)
		edited.set_text(0, new_id)
		edited_meta["id"] = new_id
	elif edited_id == 1: # Station Renamed
		station_renamed.emit(edited.get_parent().get_metadata(0)["id"], edited.get_text(1))
	elif edited_id == 3: # Recipe ID changed
		var new_id: String = validate_id(edited.get_parent(), edited.get_text(0), edited)
		recipe_id_changed.emit(edited.get_parent().get_parent().get_metadata(0)["id"], edited_meta["id"], new_id)
		edited.set_text(0, new_id)
		edited_meta["id"] = new_id
	
	#elif edited_id == 2 or edited_id == 3:
		#await get_tree().process_frame # Waiting for the tree to unblock
		#var new_size: int = edited.get_range(1)
		#var child_count: int = edited.get_child_count()
		#if child_count < new_size: # Add more slots
			#for remaining in range(new_size - child_count):
				#var new_slot: TreeItem = create_item(edited)
				#
				#new_slot.set_cell_mode(0, TreeItem.CELL_MODE_RANGE)
				#new_slot.set_editable(0, true)
				#new_slot.set_editable(1, true)
				#
				#new_slot.set_metadata(0, 4)
			#var new_child: int = edited.get_child_count()
			#var slots: Array[TreeItem] = edited.get_children()
			#for slot_idx in range(slots.size()):
				#slots[slot_idx].set_range_config(0, 0, new_child - 1, 1.0)
				#slots[slot_idx].set_range(0, slot_idx)
		#
		#elif new_size < child_count: # Remove slots
			#var child_array: Array[TreeItem]  = edited.get_children()
			#for slot_idx in range(new_size, child_array.size()):
				#child_array[slot_idx].free()
	#elif edited_id == 4:
		#var parent: TreeItem = edited.get_parent()
		#var current_pos: int = edited.get_index()
		#var target_position: int = edited.get_range(0)
		#if target_position < current_pos:
			#edited.move_before(parent.get_child(target_position))
		#else:
			#edited.move_after(parent.get_child(target_position))
		#
		#var all_child: Array[TreeItem] = parent.get_children()
		#
		#for child_idx in range(all_child.size()):
			#all_child[child_idx].set_range(0, child_idx)


func search_item(search_value: String) -> void:
	for variable in root_tree.get_children():
		if search_value.is_empty() or variable.get_text(0).containsn(search_value):
			variable.visible = true
		else:
			for property in variable.get_children():
				if property.get_metadata(0)["idx"] != 2:
					continue
				var recipe_found: bool = false
				
				for recipe in property.get_children():
					if recipe.get_text(0).containsn(search_value):
						recipe_found = true
						break
				
				variable.visible = recipe_found


func clear_stations() -> void:
	for station in root_tree.get_children():
		station.free()
