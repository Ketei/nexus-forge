@tool
extends TextEdit


var enter_shifts_focus: bool = false


func _ready() -> void:
	if syntax_highlighter == null:
		syntax_highlighter = NFEditorDialogSyntaxHighlighter.new()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.echo or not event.pressed:
			return
		if event.unicode == 123:
			insert_text_at_caret("}")
			set_caret_column(get_caret_column() - 1)
		elif event.unicode == 125:
			var caret_col: int = get_caret_column()
			var caret_text: String = get_line(get_caret_line())
			if caret_col < caret_text.length() and caret_text[caret_col] == "}":
				accept_event()
				set_caret_column(caret_col + 1)
		elif event.keycode == KEY_BACKSPACE:
			var caret_col: int = get_caret_column()
			var caret_line: int = get_caret_line()
			var current_text: String = get_line(caret_line)
			
			if 0 < caret_col and caret_col < current_text.length():
				if ( current_text[caret_col - 1] == "{" and current_text[caret_col] == "}" ) or current_text[caret_col - 1] == "[" and current_text[caret_col] == "]":
					accept_event()
					remove_text(caret_line, caret_col - 1, caret_line, caret_col + 1)
					set_caret_column(caret_col - 1)
		elif event.unicode == 91:
			insert_text_at_caret("]")
			set_caret_column(get_caret_column() - 1)
		elif event.unicode == 93:
			var caret_col: int = get_caret_column()
			var caret_text: String = get_line(get_caret_line())
			if caret_col < caret_text.length() and caret_text[caret_col] == "]":
				accept_event()
				set_caret_column(caret_col + 1)
		elif event.keycode == KEY_ENTER:
			if not enter_shifts_focus:
				return
			if event.ctrl_pressed:
				var next_focus: Control = find_next_valid_focus()
				if next_focus != null:
					next_focus.grab_focus()
					accept_event()
			elif event.shift_pressed:
				var prev_focus: Control = find_prev_valid_focus()
				if prev_focus != null:
					prev_focus.grab_focus()
					accept_event()
