extends DiscourseGraphNode


var available_methods: Dictionary = {
	#"a_method": [{"name": "arg_name", "type": TYPE_INT, "has_default": true}]
}


func _post_init() -> void:
	set_node_id(&"Call")
	title = "Call Method"
	graph_icon = get_theme_icon("MemberMethod", "EditorIcons")
	node_type = DialogueNodeType.CALLABLE
	parent_mode = PortMode.OUTPUT
	parent_port = 0
	size = Vector2(280, 84)
	custom_minimum_size.y = 84
	
	available_methods = get_user_methods()
	
	var methods_node: OptionButton = OptionButton.new()
	methods_node.name = &"MethodsOptBtn"
	methods_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	methods_node.fit_to_longest_item = false
	methods_node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	methods_node.custom_minimum_size.y = 32
	
	var method_keys: Array = available_methods.keys()
	
	method_keys.sort_custom(ArrayUtils.sort_custom_alphabetically_asc)
	
	for method:String in method_keys:
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
	graph_icon = get_theme_icon("Callable", "EditorIcons")
	set_output_connection_icon(&"methods", get_theme_icon("Callable", "EditorIcons"))
	for arg_port in range(get_child_count() - 1):
		var id: StringName = StringName("argument_" + str(arg_port + 1))
		match get_input_port_type(arg_port):
			SlotConnectionType.VAR_INT:
				set_input_connection_icon(id, get_theme_icon("int", "EditorIcons"))
			SlotConnectionType.VAR_FLOAT:
				set_input_connection_icon(id, get_theme_icon("float", "EditorIcons"))
			SlotConnectionType.VAR_BOOL:
				set_input_connection_icon(id, get_theme_icon("bool", "EditorIcons"))
			SlotConnectionType.VAR_STRING:
				set_input_connection_icon(id, get_theme_icon("String", "EditorIcons"))
			_:
				set_input_connection_icon(id, get_theme_icon("Variant", "EditorIcons"))


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
	var inputs: Array[Dictionary] = []
	
	for arg_idx in range(get_child_count() - 1):
		inputs.append(
				get_uuid_and_port_connected_to(
							PortMode.INPUT,
							arg_idx))
	
	var output_connections: Dictionary = {
		"caller": get_uuid_and_port_connected_to(PortMode.OUTPUT, 0)}
	var metadata: Dictionary = {
		"method": get_current_method(),
		"arguments": inputs}
	
	return _build_node_data(metadata, output_connections)


func _set_node_data(data: Dictionary) -> void:
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if not metadata.has("method") or typeof(metadata["method"]) != TYPE_STRING:
		return
	
	var method_opt_btn: OptionButton = get_field(&"methods")
	for idx in range(method_opt_btn.item_count):
		if method_opt_btn.get_item_metadata(idx) == metadata["method"]:
			method_opt_btn.select(idx)
			load_method(metadata["method"])
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


func reload_methods() -> void:
	available_methods = get_user_methods()
	var opt_btn: OptionButton = get_field(&"methods")
	var selected_method: String = opt_btn.get_selected_metadata() if opt_btn.selected != -1 else ""
	var all_methods: Array = available_methods.keys()
	var new_select: int = -1
	var emit_updated: bool = false
	
	all_methods.sort_custom(ArrayUtils.sort_custom_alphabetically_asc)
	
	if selected_method != "":
		new_select = all_methods.find(selected_method)
	
	opt_btn.clear()
	
	for method in all_methods:
		opt_btn.add_item(method)
		opt_btn.set_item_metadata(-1, method)
	
	if new_select != -1:
		opt_btn.select(new_select)
	elif new_select == -1:
		if available_methods.size() == 0:
			clear_input_args()
		else:
			opt_btn.select(0)
			load_method(opt_btn.get_item_metadata(0))
		node_updated.emit()
		return # Since there was no equal method we stop here
	
	# Since there is an equal named method, we will check all the arguments.
	var arg_idx: int = -1 # With the index
	for new_argument:Dictionary in available_methods[selected_method]:
		arg_idx += 1
		
		# If the new index is equal or larger as the child count, we add the argument.
		# Index 0 to child count 0, means we need to add a new child.
		if get_child_count() - 1 <= arg_idx:
			add_input_arg(new_argument["name"], new_argument["type"])
			emit_updated = true
			continue # And we continue
		
		# We grab the existing argument to repurpose it.
		var field_id: StringName = &"argument_" + StringName(str(arg_idx + 1))
		var current_input_type: int = get_slot_type_left(arg_idx + 1)
		var new_data_type: int = new_argument["type"]
		var new_port_type: int = 0
		var new_type_color: String = ""
		var compatible: bool = false
		var new_icon: Texture2D = null
		
		match new_data_type:
			TYPE_INT:
				new_port_type = SlotConnectionType.VAR_INT
				new_type_color = "integer"
				new_icon = get_theme_icon("int", "EditorIcons")
			TYPE_FLOAT:
				new_port_type = SlotConnectionType.VAR_FLOAT
				new_type_color = "float"
				new_icon = get_theme_icon("float", "EditorIcons")
			TYPE_BOOL:
				new_port_type = SlotConnectionType.VAR_BOOL
				new_type_color = "bool"
				new_icon = get_theme_icon("bool", "EditorIcons")
			TYPE_STRING:
				new_port_type = SlotConnectionType.VAR_STRING
				new_type_color = "string"
				new_icon = get_theme_icon("String", "EditorIcons")
			_:
				new_port_type = SlotConnectionType.VAR_ANY
				new_type_color = "any"
				new_icon = get_theme_icon("Variant", "EditorIcons")
		
		if has_any_input(arg_idx):
			match current_input_type:
				SlotConnectionType.VAR_INT:
					compatible = new_data_type == TYPE_INT
				SlotConnectionType.VAR_FLOAT:
					compatible = new_data_type == TYPE_FLOAT
				SlotConnectionType.VAR_BOOL:
					compatible = new_data_type == TYPE_BOOL
				SlotConnectionType.VAR_STRING:
					compatible = new_data_type == TYPE_STRING
				SlotConnectionType.VAR_ANY: # The current port accepts anything
					# We grab the node that connects to the argument
					var input_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, arg_idx)
					# And grab the port type of that node
					var output_type: int = -1 if input_target == null else input_target.get_output_port_type(
							input_target.get_port_connected_to(PortMode.OUTPUT, self, arg_idx))
					
					# And it's compatible if the new port type matches the output
					# port of the node connected to this one or is an "any".
					compatible = output_type == new_port_type or output_type == SlotConnectionType.VAR_ANY
			
			if not compatible: # If it isn't compatible we disconnect it.
				disconnect_port(PortMode.INPUT, arg_idx)
				emit_updated = true
		
		# Update the field text
		get_field(field_id).text = new_argument["name"]
		
		# If the types don't match we assign the type, change the color and icon.
		if current_input_type != new_port_type:
			set_slot_color_left(arg_idx, COLORS[new_type_color])
			set_slot_type_left(arg_idx, new_port_type)
			emit_updated = true
	
	if emit_updated:
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
		_:
			slot_type = SlotConnectionType.VAR_ANY
			input_icon = get_theme_icon("Variant", "EditorIcons")
			input_color = COLORS["any"]
	
	add_field(
			field_id,
			arg,
			false,
			slot_type,
			-1)
	
	set_input_connection_icon(field_id, input_icon)
	set_slot_color_left(slot_target, input_color)


func clear_input_args() -> void:
	var fields_to_remove: Array[StringName] = []
	for item in range(get_child_count() - 1, 0, -1):
		var field_id: StringName = &"argument_" + StringName(str(item))
		fields_to_remove.append(field_id)
	if not fields_to_remove.is_empty():
		remove_fields(fields_to_remove)
		update_node_size.call_deferred()


func update_node_size() -> void:
	size.y = 0 


static func get_user_methods() -> Dictionary:
	var methods: Dictionary = {}
	
	var method_blacklsit: Array[String] = []
	var singleton: DiscourseAPI = DiscourseAPI.new()
	#var parser: DialogParser = DialogParser.new_parser()
	var base_methods: Array = ClassDB.class_get_method_list(&"RefCounted")
	
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
