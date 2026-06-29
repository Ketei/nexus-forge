@tool
extends Tree


signal node_activated(node: StringName)
signal directory_edited
signal item_renamed(uuid: StringName, new_name: String)
signal node_structure_changed
signal collapsed_state_changed

enum ContextMenuID {
	EDIT,
	FOCUS,
	REMOVE,
}

const DATA_COLOR: Color = Color(0.557, 0.937, 0.592)
const DIALOG_COLOR: Color = Color(0.553, 0.647, 0.953)
const SETTINGS_COLOR: Color = Color(0.99, 0.808, 0.495)
const RESOURCE_COLOR: Color = Color(0.988, 0.498, 0.498)

const DIALOG: Array[DialogParser.NodeTypes] = [
		DialogParser.NodeTypes.ENTRY,
		DialogParser.NodeTypes.DIALOG,
		DialogParser.NodeTypes.CHOICES,
		DialogParser.NodeTypes.BRANCH,
		DialogParser.NodeTypes.COMPARATION,
		DialogParser.NodeTypes.EVENT,
		DialogParser.NodeTypes.MATCH,
		DialogParser.NodeTypes.PAUSE,
		DialogParser.NodeTypes.RANDOM,
		DialogParser.NodeTypes.ANCHOR_POINTER,
		DialogParser.NodeTypes.ANCHOR,
		DialogParser.NodeTypes.DIALOG_END,
		DialogParser.NodeTypes.DIALOG_MERGE,
		DialogParser.NodeTypes.LOCALIZED_TEXT]
	
const DATA: Array[DialogParser.NodeTypes] = [
		DialogParser.NodeTypes.CONDITION_SELECT,
		DialogParser.NodeTypes.TYPE_GUARD,
		DialogParser.NodeTypes.VALUE,
		DialogParser.NodeTypes.SIGNAL,
		DialogParser.NodeTypes.CALLABLE,
		DialogParser.NodeTypes.CALLABLE_RETURN,
		DialogParser.NodeTypes.VARIABLE_GET,
		DialogParser.NodeTypes.RANDOM_VALUE,
		DialogParser.NodeTypes.DATA_EVENT,
		DialogParser.NodeTypes.LOCALIZED_TEXT,
		DialogParser.NodeTypes.METADATA]
	
const SETTINGS: Array[DialogParser.NodeTypes] = [
		DialogParser.NodeTypes.SETTINGS_CHARACTER,
		DialogParser.NodeTypes.SETTINGS_DIALOG,
		DialogParser.NodeTypes.SETTINGS_OPTION]
	
const RESOURCES: Array[DialogParser.NodeTypes] = [
		DialogParser.NodeTypes.RESOURCE]

var nodes: Dictionary[StringName, TreeItem] = {}

var context_menu: PopupMenu = null


func ready_plugin() -> void:
	context_menu = PopupMenu.new()
	add_child(context_menu)
	
	context_menu.add_icon_item(
			get_theme_icon("Edit", "EditorIcons"),
			"Edit",
			ContextMenuID.EDIT)
	context_menu.add_icon_item(
		load("res://addons/nexus_forge/icons/navigation_icon.svg"),
		"Focus",
		ContextMenuID.FOCUS)
	context_menu.add_icon_item(
			load("res://addons/nexus_forge/icons/folder_remove.svg"),
			"Remove",
			ContextMenuID.REMOVE)
	
	context_menu.size.y = 0
	
	create_item().collapsed = true
	button_clicked.connect(_on_discourse_tree_button_clicked)
	item_activated.connect(_on_discourse_node_activated)
	item_edited.connect(_on_discourse_item_edited)
	item_collapsed.connect(_on_item_collapsed)
	item_mouse_selected.connect(_on_item_mouse_selected)
	
	context_menu.id_pressed.connect(_on_context_id_pressed)


func _on_context_id_pressed(id: int) -> void:
	var selected: TreeItem = get_selected()
	
	match id:
		ContextMenuID.EDIT:
			edit_selected.call_deferred(true)
		ContextMenuID.FOCUS:
			if selected.get_metadata(0)["is_node"]:
				node_activated.emit(selected.get_metadata(0)["uuid"])
		ContextMenuID.REMOVE:
			if not selected.get_metadata(0)["is_node"]:
				var parent: TreeItem = selected.get_parent()
				for sub_item in selected.get_children():
					selected.remove_child(sub_item)
					parent.add_child(sub_item)
				
				selected.free()
				directory_edited.emit()


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
	var item: TreeItem = get_selected()
	context_menu.position = DisplayServer.mouse_get_position()
	context_menu.set_item_disabled(
			context_menu.get_item_index(ContextMenuID.FOCUS),
			not item.get_metadata(0)["is_node"])
	context_menu.set_item_disabled(
			context_menu.get_item_index(ContextMenuID.REMOVE),
			item.get_metadata(0)["is_node"])
	context_menu.popup()


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var at_node: TreeItem = get_item_at_position(at_position)
	var drop_position: int = get_drop_section_at_position(at_position)
	if drop_position == -100:
		data.get_parent().remove_child(data)
		get_root().add_child(data)
	else:
		match drop_position:
			-1: # Above
				data.move_before(at_node)
			0: # On (Shouldn't be used)
				data.get_parent().remove_child(data)
				at_node.add_child(data)
			1: # Below
				data.move_after(at_node)
	
	node_structure_changed.emit()


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


func _on_item_collapsed(item: TreeItem) -> void:
	collapsed_state_changed.emit()


func _on_discourse_tree_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	if item.get_metadata(0)["is_node"]:
		item.select(0)
		edit_selected.call_deferred(true)
	else: # Deleting folder
		var parent: TreeItem = item.get_parent()
		for sub_item in item.get_children():
			item.remove_child(sub_item)
			parent.add_child(sub_item)
		
		item.free()
		directory_edited.emit()


func _on_discourse_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var is_node: bool = edited.get_metadata(0)["is_node"]
	
	if is_node:
		var uuid: StringName = edited.get_metadata(0)["uuid"]
		var new_name: String = get_unique_name_for_node(edited.get_text(0), edited)
		edited.set_text(0, new_name)
		item_renamed.emit(uuid, new_name)
	else:
		var new_name: String = get_unique_name_on_tree(
				edited.get_parent(),
				edited.get_text(0),
				edited)
		edited.set_text(0, new_name)
	
	directory_edited.emit()


func _on_discourse_node_activated() -> void:
	var active: TreeItem = get_selected()
	if active == null:
		return
	
	node_activated.emit(active.get_metadata(0)["uuid"])


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
				"uuid": item.get_metadata(0)["uuid"]})
		else:
			structure.append({
				"is_node": false,
				"name": item.get_text(0),
				"items": get_folder_structure(item)})
	return structure


func create_folder(folder_name: String, on_node: TreeItem = get_root(), select: bool = true) -> void:
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
	
	if select:
		new_folder.select(0)
		ensure_cursor_is_visible()


func is_folder(item: TreeItem) -> bool:
	var data: Dictionary = item.get_metadata(0)
	if data.has("is_node"):
		return not data["is_node"]
	return false


func create_node(node: DiscourseGraphNode, on: TreeItem = get_root()) -> void:
	var new_item: TreeItem = on.create_child()
	var type: int = 0 if node.node_type in DIALOG else 1 if node.node_type in DATA else 2 if node.node_type in SETTINGS else 3 if node.node_type in RESOURCES else -1
	new_item.set_icon(0, preload("res://addons/nexus_forge/icons/node_icon.svg") if node.graph_icon == null else node.graph_icon)
	if 0 <= type:
		new_item.set_icon_modulate(0, DIALOG_COLOR if type == 0 else DATA_COLOR if type == 1 else SETTINGS_COLOR if type == 2 else RESOURCE_COLOR)
	new_item.set_text(0, str(node.get_node_id()))
	new_item.add_button(
			0,
			get_theme_icon("Edit", "EditorIcons"),
			0,
			false,
			"Edit ID")
	
	new_item.set_metadata(0, {"is_node": true, "uuid": node.get_node_uuid()})
	
	nodes[node.get_node_uuid()] = new_item


func select_node(node_uuid: StringName) -> void:
	for root_item in get_root().get_children():
		if root_item.get_metadata(0)["is_node"] and root_item.get_metadata(0)["uuid"] == node_uuid:
			ensure_expanded(root_item)
			root_item.select(0)
			ensure_cursor_is_visible()
			return
		elif _select_on_children(root_item, node_uuid):
			return


func _select_on_children(on_tree: TreeItem, node_uuid: StringName) -> bool:
	for child in on_tree.get_children():
		if child.get_metadata(0)["is_node"] and child.get_metadata(0)["uuid"] == node_uuid:
			ensure_expanded(child)
			child.select(0)
			ensure_cursor_is_visible()
			return true
		elif _select_on_children(child, node_uuid):
			return true
	return false


func ensure_expanded(node: TreeItem) -> void:
	var current_node: TreeItem = node.get_parent()
	while current_node != null:
		if current_node.collapsed:
			current_node.collapsed = false
		current_node = current_node.get_parent()


func remove_dialog_node(uuid: StringName) -> bool:
	if not nodes.has(uuid):
		return false
	
	var node: TreeItem = nodes[uuid]
	nodes.erase(uuid)
	node.free()
	return true


func get_unique_name_for_node(desired_name: String, skip_item: TreeItem = null) -> String:
	var trailing_data: Dictionary = StringUtils.get_trailing_integer(desired_name)
	var iteration: int = trailing_data["integer"]
	var all_names: Dictionary = {}
	var base_name: String = desired_name
	
	if trailing_data["has_integer"]:
		base_name = desired_name.trim_suffix(str(iteration))
	
	for node in nodes.values():
		if node == skip_item:
			continue
		all_names[node.get_text(0)] = null
	
	if all_names.has(desired_name):
		var edited_name: String = desired_name
		while all_names.has(edited_name):
			iteration += 1
			edited_name = base_name + str(iteration)
		base_name = edited_name
	
	return base_name


func get_unique_name_on_tree(tree: TreeItem, desired_name: String, skip_item: TreeItem = null) -> String:
	var edited_name: String = desired_name
	var iteration: int = StringUtils.get_trailing_integer(desired_name)["integer"]
	
	while has_text_on_tree(edited_name, 0, tree, skip_item):
		iteration += 1
		edited_name = desired_name + str(iteration)
	
	return edited_name


func has_text_on_tree(text: String, column: int, tree: TreeItem, skip_item: TreeItem = null) -> bool:
	for item in tree.get_children():
		if item == skip_item:
			continue
		if item.get_text(column) == text:
			return true
	return false


func search_for_node(pattern: String) -> void:
	var is_empty: bool = pattern.is_empty()
	for item in get_root().get_children():
		item.visible = _search_on_children(item, pattern) or is_empty or item.get_text(0).containsn(pattern)


func set_node_id(uuid: StringName, id: String) -> void:
	if not nodes.has(uuid):
		return
	nodes[uuid].set_text(0, id)


func _search_on_children(from: TreeItem, pattern: String) -> bool:
	var found: bool = false
	var is_empty: bool = pattern.is_empty()
	for child in from.get_children():
		child.visible = _search_on_children(child, pattern) or is_empty or child.get_text(0).containsn(pattern)
		if not found and child.visible:
			found = true
	return found


func clear_tree() -> void:
	var root: TreeItem = get_root()
	if root != null:
		var collapsed: bool = root.collapsed
		root.free()
		create_item().collapsed = collapsed
	nodes.clear()


func set_collapsed_folders(folders: Dictionary) -> void:
	if folders.is_empty():
		return
	
	var folder_items: Dictionary[String, TreeItem] = get_folder_item_paths()
	
	for path in folders.keys():
		if typeof(folders[path]) != TYPE_BOOL:
			continue
		if folder_items.has(path):
			folder_items[path].collapsed = folders[path]


func get_folder_item_paths() -> Dictionary[String, TreeItem]:
	var items: Dictionary[String, TreeItem] = {}
	for top_item in get_root().get_children():
		if not top_item.get_metadata(0)["is_node"]:
			items[_get_path_of_node(top_item)] = top_item
		_set_folder_items(top_item, items)
	
	return items


func _set_folder_items(from: TreeItem, _on: Dictionary[String, TreeItem]) -> void:
	for item in from.get_children():
		if not item.get_metadata(0)["is_node"]:
			_on[_get_path_of_node(item)] = item


func get_collapsed_folders() -> Dictionary[String, bool]:
	var collapsed_items: Dictionary[String, bool] = {}
	var folders: Dictionary[String, TreeItem] = get_folder_item_paths()
	
	for path in folders.keys():
		collapsed_items[path] = folders[path].collapsed
	return collapsed_items


func _get_path_of_node(item: TreeItem) -> String:
	var root: TreeItem = get_root()
	if item == null or item == root:
		return ""
	
	var reverse_path: Array[String] = []
	
	var current_level: TreeItem = item
	
	while current_level != root and current_level != null:
		reverse_path.append(current_level.get_text(0))
		current_level = current_level.get_parent()
	
	reverse_path.append("root")
	reverse_path.reverse()
	return "/".join(reverse_path) + "/"
