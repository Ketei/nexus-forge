@tool
extends EditorFileDialog


signal dialog_finished(completed: bool, path: String)


func _ready() -> void:
	access = ACCESS_RESOURCES
	size = Vector2i(850, 600)
	initial_position = WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	dir_selected.connect(on_dir_selected)
	canceled.connect(on_canceled)


func on_dir_selected(file_path: String) -> void:
	dialog_finished.emit(true, file_path)


func on_canceled() -> void:
	dialog_finished.emit(false, "")
