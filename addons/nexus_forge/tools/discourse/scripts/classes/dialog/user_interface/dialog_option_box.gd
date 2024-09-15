class_name DialogOption
extends Control


## The index of the option, used to identify what it is.
var option_id: int = 0

@onready var options_text: Label = $PanelContainer/OptionsText


## Called when the object is created to set the text.
func set_option_text(opt_text: String) -> void:
	options_text.text = opt_text


## Called when the option is focused and unfocused.
func option_focused(_is_focused: bool) -> void:
	pass


## Called by the OptionsControl when the option is selected.
func option_selected() -> void:
	pass
