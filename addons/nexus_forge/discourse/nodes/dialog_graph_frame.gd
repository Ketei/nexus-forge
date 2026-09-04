@tool
extends GraphFrame


signal close_frame_requested(uuid: StringName)
signal frame_title_changed(uuid: StringName, from: String, to: String)
signal frame_color_changed(uuid: StringName, from: Color, to: Color)

var last_click_time: int = 0
var label_editor: LineEdit = null
var _uuid: String = ""
var starting_color: Color
var color_picker: ColorPickerButton


func _init(uuid: String = "") -> void:
	_uuid = UUID.generate_new() if uuid.is_empty() else uuid
	var title_frame: HBoxContainer = get_titlebar_hbox()
	var title_label: Label = title_frame.get_child(0)
	var centering_spacer: Control = Control.new()
	label_editor = LineEdit.new()
	color_picker = ColorPickerButton.new()
	var color_picker_icon: TextureRect = TextureRect.new()
	var close_button: Button = Button.new()
	var buttons_container: HBoxContainer = HBoxContainer.new()
	
	set_process_input(false)
	
	tint_color_enabled = true
	tint_color = Color(0.0, 0.0, 0.0, 0.588)
	starting_color = Color(0.0, 0.0, 0.0, 0.588)
	custom_minimum_size = Vector2(200, 200)
	size = Vector2(200, 200)
	
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	centering_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centering_spacer.custom_minimum_size = Vector2(72.0, 32.0)
	
	# Ensuring there is ALWAYS an area to click
	title_label.custom_minimum_size.y = 32.0
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# ----
	# Enabling label to signal for clicks
	title_label.focus_mode = Control.FOCUS_CLICK
	title_label.mouse_filter = Control.MOUSE_FILTER_PASS
	# ----
	
	title_label.focus_entered.connect(_on_label_clicked.bind(title_label, label_editor))
	
	label_editor.placeholder_text = "Frame Title"
	label_editor.flat = true
	label_editor.caret_blink = true
	label_editor.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	label_editor.alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_editor.visible = false
	label_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	color_picker.name = &"ColorPickerBtn"
	color_picker.tooltip_text = "Frame tint color"
	color_picker.custom_minimum_size = Vector2(32.0, 32.0) # 32 is the title height
	color_picker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	color_picker.color_changed.connect(_on_color_changed)
	color_picker.popup_closed.connect(_on_color_popup_closed)
	color_picker.color = Color(0.0, 0.0, 0.0, 0.588) # Default tint from frame
	
	color_picker.self_modulate = Color.TRANSPARENT
	
	color_picker_icon.name = &"ColorPickerTextureRect"
	color_picker_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	color_picker_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	color_picker_icon.custom_minimum_size = Vector2(16.0, 16.0)
	color_picker_icon.position = Vector2(8.0, 8.0)
	color_picker_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_picker.add_child(color_picker_icon)
	
	close_button.name = &"CloseFrameBtn"
	close_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_button.expand_icon = true
	close_button.custom_minimum_size = Vector2(32.0, 32.0) # 32 is the title height
	close_button.flat = true
	close_button.tooltip_text = "Remove frame"
	close_button.add_theme_constant_override(&"icon_max_width", 16)
	
	buttons_container.name = &"ButtonContainerHBox"
	buttons_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	buttons_container.add_child(color_picker)
	buttons_container.add_spacer(false)
	buttons_container.add_child(close_button)
	
	title_frame.add_child(centering_spacer)
	title_frame.move_child(centering_spacer, 0)
	title_frame.add_child(label_editor)
	title_frame.add_child(buttons_container)
	
	label_editor.editing_toggled.connect(_on_label_editor_edit_toggled.bind(title_label))
	
	close_button.pressed.connect(_on_close_frame_pressed)


func _ready() -> void:
	var title_frame: HBoxContainer = get_titlebar_hbox()
	var container: HBoxContainer = title_frame.get_node_or_null(^"ButtonContainerHBox")
	if container == null:
		return
	var color_picker: ColorPickerButton = container.get_node_or_null(^"ColorPickerBtn")
	var close_button: Button = container.get_node_or_null(^"CloseFrameBtn")
	if close_button != null:
		close_button.icon = get_theme_icon("Close", "EditorIcons")
	
	if color_picker != null:
		color_picker.icon = get_theme_icon("ColorPick", "EditorIcons")
		var color_picker_icon: TextureRect = color_picker.get_node_or_null(^"ColorPickerTextureRect")
		if color_picker_icon != null:
			color_picker_icon.texture = get_theme_icon("ColorPick", "EditorIcons")


func _on_color_button_pressed(color_button: Button, color_picker: ColorPicker) -> void:
	color_picker.global_position = color_button.global_position + color_button.size
	color_picker.visible = true


func _on_label_clicked(title_label: Label, title_edit: LineEdit) -> void:
	var click_time: int = Time.get_ticks_msec()
	var time_diff: int = click_time - last_click_time
	last_click_time = click_time
	if 500 < time_diff:
		title_label.release_focus()
		return
	title_label.visible = false
	title_edit.visible = true
	title_edit.grab_focus(true)
	title_edit.edit(true)
	title_edit.text = title_label.text
	title_edit.caret_column = title_edit.text.length()
	title_edit.select_all()


func _on_label_editor_edit_toggled(is_toggled: bool, label: Label) -> void:
	if is_toggled:
		return
	label_editor.visible = false
	label.visible = true
	
	var old_title: String = title
	var new_title: String = label_editor.text.strip_edges()
	
	if new_title == old_title:
		return
	
	title = new_title
	frame_title_changed.emit(get_frame_uuid(), old_title, new_title)


func _on_color_changed(color: Color) -> void:
	tint_color = color


func _on_color_popup_closed() -> void:
	var old_color: Color = starting_color
	var new_color: Color = color_picker.color
	
	if new_color == old_color:
		return
	starting_color = new_color
	
	frame_color_changed.emit(
		get_frame_uuid(),
		old_color,
		new_color)


func _on_close_frame_pressed() -> void:
	close_frame_requested.emit(get_frame_uuid())


func get_frame_data() -> Dictionary:
	return {
		"size": size,
		"position": position_offset,
		"tint_color": tint_color,
		"title": title}


func get_frame_uuid() -> String:
	return _uuid


func set_frame_tint(tint: Color) -> void:
	tint_color = tint
	starting_color = tint


func set_frame_data(data: Dictionary) -> void:
	var tint = data.get("tint_color")
	if typeof(tint) == TYPE_COLOR:
		color_picker.color = tint
		tint_color = tint
	
	var pos_offset = data.get("position")
	if typeof(pos_offset) == TYPE_VECTOR2:
		position_offset = pos_offset
	
	var _title = data.get("title")
	if typeof(_title) == TYPE_STRING:
		title = _title
	
	var _size = data.get("size")
	if typeof(_size) == TYPE_VECTOR2:
		size = _size
