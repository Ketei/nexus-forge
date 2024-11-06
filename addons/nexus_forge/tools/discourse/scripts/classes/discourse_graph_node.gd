@tool
class_name DiscourseGraphNode
extends GraphNode


signal close_requested(graph_node: DiscourseGraphNode)
signal id_changed(new_id: String)
signal id_submitted(new_id: String)
signal node_updated

var in_connections: Dictionary = {}
var out_connections: Dictionary = {}

var node_type := DialogData.DialogType.DIALOG
var node_id: String = "":
	set(new_node_id):
		if _debug_naming:
			node_id = new_node_id
		else:
			node_id = new_node_id.strip_edges()
			id_changed.emit(node_id)
			node_updated.emit()
var _clear_on_load: bool = false
var _debug_naming: bool = false


func _get_node_id() -> String:
	return node_id


func create_input_connection(port_id: String, port_index: int) -> void:
	in_connections[port_id] = {"port": port_index, "connection": null}


func create_output_connection(port_id: String, port_index: int) -> void:
	out_connections[port_id] = {"port": port_index, "connection": null}


func erase_input_connection(port_id: String) -> void:
	in_connections.erase(port_id)


func erase_output_connection(port_id: String) -> void:
	out_connections.erase(port_id)


func connect_input_port(port_id: String, connection: DiscourseGraphNode) -> void:
	in_connections[port_id]["connection"] = connection


func connect_output_port(port_id: String, connection: DiscourseGraphNode) -> void:
	out_connections[port_id]["connection"] = connection


func disconnect_input_port(port_id: String) -> void:
	in_connections[port_id]["connection"] = null


func disconnect_output_port(port_id: String) -> void:
	out_connections[port_id]["connection"] = null


func has_output_connection(port_id: String) -> bool:
	if out_connections.has(port_id):
		return out_connections[port_id]["connection"] != null
	return false


func has_input_connection(port_id: String) -> bool:
	if in_connections.has(port_id):
		return in_connections[port_id]["connection"] != null
	return false


# --- Input Get ---
func get_input_port_idx_by_id(port_id: String) -> int:
	return in_connections[port_id]["port"]


func get_input_port_connection_by_id(port_id: String) -> DiscourseGraphNode:
	return  in_connections[port_id]["connection"]


func get_input_port_id_by_idx(port_idx: int) -> String:
	for port in in_connections:
		if in_connections[port]["port"] == port_idx:
			return port
	return ""


func get_input_port_connection_by_idx(port_idx: int) -> DiscourseGraphNode:
	for port in in_connections:
		if in_connections[port]["port"] == port_idx:
			return in_connections[port]["connection"]
	return null


func get_input_port_id_by_connection(connection: DiscourseGraphNode) -> String:
	for port in in_connections:
		if in_connections[port]["connection"] == connection:
			return port
	return ""


func get_input_port_idx_by_connection(connection: DiscourseGraphNode) -> int:
	for port in in_connections:
		if in_connections[port]["connection"] == connection:
			return in_connections[port]["port"]
	return -1

# -----------------

# --- Output Get ---
func get_output_port_idx_by_id(port_id: String) -> int:
	return out_connections[port_id]["port"]


func get_output_port_connection_by_id(port_id: String) -> DiscourseGraphNode:
	return  out_connections[port_id]["connection"]


func get_output_port_id_by_idx(port_idx: int) -> String:
	for port in out_connections:
		if out_connections[port]["port"] == port_idx:
			return port
	return ""


func get_output_port_connection_by_idx(port_idx: int) -> DiscourseGraphNode:
	for port in out_connections:
		if out_connections[port]["port"] == port_idx:
			return out_connections[port]["connection"]
	return null


func get_output_port_id_by_connection(connection: DiscourseGraphNode) -> String:
	for port in out_connections:
		if out_connections[port]["connection"] == connection:
			return port
	return ""


func get_output_port_idx_by_connection(connection: DiscourseGraphNode) -> int:
	for port in out_connections:
		if out_connections[port]["connection"] == connection:
			return out_connections[port]["port"]
	return -1

# ------------------

func close_node() -> void:
	close_requested.emit(self)


func get_connected_input_ports() -> Array[String]:
	var connections_list: Array[String] = []
	for port_id in in_connections:
		if has_input_connection(port_id):
			connections_list.append(port_id)
	return connections_list


func get_connected_output_ports() -> Array[String]:
	var connections_list: Array[String] = []
	for port_id in out_connections:
		if has_output_connection(port_id):
			connections_list.append(port_id)
	return connections_list


func _is_root() -> bool:
	return false


## Will return true if there is a path from this node to the dialog entry.
func is_connected_to_root(_from_node: DiscourseGraphNode = null) -> bool:
	var caller_node: DiscourseGraphNode = self if _from_node == null else _from_node
	
	if self == _from_node:
		return false
	
	
	if node_type == DialogData.DialogType.START:
		return true
	elif node_type == DialogData.DialogType.DIALOG or node_type == DialogData.DialogType.OPTIONS:
		if has_input_connection("next"):
			return get_input_port_connection_by_id("next").is_connected_to_root(caller_node)
		else:
			return false
	elif node_type == DialogData.DialogType.CALL:
		if has_output_connection("call"):
			return get_output_port_connection_by_id("call").is_connected_to_root(caller_node)
		else:
			return false
	elif node_type == DialogData.DialogType.CHARACTER:
		if has_output_connection("character"):
			return get_output_port_connection_by_id("character").is_connected_to_root(caller_node)
		else:
			return false
	elif node_type == DialogData.DialogType.COMPARATION:
		if has_output_connection("result"):
			return get_output_port_connection_by_id("result").is_connected_to_root(caller_node)
		else:
			return false
	elif node_type == DialogData.DialogType.CONDITION:
		if has_input_connection("next"):
			return get_input_port_connection_by_id("next").is_connected_to_root(caller_node)
		else:
			return false
	elif node_type == DialogData.DialogType.RANDOM:
		if has_input_connection("next"):
			return get_input_port_connection_by_id("next").is_connected_to_root(caller_node)
		else:
			return false
	elif node_type == DialogData.DialogType.REPLY:
		if has_output_connection("reply"):
			return get_output_port_connection_by_id("reply").is_connected_to_root(caller_node)
		else:
			return false
	elif node_type == DialogData.DialogType.VARIABLES:
		if has_output_connection("variables"):
			return get_output_port_connection_by_id("variables").is_connected_to_root(caller_node)
		else:
			return false
	elif node_type == DialogData.DialogType.SIGNAL:
		if has_output_connection("signal"):
			return get_output_port_connection_by_id("signal").is_connected_to_root(caller_node)
		else:
			return false
	elif node_type == DialogData.DialogType.COMMENT:
		return false
	elif node_type == DialogData.DialogType.ID:
		if has_input_connection("next"):
			return get_input_port_connection_by_id("next").is_connected_to_root(caller_node)
		else:
			return false
	elif node_type == DialogData.DialogType.VALUE:
		if has_output_connection("value"):
			return get_output_port_connection_by_id("value").is_connected_to_root(caller_node)
		else:
			return false
	else:
		return false


func get_earliest_connected_node(_from_node: DiscourseGraphNode = null, _prev_node: DiscourseGraphNode = null) -> DiscourseGraphNode:
	var caller_node: DiscourseGraphNode = self if _from_node == null else _from_node
	
	if self == _from_node:
		if _prev_node == null:
			return self
		else:
			return _prev_node
	
	if node_type == DialogData.DialogType.START:
		return self
	elif node_type == DialogData.DialogType.DIALOG or node_type == DialogData.DialogType.OPTIONS:
		if has_input_connection("next"):
			return get_input_port_connection_by_id("next").get_earliest_connected_node(caller_node, self)
		else:
			return self
	elif node_type == DialogData.DialogType.CALL:
		if has_output_connection("call"):
			return get_output_port_connection_by_id("call").get_earliest_connected_node(caller_node, self)
		else:
			return self
	elif node_type == DialogData.DialogType.CHARACTER:
		if has_output_connection("character"):
			return get_output_port_connection_by_id("character").get_earliest_connected_node(caller_node, self)
		else:
			return self
	elif node_type == DialogData.DialogType.COMPARATION:
		if has_output_connection("result"):
			return get_output_port_connection_by_id("result").get_earliest_connected_node(caller_node, self)
		else:
			return self
	elif node_type == DialogData.DialogType.CONDITION:
		if has_input_connection("next"):
			return get_input_port_connection_by_id("next").get_earliest_connected_node(caller_node, self)
		else:
			return self
	elif node_type == DialogData.DialogType.RANDOM:
		if has_input_connection("next"):
			return get_input_port_connection_by_id("next").get_earliest_connected_node(caller_node, self)
		else:
			return self
	elif node_type == DialogData.DialogType.REPLY:
		if has_output_connection("reply"):
			return get_output_port_connection_by_id("reply").get_earliest_connected_node(caller_node, self)
		else:
			return self
	elif node_type == DialogData.DialogType.VARIABLES:
		if has_output_connection("variables"):
			return get_output_port_connection_by_id("variables").get_earliest_connected_node(caller_node, self)
		else:
			return self
	elif node_type == DialogData.DialogType.SIGNAL:
		if has_output_connection("signal"):
			return get_output_port_connection_by_id("signal").get_earliest_connected_node(caller_node, self)
		else:
			return self
	elif node_type == DialogData.DialogType.COMMENT:
		return self
	elif node_type == DialogData.DialogType.ID:
		if has_input_connection("next"):
			return get_input_port_connection_by_id("next").get_earliest_connected_node(caller_node, self)
		else:
			return self
	elif node_type == DialogData.DialogType.VALUE:
		if has_output_connection("value"):
			return get_output_port_connection_by_id("value").get_earliest_connected_node(caller_node, self)
		else:
			return self
	else:
		return self


func generate_node_dictionary() -> Dictionary:
	return {}
