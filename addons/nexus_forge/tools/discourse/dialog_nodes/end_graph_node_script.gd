@tool
extends DiscourseGraphNode


func _ready() -> void:
	graph_type = GraphType.END
	add_utility()
	register_input_connection("previous", 0, false)


func _is_orphan() -> bool:
	return false


func _get_node_data() -> Dictionary:
	return {
		"_type": graph_type,
		"_offset": position_offset
		}
