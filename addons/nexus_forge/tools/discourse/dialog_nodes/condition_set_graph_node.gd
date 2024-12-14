@tool
extends DiscourseGraphNode


func _ready() -> void:
	graph_type = GraphType.CONDITIONAL_VALUE
	register_input_connection("value", 0, true)
	register_input_connection("true", 1, true)
	register_input_connection("false", 2, true)
	register_output_connection("variable", 0, false)
	add_utility()


func _is_orphan() -> bool:
	if has_any_output_connection("variable"):
		for output_con in get_output_connections("variable"):
			if not output_con._is_orphan():
				return false
	return true


func _get_node_data() -> Dictionary:
	return {
		"result": -1 if not has_any_input_connection("value") else get_input_connections("value")[0].node_id,
		"true": -1 if not has_any_input_connection("true") else get_input_connections("true")[0].node_id,
		"false": -1 if not has_any_input_connection("false") else get_input_connections("false")[0].node_id,
		"_type": graph_type,
		"_offset": position_offset
	}
