@tool
extends Tree


signal node_activated(node: DiscourseGraphNode)
signal directory_edited
signal item_renamed(uuid: StringName, type: DiscourseGraphNode.DialogueNodeType, new_name: String, localized: bool)


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	create_item().collapsed = true
	button_clicked.connect(_on_discourse_tree_button_clicked)
	item_activated.connect(_on_discourse_node_activated)
	item_edited.connect(_on_discourse_item_edited)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var at_node: TreeItem = get_item_at_position(at_position)
	var drop_position: int = get_drop_section_at_position(at_position)
	if drop_position == -100:
		data.move_after(get_root().get_child(-1))
	else:
		match drop_position:
			-1: # Above
				data.move_before(at_node)
			0: # On (Shouldn't be used)
				if at_node.get_child_count() == 0:
					data.get_parent().remove_child(data)
					at_node.add_child(data)
				else:
					data.move_before(at_node.get_child(-1))
			1: # Below
				data.move_after(at_node)


func _get_drag_data(at_position: Vector2) -> Variant:
	var selected: TreeItem = get_item_at_position(at_position)
	if selected == null:
		return null
	
	var data: Label = Label.new()
	data.text = selected.get_text(0)
	set_drag_preview(data)
	return get_selected()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var item_at_pos: TreeItem = get_item_at_position(at_position)
	if item_at_pos == null or data is not TreeItem or data == item_at_pos:
		return false
	
	drop_mode_flags = DropModeFlags.DROP_MODE_INBETWEEN
	
	if not item_at_pos.get_metadata(0)["is_node"]:
		drop_mode_flags += DropModeFlags.DROP_MODE_ON_ITEM
	
	return belongs_to_tree(data)


func _on_discourse_tree_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	if item.get_metadata(0)["is_node"]:
		item.select(0)
		edit_selected(true)
	else: # Deleting folder
		for sub_item in item.get_children():
			item.remove_child(sub_item)
			item.get_parent().add_child(sub_item)
		item.free()
		directory_edited.emit()


func _on_discourse_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var is_node: bool = edited.get_metadata(0)["is_node"]
	if is_node:
		var node: DiscourseGraphNode = edited.get_metadata(0)["node"]
		if edited.get_text(0) == node.custom_id:
			return
		var new_name: String = get_unique_name_on_tree(edited.get_text(0), edited)
		node.custom_id = new_name
		edited.set_text(0, new_name)
		item_renamed.emit(node.get_node_uuid(), node.node_type, new_name, node.is_node_localized())
	else:
		var new_name: String = get_unique_name_on_tree(
				edited.get_text(0),
				edited)
		edited.set_text(0, new_name)
	
	directory_edited.emit()



func _on_discourse_node_activated() -> void:
	var active: TreeItem = get_selected()
	if active == null:
		return
	
	#var node: DiscourseGraphNode = active.get_metadata(0)["node"]
	node_activated.emit(active.get_metadata(0)["node"])
	#discourse_window.discourse_graph_edit.focus_graph_node(node)
	#_on_graph_edit_offset_changed(Vector2.ZERO)


func belongs_to_tree(item: TreeItem) -> bool:
	var root: TreeItem = get_root()
	while item != null:
		if item == root:
			return true
		item = item.get_parent()
	return false


func get_folder_structure(_from: TreeItem = get_root()) -> Array[Dictionary]:
	var structure: Array[Dictionary] = []
	for item in _from.get_children():
		if item.get_metadata(0)["is_node"]:
			structure.append({
				"is_node": true,
				"uuid": item.get_metadata(0)["node"].get_node_uuid()})
		else:
			#structure["folders"].append(get_folder_structure(item))
			structure.append({
				"is_node": false,
				"name": item.get_text(0),
				"items": get_folder_structure(item)})
	return structure


func create_folder(folder_name: String, on_node: TreeItem = get_root()) -> void:
	var new_folder: TreeItem = on_node.create_child()
	new_folder.set_text(0, folder_name)
	new_folder.set_editable(0, true)
	new_folder.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
	new_folder.add_button(
			0,
			get_theme_icon("Remove", "EditorIcons"),
			-1,
			false,
			"Delete Group")
	new_folder.set_metadata(0, {"is_node": false})


func is_folder(item: TreeItem) -> bool:
	var data: Dictionary = item.get_metadata(0)
	if data.has("is_node"):
		return not data["is_node"]
	return false


func create_node(node: DiscourseGraphNode) -> void:
	var new_item: TreeItem = get_root().create_child()
		
	new_item.set_text(0, str(node.custom_id))
	new_item.add_button(
			0,
			get_theme_icon("Edit", "EditorIcons"),
			0,
			false,
			"Edit ID")
	
	new_item.set_metadata(0, {"node": node, "is_node": true, "uuid": node.get_node_uuid()})
	
	#if node == discourse_window.discourse_graph_edit.entry_node and new_item.get_index() != 0:
		#new_item.move_before(new_item.get_parent().get_first_child())


func remove_dialog_node(uuid: StringName, _on: TreeItem = get_root()) -> bool:
	for child in _on.get_children():
		var meta: Dictionary = child.get_metadata(0)
		if not meta["is_node"]: # Is folder
			var result: bool = remove_dialog_node(uuid, child)
			if result:
				return true
		elif meta["uuid"] == uuid:
			child.free()
			return true
	return false


func get_unique_name_on_tree(desired_name: String, skip_item: TreeItem = null) -> String:
	var edited_name: String = desired_name
	var iteration: int = 0
	
	while has_text_on_tree(edited_name, 0, skip_item):
		iteration += 1
		edited_name = desired_name + str(iteration)
	
	return edited_name


func has_text_on_tree(text: String, column: int, skip_item: TreeItem = null) -> bool:
	for item in get_root().get_children():
		if item == skip_item:
			continue
		if item.get_text(column) == text:
			return true
	return false
