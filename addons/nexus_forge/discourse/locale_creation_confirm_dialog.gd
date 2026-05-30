extends ConfirmationDialog


signal dialog_finished(code_selected: String)

var _code_opt_btn: OptionButton = null


func _init() -> void:
	_code_opt_btn = OptionButton.new()
	_code_opt_btn.custom_minimum_size.y = 32
	_code_opt_btn.fit_to_longest_item = false
	_code_opt_btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_code_opt_btn.get_popup().max_size = Vector2i(200, 350)
	add_child(_code_opt_btn)
	ok_button_text = "Create"


func _ready() -> void:
	var cancel_button: Button = get_cancel_button()
	size = Vector2i(220, 89)
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	get_ok_button().focus_previous = _code_opt_btn.get_path()
	cancel_button.focus_next = _code_opt_btn.get_path()
	cancel_button.get_parent().move_child(cancel_button, 0)
	_code_opt_btn.focus_next = get_ok_button().get_path()
	_code_opt_btn.focus_previous = cancel_button.get_path()
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)


# Each dictionary will have the keys: "code", "enabled" & "name"
func set_codes(codes: Array[Dictionary]) -> void:
	_code_opt_btn.clear()
	var idx: int = -1
	for item in codes:
		idx += 1
		_code_opt_btn.add_item(item["name"])
		_code_opt_btn.set_item_disabled(idx, item["disabled"])
		_code_opt_btn.set_item_metadata(idx, item["code"])


func select_language(lang: String) -> void:
	for idx in range(_code_opt_btn.item_count):
		if _code_opt_btn.get_item_metadata(idx) == lang:
			_code_opt_btn.select(idx)
			return


func _on_confirmed() -> void:
	var selected: int = _code_opt_btn.selected
	if _code_opt_btn.is_item_disabled(selected):
		dialog_finished.emit("")
	else:
		dialog_finished.emit(_code_opt_btn.get_item_metadata(selected))


func _on_canceled() -> void:
	dialog_finished.emit("")


func sort_codes_array(codes: Array[Dictionary]) -> void:
	codes.sort_custom(_sort_codes_alphabetically)


func focus_option_button() -> void:
	_code_opt_btn.grab_focus()


func _sort_codes_alphabetically(region_a: Dictionary, region_b: Dictionary) -> bool:
	return region_a["name"].naturalnocasecmp_to(region_b["name"]) < 0
