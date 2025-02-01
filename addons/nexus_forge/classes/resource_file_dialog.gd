extends FileDialog
#extends EditorFileDialog


signal dialog_finished(success: bool, resource_path: String)


func _ready() -> void:
	add_filter("*.tres", "Resources")
	access = ACCESS_RESOURCES
	size = Vector2i(600, 400)
	initial_position = WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	file_selected.connect(on_file_selected)
	canceled.connect(on_canceled)


func on_file_selected(file_path: String) -> void:
	dialog_finished.emit(true, file_path)


func on_canceled() -> void:
	dialog_finished.emit(false, "")
