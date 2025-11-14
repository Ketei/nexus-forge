@tool
extends PanelContainer


signal create_resource_pressed
signal load_resource_pressed
signal resource_dropped(resourse: Resource)

@export var message_minimum_size: Vector2 = Vector2(250.0, 0):
	get():
		return $CenterContainer/InfoContainer.custom_minimum_size
	set(new_size):
		$CenterContainer/InfoContainer.custom_minimum_size = new_size

var resource_class: StringName = &""

@onready var create_db_button: Button = $CenterContainer/InfoContainer/ButtonsContainer/CreateDBButton
@onready var load_db_button: Button = $CenterContainer/InfoContainer/ButtonsContainer/LoadDBButton
@onready var info_label: RichTextLabel = $CenterContainer/InfoContainer/InfoLabel



func _ready() -> void:
	create_db_button.icon = get_theme_icon("New", "EditorIcons")
	load_db_button.icon = get_theme_icon("Load", "EditorIcons")
	load_db_button.pressed.connect(load_resource_pressed.emit)
	create_db_button.pressed.connect(create_resource_pressed.emit)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has_all(["type", "files"]) and typeof(data["type"]) == TYPE_STRING and data["type"] == "files" and typeof(data["files"]) == TYPE_PACKED_STRING_ARRAY and data["files"].size() == 1


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var res_load: Resource = load(data["files"][0])
	if res_load != null and res_load.get_script().get_global_name() == resource_class:
		resource_dropped.emit(res_load)


func set_resource_type(res_class: String, tool_type: String, res_name: String) -> void:
	resource_class = StringName(res_class)
	info_label.text = "{0} uses a resource of type [color=AQUAMARINE]{1}[/color] to store data. You can create one, load one or drop it here to use in your project. 

Only one resource can be used for the project.

The path to this resource will be saved to your project settings and loaded automatically next time you open the project.".format([tool_type, res_class])
	load_db_button.text = "Load {0}".format([res_name])
	create_db_button.text = "Create {0}".format([res_name])
