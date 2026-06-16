@tool
extends DiscourseGraphNode


var _updating_choices: bool = false


func _post_init() -> void:
	set_node_id(&"Choices")
	title = "Choices"
	node_type = DialogueNodeType.CHOICES
	parent_mode = PortMode.INPUT
	parent_port = 0
	size = Vector2(220.0, 124.0)
	custom_minimum_size.y = 124.0
	
	var choice_count_container: HBoxContainer = HBoxContainer.new()
	var choices_label: Label = Label.new()
	var choices_spinbox: SpinBox = SpinBox.new()
	var first_choice: LineEdit = preload("res://addons/nexus_forge/discourse/choice_node_lineedit.gd").new()
	
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
	
	first_choice.text_changed.connect(_on_option_text_changed)
	
	var next_in_idx: int = add_field(
			&"choice_counter",
			choice_count_container,
			false,
			SlotConnectionType.DIALOG)
	map_field(&"choice_counter", &"choice_count", choices_spinbox)
	
	var first_out_idx: int = add_field(
			&"choice_1",
			first_choice,
			false,
			SlotConnectionType.SETTINGS_OPTION,
			SlotConnectionType.DIALOG)
	
	set_slot_color_left(next_in_idx, COLORS["dialog"])
	set_slot_color_right(first_out_idx, COLORS["dialog"])
	set_slot_color_left(first_out_idx, COLORS["setting"])
	
	
	choices_spinbox.value_changed.connect(_on_choice_count_changed)


func _ready() -> void:
	graph_icon = preload("res://addons/nexus_forge/icons/list_icon.svg")
	set_slot_custom_icon_left(0, flow_icon)
	for child_idx in range(1, get_child_count()):
		set_slot_custom_icon_right(child_idx, flow_icon)
	set_input_connection_icon(
			&"choice_1",
			preload("res://addons/nexus_forge/icons/gear_icon.png"))


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	
	if not has_any_input(0):
		issues.append("Warning: Node is orphan.")
	
	for choice in range(1, get_child_count()):
		if not has_any_output(choice - 1):
			issues.append(str("Warning: Option ", choice, " has no output connection."))
	
	return issues


func _on_option_text_changed(_text: String) -> void:
	node_updated.emit()


func set_choice_count(value: int) -> void:
	var current: int = get_child_count() - 1
	if value == current:
		return
	
	if current < value:
		for extra in range(value - current):
			var choice_id: StringName = &"choice_" + StringName(str(current + extra + 1))
			var new_idx: int = add_field(
					choice_id,
					get_choice_node(),
					false,
					SlotConnectionType.SETTINGS_OPTION,
					SlotConnectionType.DIALOG)
			set_input_connection_icon(
					choice_id,
					preload("res://addons/nexus_forge/icons/gear_icon.png"))
			set_slot_color_right(new_idx, COLORS["dialog"])
			set_slot_color_left(new_idx, COLORS["setting"])
			set_slot_custom_icon_right(new_idx, flow_icon)
	else:
		var choices_to_remove: Array[StringName] = []
		for over in range(current - value):
			choices_to_remove.append(StringName("choice_" + str(current - over)))
		remove_choices(choices_to_remove)


func _on_choice_count_changed(value: int) -> void:
	if _updating_choices or value == get_child_count() - 1:
		return
	
	_updating_choices = true
	
	_update_value_to_spinbox.call_deferred()


func _update_value_to_spinbox() -> void:
	set_choice_count(
			get_mapped_field(&"choice_counter", &"choice_count").value)
	_updating_choices = false
	node_updated.emit()


func _get_node_data() -> Dictionary:
	var options: Array[Dictionary] = []
	var metadata: Dictionary = {"choices": options}
		
	for choice in range(1, get_child_count()):
		var field_id: StringName = &"choice_" + StringName(str(int(choice)))
		var field: LineEdit = get_field(field_id)
		
		options.append(
				{
					"text": field.text.strip_edges(),
					"output_connections":{
						"next_node":  get_uuid_and_port_connected_to(PortMode.OUTPUT, choice - 1)
					},
					"input_connections": {
						"settings": get_uuid_and_port_connected_to(PortMode.INPUT, choice)
					}
				})
	
	return _build_node_data(metadata)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if not metadata.has("choices") or typeof(metadata["choices"]) != TYPE_ARRAY:
		return
	
	var true_options: Array = []
	for option in metadata["choices"]:
		if typeof(option) != TYPE_DICTIONARY or typeof(option.get("text")) != TYPE_STRING:
			continue
		true_options.append(option)
	
	var choice_size: int = true_options.size()
	var choice_count: int = max(1, choice_size)
	get_mapped_field(&"choice_counter", &"choice_count").set_value_no_signal(choice_count)
	set_choice_count(choice_count)
	for option in range(1, choice_size + 1):
		get_field(&"choice_" + StringName(str(option))).text = true_options[option - 1]["text"]


func choice_count() -> int:
	return get_mapped_field(&"choice_counter", &"choice_count").value


func get_choice_node() -> LineEdit:
	var new_choice: LineEdit = preload("res://addons/nexus_forge/discourse/choice_node_lineedit.gd").new()
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


func remove_choices(choices: Array[StringName]) -> void:
	if choices.is_empty():
		return
	
	for choice_id in choices:
		var choice: LineEdit = get_field(choice_id)
		choice.text_changed.disconnect(_on_option_text_changed)
	
	remove_fields(choices, -1)


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
