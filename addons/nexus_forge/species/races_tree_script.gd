@tool
extends Tree


signal species_created(species_id: StringName)
signal species_selected(species_id: StringName)
signal erase_species_requested(species_id: StringName)
signal species_id_changed(from: StringName, to: StringName)
signal something_changed
signal species_dehibridized(species_id: StringName, dom: StringName, sub: StringName)
signal species_moved(species: StringName, from: StringName, to: StringName)

const LineEditConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd")

enum ButtonID {
	CREATE_SPECIES,
	ERASE_SPECIES,
	GO_TO_HYBRID,}

enum PopUpID {
	CREATE_SPECIES,
	ERASE_SPECIES,
	CHANGE_ID
}

var current_search: String = ""
var _races_menu: PopupMenu
var _popup_pos: Vector2 = Vector2.ZERO

var _hybrid_pointers: Dictionary[StringName, Dictionary] = {}
var _species_trees: Dictionary[StringName, TreeItem] = {}
var _species_block: Dictionary[StringName, Array] = {}


func ready_plugin() -> void:
	_races_menu = PopupMenu.new()
	_races_menu.add_icon_item(
			preload("res://addons/nexus_forge/icons/dna_plus.svg"),
			"Add Subspecies",
			PopUpID.CREATE_SPECIES)
	_races_menu.add_icon_item(
			get_theme_icon("Edit", "EditorIcons"),
			"Edit ID",
			PopUpID.CHANGE_ID)
	_races_menu.add_icon_item(
			get_theme_icon("Remove", "EditorIcons"),
			"Remove Species",
			PopUpID.ERASE_SPECIES)
	_races_menu.size = Vector2i.ZERO
	add_child(_races_menu)
	create_item()
	
	item_edited.connect(_on_item_edited)
	item_mouse_selected.connect(_on_item_mouse_selected, CONNECT_DEFERRED)
	button_clicked.connect(_on_button_clicked)
	_races_menu.id_pressed.connect(_on_popup_id_pressed)


func _on_popup_id_pressed(id: int) -> void:
	var target: TreeItem = get_item_at_position(_popup_pos)
	
	match id:
		PopUpID.CREATE_SPECIES:
			_on_button_clicked(target, 0, ButtonID.CREATE_SPECIES, MOUSE_BUTTON_LEFT)
		PopUpID.CHANGE_ID:
			edit_selected()
		PopUpID.ERASE_SPECIES:
			_on_button_clicked(target, 0, ButtonID.ERASE_SPECIES, MOUSE_BUTTON_LEFT)


func _gui_input(event: InputEvent) -> void:
	# Must be keypress
	# Have focus
	# Not be an echo
	# And be the delete key
	if not has_focus():
		return
	
	if event is InputEventKey:
		if event.echo or not event.pressed:
			return
		
		if event.keycode == KEY_DELETE:
			var selected: TreeItem = get_selected()
			
			accept_event()
			
			if selected == null:
				return
			
			if selected.get_metadata(0)["is_pointer"]: # We're pointing. Turn hybrid normal
				var species_id: StringName = selected.get_metadata(0)["id"]
				var dominant_species: StringName = _hybrid_pointers[species_id]["dom"]
				var submissive: StringName = _hybrid_pointers[species_id]["sub"]
				remove_hybrid_pointer(selected)
				species_dehibridized.emit(species_id, get_dominant_gene(species_id), dominant_species, submissive)
				return
			
			erase_species_requested.emit(selected.get_metadata(0)["id"])


func dehybridize_species(species: StringName, new_dom: StringName = &"") -> void:
	if not _hybrid_pointers.has(species) or (not new_dom.is_empty() and not _species_trees.has(new_dom)):
		return
	
	var tree: TreeItem = _species_trees[species]
	var target: TreeItem = get_root() if new_dom.is_empty() else _species_trees[new_dom]
	
	if _hybrid_pointers[species]["dom"] != null:
		_hybrid_pointers[species]["dom"].free()
	if _hybrid_pointers[species]["sub"] != null:
		_hybrid_pointers[species]["sub"].free()
	
	_hybrid_pointers.erase(species)
	
	tree.get_parent().remove_child(tree)
	target.add_child(tree)
	sort_single_item(tree)
	


func remove_hybrid_link(hybrid: StringName, remove_species: StringName) -> void:
	if not _hybrid_pointers.has_all([hybrid, remove_species]):
		return
	
	var target_pointer: TreeItem = null
	
	if _hybrid_pointers[hybrid]["dom"] != null and _hybrid_pointers[hybrid]["dom"].get_metadata(0)["id"] == remove_species:
		target_pointer = _hybrid_pointers[hybrid]["dom"]
	elif _hybrid_pointers[hybrid]["sub"] != null and _hybrid_pointers[hybrid]["sub"].get_metadata(0)["id"] == remove_species:
		target_pointer = _hybrid_pointers[hybrid]["sub"]
	
	if target_pointer != null:
		remove_hybrid_pointer(target_pointer)


func remove_hybrid_pointer(pointer: TreeItem) -> void:
	var selected_id: StringName = pointer.get_metadata(0)["id"]
	var hybrid: TreeItem = _species_trees[selected_id]
	var new_parent: TreeItem = null
	if _hybrid_pointers[selected_id]["dom"] == pointer:
		new_parent = _hybrid_pointers[selected_id]["sub"].get_parent()
	else:
		new_parent = _hybrid_pointers[selected_id]["dom"].get_parent()
	
	hybrid.get_parent().remove_child(hybrid)
	new_parent.add_child(hybrid)
	
	_hybrid_pointers[selected_id]["dom"].free()
	_hybrid_pointers[selected_id]["sub"].free()
	
	_hybrid_pointers.erase(selected_id)
	sort_single_item(hybrid)


func _scan_for_hybrid_pointers(from: TreeItem) -> Array[TreeItem]:
	var all_ids: Array[TreeItem] = []
	for item in from.get_children():
		if item.get_metadata(0)["is_pointer"]:
			all_ids.append(item)
		all_ids.append_array(_scan_for_hybrid_pointers(item))
	return all_ids


func _get_drag_data(at_position: Vector2) -> Variant:
	var node: TreeItem = get_item_at_position(at_position)
	if node == null or node.get_metadata(0)["is_pointer"] or _hybrid_pointers.has(node.get_metadata(0)["id"]):
		return null
	
	var data: Dictionary = {
		"type": "species",
		"node": node}
	var preview: Label = Label.new()
	preview.text = "   " + node.get_text(0)
	set_drag_preview(preview)
	return data


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has_all(["type", "node"]) or data["type"] != "species":
		return false
	
	drop_mode_flags = DROP_MODE_ON_ITEM
	
	var target_node: TreeItem = get_item_at_position(at_position)
	
	if target_node == null:
		return true
	
	var grabbed_id: StringName = data["node"].get_metadata(0)["id"]
	var is_grabbed_pointer: bool = data["node"].get_metadata(0)["is_pointer"]
	var target_id: StringName = target_node.get_metadata(0)["id"]
	var is_target_pointer: bool = target_node.get_metadata(0)["is_pointer"]
	
	return not species_has_subspecies(grabbed_id, target_id) and can_link_species(grabbed_id, target_id) and not is_target_pointer and target_node != data["node"] and not species_has_ancestor(target_id, grabbed_id)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var new_parent: TreeItem = get_item_at_position(at_position)
	var dropped_item: TreeItem = data["node"]
	var original_parent: TreeItem = dropped_item.get_parent()
	var root: TreeItem = get_root()
	
	if new_parent == null:
		new_parent = root
	
	if original_parent == new_parent:
		return
	
	var original_p_id: StringName = &"" if original_parent == root else original_parent.get_metadata(0)["id"]
	var new_p_id: StringName = &"" if new_parent == root else new_parent.get_metadata(0)["id"]
	
	original_parent.remove_child(dropped_item)
	new_parent.add_child(dropped_item)
	sort_single_item(dropped_item)
	species_moved.emit(dropped_item.get_metadata(0)["id"], original_p_id, new_p_id)


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var selected: TreeItem = get_selected()
	
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_races_menu.set_item_disabled(0, selected.get_metadata(0)["is_pointer"])
		_races_menu.set_item_text(
			2,
			"Dehybridize" if selected.get_metadata(0)["is_pointer"] else "Remove Species")
		_popup_pos = mouse_position
		_races_menu.position = DisplayServer.mouse_get_position()
		_races_menu.popup()
	
	species_selected.emit(selected.get_metadata(0)["id"])


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	edited.set_text(0, edited.get_text(0).strip_edges())
	var valid_name: String = get_valid_id(edited.get_text(0), edited)
	
	if valid_name == String(edited.get_metadata(0)["id"]):
		return
	
	var old_id: StringName = edited.get_metadata(0)["id"]
	var new_id: StringName = StringName(valid_name)
	
	set_species_id(old_id, new_id)
	
	species_id_changed.emit(old_id, new_id)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == ButtonID.CREATE_SPECIES:
		var id_creator := LineEditConfirmationDialog.new()
		id_creator.line_placeholder_text = "Subspecies ID"
		id_creator.allow_empty = false
		id_creator.use_blacklist = true
		id_creator.character_blacklist.append(" ")
		id_creator.text_blacklist.assign(get_all_species())
		id_creator.title = "Create Subspecies"
		id_creator.ok_button_text = "Create"
		add_child(id_creator)
		id_creator.show()
		id_creator.grab_text_focus()
		
		var result: Array = await id_creator.dialog_finished
		
		if result[0]:
			var race_id: StringName = StringName(result[1])
			_add_species_on(race_id, item.get_metadata(0)["id"])
			species_created.emit(race_id)
		
		id_creator.queue_free()
	elif id == ButtonID.ERASE_SPECIES:
		erase_species_requested.emit(item.get_metadata(0)["id"])
	elif id == ButtonID.GO_TO_HYBRID:
		var target: TreeItem = _species_trees[item.get_metadata(0)["id"]]
		ensure_uncollapsed(item.get_metadata(0)["id"])
		target.select(0)
		ensure_cursor_is_visible()
		if not item.is_selected(0):
			species_selected.emit(item.get_metadata(0)["id"])


func set_species_id(old_id: StringName, new_id: StringName) -> void:
	if not _species_trees.has(old_id) or _species_trees.has(new_id):
		return
	
	var target: TreeItem = _species_trees[old_id]
	var valid_name: String = String(new_id)
	
	if _hybrid_pointers.has(old_id):
		var pointers: Array = [
			_hybrid_pointers[old_id]["dom"],
			_hybrid_pointers[old_id]["sub"]]
		_hybrid_pointers[new_id] = _hybrid_pointers[old_id]
		_hybrid_pointers.erase(old_id)
		
		for pointer: TreeItem in pointers:
			pointer.set_text(0, valid_name)
			pointer.get_metadata(0)["id"] = new_id
			sort_single_item(pointer)
	
	target.set_text(0, valid_name)
	target.get_metadata(0)["id"] = new_id
	
	_species_trees[new_id] = _species_trees[old_id]
	_species_trees.erase(old_id)
	
	sort_single_item(target)



func select_species(species_id: StringName, emit_select: bool) -> void:
	if not _species_trees.has(species_id):
		return
	
	_species_trees[species_id].select(0)
	
	if emit_select:
		species_selected.emit(species_id)


func has_species(species_id: StringName) -> bool:
	return _species_trees.has(species_id)


func erase_species(species_id: StringName) -> bool:
	if not _species_trees.has(species_id):
		return false
	
	var target: TreeItem = _species_trees[species_id]
	
	var hybrid_pointers_erased: Dictionary[TreeItem, Variant] = {}
	
	for pointer in _scan_for_hybrid_pointers(target):
		if hybrid_pointers_erased.has(pointer):
			continue
		hybrid_pointers_erased[pointer] = null
	
	for pointer in hybrid_pointers_erased.keys():
		remove_hybrid_pointer(pointer)
	
	if _hybrid_pointers.has(species_id):
		_hybrid_pointers[species_id]["dom"].free()
		_hybrid_pointers[species_id]["sub"].free()
		_hybrid_pointers.erase(species_id)
	
	_species_trees.erase(species_id)
	target.free()
	
	return true


func is_species_hybrid(species_id: StringName) -> bool:
	return _hybrid_pointers.has(species_id)


func get_hybrid_species_of(species_id: StringName) -> Array[String]:
	var hybrids: Array[String] = []
	if not _species_trees.has(species_id):
		return hybrids
	
	for direct_child in _species_trees[species_id].get_children():
		if not direct_child.get_metadata(0)["is_pointer"]:
			continue
		hybrids.append(direct_child.get_metadata(0)["id"])
	return hybrids


func species_has_ancestor(species: StringName, ancestor: StringName) -> bool:
	if not _species_trees.has_all([species, ancestor]):
		return false
	elif species == ancestor:
		return true
	
	var current: TreeItem = _species_trees[species].get_parent()
	var root: TreeItem = get_root()
	while current != root and current != null:
		if current.get_metadata(0)["id"] == ancestor:
			return true
		current = current.get_parent()
	
	return false


func can_link_species(which: StringName, to: StringName) -> bool:
	if _species_block.has(which):
		return not _species_block[which].has(to)
	return true


func get_dominant_gene(of_species: StringName) -> StringName:
	if _hybrid_pointers.has(of_species):
		return _hybrid_pointers[of_species]["dom"].get_parent().get_metadata(0)["id"]
	return &""


func get_parent_species_of(species: StringName) -> StringName:
	if _species_trees.has(species):
		var parent: TreeItem = _species_trees[species].get_parent()
		if parent == get_root():
			return &""
		else:
			return parent.get_metadata(0)["id"]
	return &""


func get_recessive_gene(of_species: StringName) -> StringName:
	if _hybrid_pointers.has(of_species):
		return _hybrid_pointers[of_species]["sub"].get_parent().get_metadata(0)["id"]
	return &""


func get_all_species() -> Array[String]:
	var races: Array[String] = []
	for race in _species_trees.values():
		races.append(race.get_text(0))
	return races


func create_species(species_id: StringName, on_species: StringName = &"") -> void:
	if _add_species_on(species_id, on_species):
		sort_single_item(_species_trees[species_id])


func _add_species_on(new_id: StringName, on_species: StringName) -> bool:
	if _species_trees.has(new_id):
		var parent_tree: TreeItem = _species_trees[new_id].get_parent()
		var parent_id: StringName = &"" if parent_tree == get_root() else _species_trees[new_id].get_parent().get_metadata(0)["id"]
		if parent_id != on_species:
			NFPluginGameHandler._log_msg(
					"kindred - editor",
					"Subspecies '%s' already exists under parent species '%s', can't add to '%s'." % [new_id, on_species, "[ORIGIN]" if parent_id.is_empty() else parent_id],
					NFPluginGameHandler._LogLevel.ERROR)
		return false
	elif not on_species.is_empty() and not _species_trees.has(on_species):
		NFPluginGameHandler._log_msg(
				"kindred - editor",
				"Unable to create subspecies '%s' on inexistent species '%s'." % [new_id, on_species],
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	elif species_has_subspecies(on_species, new_id):
		return false
	
	var target: TreeItem = get_root() if on_species.is_empty() else _species_trees[on_species]
	
	var new_race: TreeItem = target.create_child()
	new_race.set_text(0, String(new_id))
	new_race.set_metadata(0, {"id": new_id, "is_pointer": false})
	new_race.set_editable(0, true)
	
	new_race.add_button(
			0,
			preload("res://addons/nexus_forge/icons/dna_plus.svg"),
			0,
			false,
			"New subspecies")
	
	_species_trees[new_id] = new_race
	
	return true


func hybridize_species(hybrid_id: StringName, dominant: StringName, recessive: StringName) -> void:
	var all_species: Array[StringName] = [hybrid_id, dominant, recessive]
	
	if not _species_trees.has_all(all_species):
		return
	
	var hybrid: TreeItem = _species_trees[hybrid_id]
	
	var root: TreeItem = get_root()
	
	var dominant_block: TreeItem = _species_trees[dominant]
	while dominant_block.get_parent() != root and dominant_block != null:
		dominant_block = dominant_block.get_parent()
	
	var submissive_block: TreeItem = _species_trees[recessive]
	while submissive_block.get_parent() != root and submissive_block != null:
		submissive_block = submissive_block.get_parent()
	
	if dominant_block != null:
		if not _species_block.has(dominant_block.get_metadata(0)["id"]):
			_species_block[dominant_block.get_metadata(0)["id"]] = []
		if not _species_block[dominant_block.get_metadata(0)["id"]].has(hybrid_id):
			_species_block[dominant_block.get_metadata(0)["id"]].append(hybrid_id)
	
	if submissive_block != null:
		if not _species_block.has(submissive_block.get_metadata(0)["id"]):
			_species_block[submissive_block.get_metadata(0)["id"]] = []
		if not _species_block[submissive_block.get_metadata(0)["id"]].has(hybrid_id):
			_species_block[submissive_block.get_metadata(0)["id"]].append(hybrid_id)
	
	# Move the hybrid node to the top.
	# Add species pointers to parent a and b
	
	hybrid.get_parent().remove_child(hybrid)
	get_root().add_child(hybrid)
	
	sort_single_item(hybrid)
	
	add_hybrid_pointer_on(dominant, hybrid_id, true)
	add_hybrid_pointer_on(recessive, hybrid_id, false)


func add_hybrid_pointer_on(species: StringName, pointer_id: StringName, dominant: bool) -> void:
	if not _species_trees.has(species):
		return
	
	var pointer: TreeItem = _species_trees[species].create_child()
	pointer.set_metadata(0, {"id": pointer_id, "is_pointer": true})
	pointer.set_text(0, String(pointer_id))
	pointer.set_editable(0, true)
	sort_single_item(pointer)
	if not _hybrid_pointers.has(pointer_id):
		_hybrid_pointers[pointer_id] = {"dom": null, "sub": null}
	if dominant:
		_hybrid_pointers[pointer_id]["dom"] = pointer
	else:
		_hybrid_pointers[pointer_id]["sub"] = pointer
	
	pointer.set_custom_color(0, Color(0.778, 0.633, 1.0))
	pointer.add_button(
			0,
			load("res://addons/nexus_forge/icons/dna_goto.svg"),
			ButtonID.GO_TO_HYBRID,
			false,
			"Go to Hybrid Entry")


func set_species_as_subspecies_of(species: StringName, dom_species: StringName) -> void:
	if not _species_trees.has(species) or (not dom_species.is_empty() and not _species_trees.has(dom_species)):
		return
	
	var target: TreeItem = _species_trees[species]
	var new_parent: TreeItem = get_root() if dom_species.is_empty() else _species_trees[dom_species]
	
	if target.get_parent() == new_parent:
		return
	
	target.get_parent().remove_child(target)
	new_parent.add_child(target)
	
	sort_single_item(target)


func get_subspecies_of(species_id: StringName) -> Array[StringName]:
	var subspecies: Array[StringName] = []
	
	if not _species_trees.has(species_id):
		return subspecies
	
	for species_item in _species_trees[species_id].get_children():
		subspecies.append(species_item.get_metadata(0)["id"])
		subspecies.append_array(get_subspecies_of(species_item.get_metadata(0)["id"]))
	
	return subspecies


func has_subspecies(species_id: StringName) -> bool:
	if _species_trees.has(species_id):
		return 0 < _species_trees[species_id].get_child_count()
	return false


func get_subspecies_map_of(species_id: StringName) -> Dictionary[StringName, Dictionary]:
	var map: Dictionary[StringName, Dictionary] = {}
	if not _species_trees.has(species_id):
		return map
	map = {
		species_id: {
			"hybrid_flag": is_species_hybrid(species_id),
			"dominant": get_dominant_gene(species_id),
			"recessive": get_recessive_gene(species_id),
			"subspecies": _map_subspecies_of(species_id)}}
	
	return map


func get_natural_subspecies_of(species_id: StringName) -> Array[StringName]:
	var sub_keys: Array[StringName] = []
	if not _species_trees.has(species_id):
		return sub_keys
	var subspecies: Dictionary[StringName, Variant] = {}
	
	_recursive_get_subspecies_of(species_id, false, subspecies)
	sub_keys.assign(subspecies.keys())
	return sub_keys


func _recursive_get_subspecies_of(species_id: StringName, include_hybrid: bool, _on: Dictionary[StringName, Variant]) -> void:
	for subspecies in _species_trees[species_id].get_children():
		var id: StringName = subspecies.get_metadata(0)["id"]
		if is_species_hybrid(id):
			if include_hybrid:
				_on[id] = null
		else:
			_on[id] = null
		_recursive_get_subspecies_of(id, include_hybrid, _on)


func _map_subspecies_of(species_id: StringName) -> Dictionary[StringName, Dictionary]:
	var map: Dictionary[StringName, Dictionary] = {}
	
	if not _species_trees.has(species_id):
		return map
	
	for item in _species_trees[species_id].get_children():
		var sub_id: StringName = item.get_metadata(0)["id"]
		map[sub_id] = {
				"hybrid_flag": item.get_metadata(0)["is_pointer"],
				"dominant": get_dominant_gene(sub_id),
				"recessive": get_recessive_gene(sub_id),
				"subspecies": _map_subspecies_of(sub_id)}
	return map


func _restore_tree(map: Dictionary, on_species: StringName = &"") -> void:
	if not on_species.is_empty() and not _species_trees.has(on_species):
		return
	
	_iterate_restore_species(map, on_species)
	_iterate_restore_hybrid_pointers(map)


func _iterate_restore_species(map: Dictionary, on: StringName) -> void:
	for species_id in map.keys():
		if map[species_id]["hybrid_flag"]:
			if not _species_trees.has(species_id):
				_add_species_on(species_id, &"")
		else:
			_add_species_on(species_id, on)
		
		_iterate_restore_species(map[species_id]["subspecies"], species_id)


func _iterate_restore_hybrid_pointers(map: Dictionary) -> void:
	for id in map.keys():
		if map[id]["hybrid_flag"]:
			hybridize_species(id, map[id]["dominant"], map[id]["recessive"])
		
		_iterate_restore_hybrid_pointers(map[id]["subspecies"])


func get_species_tree(_from: TreeItem = get_root()) -> Dictionary:
	var species: Dictionary = {}
	
	for child in _from.get_children():
		species[child.get_metadata(0)["id"]] = get_species_tree(child)
	
	return species


func get_species_map() -> Array[Dictionary]:
	var map: Array[Dictionary] = []
	var root: TreeItem = get_root()
	
	for species_id in _species_trees.keys():
		var dominant_species: StringName = &""
		var recessive_species: StringName = &""
		
		if _hybrid_pointers.has(species_id):
			dominant_species = _hybrid_pointers[species_id]["dom"].get_parent().get_metadata(0)["id"]
			recessive_species = _hybrid_pointers[species_id]["sub"].get_parent().get_metadata(0)["id"]
		else:
			var parent: TreeItem = _species_trees[species_id].get_parent()
			dominant_species = &"" if parent == root else parent.get_metadata(0)["id"]
		map.append({
			"species_id": species_id,
			"dominant_species": dominant_species,
			"recessive_species": recessive_species})
	
	return map


func search_species(text: String) -> void:
	if current_search == text:
		return
	
	if text.is_empty():
		_show_all_species()
	else:
		for species in get_root().get_children():
			species.visible = _search_subspecies(text, species)
	
	current_search = text


func _show_all_species(_from: TreeItem = get_root()) -> void:
	for species in _from.get_children():
		species.visible = true
		_show_all_species(species)


func _search_subspecies(text: String, species: TreeItem) -> bool:
	var found: bool = false
	for child in species.get_children():
		child.visible = child.get_text(0).containsn(text) or _search_subspecies(text, child)
		if not found and child.visible:
			found = true
	return found


func get_valid_id(desired: String, skip_item: TreeItem = null) -> String:
	var all_species: Array[String] = get_all_species()
	var modified: String = desired
	var iteration: int = 0
	
	if skip_item != null:
		all_species.erase(skip_item.get_text(0))
	
	while all_species.has(modified):
		iteration += 1
		modified = desired + str(iteration)
	
	return modified


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	
	for child in item.get_parent().get_children():
		if child == item:
			continue # We ignore the item we just added
		
		if item.get_text(0).naturalnocasecmp_to(child.get_text(0)) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != item.get_parent().get_child_count() - 1:
			item.move_after(get_root().get_child(-1))


func clear_species() -> void:
	_species_trees.clear()
	_hybrid_pointers.clear()
	for item in get_root().get_children():
		item.free()


func species_has_subspecies(subspecies: StringName, species: StringName = &"") -> bool:
	if not species.is_empty() and not _species_trees.has(species):
		return false
	
	var target: TreeItem = get_root() if species.is_empty() else _species_trees[species]
	
	for item in target.get_children():
		if item.get_metadata(0)["id"] == subspecies:
			return true
	return false


func ensure_uncollapsed(species: StringName) -> void:
	if not _species_trees.has(species):
		return
	var step: TreeItem = _species_trees[species].get_parent()
	
	while step != get_root() and step != null:
		step.collapsed = false
		step = step.get_parent()
