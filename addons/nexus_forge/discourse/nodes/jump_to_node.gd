extends DiscourseGraphNode


signal go_to_anchor_pressed(node_uuid: StringName)
signal selected_shortcut_changed(node_uuid: StringName, old_anchor: StringName, new_anchor: StringName)

var shortcuts: OptionButton


func _post_init() -> void:
	set_node_id(&"FlowIn")
	title = "Flow In"
	node_type = DialogueNodeType.SHORTCUT_IN
	parent_mode = PortMode.INPUT
	parent_port = 0
	size = Vector2(200.0, 87.0)
	
	var fields: HBoxContainer = HBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.custom_minimum_size.y = 32.0
	
	shortcuts = OptionButton.new()
	shortcuts.disabled = true
	shortcuts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shortcuts.custom_minimum_size.y = 32
	shortcuts.set_meta(&"old_value", &"")
	
	var go_to_btn: Button = Button.new()
	go_to_btn.custom_minimum_size = Vector2(32.0, 32.0)
	go_to_btn.disabled = true
	go_to_btn.tooltip_text = "Go to anchor"
	
	go_to_btn.pressed.connect(_on_go_to_anchor_pressed)
	shortcuts.item_selected.connect(_on_anchor_idx_selected)
	
	fields.add_child(shortcuts)
	fields.add_child(go_to_btn)
	
	add_field(
			&"fields",
			fields,
			false,
			SlotConnectionType.DIALOG)
	
	map_field(&"fields", &"button", go_to_btn)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/dialog_exit.svg")
	set_slot_custom_icon_left(0, flow_icon)
	set_slot_color_left(0, COLORS["dialog"])
	get_mapped_field(&"fields", &"button").icon = get_theme_icon("ExternalLink", "EditorIcons")


func _get_node_data() -> Dictionary:
	var metadata: Dictionary = {
		"anchor_target": shortcuts.get_selected_metadata() if 0 <= shortcuts.selected else &""}
	return _build_node_data(metadata)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("anchor_target"):
		var target_type: int = typeof(metadata["anchor_target"])
		if target_type == TYPE_STRING_NAME or target_type == TYPE_STRING:
			select_target(metadata["anchor_target"])


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("WARNING: Node is orphan.")
	if has_any_input(0) and shortcuts.selected == -1:
		issues.append("WARNING: Node connected but no anchor is selected.")
	return issues


func add_anchor(target_uuid: StringName, target_text: String) -> void:
	var go_to_btn: Button = get_mapped_field(&"fields", &"button")
	var id_selected: StringName = shortcuts.get_selected_metadata() if -1 < shortcuts.selected else &""
	var existing_anchors: Dictionary[StringName, String] = {}
	
	for idx in range(shortcuts.item_count):
		existing_anchors[shortcuts.get_item_metadata(idx)] = shortcuts.get_item_text(idx)
	
	existing_anchors[target_uuid] = target_text
	
	var ids: Array[StringName] = []
	ids.assign(existing_anchors.keys())
	
	ids.sort_custom(func(a,b): return existing_anchors[a] < existing_anchors[b])
	
	shortcuts.clear()
	
	for id in ids:
		shortcuts.add_item(existing_anchors[id])
		shortcuts.set_item_metadata(-1, id)
	
	var new_idx: int = ids.find(id_selected)
	
	if new_idx == -1:
		shortcuts.select(0)
		shortcuts.set_meta(&"old_value", shortcuts.get_item_metadata(0))
	else:
		shortcuts.select(new_idx)
		shortcuts.set_meta(&"old_value", shortcuts.get_item_metadata(new_idx))
	
	if shortcuts.disabled:
		shortcuts.disabled = false
	
	if go_to_btn.disabled:
		go_to_btn.disabled = false


func update_anchor(target_uuid: StringName, new_text: String) -> void:
	for idx in range(shortcuts.item_count):
		if shortcuts.get_item_metadata(idx) != target_uuid:
			continue
		shortcuts.set_item_text(idx, new_text)
		return


func get_selected_target_uuid() -> StringName:
	if -1 < shortcuts.selected:
		return shortcuts.get_selected_metadata()
	return &""


func remove_anchor(target_uuid: StringName) -> bool:
	var go_to_btn: Button = get_mapped_field(&"fields", &"button")
	var selected_index: int = shortcuts.selected
	
	for idx in range(shortcuts.item_count):
		if shortcuts.get_item_metadata(idx) != target_uuid:
			continue
		shortcuts.remove_item(idx)
		if shortcuts.item_count == 0:
			shortcuts.select(-1)
			shortcuts.set_meta(&"old_value", &"")
			shortcuts.disabled = true
			go_to_btn.disabled = true
		else:
			if selected_index == idx:
				var new_index: int = clampi(selected_index, 0, shortcuts.item_count - 1)
				shortcuts.select(new_index)
				shortcuts.set_meta(&"old_value", shortcuts.get_item_metadata(new_index))
		return true
	
	return false


func _on_go_to_anchor_pressed() -> void:
	if shortcuts.selected == -1:
		return
	go_to_anchor_pressed.emit(shortcuts.get_selected_metadata())


func select_target(uuid: StringName) -> void:
	for idx in range(shortcuts.item_count):
		if shortcuts.get_item_metadata(idx) == uuid:
			shortcuts.select(idx)
			shortcuts.set_meta(&"old_value", shortcuts.get_item_metadata(idx))
			return


func _on_anchor_idx_selected(idx: int) -> void:
	var old_value: StringName = shortcuts.get_meta(&"old_value", &"")
	var new_value: StringName = shortcuts.get_item_metadata(idx)
	
	if new_value == old_value:
		return
	
	shortcuts.set_meta(&"old_value", new_value)
	
	selected_shortcut_changed.emit(
			get_node_uuid(),
			old_value,
			new_value)
