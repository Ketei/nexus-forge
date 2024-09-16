extends DiscourseGraphNode



func _ready() -> void:
	node_type = DialogData.DialogType.END
	create_input_connection("next", 0)
	
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


func _is_root() -> bool:
	return false


func generate_node_dictionary() -> Dictionary:
	var return_dict: Dictionary = DialogData.get_end_structure()
	return_dict["offset"] = position_offset
	return return_dict
