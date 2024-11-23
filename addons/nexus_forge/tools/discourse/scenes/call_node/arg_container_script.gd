@tool
extends HBoxContainer


signal current_value_updated

const FLOAT_STEP: float = 0.01

@onready var val_spin_box: SpinBox = $ValContainer/ValSpinBox
@onready var bool_box: CheckBox = $ValContainer/BoolBox
@onready var string_line: LineEdit = $ValContainer/StringLine
@onready var var_label: Label = $VarLabel

var int_mode: bool = false


func _ready() -> void:
	#current_visible = val_spin_box
	val_spin_box.value_changed.connect(on_val_updated)
	bool_box.toggled.connect(on_bool_updated)
	string_line.text_changed.connect(on_text_updated)


func set_arg_type(type_of: Variant.Type) -> void:
	val_spin_box.visible = type_of == TYPE_INT or type_of == TYPE_FLOAT
	bool_box.visible = type_of == TYPE_BOOL
	string_line.visible = type_of == TYPE_STRING
	
	val_spin_box.step = FLOAT_STEP if type_of == TYPE_FLOAT else 1.0
	int_mode = type_of == TYPE_INT


func set_arg_value(new_value: Variant) -> void:
	var val_type := typeof(new_value)
	
	if val_type == TYPE_INT or val_type == TYPE_FLOAT:
		val_spin_box.value = new_value
	elif val_type == TYPE_BOOL:
		bool_box.button_pressed = new_value
	elif val_type == TYPE_STRING:
		string_line.text = new_value


#func generate_node_dictionary() -> Dictionary:
	#var value_dictionary: Dictionary = DialogData._get_val_structure()
	#if val_spin_box == current_visible:
		#if val_spin_box.step == 1.0:
			#value_dictionary["element_type"] = DialogData.ElementType.INT
		#else:
			#value_dictionary["element_type"] = DialogData.ElementType.FLOAT
		#value_dictionary["value"] = val_spin_box.value
	#
	#elif bool_box == current_visible:
		#value_dictionary["element_type"] = DialogData.ElementType.BOOL
		#value_dictionary["value"] = bool_box.button_pressed
	#else:
		#value_dictionary["element_type"] = DialogData.ElementType.STRING
		#value_dictionary["value"] = string_line.text
	#
	#return value_dictionary


func get_argument() -> Variant:
	if val_spin_box.visible:
		if int_mode:
			return int(val_spin_box.value)
		else:
			return float(val_spin_box.value)
	elif bool_box.visible:
		return bool_box.button_pressed
	else:
		return string_line.text.strip_edges()


func on_val_updated(_new_val: float) -> void:
	current_value_updated.emit()


func on_bool_updated(_is_pressed:bool) -> void:
	current_value_updated.emit()


func on_text_updated(_new_text: String) -> void:
	current_value_updated.emit()
