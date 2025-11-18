extends DiscourseGraphNode


var current_mode: int = TYPE_INT


func _post_init() -> void:
	name = &"RandomValue"
	custom_id = "RandomValue"
	title = "Random Value"
	node_type = DialogueNodeType.RANDOM_VALUE
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(240.0, 165.0)
	var header_container: HBoxContainer = HBoxContainer.new()
	var random_type: MenuButton = MenuButton.new()
	var random_popup: PopupMenu = random_type.get_popup()
	var header_label: Label = Label.new()
	var min_container: HBoxContainer = HBoxContainer.new()
	var max_container: HBoxContainer = HBoxContainer.new()
	var min_label: Label = Label.new()
	var max_label: Label = Label.new()
	var min_spinbox: SpinBox = SpinBox.new()
	var max_spinbox: SpinBox = SpinBox.new()
	
	header_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	min_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	max_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	min_container.custom_minimum_size.y = 32.0
	max_container.custom_minimum_size.y = 32.0
	
	header_label.text = "Random Value"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	random_type.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	random_type.custom_minimum_size = Vector2(32.0, 32.0)
	
	min_label.text = "Min"
	min_label.custom_minimum_size.x = 35.0
	min_spinbox.custom_minimum_size = Vector2(90.0, 32.0)
	min_spinbox.min_value = 0.0
	min_spinbox.max_value = 100.0
	min_spinbox.allow_lesser = true
	min_spinbox.allow_greater = true
	
	max_label.text = "Max"
	max_label.custom_minimum_size.x = 35.0
	max_spinbox.custom_minimum_size = Vector2(90.0, 32.0)
	max_spinbox.allow_greater = true
	
	header_container.add_child(header_label)
	header_container.add_child(random_type)
	
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
	map_field(&"random_type", "type_button", random_type)
	
	add_field(
			&"min_value",
			min_container,
			false,
			SlotConnectionType.VAR_INT,
			-1)
	set_slot_color_left(1, COLORS["integer"])
	map_field(&"min_value", "min_label", min_label)
	map_field(&"min_value", "min_spinbox", min_spinbox)
	map_field(&"min_value", "min_spinbox", min_spinbox)
	
	add_field(
			&"max_value",
			max_container,
			false,
			SlotConnectionType.VAR_INT,
			-1)
	set_slot_color_left(2, COLORS["integer"])
	map_field(&"max_value", "max_spinbox", max_spinbox)
	
	min_spinbox.value_changed.connect(_on_min_value_changed.bind(max_spinbox))
	random_popup.id_pressed.connect(_on_random_type_selected.bind(random_type, min_spinbox, max_spinbox, min_label))


func _ready() -> void:
	var random_type: MenuButton = get_mapped_field(&"random_type", "type_button")
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
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["mode"] = current_mode
	data["values"] = {
		"base": get_mapped_field(&"min_value", "min_spinbox").value,
		"max": get_mapped_field(&"max_value", "max_spinbox").value}
	data["input_connections"] = {
		"base_value": get_uuid_and_port_connected_to(PortMode.INPUT, 0),
		"max_value": get_uuid_and_port_connected_to(PortMode.INPUT, 1)}
	data["output_connections"] = {
		"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	return data


func _set_node_data(data: Dictionary) -> void:
	position_offset = data["position"]
	var base: SpinBox = get_mapped_field(&"min_value", "min_spinbox")
	var max_value: SpinBox = get_mapped_field(&"max_value", "max_spinbox")
	var min_label: Label = get_mapped_field(&"min_value", "min_label")
	var type_menu: MenuButton = get_mapped_field(&"random_type", "type_button")
	
	current_mode = data["mode"]
	set_type_fields(current_mode, type_menu, base, max_value, min_label)
	base.value = data["values"]["base"]
	max_value.value = maxf(data["values"]["base"], data["values"]["max"])


func _on_min_value_changed(min_value: float, max_spinbox: SpinBox) -> void:
	if current_mode == TYPE_BOOL:
		return
	
	max_spinbox.min_value = min_value
	
	if max_spinbox.value < min_value:
		max_spinbox.set_value_no_signal(min_value)


func _on_random_type_selected(type: int, menu: MenuButton, min_spinbox: SpinBox, max_spinbox: SpinBox, min_label: Label) -> void:
	if current_mode == type:
		return
	current_mode = type
	set_type_fields(type, menu, min_spinbox, max_spinbox, min_label)
	node_updated.emit()


func set_type_fields(type: int, menu: MenuButton, min_spinbox: SpinBox, max_spinbox: SpinBox, min_label: Label) -> void:
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
			max_spinbox.value = min_spinbox.value
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
		if not Ranges.is_between(min_spinbox.value, 0.0, 100.0):
			min_spinbox.value = clampf(min_spinbox.value, 0.0, 100.0)
		set_field_visible(&"max_value", false)
		set_deferred(&"size", Vector2(240.0, 85.0))
