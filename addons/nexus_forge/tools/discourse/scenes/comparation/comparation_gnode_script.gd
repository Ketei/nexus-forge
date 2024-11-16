@tool
extends DiscourseGraphNode


@onready var operation_option: OptionButton = $CompContainer/OperationOption


func _ready() -> void:
	node_type = DialogData.DialogType.COMPARATION
	create_output_connection("result", 0)
	
	create_input_connection("value_a", 0)
	create_input_connection("value_b", 1)
	
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
	
	operation_option.item_selected.connect(on_operation_selected)


func select_by_text(comparation: Variant.Operator) -> void:
	operation_option.select(operator_to_id(comparation))


func selected_to_operator(selected_id: int) -> Variant.Operator:
	match selected_id:
		0:
			return OP_EQUAL
		1:
			return OP_NOT_EQUAL
		2:
			return OP_LESS
		3:
			return OP_LESS_EQUAL
		4:
			return OP_GREATER_EQUAL
		5:
			return OP_GREATER
		_:
			return OP_EQUAL


func operator_to_id(operator: Variant.Operator) -> int:
	match operator:
		OP_EQUAL:
			return 0
		OP_NOT_EQUAL:
			return 1
		OP_LESS:
			return 2
		OP_LESS_EQUAL:
			return 3
		OP_GREATER_EQUAL:
			return 4
		OP_GREATER:
			return 5
		_:
			return 0



func _is_root() -> bool:
	return not has_output_connection("result")


func generate_node_dictionary() -> Dictionary:
	var comp_dictionary: Dictionary = DialogData.get_comparation_structure()
	if has_input_connection("value_a"):
		comp_dictionary["var_a"] = get_input_port_connection_by_id("value_a").generate_node_dictionary()
	if has_input_connection("value_b"):
		comp_dictionary["var_b"] = get_input_port_connection_by_id("value_b").generate_node_dictionary()
	comp_dictionary["operator"] = selected_to_operator(operation_option.get_item_id(operation_option.selected))
	comp_dictionary["offset"] = position_offset
	#print("----------------")
	#print(comp_dictionary)
	#print("-------------------")
	return comp_dictionary


func on_operation_selected(_op_idx: int) -> void:
	node_updated.emit() 
