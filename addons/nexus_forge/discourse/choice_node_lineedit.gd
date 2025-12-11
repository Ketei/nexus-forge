@tool
extends LineEdit


func _gui_input(event):
	if event is InputEventKey:
		if event.echo or not event.pressed:
			return
		
		var caret_pos: int = caret_column
		
		# --- 1. Handle Opening Brackets ({ and [) ---
		if event.unicode == 123 or event.unicode == 91: # { or [
			accept_event()
			insert_text_at_caret("{}")
			caret_column = caret_pos + 1
			
		# --- 2. Handle Closing Brackets (} and ]) ---
		elif event.unicode == 125 or event.unicode == 93: # } or ]
			if caret_pos < text.length() and text[caret_pos] == "}":
				accept_event()
				caret_column = caret_pos + 1

		# --- 3. Handle Backspace (Delete Pair) ---
		elif event.keycode == KEY_BACKSPACE:
			if caret_pos > 0 and caret_pos < text.length():
				var prev_char: String = text[caret_pos - 1]
				var next_char: String = text[caret_pos]
				
				if prev_char == "{" and next_char == "}":
					accept_event()
					delete_text(caret_pos - 1, caret_pos + 1)
					caret_column = caret_pos - 1
