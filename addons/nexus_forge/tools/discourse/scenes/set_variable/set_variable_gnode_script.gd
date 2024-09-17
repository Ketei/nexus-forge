extends DiscourseGraphNode

const SER_VARIABLE_CONTAINER = preload("res://addons/nexus_forge/tools/discourse/scenes/set_variable/ser_variable_container.tscn")
const MAXI_SIZE := Vector2(370, 280)
const MINI_SIZE := Vector2(175, 90)

var minimized: bool = false
var minimize_button: Button

@onready var add_var_button: Button = $SetVarLabel/AddVarButton
@onready var variables_container: VBoxContainer = $ScrollContainer/VariablesContainer
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var set_var_label: Label = $SetVarLabel


func _ready() -> void:
	node_type = DialogData.DialogType.VARIABLES
	create_output_connection("variables", 0)
	add_var_button.pressed.connect(on_add_variable)
	
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


func minimize() -> void:
	set_var_label.text = str("Variables (", variables_container.get_child_count(), ")")
	add_var_button.visible = false
	scroll_container.visible = false
	size = MINI_SIZE


func maximize() -> void:
	set_var_label.text = "Variables"
	add_var_button.visible = true
	scroll_container.visible = true
	size = MAXI_SIZE


func on_minimize_pressed() -> void:
	minimize_button.release_focus()
	if minimized:
		maximize()
	else:
		minimize()
	
	minimized = not minimized
	node_updated.emit()


func on_add_variable() -> void:
	var new_var: HBoxContainer = SER_VARIABLE_CONTAINER.instantiate()
	variables_container.add_child(new_var)
	new_var.close_requested.connect(on_node_remove_requested)
	node_updated.emit()


func add_variable_type(variable_name: String, value: Variant) -> void:
	var new_var: HBoxContainer = SER_VARIABLE_CONTAINER.instantiate()
	var type: int = typeof(value)
	
	variables_container.add_child(new_var)
	
	new_var.var_name_line.text = variable_name
	
	if type == TYPE_BOOL:
		new_var.on_var_type_selected(2)
		new_var.bool_var_node.button_pressed = value
	elif type == TYPE_INT:
		new_var.on_var_type_selected(0)
		new_var.val_var_node.value = value
	elif type == TYPE_FLOAT:
		new_var.on_var_type_selected(1)
		new_var.val_var_node.value = value
	elif type == TYPE_STRING:
		new_var.on_var_type_selected(3)
		new_var.str_val_node.text = value


func _is_root() -> bool:
	return not has_output_connection("variables")


func generate_node_dictionary() -> Dictionary:
	var new_val_data: Dictionary = DialogData.get_set_var_structure()
	new_val_data["offset"] = position_offset
	new_val_data["expand"] = not minimized
	
	for set_var in variables_container.get_children():
		new_val_data["variables"][set_var.get_variable_path()] = set_var.get_variable_value()
	
	return new_val_data


func on_node_remove_requested(node: Control) -> void:
	node.queue_free()
	node_updated.emit()
