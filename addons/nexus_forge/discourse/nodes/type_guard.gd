@tool
extends DiscourseGraphNode


signal fallback_changed(uuid: StringName, from: Variant, to: Variant)

var filter_mode: int = TYPE_NIL
var str_fallback: LineEdit
var bool_fallback: CheckButton
var val_fallback: SpinBox
var spinbox_container: HBoxContainer


func _post_init() -> void:
	set_node_id(&"TypeGuard")
	title = "Type Guard"
	node_type = DialogueNodeType.TYPE_GUARD
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(220.0, 120.0)
	
	var connection_label: Label = Label.new()
	var fallback_panel: PanelContainer = PanelContainer.new()
	spinbox_container = HBoxContainer.new()
	var spnbx_label: Label = Label.new()
	val_fallback = SpinBox.new()
	bool_fallback = CheckButton.new()
	str_fallback = LineEdit.new()
	var awaiting_label: Label = Label.new()
	
	awaiting_label.text = "- Fallback -"
	awaiting_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	awaiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	connection_label.text = "Input Output"
	connection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	connection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	fallback_panel.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	fallback_panel.custom_minimum_size.y = 32.0
	fallback_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	spinbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	spnbx_label.text = "Fallback"
	spnbx_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	val_fallback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_fallback.allow_greater = true
	val_fallback.allow_lesser = true
	val_fallback.set_meta(&"old_value", 0.0)
	val_fallback.value_changed.connect(_on_value_fallback_value_changed)
	
	bool_fallback.text = "Is True"
	bool_fallback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bool_fallback.toggled.connect(_on_bool_fallback_toggled)
	
	str_fallback.placeholder_text = "Fallback"
	str_fallback.text_changed.connect(node_updated.emit)
	str_fallback.editing_toggled.connect(_on_text_fallback_edit_toggled)
	str_fallback.set_meta(&"old_value", "")
	
	spinbox_container.visible = false
	bool_fallback.visible = false
	str_fallback.visible = false
	
	spinbox_container.add_child(spnbx_label)
	spinbox_container.add_child(val_fallback)
	
	fallback_panel.add_child(spinbox_container)
	fallback_panel.add_child(bool_fallback)
	fallback_panel.add_child(str_fallback)
	fallback_panel.add_child(awaiting_label)
	
	add_field(
			&"connection",
			connection_label,
			false,
			SlotConnectionType.VAR_ANY,
			SlotConnectionType.VAR_GUARD)
	set_slot_color_left(0, COLORS["any"])
	set_slot_color_right(0, COLORS["any"])
	add_field(&"fallback", fallback_panel)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/shield_icon.svg")
	set_field_connection_icons(
			&"connection",
			get_theme_icon("Variant", "EditorIcons"),
			get_theme_icon("Variant", "EditorIcons"))


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	return issues


func _get_node_data() -> Dictionary:
	var input_connections: Dictionary = {
		"value": get_uuid_and_port_connected_to(PortMode.INPUT, 0)}
	var output_connections: Dictionary = {
		"output": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	var metadata: Dictionary = {"fallback_value": get_active_data_type()}
	
	return _build_node_data(metadata, output_connections, input_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("fallback_value"):
		match typeof(metadata["fallback_value"]):
			TYPE_INT, TYPE_FLOAT:
				val_fallback.set_value_no_signal(metadata["fallback_value"])
			TYPE_BOOL:
				bool_fallback.set_pressed_no_signal(metadata["fallback_value"])
			TYPE_STRING:
				str_fallback.text = metadata["fallback_value"]
			_:
				return


func _on_output_connected(output: int, to_node: DiscourseGraphNode, _to_port: int) -> void:
	var fallback_panel: PanelContainer = get_field(&"fallback")
	var type: int = to_node.get_input_port_type(
			to_node.get_port_connected_to(PortMode.INPUT, self, output))
	
	for child in fallback_panel.get_children():
		child.visible = false
	
	match type:
		SlotConnectionType.VAR_INT:
			set_slot_type_right(0, SlotConnectionType.VAR_INT)
			set_slot_color_right(0, COLORS["integer"])
			set_output_connection_icon(&"connection", get_theme_icon("int", "EditorIcons"))
			spinbox_container.visible = true
			val_fallback.step = 1.0
			filter_mode = TYPE_INT
		SlotConnectionType.VAR_FLOAT:
			set_slot_type_right(0, SlotConnectionType.VAR_FLOAT)
			set_slot_color_right(0, COLORS["float"])
			set_output_connection_icon(&"connection", get_theme_icon("float", "EditorIcons"))
			val_fallback.visible = true
			val_fallback.step = 0.01
			filter_mode = TYPE_FLOAT
		SlotConnectionType.VAR_BOOL:
			set_slot_type_right(0, SlotConnectionType.VAR_BOOL)
			bool_fallback.visible = true
			set_slot_color_right(0, COLORS["bool"])
			set_output_connection_icon(&"connection", get_theme_icon("bool", "EditorIcons"))
			filter_mode = TYPE_BOOL
		SlotConnectionType.VAR_STRING:
			set_slot_type_right(0, SlotConnectionType.VAR_STRING)
			str_fallback.visible = true
			set_slot_color_right(0, COLORS["string"])
			set_output_connection_icon(&"connection", get_theme_icon("String", "EditorIcons"))
			filter_mode = TYPE_STRING


func _on_output_disconnected(_output: int, _to_node: DiscourseGraphNode, _to_port: int) -> void:
	var fallback: Control = get_field(&"fallback")
	for child in fallback.get_children():
		child.visible = false
	fallback.get_child(3).visible = true
	set_slot_type_right(0, SlotConnectionType.VAR_GUARD)
	set_slot_color_right(0, COLORS["any"])
	
	set_output_connection_icon(&"connection", get_theme_icon("Variant", "EditorIcons"))
	filter_mode = TYPE_NIL


func set_fallback_value(value: Variant) -> void:
	var val_type: int = typeof(value)
	
	match val_type:
		TYPE_INT, TYPE_FLOAT:
			val_fallback.set_value_no_signal(value)
			val_fallback.set_meta(&"old_value", val_fallback.value)
		TYPE_BOOL:
			bool_fallback.set_pressed_no_signal(value)
		TYPE_STRING:
			str_fallback.text = value
			str_fallback.set_meta(&"old_value", value)


func _on_text_fallback_edit_toggled(is_toggled: bool) -> void:
	if is_toggled or filter_mode != TYPE_STRING:
		return
	
	var new_value: String = str_fallback.text
	var old_value: String = str_fallback.get_meta(&"old_value")
	
	if new_value == old_value:
		return
	
	str_fallback.set_meta(&"old_value", new_value)
	
	fallback_changed.emit(
			get_node_uuid(),
			old_value,
			new_value)


func _on_value_fallback_value_changed(value: float) -> void:
	if filter_mode != TYPE_INT and filter_mode != TYPE_FLOAT:
		return
	var old_value: float = val_fallback.get_meta(&"old_value")
	
	if value == old_value:
		return
	
	val_fallback.set_meta(&"old_value", value)
	fallback_changed.emit(
		get_node_uuid(),
		old_value,
		value)


func _on_bool_fallback_toggled(is_toggled: bool) -> void:
	if filter_mode != TYPE_BOOL:
		return
	fallback_changed.emit(
		get_node_uuid(),
		not is_toggled,
		is_toggled)


func get_active_data_type() -> Variant:
	var fallback_panel: PanelContainer = get_field(&"fallback")
	match filter_mode:
		TYPE_INT:
			return int(val_fallback.value)
		TYPE_FLOAT:
			return val_fallback.value
		TYPE_STRING:
			return str_fallback.text
		TYPE_BOOL:
			return bool_fallback.button_pressed
		_:
			return null
