extends ConfirmationDialog

signal option_selected(save_opt: int)

#
#enum SaveOption {
	#SAVE,
	#DISCARD,
	#CANCEL,
#}


func _ready() -> void:
	var discard_button: Button = add_button("Discard Changes", true)
	
	discard_button.pressed.connect(on_discard_pressed)
	confirmed.connect(on_save_pressed)
	canceled.connect(on_cancel_pressed)


func on_save_pressed() -> void:
	option_selected.emit(0)


func on_cancel_pressed() -> void:
	option_selected.emit(2)


func on_discard_pressed() -> void:
	option_selected.emit(1)
	hide()
