@tool
extends DiscourseGraphNode


const ICON_BOOL = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const ICON_FLOAT = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const ICON_INT = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const ICON_STRING = preload("res://addons/nexus_forge/common_icons/variables/string.svg")

var arg_nodes: Array[Control] = []
@onready var call_opt_btn: OptionButton = $CallContainer/CallOptBtn
@onready var return_texture: TextureRect = $CallContainer/ReturnTexture


func _ready() -> void:
	graph_type = GraphType.RETURN_CALL
	register_output_connection("value", 0, true)
	
	var idx: int = -1
	
	for call_id in NexusForge.Callables.get_callable_return_ids():
		idx += 1
		call_opt_btn.add_item(
				NexusForge.Callables.get_callable_return_name(call_id))
		call_opt_btn.set_item_metadata(idx, call_id)
	
	if idx != -1:
		on_call_idx_selected(0)
	
	add_utility()
	
	call_opt_btn.item_selected.connect(on_call_idx_selected)


func _connection_set(is_input: bool, connection_id: String, node: DiscourseGraphNode) -> void:
	if is_input:
		var con_id: int = int(connection_id)
		set_arg_enabled(con_id - 1, node == null)
		if node != null and node.graph_type == GraphType.VALUE:
			var val_node: DiscourseGraphNode = get_input_connections(connection_id)[0]
			val_node.set_type(val_node.op_native_to_type(get_arg_type(con_id - 1)), true)


func _get_node_data() -> Dictionary:
	var args: Array[Dictionary] = []
	
	for arg_idx in range(arg_nodes.size()):
		args.append(
			{
				"id": -1 if not has_any_output_connection(str(arg_idx + 1)) else get_output_connections(str(arg_idx + 1))[0].node_id,
				"value": get_node_value(arg_nodes[arg_idx])
			}
		)
	
	return {
		"_type": graph_type,
		"_offset": position_offset,
		"call_id": "" if call_opt_btn.selected == -1 else call_opt_btn.get_item_metadata(call_opt_btn.selected),
		"call_args": args
	}


func _is_orphan() -> bool:
	if has_any_output_connection("value"):
		return get_output_connections("value")[0]._is_orphan()
	return true


func on_call_idx_selected(idx: int) -> void:
	for arg_idx in range(arg_nodes.size()):
		var arg_id: String = str(arg_idx + 1)
		
		if has_any_input_connection(arg_id):
			var from := get_input_connections(arg_id)
			disconnect_signaled.emit(
					from[0].name,
					from[0].get_output_connection_port_by_id("value"),
					name,
					get_input_port(arg_id))
			disconnect_input_node(arg_id, from[0])
		arg_nodes[arg_idx].visible = false
		arg_nodes[arg_idx].queue_free()
	
	arg_nodes.clear()
	
	var call_id: String = call_opt_btn.get_item_metadata(idx)
	var arg_counter: int = 0
	
	match NexusForge.Callables.get_callable_return_type(call_id):
		TYPE_INT:
			return_texture.texture = ICON_INT
		TYPE_BOOL:
			return_texture.texture = ICON_BOOL
		TYPE_STRING:
			return_texture.texture = ICON_STRING
		TYPE_FLOAT:
			return_texture.texture = ICON_FLOAT
		_:
			return_texture.texture = null
	
	for arg_type in NexusForge.Callables.get_callable_return_args(call_id):
		var new_node: Control = null
		arg_counter += 1
		match arg_type:
			TYPE_INT:
				new_node = SpinBox.new()
				new_node.step = 1.0
				new_node.allow_greater = true
				new_node.allow_lesser = true
			TYPE_FLOAT:
				new_node = SpinBox.new()
				new_node.step = 0.01
				new_node.allow_greater = true
				new_node.allow_lesser = true
			TYPE_BOOL:
				new_node = CheckButton.new()
				new_node.toggled.connect(_on_bool_toggled)
				new_node.text = "False"
			TYPE_STRING:
				new_node = LineEdit.new()
				new_node.placeholder_text = "Text Argument"
		
		new_node.custom_minimum_size.y = 32
		
		add_child(new_node)
		arg_nodes.append(new_node)
		register_input_connection(str(arg_counter), arg_counter - 1, true)
		set_slot(
			arg_counter,
			true,
			PortType.VALUE,
			Color(0.163, 0.836, 0.729),
			false,
			0,
			Color.WHITE)
	size.y = 87 + (34 * arg_nodes.size())


func _on_bool_toggled(is_toggled: bool, target: CheckButton) -> void:
	target.text = "True" if is_toggled else "False"


func get_arg_type(idx: int) -> int:
	var node: Control = arg_nodes[idx]
	if node is LineEdit:
		return TYPE_STRING
	elif node is SpinBox:
		if node.step == 1.0:
			return TYPE_INT
		else:
			return TYPE_FLOAT
	else:
		return TYPE_STRING


func set_arg_enabled(idx: int, is_enabled: bool) -> void:
	var arg: Control = arg_nodes[idx]
	
	if arg is LineEdit:
		arg.editable = is_enabled
	elif arg is SpinBox:
		arg.editable = is_enabled
	elif arg is LineEdit:
		arg.editable = is_enabled
	elif arg is CheckButton:
		arg.disabled = not is_enabled


func get_node_value(node: Control) -> Variant:
	if node is SpinBox:
		if node.step == 1.0:
			return int(node.value)
		else:
			return float(node.value)
	elif node is LineEdit:
		return node.text.strip_edges()
	elif node is CheckButton:
		return node.button_pressed
	else:
		return null


func set_call(call_id: String) -> void:
	for idx in range(call_opt_btn.item_count):
		if call_opt_btn.get_item_metadata(idx) == call_id:
			call_opt_btn.select(idx)
			on_call_idx_selected(idx)
			break


func set_call_args(call_args: Array) -> void:
	for idx in range(clampi(call_args.size(), 0, arg_nodes.size())):
		match typeof(call_args[idx]):
			TYPE_INT:
				if arg_nodes[idx] is SpinBox:
					arg_nodes[idx].value = call_args[idx]
			TYPE_FLOAT:
				if arg_nodes[idx] is SpinBox:
					arg_nodes[idx].value = call_args[idx]
			TYPE_STRING:
				if arg_nodes[idx] is LineEdit:
					arg_nodes[idx].text = call_args[idx]
			TYPE_BOOL:
				if arg_nodes[idx] is CheckButton:
					arg_nodes[idx].button_pressed = call_args[idx]
