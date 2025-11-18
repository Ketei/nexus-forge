extends DiscourseGraphNode


var current_mode: int = TYPE_INT


func _post_init() -> void:
	name = &"Match"
	custom_id = "Match"
	title = "Match"
	size = Vector2(240.0, 204.0)
	parent_mode = PortMode.INPUT
	parent_port = 0
	node_type = DialogueNodeType.MATCH
	
	var case_label: Label = Label.new()
	var value_label: Label = Label.new()
	var default_label: Label = Label.new()
	
	var cases: SpinBox = SpinBox.new()
	var value_menu: MenuButton = MenuButton.new()
	var menu_popup: PopupMenu = value_menu.get_popup()
	var value_text: LineEdit = LineEdit.new()
	var value_number: SpinBox = SpinBox.new()
	var cases_container: HBoxContainer = HBoxContainer.new()
	var val_type_container: HBoxContainer = HBoxContainer.new()
	var case_one: PanelContainer = get_new_match_field()
	
	case_label.text = "Cases"
	case_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	case_label.custom_minimum_size = Vector2(50.0, 32.0)
	cases.min_value = 1
	cases.value = 1
	
	value_label.text = "Value"
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(50.0, 32.0)
	value_menu.flat = false
	value_menu.custom_minimum_size = Vector2(32.0, 32.0)
	value_menu.expand_icon = false
	value_menu.focus_mode = Control.FOCUS_ALL
	
	value_menu.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	default_label.text = "Default"
	default_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	default_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	default_label.custom_minimum_size.y = 32.0
	default_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	value_text.placeholder_text = "String"
	value_text.visible = false
	value_text.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_number.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_number.allow_greater = true
	value_number.allow_lesser = true
	value_number.step = 1.0
	
	val_type_container.add_child(value_menu)
	val_type_container.add_child(value_label)
	cases_container.add_child(case_label)
	cases_container.add_child(cases)
	
	add_field(
			&"cases",
			cases_container,
			false,
			SlotConnectionType.DIALOG)
	map_field(&"cases", "case_count", cases)
	
	add_field(
		&"values",
		val_type_container,
		false,
		SlotConnectionType.VAR_INT)
	
	add_field(
		&"case_default",
		default_label,
		false,
		-1,
		SlotConnectionType.DIALOG)
	
	add_field(
		&"case_1",
		case_one,
		false,
		-1,
		SlotConnectionType.DIALOG)

	set_slot_color_left(0, COLORS["dialog"])
	set_slot_color_left(1, COLORS["integer"])
	set_slot_color_right(2, COLORS["dialog"])
	set_slot_color_right(3, COLORS["dialog"])
	
	cases.value_changed.connect(_on_match_count_changed)
	menu_popup.id_pressed.connect(_on_value_type_changed)


func _ready() -> void:
	var value_menu: MenuButton = get_field(&"values").get_child(0)
	var menu_popup: PopupMenu = value_menu.get_popup()
	set_slot_custom_icon_left(0, flow_icon)
	set_slot_custom_icon_right(2, flow_icon)
	set_slot_custom_icon_right(3, flow_icon)
	
	menu_popup.add_icon_item(
			get_theme_icon("int", "EditorIcons"),
			"",
			TYPE_INT)
	menu_popup.add_icon_item(
			get_theme_icon("float", "EditorIcons"),
			"",
			TYPE_FLOAT)
	menu_popup.add_icon_item(
			get_theme_icon("String", "EditorIcons"),
			"",
			TYPE_STRING)
	
	value_menu.icon = get_theme_icon("int", "EditorIcons")


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	var cases: Array[Dictionary] = []
	
	for case in range(1, get_child_count() - 2):
		var case_id: StringName = &"case_" + StringName(str(int(case)))
		var control: Control = get_field(case_id).get_child(1 if current_mode == TYPE_STRING else 0)
		var case_data: Dictionary = {}
		case_data["output_connections"] = {
			"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, case)}
		match current_mode:
			TYPE_INT:
				case_data["value"] = int(control.value)
			TYPE_FLOAT:
				case_data["value"] = float(control.value)
			TYPE_STRING:
				case_data["value"] = control.text
		cases.append(case_data)
	
	data["node_type"] = node_type
	data["position"] = position_offset
	data["output_connections"] = {
		"default": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	data["input_connections"] = {
		"match_value_source": get_uuid_and_port_connected_to(PortMode.INPUT, 1)}
	data["match_data_type"] = current_mode
	data["cases"] = cases
	
	return data


func set_current_mode(mode: int) -> void:
	var menu_button: MenuButton = get_field(&"values").get_child(0)
	current_mode = mode
	match current_mode:
		TYPE_INT:
			set_slot_type_left(1, SlotConnectionType.VAR_INT)
			set_slot_color_left(1, COLORS["integer"])
			menu_button.icon = get_theme_icon("int", "EditorIcons")
			for match_option in range(3, get_child_count()):
				var val: SpinBox = get_child(match_option).get_child(1).get_child(0)
				get_child(match_option).get_child(1).get_child(1).visible = false
				val.visible = true
				val.step = 1.0
		TYPE_FLOAT:
			set_slot_type_left(1, SlotConnectionType.VAR_FLOAT)
			set_slot_color_left(1, COLORS["float"])
			menu_button.icon = get_theme_icon("float", "EditorIcons")
			for match_option in range(3, get_child_count()):
				var val: SpinBox = get_child(match_option).get_child(1).get_child(0)
				get_child(match_option).get_child(1).get_child(1).visible = false
				val.visible = true
				val.step = 0.01
		TYPE_STRING:
			set_slot_type_left(1, SlotConnectionType.VAR_STRING)
			set_slot_color_left(1, COLORS["string"])
			menu_button.icon = get_theme_icon("String", "EditorIcons")
			for match_option in range(3, get_child_count()):
				get_child(match_option).get_child(1).get_child(0).visible = false
				get_child(match_option).get_child(1).get_child(1).visible = true


func _on_value_type_changed(id: int) -> void:
	set_current_mode(id)
	node_updated.emit()


func _on_match_value_changed(_value: float) -> void:
	node_updated.emit()


func _on_match_text_changed(_text: String) -> void:
	node_updated.emit()


func _set_node_data(data: Dictionary) -> void:
	var case_count: int = data["cases"].size()
	position_offset = data["position"]
	get_mapped_field(&"cases", "case_count").set_value_no_signal(case_count)
	set_match_case_count(case_count)
	
	set_current_mode(data["match_data_type"])
	
	for match_option in range(1, case_count + 1):
		var case_id: StringName = &"case_" + StringName(str(int(match_option)))
		var field: Control = get_field(case_id)
		match current_mode:
			TYPE_STRING:
				field.get_child(1).text = data["cases"][match_option - 1]["value"]
			_:
				field.get_child(0).value = data["cases"][match_option - 1]["value"]
	position_offset = data["position"]


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if not has_any_output(0):
		issues.append("Warning: No default exit connected.")
	return issues


func set_match_case_count(new_count: int) -> void:
	var current: int = get_child_count() - 3
	
	if new_count == current:
		return
	if current < new_count:
		for new_match in range(new_count - current):
			var new_field: PanelContainer = get_new_match_field()
			var field_idx: int = add_field(
					&"case_" + StringName(str(current + new_match + 1)),
					new_field,
					false,
					-1,
					SlotConnectionType.DIALOG)
			set_slot_color_right(field_idx, COLORS["dialog"])
			set_slot_custom_icon_right(field_idx, flow_icon)
	else:
		for over in range(current - new_count):
			remove_match(current - over)


func _on_match_count_changed(new_count: int) -> void:
	set_match_case_count(new_count)
	node_updated.emit()


func remove_match(match_option: int) -> void:
	var field_id: StringName = &"case_" + StringName(str(match_option))
	var child: Control = get_child(match_option + 2)
	child.get_child(1).get_child(0).value_changed.disconnect(_on_match_value_changed)
	child.get_child(1).get_child(1).text_changed.disconnect(_on_match_text_changed)
	remove_field(field_id, 40)


func get_new_match_field() -> PanelContainer:
	var new_field: PanelContainer = PanelContainer.new()
	var value_text: LineEdit = LineEdit.new()
	var value_number: SpinBox = SpinBox.new()
	
	new_field.custom_minimum_size = Vector2(160.0, 32.0)
	new_field.size_flags_horizontal = SizeFlags.SIZE_EXPAND + SizeFlags.SIZE_SHRINK_END
	new_field.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	
	value_text.placeholder_text = "String"
	value_text.visible = current_mode == TYPE_STRING
	value_text.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	value_number.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_number.allow_greater = true
	value_number.allow_lesser = true
	value_number.step = 1.0 if current_mode == TYPE_INT else 0.01
	value_number.visible = current_mode != TYPE_STRING
	
	value_text.text_changed.connect(_on_match_text_changed)
	value_number.value_changed.connect(_on_match_value_changed)
	
	new_field.add_child(value_number)
	new_field.add_child(value_text)
	
	return new_field
