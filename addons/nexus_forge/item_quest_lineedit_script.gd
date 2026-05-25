@tool
extends LineEdit


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_echo() or not event.is_pressed():
			return
		if event.unicode == 123:
			insert_text_at_caret("}")
			set_caret_column(get_caret_column() - 1)
		elif event.unicode == 125:
			var caret_col: int = get_caret_column()
			if caret_col < text.length() and text[caret_col] == "}":
				accept_event()
				set_caret_column(caret_col + 1)
		elif event.keycode == KEY_BACKSPACE:
			var caret_col: int = get_caret_column()
			
			if 0 < caret_col and caret_col < text.length():
				if ( text[caret_col - 1] == "{" and text[caret_col] == "}" ):
					accept_event()
					delete_text(caret_col - 1, caret_col + 1)
					set_caret_column(caret_col - 1)
