extends DiscourseGraphNode


func _ready() -> void:
	node_type = DialogData.DialogType.CONDITION
	create_input_connection("next", 0)
	create_input_connection("result", 1)
	
	create_output_connection("true", 0)
	create_output_connection("false", 1)
	
	var new_hbox_node := HBoxContainer.new()
	new_hbox_node.name = &"GraphButtonsNode"
	new_hbox_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_hbox_node.alignment = BoxContainer.ALIGNMENT_END
	
	var close_button := Button.new()
	close_button.name = &"CloseButton"
	close_button.text = "x"
	close_button.flat = true
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.pressed.connect(close_node)
	
	var title_bar: HBoxContainer = get_titlebar_hbox()
	title_bar.add_child(new_hbox_node)
	new_hbox_node.add_child(close_button)


func get_input_port_by_type(input_type: int) -> int:
	for port in range(get_child_count()):
		if not is_slot_enabled_left(port):
			continue
		if get_input_port_type(port) == input_type:
			return port
	return -1


func get_output_port_by_type(output_type: int) -> int:
	for port in range(get_child_count()):
		if not is_slot_enabled_right(port):
			continue
		if get_output_port_type(port) == output_type:
			return port
	return -1


func _is_root() -> bool:
	return not has_input_connection("next")


func generate_node_dictionary() -> Dictionary:
	var condition_dictionary: Dictionary = DialogData.get_condition_structure()
	if has_input_connection("result"):
		condition_dictionary["comparation"] = get_input_port_connection_by_id("result").generate_node_dictionary()
	if has_output_connection("true"):
		var next_true_node: DiscourseGraphNode = get_output_port_connection_by_id("true")
		var true_next_structure: Dictionary = DialogData.get_next_structure()
		if next_true_node.node_type == DialogData.DialogType.DIALOG or next_true_node.node_type == DialogData.DialogType.OPTIONS or next_true_node.node_type == DialogData.DialogType.ID:
			#condition_dictionary["true"] = DialogData.get_next_structure()
			true_next_structure["type"] = DialogData.NextType.ID
			true_next_structure["data"] = DialogData.get_next_by_id()
			true_next_structure["data"]["next"] = next_true_node.node_id
			true_next_structure["data"]["use_shortcut"] = next_true_node.node_type == DialogData.DialogType.ID
			true_next_structure["data"]["offset"] = next_true_node.position_offset
		else:
			match next_true_node.node_type:
				DialogData.DialogType.RANDOM:
					true_next_structure["type"] = DialogData.NextType.RANDOM
				DialogData.DialogType.CONDITION:
					true_next_structure["type"] = DialogData.NextType.CONDITION
				DialogData.DialogType.END:
					true_next_structure["type"] = DialogData.NextType.END
				_:
					printerr("Something unexpected happened while tryting to generate dict for conditional split")
			true_next_structure["data"] = next_true_node.generate_node_dictionary()
		condition_dictionary["true"] = true_next_structure
	
	if has_output_connection("false"):
		var next_false_node: DiscourseGraphNode = get_output_port_connection_by_id("false")
		var false_next_structure: Dictionary = DialogData.get_next_structure()
		if next_false_node.node_type == DialogData.DialogType.DIALOG or next_false_node.node_type == DialogData.DialogType.OPTIONS or next_false_node.node_type == DialogData.DialogType.ID:
			false_next_structure["type"] = DialogData.NextType.ID
			false_next_structure["data"] = DialogData.get_next_by_id()
			false_next_structure["data"]["next"] = next_false_node.node_id
			false_next_structure["data"]["use_shortcut"] = next_false_node.node_type == DialogData.DialogType.ID
			false_next_structure["data"]["offset"] = next_false_node.position_offset
		else:
			match next_false_node.node_type:
				DialogData.DialogType.RANDOM:
					false_next_structure["type"] = DialogData.NextType.RANDOM
				DialogData.DialogType.CONDITION:
					false_next_structure["type"] = DialogData.NextType.CONDITION
				DialogData.DialogType.END:
					false_next_structure["type"] = DialogData.NextType.END
				_:
					printerr("Something unexpected happened while tryting to generate dict for conditional split")
			false_next_structure["data"] = next_false_node.generate_node_dictionary()
	
	condition_dictionary["offset"] = position_offset
	return condition_dictionary
