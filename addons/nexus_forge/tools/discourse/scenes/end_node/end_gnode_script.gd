extends DiscourseGraphNode



func _ready() -> void:
	node_type = DialogData.DialogType.END
	create_input_connection("next", 0)


func _is_root() -> bool:
	return false


func generate_node_dictionary() -> Dictionary:
	var return_dict: Dictionary = DialogData.get_end_structure()
	return_dict["offset"] = position_offset
	return return_dict
