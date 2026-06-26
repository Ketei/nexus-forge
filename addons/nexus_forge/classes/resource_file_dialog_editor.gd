@tool
extends EditorFileDialog


signal dialog_finished(success: bool, resource_path: String)


var expected_extension: String = "tres"


func _ready() -> void:
	add_filter("*.tres", "Resources")
	access = ACCESS_RESOURCES
	size = Vector2i(850, 600)
	initial_position = WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	file_selected.connect(on_file_selected)
	canceled.connect(on_canceled)


func on_file_selected(file_path: String) -> void:
	if file_path.get_extension() != expected_extension:
		file_path = file_path.get_basename() + "." + expected_extension
	dialog_finished.emit(true, file_path)


func on_canceled() -> void:
	dialog_finished.emit(false, "")
