@tool
extends Tree


signal character_selected(character_sheet: CharacterSheet, unsaved: bool)
signal character_closed(resource: CharacterSheet, unsaved: bool)
#signal character_id_changed(from: StringName, to: StringName)


func ready_plugin() -> void:
	create_item()
	
	button_clicked.connect(_on_button_clicked)
	#item_edited.connect(_on_item_edited)
	item_selected.connect(_on_item_selected)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		var meta: Dictionary = item.get_metadata(0)
		character_closed.emit(meta["resource"], meta["unsaved"])


func _on_item_selected() -> void:
	var data: Dictionary = get_selected().get_metadata(0)
	character_selected.emit(
			data["resource"],
			data["unsaved"])


func is_any_unsaved() -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["unsaved"]:
			return true
	return false


func is_unsaved(character: CharacterSheet) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == character:
			return item.get_metadata(0)["unsaved"]
	return false


func set_all_saved() -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["unsaved"]:
			item.set_text(0, item.get_text(0).trim_suffix("*"))
		item.get_metadata(0)["unsaved"] = false


func clear_characters() -> void:
	for characer in get_root().get_children():
		characer.free()


func has_character(resource: CharacterSheet) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == resource:
			return true
	return false


func select_character(resource: CharacterSheet, emit_selected: bool = true) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == resource:
			if emit_selected:
				item.select(0)
			else:
				item_selected.disconnect(_on_item_selected)
				item.select(0)
				item_selected.connect(_on_item_selected)


func get_open_paths() -> Array[String]:
	var paths: Array[String] = []
	
	for item in get_root().get_children():
		paths.append(item.get_metadata(0)["resource"].resource_path)
	return paths


func create_character(resource: CharacterSheet, select: bool = false, emit_select: bool = true) -> void:
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, resource.resource_path.get_file())
	new_item.set_metadata(0, {"resource": resource, "stats": stats_to_data(resource.stats), "unsaved": false})
	new_item.add_button(
			0,
			get_theme_icon("Close", "EditorIcons"),
			0,
			false,
			"Close")
	
	sort_single_item(new_item)
	
	if select:
		if emit_select:
			new_item.select(0)
		else:
			item_selected.disconnect(_on_item_selected)
			new_item.select(0)
			item_selected.connect(_on_item_selected)


func set_unsaved(character_resource: CharacterSheet, unsaved: bool) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == character_resource:
			if unsaved:
				if not item.get_metadata(0)["unsaved"]:
					item.set_text(0, item.get_text(0) + "*")
			else:
				if item.get_metadata(0)["unsaved"]:
					item.set_text(0, item.get_text(0).trim_suffix("*"))
			item.get_metadata(0)["unsaved"] = unsaved
			return


func get_unsaved() -> Array[CharacterSheet]:
	var unsaved: Array[CharacterSheet] = []
	for item in get_root().get_children():
		if item.get_metadata(0)["unsaved"]:
			unsaved.append(item.get_metadata(0)["resource"])
	return unsaved


func remove_character(character_sheet: CharacterSheet) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == character_sheet:
			item.free()
			return


func get_valid_id(desired: StringName, skip: TreeItem = null) -> String:
	var modified: String = desired
	var iteration: int = 0
	
	while has_id(modified, skip):
		iteration += 1
		modified = desired + str(iteration)
	
	return modified


func has_id(id: String, skip: TreeItem = null) -> bool:
	for item in get_root().get_children():
		if item == skip:
			continue
		if item.get_text(0) == id:
			return true
	return false


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	
	for child in get_root().get_children():
		if child == item:
			continue # We ignore the item we just added
		
		if item.get_text(0).naturalnocasecmp_to(child.get_text(0)) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != get_root().get_child_count() - 1:
			item.move_after(get_root().get_child(-1))


func update_talent_objects() -> void:
	var stats: Dictionary[StringName, int] = StatBlock.stats()
	
	for item in get_root().get_children():
		var sheet: CharacterSheet = item.get_metadata(0)["resource"]
		var turn_unsaved: bool = false
		
		for stat in stats.keys():
			var range: ValueRange = sheet.stats.get(stat)
			if range == null:
				range = RangeInt.new() if stats[stat] == TYPE_INT else RangeFloat.new()
				sheet.stats.set(stat, range)
			var data: Dictionary[StringName, Dictionary] = item.get_metadata(0)["stats"]
			if data.has(stat):
				range.allow_greater = data[stat]["allow_greater"]
				range.allow_lesser = data[stat]["allow_lesser"]
				range.value = data[stat]["value"]
				if not turn_unsaved and data[stat]["type"] != stats[stat]:
					turn_unsaved = true
		
		for skill in SkillSet.skills():
			if sheet.skills.get(skill) == null:
				sheet.skills.set(skill, 0)
		
		for trait_id in TraitBlock.traits():
			if sheet.traits.get(trait_id) == null:
				sheet.traits.set(trait_id, 0)
		
		if turn_unsaved and not item.get_metadata(0)["unsaved"]:
			item.set_text(0, item.get_text(0) + "*")
			item.get_metadata(0)["unsaved"] = true


func stats_to_data(block: StatBlock) -> Dictionary[StringName, Dictionary]:
	if block == null:
		block = StatBlock.new(true)
	var data: Dictionary[StringName, Dictionary] = {}
	var stats: Dictionary[StringName, int] = StatBlock.stats()
	
	for stat in stats.keys():
		var item: ValueRange = block.get(stat)
		if item == null:
			item = RangeInt.new() if stats[stat] == TYPE_INT else RangeFloat.new()
			block.set(stat, item)
		data[stat] = {
			"allow_greater": item.allow_greater,
			"allow_lesser": item.allow_lesser,
			"value": item.value,
			"type": stats[stat]}
	return data


func update_sheet(sheet: CharacterSheet) -> void:
	for item in get_root().get_children():
		if item.get_metadata(0)["resource"] == sheet:
			item.get_metadata(0)["stats"] = stats_to_data(sheet.stats)
