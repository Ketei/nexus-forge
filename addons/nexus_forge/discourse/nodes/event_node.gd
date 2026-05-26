extends DiscourseGraphNode


func _post_init() -> void:
	set_node_id(&"DialogEvent")
	title = "Event"
	size = Vector2(240.0, 196.0)
	node_type = DialogueNodeType.EVENT
	parent_mode = PortMode.INPUT
	parent_port = 0
	
	var connection_ctrn: Control = Control.new()
	var call_label: Label = Label.new()
	var var_label: Label = Label.new()
	var signal_label: Label = Label.new()
	var variable_path: LineEdit = LineEdit.new()
	var var_panel: PanelContainer = PanelContainer.new()
	
	var_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var_panel.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	
	variable_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	variable_path.custom_minimum_size.y = 32
	variable_path.visible = false
	variable_path.placeholder_text = "Variable Path"
	
	var_panel.add_child(var_label)
	var_panel.add_child(variable_path)
	
	connection_ctrn.custom_minimum_size.y = 32
	connection_ctrn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	call_label.text = "Call method"
	call_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	call_label.custom_minimum_size.y = 32
	var_label.text = "Set variable"
	var_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var_label.custom_minimum_size.y = 32
	signal_label.text = "Emit signal"
	signal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	signal_label.custom_minimum_size.y = 32
	
	add_field(
			&"connection",
			connection_ctrn,
			false,
			SlotConnectionType.DIALOG,
			SlotConnectionType.DIALOG)
	
	add_field(
			&"variable",
			var_panel,
			false,
			SlotConnectionType.VAR_ANY,
			-1)
	map_field(&"variable", &"path", variable_path)
	
	add_field(
			&"callable",
			call_label,
			false,
			SlotConnectionType.CALL,
			-1)
	
	add_field(
			&"signal",
			signal_label,
			false,
			SlotConnectionType.SIGNAL,
			-1)
	
	
	variable_path.text_changed.connect(node_updated.emit)
	variable_path.focus_exited.connect(_on_var_path_focus_lost)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/bulb_icon.svg")
	set_input_connection_icon(&"variable", get_theme_icon("Variant", "EditorIcons"))
	set_input_connection_icon(&"callable", get_theme_icon("Callable", "EditorIcons"))
	set_input_connection_icon(&"signal", get_theme_icon("Signals", "EditorIcons"))
	set_slot_color_left(0, COLORS["dialog"])
	set_slot_color_right(0, COLORS["dialog"])
	set_slot_color_left(1, COLORS["any"])
	set_slot_color_left(2, COLORS["method"])
	set_slot_color_left(3, COLORS["signal"])
	
	set_slot_custom_icon_left(0, flow_icon)
	set_slot_custom_icon_right(0, flow_icon)


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if has_any_input(1) and get_mapped_field(&"variable", &"path").text.strip_edges().is_empty():
		issues.append("Error: Variable is being set but no path provided.")
	return issues


func _on_input_connected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	if input_port == 1:
		var set_var: PanelContainer = get_field(&"variable")
		set_var.get_child(0).visible = false
		set_var.get_child(1).visible = true


func _on_input_disconnected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	if input_port == 1:
		var set_var: PanelContainer = get_field(&"variable")
		set_var.get_child(0).visible = true
		set_var.get_child(1).visible = false


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	
	var metadata: Dictionary = {
		"variable_path": get_mapped_field(&"variable", &"path").text.strip_edges()}
	var output_connections: Dictionary = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	var input_connections: Dictionary = {
		"variable_value": get_uuid_and_port_connected_to(PortMode.INPUT, 1),
		"callable": get_uuid_and_port_connected_to(PortMode.INPUT, 2),
		"signal": get_uuid_and_port_connected_to(PortMode.INPUT, 3)}
	
	return _build_node_data(metadata, output_connections, input_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("variable_path") and typeof(metadata["variable_path"]) == TYPE_STRING:
		get_mapped_field(&"variable", &"path").text = metadata["variable_path"]


func _on_var_path_focus_lost() -> void:
	var var_path: LineEdit = get_mapped_field(&"variable", &"path")
	var_path.tooltip_text = var_path.text.strip_edges()
