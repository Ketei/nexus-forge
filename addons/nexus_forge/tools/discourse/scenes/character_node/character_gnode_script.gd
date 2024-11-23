@tool
extends DiscourseGraphNode


const MAXI_SIZE := Vector2(360, 155)
const MINI_SIZE := Vector2(175, 80)

var minimize_button: Button
var minimized: bool = false

@onready var id_label: Label = $ChararacterID/IDLabel
@onready var moods: HBoxContainer = $Moods

@onready var char_id_line: LineEdit = $ChararacterID/CharIDLine
@onready var idle_line: LineEdit = $Moods/IdleAnimContainer/IdleLine
@onready var play_idle_check_button: CheckBox = $Moods/IdleAnimContainer/PlayIdleCheckButton
@onready var talking_idle: LineEdit = $Moods/TalkAnimContainer/TalkingIdle
@onready var play_talking_check_button: CheckBox = $Moods/TalkAnimContainer/PlayTalkingCheckButton


func _ready() -> void:
	node_type = DialogData.DialogType.CHARACTER
	create_output_connection("character", 0)
	
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
	
	char_id_line.text_changed.connect(on_text_changed)
	idle_line.text_changed.connect(on_text_changed)
	talking_idle.text_changed.connect(on_text_changed)
	play_idle_check_button.toggled.connect(on_button_toggled)
	play_talking_check_button.toggled.connect(on_button_toggled)


func on_minimize_pressed() -> void:
	minimize_button.release_focus()
	if minimized:
		maximize()
	else:
		minimize()
	minimized = not minimized
	node_updated.emit()


func minimize() -> void:
	if char_id_line.text.is_empty():
		id_label.text = "[NO ID]"
	else:
		id_label.text = char_id_line.text
	
	char_id_line.visible = false
	moods.visible = false
	
	size = MINI_SIZE


func maximize() -> void:
	id_label.text = "Character ID"
	
	char_id_line.visible = true
	moods.visible = true
	
	size = MAXI_SIZE 


func _is_root() -> bool:
	return not has_output_connection("character")


func generate_node_dictionary() -> Dictionary:
	var character_structure: Dictionary = NFDiscourseTool.get_character_structure()
	character_structure["id"] = char_id_line.text
	character_structure["idle"]["animation"] = idle_line.text
	character_structure["idle"]["play"] = play_idle_check_button.button_pressed
	character_structure["talking"]["animation"] = talking_idle.text
	character_structure["talking"]["play"] = play_talking_check_button.button_pressed
	character_structure["offset"] = position_offset
	character_structure["expand"] = not minimized
	return character_structure


func on_text_changed(_new_text: String) -> void:
	node_updated.emit()


func on_button_toggled(_is_toggled: bool) -> void:
	node_updated.emit()
