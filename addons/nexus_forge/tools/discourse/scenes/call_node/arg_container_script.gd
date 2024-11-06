@tool
extends HBoxContainer


signal current_value_updated

@onready var val_spin_box: SpinBox = $ValContainer/ValSpinBox
@onready var bool_box: CheckBox = $ValContainer/BoolBox
@onready var string_line: LineEdit = $ValContainer/StringLine
@onready var var_label: Label = $VarLabel

var current_visible: Control


func _ready() -> void:
	current_visible = val_spin_box
	val_spin_box.value_changed.connect(on_val_updated)
	bool_box.toggled.connect(on_bool_updated)
	string_line.text_changed.connect(on_text_updated)


func set_arg_type(type_of: Variant.Type) -> void:
	current_visible.visible = false
	
	match type_of:
		TYPE_INT:
			current_visible = val_spin_box
			val_spin_box.step = 1.0
		TYPE_FLOAT:
			current_visible = val_spin_box
			val_spin_box.step = 1.0
		TYPE_BOOL:
			current_visible = bool_box
		TYPE_STRING:
			current_visible = string_line
		_:
			current_visible = string_line
	
	current_visible.visible = true


func set_arg_value(new_value: Variant) -> void:
	var val_type := typeof(new_value)
	if current_visible == val_spin_box:
		if val_type == TYPE_INT or val_type == TYPE_FLOAT:
			val_spin_box.value = new_value
	elif current_visible == bool_box:
		if val_type == TYPE_BOOL:
			bool_box.button_pressed = new_value
	elif current_visible == string_line:
		if val_type == TYPE_STRING:
			string_line.text = new_value


func generate_node_dictionary() -> Dictionary:
	var value_dictionary: Dictionary = DialogData._get_val_structure()
	if val_spin_box == current_visible:
		if val_spin_box.step == 1.0:
			value_dictionary["element_type"] = DialogData.ElementType.INT
		else:
			value_dictionary["element_type"] = DialogData.ElementType.FLOAT
		value_dictionary["value"] = val_spin_box.value
	
	elif bool_box == current_visible:
		value_dictionary["element_type"] = DialogData.ElementType.BOOL
		value_dictionary["value"] = bool_box.button_pressed
	else:
		value_dictionary["element_type"] = DialogData.ElementType.STRING
		value_dictionary["value"] = string_line.text
	
	return value_dictionary


func on_val_updated(_new_val: float) -> void:
	if current_visible == val_spin_box:
		current_value_updated.emit()


func on_bool_updated(_is_pressed:bool) -> void:
	if current_visible == bool_box:
		current_value_updated.emit()


func on_text_updated(_new_text: String) -> void:
	if current_visible == string_line:
		current_value_updated.emit()
