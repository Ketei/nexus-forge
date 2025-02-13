@tool
extends Tree

signal issue_pressed(issue_node: DiscourseGraphNode)

const GO_TO = preload("res://addons/nexus_forge/common_icons/go_to.svg")
var root_tree: TreeItem = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	root_tree = create_item()
	button_clicked.connect(_on_button_clicked)


func log_issue(issue_text: String, problem_node: DiscourseGraphNode) -> void:
	var new_issue: TreeItem = root_tree.create_child()
	new_issue.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_issue.set_text(0, issue_text)
	new_issue.add_button(0, GO_TO, -1, false, "Go to Node")
	new_issue.set_metadata(0, problem_node)


func clear_issues() -> void:
	for issue in root_tree.get_children():
		issue.free()


func _on_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	if is_instance_valid(item.get_metadata(0)):
		issue_pressed.emit(item.get_metadata(0))
