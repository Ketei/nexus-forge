@tool
extends DiscourseGraphNode


func _ready() -> void:
	graph_type = GraphType.EVENT
	register_output_connection("next", 0, true)
	register_input_connection("previous", 0, true)
	register_input_connection("call", 1, false)
	register_input_connection("variable", 2, false)
	register_input_connection("signal", 3, false)
	add_utility()


func _is_orphan() -> bool:
	if has_any_input_connection("previous"):
		return get_input_connections("previous")[0]._is_orphan()
	return true


func _get_node_data() -> Dictionary:
	var callables: Array[int] = []
	var variables: Array[int] = []
	var signals: Array[int] = []
	
	for call_connection in get_input_connections("call"):
		callables.append(call_connection.node_id)
	
	for variable_connection in get_input_connections("variable"):
		variables.append(variable_connection.node_id)
	
	for signal_connection in get_input_connections("signal"):
		signals.append(signal_connection.node_id)
	
	return {
		"next": -1 if not has_any_output_connection("next") else get_output_connections("next")[0].node_id,
		"signals": signals,
		"callables": callables,
		"variables": variables,
		"_type": graph_type,
		"_offset": position_offset
	}
