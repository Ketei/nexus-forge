@tool
extends Window


signal action_finished(confirmed: bool, text: String)
signal variable_called(path: String)

var phrase_keys: Array[String] = []
var methods: Array[String] = []
var plain_formats: Array[String] = []
var variables: Array[String] = []

var signal_variables: bool = true

@onready var debounce_timer: Timer = $DebounceTimer
@onready var text_code_edit: CodeEdit = $MainPanel/MainContainer/TextCodeEdit
@onready var cancel_button: Button = $MainPanel/MainContainer/ButtonContainer/CancelButton
@onready var accept_button: Button = $MainPanel/MainContainer/ButtonContainer/AcceptButton


func _ready() -> void:
	var panel: PanelContainer = $MainPanel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = get_theme_color("background", "Editor")
	style.set_content_margin_all(8.0)
	
	panel.add_theme_stylebox_override(&"panel", style)


func connect_signals() -> void:
	text_code_edit.clear_string_delimiters()
	debounce_timer.timeout.connect(_on_debounce_timeout)
	text_code_edit.text_changed.connect(_on_text_changed)
	text_code_edit.code_completion_requested.connect(_on_code_completion_requested)
	accept_button.pressed.connect(_on_confirmed, CONNECT_DEFERRED)
	cancel_button.pressed.connect(_on_canceled)
	close_requested.connect(_on_canceled)


func _on_text_changed() -> void:
	var confirmed_via_keys: bool = Input.is_physical_key_pressed(KEY_TAB) or Input.is_physical_key_pressed(KEY_ENTER)
	var confirmed_via_mouse: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if not confirmed_via_keys and not confirmed_via_mouse:
	#else:
		debounce_timer.start()


func _on_debounce_timeout() -> void:
	check_for_code_completion_on_caret()


# We leave this as is for manual code-completion request
func _on_code_completion_requested() -> void:
	check_for_code_completion_on_caret()


func check_for_code_completion_on_caret() -> void:
	var caret_line: int = text_code_edit.get_caret_line()
	var caret_col: int = text_code_edit.get_caret_column()
	
	if caret_col == 0:
		return
	
	var line_text: String = text_code_edit.get_line(caret_line).substr(0, caret_col)
	
	var open_brace_idx: int = line_text.rfind("{")
	
	if open_brace_idx == -1 or open_brace_idx < line_text.rfind("}"):
		return
	
	var current_syntax: String = line_text.substr(open_brace_idx)
	
	if current_syntax.begins_with("{!"):
		if methods.is_empty():
			return
		var clean_syntax: String = current_syntax.substr(2).strip_edges(false)
		var new_sort: Array[String] = methods.duplicate()
		new_sort.sort_custom(
			func (a:String,b:String):
				var dist_a: float = StringUtils.levenshtein_distance(a, clean_syntax)
				var dist_b: float = StringUtils.levenshtein_distance(b, clean_syntax)
				return dist_a < dist_b)
		
		for method in new_sort:
			text_code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, method, method)
		text_code_edit.update_code_completion_options(true)
	elif current_syntax.begins_with("{$"):
		if signal_variables:
			variable_called.emit(current_syntax.substr(2))
			return
		else:
			if variables.is_empty():
				return
		var clean_syntax: String = current_syntax.substr(2).strip_edges(false)
		var new_sort: Array[String] = variables.duplicate()
		new_sort.sort_custom(
			func (a:String,b:String):
				var dist_a: float = StringUtils.levenshtein_distance(a, clean_syntax)
				var dist_b: float = StringUtils.levenshtein_distance(b, clean_syntax)
				return dist_a < dist_b)
		
		for var_path in new_sort:
			text_code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, var_path, var_path)
		text_code_edit.update_code_completion_options(true)
	elif current_syntax.begins_with("{&"):
		if phrase_keys.is_empty():
			return
		var clean_syntax: String = current_syntax.substr(2).strip_edges(false)
		var new_sort: Array[String] = phrase_keys.duplicate()
		new_sort.sort_custom(
			func (a:String,b:String):
				var dist_a: float = StringUtils.levenshtein_distance(a, clean_syntax)
				var dist_b: float = StringUtils.levenshtein_distance(b, clean_syntax)
				return dist_a < dist_b)
		
		for method in new_sort:
			text_code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, method, method)
		text_code_edit.update_code_completion_options(true)
	elif current_syntax.begins_with("{"):
		if plain_formats.is_empty():
			return
		var clean_syntax: String = current_syntax.substr(1).strip_edges(false)
		var new_sort: Array[String] = plain_formats.duplicate()
		new_sort.sort_custom(
			func (a:String,b:String):
				var dist_a: float = StringUtils.levenshtein_distance(a, clean_syntax)
				var dist_b: float = StringUtils.levenshtein_distance(b, clean_syntax)
				return dist_a < dist_b)
		
		for format in new_sort:
			text_code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, format, format)
		text_code_edit.update_code_completion_options(true)


func display_completion_options_variables(variables: Array[Dictionary]) -> void:
	if variables.is_empty():
		return
	
	for data in variables:
		if data["is_folder"]: # Is a folder
			text_code_edit.add_code_completion_option(CodeEdit.KIND_CLASS, data["path"], data["path"])
		else: # Is a variable
			text_code_edit.add_code_completion_option(CodeEdit.KIND_VARIABLE, data["path"], data["path"])
	
	text_code_edit.update_code_completion_options(true)


func set_code_text(text: String, caret_line: int = -1, caret_column: int = -1) -> void:
	text_code_edit.text = text
	
	var target_line: int = caret_line
	if target_line < 0:
		target_line = text_code_edit.get_line_count() - 1
	
	text_code_edit.set_caret_line(target_line)
	
	if caret_column < 0:
		text_code_edit.set_caret_column(
			text_code_edit.get_line(target_line).length())
	else:
		text_code_edit.set_caret_column(caret_column)


func get_code_text() -> String:
	return text_code_edit.text


func grab_code_focus() -> void:
	text_code_edit.grab_focus()


func _on_confirmed() -> void:
	hide()
	action_finished.emit(true, text_code_edit.text.strip_edges().replace("\n", " "))


func _on_canceled() -> void:
	hide()
	action_finished.emit(false, "")
