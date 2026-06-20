@tool
extends EditorFileDialog


signal dialog_finished(success: bool, resource_path: String)


func _ready() -> void:
	access = ACCESS_RESOURCES
	file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	size = Vector2i(850, 600)
	initial_position = WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dir_selected.connect(on_dir_selected)
	canceled.connect(on_canceled)


func on_dir_selected(dir_path: String) -> void:
	dialog_finished.emit(true, dir_path)


func on_canceled() -> void:
	dialog_finished.emit(false, "")
