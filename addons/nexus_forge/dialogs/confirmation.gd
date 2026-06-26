extends ConfirmationDialog

signal dialog_finished(success: bool)

var confirm_on_right: bool = true


func _ready() -> void:
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)
	
	if confirm_on_right:
		var cancel: Button = get_cancel_button()
		cancel.get_parent().move_child(cancel, 0)


func _on_confirmed() -> void:
	dialog_finished.emit(true)


func _on_canceled() -> void:
	dialog_finished.emit(false)
