@tool
extends Tree


signal issue_activated(issue_node: StringName)


func ready_plugin() -> void:
	create_item()
	
	item_activated.connect(_on_issue_activated)
	button_clicked.connect(_on_button_clicked)


func _on_issue_activated() -> void:
	issue_activated.emit(get_selected().get_metadata(0)["node"])


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		item.free()


func add_issue(issue: String, node: StringName) -> void:
	var new_issue: TreeItem = get_root().create_child()
	new_issue.set_text(0, issue)
	new_issue.set_metadata(0, {"node": node})
	new_issue.add_button(
			0,
			get_theme_icon("GuiClose", "EditorIcons"),
			0,
			false,
			"Remove issue")


func has_issues() -> bool:
	return 0 < get_root().get_child_count()


func clear_issues() -> void:
	for issue in get_root().get_children():
		issue.free()
