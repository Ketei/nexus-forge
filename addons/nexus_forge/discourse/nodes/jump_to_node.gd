class_name DiscourseGraphAnchorPointer
extends DiscourseGraphNode


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
	name = &"AnchorPointer"
	custom_id = "AnchroPointer"
	title = "Go To Anchor"
	node_type = DialogueNodeType.ANCHOR_POINTER
	parent_mode = PortMode.INPUT
	parent_port = 0
	size = Vector2(260.0, 87.0)
	
	var shortcuts: OptionButton = OptionButton.new()
	shortcuts.disabled = true
	shortcuts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shortcuts.custom_minimum_size.y = 32
	
	add_field(
			&"shortcuts",
			shortcuts,
			false,
			SlotConnectionType.DIALOG)
	set_slot_custom_icon_left(0, flow_icon)
	set_slot_color_left(0, COLORS["dialog"])
	reload_anchors()


func _get_node_data() -> Dictionary:
	var menu: OptionButton = get_field(&"shortcuts")
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["anchor_target"] = menu.get_item_metadata(menu.selected) if 0 <= menu.selected else ""
	return data


func _set_node_data(data: Dictionary) -> void:
	position_offset = data["position"]
	select_anchor(data["anchor_target"])


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if has_any_input(0) and jump_targets.is_empty():
		issues.append("Warning: Node connected but no anchor is selected.")
	return issues


#func _clone() -> DiscourseGraphNode:
	#var titlebox: HBoxContainer = get_titlebar_hbox().get_child(-1)
	#var new_node: DiscourseGraphNode = get_script().new(
			#"",
			#theme_type_variation,
			#titlebox.has_node(^"DuplicateBtn"),
			#titlebox.has_node(^"CloseBtn"),
			#titlebox.has_node(^"EditIdBtn"),
			#titlebox.has_node(^"LocalizeBtn"))
	#
	#new_node._set_node_data(_get_node_data())
	#return new_node


func select_anchor(uuid: String) -> void:
	if not jump_targets.has(uuid):
		return
	
	var menu: OptionButton = get_field(&"shortcuts")
	
	for idx in range(menu.item_count):
		if menu.get_item_metadata(idx) == uuid:
			menu.select(idx)
			break


func reload_anchors() -> void:
	var menu: OptionButton = get_field(&"shortcuts")
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


func sort_custom_uuids(uuid_a: String, uuid_b: String) -> bool:
	return jump_targets[uuid_a].naturalnocasecmp_to(jump_targets[uuid_b]) < 0
