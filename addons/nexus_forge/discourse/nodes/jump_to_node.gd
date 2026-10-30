@tool
extends DiscourseGraphNode


signal go_to_anchor_pressed(node_uuid: String)
signal selected_shortcut_changed(node_uuid: String, old_anchor: String, new_anchor: String)

var shortcuts: OptionButton
var go_to_btn: Button


func _post_init() -> void:
	set_node_id("FlowIn")
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
	shortcuts.set_meta(&"old_value", "")
	
	go_to_btn = Button.new()
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


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/dialog_exit.svg")
	set_slot_custom_icon_left(0, flow_icon)
	set_slot_color_left(0, COLORS["dialog"])
	go_to_btn.icon = get_theme_icon("ExternalLink", "EditorIcons")


func _get_node_data() -> Dictionary:
	var metadata: Dictionary = {
		"anchor_target": shortcuts.get_selected_metadata() if 0 <= shortcuts.selected else ""}
	return _build_node_data(metadata)


func _set_node_data(data: Dictionary) -> void:
	super(data)
	var target_data: Variant = data.get("metadata", NFDictUtils.EMPTY_DICT).get("anchor_target")
	var target_type: int = typeof(target_data)
	if target_type == TYPE_STRING or target_type == TYPE_STRING_NAME:
		select_target(target_data)


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("WARNING: Node is orphan.")
	if has_any_input(0) and shortcuts.selected == -1:
		issues.append("WARNING: Node connected but no anchor is selected.")
	return issues


func add_anchor(target_uuid: String, target_text: String) -> void:
	var id_selected: String = shortcuts.get_selected_metadata() if -1 < shortcuts.selected else ""
	var existing_anchors: Dictionary[String, String] = {}
	
	for idx in range(shortcuts.item_count):
		existing_anchors[shortcuts.get_item_metadata(idx)] = shortcuts.get_item_text(idx)
	
	existing_anchors[target_uuid] = target_text
	
	var ids: Array[String] = []
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


func update_anchor(target_uuid: String, new_text: String) -> void:
	for idx in range(shortcuts.item_count):
		if shortcuts.get_item_metadata(idx) != target_uuid:
			continue
		shortcuts.set_item_text(idx, new_text)
		return


func get_selected_target_uuid() -> String:
	if -1 < shortcuts.selected:
		return shortcuts.get_selected_metadata()
	return ""


func remove_anchor(target_uuid: String) -> bool:
	var selected_index: int = shortcuts.selected
	
	for idx in range(shortcuts.item_count):
		if shortcuts.get_item_metadata(idx) != target_uuid:
			continue
		shortcuts.remove_item(idx)
		if shortcuts.item_count == 0:
			shortcuts.select(-1)
			shortcuts.set_meta(&"old_value", "")
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


func select_target(uuid: String) -> void:
	for idx in range(shortcuts.item_count):
		if shortcuts.get_item_metadata(idx) == uuid:
			shortcuts.select(idx)
			shortcuts.set_meta(&"old_value", shortcuts.get_item_metadata(idx))
			return


func _on_anchor_idx_selected(idx: int) -> void:
	var old_value: String = shortcuts.get_meta(&"old_value", "")
	var new_value: String = shortcuts.get_item_metadata(idx)
	
	if new_value == old_value:
		return
	
	shortcuts.set_meta(&"old_value", new_value)
	
	selected_shortcut_changed.emit(
			get_node_uuid(),
			old_value,
			new_value)
