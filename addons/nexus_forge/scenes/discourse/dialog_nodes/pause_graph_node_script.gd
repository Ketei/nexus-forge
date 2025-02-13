@tool
extends DiscourseGraphNode


func _ready() -> void:
	graph_type = GraphType.PAUSE
	register_input_connection("previous", 0, false)
	register_output_connection("next", 0, true)
	add_utility()


func _is_orphan() -> bool:
	if has_any_input_connection("previous"):
		for prev_con in get_input_connections("previous"):
			if not prev_con._is_orphan():
				return false
	return true


func _get_node_data() -> Dictionary:
	return {
		"next": -1 if not has_any_output_connection("next") else get_output_connections("next")[0].node_id,
		"_type": graph_type,
		"_offset": position_offset
	}
