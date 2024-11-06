@tool
extends ConfirmationDialog


signal action_taken(is_confirmed: bool)


func _ready() -> void:
	get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	get_label().vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	confirmed.connect(on_dialog_confirmed)
	canceled.connect(on_dialog_canceled)


func confirm_action() -> ConfirmationDialog:
	show()
	return self


func on_dialog_confirmed() -> void:
	action_taken.emit(true)


func on_dialog_canceled() -> void:
	action_taken.emit(false)
