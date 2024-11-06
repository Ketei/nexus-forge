@tool
extends PanelContainer


@onready var info_container: Tree = %InfoContainer
@onready var clear_button: Button = $LogContainer/IssueContainer/ButtonsContainer/ClearButton
@onready var close_button: Button = $LogContainer/TitleContainer/CloseButton


func _ready() -> void:
	clear_button.pressed.connect(on_clear_pressed)
	close_button.pressed.connect(on_close_pressed)
	visible = false


func on_clear_pressed() -> void:
	clear_button.release_focus()
	info_container.clear_logs()


func on_close_pressed() -> void:
	close_button.release_focus()
	visible = false
