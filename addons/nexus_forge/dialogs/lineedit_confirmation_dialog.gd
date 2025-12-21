extends ConfirmationDialog


signal dialog_finished(success: bool, line_selected: String)

var _dialog_line: LineEdit
var _info_label: TextureRect
var _ok_button: Button
var line_placeholder_text: String:
	set(new_text):
		_dialog_line.placeholder_text = new_text
	get():
		return _dialog_line.placeholder_text

var text_blacklist: Array[String] = []
var character_blacklist: PackedStringArray = []
var strip_edges: bool = true
var use_blacklist: bool = false
var allow_empty: bool = true

var error_line_empty_msg: String = "Field can't be empty"
var error_line_blacklist_word_msg: String = "Word is blacklisted"
var error_line_blacklist_character_msg: String = "A character is blacklisted"
var error_line_ok: String = "No issues found"


func _init() -> void:
	_dialog_line = LineEdit.new()
	_info_label = TextureRect.new()
	_info_label.custom_minimum_size = Vector2(32.0, 32.0)
	_info_label.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_info_label.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_info_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	_dialog_line.custom_minimum_size.y = 32.0
	_dialog_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size = Vector2i(250, 89)
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var new_container: HBoxContainer = HBoxContainer.new()
	new_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(new_container)
	new_container.add_child(_dialog_line)
	new_container.add_child(_info_label)
	
	_ok_button = get_ok_button()
	
	if not allow_empty:
		_info_label.texture = preload("res://addons/nexus_forge/icons/error_red.svg")
		get_ok_button().disabled = true
		_info_label.tooltip_text = error_line_empty_msg
	elif use_blacklist and "" in text_blacklist:
		_info_label.texture = preload("res://addons/nexus_forge/icons/error_red.svg")
		get_ok_button().disabled = "" in text_blacklist
		_info_label.tooltip_text = error_line_empty_msg
	else:
		_info_label.texture = preload("res://addons/nexus_forge/icons/check_green.svg")
		_info_label.tooltip_text = error_line_ok
	
	_dialog_line.text_changed.connect(_on_text_changed)
	_dialog_line.text_submitted.connect(_on_text_submitted)
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)


func _on_text_changed(text: String) -> void:
	var stripped_text: String = text.strip_edges()
	var invalid_char: bool = false
	for character in text:
		if character in character_blacklist:
			invalid_char = true
			break
	if stripped_text.is_empty() and not allow_empty:
		_ok_button.disabled = true
		_info_label.texture = preload("res://addons/nexus_forge/icons/error_red.svg")
		_info_label.tooltip_text = error_line_empty_msg
	elif use_blacklist and stripped_text in text_blacklist:
		_ok_button.disabled = true
		_info_label.texture = preload("res://addons/nexus_forge/icons/error_red.svg")
		_info_label.tooltip_text = error_line_blacklist_word_msg
	elif invalid_char:
		_ok_button.disabled = true
		_info_label.texture = preload("res://addons/nexus_forge/icons/error_red.svg")
		_info_label.tooltip_text = error_line_blacklist_character_msg
	elif _ok_button.disabled:
		_info_label.texture = preload("res://addons/nexus_forge/icons/check_green.svg")
		_info_label.tooltip_text = error_line_ok
		_ok_button.disabled = false


func _on_text_submitted(text: String) -> void:
	if get_ok_button().disabled:
		return
	hide()
	dialog_finished.emit(
			true,
			text.strip_edges() if strip_edges else text)


func _on_confirmed() -> void:
	var line_text: String = _dialog_line.text
	if strip_edges:
		line_text = line_text.strip_edges()
	dialog_finished.emit(true, line_text)


func _on_canceled() -> void:
	dialog_finished.emit(false, "")


func grab_text_focus() -> void:
	_dialog_line.grab_focus()


func set_line_text(text: String, caret_pos: int = -1) -> void:
	_dialog_line.text = text
	if -1 < caret_pos:
		_dialog_line.caret_column = caret_pos
	_on_text_changed(text)


func select_all_text() -> void:
	_dialog_line.select_all()
