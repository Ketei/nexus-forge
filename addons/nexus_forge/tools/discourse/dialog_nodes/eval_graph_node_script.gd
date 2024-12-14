@tool
extends DiscourseGraphNode


@onready var eval_opt_btn: OptionButton = $HBoxContainer/EvalOptBtn


func _ready() -> void:
	graph_type = GraphType.EVAL
	eval_opt_btn.clear()
	eval_opt_btn.add_item("==", OP_EQUAL)
	eval_opt_btn.add_item("!=", OP_NOT_EQUAL)
	eval_opt_btn.add_item("<", OP_LESS)
	eval_opt_btn.add_item("<=", OP_LESS_EQUAL)
	eval_opt_btn.add_item(">", OP_GREATER)
	eval_opt_btn.add_item(">=", OP_GREATER_EQUAL)
	
	register_input_connection("a", 0, true)
	register_input_connection("b", 1, true)
	register_output_connection("value", 0, true)
	add_utility()
	eval_opt_btn.item_selected.connect(on_field_updated)


func on_field_updated(_arg: Variant = null) -> void:
	node_updated.emit()


func _is_orphan() -> bool:
	if has_any_output_connection("value"):
		for result_opt in get_output_connections("value"):
			if not result_opt._is_orphan():
				return false
	return true


func _get_node_data() -> Dictionary:
	return {
		"a": -1 if not has_any_input_connection("a") else get_input_connections("a")[0].node_id,
		"b": -1 if not has_any_input_connection("b") else get_input_connections("b")[0].node_id,
		"operator": eval_opt_btn.get_item_id(eval_opt_btn.selected),
		"_type": graph_type,
		"_offset": position_offset
	}


func set_operator(operator: int) -> void:
	for item_idx in range(eval_opt_btn.item_count):
		if eval_opt_btn.get_item_id(item_idx) == operator:
			eval_opt_btn.select(item_idx)
			break
