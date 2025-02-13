@tool
extends DiscourseGraphNode


signal target_changed(node)

var id_changed: bool = false

@onready var jump_id: LineEdit = $JumpID


func _ready() -> void:
	graph_type = GraphType.JUMP_TARGET
	
	add_utility()
	register_output_connection("next", 0, true)
	
	jump_id.focus_exited.connect(on_focus_lost)
	jump_id.text_changed.connect(on_text_changed)


func _get_node_data() -> Dictionary:
	return {
		"name": jump_id.text.strip_edges(),
		"next": -1 if not has_any_output_connection("next") else get_output_connections("next")[0].node_id,
		"_type": graph_type,
		"_offset": position_offset
	}


func _is_orphan() -> bool:
	return false


func get_current_id() -> String:
	return jump_id.text.strip_edges()


func set_current_id(new_id: String) -> void:
	jump_id.text = new_id


func on_focus_lost() -> void:
	target_changed.emit(self)


func on_text_changed(_text: String) -> void:
	if not id_changed:
		id_changed = true
