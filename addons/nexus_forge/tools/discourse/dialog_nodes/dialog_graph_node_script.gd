@tool
extends DiscourseGraphNode


@onready var char_id_ln_edt: LineEdit = $CharacterNode/CharIDLnEdt
@onready var speed_spn_bx: SpinBox = $SpeedNode/SpeedSpnBx
@onready var dialog_txt_edt: TextEdit = $DialogTxtEdt


func _ready() -> void:
	graph_type = GraphType.DIALOG
	register_input_connection("previous", 0, false)
	register_output_connection("next", 0, true)
	add_utility()
	char_id_ln_edt.text_changed.connect(on_field_updated)
	speed_spn_bx.value_changed.connect(on_field_updated)
	dialog_txt_edt.text_changed.connect(on_field_updated)


func set_dialog_data(text: String, speed: float, character: String) -> void:
	dialog_txt_edt.text = text
	speed_spn_bx.value = speed
	char_id_ln_edt.text = character


func on_field_updated(_update_value: Variant = null) -> void:
	node_updated.emit()


func _is_orphan() -> bool:
	if has_any_input_connection("previous"):
		for input in get_input_connections("previous"):
			if not input._is_orphan():
				return false
	return true


func _get_node_data() -> Dictionary:
	return {
		"text": dialog_txt_edt.text.strip_edges(),
		"character_id": char_id_ln_edt.text.strip_edges(),
		"speed": speed_spn_bx.value,
		"next": -1 if not has_any_output_connection("next") else get_output_connections("next")[0].node_id,
		"_type": graph_type,
		"_offset": position_offset,
		"_size": size
		}
