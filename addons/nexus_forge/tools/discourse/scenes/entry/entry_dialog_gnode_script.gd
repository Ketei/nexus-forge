@tool
extends DiscourseGraphNode


func _ready() -> void:
	node_type = DialogData.DialogType.START 
	create_output_connection("next", 0)


func _is_root() -> bool:
	return true


func generate_node_dictionary() -> Dictionary:
	var next_port: DiscourseGraphNode = get_output_port_connection_by_id("next")
	var next_structure := NFDiscourseTool.get_next_structure()
	if next_port == null:
		return {}
	elif next_port.node_type == DialogData.DialogType.DIALOG or next_port.node_type == DialogData.DialogType.OPTIONS:
		next_structure["next_type"] = DialogData.NextType.ID
		next_structure["data"] = NFDiscourseTool.get_next_by_id()
		next_structure["data"]["next"] = next_port.node_id
		next_structure["data"]["use_shortcut"] = false
		next_structure["data"]["offset"] = next_port.position_offset
	elif next_port.node_type == DialogData.DialogType.ID:
		next_structure["next_type"] = DialogData.NextType.ID
		next_structure["data"] = next_port.generate_node_dictionary()
	elif next_port.node_type == DialogData.DialogType.RANDOM:
		next_structure["next_type"] = DialogData.NextType.RANDOM
		next_structure["data"] = next_port.generate_node_dictionary()
	elif next_port.node_type == DialogData.DialogType.CONDITION:
		next_structure["next_type"] = DialogData.NextType.CONDITION
		next_structure["data"] = next_port.generate_node_dictionary()
	elif next_port.node_type == DialogData.DialogType.END:
		next_structure["next_type"] = DialogData.NextType.END
		next_structure["data"] = next_port.generate_node_dictionary()
	
	return next_structure
