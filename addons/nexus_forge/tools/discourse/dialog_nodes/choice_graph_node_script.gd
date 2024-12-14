@tool
extends DiscourseGraphNode


var choices: Array[LineEdit] = []
@onready var choice_count_spn_bx: SpinBox = $HBoxContainer/ChoiceCountSpnBx
@onready var keep_text_chk_bx: CheckBox = $HBoxContainer/KeepTextChkBx


func _ready() -> void:
	graph_type = GraphType.CHOICES
	
	register_input_connection("previous", 0, false)
	register_input_connection("1", 1, true)
	register_output_connection("1", 0, true)
	
	add_utility()
	choices.append($ChoiceA)
	choice_count_spn_bx.value_changed.connect(on_field_updated)
	choice_count_spn_bx.value_changed.connect(on_choice_count_changed)
	keep_text_chk_bx.toggled.connect(on_field_updated)
	$ChoiceA.text_changed.connect(on_field_updated)


func _is_orphan() -> bool:
	if has_any_input_connection("next"):
		for input in get_input_connections("next"):
			if not input._is_orphan():
				return false
	return true


func _connection_set(is_input: bool, connection_id: String, node: DiscourseGraphNode) -> void:
	if is_input and connection_id == "next" and node != null:
		keep_text_chk_bx.visible = node.graph_type == GraphType.DIALOG
	else:
		keep_text_chk_bx.visible = false


func _get_node_data() -> Dictionary:
	var final_choices: Array[Dictionary] = []
	for choice_idx in range(choices.size()):
		var choice_id: String = str(choice_idx + 1)
		final_choices.append(
				{
					"text": get_child(choice_idx + 1).text.strip_edges(),
					"condition": -1 if not has_any_input_connection(choice_id) else get_input_connections(choice_id)[0].node_id,
					"next": -1 if not has_any_output_connection(choice_id) else get_output_connections(choice_id)[0].node_id
					})
	return {
		"keep_text": keep_text_chk_bx.button_pressed if keep_text_chk_bx.visible else false,
		"choices": final_choices,
		"_type": graph_type,
		"_offset": position_offset
	}


func set_choice_count(choice_count: int) -> void:
	choice_count_spn_bx.value = choice_count


func set_choices(choices_text: Array[String]) -> void:
	if choices_text.is_empty():
		return
		
	set_choice_count(choices_text.size())
	
	for choice_idx in range(choices_text.size()):
		choices[choice_idx].text = choices_text[choice_idx]


func set_keep_text(keep: bool) -> void:
	keep_text_chk_bx.button_pressed = keep


func on_choice_count_changed(new_count: float) -> void:
	var max_size: int = int(new_count)
	var choice_size: int = choices.size()
	if choice_size == max_size:
		return
	elif max_size < choice_size:
		for node_idx in range(maxi(1, max_size), choice_size):
			var child_idx: int = choices[node_idx].get_index()
			choices[node_idx].free()
			delete_input_connection(str(child_idx))
			delete_output_connection(str(child_idx))
		choices.resize(max_size)
	else:
		for idx in range(max_size - choice_size):
			var new_option := LineEdit.new()
			add_child(new_option)
			var child_idx: int = new_option.get_index()
			new_option.text_changed.connect(on_field_updated)
			new_option.placeholder_text = "Choice Text"
			choices.append(new_option)
			register_input_connection(str(child_idx), child_idx, true)
			register_output_connection(str(child_idx), child_idx - 1, true)
			set_slot(child_idx, true, PortType.VALUE, Color(0.163, 0.836, 0.729), true, PortType.NEXT, Color(0.157, 0.784, 0))
	size.y = 87 + (34 * choices.size())


func on_field_updated(_arg: Variant) -> void:
	node_updated.emit()
