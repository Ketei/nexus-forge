@tool
extends PanelContainer


signal create_resource_pressed
signal load_resource_pressed


@onready var create_db_button: Button = $CenterContainer/InfoContainer/ButtonsContainer/CreateDBButton
@onready var load_db_button: Button = $CenterContainer/InfoContainer/ButtonsContainer/LoadDBButton
@onready var info_label: RichTextLabel = $CenterContainer/InfoContainer/InfoLabel


func _ready() -> void:
	load_db_button.pressed.connect(load_resource_pressed.emit)
	create_db_button.pressed.connect(create_resource_pressed.emit)


func set_resource_type(res_class: String, tool_type: String, res_name: String) -> void:
	info_label.text = "{0} uses a resource of type [color=AQUAMARINE]{1}[/color] to store data. You can create one or load one to use in your project. 

Only one resource can be used for the project.

The path to this resource will be saved to your project settings and loaded automatically next time you open the project.".format([tool_type, res_class])
	load_db_button.text = "Load {0} Resource".format([res_name])
	create_db_button.text = "Create {0} Resource".format([res_name])
