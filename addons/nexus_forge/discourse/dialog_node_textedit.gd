@tool
extends TextEdit


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_echo() or not event.is_pressed():
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
