@tool
extends DiscourseGraphNode


@onready var reply_line: LineEdit = $RepliesContainer/Reply/ReplyLine


func _ready() -> void:
	node_type = DialogData.DialogType.REPLY
	create_output_connection("reply", 0)
	
	create_input_connection("result", 0)
	create_input_connection("signal", 1)
	create_input_connection("variables", 2)
	create_input_connection("call", 3)
	
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
	
	reply_line.text_changed.connect(on_reply_text_changed)


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
	return not has_output_connection("reply")


func generate_node_dictionary() -> Dictionary:
	var reply_otion_data: Dictionary = NFDiscourseTool.get_option_structure()
	reply_otion_data["text"] = reply_line.text
	reply_otion_data["offset"] = position_offset
	if has_input_connection("result"):
		reply_otion_data["conditions"] = get_input_port_connection_by_id("result").generate_node_dictionary()
	if has_input_connection("signal"):
		reply_otion_data["signal"] = get_input_port_connection_by_id("signal").generate_node_dictionary()
	if has_input_connection("variables"):
		reply_otion_data["set_variable"] = get_input_port_connection_by_id("variables").generate_node_dictionary()
	if has_input_connection("call"):
		reply_otion_data["call"] = get_input_port_connection_by_id("call").generate_node_dictionary()
	
	return reply_otion_data


func on_reply_text_changed(_new_text: String) -> void:
	node_updated.emit()
