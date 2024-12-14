@tool
extends DiscourseGraphNode


func _ready() -> void:
	graph_type = GraphType.CONDITIONAL_DIALOG
	register_input_connection("previous", 0, true)
	register_input_connection("value", 1, true)
	register_output_connection("true", 0, true)
	register_output_connection("false", 1, true)
	add_utility()


func _is_orphan() -> bool:
	if has_any_input_connection("previous"):
		return get_input_connections("previous")[0]._is_orphan()
	return true


func _get_node_data() -> Dictionary:
	return {
		"true": -1 if not has_any_output_connection("true") else get_output_connections("true")[0].node_id,
		"false": -1 if not has_any_output_connection("false") else get_output_connections("false")[0].node_id,
		"result": -1 if not has_any_input_connection("value") else get_input_connections("value")[0].node_id,
		"_type": graph_type,
		"_offset": position_offset
	}
