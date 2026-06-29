extends DiscourseGraphNode


var _highest_port_connected: int = -1
var _connection_updates_disabled: bool = false


func _post_init() -> void:
	set_node_id(&"DialogMerge")
	title = "Dialog Merge"
	size = Vector2(200.0, 79.0)
	custom_minimum_size.y = 79.0
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
	graph_icon = preload("res://addons/nexus_forge/icons/merge_icon.svg")
	for child_idx in range(get_child_count()):
		set_slot_custom_icon_left(child_idx, flow_icon)
	set_slot_custom_icon_right(0, flow_icon)


func _on_input_connected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	if _connection_updates_disabled:
		if _highest_port_connected < input_port:
			_highest_port_connected = input_port
		return
	
	if input_port < _highest_port_connected:
		return
	
	_highest_port_connected = input_port
	var field_idx: int = add_field(
			&"merge_" + StringName(str(_highest_port_connected + 1)),
			get_new_merge_node(),
			false,
			SlotConnectionType.DIALOG)
	set_slot_custom_icon_left(field_idx, flow_icon)
	set_slot_color_left(field_idx, COLORS["dialog"])


func _on_input_disconnected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	if _connection_updates_disabled:
		return
	
	if input_port != _highest_port_connected:
		return
	
	remove_unused_fields()
	
	if _highest_port_connected == 0 and not has_any_input(0):
		_highest_port_connected = -1
	
	update_size.call_deferred()


func remove_unused_fields() -> void:
	var target_fields: Array[StringName] = []
	for port in range(get_child_count() - 1, 0, -1):
		if has_any_input(port - 1):
			break
		var id: StringName = StringName("merge_" + str(port))
		target_fields.append(id)
		_highest_port_connected -= 1
	
	remove_fields(target_fields, -1)
	
	update_size.call_deferred()


func update_size() -> void:
	size.y = 0


func _get_node_data() -> Dictionary:
	var metadata: Dictionary = {
		"port_count": get_child_count()}
	var output_connections: Dictionary = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	
	return _build_node_data(metadata, output_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("port_count") and typeof(metadata["port_count"]) == TYPE_INT:
		set_input_port_count(metadata["port_count"])


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
					_highest_port_connected = port_idx - 1
					break


func get_new_merge_node() -> Control:
	var new_point: Control = Control.new()
	new_point.custom_minimum_size.y = 24.0
	new_point.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return new_point
