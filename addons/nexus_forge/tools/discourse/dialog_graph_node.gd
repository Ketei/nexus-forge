class_name DiscourseGraphNode
extends GraphNode


@warning_ignore("unused_signal")
signal node_updated
@warning_ignore("unused_signal")
signal disconnect_signaled(from: StringName, from_port:int, to: StringName, to_port: int)
@warning_ignore("unused_signal")
signal close_requested(graph_node: DiscourseGraphNode)
signal duplicate_requested(graph_node: DiscourseGraphNode)

enum GraphType {
	DIALOG,
	CHOICES,
	SIGNAL,
	VALUE,
	WAIT,
	PAUSE,
	CONDITIONAL_VALUE,
	CONDITIONAL_DIALOG,
	MATCH,
	MATH,
	EVAL,
	RANDOM,
	VAR_SET,
	JUMP,
	JUMP_TARGET,
	CALL,
	RETURN_CALL,
	EVENT,
	ENTRY,
	END,
}

enum ValueType{
	TYPE_INT = 0,
	TYPE_FLOAT = 1,
	TYPE_BOOL = 2,
	TYPE_STRING = 3,
	TYPE_VARIABLE = 4,
	TYPE_NIL = 5,
}

enum PortType {
	NEXT = 0,
	CALLABLE = 1,
	VARIABLES = 2,
	SIGNAL = 3,
	VALUE = 4
}

const CLOSE_ICON = preload("res://addons/nexus_forge/common_icons/close_icon.svg")
const COPY_ICON = preload("res://addons/nexus_forge/common_icons/copy_icon.svg")

var node_id: int = 0
var graph_type := GraphType.DIALOG
var _connections: Dictionary = {"input": {}, "output": {}}
var _button_box: HBoxContainer = null


func _connection_set(_is_input: bool, _connection_id: String, _node: DiscourseGraphNode) -> void:
	pass


func _get_node_data() -> Dictionary:
	return {}


func _is_orphan() -> bool:
	return true


func add_utility() -> void:
	if _button_box != null:
		_button_box.queue_free()
	
	_button_box = HBoxContainer.new()
	_button_box.name = &"GraphButtonsNode"
	_button_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_button_box.alignment = BoxContainer.ALIGNMENT_END
	
	var dup_btn := Button.new()
	dup_btn.name = &"DuplicateBtn"
	dup_btn.flat = true
	dup_btn.icon = COPY_ICON
	dup_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dup_btn.custom_minimum_size = Vector2(22, 22)
	
	var close_btn := Button.new()
	close_btn.name = &"CloseBtn"
	close_btn.flat = true
	close_btn.icon = CLOSE_ICON
	close_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_btn.custom_minimum_size = Vector2(22, 22)
	
	close_btn.pressed.connect(close_requested.emit.bind(self))
	dup_btn.pressed.connect(duplicate_requested.emit.bind(self))
	
	var title_bar: HBoxContainer = get_titlebar_hbox()
	title_bar.add_child(_button_box)
	_button_box.add_child(dup_btn)
	_button_box.add_child(close_btn)


func input_port_allows_multiple_connections(port_id: String) -> bool:
	return not _connections["input"][port_id]["single"]


func output_port_allows_multiple_connections(port_id: String) -> bool:
	return not _connections["output"][port_id]["single"]


func register_input_connection(connection_id: String, port_slot: int, single_connection: bool) -> void:
	_connections["input"][connection_id] = {
		"port": port_slot,
		"single": single_connection,
		"nodes": Array([], TYPE_OBJECT, &"GraphNode", DiscourseGraphNode)}


func delete_input_connection(connection_id: String) -> void:
	_connections["input"].erase(connection_id)


func delete_output_connection(connection_id: String) -> void:
	_connections["output"].erase(connection_id)


func has_any_input_connection(connection_id: String) -> bool:
	return not _connections["input"][connection_id]["nodes"].is_empty()


func get_input_connections(connection_id: String) -> Array[DiscourseGraphNode]:
	return _connections["input"][connection_id]["nodes"]


func get_input_id_by_connection(graph_node: DiscourseGraphNode) -> String:
	for connection in _connections["input"]:
		if _connections["input"][connection]["nodes"].has(graph_node):
			return connection
	return ""


func get_output_id_by_connection(graph_node: DiscourseGraphNode) -> String:
	for connection in _connections["output"]:
		if _connections["output"][connection]["nodes"].has(graph_node):
			return connection
	return ""


func register_output_connection(connection_id: String, port_slot: int, single_connection: bool) -> void:
	_connections["output"][connection_id] = {
		"port": port_slot,
		"single": single_connection,
		"nodes": Array([], TYPE_OBJECT, &"GraphNode", DiscourseGraphNode)}


func has_any_output_connection(connection_id: String) -> bool:
	return not _connections["output"][connection_id]["nodes"].is_empty()


func get_output_connections(connection_id: String) -> Array[DiscourseGraphNode]:
	return _connections["output"][connection_id]["nodes"]


func get_output_port(connection_id: String) -> int:
	return _connections["output"][connection_id]["port"]


func get_input_port(connection_id: String) -> int:
	return _connections["input"][connection_id]["port"]


func get_input_id_by_port(port: int) -> String:
	for input_id in _connections["input"]:
		if _connections["input"][input_id]["port"] == port:
			return input_id
	return ""


func get_output_id_by_port(port: int) -> String:
	for output_id in _connections["output"]:
		if _connections["output"][output_id]["port"] == port:
			return output_id
	return ""


func connect_input_node(connection_id: String, node: DiscourseGraphNode) -> void:
	_connections["input"][connection_id]["nodes"].append(node)
	_connection_set(true, connection_id, node)


func connect_output_node(connection_id: String, node: DiscourseGraphNode) -> void:
	_connections["output"][connection_id]["nodes"].append(node)
	_connection_set(false, connection_id, node)


func disconnect_input_node(connection_id: String, connection: DiscourseGraphNode) -> void:
	_connection_set(true, connection_id, null)
	_connections["input"][connection_id]["nodes"].erase(connection)


func disconnect_output_node(connection_id: String, connection: DiscourseGraphNode) -> void:
	_connection_set(false, connection_id, null)
	_connections["output"][connection_id]["nodes"].erase(connection)


func input_allows_multiple_connections(input_id: String) -> bool:
	return not _connections["input"][input_id]["single"]


func output_allows_multiple_connections(output_id: String) -> bool:
	return not _connections["output"][output_id]["single"]


func get_input_ids() -> Array[String]:
	return Array(_connections["input"].keys(), TYPE_STRING, &"", null)


func get_output_ids() -> Array[String]:
	return Array(_connections["output"].keys(), TYPE_STRING, &"", null)
