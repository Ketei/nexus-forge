@tool
extends DiscourseGraphNode


const ARG_CONTAINER = preload("res://addons/nexus_forge/tools/discourse/scenes/call_node/arg_container.tscn")
const MINI_SIZE := Vector2(175, 90)

var minimize_button: Button
var minimized: bool = false

@onready var callables_option_button: OptionButton = $CallContainer/CallablesOptionButton
@onready var args_container: VBoxContainer = $ArgsContainer
@onready var call_label: Label = $CallContainer/CallLabel


func _ready() -> void:
	callables_option_button.clear()
	node_type = DialogData.DialogType.CALL
	create_output_connection("result", 0)
	var current_idx: int = -1
	
	for callable in NexusForge.Callables.get_callable_ids(true): #return_callables:
		current_idx += 1
		callables_option_button.add_item(NexusForge.Callables.get_callable_name(callable, true)) #(return_callables[callable]["name"])
		callables_option_button.set_item_metadata(current_idx, callable)
	
	if -1 < current_idx:
		callables_option_button.select(0)
		on_callable_selected(0)
	
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
	
	callables_option_button.item_selected.connect(on_callable_selected)
	

func on_callable_selected(callable_selected: int) -> void:
	for child in args_container.get_children():
		child.visible = false
		child.free()
	
	for arg:Dictionary in NexusForge.Callables.get_callable_args(callables_option_button.get_item_metadata(callable_selected), true): #return_callables[callables_option_button.get_item_metadata(callable_selected)]["args"]:
		var new_arg = ARG_CONTAINER.instantiate()
		args_container.add_child(new_arg)
		new_arg.set_arg_type(arg["type"])
		new_arg.var_label.text = arg["name"]
		new_arg.current_value_updated.connect(on_arg_updated)
	
	size.y = 90 + (args_container.get_child_count() * 39)
	node_updated.emit()


func on_arg_updated() -> void:
	node_updated.emit()


func select_by_key(callable_key: String) -> void:
	for item_idx in range(callables_option_button.item_count):
		if callables_option_button.get_item_metadata(item_idx) == callable_key:
			callables_option_button.select(item_idx)
			on_callable_selected(item_idx)
			break


func set_args(args: Array) -> void:
	var max_arg: int = args.size() - 1
	
	if max_arg < 0:
		return
	
	for arg_idx in range(args_container.get_child_count()):
		args_container.get_child(arg_idx).set_arg_value(args[mini(arg_idx, max_arg)]["value"])


func on_minimize_pressed() -> void:
	minimize_button.release_focus()
	
	if minimized:
		maximize()
	else:
		minimize()
	
	minimized = not minimized
	node_updated.emit()


func minimize() -> void:
	call_label.text = callables_option_button.get_item_text(callables_option_button.selected)
	callables_option_button.visible = false
	args_container.visible = false
	size = MINI_SIZE


func maximize() -> void:
	call_label.text = "Callable"
	callables_option_button.visible = true
	args_container.visible = true
	size.x = 300
	size.y = 90 + (args_container.get_child_count() * 39)


func _is_root() -> bool:
	return not has_output_connection("result")


func generate_node_dictionary() -> Dictionary:
	var call_structure: Dictionary = NFDiscourseTool.get_call_structure()
	var call_id: String = ""
	
	if callables_option_button.selected != -1:
		call_id = callables_option_button.get_item_metadata(callables_option_button.selected)

	call_structure["call_id"] =  call_id
	call_structure["offset"] = position_offset
	call_structure["is_return"] = true
	call_structure["expand"] = not minimized
	
	for argument in args_container.get_children():
		call_structure["args"].append(argument.get_argument())
	
	return call_structure
