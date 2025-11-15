extends ConfirmationDialog

signal dialog_finished(success: bool)


func _ready() -> void:
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)


func _on_confirmed() -> void:
	dialog_finished.emit(true)


func _on_canceled() -> void:
	dialog_finished.emit(false)
