extends DiscourseGraphNode


func _post_init() -> void:
	name = &"Resource"
	custom_id = "Resource"
	title = "Resource"
	node_type = DialogueNodeType.RESOURCE
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(260, 83)
	
	#var resource_container: HBoxContainer = HBoxContainer.new()
	var res_path: LineEdit = preload("res://addons/nexus_forge/discourse/res_drop_lineedit.gd").new()
	#var browse_res: Button = Button.new()
	
	#resource_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	res_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_path.placeholder_text = "Resource Path"
	res_path.custom_minimum_size.y = 32
	
	#browse_res.custom_minimum_size = Vector2(32.0, 32.0)
	#browse_res.expand_icon = true
	#browse_res.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#browse_res.flat = true
	#browse_res.icon = get_theme_icon("Folder", "EditorIcons")
	#browse_res.add_theme_constant_override(&"icon_max_width", 24)
	#browse_res.tooltip_text = "Browse for resource"
	
	#resource_container.add_child(browse_res)
	#resource_container.add_child(res_path)
	
	add_field(
		&"res_path",
		res_path,
		false,
		-1,
		SlotConnectionType.RESOURCE)


func _ready() -> void:
	graph_icon = get_theme_icon("ResourcePreloader", "EditorIcons")
	set_slot_color_right(0, COLORS["object"])
	set_output_connection_icon(&"res_path", get_theme_icon("Object", "EditorIcons"))


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["resource_path"] = get_field(&"res_path").text.strip_edges()
	data["output_connections"] = {
		"resource_target": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	return data


func _set_node_data(data: Dictionary) -> void:
	position_offset = data["position"]
	get_field(&"res_path").text = data["resource_path"]


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	var res_line: LineEdit = get_field(&"res_path")
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if not ResourceLoader.exists(res_line.text.strip_edges()):
		issues.append("Warning: Provided resource {resource} does not exist".format({"resource": get_field(&"res_path").text.strip_edges()}))
	if has_any_output(0) and res_line.text.is_empty():
		issues.append("Warning: Resource is being provided but no resource selected.")
	return issues
