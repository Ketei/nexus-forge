extends DiscourseGraphNode


func _ready() -> void:
	node_type = DialogData.DialogType.START 
	create_output_connection("next", 0)


func _is_root() -> bool:
	return true
