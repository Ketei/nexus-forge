@tool
extends DiscourseGraphNode


signal go_to_dialog(dialog_id: String)

@onready var go_to_id_button: Button = $IDContainer/GoToIDButton
@onready var go_to_id_line: LineEdit = $IDContainer/GoToIDLine


func _ready() -> void:
	node_type = DialogData.DialogType.ID
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

	go_to_id_button.pressed.connect(_on_go_to_button_pressed)
	go_to_id_line.text_changed.connect(on_id_line_changed)


func _on_go_to_button_pressed() -> void:
	go_to_dialog.emit(go_to_id_line.text)
	go_to_id_button.release_focus()


func _is_root() -> bool:
	return not has_input_connection("next")


func get_connection_id() -> String:
	return go_to_id_line.text


func set_short_id(new_target: String) -> void:
	go_to_id_line.text = new_target


func generate_node_dictionary() -> Dictionary:
	var go_to_id_data: Dictionary = NFDiscourseTool.get_next_by_id()
	go_to_id_data["next"] = go_to_id_line.text
	go_to_id_data["use_shortcut"] = true
	go_to_id_data["offset"] = position_offset
	
	return go_to_id_data


func on_id_line_changed(_new_id: String) -> void:
	node_updated.emit()
