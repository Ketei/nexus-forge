extends DiscourseGraphNode


var available_methods: Dictionary = {}


func _post_init() -> void:
	name = &"CallWithReturn"
	custom_id = "CallWithReturn"
	title = "Call Method (Return)"
	graph_icon = get_theme_icon("MemberMethod", "EditorIcons")
	node_type = DialogueNodeType.CALLABLE_RETURN
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(280, 83)
	
	available_methods = get_user_methods()
	
	var methods_node: OptionButton = OptionButton.new()
	methods_node.name = &"MethodsOptBtn"
	methods_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	methods_node.fit_to_longest_item = false
	methods_node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	for method:String in available_methods.keys():
		methods_node.add_item(method.capitalize())
		methods_node.set_item_metadata(-1, method)
	
	add_field(
			&"methods",
			methods_node,
			false,
			-1,
			SlotConnectionType.VAR_ANY,
			null,
			get_theme_icon("Variant", "EditorIcons"))
	
	set_slot_color_right(0, COLORS["method"])
	
	if not available_methods.is_empty():
		methods_node.select(0)
		_on_method_selected(0)
	else:
		methods_node.disabled = true
	
	methods_node.item_selected.connect(_on_method_selected)


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	if available_methods.is_empty() and has_any_output(0):
		issues.append("Warning: Method is connected but no Method is available.")
	var method: String = get_current_method()
	for arg_idx in range(0, get_child_count() - 1):
		if not has_any_input(arg_idx) and not has_default_arg(method, arg_idx):
			issues.append("Error: Missing method argument " + str(arg_idx) + ".")
	return issues


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	var inputs: Array[Dictionary] = []
	
	for arg_idx in range(get_child_count() - 1):
		inputs.append(get_uuid_and_port_connected_to(
							PortMode.INPUT,
							arg_idx))
	data["output_connections"] = {
		"caller": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	data["node_type"] = node_type
	data["position"] = position_offset
	data["method"] = get_current_method()
	data["arguments"] = inputs
	return data


func _set_node_data(data: Dictionary) -> void:
	var method_opt_btn: OptionButton = get_field(&"methods")
	position_offset = data["position"]
	for idx in range(method_opt_btn.item_count):
		if method_opt_btn.get_item_metadata(idx) == data["method"]:
			method_opt_btn.select(idx)
			load_method(data["method"])
			break


func _on_method_selected(idx: int) -> void:
	var opt_btn: OptionButton = get_field(&"methods")
	var id: String = opt_btn.get_item_metadata(idx)
	load_method(id)
	node_updated.emit()


func load_method(method_id: String) -> void:
	var var_color: Color = COLORS["any"]
	var type: SlotConnectionType = SlotConnectionType.VAR_ANY
	var icon: Texture2D = get_theme_icon("Variant", "EditorIcons")
	
	match available_methods[method_id]["return_type"]:
		TYPE_INT:
			var_color = COLORS["integer"]
			type = SlotConnectionType.VAR_INT
			icon = get_theme_icon("int", "EditorIcons")
		TYPE_FLOAT:
			var_color = COLORS["float"]
			type = SlotConnectionType.VAR_FLOAT
			icon = get_theme_icon("float", "EditorIcons")
		TYPE_BOOL:
			var_color = COLORS["bool"]
			type = SlotConnectionType.VAR_BOOL
			icon = get_theme_icon("bool", "EditorIcons")
		TYPE_STRING:
			var_color = COLORS["string"]
			type = SlotConnectionType.VAR_STRING
			icon = get_theme_icon("String", "EditorIcons")
	
	clear_input_args()
	
	for argument:Dictionary in available_methods[method_id]["arguments"]:
		add_input_arg(argument["name"], argument["type"])
	
	if has_any_output(0) and get_slot_type_right(0) != type:
		var target: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, 0)
		disconnect_requested.emit(
			name,
			0,
			target.name,
			target.get_input_port_connected_to(self))
	
	set_slot_type_right(0, type)
	set_slot_color_right(0, var_color)
	set_output_connection_icon(&"methods", icon)


func get_current_method() -> String:
	var opt_btn: OptionButton = get_field(&"methods")
	if opt_btn.selected == -1:
		return ""
	else:
		return opt_btn.get_item_metadata(opt_btn.selected)


func has_default_arg(method: String, argument_idx: int) -> bool:
	if method.is_empty() or not available_methods.has(method):
		return false
	return available_methods[method]["arguments"][argument_idx]["has_default"]


func add_input_arg(arg_text: String, arg_type: int) -> void:
	var slot_target: int = get_child_count()
	var arg: Label = Label.new()
	var slot_type: SlotConnectionType = SlotConnectionType.VAR_ANY
	var field_id: StringName = &"argument_" + StringName(str(slot_target))
	
	var input_icon: Texture2D = get_theme_icon("Variant", "EditorIcons")
	var input_color: Color = COLORS["any"]
	arg.custom_minimum_size.y = 24
	arg.text = arg_text.capitalize()
	arg.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	arg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	match arg_type:
		TYPE_INT:
			slot_type = SlotConnectionType.VAR_INT
			input_icon = get_theme_icon("int", "EditorIcons")
			input_color = COLORS["integer"]
		TYPE_FLOAT:
			slot_type = SlotConnectionType.VAR_FLOAT
			input_icon = get_theme_icon("float", "EditorIcons")
			input_color = COLORS["float"]
		TYPE_BOOL:
			slot_type = SlotConnectionType.VAR_BOOL
			input_icon = get_theme_icon("bool", "EditorIcons")
			input_color = COLORS["bool"]
		TYPE_STRING:
			slot_type = SlotConnectionType.VAR_STRING
			input_icon = get_theme_icon("String", "EditorIcons")
			input_color = COLORS["string"]
	
	add_field(
			field_id,
			arg,
			false,
			slot_type,
			-1,
			input_icon)
	set_slot_color_left(slot_target, input_color)


func clear_input_args() -> void:
	for item in range(get_child_count() - 1, 0, -1):
		var field_id: StringName = &"argument_" + StringName(str(item))
		remove_field(field_id, 32)


func get_user_methods() -> Dictionary:
	var methods: Dictionary = {}
	
	var method_blacklsit: Array[String] = []
	var singleton: DialogParser.DiscourseAPI = DialogParser.DiscourseAPI.new()
	var base_methods: Array = ClassDB.class_get_method_list(&"RefCounted")
	
	for method in base_methods:
		method_blacklsit.append(method["name"])
		
	for method:Dictionary in singleton.get_method_list():
		if method["name"] in method_blacklsit or method["return"]["type"] == TYPE_NIL:
			continue
		
		var default_count: int = method["default_args"].size()
		var default_index: int = method["args"].size() - default_count
		var args: Array[Dictionary] = []
		var arg_idx: int = -1
		for arg: Dictionary in method["args"]:
			arg_idx += 1
			args.append({
				"name": arg["name"],
				"type": arg["type"],
				"has_default": default_index <= arg_idx})
		methods[method["name"]] = {"return_type": method["return"]["type"], "arguments": args}
	
	return methods
