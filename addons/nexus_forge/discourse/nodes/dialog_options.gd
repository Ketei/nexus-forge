@tool
extends DiscourseGraphNode


signal use_code_editor_pressed(target: TextEdit)
const MAX_LINES: int = 3
const EXTRA_Y_PADDING: int = 8
const CHOICE_TEXT_EDIT = preload("res://addons/nexus_forge/discourse/textedit_bracket_handler.gd")

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
	var first_choice: HBoxContainer = get_choice_node()
	
	choices_label.text = "Choices"
	choices_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	choices_label.custom_minimum_size.y = 32.0
	
	choices_spinbox.custom_minimum_size.y = 32.0
	choices_spinbox.value = 1.0
	choices_spinbox.min_value = 1.0
	
	choice_count_container.add_child(choices_label)
	choice_count_container.add_child(choices_spinbox)
	
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
		var choice_id: StringName = StringName("choice_" + str(child_idx))
		set_slot_custom_icon_right(child_idx, flow_icon)
		get_field(choice_id).get_child(1).icon = get_theme_icon("DistractionFree", "EditorIcons")
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


func _on_option_text_changed(box: TextEdit) -> void:
	_update_choice_textbox_size(box)
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


func _update_choice_textbox_size(box: TextEdit) -> void:
	if box.size.x <= 0 or not box.is_visible_in_tree():
		return
	
	box.scroll_fit_content_height = true
	var total_visual_lines: int = 0
	for i in range(box.get_line_count()):
		total_visual_lines += 1 + box.get_line_wrap_count(i)
	if total_visual_lines <= MAX_LINES:
		reset_height.call_deferred()
		box.custom_minimum_size.y = 0
		return
	box.scroll_fit_content_height = false
	
	var new_height: float = MAX_LINES * box.get_line_height() + EXTRA_Y_PADDING
	if new_height != box.custom_minimum_size.y:
		box.custom_minimum_size.y = new_height


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
		var field: TextEdit = get_field(field_id).get_child(0)
		
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
	
	if metadata.has("localized") and typeof(metadata["localized"]) == TYPE_BOOL:
		set_node_localized(metadata["localized"])
	
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
		get_field(&"choice_" + StringName(str(option))).get_child(0).text = true_options[option - 1]["text"]


func choice_count() -> int:
	return get_mapped_field(&"choice_counter", &"choice_count").value


func get_choice_node() -> HBoxContainer:
	var new_choice: TextEdit = CHOICE_TEXT_EDIT.new()
	var expand_button: Button = Button.new()
	var container: HBoxContainer = HBoxContainer.new()
	var highlighter: NFEditorDialogSyntaxHighlighter = NFEditorDialogSyntaxHighlighter.new()
	
	highlighter.set_use_token("*", false)
	
	container.add_child(new_choice)
	container.add_child(expand_button)
	
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	new_choice.syntax_highlighter = NFEditorDialogSyntaxHighlighter.new()
	new_choice.placeholder_text = "Choice Text"
	new_choice.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	new_choice.custom_minimum_size.y = 32.0
	new_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_choice.syntax_highlighter = highlighter
	new_choice.resized.connect(reset_height, CONNECT_DEFERRED)
	new_choice.text_changed.connect(_on_option_text_changed.bind(new_choice))
	
	expand_button.icon = get_theme_icon("DistractionFree", "EditorIcons")
	expand_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	expand_button.flat = true
	expand_button.pressed.connect(use_code_editor_pressed.emit.bind(new_choice))
	
	return container


func remove_choice(idx: int) -> void:
	var field_id: StringName = &"choice_" + StringName(str(idx))
	var choice: TextEdit = get_field(field_id).get_child(0)
	choice.text_changed.disconnect(_on_option_text_changed)
	remove_field(field_id, 40)


func remove_choices(choices: Array[StringName]) -> void:
	if choices.is_empty():
		return
	
	for choice_id in choices:
		var choice: TextEdit = get_field(choice_id).get_child(0)
		choice.text_changed.disconnect(_on_option_text_changed)
	
	remove_fields(choices, -1)


func reset_height() -> void:
	size.y = 0


func set_option_text(option: int, text: String) -> void:
	var field_id: StringName = &"choice_" + StringName(str(option))
	
	var option_line: TextEdit = get_field(field_id).get_child(0)
	if option_line != null:
		option_line.text = text


func get_options() -> Array[String]:
	var options: Array[String] = []
	
	for choice in range(1, get_child_count()):
		var field_id: StringName = &"choice_" + StringName(str(int(choice)))
		var field: TextEdit = get_field(field_id).get_child(0)
		options.append(field.text)
	
	return options
