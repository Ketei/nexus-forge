extends DiscourseGraphNode


@onready var type_option_button: OptionButton = $TypeContainer/TypeOptionButton
@onready var val_spin_box: SpinBox = $PanelContainer/ValSpinBox
@onready var string_edit: LineEdit = $PanelContainer/StringEdit
@onready var bool_box: CheckBox = $PanelContainer/BoolBox

@onready var current_node: Control = val_spin_box


func _ready() -> void:
	node_type = DialogData.DialogType.VALUE
	create_output_connection("value", 0)
	
	var new_hbox_node := HBoxContainer.new()
	new_hbox_node.name = &"GraphButtonsNode"
	new_hbox_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_hbox_node.alignment = BoxContainer.ALIGNMENT_END
	
	var close_button := Button.new()
	close_button.name = &"CloseButton"
	close_button.text = "x"
	close_button.flat = true
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.pressed.connect(close_node)
	
	var title_bar: HBoxContainer = get_titlebar_hbox()
	title_bar.add_child(new_hbox_node)
	new_hbox_node.add_child(close_button)
	
	val_spin_box.value_changed.connect(on_val_updated)
	string_edit.text_changed.connect(on_string_updated)
	bool_box.toggled.connect(on_bool_toggled)


func on_type_selected(idx_selected: int) -> void:
	current_node.visible = false
	match idx_selected:
		0: # Fnteger
			current_node = val_spin_box
			val_spin_box.step = 1
		1: # Float
			current_node = val_spin_box
			val_spin_box.step = 0.01
		2: # Bool
			current_node = bool_box
		3: # String
			current_node = string_edit
		4: # Variable
			current_node = string_edit
		_:
			type_option_button.select(3)
			current_node = string_edit
	current_node.visible = true


func select_by_resource(type: DialogData.ElementType) -> void:
	if type == DialogData.ElementType.INT:
		on_type_selected(0)
	elif type == DialogData.ElementType.FLOAT:
		on_type_selected(1)
	elif type == DialogData.ElementType.BOOL:
		on_type_selected(2)
	elif type == DialogData.ElementType.STRING:
		on_type_selected(3)
	if type == DialogData.ElementType.VAR:
		on_type_selected(4)


func set_value(new_value: Variant) -> void:
	var val_type: int = typeof(new_value)
	if current_node == val_spin_box:
		if val_type == TYPE_INT or val_type == TYPE_FLOAT:
			val_spin_box.value = new_value
	elif current_node == string_edit:
		if val_type == TYPE_STRING:
			string_edit.text = new_value
	elif current_node == bool_box:
		if val_type == TYPE_BOOL:
			bool_box.button_pressed = new_value


func get_input_port_by_type(input_type: int) -> int:
	for port in range(get_child_count()):
		if not is_slot_enabled_left(port):
			continue
		if get_input_port_type(port) == input_type:
			return port
	return -1


func get_output_port_by_type(output_type: int) -> int:
	for port in range(get_child_count()):
		if not is_slot_enabled_right(port):
			continue
		if get_output_port_type(port) == output_type:
			return port
	return -1


func _is_root() -> bool:
	return not has_output_connection("value")


func on_val_updated(_new_val: float) -> void:
	if current_node == val_spin_box:
		node_updated.emit()


func on_string_updated(_new_string: String) -> void:
	if current_node == string_edit:
		node_updated.emit()


func on_bool_toggled(_is_toggled: bool) -> void:
	if current_node == bool_box:
		node_updated.emit()


func generate_node_dictionary() -> Dictionary:
	var value_struct: Dictionary = DialogData.get_element_structure()
	value_struct["offset"] = position_offset
	if current_node == val_spin_box:
		if val_spin_box.step == 1.0:
			value_struct["value"] = DialogData._get_val_structure(DialogData.ElementType.INT)
		else:
			value_struct["value"] = DialogData._get_val_structure(DialogData.ElementType.FLOAT)
		value_struct["value"]["value"] = val_spin_box.value
	elif current_node == string_edit:
		if type_option_button.selected == 4:
			value_struct["value"] = DialogData._get_val_structure(DialogData.ElementType.VAR)
		else:
			value_struct["value"] = DialogData._get_val_structure(DialogData.ElementType.STRING)
		value_struct["value"]["value"] = string_edit.text
	elif current_node == bool_box:
		value_struct["value"] = DialogData._get_val_structure(DialogData.ElementType.BOOL)
		value_struct["value"]["value"] = bool_box.button_pressed

	return value_struct
