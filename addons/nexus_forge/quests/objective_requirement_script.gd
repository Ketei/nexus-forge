extends HBoxContainer


signal requirement_changed
signal erase_requirement_pressed(item: Control)


var mode: int = TYPE_INT

var req_type_mn_btn: MenuButton# = $ReqTypeMnBtn
var req_ln_edt: LineEdit# = $ReqLnEdt
var comp_mn_btn: MenuButton# = $CompMnBtn
var str_comp_ln_edt: LineEdit# = $DataPanel/LineEdit
var num_comp_spn_bx: SpinBox# = $DataPanel/SpinBox
var bool_comp_opt_btn: OptionButton# = $DataPanel/OptionButton
var erase_btn: Button# = $EraseBtn


func _init() -> void:
	var data_panel: PanelContainer = PanelContainer.new()
	
	req_type_mn_btn = MenuButton.new()
	req_ln_edt = LineEdit.new()
	comp_mn_btn = MenuButton.new()
	str_comp_ln_edt = LineEdit.new()
	num_comp_spn_bx = SpinBox.new()
	bool_comp_opt_btn = OptionButton.new()
	erase_btn = Button.new()
	
	req_type_mn_btn.flat = false
	req_type_mn_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	req_type_mn_btn.custom_minimum_size = Vector2(32.0, 32.0)
	
	req_ln_edt.custom_minimum_size.y = 32.0
	req_ln_edt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	req_ln_edt.caret_blink = true
	
	comp_mn_btn.custom_minimum_size = Vector2(32.0, 32.0)
	
	data_panel.custom_minimum_size.y = 32.0
	data_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_panel.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	
	num_comp_spn_bx.allow_greater = true
	num_comp_spn_bx.allow_lesser = true
	num_comp_spn_bx.visible = mode == TYPE_INT or mode == TYPE_FLOAT
	
	str_comp_ln_edt.visible = mode == TYPE_STRING
	str_comp_ln_edt.caret_blink = true
	
	bool_comp_opt_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	bool_comp_opt_btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bool_comp_opt_btn.visible = mode == TYPE_BOOL
	
	erase_btn.custom_minimum_size = Vector2(32.0, 32.0)
	erase_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_btn.flat = true
	
	data_panel.add_child(str_comp_ln_edt)
	data_panel.add_child(num_comp_spn_bx)
	data_panel.add_child(bool_comp_opt_btn)
	
	add_child(req_type_mn_btn)
	add_child(req_ln_edt)
	add_child(comp_mn_btn)
	add_child(data_panel)
	add_child(erase_btn)


func _ready() -> void:
	var req_popup: PopupMenu = req_type_mn_btn.get_popup()
	var comp_popup: PopupMenu = comp_mn_btn.get_popup()
	req_popup.add_icon_item(
			preload("res://addons/nexus_forge/icons/int.svg"),
			"",
			TYPE_INT)
	req_popup.add_icon_item(
			preload("res://addons/nexus_forge/icons/float.svg"),
			"",
			TYPE_FLOAT)
	req_popup.add_icon_item(
			preload("res://addons/nexus_forge/icons/bool.svg"),
			"",
			TYPE_BOOL)
	req_popup.add_icon_item(
			preload("res://addons/nexus_forge/icons/string.svg"),
			"",
			TYPE_STRING)
	req_type_mn_btn.icon = preload("res://addons/nexus_forge/icons/int.svg")
	req_type_mn_btn.set_meta(&"selected", TYPE_INT)
	req_type_mn_btn.focus_mode = Control.FOCUS_CLICK
	req_type_mn_btn.tooltip_text = "Requirement type"
	
	comp_popup.add_item("==", OP_EQUAL)
	comp_popup.add_item("!=", OP_NOT_EQUAL)
	comp_popup.add_item("<", OP_LESS)
	comp_popup.add_item("<=", OP_LESS_EQUAL)
	comp_popup.add_item(">", OP_GREATER)
	comp_popup.add_item(">=", OP_GREATER_EQUAL)
	
	comp_mn_btn.text = "=="
	comp_mn_btn.set_meta(&"selected", OP_EQUAL)
	comp_mn_btn.focus_mode = Control.FOCUS_ALL
	comp_mn_btn.tooltip_text = "Comparation type"
	
	bool_comp_opt_btn.add_item("False", 0)
	bool_comp_opt_btn.add_item("True", 1)
	
	bool_comp_opt_btn.select(0)
	
	erase_btn.icon = get_theme_icon("Remove", "EditorIcons")
	erase_btn.tooltip_text = "Erase requirement"
	
	req_type_mn_btn.focus_next = req_ln_edt.get_path()
	req_ln_edt.focus_next = comp_mn_btn.get_path()
	comp_mn_btn.focus_previous = req_ln_edt.get_path()
	comp_mn_btn.focus_next = num_comp_spn_bx.get_path()
	
	str_comp_ln_edt.focus_previous = comp_mn_btn.get_path()
	num_comp_spn_bx.focus_previous = comp_mn_btn.get_path()
	bool_comp_opt_btn.focus_previous = comp_mn_btn.get_path()
	
	str_comp_ln_edt.focus_next = erase_btn.get_path()
	num_comp_spn_bx.focus_next = erase_btn.get_path()
	bool_comp_opt_btn.focus_next = erase_btn.get_path()
	
	erase_btn.focus_previous = num_comp_spn_bx.get_path()
	
	erase_btn.pressed.connect(_on_erase_requirement_pressed)
	
	req_popup.id_pressed.connect(_on_mode_selected)
	comp_popup.id_pressed.connect(_on_comparation_selected)
	req_ln_edt.text_changed.connect(_requirement_changed)
	str_comp_ln_edt.text_changed.connect(_requirement_changed)
	num_comp_spn_bx.value_changed.connect(_requirement_changed)
	bool_comp_opt_btn.item_selected.connect(_requirement_changed)


func set_focus_previous_requirement(to_node: Control) -> void:
	if to_node == null:
		req_type_mn_btn.focus_previous = ^""
		req_ln_edt.focus_previous = ^""
	else:
		req_type_mn_btn.focus_previous = to_node.get_path()
		req_ln_edt.focus_previous = to_node.get_path()


func set_focus_next_requirement(to_node: Control) -> void:
	if to_node == null:
		erase_btn.focus_next = ^""
	else:
		erase_btn.focus_next = to_node.get_path()


func get_active_value() -> Variant:
	match mode:
		TYPE_INT:
			return int(num_comp_spn_bx.value)
		TYPE_FLOAT:
			return float(num_comp_spn_bx.value)
		TYPE_BOOL:
			return true if bool_comp_opt_btn.get_selected_id() == 1 else false
		TYPE_STRING:
			return str_comp_ln_edt.text
		_:
			return true


func get_requirement() -> Dictionary:
	return {
		req_ln_edt.text.strip_edges(): {
			"operator": comp_mn_btn.get_meta(&"selected", OP_EQUAL),
			"value": get_active_value()}
	}


func set_requirement(req_data: Dictionary) -> void:
	var key: String = req_data.keys()[0]
	req_ln_edt.text = key
	set_requirement_mode(typeof(req_data[key]["value"]))
	set_comparation_mode(req_data[key]["operator"])
	match mode:
		TYPE_INT, TYPE_FLOAT:
			num_comp_spn_bx.set_value_no_signal(req_data[key]["value"])
		TYPE_BOOL:
			select_bool_comp(req_data[key]["value"])
		TYPE_STRING:
			str_comp_ln_edt.text = req_data[key]["value"]


func has_text(text: String) -> bool:
	if text.is_empty():
		return false
	
	return req_ln_edt.text.containsn(text) or _data_to_string().containsn(text)


func _on_erase_requirement_pressed() -> void:
	erase_requirement_pressed.emit(self)


func _requirement_changed(_val = null) -> void:
	requirement_changed.emit()


func _on_comparation_selected(id: int) -> void:
	set_comparation_mode(id)
	requirement_changed.emit()


func set_comparation_mode(id: int) -> void:
	if id == comp_mn_btn.get_meta(&"selected", OP_EQUAL):
		return
	
	var comp_popup: PopupMenu = comp_mn_btn.get_popup()
	comp_mn_btn.set_meta(&"selected", id)
	comp_mn_btn.text = comp_popup.get_item_text(comp_popup.get_item_index(id))


func _on_mode_selected(id: int) -> void:
	set_requirement_mode(id)
	requirement_changed.emit()


func set_requirement_mode(id: int) -> void:
	if mode == id:
		return
	
	var comp_popup: PopupMenu = comp_mn_btn.get_popup()
	var type_popup: PopupMenu = req_type_mn_btn.get_popup()
	str_comp_ln_edt.visible = id == TYPE_STRING
	num_comp_spn_bx.visible = id == TYPE_INT or id == TYPE_FLOAT
	bool_comp_opt_btn.visible = id == TYPE_BOOL
	req_type_mn_btn.set_meta(&"selected", id)
	req_type_mn_btn.icon = type_popup.get_item_icon(type_popup.get_item_index(id))
	
	comp_popup.clear()
	
	if id == TYPE_INT or id == TYPE_FLOAT:
		comp_popup.add_item("==", OP_EQUAL)
		comp_popup.add_item("!=", OP_NOT_EQUAL)
		comp_popup.add_item("<", OP_LESS)
		comp_popup.add_item("<=", OP_LESS_EQUAL)
		comp_popup.add_item(">", OP_GREATER)
		comp_popup.add_item(">=", OP_GREATER_EQUAL)
		num_comp_spn_bx.step = 1.0 if id == TYPE_INT else 0.01
		comp_mn_btn.focus_next = num_comp_spn_bx.get_path()
		erase_btn.focus_previous = num_comp_spn_bx.get_path()
	else:
		var selected_id: int = comp_mn_btn.get_meta(&"selected", OP_EQUAL)
		
		if id == TYPE_BOOL:
			comp_mn_btn.focus_next = bool_comp_opt_btn.get_path()
			erase_btn.focus_previous = bool_comp_opt_btn.get_path()
		else:
			comp_mn_btn.focus_next = str_comp_ln_edt.get_path()
			erase_btn.focus_previous = str_comp_ln_edt.get_path()
		
		comp_popup.add_item("==", OP_EQUAL)
		comp_popup.add_item("!=", OP_NOT_EQUAL)
		if selected_id != OP_EQUAL and selected_id != OP_NOT_EQUAL:
			comp_mn_btn.set_meta(&"selected", OP_EQUAL)
			comp_mn_btn.text = "=="
	
	mode = id


func select_bool_comp(is_true: bool) -> void:
	bool_comp_opt_btn.select(bool_comp_opt_btn.get_item_index(1 if is_true else 0))


func _data_to_string() -> String:
	match mode:
		TYPE_INT, TYPE_FLOAT:
			return str(num_comp_spn_bx.value)
		TYPE_BOOL:
			return "true" if bool_comp_opt_btn.selected == 1 else "false"
		TYPE_STRING:
			return str_comp_ln_edt.text
		_:
			return ""
