class_name DiscourseGraphAnchorPointer
extends DiscourseGraphNode


signal go_to_anchor_pressed(node_uuid: StringName)


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
	var options: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("WARNING: Node is orphan.")
	if has_any_input(0) and options.selected == -1:
		issues.append("WARNING: Node connected but no anchor is selected.")
	return issues


func add_anchor(target_uuid: StringName, target_text: String) -> void:
	var options: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	var go_to_btn: Button = get_mapped_field(&"fields", &"button")
	var id_selected: StringName = options.get_selected_metadata() if -1 < options.selected else &""
	var existing_anchors: Dictionary[StringName, String] = {}
	
	for idx in range(options.item_count):
		existing_anchors[options.get_item_metadata(idx)] = options.get_item_text(idx)
	
	existing_anchors[target_uuid] = target_text
	
	var ids: Array[StringName] = []
	ids.assign(existing_anchors.keys())
	
	ids.sort_custom(func(a,b): return existing_anchors[a] < existing_anchors[b])
	
	options.clear()
	
	for id in ids:
		options.add_item(existing_anchors[id])
		options.set_item_metadata(-1, id)
	
	var new_idx: int = ids.find(id_selected)
	
	if new_idx == -1:
		options.select(0 if 0 < options.item_count else -1)
	else:
		options.select(new_idx)
	
	if options.disabled:
		options.disabled = false
	
	if go_to_btn.disabled:
		go_to_btn.disabled = false


func update_anchor(target_uuid: StringName, new_text: String) -> void:
	var options: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	
	for idx in range(options.item_count):
		if options.get_item_metadata(idx) != target_uuid:
			continue
		options.set_item_text(idx, new_text)
		return


func remove_anchor(target_uuid: StringName) -> bool:
	var options: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	var go_to_btn: Button = get_mapped_field(&"fields", &"button")
	
	for idx in range(options.item_count):
		if options.get_item_metadata(idx) != target_uuid:
			continue
		options.remove_item(idx)
		if options.item_count == 0:
			options.disabled = true
			go_to_btn.disabled = true
		return true
	
	return false


func _on_go_to_anchor_pressed() -> void:
	var menu: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	if menu.selected == -1:
		return
	go_to_anchor_pressed.emit(menu.get_selected_metadata())


func select_anchor(uuid: String) -> void:
	var menu: OptionButton = get_mapped_field(&"fields", &"shortcuts")
	
	for idx in range(menu.item_count):
		if menu.get_item_metadata(idx) == uuid:
			menu.select(idx)
			return
