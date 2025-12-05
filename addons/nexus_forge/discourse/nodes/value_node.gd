extends DiscourseGraphNode


signal value_changed
signal data_type_changed


var active_value: Control = null


var mode: int = TYPE_INT:
	set(new_mode):
		if mode == new_mode:
			return
		
		if active_value != null:
			match mode:
				TYPE_INT:
					active_value.value_changed.disconnect(_on_value_changed)
				TYPE_FLOAT:
					active_value.value_changed.disconnect(_on_value_changed)
				TYPE_BOOL:
					active_value.toggled.disconnect(_on_value_changed)
				TYPE_STRING:
					active_value.text_changed.disconnect(_on_value_changed)
		
		mode = new_mode
		
		for option in get_field(&"data").get_child(0).get_children():
			option.visible = false
		
		match new_mode as Variant.Type:
			TYPE_INT:
				active_value = get_field(&"data").get_child(0).get_child(0)
				active_value.step = 1.0
				active_value.visible = true
				active_value.value_changed.connect(_on_value_changed, CONNECT_DEFERRED)
				set_slot_type_right(0, SlotConnectionType.VAR_INT)
				set_slot_color_right(0, COLORS["integer"])
				#set_output_connection_icon(&"data", get_theme_icon("int", "EditorIcons"))
			TYPE_FLOAT:
				active_value = get_field(&"data").get_child(0).get_child(0)
				active_value.visible = true
				active_value.step = 0.01
				active_value.value_changed.connect(_on_value_changed, CONNECT_DEFERRED)
				set_slot_type_right(0, SlotConnectionType.VAR_FLOAT)
				set_slot_color_right(0, COLORS["float"])
				#set_output_connection_icon(&"data", get_theme_icon("float", "EditorIcons"))
			TYPE_BOOL:
				active_value = get_field(&"data").get_child(0).get_child(1)
				active_value.visible = true
				active_value.toggled.connect(_on_value_changed, CONNECT_DEFERRED)
				set_slot_type_right(0, SlotConnectionType.VAR_BOOL)
				set_slot_color_right(0, COLORS["bool"])
				#set_output_connection_icon(&"data", get_theme_icon("bool", "EditorIcons"))
			TYPE_STRING:
				active_value = get_field(&"data").get_child(0).get_child(2)
				active_value.visible = true
				active_value.text_changed.connect(_on_value_changed, CONNECT_DEFERRED)
				set_slot_type_right(0, SlotConnectionType.VAR_STRING)
				set_slot_color_right(0, COLORS["string"])
				#set_output_connection_icon(&"data", get_theme_icon("String", "EditorIcons"))
		data_type_changed.emit()


func _post_init() -> void:
	name = &"Value"
	title = "Value"
	custom_id = "Value"
	node_type = DialogueNodeType.VALUE
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(260, 90)
	
	var main_container: HBoxContainer = HBoxContainer.new()
	var data_panel: PanelContainer = PanelContainer.new()
	var data_spnbx: SpinBox = SpinBox.new()
	var data_chk_bx: CheckBox = CheckBox.new()
	var data_ln_edt: LineEdit = LineEdit.new()
	#var data_type_optbtn: OptionButton = OptionButton.new()
	var data_menu: MenuButton = MenuButton.new()
	var data_popup: PopupMenu = data_menu.get_popup()
	
	main_container.custom_minimum_size.y = 32
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_panel.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	data_spnbx.allow_greater = true
	data_spnbx.allow_lesser = true
	data_chk_bx.text = "Is True"
	data_chk_bx.visible = false
	data_ln_edt.visible = false
	
	data_menu.flat = false
	data_menu.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	data_menu.custom_minimum_size = Vector2(32.0, 32.0)
	
	data_panel.add_child(data_spnbx)
	data_panel.add_child(data_chk_bx)
	data_panel.add_child(data_ln_edt)
	
	main_container.add_child(data_panel)
	main_container.add_child(data_menu)
	
	add_field(
			&"data",
			main_container,
			false,
			-1,
			SlotConnectionType.VAR_INT)
	map_field(&"data", &"number", data_spnbx)
	map_field(&"data", &"bool", data_chk_bx)
	map_field(&"data", &"text", data_ln_edt)
	
	set_slot_color_right(0, COLORS["integer"])
	
	active_value = data_spnbx
	
	data_popup.id_pressed.connect(_on_data_type_selected)
	data_spnbx.value_changed.connect(_on_value_changed, CONNECT_DEFERRED)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/variable_icon.svg")
	var data_menu: MenuButton = get_field(&"data").get_child(1)
	var data_popup: PopupMenu = data_menu.get_popup()
	
	data_menu.icon = get_theme_icon("int", "EditorIcons")
	data_popup.add_icon_item(
			get_theme_icon("int", "EditorIcons"),
			"",
			TYPE_INT)
	data_popup.add_icon_item(
			get_theme_icon("float", "EditorIcons"),
			"",
			TYPE_FLOAT)
	data_popup.add_icon_item(
			get_theme_icon("bool", "EditorIcons"),
			"",
			TYPE_BOOL)
	data_popup.add_icon_item(
			get_theme_icon("String", "EditorIcons"),
			"",
			TYPE_STRING)
	
	data_menu.icon = data_popup.get_item_icon(data_popup.get_item_index(mode))


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["value"] = get_current_value()
	data["output_connections"] = {
		"next_node": get_uuid_and_port_connected_to(
				PortMode.OUTPUT,
				0)
	}
	return data


func _set_node_data(data: Dictionary) -> void:
	var menu: MenuButton = get_field(&"data").get_child(1)
	mode = typeof(data["value"])
	
	match mode:
		TYPE_INT:
			get_mapped_field(&"data", &"number").value = data["value"]
			menu.icon = get_theme_icon("int", "EditorIcons")
		TYPE_FLOAT:
			get_mapped_field(&"data", &"number").value = data["value"]
			menu.icon = get_theme_icon("float", "EditorIcons")
		TYPE_BOOL:
			get_mapped_field(&"data", &"bool").button_pressed = data["value"]
			menu.icon = get_theme_icon("bool", "EditorIcons")
		TYPE_STRING:
			get_mapped_field(&"data", &"text").text = data["value"]
			menu.icon = get_theme_icon("String", "EditorIcons")
	
	position_offset = data["position"]


func _on_data_type_selected(type: int) -> void:
	if type == mode:
		return
	
	if has_any_output(0):
		var target: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, 0)
		var target_input: int = target.get_port_connected_to(PortMode.INPUT, self, 0)
		var port_type: int = target.get_slot_type_left(target_input)
		if port_type != SlotConnectionType.VAR_ANY:
			disconnect_requested.emit(
					name,
					0,
					target.name,
					target_input)
	var menu: MenuButton = get_field(&"data").get_child(1)
	var pop: Popup = menu.get_popup()
	
	menu.icon = pop.get_item_icon(pop.get_item_index(type))
	mode = type
	


func _on_value_changed(_value: Variant = null) -> void:
	value_changed.emit()


func get_current_value(default: Variant = null) -> Variant:
	var data: Control = get_field(&"data")
	match mode:
		TYPE_INT:
			return int(data.get_child(0).get_child(0).value)
		TYPE_FLOAT:
			return float(data.get_child(0).get_child(0).value)
		TYPE_BOOL:
			return data.get_child(0).get_child(1).button_pressed
		TYPE_STRING:
			return data.get_child(0).get_child(2).text
		_:
			return default


func clamp_range(min_value: float, max_value: float, allow_lesser: bool = false, allow_greater: bool = false) -> void:
	var reconnect: bool = false
	var range_box: SpinBox = get_field(&"data").get_child(0).get_child(0)
	range_box.min_value = min_value
	range_box.max_value = max_value
	range_box.allow_lesser = allow_lesser
	range_box.allow_greater = allow_greater
	
	
	if range_box.value_changed.is_connected(_on_value_changed):
		reconnect = true
		range_box.value_changed.disconnect(_on_value_changed)
	
	if not allow_greater and not allow_lesser:
		range_box.value = clampf(range_box.value, min_value, max_value)
		#range_box.set_value_no_signal(clampf(range_box.value, min_value, max_value))
	elif not allow_lesser:
		range_box.value = maxf(min_value, range_box.value)
		#range_box.set_value_no_signal(maxf(min_value, range_box.value))
	elif not allow_greater:
		range_box.value = minf(range_box.value, max_value)
		#range_box.set_value_no_signal(minf(range_box.value, max_value))
	
	if reconnect:
		range_box.value_changed.connect(_on_value_changed)
