@tool
extends Tree


signal quest_selected
signal stage_selected(stage: StringName)
signal objective_selected(of_stage: StringName, objective: StringName)

signal stage_created(stage_id: StringName)
signal objective_created(stage_id: StringName, objective_id: StringName)

signal quest_id_changed(from: StringName, to: StringName)
signal stage_id_changed(from: StringName, to: StringName)
signal objective_id_changed(on_stage: StringName, from: StringName, to: StringName)

signal entry_stage_selected(stage_id: StringName)

signal stage_duplicated(from: StringName, duplicate_id: StringName)
signal objective_duplicated(from_stage: StringName, objective: StringName, duplicate_id: StringName)

signal stage_moved(stage_id: StringName, from_index: int, to_index: int)
signal objective_moved(objective_id: StringName, from_stage: StringName, from_index: int, to_stage: StringName, to_index: int)
signal stage_erased(stage_id: StringName, index: int)
signal objective_erased(from_stage: StringName, objective_id: StringName, index: int)


enum ItemType {
	QUEST,
	STAGE,
	OBJECTIVE}

enum ButtonID {
	ADD_STAGE,
	ADD_OBJECTIVE}

enum PopupItemID{
	ADD_ITEM,
	EDIT_ITEM,
	DUPLICATE,
	REMOVE_ITEM,
	SET_ENTRY,
}

const ENTRY_COLOR: Color = Color(0.443, 0.737, 0.988)

var root: TreeItem
var quest_popup: PopupMenu
var right_position: Vector2 = Vector2.ZERO


func ready_plugin() -> void:
	quest_popup = PopupMenu.new()
	quest_popup.size = Vector2i(145, 10)
	add_child(quest_popup)
	
	quest_popup.add_icon_item(get_theme_icon("Add", "EditorIcons"), "Add", PopupItemID.ADD_ITEM)
	quest_popup.add_icon_item(get_theme_icon("Edit", "EditorIcons"), "Edit ID", PopupItemID.EDIT_ITEM)
	quest_popup.add_icon_item(get_theme_icon("Duplicate", "EditorIcons"), "Duplicate", PopupItemID.DUPLICATE)
	quest_popup.add_icon_item(get_theme_icon("Remove", "EditorIcons"), "Remove", PopupItemID.REMOVE_ITEM)
	quest_popup.add_separator()
	quest_popup.add_item("Set as entry", PopupItemID.SET_ENTRY)
	quest_popup.id_pressed.connect(_on_popup_id_pressed)
	
	item_mouse_selected.connect(_on_item_clicked)
	button_clicked.connect(_on_button_clicked)
	item_edited.connect(_on_item_edited)


func _get_drag_data(at_position: Vector2) -> Variant:
	var item: TreeItem = get_item_at_position(at_position)
	if item == null or item.get_metadata(0)["type"] == ItemType.QUEST:
		return null
	
	var preview: Label = Label.new()
	preview.text = "   " + item.get_text(0)
	set_drag_preview(preview)
	
	return {"type": "quest_item", "item": item}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has_all(["type", "item"]) or typeof(data["type"]) != TYPE_STRING or typeof(data["item"]) != TYPE_OBJECT or data["item"] is not TreeItem or data["type"] != "quest_item":
		drop_mode_flags = DROP_MODE_DISABLED
		return false
	
	var target: TreeItem = get_item_at_position(at_position)
	
	if target == null or target == data["item"]:
		drop_mode_flags = DROP_MODE_DISABLED
		return false
	
	var compatible: bool = false
	
	match data["item"].get_metadata(0)["type"]:
		ItemType.OBJECTIVE:
			if target.get_metadata(0)["type"] == ItemType.STAGE:
				compatible = true
				drop_mode_flags = DROP_MODE_ON_ITEM
			elif target.get_metadata(0)["type"] == ItemType.OBJECTIVE:
				compatible = true
				drop_mode_flags = DROP_MODE_INBETWEEN
		ItemType.STAGE:
			if target.get_metadata(0)["type"] == ItemType.STAGE:
				compatible = true
				drop_mode_flags = DROP_MODE_INBETWEEN
			elif target.get_metadata(0)["type"] == ItemType.QUEST:
				compatible = true
				drop_mode_flags = DROP_MODE_ON_ITEM
	
	if not compatible:
		drop_mode_flags = DROP_MODE_DISABLED
	
	return compatible


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var on_item: TreeItem = get_item_at_position(at_position)
	var section: int = get_drop_section_at_position(at_position)
	var item: TreeItem = data["item"]
	
	var original_parent: TreeItem = item.get_parent()
	var original_index: int = item.get_index()
	var item_type: int = item.get_metadata(0)["type"]
	var item_id: StringName = item.get_metadata(0)["id"]
	var origin_stage_id: StringName = &""
	
	if item_type == ItemType.OBJECTIVE:
		origin_stage_id = original_parent.get_metadata(0)["id"]
	
	if on_item.get_metadata(0)["type"] == ItemType.QUEST:
		var item_count: int = root.get_child_count()
		if 1 < item_count and item.get_index() < item_count - 1:
			item.move_after(root.get_child(item_count - 1))
	elif on_item.get_metadata(0)["type"] == ItemType.STAGE: # Moving an objective
		if section == 0: # Dropped ON a stage (Objective reassignment)
			original_parent.remove_child(item)
			on_item.add_child(item)
		elif section == -1: # Above
			item.move_before(on_item)
		elif section == 1: # Below
			item.move_after(on_item)
	else:
		if section == 1:
			item.move_after(on_item)
		else:
			item.move_before(on_item)
	
	var new_parent: TreeItem = item.get_parent()
	var new_index: int = item.get_index()
	
	if item_type == ItemType.STAGE:
		if original_index != new_index:
			stage_moved.emit(item_id, original_index, new_index)
	elif item_type == ItemType.OBJECTIVE:
		var new_stage_id: StringName = new_parent.get_metadata(0)["id"]
		if origin_stage_id != new_stage_id or original_index != new_index:
			objective_moved.emit(item_id, origin_stage_id, original_index, new_stage_id, new_index)


func erase_stage(stage_id: StringName) -> void:
	var stage: TreeItem = get_stage(stage_id)
	if stage != null:
		stage.free()


func erase_objective(on_stage: StringName, objective_id: StringName) -> void:
	var objective: TreeItem = get_objective(on_stage, objective_id)
	if objective != null:
		objective.free()


func get_stage(stage_id: StringName) -> TreeItem:
	for item in get_root().get_children():
		if item.get_metadata(0)["id"] == stage_id:
			return item
	return null


func get_objective(from_stage: StringName, objective_id: StringName) -> TreeItem:
	var stage: TreeItem = get_stage(from_stage)
	
	if stage == null:
		return null
	
	for objective in stage.get_children():
		if objective.get_metadata(0)["id"] == objective_id:
			return objective
	return null


func move_objective(objective_id: StringName, from_stage: StringName, to_stage: StringName, to_index: int) -> void:
	var target: TreeItem = get_stage(to_stage)
	var origin: TreeItem = get_objective(from_stage, objective_id)
	
	if origin == null or target == null or has_id(origin.get_text(0), target, origin):
		return
	
	if target != origin.get_parent():
		origin.get_parent().remove_child(origin)
		target.add_child(origin)
	
	var child_count: int = target.get_child_count()
	var max_index: int = child_count - 1
	
	if to_index < -child_count or max_index < to_index:
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Failed changing objective '%s' index. Index out of bounds" % objective_id,
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var target_index: int = wrapi(to_index, 0, max_index)
	var current_index: int = origin.get_index()
	
	if current_index != target_index:
		if target_index == 0:
			origin.move_before(target.get_first_child())
		else:
			if target_index < current_index:
				target_index -= 1
			origin.move_after(target.get_child(target_index))


func move_stage(stage_id: StringName, to_index: int) -> void:
	var stage: TreeItem = get_stage(stage_id)
	
	if stage == null:
		return
	
	var child_count: int = get_root().get_child_count()
	var max_index: int = child_count - 1
	
	if to_index < -child_count or max_index < to_index:
		NFPluginGameHandler._log_msg(
				"odyssey - editor",
				"Failed changing stage '%s' index. Index out of bounds",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var target_index: int = wrapi(to_index, 0, max_index)
	var current_index: int = stage.get_index()
	
	if current_index == target_index:
		return
	
	if target_index == 0:
		stage.move_before(get_root().get_first_child())
	else:
		if target_index < current_index:
			target_index -= 1
		stage.move_after(get_root().get_child(target_index))


func set_objective_id(on_stage: StringName, from: StringName, to: StringName) -> void:
	var objective: TreeItem = get_objective(on_stage, from)
	var str_id: String = String(to)
	
	if objective == null or has_id(to, objective.get_parent(), objective):
		return
	
	objective.set_text(0, String(to))
	objective.get_metadata(0)["id"] = to


func set_stage_id(from: StringName, to: StringName) -> void:
	var stage: TreeItem = get_stage(from)
	var target_id: String = String(to)
	if stage == null or has_id(target_id, get_root(), stage):
		return
	stage.set_text(0, target_id)
	stage.get_metadata(0)["id"] = to


func get_entry_stage() -> StringName:
	for item in root.get_children():
		if item.get_metadata(0)["is_entry"]:
			return item.get_metadata(0)["id"]
	return &""


func set_entry_stage(stage_id: StringName) -> void:
	for item in root.get_children():
		if item.get_metadata(0)["id"] == stage_id:
			item.set_icon_modulate(0, ENTRY_COLOR)
			item.get_metadata(0)["is_entry"] = true
		else:
			item.set_icon_modulate(0, Color.WHITE)
			item.get_metadata(0)["is_entry"] = false


func select_quest(emit_select: bool = true) -> void:
	root.select(0)
	if emit_select:
		quest_selected.emit()


func set_quest(quest: Quest, select: bool = false, emit_select: bool = true) -> void:
	if root == null:
		root = create_item()
	else:
		clear_quests()
	
	root.set_text(0, String(quest.id))
	root.set_editable(0, true)
	root.disable_folding = true
	root.set_icon(0, preload("res://addons/nexus_forge/icons/scroll_full.svg"))
	root.add_button(
		0,
		get_theme_icon("Add", "EditorIcons"),
		ButtonID.ADD_STAGE,
		false,
		"Create stage")
	root.set_metadata(0, {"id": quest.id, "type": ItemType.QUEST})
	
	for stage_id in quest.stages():
		var stage_item: TreeItem = root.create_child()
		stage_item.set_text(0, stage_id)
		stage_item.set_editable(0, true)
		stage_item.set_icon(0, preload("res://addons/nexus_forge/icons/sign_icon.svg"))
		stage_item.add_button(
			0,
			get_theme_icon("Add", "EditorIcons"),
			ButtonID.ADD_OBJECTIVE,
			false,
			"Create objective")
		stage_item.set_metadata(0, {"id": stage_id, "type": ItemType.STAGE, "is_entry": quest.entry_stage == stage_id})
		if quest.entry_stage == stage_id:
			stage_item.set_icon_modulate(0, ENTRY_COLOR)
		for objective_id in quest.get_stage(stage_id).objectives():
			var objective_item: TreeItem = stage_item.create_child()
			objective_item.set_text(0, objective_id)
			objective_item.set_editable(0, true)
			objective_item.set_icon(0, preload("res://addons/nexus_forge/icons/target_icon.svg"))
			objective_item.set_metadata(0, {"id": objective_id, "type": ItemType.OBJECTIVE})
	
	if select:
		root.select(0)
		if emit_select:
			quest_selected.emit()


func add_stage(stage_id: String, index: int = -1) -> TreeItem:
	var stage_item: TreeItem = root.create_child()
	stage_item.set_text(0, stage_id)
	stage_item.set_editable(0, true)
	stage_item.set_icon(0, preload("res://addons/nexus_forge/icons/sign_icon.svg"))
	stage_item.add_button(
		0,
		get_theme_icon("Add", "EditorIcons"),
		ButtonID.ADD_OBJECTIVE,
		false,
		"Create objective")
	stage_item.set_metadata(0, {"id": StringName(stage_id), "type": ItemType.STAGE, "is_entry": false})
	
	if index != -1:
		var child_count: int = root.get_child_count()
		var max_index: int = child_count - 1
		if RangeUtils.is_between(index, -child_count, max_index):
			var target_index: int = wrapi(index, 0, max_index)
			var current_index: int = stage_item.get_index()
			if current_index != target_index:
				if target_index == 0:
					stage_item.move_before(root.get_first_child())
				else:
					if target_index < current_index:
						target_index -= 1
					stage_item.move_after(root.get_child(target_index))
	
	return stage_item


func select_stage(stage_id: StringName, emit_select: bool = true) -> void:
	for item in root.get_children():
		if item.get_metadata(0)["id"] == stage_id:
			if emit_select:
				item.select(0)
			else:
				item_mouse_selected.disconnect(_on_item_clicked)
				item.select(0)
				item_mouse_selected.connect(_on_item_clicked, CONNECT_DEFERRED)
			return


func add_objective(on_stage: StringName, objective_id: StringName, index: int = -1) -> void:
	var stage: TreeItem = get_stage(on_stage)
	
	if stage == null or has_id(objective_id, stage):
		return
	
	add_objective_on_tree(stage, objective_id, index)


func add_objective_on_tree(on_item: TreeItem, objective_id: String, index: int = -1) -> void:
	var objective_item: TreeItem = on_item.create_child()
	objective_item.set_text(0, objective_id)
	objective_item.set_editable(0, true)
	objective_item.set_icon(0, preload("res://addons/nexus_forge/icons/target_icon.svg"))
	objective_item.set_metadata(0, {"id": StringName(objective_id), "type": ItemType.OBJECTIVE})
	
	if index == -1:
		return
	
	var child_count: int = on_item.get_child_count()
	var max_index: int = child_count - 1
	if not RangeUtils.is_between(index, -child_count, max_index):
		return
	var target_index: int = wrapi(index, 0, max_index)
	var current_index: int = objective_item.get_index()
	if target_index == current_index:
		return
	if target_index == 0:
		objective_item.move_before(on_item.get_first_child())
	else:
		if target_index < current_index:
			target_index -= 1
		objective_item.move_after(on_item.get_child(target_index))


func sort_all() -> void:
	if root == null:
		return
	
	var stages: Array[TreeItem] = root.get_children()
	var stage_count: int = stages.size()
	
	if 1 < stage_count:
		stages.sort_custom(_sort_tree_alphabetically)
		if stages[0] != root.get_first_child():
			stages[0].move_before(root.get_first_child())
		for stage_idx in range(1, stage_count):
			stages[stage_idx].move_after(stages[stage_idx - 1])
	
	for stage_item in stages:
		var objectives: Array[TreeItem] = stage_item.get_children()
		var objective_count: int = objectives.size()
		if 1 < objective_count:
			objectives.sort_custom(_sort_tree_alphabetically)
			if objectives[0] != stage_item.get_first_child():
				objectives[0].move_before(stage_item.get_first_child())
				for objective_idx in range(1, objective_count):
					objectives[objective_idx].move_after(objectives[objective_idx - 1])


func clear_quests() -> void:
	root = null
	clear()
	root = create_item()


func sort_single_item(item: TreeItem) -> void:
	var before_item: TreeItem = null
	var parent: TreeItem = item.get_parent()
	
	for child in parent.get_children():
		if child == item:
			continue # We ignore the item we just added
		
		if item.get_text(0).naturalnocasecmp_to(child.get_text(0)) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != parent.get_child_count() - 1:
			item.move_after(parent.get_child(-1))


func get_unique_id(desired: String, on_tree: TreeItem, skip: TreeItem = null) -> String:
	var modified: String = desired
	var iteration: int = 0
	while has_id(modified, on_tree, skip):
		iteration += 1
		modified = desired + str(iteration)
	return modified


func has_id(id: String, on_tree: TreeItem, skip: TreeItem = null) -> bool:
	for item in on_tree.get_children():
		if item == skip:
			continue
		if item.get_text(0) == id:
			return true
	return false


func get_quest_id() -> StringName:
	return root.get_metadata(0)["id"]


func search_for(text: String) -> void:
	var is_empty: bool = text.is_empty()
	for stage in get_root().get_children():
		var obj_visible: bool = false
		for objective in stage.get_children():
			objective.visible = is_empty or objective.get_text(0).containsn(text)
			if obj_visible == false and objective.visible:
				obj_visible = true
		stage.visible = obj_visible or is_empty or stage.get_text(0).containsn(text)


func get_quest_structure() -> Array[Dictionary]:
	var structure: Array[Dictionary] = [
		#{"stage": "abd", "objectives": ["a", "b"]}
	]
	
	for stage in root.get_children():
		var objectives: Array = []
		for objective in stage.get_children():
			objectives.append(objective.get_text(0))
		structure.append({
			"stage": stage.get_text(0),
			"objectives": objectives})
	
	return structure


func set_quest_structure(structure: Array[Dictionary]) -> void:
	if root == null or structure.is_empty():
		return
	
	var stage_ids: Array[String] = []
	var objectives: Dictionary[String, Array] = {}
	
	for item in structure:
		stage_ids.append(item["stage"])
		objectives[item["stage"]] = ArrayUtils.create_typed(TYPE_STRING, item["objectives"].duplicate())
	
	var stages: Array[TreeItem] = root.get_children()
	var stage_count: int = stages.size()
	
	if 1 < stage_count: # Only sort stages if there are more than 2.
		stages.sort_custom(_sort_from_cfg.bind(stage_ids))
		
		if stages[0] != root.get_first_child():
			stages[0].move_before(root.get_first_child())
		
		for stage_idx in range(1, stage_count):
			stages[stage_idx].move_after(stages[stage_idx - 1])
	
	for stage_item in stages: # Only sort objectives on stages if there are more than 2
		if not objectives.has(stage_item.get_text(0)):
			continue
		var objective_items: Array[TreeItem] = stage_item.get_children()
		var objective_count: int = objective_items.size()
		
		if objective_count < 2:
			continue
		
		objective_items.sort_custom(_sort_from_cfg.bind(objectives[stage_item.get_text(0)]))
		
		if objective_items[0] != stage_item.get_first_child():
			objective_items[0].move_before(stage_item.get_first_child())
		
		for item_idx in range(1, objective_count):
			objective_items[item_idx].move_after(objective_items[item_idx - 1])


func _sort_from_cfg(a: TreeItem, b: TreeItem, elements: Array[String]) -> bool:
	var a_idx: int = elements.find(a.get_text(0))
	var b_idx: int = elements.find(b.get_text(0))
	
	if -1 < a_idx and -1 < b_idx:
		return a_idx < b_idx
	elif -1 < a_idx or -1 < b_idx:
		return -1 < a_idx # If a is in the list, returns true. If b, returns false
	else:
		return a.get_text(0).nocasecmp_to(b.get_text(0)) < 0 # Sort alphabetically at the end


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	match id:
		ButtonID.ADD_STAGE:
			var dialog := preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
			dialog.allow_empty = false
			dialog.use_blacklist = true
			dialog.title = "Create stage"
			dialog.line_placeholder_text = "Stage ID"
			for stage in item.get_children():
				dialog.text_blacklist.append(stage.get_text(0))
			add_child(dialog)
			dialog.popup()
			dialog.grab_text_focus()
			
			var result: Array = await dialog.dialog_finished
			
			if result[0]:
				add_stage(result[1])
				stage_created.emit(StringName(result[1]))
			
			dialog.queue_free()
		ButtonID.ADD_OBJECTIVE:
			var dialog := preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
			dialog.allow_empty = false
			dialog.use_blacklist = true
			dialog.title = "Create objective"
			dialog.line_placeholder_text = "Objective ID"
			#dialog.character_blacklist.append(" ")
			for stage in item.get_children():
				dialog.text_blacklist.append(stage.get_text(0))
			add_child(dialog)
			dialog.popup()
			dialog.grab_text_focus()
			
			var result: Array = await dialog.dialog_finished
			
			if result[0]:
				add_objective_on_tree(item, result[1])
				objective_created.emit(item.get_metadata(0)["id"], StringName(result[1]))
			
			dialog.queue_free()


func _sort_tree_alphabetically(a: TreeItem, b: TreeItem) -> bool:
	return a.get_text(0).naturalnocasecmp_to(b.get_text(0)) < 0


func _on_item_clicked(mouse_position: Vector2, mouse_button_index: int) -> void:
	var selected: TreeItem = get_selected()
	
	match selected.get_metadata(0)["type"]:
		ItemType.QUEST:
			quest_selected.emit()
		ItemType.STAGE:
			stage_selected.emit(selected.get_metadata(0)["id"])
		ItemType.OBJECTIVE:
			objective_selected.emit(selected.get_parent().get_metadata(0)["id"], selected.get_metadata(0)["id"])
	
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
		
	right_position = mouse_position
	var add_text: String = "Add"
	
	if selected.get_metadata(0)["type"] == ItemType.QUEST:
		add_text += " stage"
	elif selected.get_metadata(0)["type"] == ItemType.STAGE:
		add_text += " objective"
	quest_popup.set_item_text(quest_popup.get_item_index(PopupItemID.ADD_ITEM), add_text)
	
	quest_popup.position = DisplayServer.mouse_get_position()
	quest_popup.set_item_disabled(
		quest_popup.get_item_index(PopupItemID.REMOVE_ITEM),
		selected.get_metadata(0)["type"] == ItemType.QUEST)
	quest_popup.set_item_disabled(
		quest_popup.get_item_index(PopupItemID.ADD_ITEM),
		selected.get_metadata(0)["type"] == ItemType.OBJECTIVE)
	quest_popup.set_item_disabled(
		quest_popup.get_item_index(PopupItemID.SET_ENTRY),
		selected.get_metadata(0)["type"] != ItemType.STAGE)
	quest_popup.set_item_disabled(
		quest_popup.get_item_index(PopupItemID.DUPLICATE),
		selected.get_metadata(0)["type"] == ItemType.QUEST)
	
	quest_popup.popup()


func _on_popup_id_pressed(id: int) -> void:
	var target: TreeItem = get_item_at_position(right_position)
	
	if target == null:
		return
	
	match id:
		PopupItemID.ADD_ITEM:
			match target.get_metadata(0)["type"]:
				ItemType.QUEST:
					_on_button_clicked(target, 0, ButtonID.ADD_STAGE, MOUSE_BUTTON_LEFT)
				ItemType.STAGE:
					_on_button_clicked(target, 0, ButtonID.ADD_OBJECTIVE, MOUSE_BUTTON_LEFT)
		PopupItemID.EDIT_ITEM:
			edit_selected()
		PopupItemID.REMOVE_ITEM:
			match target.get_metadata(0)["type"]:
				ItemType.STAGE:
					stage_erased.emit(target.get_metadata(0)["id"],
					target.get_index())
					target.free()
				ItemType.OBJECTIVE:
					objective_erased.emit(target.get_parent().get_metadata(0)["id"],
					target.get_metadata(0)["id"],
					target.get_index())
					target.free()
		PopupItemID.SET_ENTRY:
			if not target.get_metadata(0)["is_entry"]:
				set_entry_stage(target.get_metadata(0)["id"])
				entry_stage_selected.emit(target.get_metadata(0)["id"])
		PopupItemID.DUPLICATE:
			var dialog := preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
			var type: ItemType = target.get_metadata(0)["type"]
			var new_id: String = get_unique_id(target.get_text(0) + "_copy", target.get_parent())
			dialog.allow_empty = false
			dialog.use_blacklist = true
			dialog.title = "Duplicate stage" if type == ItemType.STAGE else "Duplicate objective"
			dialog.line_placeholder_text = "Stage ID" if type == ItemType.STAGE else "Objective ID"
			for stage in target.get_parent().get_children():
				dialog.text_blacklist.append(stage.get_text(0))
			add_child(dialog)
			dialog.set_line_text(new_id, new_id.length())
			dialog.popup()
			dialog.grab_text_focus()
			dialog.select_all_text()
			
			var result: Array = await dialog.dialog_finished
			
			if result[0]:
				if type == ItemType.STAGE:
					var dupe_stage: TreeItem = add_stage(result[1])
					for obj in target.get_children():
						add_objective_on_tree(dupe_stage, obj.get_text(0))
					stage_duplicated.emit(target.get_metadata(0)["id"], StringName(result[1]))
				else:
					add_objective_on_tree(target.get_parent(), result[1])
					objective_duplicated.emit(target.get_parent().get_metadata(0)["id"], target.get_metadata(0)["id"], StringName(result[1]))
				
			dialog.queue_free()


func _on_item_edited() -> void:
	var item: TreeItem = get_edited()
	
	var old_id: StringName = item.get_metadata(0)["id"]
	var new_name: String = get_unique_id(item.get_text(0).strip_edges(), item.get_parent(), item) if item != root else item.get_text(0).strip_edges()
	var new_id: StringName = StringName(new_name)
	
	if old_id == new_id:
		return
	
	item.get_metadata(0)["id"] = new_id
	item.set_text(0, new_name)
	
	match item.get_metadata(0)["type"]:
		ItemType.QUEST:
			quest_id_changed.emit(old_id, new_id)
		ItemType.STAGE:
			stage_id_changed.emit(old_id, new_id)
		ItemType.OBJECTIVE:
			objective_id_changed.emit(item.get_parent().get_metadata(0)["id"], old_id, new_id)
