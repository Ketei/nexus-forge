@tool
extends Tree


signal node_activated(node: StringName)

signal item_renamed(uuid: StringName, old_name: String, new_name: String)
signal folder_renamed(folder_id: int, old_name: String, new_name: String)

signal item_moved(from_path: String, from_index: int, to_path: String, to_index: int)

signal directory_removed(path: String, index: int, id: int, contents: Array[Dictionary])

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

const DIALOG: Array[NFDialogParser.NodeTypes] = [
		NFDialogParser.NodeTypes.ENTRY,
		NFDialogParser.NodeTypes.DIALOG,
		NFDialogParser.NodeTypes.CHOICES,
		NFDialogParser.NodeTypes.BRANCH,
		NFDialogParser.NodeTypes.COMPARATION,
		NFDialogParser.NodeTypes.EVENT,
		NFDialogParser.NodeTypes.MATCH,
		NFDialogParser.NodeTypes.PAUSE,
		NFDialogParser.NodeTypes.RANDOM,
		NFDialogParser.NodeTypes.SHORTCUT,
		NFDialogParser.NodeTypes.SHORTCUT_TARGET,
		NFDialogParser.NodeTypes.DIALOG_END,
		NFDialogParser.NodeTypes.DIALOG_MERGE,
		NFDialogParser.NodeTypes.LOCALIZED_TEXT]
	
const DATA: Array[NFDialogParser.NodeTypes] = [
		NFDialogParser.NodeTypes.CONDITION_SELECT,
		NFDialogParser.NodeTypes.TYPE_GUARD,
		NFDialogParser.NodeTypes.VALUE,
		NFDialogParser.NodeTypes.SIGNAL,
		NFDialogParser.NodeTypes.CALLABLE,
		NFDialogParser.NodeTypes.CALLABLE_RETURN,
		NFDialogParser.NodeTypes.VARIABLE_GET,
		NFDialogParser.NodeTypes.RANDOM_VALUE,
		NFDialogParser.NodeTypes.DATA_EVENT,
		NFDialogParser.NodeTypes.LOCALIZED_TEXT,
		NFDialogParser.NodeTypes.METADATA]
	
const SETTINGS: Array[NFDialogParser.NodeTypes] = [
		NFDialogParser.NodeTypes.SETTINGS_CHARACTER,
		NFDialogParser.NodeTypes.SETTINGS_DIALOG,
		NFDialogParser.NodeTypes.SETTINGS_OPTION]
	
const RESOURCES: Array[NFDialogParser.NodeTypes] = [
		NFDialogParser.NodeTypes.RESOURCE]

var nodes: Dictionary[StringName, TreeItem] = {}

var context_menu: PopupMenu = null
var _folder_id: int = 0


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
			if selected.get_metadata(0)["is_node"]:
				return
			
			var metadata: Dictionary = selected.get_metadata(0)
			var original_path: String = get_path_to_item(selected)
			var original_index: int = selected.get_index()
			var folder_id: int = metadata["id"]
			var items_contained: Array[Dictionary] = []
			for sub_item in selected.get_children():
				var is_node: bool = metadata["is_node"]
				var data: Dictionary = {
					"is_node": is_node,
					"name": metadata["name"]}
				if is_node:
					data["uuid"] = metadata["uuid"]
				else:
					data["id"] = metadata["id"]
				items_contained.append(data)
			
			remove_folder_tree(selected)
			
			directory_removed.emit(
					original_path,
					original_index,
					folder_id,
					items_contained)


func remove_folder(folder_path: String) -> void:
	var item: TreeItem = get_item_from_path(folder_path)
	remove_folder_tree(item)


func remove_folder_tree(folder: TreeItem) -> void:
	if not is_instance_valid(folder) or not is_folder(folder):
		return
	
	var parent: TreeItem = folder.get_parent()
	for sub_item in folder.get_children():
		folder.remove_child(sub_item)
		parent.add_child(sub_item)
	folder.free()


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
	var dropped_item: TreeItem = data
	var at_node: TreeItem = get_item_at_position(at_position)
	var drop_position: int = get_drop_section_at_position(at_position)
	var original_path: String = get_path_to_item(dropped_item)
	var original_index: int = dropped_item.get_index()
	
	if drop_position == -100:
		dropped_item.get_parent().remove_child(dropped_item)
		get_root().add_child(dropped_item)
	else:
		match drop_position:
			-1: # Above
				data.move_before(at_node)
			0: # On
				if at_node == data.get_parent():
					if data.get_index() != at_node.get_child_count() -1:
						data.move_after(at_node.get_child(-1))
				else:
					data.get_parent().remove_child(data)
					at_node.add_child(data)
			1: # Below
				if is_folder(at_node) and 0 < at_node.get_child_count() and not at_node.collapsed:
					var target: TreeItem = at_node.get_first_child()
					if target != data:
						data.move_before(target)
				else:
					data.move_after(at_node)
	
	var new_index: int = dropped_item.get_index()
	var new_path: String = get_path_to_item(dropped_item)
	
	if new_index != original_index or new_path != original_path:
		item_moved.emit(
			original_path,
			original_index,
			new_path,
			new_index)


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
	
	if data is not TreeItem or data == item_at_pos or _node_contains(data, item_at_pos):
		return false
	
	drop_mode_flags = DropModeFlags.DROP_MODE_INBETWEEN
	
	if is_folder(item_at_pos):
		drop_mode_flags += DropModeFlags.DROP_MODE_ON_ITEM
	
	return belongs_to_tree(data)


func _node_contains(parent: TreeItem, child: TreeItem) -> bool:
	if child == null or parent == null:
		return false
	
	var current: TreeItem = child
	
	while current != null:
		if current == parent:
			return true
		current = current.get_parent()
	
	return false


func _on_item_collapsed(item: TreeItem) -> void:
	collapsed_state_changed.emit()


func _on_discourse_tree_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	if item.get_metadata(0)["is_node"]:
		item.select(0)
		edit_selected.call_deferred(true)
	else: # Deleting folder
		var metadata: Dictionary = item.get_metadata(0)
		var original_path: String = get_path_to_item(item)
		var folder_id: int = metadata["id"]
		var items_contained: Array[Dictionary] = []
		for sub_item in item.get_children():
			var is_node: bool = metadata["is_node"]
			var data: Dictionary = {
				"is_node": is_node,
				"name": metadata["name"]}
			if is_node:
				data["uuid"] = metadata["uuid"]
			else:
				data["id"] = metadata["id"]
			items_contained.append(data)
		
		remove_folder_tree(item)
		
		directory_removed.emit(
				original_path,
				folder_id,
				items_contained)


func _on_discourse_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var is_node: bool = edited.get_metadata(0)["is_node"]
	
	if is_node:
		var uuid: StringName = edited.get_metadata(0)["uuid"]
		var old_name: String = edited.get_metadata(0)["name"]
		var new_name: String = get_unique_name_for_node(edited.get_text(0), edited)
		
		if new_name != old_name:
			edited.get_metadata(0)["name"] = new_name
			edited.set_text(0, new_name)
			item_renamed.emit(uuid, old_name, new_name)
	else:
		var new_name: String = get_unique_name_on_tree(
				edited.get_parent(),
				edited.get_text(0),
				edited)
		var old_name: String = edited.get_metadata(0)["name"]
		
		if new_name != old_name:
			edited.set_text(0, new_name)
			edited.get_metadata(0)["name"] = new_name
			folder_renamed.emit(
					edited.get_metadata(0)["id"],
					old_name,
					new_name)


func _on_discourse_node_activated() -> void:
	var active: TreeItem = get_selected()
	if active == null:
		return
	
	node_activated.emit(active.get_metadata(0)["uuid"])


func claim_folder_id() -> int:
	var claimed_id: int = _folder_id
	_folder_id += 1
	return claimed_id


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
	var true_name: String = get_unique_name_on_tree(
				on_node,
				folder_name)
	var new_folder: TreeItem = on_node.create_child()
	new_folder.set_text(0, true_name)
	new_folder.set_editable(0, true)
	new_folder.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
	new_folder.add_button(
			0,
			get_theme_icon("Remove", "EditorIcons"),
			-1,
			false,
			"Delete Group")
	new_folder.set_metadata(0, {"name": true_name, "is_node": false, "id": claim_folder_id()})
	
	if select:
		new_folder.select(0)
		ensure_cursor_is_visible()


func is_folder(item: TreeItem) -> bool:
	if item == null:
		return false
	var data = item.get_metadata(0)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.has("is_node") and typeof(data["is_node"]) == TYPE_BOOL:
		return not data["is_node"]
	return false


func create_node(node: DiscourseGraphNode, on: TreeItem = get_root()) -> void:
	var new_item: TreeItem = on.create_child()
	var type: int = 0 if node.node_type in DIALOG else 1 if node.node_type in DATA else 2 if node.node_type in SETTINGS else 3 if node.node_type in RESOURCES else -1
	var node_name: String = str(node.get_node_id())
	new_item.set_icon(0, preload("res://addons/nexus_forge/icons/node_icon.svg") if node.graph_icon == null else node.graph_icon)
	if 0 <= type:
		new_item.set_icon_modulate(0, DIALOG_COLOR if type == 0 else DATA_COLOR if type == 1 else SETTINGS_COLOR if type == 2 else RESOURCE_COLOR)
	new_item.set_text(0, node_name)
	new_item.add_button(
			0,
			get_theme_icon("Edit", "EditorIcons"),
			0,
			false,
			"Edit ID")
	
	new_item.set_metadata(0, {"name": node_name,  "is_node": true, "uuid": node.get_node_uuid()})
	
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
	
	
	for node in nodes.values():
		if node == skip_item:
			continue
		all_names[node.get_text(0)] = null
	
	if all_names.has(desired_name):
		if trailing_data["has_integer"]:
			base_name = desired_name.trim_suffix(str(iteration))
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


func get_path_to_item(folder: TreeItem) -> String:
	if not is_instance_valid(folder) or folder.get_parent() == null: # Skip if root
		return ""
	
	var path_parts: Array[String] = []
	
	var root: TreeItem = get_root()
	var current_item: TreeItem = folder
	while current_item != null and current_item != root:
		path_parts.append(current_item.get_text(0))
		current_item = current_item.get_parent()
	
	path_parts.reverse()
	
	return StringUtils.make_path(path_parts)


func get_item_from_path(path: String) -> TreeItem:
	if path.is_empty():
		return null
	
	var slices: PackedStringArray = path.split("/", false)
	var node_id: String = slices[-1]
	var current_item: TreeItem = get_root()
	
	for path_slice in slices.slice(0, -1):
		var found: bool = false
		for item in current_item.get_children():
			if item.get_text(0) == path_slice:
				current_item = item
				found = true
				break
		if not found:
			return null
	
	for item in current_item.get_children():
		if item.get_text(0) == node_id:
			return item
	
	return null


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
