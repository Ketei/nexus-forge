@tool
extends PopupMenu


var to_input: bool = false
var from_node: DiscourseGraphNode = null
var from_port: int = 0
var to_node: DiscourseGraphNode = null
var to_port: int = 0
var at := Vector2.ZERO


func reset_menu() -> void:
	clear(true)
	size = Vector2i(20,10)
	to_input = false
	from_node = null
	from_port = 0
	to_node = null
	to_port = 0
	at = Vector2.ZERO
	
	for con_sig in get_signal_connection_list(&"id_pressed"):
		con_sig["signal"].disconnect(con_sig["callable"])
