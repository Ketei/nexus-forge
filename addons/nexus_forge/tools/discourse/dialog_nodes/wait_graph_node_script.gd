@tool
extends DiscourseGraphNode


@onready var wait_time_spn_bx: SpinBox = $HBoxContainer/WaitTimeSpnBx


func _ready() -> void:
	graph_type = GraphType.WAIT
	register_input_connection("previous", 0, false)
	register_output_connection("next", 0, true)
	add_utility()
	wait_time_spn_bx.value_changed.connect(on_field_changed)


func _get_node_data() -> Dictionary:
	return {
		"wait_time": wait_time_spn_bx.value,
		"next": -1 if not has_any_output_connection("next") else get_output_connections("next")[0].node_id,
		"_type": graph_type,
		"_offset": position_offset}


func _is_orphan() -> bool:
	if has_any_input_connection("previous"):
		for input in get_input_connections("previous"):
			if not input._is_orphan():
				return false
	return true


func set_wait_time(time: float) -> void:
	wait_time_spn_bx.value = time


func on_field_changed(_arg: Variant = null) -> void:
	node_updated.emit()
