extends DiscourseGraphNode


func _post_init() -> void:
	name = &"Choices"
	custom_id = "Choices"
	title = "Choices"
	node_type = DialogueNodeType.OPTIONS
	parent_mode = PortMode.INPUT
	parent_port = 0
	
	var choice_count_container: HBoxContainer = HBoxContainer.new()
	var choices_label: Label = Label.new()
	var choices_spinbox: SpinBox = SpinBox.new()
	var first_choice: LineEdit = LineEdit.new()
	
	choices_label.text = "Choices"
	choices_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	choices_label.custom_minimum_size.y = 32.0
	
	choices_spinbox.custom_minimum_size.y = 32.0
	choices_spinbox.value = 1.0
	choices_spinbox.min_value = 1.0
	
	first_choice.placeholder_text = "Choice Text"
	first_choice.custom_minimum_size.y = 32.0
	first_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	choice_count_container.add_child(choices_label)
	choice_count_container.add_child(choices_spinbox)
	
	size = Vector2(320.0, 130.0)
	custom_minimum_size = Vector2(320.0, 124.0)
	first_choice.text_changed.connect(_on_option_text_changed)
	
	var next_in_idx: int = add_field(
			&"choice_counter",
			choice_count_container,
			false,
			SlotConnectionType.DIALOG)
	map_field(&"choice_counter", "choice_count", choices_spinbox)
	
	var first_out_idx: int = add_field(
			&"choice_1",
			first_choice,
			false,
			SlotConnectionType.SETTINGS_OPTION,
			SlotConnectionType.DIALOG,
			preload("res://addons/nexus_forge/icons/gear_icon.png"))
	
	set_slot_color_left(next_in_idx, COLORS["dialog"])
	set_slot_color_right(first_out_idx, COLORS["dialog"])
	set_slot_color_left(first_out_idx, COLORS["setting"])
	
	set_slot_custom_icon_left(next_in_idx, flow_icon)
	set_slot_custom_icon_right(first_out_idx, flow_icon)
	
	choices_spinbox.value_changed.connect(_on_choice_count_changed)


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	
	if not has_any_input(0):
		issues.append("Warning: Node is orphan.")
	
	for choice in range(1, get_child_count()):
		if not has_any_output(choice):
			issues.append(str("Warning: Option ", choice, " has no connection."))
	
	return issues


func _on_option_text_changed(_text: String) -> void:
	node_updated.emit()


func set_choice_count(value: int) -> void:
	var current: int = get_child_count() - 1
	if current < value:
		for extra in range(value - current):
			var new_idx: int = add_field(
					&"choice_" + StringName(str(current + extra + 1)),
					get_choice_node(),
					false,
					SlotConnectionType.SETTINGS_OPTION,
					SlotConnectionType.DIALOG,
					preload("res://addons/nexus_forge/icons/gear_icon.png"))
			set_slot_color_right(new_idx, COLORS["dialog"])
			set_slot_color_left(new_idx, COLORS["setting"])
			set_slot_custom_icon_right(new_idx, flow_icon)
	else:
		for over in range(current - value):
			remove_choice(current - over)


func _on_choice_count_changed(value: int) -> void:
	var current: int = get_child_count() - 1
	if value == current:
		return
	
	set_choice_count(value)
	
	node_updated.emit()


func _get_node_data() -> Dictionary:
	var data: Dictionary = {"position": position_offset, "node_type": node_type}
	var options: Array[Dictionary] = []
	
	for choice in range(1, get_child_count()):
		var field_id: StringName = &"choice_" + StringName(str(int(choice)))
		var field: LineEdit = get_field(field_id)
		
		options.append(
				{
					"option_text": field.text.strip_edges(),
					"output_connections":{
						"next_node":  get_uuid_and_port_connected_to(PortMode.OUTPUT, choice - 1)
					},
					"input_connections": {
						"settings": get_uuid_and_port_connected_to(PortMode.INPUT, choice)
					}
				})
	
	data["options"] = options
	
	return data


func _set_node_data(data: Dictionary) -> void:
	position_offset = data["position"]
	var new_choice_count: int = data["options"].size()
	get_mapped_field(&"choice_counter", "choice_count").set_value_no_signal(new_choice_count)
	set_choice_count(new_choice_count)
	for option in range(1, new_choice_count + 1):
		get_field(&"choice_" + StringName(str(option))).text = data["options"][option - 1]["option_text"]


func get_choice_node() -> LineEdit:
	var new_choice: LineEdit = LineEdit.new()
	new_choice.placeholder_text = "Choice Text"
	new_choice.custom_minimum_size.y = 32.0
	new_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_choice.text_changed.connect(_on_option_text_changed)
	return new_choice


func remove_choice(idx: int) -> void:
	var field_id: StringName = &"choice_" + StringName(str(idx))
	var choice: LineEdit = get_field(field_id)
	choice.text_changed.disconnect(_on_option_text_changed)
	remove_field(field_id, 40)


func set_option_text(option: int, text: String) -> void:
	var field_id: StringName = &"choice_" + StringName(str(option))
	
	var option_line: LineEdit = get_field(field_id)
	if option_line != null:
		option_line.text = text


func get_options() -> Array[String]:
	var options: Array[String] = []
	
	for choice in range(1, get_child_count()):
		var field_id: StringName = &"choice_" + StringName(str(int(choice)))
		var field: LineEdit = get_field(field_id)
		options.append(field.text)
	
	return options
