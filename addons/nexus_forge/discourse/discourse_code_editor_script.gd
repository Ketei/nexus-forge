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


func _input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	
	if event.echo or not event.pressed:
		return
	
	if event.keycode == KEY_ENTER and event.ctrl_pressed:
		_on_confirmed.call_deferred()
		get_viewport().set_input_as_handled()


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
		var inner_text: String = current_syntax.substr(2)
		var last_pipe_idx: int = inner_text.rfind("|")
		
		if last_pipe_idx != -1:
			var active_arg: String = inner_text.substr(last_pipe_idx + 1)
			
			if active_arg.begins_with("!"):
				var clean_syntax: String = active_arg.substr(1).strip_edges(false)
				sort_and_set_completion_options(clean_syntax, methods)
			elif active_arg.begins_with("$"):
				var clean_syntax: String = active_arg.substr(1).strip_edges(false)
				if signal_variables:
					variable_called.emit(clean_syntax)
				else:
					sort_and_set_completion_options(clean_syntax, variables)
		else:
			var clean_syntax: String = current_syntax.substr(2).strip_edges(false)
			sort_and_set_completion_options(clean_syntax, methods)
	elif current_syntax.begins_with("{$"):
		if signal_variables:
			variable_called.emit(current_syntax.substr(2))
		else:
			var clean_syntax: String = current_syntax.substr(2).strip_edges(false)
			sort_and_set_completion_options(clean_syntax, variables)
	elif current_syntax.begins_with("{&"):
		var clean_syntax: String = current_syntax.substr(2).strip_edges(false)
		sort_and_set_completion_options(clean_syntax, phrase_keys)
	elif current_syntax.begins_with("{"):
		var clean_syntax: String = current_syntax.substr(1).strip_edges(false)
		sort_and_set_completion_options(clean_syntax, plain_formats)


func sort_and_set_completion_options(clean_syntax: String, options: Array[String]) -> void:
	if options.is_empty():
		return
	
	var new_sort: Array[String] = options.duplicate()
	new_sort.sort_custom(
		func (a:String,b:String):
			var dist_a: float = StringUtils.levenshtein_distance(a, clean_syntax)
			var dist_b: float = StringUtils.levenshtein_distance(b, clean_syntax)
			return dist_a < dist_b)
	
	for var_path in new_sort:
		text_code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, var_path, var_path)
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
