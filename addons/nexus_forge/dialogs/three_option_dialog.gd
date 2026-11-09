@tool
extends ConfirmationDialog


signal dialog_finished(success: bool, result: int)

var _accept_int: int = 0
var _extra_int: int = 1

var _third_button: Button

var mid_button_text: String = "Rename":
	set(t):
		mid_button_text = t
		if _third_button != null:
			_third_button.text = t


func _ready() -> void:
	_third_button = add_button(mid_button_text)
	_third_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	size = Vector2i(250, 100)
	
	var ok: Button = get_ok_button()
	var cancel: Button = get_cancel_button()
	
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.get_parent().move_child(ok, 0)
	
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)
	_third_button.pressed.connect(_on_extra)


func _on_confirmed() -> void:
	dialog_finished.emit(true, _accept_int)


func _on_canceled() -> void:
	dialog_finished.emit(false, -1)


func _on_extra() -> void:
	dialog_finished.emit(true, _extra_int)
