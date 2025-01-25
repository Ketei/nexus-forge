extends ConfirmationDialog


signal dialog_confirmed(result: bool, text: String)


var _line_edit: LineEdit = null
var accept_empty: bool = true
var clean_string: bool = false
var invalid_strings: PackedStringArray = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not accept_empty:
		get_ok_button().disabled = true
	_line_edit = LineEdit.new()
	add_child(_line_edit, false, Node.INTERNAL_MODE_FRONT)
	_line_edit.text_changed.connect(_on_line_text_changed)
	_line_edit.text_submitted.connect(_on_line_edit_text_submitted)
	_line_edit.custom_minimum_size.y = 32
	size = Vector2i(250, 90)
	initial_position = WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)


func _on_confirmed() -> void:
	var text: String = _line_edit.text
	
	if clean_string:
		text = text.strip_edges()
	
	dialog_confirmed.emit(true, text)


func _on_canceled() -> void:
	dialog_confirmed.emit(false, "")


func _on_line_text_changed(new_text: String) -> void:
	var new_string: String = new_text
	
	if clean_string:
		new_string = new_string.strip_edges()
	
	if accept_empty:
		get_ok_button().disabled = invalid_strings.has(new_string)
	else:
		get_ok_button().disabled = new_string.is_empty() or invalid_strings.has(new_string)


func _on_line_edit_text_submitted(submitted_text: String) -> void:
	if get_ok_button().disabled:
		return
		
	var text: String  = submitted_text
	
	if clean_string:
		text = text.strip_edges()
	
	dialog_confirmed.emit(true, text)
	hide()


func focus_line_edit() -> void:
	_line_edit.grab_focus()
