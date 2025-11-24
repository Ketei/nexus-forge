extends DiscourseGraphNode


var _highest_port_connected: int = -1


func _post_init() -> void:
	name = &"DialogMerge"
	custom_id = "DialogMerge"
	title = "Dialog Merge"
	size = Vector2(200.0, 79.0)
	node_type = DialogueNodeType.DIALOG_MERGE
	parent_mode = PortMode.INPUT
	parent_port = 0
	
	var first_point: Label = Label.new()
	first_point.text = "Merged"
	first_point.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	first_point.custom_minimum_size.y = 24.0
	first_point.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_field(
			&"merge_0",
			first_point,
			false,
			SlotConnectionType.DIALOG,
			SlotConnectionType.DIALOG)
	set_slot_color_left(0, COLORS["dialog"])
	set_slot_color_right(0, COLORS["dialog"])


func _ready() -> void:
	for child_idx in range(get_child_count()):
		set_slot_custom_icon_left(child_idx, flow_icon)
	
	set_slot_custom_icon_right(0, flow_icon)


func _on_input_connected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	if _highest_port_connected < input_port:
		_highest_port_connected = input_port
		var field_idx: int = add_field(
				&"merge_" + StringName(str(_highest_port_connected + 1)),
				get_new_merge_node(),
				false,
				SlotConnectionType.DIALOG)
		set_slot_custom_icon_left(field_idx, flow_icon)
		set_slot_color_left(field_idx, COLORS["dialog"])


func _on_input_disconnected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	if input_port == _highest_port_connected:
		var target_remove: StringName = &"merge_" + StringName(str(input_port + 1))
		remove_field(target_remove)
		_highest_port_connected -= 1
		
		for port_idx in range(_highest_port_connected, -1, -1):
			if port_idx == 0:
				_highest_port_connected = 0 if has_any_input(0) else -1
				break
			elif not has_any_input(port_idx):
				var field_id: StringName = &"merge_" + StringName(str(port_idx))
				remove_field(field_id, 29)
			else:
				_highest_port_connected = port_idx
				break


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["port_count"] = get_child_count()
	data["output_connections"] = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)
	}
	return data


func _set_node_data(data: Dictionary) -> void:
	position_offset = data["position"]
	set_input_port_count(data["port_count"])


func set_input_port_count(new_count: int) -> void:
	new_count = maxi(new_count, 1)
	var current_count: int = get_child_count()
	if new_count == current_count:
		return
	
	if current_count < new_count:
		for missing_port in range(current_count,  (new_count - current_count) + 1):
			var field_idx: int = add_field(
				&"merge_" + StringName(str(missing_port)),
				get_new_merge_node(),
				false,
				SlotConnectionType.DIALOG)
			set_slot_custom_icon_left(missing_port, flow_icon)
			set_slot_color_left(field_idx, COLORS["dialog"])
		_highest_port_connected = new_count - 1
	else:
		for extra_ports in range(_highest_port_connected + 1, new_count, -1):
			if has_any_input(extra_ports - 1):
				disconnect_port(
						PortMode.INPUT,
						extra_ports - 1)
			
			var target_remove: StringName = &"merge_" + StringName(str(extra_ports + 1))
			remove_field(target_remove)
			
			for port_idx in range(_highest_port_connected, -1, -1):
				if port_idx == 0:
					_highest_port_connected = 0 if has_any_input(0) else -1
					break
				elif not has_any_input(port_idx):
					var field_id: StringName = &"merge_" + StringName(str(port_idx))
					remove_field(field_id, 29)
				else:
					_highest_port_connected = port_idx
					break
		_highest_port_connected = new_count if has_any_input(new_count - 1) else -1


func get_new_merge_node() -> Control:
	var new_point: Control = Control.new()
	new_point.custom_minimum_size.y = 24.0
	new_point.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return new_point
