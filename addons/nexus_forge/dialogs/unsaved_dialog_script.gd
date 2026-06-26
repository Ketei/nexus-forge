@tool
extends AcceptDialog


signal dialog_finished(action: int) # 0 = save, 1 = don't save, 2 = cancel

func _init() -> void:
	dialog_text = "Do you want to save changes?"
	title = "Discourse"
	size = Vector2i(250, 85)
	initial_position = WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN


func _ready() -> void:
	get_ok_button().text = "Save"
	var dont_save := add_button("Discard", true)
	var cancel := add_cancel_button("Cancel")
	
	confirmed.connect(dialog_finished.emit.bind(0))
	dont_save.pressed.connect(_on_no_save_pressed)
	cancel.pressed.connect(dialog_finished.emit.bind(2))


func _on_no_save_pressed() -> void:
	hide()
	dialog_finished.emit(1)
