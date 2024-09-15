class_name DialogTextBox
extends Control


signal visible_characters_changed
## Emmited when all characters of the text have been displayed on the textbox.
signal text_displayed
signal progress_scene_pressed

@export var letter_reveal_time: float = 0.1 :
	set(new_time):
		letter_reveal_time = snappedf(new_time, 0.01)
@export_group("Text")
@export var progress_text: StringName = &"ui_accept"
@export_group("Sound")
@export var typing_sound: AudioStream
@export_group("Flags")
## When display_text is called if no name, the name label will hide.
@export var hide_name_when_empty: bool = true
## When display_text is called if no name, the portrailt will hide.
@export var hide_portrait_when_empty: bool = true

#var typing_paused: bool = false
var listening_to_input: bool = false:
	set(is_listening):
		listening_to_input = is_listening
		set_process_unhandled_key_input(is_listening)

@onready var dialog_text: RichTextLabel = %DialogTextBox
@onready var typing_audio_player: AudioStreamPlayer = %TypingAudioPlayer
@onready var actor_name_label: Label = %ActorNameLabel

@onready var portrait_texture_rect: PortraitTextureRect = %ActorPortrait

@onready var actor_name_container: PanelContainer = %ActorNameContainer
@onready var portrait_container: PanelContainer = %ActorPortraitContainer

var delta_elapsed: float = 0.0

func _ready() -> void:
	visible = false
	dialog_text.get_v_scroll_bar().step = dialog_text.size.y
	set_process(false)
	set_process_unhandled_key_input(false)
	visible_characters_changed.connect(_on_visible_characters_changed)
	#text_displayed.connect(on_text_displayed)
	
	#set_actor_name("Jules the Dragon")
	#await get_tree().create_timer(2.0).timeout
	#start_dialogue("GGhhkasjahd!!! T-THEY ARE TOO [color=RED][font_size=30][shake rate=20.0 level=20 connected=1]BIG!!!!![/shake][/font_size][/color]")


#func on_text_displayed() -> void:
	#print("I've finished talking")


func _process(delta: float) -> void:
	delta_elapsed += delta
	_evaluate_text_to_display()


func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(progress_text):
		if dialog_text.visible_ratio < 1:
			display_all_text()
		else:
			progress_scene_pressed.emit()


func open_dialog_box() -> void:
	actor_name_container.visible = !(hide_name_when_empty and actor_name_label.text.is_empty())
	portrait_container.visible = !(hide_portrait_when_empty and portrait_texture_rect.texture == null)
	visible = true


func close_dialog_box() -> void:
	visible = false


func start_dialogue() -> void:
	if 0.0 < letter_reveal_time:
		set_process(true)
	
	if dialog_text.visible_ratio == 1.0:
		text_displayed.emit()


func set_dialog_text(text_to_display: String) -> void:
	#dialog_text.clear()
	#dialog_text.parse_bbcode(text_to_display)
	dialog_text.text = text_to_display
	if 0.0 < letter_reveal_time:
		#dialog_text.call_deferred("visible_characters", 0)
		dialog_text.visible_characters = 0
	else:
		#dialog_text.call_deferred("visible_ratio", 1.0)
		dialog_text.visible_ratio = 1.0
	#dialog_text.queue_redraw()

## Returns true if the textbox is still displaying text. If paused it'll always
## return false.
func is_textbox_typing() -> bool:
	return dialog_text.visible_ratio < 1


## It'll display all the text on the textbox. Usefull to skip the text appearing
## over time.
func display_all_text() -> void:
	dialog_text.visible_ratio = 1.0


## Changes the name of the actor displayed.
func set_actor_name(new_name: String, label_settings:LabelSettings = null) -> void:
	actor_name_label.text = new_name
	actor_name_label.label_settings = label_settings


# Called only when 0 < letter_reveral_time.
func _on_visible_characters_changed() -> void:
	if not typing_audio_player.playing and typing_sound != null:
		typing_audio_player.play()
	
	if dialog_text.visible_ratio == 1.0:
		set_process(false)
		delta_elapsed = 0
		text_displayed.emit()


# Called only when 0 < letter_reveral_time.
func _evaluate_text_to_display() -> void:
	if letter_reveal_time == 0 or dialog_text.visible_ratio == 1.0:
		dialog_text.visible_ratio = 1.0
		visible_characters_changed.emit()
		return
	
	var letter_increase: float = floorf(delta_elapsed / letter_reveal_time)
	
	if 0 < letter_increase:
		delta_elapsed -= letter_increase * letter_reveal_time
		dialog_text.visible_characters += int(letter_increase)
		visible_characters_changed.emit()
