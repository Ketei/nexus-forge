extends HBoxContainer


signal close_requested(node: Control)

@onready var var_types_option: OptionButton = $VarTypesOption
@onready var val_var_node: SpinBox = $PanelContainer/ValVarNode
@onready var bool_var_node: CheckBox = $PanelContainer/BoolVarNode
@onready var str_val_node: LineEdit = $PanelContainer/StrValNode
@onready var var_name_line: LineEdit = $VarNameLine
@onready var remove_var_button: Button = $RemoveVarButton

var current_type: Control = null


func _ready() -> void:
	current_type = val_var_node
	var_types_option.item_selected.connect(on_var_type_selected)
	remove_var_button.pressed.connect(on_remove_pressed)


func on_remove_pressed() -> void:
	close_requested.emit(self)


func on_var_type_selected(selected_idx: int) -> void:
	current_type.visible = false
	
	match selected_idx:
		0: # Int
			current_type = val_var_node
			val_var_node.step = 1.0
		1: # Float
			current_type = val_var_node
			val_var_node.step = 0.01
		2: # Bool
			current_type = bool_var_node
		3: # String
			current_type = str_val_node
		_:
			current_type = str_val_node
			var_types_option.select(3)
	
	current_type.visible = true


func get_variable_path() -> String:
	return var_name_line.text


func get_variable_value() -> Variant:
	if val_var_node == current_type:
		return val_var_node.value
	elif bool_var_node == current_type:
		return bool_var_node.button_pressed
	else:
		return str_val_node.text
