extends DiscourseGraphNode


var available_methods: Dictionary = {}


func _post_init() -> void:
	name = &"Call"
	custom_id = "Call"
	title = "Call Method"
	graph_icon = get_theme_icon("MemberMethod", "EditorIcons")
	node_type = DialogueNodeType.CALLABLE
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
			SlotConnectionType.CALL)
	set_slot_color_right(0, COLORS["method"])
	
	
	if not available_methods.is_empty():
		methods_node.select(0)
		_on_method_selected(0)
	
	methods_node.item_selected.connect(_on_method_selected)


func _ready() -> void:
	set_output_connection_icon(&"methods", get_theme_icon("Callable", "EditorIcons"))


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
		inputs.append(
				get_uuid_and_port_connected_to(
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


func load_method(method_id: String) -> void:
	clear_input_args()
	for argument:Dictionary in available_methods[method_id]:
		add_input_arg(argument["name"], argument["type"])


func _on_method_selected(idx: int) -> void:
	var opt_btn: OptionButton = get_field(&"methods")
	var id: String = opt_btn.get_item_metadata(idx)
	
	load_method(id)
	node_updated.emit()


func get_current_method() -> String:
	var opt_btn: OptionButton = get_field(&"methods")
	if opt_btn.selected == -1:
		return ""
	else:
		return opt_btn.get_item_metadata(opt_btn.selected)


func has_default_arg(method: String, argument_idx: int) -> bool:
	if method.is_empty() or not available_methods.has(method):
		return false
	return available_methods[method][argument_idx]["has_default"]


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
			-1)
	set_input_connection_icon(field_id, input_icon)
	set_slot_color_left(slot_target, input_color)


func clear_input_args() -> void:
	for item in range(get_child_count() - 1, 0, -1):
		var field_id: StringName = &"argument_" + StringName(str(item))
		remove_field(field_id, 32)


func get_user_methods() -> Dictionary:
	var methods: Dictionary = {}
	
	var method_blacklsit: Array[String] = []
	var singleton: DialogParser.DiscourseAPI = DialogParser.DiscourseAPI.new()
	var parser: DialogParser = DialogParser.new_parser()
	var base_methods: Array = parser.get_method_list()
	
	for method in base_methods:
		method_blacklsit.append(method["name"])
		
	for method:Dictionary in singleton.get_method_list():
		if method["name"] in method_blacklsit:
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
		methods[method["name"]] = args
	
	return methods
