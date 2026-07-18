@tool
extends Window


signal window_finished(success: bool, result: String)

@onready var char_search_ln_edt: LineEdit = $MainPanel/MainContainer/CharSearchLnEdt
@onready var cancel_btn: Button = $MainPanel/MainContainer/ButtonContainer/CancelBtn
@onready var accept_btn: Button = $MainPanel/MainContainer/ButtonContainer/AcceptBtn
@onready var character_list: Tree = $MainPanel/MainContainer/CharacterList


func _ready() -> void:
	accept_btn.disabled = true
	character_list.item_selected.connect(_on_item_selected)
	character_list.item_activated.connect(_on_item_activated)
	accept_btn.pressed.connect(_on_accept_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	char_search_ln_edt.text_changed.connect(_on_search_character_text_changed)
	close_requested.connect(_on_cancel_pressed)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return
		
		if event.keycode == KEY_ESCAPE:
			_on_cancel_pressed()
			get_viewport().set_input_as_handled()
		elif char_search_ln_edt.has_focus():
			if (event.keycode == KEY_DOWN or event.keycode == KEY_TAB) and 0 < character_list.get_root().get_child_count():
				character_list.grab_focus.call_deferred(true)
				_select_first_visible_item()
				get_viewport().set_input_as_handled()
		elif character_list.has_focus():
			if (event.keycode == KEY_UP or (event.keycode == KEY_TAB and event.shift_pressed)) and _is_top_selected():
				character_list.deselect_all()
				accept_btn.disabled = true
				char_search_ln_edt.grab_focus.call_deferred(true)
				char_search_ln_edt.edit.call_deferred(true)
				char_search_ln_edt.caret_column = char_search_ln_edt.text.length()
				get_viewport().set_input_as_handled()


# character_data = {path: ID}
func populate_characters(character_data: Dictionary[String, Variant]) -> void:
	if character_list.get_root() != null:
		character_list.clear()
	var root: TreeItem = character_list.create_item()
	var paths: Array[String] = []
	var traveled: Dictionary[StringName, Variant] = {}
	for key in character_data.keys():
		if typeof(character_data[key]) != TYPE_NIL and not traveled.has(character_data[key]):
			paths.append(key)
			traveled[character_data[key]] = null
	
	paths.sort_custom(func (a,b): return character_data[a] < character_data[b])
	
	for path in paths:
		var item: TreeItem = root.create_child()
		item.set_text(0, String(character_data[path]))
		item.set_tooltip_text(0, path)


func grab_search_focus() -> void:
	char_search_ln_edt.grab_focus.call_deferred(true)
	char_search_ln_edt.edit.call_deferred(true)


func _is_top_selected() -> bool:
	for item in character_list.get_root().get_children():
		if item.visible:
			return item.is_selected(0)
	return false


func _select_first_visible_item() -> void:
	for item in character_list.get_root().get_children():
		if item.visible:
			item.select(0)
			return


func _on_search_character_text_changed(text: String) -> void:
	var clean: String = text.strip_edges()
	
	if clean.is_empty():
		for item in character_list.get_root().get_children():
			item.visible = true
	else:
		for item in character_list.get_root().get_children():
			item.visible = item.get_text(0).containsn(clean)
	
	var selected: TreeItem = character_list.get_selected()
	
	if selected == null:
		if not accept_btn.disabled:
			accept_btn.disabled = true


func _on_item_selected() -> void:
	if accept_btn.disabled:
		accept_btn.disabled = false


func _on_item_activated() -> void:
	_on_accept_pressed()


func _on_accept_pressed() -> void:
	hide()
	var selected: String = character_list.get_selected().get_text(0)
	window_finished.emit(true, selected)


func _on_cancel_pressed() -> void:
	hide()
	window_finished.emit(false, "")
