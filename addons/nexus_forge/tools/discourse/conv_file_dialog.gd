@tool
#extends EditorFileDialog
extends FileDialog


signal dialog_finished(success: bool, path: String)


func _ready() -> void:
	if file_mode == FILE_MODE_SAVE_FILE:
		title = "Create a Conversation"
		ok_button_text = "Save"
	else:
		title = "Load a Conversation"
		ok_button_text = "Open"
	
	size = Vector2i(500, 350)
	initial_position = WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	
	add_filter("*.tres", "Resources")
	
	file_selected.connect(_on_file_selected)
	canceled.connect(_on_dialog_cancelled)


func _on_file_selected(path: String) -> void:
	dialog_finished.emit(true, path)


func _on_dialog_cancelled() -> void:
	dialog_finished.emit(false, "")
