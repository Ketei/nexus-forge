@tool
extends PanelContainer


signal field_updated

var _string_line_edit: LineEdit = null
var _val_spinbox: SpinBox = null
var _bool_checkbtn: CheckButton = null


func _ready() -> void:
	custom_minimum_size.y = 32
	add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	
	_string_line_edit = LineEdit.new()
	_val_spinbox = SpinBox.new()
	_bool_checkbtn = CheckButton.new()
	
	add_child(_string_line_edit)
	add_child(_val_spinbox)
	add_child(_bool_checkbtn)
	
	_string_line_edit.placeholder_text = "String"
	_string_line_edit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	_val_spinbox.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	_bool_checkbtn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bool_checkbtn.text = "False"
	
	_bool_checkbtn.visible = true
	_val_spinbox.visible = false
	_string_line_edit.visible = false
	
	_bool_checkbtn.toggled.connect(on_bool_toggled)
	_bool_checkbtn.toggled.connect(on_field_updated)
	_val_spinbox.value_changed.connect(on_field_updated)
	_string_line_edit.text_changed.connect(on_field_updated)


func on_field_updated(_arg: Variant = null) -> void:
	field_updated.emit()


func on_bool_toggled(is_pressed: bool) -> void:
	_bool_checkbtn.text = "True" if is_pressed else "False"


func set_type(val_type: int) -> void:
	_bool_checkbtn.visible = val_type == TYPE_BOOL
	_string_line_edit.visible = val_type == TYPE_STRING
	_val_spinbox.visible = val_type == TYPE_INT or val_type == TYPE_FLOAT
	if _val_spinbox.visible:
		_val_spinbox.step = 0.01 if val_type == TYPE_FLOAT else 1.0


func set_value(value: Variant) -> void:
	match typeof(value):
		TYPE_INT:
			_val_spinbox.value = value
		TYPE_FLOAT:
			_val_spinbox.value = value
		TYPE_BOOL:
			_bool_checkbtn.button_pressed = value
		TYPE_STRING:
			_string_line_edit.text = value


func get_value() -> Variant:
	if _string_line_edit.visible:
		return _string_line_edit.text.strip_edges()
	elif _val_spinbox.visible:
		if _val_spinbox.step == 1.0:
			return int(_val_spinbox.value)
		else:
			return _val_spinbox.value
	else:
		return _bool_checkbtn.button_pressed
