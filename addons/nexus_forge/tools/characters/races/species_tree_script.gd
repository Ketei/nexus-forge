extends Tree


signal species_selected(species_id: String)

var root_tree: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "Species ID")
	set_column_title(1, "Species Name")
	
	set_column_expand(0, true)
	set_column_expand(1, true)
	
	set_column_expand_ratio(0, 2)
	set_column_expand_ratio(1, 3)
	
	item_edited.connect(on_item_edited)
	item_selected.connect(on_item_selected)
	
	create_species("breeding_bitch", "Shiba Inu")


func create_species(species_id: String, species_name: String) -> void:
	var new_species = create_item(root_tree)
	var valid_id: String = validate_id(species_id)
	var new_name = "New Species" if species_name.is_empty() else species_name
	
	new_species.set_editable(0, true)
	new_species.set_editable(1, true)
	
	new_species.set_text(0, valid_id)
	new_species.set_metadata(0, valid_id)
	
	new_species.set_text(1, new_name)


func on_item_edited() -> void:
	var edited_tree: TreeItem = get_edited()
	
	if edited_tree.get_metadata(0) == edited_tree.get_text(0):
		return
	
	var new_id: String = validate_id(edited_tree.get_text(0))
	
	if edited_tree.get_text(0) != new_id:
		edited_tree.set_text(0, new_id)
	edited_tree.set_metadata(0, new_id)


func on_item_selected() -> void:
	species_selected.emit(get_selected().get_text(0))


func validate_id(desired_id: String) -> String:
	var ideal_id: String = "new_species" if desired_id.is_empty() else desired_id
	var tweaked_id: String = ideal_id
	var iteration_count: int = 1
	while has_id(tweaked_id):
		tweaked_id = str(ideal_id, "_", iteration_count)
		iteration_count += 1
	return tweaked_id


func has_id(id_to_check: String) -> bool:
	for data_tree in root_tree.get_children():
		if data_tree.get_metadata(0) == id_to_check:
			return true
	return false
