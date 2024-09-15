# Dialog
extends DiscourseGraphNode

const DEFAULT_SIZE := Vector2(410,480)
const MINI_SIZE := Vector2(145, 180)

var minimized: bool = false
var minimize_button: Button

@onready var id_label: Label = $ConversationID/IDLabel
@onready var dialog_id_line: LineEdit = $ConversationID/DialogIDLine
@onready var text_edit: TextEdit = $DialogContainer/TextEdit
@onready var seconds_spin_box: SpinBox = $DialogContainer/OptionsContainer/SecondsPerLetter/SecondsSpinBox
@onready var pause_check_box: CheckBox = $DialogContainer/OptionsContainer/PauseCheckBox
@onready var options_container: HBoxContainer = $DialogContainer/OptionsContainer


func _ready() -> void:
	create_output_connection("next", 0)
	create_input_connection("next", 0)
	create_input_connection("character", 1)
	create_input_connection("signal", 2)
	create_input_connection("variables", 3)
	create_input_connection("call", 4)

	node_type = DialogData.DialogType.DIALOG
	
	var new_hbox_node := HBoxContainer.new()
	new_hbox_node.name = &"GraphButtonsNode"
	new_hbox_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_hbox_node.alignment = BoxContainer.ALIGNMENT_END
	
	minimize_button = Button.new()
	minimize_button.name = &"MinimizeButton"
	minimize_button.text = "-"
	minimize_button.flat = true
	minimize_button.custom_minimum_size = Vector2(32, 32)
	minimize_button.pressed.connect(on_minimize_pressed)
	
	
	var close_button := Button.new()
	close_button.name = &"CloseButton"
	close_button.text = "x"
	close_button.flat = true
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.pressed.connect(close_node)
	
	var title_bar: HBoxContainer = get_titlebar_hbox()
	title_bar.add_child(new_hbox_node)
	new_hbox_node.add_child(minimize_button)
	new_hbox_node.add_child(close_button)
	
	dialog_id_line.text_changed.connect(on_line_id_changed)


func on_line_id_changed(new_line: String) -> void:
	node_id = new_line


func minimize() -> void:
	if dialog_id_line.text.is_empty():
		id_label.text = "[NO ID]"
	else:
		id_label.text = dialog_id_line.text
	
	dialog_id_line.visible = false
	text_edit.visible = false
	options_container.visible = false
	size = MINI_SIZE


func maximize() -> void:
	id_label.text = "ID"
	dialog_id_line.visible = true
	text_edit.visible = true
	options_container.visible = true
	size = DEFAULT_SIZE


func on_minimize_pressed() -> void:
	minimize_button.release_focus()
	if minimized:
		maximize()
	else:
		minimize()
	
	minimized = not minimized


func _is_root() -> bool:
	return true


func generate_node_dictionary() -> Dictionary:
	var dialog_dict: Dictionary = DialogData.get_dialog_structure()
	if has_input_connection("character"):
		dialog_dict["character"] = get_input_port_connection_by_id("character").generate_node_dictionary()
	if has_input_connection("signal"):
		dialog_dict["signal"] = get_input_port_connection_by_id("signal").generate_node_dictionary()
	if has_input_connection("variables"):
		dialog_dict["set_variable"] = get_input_port_connection_by_id("variables").generate_node_dictionary()
	if has_input_connection("call"):
		dialog_dict["call"] = get_input_port_connection_by_id("call").generate_node_dictionary()
	if has_output_connection("next"):
		var next_dict: Dictionary = DialogData.get_next_structure()
		var next_node: DiscourseGraphNode = get_output_port_connection_by_id("next")
		var next_class: DialogData.NextType
		var next_dict_data: Dictionary
		
		if next_node.node_type == DialogData.DialogType.DIALOG or next_node.node_type == DialogData.DialogType.OPTIONS:
			next_class = DialogData.NextType.ID
			next_dict_data = DialogData.get_next_by_id()
			next_dict_data["next"] = next_node.node_id
			next_dict_data["use_shortcut"] = false
			next_dict_data["offset"] = next_node.position_offset
		elif next_node.node_type == DialogData.DialogType.ID:
			next_class = DialogData.NextType.ID
			next_dict_data = next_node.generate_node_dictionary()
		elif next_node.node_type == DialogData.DialogType.RANDOM:
			next_class = DialogData.NextType.RANDOM
			next_dict_data = next_node.generate_node_dictionary()
		elif next_node.node_type == DialogData.DialogType.CONDITION:
			next_class = DialogData.NextType.CONDITION
			next_dict_data = next_node.generate_node_dictionary()
		elif next_node.node_type == DialogData.DialogType.END:
			next_class = DialogData.NextType.END
			next_dict_data = next_node.generate_node_dictionary()
		
		next_dict["type"] = next_class
		next_dict["data"] = next_dict_data
		dialog_dict["next"] = next_dict
	
	dialog_dict["dialog"]["text"] = text_edit.text
	dialog_dict["dialog"]["seconds_per_letter"] = seconds_spin_box.value
	dialog_dict["pause"] = pause_check_box.button_pressed
	dialog_dict["offset"] = position_offset
	
	return dialog_dict
