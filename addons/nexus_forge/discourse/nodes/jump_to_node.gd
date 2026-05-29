class_name DiscourseGraphAnchorPointer
extends DiscourseGraphNode


signal go_to_anchor_pressed(node_uuid: StringName)
# UUID, ID
static var jump_targets: Dictionary[StringName, String] = {}


static func add_anchor(target_uuid: StringName, target_text: String) -> void:
	jump_targets[target_uuid] = target_text


static func update_anchor(target_uuid: StringName, new_text: String) -> void:
	if jump_targets.has(target_uuid):
		jump_targets[target_uuid] = new_text


static func remove_anchor(target_uuid: StringName) -> bool:
	return jump_targets.erase(target_uuid)


static func get_available_id(desired_id: String) -> String:
	var tweaked_id: String = desired_id
	var used_ids: Array = jump_targets.values()
	var iteration: int = 0
	
	while tweaked_id in used_ids:
		iteration += 1
		tweaked_id = desired_id + "_" + str(iteration)
	
	return tweaked_id


func _post_init() -> void:
	set_node_id(&"AnchorPointer")
	title = "Go To"
	node_type = DialogueNodeType.ANCHOR_POINTER
	parent_mode = PortMode.INPUT
	parent_port = 0
	size = Vector2(200.0, 87.0)
	
	var fields: HBoxContainer = HBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.custom_minimum_size.y = 32.0
	
	var shortcuts: OptionButton = OptionButton.new()
	shortcuts.disabled = true
	shortcuts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shortcuts.custom_minimum_size.y = 32
	
	var go_to_btn: Button = Button.new()
	go_to_btn.custom_minimum_size = Vector2(32.0, 32.0)
	go_to_btn.disabled = true
	go_to_btn.tooltip_text = "Go to anchor"
	
	go_to_btn.pressed.connect(_on_go_to_anchor_pressed)
	
	fields.add_child(shortcuts)
	fields.add_child(go_to_btn)
	
	add_field(
			&"fields",
			fields,
			false,
			SlotConnectionType.DIALOG)
	
	map_field(&"fields", &"shortcuts", shortcuts)
	map_field(&"fields", &"button", go_to_btn)
	reload_anchors()


func _ready() -> void:
	var menu: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	graph_icon = preload("res://addons/nexus_forge/icons/dialog_exit.svg")
	set_slot_custom_icon_left(0, flow_icon)
	set_slot_color_left(0, COLORS["dialog"])
	get_mapped_field(&"fields", &"button").icon = get_theme_icon("ExternalLink", "EditorIcons")


func _get_node_data() -> Dictionary:
	var menu: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	
	var metadata: Dictionary = {
		"anchor_target": menu.get_selected_metadata() if 0 <= menu.selected else ""}
	return _build_node_data(metadata)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("anchor_target") and typeof(metadata["anchor_target"]) == TYPE_STRING:
		select_anchor(metadata["anchor_target"])


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if has_any_input(0) and jump_targets.is_empty():
		issues.append("Warning: Node connected but no anchor is selected.")
	return issues


func _on_go_to_anchor_pressed() -> void:
	var menu: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	if menu.selected == -1:
		return
	go_to_anchor_pressed.emit(menu.get_selected_metadata())


func select_anchor(uuid: String) -> void:
	if not jump_targets.has(uuid):
		return
	
	var menu: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	
	for idx in range(menu.item_count):
		if menu.get_item_metadata(idx) == uuid:
			menu.select(idx)
			break


func reload_anchors() -> void:
	var menu: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	var go_to_btn: Button = get_mapped_field(&"fields", &"button")
	var current_uuid: String = menu.get_item_metadata(menu.selected) if 0 <= menu.selected else ""
	
	menu.clear()
	
	var index: int = -1
	var target_uuids: Array = jump_targets.keys()
	target_uuids.sort_custom(sort_custom_uuids)
	
	for uuid in target_uuids:
		index += 1
		menu.add_item(jump_targets[uuid])
		menu.set_item_metadata(index, uuid)
		if uuid == current_uuid:
			menu.select(index)
	
	menu.disabled = menu.item_count == 0
	go_to_btn.disabled = menu.disabled


func sort_custom_uuids(uuid_a: String, uuid_b: String) -> bool:
	return jump_targets[uuid_a].naturalnocasecmp_to(jump_targets[uuid_b]) < 0
