@tool
extends Tree


signal species_created(species_id: StringName, item: TreeItem)
signal species_selected(species_id: StringName)
signal species_erased(species_id: Array[StringName])
signal species_id_changed(from: StringName, to: StringName)

const LineEditConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd")

enum ButtonID {
	CREATE_SPECIES,
	ERASE_SPECIES}

enum PopUpID {
	CREATE_SPECIES,
	ERASE_SPECIES,
	CHANGE_ID
}

var current_search: String = ""
var _races_menu: PopupMenu
var _popup_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	
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
	if not event is InputEventKey or not has_focus() or event.is_echo() or not event.keycode == KEY_DELETE:
		return
	
	var selected: TreeItem = get_selected()
	
	if event.is_echo() or get_selected() == null:
		return
	
	accept_event()
	
	var all_species: Array[StringName] = get_subspecies_of(selected)
	all_species.append(selected.get_metadata(0))
	
	if 0 < selected.get_child_count():
		var dialog := preload("res://addons/nexus_forge/dialogs/confirmation.gd").new()
		
		dialog.title = "Delete species tree..."
		dialog.dialog_text = str("Delete ", selected.get_text(0),  " and all subspecies?")
		dialog.ok_button_text = "Delete All"
		dialog.cancel_button_text = "Cancel"
		dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		add_child(dialog)
		dialog.show()
		
		var delete: bool = await dialog.dialog_finished
		
		if not delete:
			dialog.queue_free()
			return
	
	selected.free()
	species_erased.emit(all_species)


func _get_drag_data(at_position: Vector2) -> Variant:
	var node: TreeItem = get_item_at_position(at_position)
	if node == null:
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
	return target_node != data["node"] and not _has_parent(target_node, data["node"])


func _has_parent(item: TreeItem, to: TreeItem) -> bool:
	if item == null or to == null:
		return false
	
	var current_item: TreeItem = item
	while current_item.get_parent() != null:
		if current_item == to:
			return true
		current_item = current_item.get_parent()
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if get_drop_section_at_position(at_position) == -100:
		data["node"].get_parent().remove_child(data["node"])
		get_root().add_child(data["node"])
	else:
		var on_node: TreeItem = get_item_at_position(at_position)
		data["node"].get_parent().remove_child(data["node"])
		on_node.add_child(data["node"])
	sort_single_item(data["node"])


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var selected: TreeItem = get_selected()
	
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_popup_pos = mouse_position
		_races_menu.position = DisplayServer.mouse_get_position()
		_races_menu.popup()
	
	species_selected.emit(selected.get_metadata(0))


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var valid_name: String = get_valid_id(edited.get_text(0), edited)
	
	if valid_name == String(edited.get_metadata(0)):
		return
	
	var old_id: StringName = edited.get_metadata(0)
	var new_id: StringName = StringName(valid_name)
	
	edited.set_text(0, valid_name)
	edited.set_metadata(0, new_id)
	
	sort_single_item(edited)
	
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
			var new_race: TreeItem = add_species(race_id, false, item)
			species_created.emit(
					race_id,
					new_race)
		
		id_creator.queue_free()
	elif id == ButtonID.ERASE_SPECIES:
		var types: Array[StringName] = [item.get_metadata(0)]
		species_erased.emit(types)
		item.free()


func get_all_species() -> Array[String]:
	return _get_races_on(get_root())


func _get_races_on(_tree: TreeItem) -> Array[String]:
	var races: Array[String] = []
	for child in _tree.get_children():
		races.append(child.get_text(0))
		races.append_array(_get_races_on(child))
	return races


func add_species(race_id: StringName, select: bool = false, on: TreeItem = get_root()) -> TreeItem:
	var new_race: TreeItem = on.create_child()
	new_race.set_text(0, String(race_id))
	new_race.set_metadata(0, race_id)
	new_race.set_editable(0, true)
	
	new_race.add_button(
			0,
			preload("res://addons/nexus_forge/icons/dna_plus.svg"),
			0,
			false,
			"New subspecies")
	
	if select:
		new_race.select(0)
	
	sort_single_item(new_race)
	
	return new_race


func get_subspecies_of(item: TreeItem) -> Array[StringName]:
	var subspecies: Array[StringName] = []
	
	for species_item in item.get_children():
		subspecies.append(species_item.get_metadata(0))
		subspecies.append_array(get_subspecies_of(species_item))
	
	return subspecies


func get_species_tree(_from: TreeItem = get_root()) -> Dictionary:
	var species: Dictionary = {}
	
	for child in _from.get_children():
		species[child.get_metadata(0)] = get_species_tree(child)
	
	return species


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
	for item in get_root().get_children():
		item.free()
