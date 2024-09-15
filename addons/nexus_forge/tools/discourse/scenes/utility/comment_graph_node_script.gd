extends DiscourseGraphNode


@onready var comment_text: TextEdit = $ComentText


func _ready() -> void:
	node_type = DialogData.DialogType.COMMENT
	
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
	return true


func generate_node_dictionary() -> Dictionary:
	var comment_struct := DialogData.get_comment_structure()
	comment_struct["text"] = comment_text.text
	comment_struct["offset"] = position_offset
	comment_struct["size"] = size
	return comment_struct
