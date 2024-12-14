@tool
extends Tree

const GO_TO = preload("res://addons/nexus_forge/tools/discourse/icons/go_to.svg")
var root_tree: TreeItem = null


signal jump_target_selected(target: DiscourseGraphNode)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	root_tree = create_item()
	button_clicked.connect(on_button_clicked)


func add_target(target_id: String, ref: DiscourseGraphNode) -> void:
	var new_shortcut: TreeItem = root_tree.create_child()
	new_shortcut.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_shortcut.set_text(0, target_id)
	new_shortcut.add_button(0, GO_TO, 0, false, "Go to Target")
	new_shortcut.set_metadata(0, ref)


func update_target(target_idx: int, new_name: String) -> void:
	root_tree.get_child(target_idx).set_text(0, new_name)


func remove_target(target_idx: int) -> void:
	root_tree.get_child(target_idx).free()


func on_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	jump_target_selected.emit(item.get_metadata(0))
