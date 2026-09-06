@tool
extends DiscourseGraphNode


signal value_changed(uuid: StringName, from: Variant, to: Variant)
signal data_type_changed(uuid: StringName, old_state: Dictionary, new_state: Dictionary)

const MAX_LINES: int = 5
const EXTRA_Y_PADDING: int = 8

var num_value: SpinBox
var text_value: TextEdit
var bool_value: CheckBox


var _mode: int = TYPE_INT


func _post_init() -> void:
	set_node_id(&"Value")
	title = "Value"
	node_type = DialogueNodeType.VALUE
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(260, 90)
	
	num_value = SpinBox.new()
	text_value = TextEdit.new()
	bool_value = CheckBox.new()
	
	var main_container: HBoxContainer = HBoxContainer.new()
	var data_panel: PanelContainer = PanelContainer.new()
	var data_menu: MenuButton = MenuButton.new()
	var data_popup: PopupMenu = data_menu.get_popup()
	
	main_container.custom_minimum_size.y = 33.0
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_panel.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	num_value.allow_greater = true
	num_value.allow_lesser = true
	num_value.step = 1.0
	num_value.set_meta(&"old_value", 0.0)
	bool_value.text = "Is True"
	bool_value.visible = false
	text_value.visible = false
	
	data_menu.flat = false
	data_menu.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	data_menu.custom_minimum_size = Vector2(32.0, 32.0)
	text_value.scroll_fit_content_height = true
	text_value.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_value.set_meta(&"old_value", "")
	
	data_panel.add_child(num_value)
	data_panel.add_child(bool_value)
	data_panel.add_child(text_value)
	
	main_container.add_child(data_panel)
	main_container.add_child(data_menu)
	
	add_field(
			&"data",
			main_container,
			false,
			-1,
			SlotConnectionType.VAR_INT)
	
	set_slot_color_right(0, COLORS["integer"])
	
	data_popup.id_pressed.connect(_on_data_type_selected)
	num_value.value_changed.connect(_on_num_value_changed)
	text_value.text_changed.connect(_on_text_field_text_changed, CONNECT_DEFERRED)
	text_value.focus_exited.connect(_on_text_value_focus_exited)
	bool_value.toggled.connect(_on_bool_value_toggled)


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
	
	data_menu.icon = data_popup.get_item_icon(data_popup.get_item_index(_mode))


func set_mode(to: int) -> bool:
	if to != TYPE_INT and to != TYPE_FLOAT and to != TYPE_BOOL and to != TYPE_STRING:
		return false
	
	if to == _mode:
		return true
	
	var menu: MenuButton = get_field(&"data").get_child(1)
	
	match to:
		TYPE_INT:
			num_value.visible = true
			text_value.visible = false
			bool_value.visible = false
			num_value.step = 1.0
			set_slot_type_right(0, SlotConnectionType.VAR_INT)
			set_slot_color_right(0, COLORS["integer"])
			menu.icon = get_theme_icon("int", "EditorIcons")
		TYPE_FLOAT:
			num_value.visible = true
			text_value.visible = false
			bool_value.visible = false
			num_value.step = 0.01
			set_slot_type_right(0, SlotConnectionType.VAR_FLOAT)
			set_slot_color_right(0, COLORS["float"])
			menu.icon = get_theme_icon("float", "EditorIcons")
		TYPE_BOOL:
			num_value.visible = false
			text_value.visible = false
			bool_value.visible = true
			set_slot_type_right(0, SlotConnectionType.VAR_BOOL)
			set_slot_color_right(0, COLORS["bool"])
			menu.icon = get_theme_icon("bool", "EditorIcons")
		TYPE_STRING:
			num_value.visible = false
			text_value.visible = true
			bool_value.visible = false
			set_slot_type_right(0, SlotConnectionType.VAR_STRING)
			set_slot_color_right(0, COLORS["string"])
			menu.icon = get_theme_icon("String", "EditorIcons")
			_resize_text_entry.call_deferred()
	
	_mode = to
	return true


func set_value(value: Variant) -> void:
	var val_type: int = typeof(value)
	
	match val_type:
		TYPE_INT, TYPE_FLOAT:
			num_value.set_value_no_signal(value)
			num_value.set_meta(&"old_value", num_value.value)
		TYPE_BOOL:
			bool_value.set_pressed_no_signal(value)
		TYPE_STRING:
			text_value.text = value
			text_value.set_meta(&"old_value", value)
			if text_value.visible:
				_resize_text_entry.call_deferred()


func _get_node_data() -> Dictionary:
	var metadata: Dictionary = {
		"value": get_current_value()}
	var output_connections: Dictionary = {
		"next_node": get_uuid_and_port_connected_to(
				PortMode.OUTPUT,
				0)}
	return _build_node_data(metadata, output_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if not metadata.has("value") or typeof(metadata["value"]) == TYPE_NIL:
		return
	
	if set_mode(typeof(metadata["value"])):
		set_value(metadata["value"])


func _on_data_type_selected(type: int) -> void:
	if type == _mode:
		return
	
	var old_state: Dictionary = {
		"output_connections": {"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)},
		"metadata": {"value": get_current_value()}}
	
	if has_any_output(0):
		var target: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, 0)
		var port_type: int = target.get_input_port_type(get_target_port_connected_to_self(PortMode.OUTPUT, 0))
		
		if not is_port_type_value_compatible(port_type, type):
			disconnect_port(PortMode.OUTPUT, 0)
	
	set_mode(type)
	
	var new_state: Dictionary = {
		"output_connections": {"next_node": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)},
		"metadata": {"value": get_current_value()}}
	
	data_type_changed.emit(
			get_node_uuid(),
			old_state,
			new_state)


func _on_num_value_changed(value: float) -> void:
	var old_value: float = num_value.get_meta(&"old_value")
	
	num_value.set_meta(&"old_value", value)
	
	value_changed.emit(
		get_node_uuid(),
		int(old_value) if _mode == TYPE_INT else old_value,
		int(value) if _mode == TYPE_INT else value)


func _on_text_field_text_changed() -> void:
	_resize_text_entry()
	node_updated.emit()


func _on_text_value_focus_exited() -> void:
	var old_value: String = text_value.get_meta(&"old_value")
	
	if text_value.text == old_value:
		return
	
	text_value.set_meta(&"old_value", text_value.text)
	value_changed.emit(
			get_node_uuid(),
			old_value,
			text_value.text)


func _on_bool_value_toggled(is_toggled: bool) -> void:
	value_changed.emit(
			get_node_uuid(),
			not is_toggled,
			is_toggled)


func _resize_text_entry() -> void:
	var lines: int = mini(text_value.get_total_visible_line_count(), MAX_LINES)
	var new_height: float = lines * text_value.get_line_height() + EXTRA_Y_PADDING
	if new_height < size.y:
		_reset_height.call_deferred()
	text_value.custom_minimum_size.y = new_height


func _reset_height() -> void:
	size.y = 0


func is_port_type_value_compatible(port_type: int, value: int) -> bool:
	if port_type == SlotConnectionType.VAR_ANY:
		return true
	elif port_type == SlotConnectionType.VAR_INT and value == TYPE_INT:
		return true
	elif port_type == SlotConnectionType.VAR_FLOAT and value == TYPE_FLOAT:
		return true
	elif port_type == SlotConnectionType.VAR_BOOL and value == TYPE_BOOL:
		return true
	elif port_type == SlotConnectionType.VAR_STRING and value == TYPE_STRING:
		return true
	else:
		return false


func get_current_value(default: Variant = null) -> Variant:
	match _mode:
		TYPE_INT:
			return int(num_value.value)
		TYPE_FLOAT:
			return num_value.value
		TYPE_BOOL:
			return bool_value.button_pressed
		TYPE_STRING:
			return text_value.text
		_:
			return default


func clamp_range(min_value: float, max_value: float, allow_lesser: bool = false, allow_greater: bool = false) -> void:
	num_value.min_value = min_value
	num_value.max_value = max_value
	num_value.allow_lesser = allow_lesser
	num_value.allow_greater = allow_greater
	
	if not allow_greater and not allow_lesser:
		num_value.set_value_no_signal(clampf(
				num_value.value,
				min_value,
				max_value))
	elif not allow_lesser:
		num_value.set_value_no_signal(maxf(
				min_value,
				num_value.value))
	elif not allow_greater:
		num_value.set_value_no_signal(minf(
				num_value.value,
				max_value))


func get_mode() -> int:
	return _mode
