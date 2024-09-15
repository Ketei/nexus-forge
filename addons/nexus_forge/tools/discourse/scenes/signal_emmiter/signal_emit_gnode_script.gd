extends DiscourseGraphNode


@onready var signal_val_line: LineEdit = $SignalValLine


func _ready() -> void:
	node_type = DialogData.DialogType.SIGNAL
	create_output_connection("signal", 0)
	
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
	return not has_output_connection("signal")


func generate_node_dictionary() -> Dictionary:
	var new_signal_data := DialogData.get_signal_structure()
	new_signal_data["signal"] = signal_val_line.text
	new_signal_data["offset"] = position_offset
	return new_signal_data
