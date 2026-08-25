extends DiscourseGraphNode


signal metadata_id_changed(index: int, from: String, to: String)


var meta_fields: int = 0
var _connection_updates_disabled: bool = false


func _post_init() -> void:
	set_node_id(&"Metadata")
	title = "Metadata"
	size = Vector2(250.0, 121.0)
	custom_minimum_size.y = 121.0
	graph_icon = preload("res://addons/nexus_forge/icons/metadata_icon.svg")
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	node_type = DialogueNodeType.METADATA
	
	var connection_node: Control = Control.new()
	connection_node.custom_minimum_size.y = 32
	connection_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_field(&"metadata_connection", connection_node, false, -1, SlotConnectionType.METADATA)
	add_metadata_port()


func _ready() -> void:
	set_slot_color_right(0, COLORS["metadata"])
	set_output_connection_icon(&"metadata_connection", load("res://addons/nexus_forge/icons/metadata_icon.svg"))
	set_slot_color_left(1, COLORS["any"])
	for port_idx in range(get_child_count() - 1):
		var id: StringName = StringName("metadata_" + str(port_idx))
		set_input_connection_icon(id, get_theme_icon("Variant", "EditorIcons"))


func _on_input_connected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	if _connection_updates_disabled:
		return
	
	var on_last: bool = input_port == get_child_count() - 2
	var id: StringName = StringName("metadata_" + str(input_port))
	var port_field: PanelContainer = get_field(id)
	var metadata_id: LineEdit = port_field.get_child(0)
	var valid_id: String = get_valid_metadata_id(metadata_id.text.strip_edges(), metadata_id)
	
	metadata_id.text = valid_id
	metadata_id.set_meta(&"old_value", valid_id)
	metadata_id.visible = true
	
	if on_last:
		add_metadata_port()


func _on_input_disconnected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	if _connection_updates_disabled:
		return
	
	if input_port == get_child_count() - 3:
		remove_unused_fields.call_deferred()


func remove_unused_fields() -> void:
	var last_port: int = -1
	var target_fields: Array[StringName] = []
	for port in range(get_child_count() - 2, 0, -1):
		if has_any_input(port - 1):
			last_port = port + 1
			break
		var id: StringName = StringName("metadata_" + str(port))
		var line: LineEdit = get_field(id).get_child(0)
		line.editing_toggled.disconnect(_on_metadata_line_edit_toggled)
		target_fields.append(id)
		meta_fields -= 1
	
	var last: Control = get_child(-1).get_child(1)
	if last != null:
		last.get_child(0).visible = false
	
	remove_fields(target_fields, -1)
	
	var line: LineEdit = get_index_field(-1).get_child(0)
	if line == null:
		NFPluginGameHandler._log_msg(
			"discourse - editor",
			"Couldn't find metadata last item.",
			NFPluginGameHandler._LogLevel.WARNING)
		return
	
	line.visible = false
	
	update_size.call_deferred()


func update_size() -> void:
	size.y = 0


func _get_node_data() -> Dictionary:
	var metadata_connections: Array[Dictionary] = []
	
	var metadata: Dictionary = {"metadata_connections": metadata_connections}
	var input_connections: Dictionary = {}
	var output_connections: Dictionary = {
		"metadata_target": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	
	if 0 < get_metadata_count():
		for port_index in range(get_metadata_count()):
			if not has_any_input(port_index):
				continue
			
			var field_id: StringName = StringName("metadata_" + str(port_index))
			var field: Control = get_field(field_id)
			
			if field == null:
				continue
			
			var metadata_id: String = field.get_child(0).text
			if has_any_input(port_index):
				input_connections[metadata_id] = get_uuid_and_port_connected_to(PortMode.INPUT, port_index)
			metadata_connections.append({
				"id": metadata_id,
				"port": port_index})
	
	return _build_node_data(metadata, output_connections, input_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
		
	if not metadata.has("metadata_connections"):
		return
	
	var metadata_size: int = metadata["metadata_connections"].size()
	var current_meta_size: int = get_child_count() - 2
	
	if current_meta_size < metadata_size:
		for _a in range(metadata_size - current_meta_size):
			add_metadata_port()
	elif metadata_size < current_meta_size:
		var fields_to_remove: Array[StringName] = []
		for port in range(current_meta_size, metadata_size, -1):
			fields_to_remove.append(StringName("metadata_" + str(port)))
		remove_fields(fields_to_remove, -1)
		update_size.call_deferred()
	
	for metadata_data:Dictionary in metadata["metadata_connections"]:
		var field_id: StringName = StringName("metadata_" + str(metadata_data["port"]))
		var field: Control = get_field(field_id)
		if field == null:
			continue
		var line: LineEdit = field.get_child(0)
		line.visible = true
		line.text = metadata_data["id"]


func _on_metadata_line_edit_toggled(is_toggled: bool, edited: LineEdit) -> void:
	if is_toggled:
		return
	
	var input_value = edited.text.strip_edges()
	var new_value: String = get_valid_metadata_id(input_value, edited)
	var old_value: String = edited.get_meta(&"old_value")
	edited.text = new_value
	
	if new_value == old_value:
		return
	
	var metadata_index: int = edited.get_parent().get_index()
	edited.set_meta(&"old_value", new_value)
	
	metadata_id_changed.emit(
			get_node_uuid(),
			metadata_index,
			old_value,
			new_value)


func get_valid_metadata_id(desired: String, skip: LineEdit = null) -> String:
	var used_ids: Dictionary[String, Variant] = {}
	
	for meta_field in range(1, get_metadata_count() + 1):
		var line: LineEdit = get_index_field(meta_field).get_child(0)
		if not line.visible or line == skip:
			continue
		used_ids[line.text] = null
	var valid_id: String = desired
	
	if used_ids.has(desired):
		var base: String = desired
		var modified: String = desired
		var trailing_data: Dictionary = StringUtils.get_trailing_integer(desired)
		var iteration: int = trailing_data["integer"]
		if trailing_data["has_integer"]:
			base = base.trim_suffix(str(iteration))
		
		while used_ids.has(modified):
			iteration += 1
			modified = base + str(iteration)
		valid_id = modified
	
	return valid_id


func _on_metadata_id_text_changed(_text: String) -> void:
	node_updated.emit()


func get_metadata_port_of(metadata_id: String) -> int:
	var meta_count: int = get_metadata_count()
	
	if meta_count <= 0:
		return -1
	
	for meta_field in range(1, meta_count):
		var field: Control = get_index_field(meta_field)
		if field == null:
			continue
		var line: LineEdit = field.get_child(0)
		if line.text == metadata_id:
			return meta_field - 1
	
	return -1


func add_metadata_port() -> void:
	var new_port: PanelContainer = PanelContainer.new()
	var metadata_line: LineEdit = LineEdit.new()
	var field_id: StringName = get_next_port_id()
	
	new_port.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	new_port.custom_minimum_size.y = 32
	new_port.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	metadata_line.text = "metadata"
	metadata_line.set_meta(&"old_value", "metadata")
	metadata_line.visible = false
	
	new_port.add_child(metadata_line)
	
	metadata_line.editing_toggled.connect(_on_metadata_line_edit_toggled.bind(metadata_line))
	metadata_line.text_changed.connect(_on_metadata_id_text_changed)
	
	var slot_idx: int = add_field(field_id, new_port, false, SlotConnectionType.VAR_ANY)
	set_slot_color_left(slot_idx, COLORS["any"])
	set_input_connection_icon(field_id, get_theme_icon("Variant", "EditorIcons"))
	
	meta_fields += 1


func get_metadata_count() -> int:
	return get_child_count() - 2


func get_next_port_id() -> StringName:
	var id: int = get_child_count() - 1
	var new_name: String = "metadata_" + str(id)
	return StringName(new_name)


func get_metadata_id(index: int) -> String:
	var id: StringName = StringName("metadata_" + str(index))
	var meta_entry: LineEdit = get_field(id)
	if meta_entry != null:
		return meta_entry.text
	return ""


func set_metadata_id(metadata_index: int, id: String) -> void:
	var meta_entry: LineEdit = get_index_field(metadata_index + 1)
	if meta_entry != null:
		meta_entry.text = id
		meta_entry.set_meta(&"old_value", id)
