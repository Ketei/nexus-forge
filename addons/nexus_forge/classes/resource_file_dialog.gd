extends FileDialog


signal dialog_finished(success: bool, resource_path: String)


func _ready() -> void:
	add_filter("*.tres", "Resources")
	access = ACCESS_RESOURCES
	file_selected.connect(on_file_selected)
	canceled.connect(on_canceled)


func on_file_selected(file_path: String) -> void:
	dialog_finished.emit(true, file_path)


func on_canceled() -> void:
	dialog_finished.emit(false, "")
