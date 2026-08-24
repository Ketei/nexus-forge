extends DiscourseGraphNode


signal mode_changed(uuid: StringName, from: float, to: float)
signal range_changed(uuid: StringName, from_min: float, from_max: float, to_min: float, to_max: float)

# Modes can only be int, float & bool
var current_mode: int = TYPE_INT
var min_spinbox: SpinBox
var max_spinbox: SpinBox
var min_label: Label
var menu: MenuButton


func _post_init() -> void:
	set_node_id(&"RandomValue")
	title = "Random Value"
	node_type = DialogueNodeType.RANDOM_VALUE
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(240.0, 165.0)
	var header_container: HBoxContainer = HBoxContainer.new()
	menu = MenuButton.new()
	var random_popup: PopupMenu = menu.get_popup()
	var header_label: Label = Label.new()
	var min_container: HBoxContainer = HBoxContainer.new()
	var max_container: HBoxContainer = HBoxContainer.new()
	min_label = Label.new()
	var max_label: Label = Label.new()
	min_spinbox = SpinBox.new()
	max_spinbox = SpinBox.new()
	
	header_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	min_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	max_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	min_container.custom_minimum_size.y = 32.0
	max_container.custom_minimum_size.y = 32.0
	
	header_label.text = "Random Value"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	menu.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.custom_minimum_size = Vector2(32.0, 32.0)
	menu.set_meta(&"old_value", current_mode)
	
	min_label.text = "Min"
	min_label.custom_minimum_size.x = 35.0
	min_spinbox.custom_minimum_size = Vector2(90.0, 32.0)
	min_spinbox.min_value = 0.0
	min_spinbox.max_value = 100.0
	min_spinbox.allow_lesser = true
	min_spinbox.allow_greater = true
	min_spinbox.set_meta(&"old_value", 0.0)
	
	max_label.text = "Max"
	max_label.custom_minimum_size.x = 35.0
	max_spinbox.custom_minimum_size = Vector2(90.0, 32.0)
	max_spinbox.allow_greater = true
	max_spinbox.set_meta(&"old_value", 0.0)
	
	header_container.add_child(header_label)
	header_container.add_child(menu)
	
	min_container.add_child(min_label)
	min_container.add_child(min_spinbox)
	
	max_container.add_child(max_label)
	max_container.add_child(max_spinbox)
	
	add_field(
			&"random_type",
			header_container,
			false,
			-1,
			SlotConnectionType.VAR_INT)
	set_slot_color_right(0, COLORS["integer"])
	
	add_field(
			&"min_value",
			min_container,
			false,
			SlotConnectionType.VAR_INT,
			-1)
	set_slot_color_left(1, COLORS["integer"])
	
	add_field(
			&"max_value",
			max_container,
			false,
			SlotConnectionType.VAR_INT,
			-1)
	set_slot_color_left(2, COLORS["integer"])
	map_field(&"max_value", &"max_spinbox", max_spinbox)
	
	min_spinbox.value_changed.connect(_on_min_value_changed)
	max_spinbox.value_changed.connect(_on_max_value_changed)
	random_popup.id_pressed.connect(_on_random_type_selected)


func _ready() -> void:
	var random_type: MenuButton = get_mapped_field(&"random_type", &"type_button")
	var random_popup: PopupMenu = random_type.get_popup()
	graph_icon = get_theme_icon("RandomNumberGenerator", "EditorIcons")
	random_type.icon = get_theme_icon("int", "EditorIcons")
	random_popup.add_icon_item(
			get_theme_icon("int", "EditorIcons"),
			"",
			TYPE_INT)
	random_popup.add_icon_item(
			get_theme_icon("float", "EditorIcons"),
			"",
			TYPE_FLOAT)
	random_popup.add_icon_item(
			get_theme_icon("bool", "EditorIcons"),
			"",
			TYPE_BOOL)
	
	
	set_input_connection_icon(&"min_value", get_theme_icon("int", "EditorIcons"))
	set_input_connection_icon(&"max_value", get_theme_icon("int", "EditorIcons"))


func _on_input_connected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	var min_spin: SpinBox = get_mapped_field(&"min_value", "min_spinbox")
	var max_spin: SpinBox = get_mapped_field(&"max_value", "max_spinbox")
	
	if input_port == 0:
		min_spin.visible = false
		max_spin.allow_lesser = true
	else:
		max_spin.visible = false


func _on_input_disconnected(input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	var min_spin: SpinBox = get_mapped_field(&"min_value", "min_spinbox")
	var max_spin: SpinBox = get_mapped_field(&"max_value", "max_spinbox")
	
	if input_port == 0:
		min_spin.visible = true
		max_spin.allow_lesser = false
	else:
		max_spin.visible = true


func _get_node_data() -> Dictionary:
	var metadata: Dictionary = {
		"mode": current_mode,
		"values": {
			"base": get_mapped_field(&"min_value", "min_spinbox").value,
			"max": get_mapped_field(&"max_value", "max_spinbox").value}}
	var input_connections: Dictionary = {
		"base_value": get_uuid_and_port_connected_to(PortMode.INPUT, 0),
		"max_value": get_uuid_and_port_connected_to(PortMode.INPUT, 1)}
	var output_connections: Dictionary = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	
	return _build_node_data(metadata, output_connections, input_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	var type_menu: MenuButton = get_mapped_field(&"random_type", "type_button")
	
	if metadata.has("mode") and typeof(metadata["mode"]) == TYPE_INT:
		set_mode(metadata["mode"])
	
	if not metadata.has("values") or typeof(metadata["values"]) != TYPE_DICTIONARY:
		return
	
	if metadata["values"].has("base"):
		var base_type: int = metadata["values"]["base"]
		if base_type == TYPE_INT or base_type == TYPE_FLOAT:
			min_spinbox.set_value_no_signal(metadata["values"]["base"])
			min_spinbox.set_meta(&"old_value", min_spinbox.value)
	
	if metadata["values"].has("max"):
		var max_type: int = metadata["values"]["max"]
		if max_type == TYPE_INT or max_type == TYPE_FLOAT:
			max_spinbox.set_value_no_signal(maxf(min_spinbox.value, metadata["values"]["max"]))
			max_spinbox.set_meta(&"old_value", max_spinbox.value)


func _on_min_value_changed(min_value: float) -> void:
	if current_mode == TYPE_BOOL:
		return
	var prev_min_value: float = min_spinbox.get_meta(&"old_value")
	var prev_max_value: float = max_spinbox.get_meta(&"old_value")
	min_spinbox.set_meta(&"old_value", min_value)
	max_spinbox.min_value = min_value
	
	if max_spinbox.value < min_value:
		max_spinbox.set_value_no_signal(min_value)
		max_spinbox.set_meta(&"old_value", min_value)
	
	range_changed.emit(
			get_node_uuid(),
			prev_min_value,
			prev_max_value,
			min_value,
			max_spinbox.value)


func _on_max_value_changed(max_value: float) -> void:
	var prev_value: float = max_spinbox.get_meta(&"old_value")
	max_spinbox.set_meta(&"old_value", max_value)
	range_changed.emit(
			get_node_uuid(),
			min_spinbox.value,
			prev_value,
			min_spinbox.value,
			max_value)


func _on_random_type_selected(type: int) -> void:
	var prev_mode: int = menu.get_meta(&"old_value")
	
	if type == prev_mode:
		return
	
	menu.set_meta(&"old_value", type)
	set_mode(type)
	mode_changed.emit(
			get_node_uuid(),
			prev_mode,
			current_mode)


func set_mode(mode: int) -> void:
	if mode != TYPE_INT and mode != TYPE_FLOAT and mode != TYPE_BOOL:
		return
	
	if current_mode == mode:
		return
	
	current_mode = mode
	_set_type_fields(mode)


func _set_type_fields(type: int) -> void:
	if min_spinbox.has_focus():
		min_spinbox.release_focus()
	elif max_spinbox.has_focus():
		max_spinbox.release_focus()
	
	match type:
		TYPE_INT:
			menu.icon = get_theme_icon("int", "EditorIcons")
			set_slot_type_left(0, SlotConnectionType.VAR_INT)
			set_slot_type_left(1, SlotConnectionType.VAR_INT)
			set_slot_type_right(0, SlotConnectionType.VAR_INT)
			set_slot_color_left(1, COLORS["integer"])
			set_slot_color_left(2, COLORS["integer"])
			set_slot_color_right(0, COLORS["integer"])
			set_input_connection_icon(&"min_value", get_theme_icon("int", "EditorIcons"))
			set_input_connection_icon(&"max_value", get_theme_icon("int", "EditorIcons"))
			
		TYPE_FLOAT:
			menu.icon = get_theme_icon("float", "EditorIcons")
			set_slot_type_left(0, SlotConnectionType.VAR_FLOAT)
			set_slot_type_left(1, SlotConnectionType.VAR_FLOAT)
			set_slot_type_right(0, SlotConnectionType.VAR_FLOAT)
			set_slot_color_left(1, COLORS["float"])
			set_slot_color_left(2, COLORS["float"])
			set_slot_color_right(0, COLORS["float"])
			set_input_connection_icon(&"min_value", get_theme_icon("float", "EditorIcons"))
			set_input_connection_icon(&"max_value", get_theme_icon("float", "EditorIcons"))
		TYPE_BOOL:
			menu.icon = get_theme_icon("bool", "EditorIcons")
			set_slot_type_left(0, SlotConnectionType.VAR_BOOL)
			set_slot_type_left(1, SlotConnectionType.VAR_INT)
			set_slot_type_right(0, SlotConnectionType.VAR_BOOL)
			set_slot_color_left(1, COLORS["integer"])
			set_slot_color_left(2, COLORS["bool"])
			set_slot_color_right(0, COLORS["bool"])
			set_input_connection_icon(&"min_value", get_theme_icon("int", "EditorIcons"))
			set_input_connection_icon(&"max_value", get_theme_icon("bool", "EditorIcons"))
	
	if type == TYPE_INT or type == TYPE_FLOAT:
		if max_spinbox.value < min_spinbox.value:
			max_spinbox.set_value_no_signal(min_spinbox.value)
		min_spinbox.step = 1.0 if type == TYPE_INT else 0.01
		min_spinbox.allow_lesser = true
		min_spinbox.allow_greater = true
		max_spinbox.step = min_spinbox.step
		set_field_visible(&"max_value", true)
		set_deferred(&"size", Vector2(240.0, 165.0))
		min_label.text = "Min"
		min_spinbox.suffix = ""
	else:
		min_label.text = "True Prob."
		min_spinbox.suffix = "%"
		min_spinbox.step = 1.0
		min_spinbox.allow_lesser = false
		min_spinbox.allow_greater = false
		if not RangeUtils.is_between(min_spinbox.value, 0.0, 100.0):
			min_spinbox.set_value_no_signal(clampf(min_spinbox.value, 0.0, 100.0))
		set_field_visible(&"max_value", false)
		set_deferred(&"size", Vector2(240.0, 85.0))
