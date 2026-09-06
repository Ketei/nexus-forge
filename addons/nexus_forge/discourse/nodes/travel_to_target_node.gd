@tool
extends DiscourseGraphNode


signal go_to_waypoint_pressed(node_uuid: StringName)
signal selected_waypoint_changed(node_uuid: StringName, old_waypoint: StringName, new_waypoint: StringName)

var _waypoints: OptionButton


func _post_init() -> void:
	set_node_id(&"TravelTo")
	title = "Travel To"
	node_type = DialogueNodeType.TRAVEL_TO
	parent_mode = PortMode.INPUT
	parent_port = 0
	size = Vector2(200.0, 87.0)
	
	var fields: HBoxContainer = HBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.custom_minimum_size.y = 32.0
	
	_waypoints = OptionButton.new()
	_waypoints.disabled = true
	_waypoints.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_waypoints.custom_minimum_size.y = 32
	_waypoints.set_meta(&"old_value", &"")
	
	var go_to_btn: Button = Button.new()
	go_to_btn.custom_minimum_size = Vector2(32.0, 32.0)
	go_to_btn.disabled = true
	go_to_btn.tooltip_text = "Go to waypoint"
	
	go_to_btn.pressed.connect(_on_go_to_anchor_pressed)
	_waypoints.item_selected.connect(_on_anchor_idx_selected)
	
	fields.add_child(_waypoints)
	fields.add_child(go_to_btn)
	
	add_field(
			&"fields",
			fields,
			false,
			SlotConnectionType.DIALOG,
			SlotConnectionType.DIALOG)
	
	map_field(&"fields", &"button", go_to_btn)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/travel_to_waypoint.svg")
	set_slot_custom_icon_left(0, flow_icon)
	set_slot_color_left(0, COLORS["dialog"])
	set_slot_custom_icon_right(0, flow_icon)
	set_slot_color_right(0, COLORS["dialog"])
	get_mapped_field(&"fields", &"button").icon = get_theme_icon("ExternalLink", "EditorIcons")


func _get_node_data() -> Dictionary:
	var output_connections: Dictionary = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	var metadata: Dictionary = {
		"travel_target": _waypoints.get_selected_metadata() if 0 <= _waypoints.selected else &""}
	return _build_node_data(metadata, output_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("travel_target"):
		var waypoint_type: int = typeof(metadata["travel_target"])
		if waypoint_type == TYPE_STRING_NAME or waypoint_type == TYPE_STRING:
			select_waypoint(metadata["travel_target"])


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("WARNING: Node is orphan.")
	if has_any_input(0) and _waypoints.selected == -1:
		issues.append("WARNING: Node connected but no waypoint is selected.")
	
	return issues


func add_waypoint(target_uuid: StringName, waypoint_id: String) -> void:
	var go_to_btn: Button = get_mapped_field(&"fields", &"button")
	var id_selected: StringName = _waypoints.get_selected_metadata() if -1 < _waypoints.selected else &""
	var existing_waypoints: Dictionary[StringName, String] = {}
	
	for idx in range(_waypoints.item_count):
		existing_waypoints[_waypoints.get_item_metadata(idx)] = _waypoints.get_item_text(idx)
	
	existing_waypoints[target_uuid] = waypoint_id
	
	var ids: Array[StringName] = []
	ids.assign(existing_waypoints.keys())
	
	ids.sort_custom(func(a,b): return existing_waypoints[a] < existing_waypoints[b])
	
	_waypoints.clear()
	
	for id in ids:
		_waypoints.add_item(existing_waypoints[id])
		_waypoints.set_item_metadata(-1, id)
	
	var new_idx: int = ids.find(id_selected)
	
	if new_idx == -1:
		_waypoints.select(0)
		_waypoints.set_meta(&"old_value", _waypoints.get_item_metadata(0))
	else:
		_waypoints.select(new_idx)
		_waypoints.set_meta(&"old_value", _waypoints.get_item_metadata(new_idx))
	
	if _waypoints.disabled:
		_waypoints.disabled = false
	
	if go_to_btn.disabled:
		go_to_btn.disabled = false


func update_waypoint_id(target_uuid: StringName, new_text: String) -> void:
	for idx in range(_waypoints.item_count):
		if _waypoints.get_item_metadata(idx) != target_uuid:
			continue
		_waypoints.set_item_text(idx, new_text)
		return


func get_selected_waypoint_uuid() -> StringName:
	if -1 < _waypoints.selected:
		return _waypoints.get_selected_metadata()
	return &""


func remove_waypoint(target_uuid: StringName) -> bool:
	var go_to_btn: Button = get_mapped_field(&"fields", &"button")
	var selected_index: int = _waypoints.selected
	
	for idx in range(_waypoints.item_count):
		if _waypoints.get_item_metadata(idx) != target_uuid:
			continue
		_waypoints.remove_item(idx)
		if _waypoints.item_count == 0:
			_waypoints.select(-1)
			_waypoints.set_meta(&"old_value", &"")
			_waypoints.disabled = true
			go_to_btn.disabled = true
		else:
			if selected_index == idx:
				var new_index: int = clampi(selected_index, 0, _waypoints.item_count - 1)
				_waypoints.select(new_index)
				_waypoints.set_meta(&"old_value", _waypoints.get_item_metadata(new_index))
		return true
	
	return false


func _on_go_to_anchor_pressed() -> void:
	if _waypoints.selected == -1:
		return
	go_to_waypoint_pressed.emit(_waypoints.get_selected_metadata())


func select_waypoint(uuid: StringName) -> void:
	for idx in range(_waypoints.item_count):
		if _waypoints.get_item_metadata(idx) == uuid:
			_waypoints.select(idx)
			_waypoints.set_meta(&"old_value", _waypoints.get_item_metadata(idx))
			return


func _on_anchor_idx_selected(idx: int) -> void:
	var old_value: StringName = _waypoints.get_meta(&"old_value", &"")
	var new_value: StringName = _waypoints.get_item_metadata(idx)
	
	if new_value == old_value:
		return
	
	_waypoints.set_meta(&"old_value", new_value)
	
	selected_waypoint_changed.emit(
			get_node_uuid(),
			old_value,
			new_value)
