@tool
extends DiscourseGraphNode


func _ready() -> void:
	graph_type = GraphType.ENTRY
	register_output_connection("next", 0, true)


func _is_orphan() -> bool:
	return false


func _get_node_data() -> Dictionary:
	return {
		"_type": graph_type,
		"_offset": position_offset}


func get_entry_id() -> int:
	if has_any_output_connection("next"):
		return get_output_connections("next")[0].node_id
	return -1
