@tool
extends Tree


signal node_delocalized(node: DiscourseGraphNode)
signal dialog_selected(node_uuid: StringName)
signal dialog_item_edited(new_id: TreeItem)

enum ButtonID {
	DELETE,
	RENAME}

const SELECTED_COLOR: Color = Color.SKY_BLUE

var _dialog_tree: TreeItem
var _options_tree: TreeItem
var _text_tree: TreeItem

var active_dialog: TreeItem = null:
	set(new_dialog):
		if active_dialog != null:
			active_dialog.clear_custom_color(0)
		active_dialog = new_dialog
		if new_dialog != null:
			new_dialog.set_custom_color(0, SELECTED_COLOR)
var previous_dialog: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	print("Ready pass!")
	var root: TreeItem = create_item()
	
	root.collapsed = true
	hide_root = true
	allow_reselect = true
	
	_dialog_tree = root.create_child()
	_options_tree = root.create_child()
	_text_tree = root.create_child()
	
	_dialog_tree.set_text(0, "Dialog")
	_options_tree.set_text(0, "Options")
	_text_tree.set_text(0, "Text")
	
	_dialog_tree.set_selectable(0, false)
	_options_tree.set_selectable(0, false)
	_text_tree.set_selectable(0, false)
	
	item_edited.connect(_on_node_edited)
	button_clicked.connect(_on_button_clicked)
	item_activated.connect(_on_item_activated)


func _on_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	if id == ButtonID.DELETE:
		node_delocalized.emit(item.get_metadata(0)["node"])
		if item == active_dialog:
			active_dialog = null
			dialog_selected.emit(&"")
		item.free()
	elif id == ButtonID.RENAME:
		item.select(0)
		edit_selected(true)


func _on_item_activated() -> void:
	var selected: TreeItem = get_selected()
	if selected == null or not selected.is_selectable(0):
		return
	active_dialog = selected
	dialog_selected.emit(
			selected.get_metadata(0)["node"].get_node_uuid())


func _on_node_edited() -> void:
	var edited: TreeItem = get_edited()
	
	if edited.get_text(0) == edited.get_metadata(0)["name"]:
		return
	
	dialog_item_edited.emit(edited)


func clear_nodes() -> void:
	for node:TreeItem in [_dialog_tree, _options_tree, _text_tree]:
		for item in node.get_children():
			item.free()


func create_dialog_node(node_name: String, node: DiscourseGraphNode) -> void:
	create_node_on(_dialog_tree, node_name, node, "DialogNode")


func rename_dialog_node(uuid: StringName, new_name: String) -> void:
	for node in _dialog_tree.get_children():
		if node.get_metadata(0)["uuid"] == uuid:
			node.set_text(0, new_name)
			node.get_metadata(0)["name"] = new_name
			break


func create_options_node(node_name: String, node: DiscourseGraphNode) -> void:
	create_node_on(_options_tree, node_name, node, "OptionsNode")


func rename_options_node(uuid: StringName, new_name: String) -> void:
	for node in _options_tree.get_children():
		if node.get_metadata(0)["uuid"] == uuid:
			node.set_text(0, new_name)
			node.get_metadata(0)["name"] = new_name
			break


func create_localized_text_node(node_name: String, node: DiscourseGraphNode) -> void:
	create_node_on(_text_tree, node_name, node, "TextNode")


func rename_text_node(uuid: StringName, new_name: String) -> void:
	for node in _text_tree.get_children():
		if node.get_metadata(0)["uuid"] == uuid:
			node.set_text(0, new_name)
			node.get_metadata(0)["name"] = new_name
			break


func remove_node(uuid: StringName) -> void:
	for tree:TreeItem in [_dialog_tree, _options_tree, _text_tree]:
		for item in tree.get_children():
			if item.get_metadata(0)["uuid"] == uuid:
				if active_dialog == item:
					active_dialog = null
					dialog_selected.emit(&"")
				item.free()
				return


func get_active_node_uuid() -> StringName:
	if active_dialog == null:
		return ""
	return active_dialog.get_metadata(0)["node"].get_node_uuid()


func get_active_node() -> DiscourseGraphNode:
	if active_dialog == null:
		return null
	return active_dialog.get_metadata(0)["node"]


func create_node_on(tree: TreeItem, node_name: String, node: DiscourseGraphNode, default_name: String) -> void:
	var new_name: String = get_unique_name_on(tree, node_name, default_name)
	var new_node: TreeItem = tree.create_child()
	new_node.set_text(0, new_name)
	new_node.add_button(
			0,
			get_theme_icon("Edit", "EditorIcons"),
			ButtonID.RENAME,
			false,
			"Rename Node")
	new_node.add_button(
			0,
			get_theme_icon("Remove", "EditorIcons"),
			ButtonID.DELETE,
			node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT,
			"Delocalize Node")
	new_node.set_metadata(0, {"name": new_name, "node": node, "uuid": node.get_node_uuid()})


func get_unique_name_on(tree_item: TreeItem, desired_name: String, default_name: String = "LocalizedNode", skip_item: TreeItem = null) -> String:
	desired_name = desired_name.strip_edges()
	if desired_name.is_empty():
		desired_name = default_name
	var modified_name: String = desired_name
	
	
	var iteration: int = -1
	while tree_has_name(tree_item, 0, modified_name, skip_item):
		iteration += 1
		modified_name = desired_name + str(iteration)
	return modified_name


func tree_has_name(tree: TreeItem, column: int, item_name: String, skip: TreeItem = null) -> bool:
	for item in tree.get_children():
		if item == skip:
			continue
		if item.get_text(column) == item_name:
			return true
	return false


func select_node(uuid: StringName) -> void:
	if uuid.is_empty():
		return
	
	for top_tree:TreeItem in [_dialog_tree, _options_tree, _text_tree]:
		for language_node in top_tree.get_children():
			if language_node.get_metadata(0)["node"].get_node_uuid() == uuid:
				language_node.select(0)
				return
