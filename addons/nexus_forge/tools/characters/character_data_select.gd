@tool
extends FileDialog


signal dialog_finished(success: bool, path: String)

var dialog_mode: int = 0 # 0 = resource, 1 = character, 2 = sound, 3 = frames


func _ready() -> void:
	match dialog_mode:
		2:
			add_filter("*.ogg,*.mp3,*.wav", "Audio Files")
		_:
			add_filter("*.tres,*.res", "Resources")
	file_selected.connect(on_file_selected)
	canceled.connect(on_cancelled)


func on_file_selected(path: String) -> void:
	dialog_finished.emit(true, path)


func on_cancelled() -> void:
	dialog_finished.emit(false, "")
