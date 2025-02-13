@tool
extends DiscourseGraphNode


@onready var operator_opt_btn: OptionButton = $HBoxContainer/OperatorOptBtn


func _ready() -> void:
	graph_type = GraphType.MATH
	operator_opt_btn.clear()
	
	operator_opt_btn.add_item("+", OP_POSITIVE)
	operator_opt_btn.add_item("-", OP_NEGATE)
	operator_opt_btn.add_item("*", OP_MULTIPLY)
	operator_opt_btn.add_item("/", OP_DIVIDE)
	
	operator_opt_btn.select(0)
	
	register_input_connection("a", 0, true)
	register_input_connection("b", 1, true)
	register_output_connection("value", 0, true)
	add_utility()
	
	operator_opt_btn.item_selected.connect(on_field_updated)


func set_math_operator(operator: int) -> void:
	for idx in range(operator_opt_btn.item_count):
		if operator_opt_btn.get_item_id(idx) == operator:
			operator_opt_btn.select(idx)
			break


func on_field_updated(_arg: Variant = null) -> void:
	node_updated.emit()


#func _connection_set(is_input: bool, _connection_id: String, node: DiscourseGraphNode) -> void:
	#if is_input and node != null:
		#if node.graph_type == GraphType.VALUE:
			#node.set_type(ValueType.TYPE_FLOAT, true)


func _is_orphan() -> bool:
	if has_any_output_connection("value"):
		for out_con in get_output_connections("value"):
			if not out_con._is_orphan():
				return false
	return true


func _get_node_data() -> Dictionary:
	return {
		"a": -1 if not has_any_input_connection("a") else get_input_connections("a")[0].node_id,
		"b": -1 if not has_any_input_connection("b") else get_input_connections("b")[0].node_id,
		"operator": operator_opt_btn.get_item_id(operator_opt_btn.selected),
		"_offset": position_offset,
		"_type": graph_type}
