extends ConfirmationDialog

signal dialog_finished(result: int)


func _ready() -> void:
	var no_inherit_btn: Button = add_button("No", false, "no_inherit")
	var cancel: Button = get_cancel_button()
	
	cancel.get_parent().move_child(cancel, 0)
	
	ok_button_text = "Yes"
	cancel_button_text = "Cancel"
	
	cancel.tooltip_text = "Cancel Import"
	get_ok_button().tooltip_text = "Import with Inheritance"
	no_inherit_btn.tooltip_text = "Import without Inheritance"
	
	title = "Import Data..."
	dialog_text = "Use stat inheritance?"
	
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)
	custom_action.connect(_on_custom_action)


func _on_custom_action(_action: StringName) -> void:
	hide()
	dialog_finished.emit(2)


func _on_confirmed() -> void:
	dialog_finished.emit(1)


func _on_canceled() -> void:
	dialog_finished.emit(0)
