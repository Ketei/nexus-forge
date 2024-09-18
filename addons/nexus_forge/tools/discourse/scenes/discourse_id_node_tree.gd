extends Tree


signal center_dialog_pressed(node_ref: DiscourseGraphNode)


var tree_root: TreeItem = null
var id_refs: Dictionary = {}


func _ready() -> void:
	tree_root = create_item()
	button_clicked.connect(on_go_to_node_pressed)


func add_node(node_ref: DiscourseGraphNode) -> void:
	var new_tree: TreeItem = create_item(tree_root)
	var ref_id: String = node_ref._get_node_id()
	if ref_id.is_empty():
		new_tree.set_text(0, "[MISSING ID]")
	else:
		new_tree.set_text(0, node_ref.node_id)
	new_tree.set_metadata(0, node_ref)
	node_ref.id_changed.connect(on_node_updated.bind(node_ref))
	new_tree.add_button(
			0,
			load("res://addons/nexus_forge/tools/discourse/icons/go_to.svg"),
			-1,
			false,
			"Go to node")
	
	id_refs[node_ref.name] = new_tree


func on_node_updated(new_id: String, node_ref: DiscourseGraphNode) -> void:
	var node_item: TreeItem = id_refs[node_ref.name]
	if new_id.is_empty():
		node_item.set_text(0, "[MISSING ID]")
	else:
		node_item.set_text(0, new_id)


func remove_node(node_ref: DiscourseGraphNode) -> void:
	id_refs[node_ref.name].free()
	id_refs.erase(node_ref.name)


func remove_all_nodes() -> void:
	id_refs.clear()
	for node_item:TreeItem in tree_root.get_children():
		node_item.free()


func on_go_to_node_pressed(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	center_dialog_pressed.emit(item.get_metadata(0))
	
