extends PanelContainer


@onready var dialog_text_edit: TextEdit = $MainSplitContainer/ParsedBox/DialogOptionSplit/DialogBox/DialogTextEdit
@onready var continue_btn: Button = $MainSplitContainer/ParsedBox/DialogOptionSplit/DialogBox/ContinueBtn
@onready var options_container: VBoxContainer = $MainSplitContainer/ParsedBox/DialogOptionSplit/OptionsContainer
@onready var options_tree: Tree = $MainSplitContainer/ParsedBox/DialogOptionSplit/OptionsContainer/OptionsTree
@onready var data_text_edit: TextEdit = $MainSplitContainer/DataSplit/DataContainer/DataTextEdit
@onready var events_text_edit: TextEdit = $MainSplitContainer/DataSplit/EventsContainer/EventsTextEdit
@onready var clear_data_btn: Button = $MainSplitContainer/DataSplit/DataContainer/ClearDataBtn
@onready var clear_events_btn: Button = $MainSplitContainer/DataSplit/EventsContainer/ClearEventsBtn


func _ready() -> void:
	options_tree.set_column_title(0, "Text")
	options_tree.set_column_title(1, "Status")
	
	options_tree.set_column_expand(0, true)
	options_tree.set_column_expand(1, true)
	
	options_tree.set_column_expand_ratio(0, 3)
	options_tree.set_column_expand_ratio(1, 1)
	
	options_tree.create_item()
	
	options_container.visible = false
	
	var success: bool = false
	
	if NexusForge.Discourse == null:
		NexusForge.Discourse = EditorDialogParser.new()
	
	if FileAccess.file_exists("user://nexus_forge/discourse_settings.cfg"):
		var cfg: ConfigFile = ConfigFile.new()
		cfg.load("user://nexus_forge/discourse_settings.cfg")
		if cfg.has_section_key("Discourse", "active_scene"):
			var path: String = cfg.get_value("Discourse", "active_scene", "")
			if not path.is_empty() and FileAccess.file_exists(path):
				success = true
				load_dialog(path)
	
	if success:
		continue_btn.grab_focus()
	else:
		continue_btn.disabled = not success
		events_text_edit.text = "[ERROR] Dialog resource not found"
	
	continue_btn.pressed.connect(_on_continue_pressed)
	options_tree.button_clicked.connect(_on_option_button_clicked)
	options_tree.item_activated.connect(_on_option_activated)
	clear_data_btn.pressed.connect(_on_clear_data_pressed)
	clear_events_btn.pressed.connect(_on_clear_events_pressed)
	NexusForge.Discourse.dialog_reached.connect(_on_dialog_reached)
	NexusForge.Discourse.options_reached.connect(_on_options_reached)
	NexusForge.Discourse.dialog_started.connect(_on_dialog_started)
	NexusForge.Discourse.dialog_paused.connect(_on_dialog_paused)
	NexusForge.Discourse.dialog_finished.connect(_on_dialog_finished)
	NexusForge.Discourse.data_set.connect(_on_data_set)
	NexusForge.Discourse.method_called.connect(_on_method_called)
	NexusForge.Discourse.signal_emmited.connect(_on_signal_emmited)


func _on_clear_data_pressed() -> void:
	data_text_edit.text = ""


func _on_clear_events_pressed() -> void:
	events_text_edit.text = ""


func _on_dialog_reached(data: Dictionary) -> void:
	data_text_edit.text += var_to_str(data) + "\n----------\n"
	data_text_edit.set_deferred("scroll_vertical", data_text_edit.get_v_scroll_bar().max_value)
	var displayed_text: String = ""
	if not data["character_id"].is_empty():
		displayed_text = data["character_id"] + ": "
	displayed_text += data["dialog_text"]
	
	dialog_text_edit.text = displayed_text


func _on_options_reached(options: Array[Dictionary]) -> void:
	data_text_edit.text += var_to_str(options) + "\n----------\n"
	data_text_edit.set_deferred("scroll_vertical", data_text_edit.get_v_scroll_bar().max_value)
	clear_options()
	for option in options:
		add_option(option["text"], option["unlocked"], option["target"])
	
	if options.is_empty():
		events_text_edit.text += "[WARNING] No options were received\n"
	else:
		options_tree.grab_focus()
		options_tree.get_root().get_first_child().select(0)
		continue_btn.disabled = true
		options_container.visible = true


func _on_option_activated() -> void:
	var selected: TreeItem = options_tree.get_selected()
	if selected == null:
		return
	NexusForge.Discourse.set_dialog_id(selected.get_metadata(0))
	NexusForge.Discourse.next_dialog()
	options_container.visible = false
	continue_btn.disabled = false
	continue_btn.grab_focus()


func _on_option_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		NexusForge.Discourse.set_dialog_id(item.get_metadata(0))
		NexusForge.Discourse.next_dialog()
		options_container.visible = false
		continue_btn.disabled = false
		continue_btn.grab_focus()


func _on_continue_pressed() -> void:
	NexusForge.Discourse.next_dialog()


func _on_data_set(path: String, data: Variant) -> void:
	events_text_edit.text += str("Variable on path ", path, " set to ", var_to_str(data), "\n")


func _on_method_called(method_string: String, arguments: Array) -> void:
	events_text_edit.text += str(
			"[EVENT] Method ",
			method_string,
			" called with arguments: ",
			var_to_str(arguments),
			"\n")


func _on_signal_emmited(signal_name: String, arguments: Array) -> void:
	events_text_edit.text += str(
			"[EVENT] Signal ",
			signal_name,
			" emmited with arguments ",
			arguments,
			"\n")
	
	events_text_edit.set_deferred("scroll_vertical", events_text_edit.get_v_scroll_bar().max_value)


func _on_dialog_started() -> void:
	events_text_edit.text += "[SIGNAL] Dialog started\n"
	continue_btn.text = "Continue Dialog"
	events_text_edit.set_deferred("scroll_vertical", events_text_edit.get_v_scroll_bar().max_value)


func _on_dialog_paused() -> void:
	events_text_edit.text += "[SIGNAL] Dialog paused\n"
	events_text_edit.set_deferred("scroll_vertical", events_text_edit.get_v_scroll_bar().max_value)


func _on_dialog_finished() -> void:
	events_text_edit.text += "[SIGNAL] Dialog finished\n"
	dialog_text_edit.text = ""
	continue_btn.text = "Start Dialog"
	events_text_edit.set_deferred("scroll_vertical", events_text_edit.get_v_scroll_bar().max_value)


func load_dialog(dialog_path: String) -> void:
	if NexusForge.Discourse.load_dialog(dialog_path):
		events_text_edit.text += "[INFO] Dialog loaded: " + dialog_path + "\n"
	else:
		events_text_edit.text += "[ERROR] Dialog couldn't be loaded\n"
	events_text_edit.set_deferred("scroll_vertical", events_text_edit.get_v_scroll_bar().max_value)


func add_option(text: String, unlocked: bool, target: StringName) -> void:
	var new_opt: TreeItem = options_tree.get_root().create_child()
	new_opt.set_text(0, text)
	new_opt.set_text(1, "Unlocked" if unlocked else "Locked")
	new_opt.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	new_opt.set_metadata(0, target)
	new_opt.add_button(
			1,
			preload("res://addons/nexus_forge/icons/right_arrow.png"),
			0,
			false,
			"Go to option")


func clear_options() -> void:
	for child in options_tree.get_root().get_children():
		child.free()
