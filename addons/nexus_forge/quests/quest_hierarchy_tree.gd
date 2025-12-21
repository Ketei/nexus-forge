@tool
extends Tree


signal quest_selected(quest: StringName)
signal stage_selected(stage: StringName)
signal objective_selected(of_stage: StringName, objective: StringName)

signal stage_created(stage_id: StringName)
signal objective_created(stage_id: StringName, objective_id: StringName)

signal quest_id_changed(from: StringName, to: StringName)
signal stage_id_changed(from: StringName, to: StringName)
signal objective_id_changed(on_stage: StringName, from: StringName, to: StringName)

signal objective_rearranged(from_stage: StringName, to_stage: StringName, objective_id: StringName)

signal stage_erased(stage_id: StringName)
signal objective_erased(from_stage: StringName, objective_id: StringName)

signal entry_stage_selected(stage_id: StringName)

signal stage_duplicated(from: StringName, duplicate_id: StringName)
signal objective_duplicated(from_stage: StringName, objective: StringName, duplicate_id: StringName)


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


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	quest_popup = PopupMenu.new()
	quest_popup.size = Vector2i(145, 10)
	add_child(quest_popup)
	#quest_popup.add_item("Add", PopupItemID.ADD_ITEM)
	quest_popup.add_icon_item(get_theme_icon("Add", "EditorIcons"), "Add", PopupItemID.ADD_ITEM)
	quest_popup.add_icon_item(get_theme_icon("Edit", "EditorIcons"), "Edit ID", PopupItemID.EDIT_ITEM)
	quest_popup.add_icon_item(get_theme_icon("Duplicate", "EditorIcons"), "Duplicate", PopupItemID.DUPLICATE)
	quest_popup.add_icon_item(get_theme_icon("Remove", "EditorIcons"), "Remove", PopupItemID.REMOVE_ITEM)
	quest_popup.add_separator()
	quest_popup.add_item("Set as entry", PopupItemID.SET_ENTRY)
	quest_popup.id_pressed.connect(_on_popup_id_pressed)
	
	item_mouse_selected.connect(_on_item_clicked, CONNECT_DEFERRED)
	button_clicked.connect(_on_button_clicked)
	item_edited.connect(_on_item_edited)


func _get_drag_data(at_position: Vector2) -> Variant:
	var item: TreeItem = get_item_at_position(at_position)
	if item == null or item.get_metadata(0)["type"] != ItemType.OBJECTIVE:
		return null
	
	var preview: Label = Label.new()
	preview.text = "   " + item.get_text(0)
	set_drag_preview(preview)
	
	return {"type": "quest_objective", "item": item, "origin_stage": item.get_parent().get_metadata(0)["id"]}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has_all(["type", "item"]) or typeof(data["type"]) != TYPE_STRING or typeof(data["item"]) != TYPE_OBJECT or data["item"] is not TreeItem or data["type"] != "quest_objective":
		return false
	
	var target: TreeItem = get_item_at_position(at_position)
	
	if target == null or target.get_metadata(0)["type"] == ItemType.QUEST or target == data["item"].get_parent() or target.get_parent() == data["item"].get_parent():
		return false
	
	drop_mode_flags = DROP_MODE_INBETWEEN if target.get_metadata(0)["type"] == ItemType.OBJECTIVE else DROP_MODE_ON_ITEM
	
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var on_item: TreeItem = get_item_at_position(at_position)
	var target_stage: StringName = &""
	
	if on_item.get_metadata(0)["type"] == ItemType.STAGE:
		data["item"].get_parent().remove_child(data["item"])
		on_item.add_child(data["item"])
		target_stage = on_item.get_metadata(0)["id"]
	else:
		var target: TreeItem = on_item.get_parent()
		data["item"].get_parent().remove_child(data["item"])
		target.add_child(data["item"])
		target_stage = target.get_metadata(0)["id"]
	sort_single_item(data["item"])
	
	objective_rearranged.emit(data["origin_stage"], target_stage, data["item"].get_metadata(0)["id"])


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
	if emit_select:
		root.select(0)
	else:
		item_mouse_selected.disconnect(_on_item_clicked)
		root.select(0)
		item_mouse_selected.connect(_on_item_clicked, CONNECT_DEFERRED)


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
	
	sort_all()
	
	if select:
		if emit_select:
			root.select(0)
		else:
			item_mouse_selected.disconnect(_on_item_clicked)
			root.select(0)
			item_mouse_selected.connect(_on_item_clicked, CONNECT_DEFERRED)


func add_stage(stage_id: String) -> TreeItem:
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
	sort_single_item(stage_item)
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


func add_objective(on_item: TreeItem, objective_id: String) -> void:
	var objective_item: TreeItem = on_item.create_child()
	objective_item.set_text(0, objective_id)
	objective_item.set_editable(0, true)
	objective_item.set_icon(0, preload("res://addons/nexus_forge/icons/target_icon.svg"))
	objective_item.set_metadata(0, {"id": StringName(objective_id), "type": ItemType.OBJECTIVE})
	sort_single_item(objective_item)


func sort_all() -> void:
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
			#dialog.character_blacklist.append(" ")
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
				add_objective(item, result[1])
				objective_created.emit(item.get_metadata(0)["id"], StringName(result[1]))
			
			dialog.queue_free()


func _sort_tree_alphabetically(a: TreeItem, b: TreeItem) -> bool:
	return a.get_text(0).naturalnocasecmp_to(b.get_text(0)) < 0


func _on_item_clicked(mouse_position: Vector2, mouse_button_index: int) -> void:
	var selected: TreeItem = get_selected()
	right_position = mouse_position
	var add_text: String = "Add"
	
	if selected.get_metadata(0)["type"] == ItemType.QUEST:
		add_text += " stage"
	elif selected.get_metadata(0)["type"] == ItemType.STAGE:
		add_text += " objective"
	
	quest_popup.set_item_text(quest_popup.get_item_index(PopupItemID.ADD_ITEM), add_text)
	
	match selected.get_metadata(0)["type"]:
		ItemType.QUEST:
			quest_selected.emit(selected.get_metadata(0)["id"])
		ItemType.STAGE:
			stage_selected.emit(selected.get_metadata(0)["id"])
		ItemType.OBJECTIVE:
			objective_selected.emit(selected.get_parent().get_metadata(0)["id"], selected.get_metadata(0)["id"])
	
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
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
					stage_erased.emit(target.get_metadata(0)["id"])
					target.free()
				ItemType.OBJECTIVE:
					objective_erased.emit(target.get_parent().get_metadata(0)["id"], target.get_metadata(0)["id"])
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
						add_objective(dupe_stage, obj.get_text(0))
					stage_duplicated.emit(target.get_metadata(0)["id"], StringName(result[1]))
				else:
					add_objective(target.get_parent(), result[1])
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
