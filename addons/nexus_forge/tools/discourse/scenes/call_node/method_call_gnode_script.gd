@tool
extends DiscourseGraphNode

const ARG_CONTAINER = preload("res://addons/nexus_forge/tools/discourse/scenes/call_node/arg_container.tscn")

const MINI_SIZE := Vector2(175, 90)

var minimized: bool = false
var minimize_button: Button

@onready var callable_option: OptionButton = $ObjectContainer/CallableOption
@onready var args_container: VBoxContainer = $ArgsContainer
@onready var label: Label = $ObjectContainer/Label


func _ready() -> void:
	callable_option.clear()
	node_type = DialogData.DialogType.CALL
	create_output_connection("call", 0)
	
	var current_idx: int = -1
	
	for callable in NexusForge.Callables.get_callable_ids():
		current_idx += 1
		callable_option.add_item(NexusForge.Callables.get_callable_name(callable, false))
		callable_option.set_item_metadata(current_idx, callable)
	
	if -1 < current_idx:
		callable_option.select(0)
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
	
	callable_option.item_selected.connect(on_callable_selected)


func on_callable_selected(callable_selected: int) -> void:
	for child in args_container.get_children():
		child.visible = false
		child.free()
	
	for arg:Dictionary in NexusForge.Callables.get_callable_args(callable_option.get_item_metadata(callable_selected), false):
		var new_arg = ARG_CONTAINER.instantiate()
		args_container.add_child(new_arg)
		new_arg.set_arg_type(arg["type"])
		new_arg.var_label.text = arg["name"]
		new_arg.current_value_updated.connect(on_arg_updated)
	
	size.y = 80 + (args_container.get_child_count() * 39)
	node_updated.emit()


func on_arg_updated() -> void:
	node_updated.emit()


func select_by_key(callable_key: String) -> void:
	for item_idx in range(callable_option.item_count):
		if callable_option.get_item_metadata(item_idx) == callable_key:
			callable_option.select(item_idx)
			on_callable_selected(item_idx)
			break


#func select_by_callable(object: String, method: String) -> void:
	#if object.is_empty() or method.is_empty():
		#return
	#
	#for item_idx in range(callable_option.item_count):
		#var key: String = callable_option.get_item_metadata(item_idx)
		#if callables[key]["callable"]["object"] == object and callables[key]["callable"]["method"] == method:
			#callable_option.select(item_idx)
			#on_callable_selected(item_idx)
			#break


func set_args(args: Array) -> void:
	var max_arg: int = args.size() - 1
	
	if max_arg < 0:
		return
	
	for arg_idx in range(args_container.get_child_count()):
		args_container.get_child(arg_idx).set_arg_value(args[mini(arg_idx, max_arg)])


func on_minimize_pressed() -> void:
	minimize_button.release_focus()
	
	if minimized:
		maximize()
	else:
		minimize()
	
	minimized = not minimized
	node_updated.emit()


func minimize() -> void:
	label.text = callable_option.get_item_text(callable_option.selected)
	callable_option.visible = false
	args_container.visible = false
	size = MINI_SIZE


func maximize() -> void:
	label.text = "Callable"
	callable_option.visible = true
	args_container.visible = true
	size.x = 300
	size.y = 80 + (args_container.get_child_count() * 39)


func _is_root() -> bool:
	return not has_output_connection("call")


func generate_node_dictionary() -> Dictionary:
	var call_structure: Dictionary = NFDiscourseTool.get_call_structure()
	var call_id: String = ""
	#var method: String = ""
	
	if callable_option.selected != -1:
		call_id = callable_option.get_item_metadata(callable_option.selected)

	call_structure["call_id"] =  call_id
	call_structure["offset"] = position_offset
	call_structure["is_return"] = false
	call_structure["expand"] = not minimized
	
	for arg_idx in range(args_container.get_child_count()):
		call_structure["args"].append(
				args_container.get_child(arg_idx).get_argument())
	return call_structure
