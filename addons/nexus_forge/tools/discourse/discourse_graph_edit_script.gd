@tool
extends GraphEdit



func get_conversation() -> Array[Dictionary]:
	var nodes: Array[DiscourseGraphNode] = []
	var orphans: Array[DiscourseGraphNode] = []
	var node_idx: int = 0
	var conv_data: Array[Dictionary] = []
	
	for node in get_children():
		if node is DiscourseGraphNode:
			nodes.append(node)
			node.node_id = node_idx
			node_idx += 1
	
	for node in nodes:
		conv_data.append(node._get_node_data())
	
	return conv_data


#func on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	#var from_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(from_node))
	#var to_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(to_node))


func on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	pass
