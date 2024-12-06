@tool
extends FileDialog


signal dialog_finished(success: bool, path: String)


var target_tree: TreeItem


func _ready() -> void:
	add_filter("*.tres", "Resources")
	initial_position = WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	size = Vector2i(512, 300)
	file_selected.connect(on_file_selected)
	canceled.connect(on_cancelled)
	if file_mode == FILE_MODE_SAVE_FILE:
		title = "Save Conversation"
		get_ok_button().text = "Save"
	else:
		title = "Select Conversation"
		get_ok_button().text = "Open"


func on_file_selected(path: String) -> void:
	dialog_finished.emit(true, "path")


func on_cancelled() -> void:
	dialog_finished.emit(false, "")
