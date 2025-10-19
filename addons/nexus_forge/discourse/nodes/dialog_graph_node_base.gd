class_name DiscourseGraphNode
extends GraphNode


signal disconnect_requested(from: StringName, out_port: int, to: StringName, in_port: int)
signal close_requested(node: DiscourseGraphNode)
signal duplicate_requested(node: DiscourseGraphNode)
signal localize_node_toggled(toggled_on: bool, node: DiscourseGraphNode)
signal node_updated


enum PortMode {
	NONE, ## The node has no parents, hence it acts as one.
	INPUT, ## The node's parent is an input.
	OUTPUT, ## The node's parent is an output.
}

#enum DialogueNodeType {
	#ENTRY = 0, ## The entry for a conversation.
	#DIALOG = 1, ## A generic dialog node
	#OPTIONS = 2, ## A collection of dialog options.
	#BRANCH = 3, ## A dialog split via if/else comparison.
	#CONDITION_SELECT = 4, ## An if-else statement that outputs a variable.
	#COMPARATION = 5, ## A direct comparation between 2 values.
	#EVENT = 6, ## Triggers a method call, a variable set or a signal emit.
	#MATCH = 7, ## Compares and selects the matching, if none match, uses default.
	#PAUSE = 8, ## Pauses dialog execution until told to continue
	#RANDOM = 9, ## Selects a random dialog. Weights can be passed around.
	#TYPE_GUARD = 10, ## Verifies outputs.
	#VALUE = 11, ## Represents specific data type
	#SIGNAL = 12, ## Represents a registered signal
	#CALLABLE = 13, ## Represents a method that can be called
	#CALLABLE_RETURN = 14, ## Represents a method that can be called
	#VARIABLE_GET = 15,
	#ANCHOR_POINTER = 16, ## A pointer that directs to a SHORTCUT_OUT.
	#ANCHOR = 17, ## A node for SHORTCUT_IN to point to.
	#DIALOG_END = 18,
	#DIALOG_MERGE = 19,
	#COMMENT = 20, ## A node that exists to explain something.
	#SETTINGS_CHARACTER = 21,
	#SETTINGS_DIALOG = 22,
	#SETTINGS_OPTION = 23,
	#RANDOM_VALUE = 24,
	#RESOURCE = 25,
	#DATA_EVENT = 26,
	#LOCALIZED_TEXT = 27,
#}

enum SlotConnectionType {
	DIALOG, ## Output Dialog
	CALL,
	SIGNAL,
	VAR_BOOL,
	VAR_STRING,
	VAR_INT,
	VAR_FLOAT,
	VAR_ANY, ## Variable
	VAR_GUARD, ## Connects to any input. Used for compat
	VAR_FORWARD, ## Inputs to any data, outputs same data type.
	SETTINGS_CHARACTER,
	SETTINGS_DIALOG,
	SETTINGS_OPTION,
	RESOURCE,
}

enum IssueLevel {
	ERROR = 0,
	WARNING = 1}

const DialogueNodeType := DialogParser.NodeTypes

const COLORS: Dictionary = {
	"dialog": Color.SEA_GREEN,
	"bool": Color(1.0, 0.439, 0.522), # Red
	"string": Color(0.945, 0.871, 0.6), # Light Yellow
	"integer": Color(0.758, 0.301, 0.97), # Light-Magenta
	"float": Color(0.486, 0.346, 0.835), # Light-Purple
	"any": Color(0.233, 0.94, 0.86), # Cyan
	"method": Color(0.18, 0.581, 1.0), # Deep-Blue
	"signal": Color(0.825, 0.433, 0.261), # Orange
	"object": Color(1.0, 0.418, 0.789), # Pink
	"setting": Color(0.853, 0.55, 0.379)} # Light-Orange/Gold

const LOCALIZED_COLOR: Color = Color.LIME_GREEN

var flow_icon: Texture2D = null

var node_type: DialogueNodeType = DialogueNodeType.DIALOG

var _uuid: StringName = &""
#var _subtitle_label: Label = null # Remove
var _uses_localization: bool = false
var custom_id: String = ""
var parent_mode: PortMode = PortMode.INPUT
var parent_port: int = 0
var graph_icon: Texture2D = null:
	set(new_icon):
		graph_icon = new_icon
		if _icon_rect != null:
			_icon_rect.texture = new_icon
			_icon_rect.visible = new_icon != null
var _icon_rect: TextureRect = null
var _node_map: Dictionary[StringName, Dictionary] = {}
var _input_nodes: Array[Dictionary] = []
var _output_nodes: Array[Dictionary] = []


func _init(uuid: StringName = &"", theme_variant: StringName = &"", with_duplicate: bool = true, with_close: bool = true, localization: bool = false) -> void:
	_uuid = StringName(UUID.generate_new()) if uuid.is_empty() else uuid
	flow_icon = preload("res://addons/nexus_forge/icons/right_arrow.png")
	var _hbox: HBoxContainer = get_titlebar_hbox()
	var title_label: Label = _hbox.get_child(0)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	_icon_rect = TextureRect.new()
	_icon_rect.name = &"GraphIcon"
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.custom_minimum_size = Vector2(20, 20)
	_icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hbox.add_child(_icon_rect)
	_hbox.move_child(_icon_rect, 0)
	#_hbox.add_theme_constant_override(&"separation", 20)
	if graph_icon != null:
		_icon_rect.texture = graph_icon
	else:
		_icon_rect.visible = false
	
	theme = preload("res://addons/nexus_forge/discourse/dialog_graph_theme.tres")
	theme_type_variation = theme_variant
	
	if with_duplicate == false and with_close == false:
		_post_init()
		return
	
	var _button_box: HBoxContainer = HBoxContainer.new()
	_button_box.name = &"GraphButtonsNode"
	_button_box.size_flags_horizontal = Control.SIZE_SHRINK_END
	_button_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hbox.add_child(_button_box)
	
	if localization:
		var localize_btn: Button = Button.new()
		localize_btn.name = &"LocalizeBtn"
		localize_btn.flat = true
		localize_btn.toggle_mode = true
		localize_btn.icon = get_theme_icon("Translation", "EditorIcons")
		localize_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		localize_btn.custom_minimum_size = Vector2(22.0, 22.0)
		localize_btn.tooltip_text = "Use Localization"
		_button_box.add_child(localize_btn)
		if with_duplicate or with_close:
			_button_box.add_spacer(false)
		localize_btn.toggled.connect(_on_localization_toggled.bind(localize_btn))
	
	if with_duplicate:
		var dup_btn := Button.new()
		dup_btn.name = &"DuplicateBtn"
		dup_btn.flat = true
		dup_btn.icon = get_theme_icon("Duplicate", "EditorIcons")
		dup_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dup_btn.custom_minimum_size = Vector2(22, 22)
		dup_btn.tooltip_text = "Duplicate node"
		_button_box.add_child(dup_btn)
		dup_btn.pressed.connect(duplicate_requested.emit.bind(self))
	
	if with_close:
		var close_btn := Button.new()
		close_btn.name = &"CloseBtn"
		close_btn.flat = true
		close_btn.icon = get_theme_icon("Close", "EditorIcons")
		close_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		close_btn.custom_minimum_size = Vector2(22, 22)
		close_btn.tooltip_text = "Remove node"
		_button_box.add_child(close_btn)
		close_btn.pressed.connect(close_requested.emit.bind(self))
	
	_post_init()


## Runs once the initiation is done. Used to set up the visual part of the node.
func _post_init() -> void:
	pass


## Called when an input is connected
func _on_input_connected(_input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	pass


func _on_output_connected(_output: int, _to_node: DiscourseGraphNode, _to_port: int) -> void:
	pass


func _on_input_disconnected(_input_port: int, _from_node: DiscourseGraphNode, _from_port: int) -> void:
	pass


## Called when an output is disconnected from a node.
func _on_output_disconnected(_output: int, _to_node: DiscourseGraphNode, _to_port: int) -> void:
	pass


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	return issues


## Use to get data from the node
func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	data["node_type"] = node_type
	data["position"] = position_offset
	return data


## Use to set data on the node
func _set_node_data(data: Dictionary) -> void:
	position_offset = data["position"]


func _clone() -> DiscourseGraphNode:
	var titlebox: HBoxContainer = get_titlebar_hbox().get_child(-1)
	var new_node: DiscourseGraphNode = get_script().new(
			"",
			theme_type_variation,
			titlebox.has_node(^"DuplicateBtn"),
			titlebox.has_node(^"CloseBtn"),
			titlebox.has_node(^"EditIdBtn"),
			titlebox.has_node(^"LocalizeBtn"))
	new_node._set_node_data(_get_node_data())
	
	return new_node


func _on_localization_toggled(toggle: bool, node: Button) -> void:
	node.disabled = true
	node.modulate = LOCALIZED_COLOR if toggle else Color.WHITE
	_uses_localization = toggle
	localize_node_toggled.emit(toggle, self)
	node_updated.emit()


func set_node_localized(is_localized: bool) -> void:
	_uses_localization = is_localized
	if not get_titlebar_hbox().has_node(^"GraphButtonsNode"):
		return
	var titlebox: HBoxContainer = get_titlebar_hbox().get_child(-1)
	var btn: Button = titlebox.get_node_or_null(^"LocalizeBtn") if titlebox.has_node(^"LocalizeBtn") else null
	if btn != null:
		btn.set_pressed_no_signal(is_localized)
		btn.disabled = is_localized
		btn.modulate = LOCALIZED_COLOR if is_localized else Color.WHITE


func set_localization_enabled(enable: bool) -> void:
	var titlebox: HBoxContainer = get_titlebar_hbox().get_child(-1)
	var btn: Button = titlebox.get_node_or_null(^"LocalizeBtn") if titlebox.has_node(^"LocalizeBtn") else null
	if enable and btn == null:
		btn = Button.new()
		btn.name = &"LocalizeBtn"
		btn.flat = true
		btn.toggle_mode = true
		btn.icon = get_theme_icon("Translation", "EditorIcons")
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.custom_minimum_size = Vector2(22, 22)
		btn.tooltip_text = "Use Localization"
		if not titlebox.has_node(^"EditIdBtn"):
			titlebox.add_spacer(true)
		titlebox.add_child(btn)
		titlebox.move_child(btn, 0)
		btn.toggled.connect(_on_localization_toggled.bind(btn))
	elif not enable and btn != null:
		if btn.toggled.is_connected(_on_localization_toggled):
			btn.toggled.disconnect(_on_localization_toggled)
		titlebox.remove_child(btn)
		btn.queue_free()


func set_input_connection_icon(field_id: StringName, icon: Texture2D) -> void:
	if field_id.is_empty():
		return
	
	for node in get_children():
		if node.get_meta(&"field_id", &"") == field_id:
			var txrct: TextureRect = node.get_child(0)
			txrct.texture = icon
			txrct.visible = icon != null
			break


func set_output_connection_icon(field_id: StringName, icon: Texture2D) -> void:
	if field_id.is_empty():
		return
	
	for node in get_children():
		if node.get_meta(&"field_id", &"") == field_id:
			var txrct: TextureRect = node.get_child(2)
			txrct.texture = icon
			txrct.visible = icon != null
			break


## Call when an input was connected/disconnected from a node.
func set_input_connection(input: int, from_output: DiscourseGraphNode, from_port: int, is_connection: bool) -> void:
	if from_output == null:
		return
		
	if is_connection:
		if can_input_multiple(input):
			#_input_nodes[input]["connections"].append(from_output)
			_input_nodes[input]["connections"].append({
				"target_node": from_output,
				"target_port": from_port})
			_on_input_connected(input, from_output, from_port)
		else:
			if has_any_input(input):
				for input_item:Dictionary in _input_nodes[input]["connections"]:
					_on_input_disconnected(
							input,
							input_item["target_node"],
							input_item["target_port"])
				_input_nodes[input]["connections"].clear()
			_input_nodes[input]["connections"].append({
				"target_node": from_output,
				"target_port": from_port
			})
			_on_input_connected(input, from_output, from_port)
	else:
		var connextion_index: int = get_connection_index(PortMode.INPUT, input, from_output, from_port)
		if connextion_index != -1:
			_input_nodes[input]["connections"].remove_at(connextion_index)
			_on_input_disconnected(input, from_output, from_port)


## Call when an output was connected/disconnected from a node.
func set_output_connection(output: int, to_input: DiscourseGraphNode, to_port: int, is_connection: bool) -> void:
	if to_input == null:
		return
	
	if is_connection:
		if can_output_multiple(output):
			_output_nodes[output]["connections"].append({
				"target_node": to_input,
				"target_port": to_port
			})
			_on_output_connected(output, to_input, to_port)
		else:
			if has_any_output(output):
				for output_item:Dictionary in _output_nodes[output]["connections"]:
					_on_output_disconnected(
							output,
							output_item["target_node"],
							output_item["target_port"])
				_output_nodes[output]["connections"].clear()
			_output_nodes[output]["connections"].append({
				"target_node": to_input,
				"target_port": to_port})
			_on_output_connected(output, to_input, to_port)
	else:
		var connection_idx: int = get_connection_index(PortMode.OUTPUT, output, to_input, to_port)
		if connection_idx != -1:
			_output_nodes[output]["connections"].remove_at(connection_idx)
			_on_output_disconnected(output, to_input, to_port)


func set_input_allow_multiple(input_idx: int, allow_multiple_inputs: bool) -> void:
	_input_nodes[input_idx]["multicon"] = allow_multiple_inputs


func set_output_allow_multiple(input_idx: int, allow_multiple_inputs: bool) -> void:
	_output_nodes[input_idx]["multicon"] = allow_multiple_inputs


func can_input_multiple(input_idx: int) -> bool:
	return _input_nodes[input_idx]["multicon"]


func is_port_available(port_type: PortMode, port: int) -> bool:
	if port_type == PortMode.INPUT:
		if has_any_input(port):
			return can_input_multiple(port)
		else:
			return true
	elif port_type == PortMode.OUTPUT:
		if has_any_output(port):
			return can_output_multiple(port)
		else:
			return true
	else:
		return false


func can_output_multiple(output_idx: int) -> bool:
	return _output_nodes[output_idx]["multicon"]


func get_input_connection_count(input_port: int) -> int:
	return _input_nodes[input_port]["connections"].size()


#func get_node_connected_to_input_port(input_idx: int, connection_idx: int = 0) -> DiscourseGraphNode:
	#return _input_nodes[input_idx]["connections"][connection_idx]["target_node"]


func get_node_connected_to_port(port_type: PortMode, port: int, connection_index: int = 0) -> DiscourseGraphNode:
	if port_type == PortMode.INPUT:
		return _input_nodes[port]["connections"][connection_index]["target_node"]
	elif port_type == PortMode.OUTPUT:
		return _output_nodes[port]["connections"][connection_index]["target_node"]
	else:
		return null


func get_target_port_connected_to_port(port_type: PortMode, port:int, connection_index: int = 0) -> int:
	if port_type == PortMode.INPUT:
		return _input_nodes[port]["connections"][connection_index]["target_port"]
	elif port_type == PortMode.OUTPUT:
		return _output_nodes[port]["connections"][connection_index]["target_port"]
	else:
		return -1


func has_any_input(input_idx: int) -> bool:
	var input_count: int = _input_nodes.size()
	if input_count == 0 or input_idx < 0 or input_count <= input_idx:
		return false
	return not _input_nodes[input_idx]["connections"].is_empty()


func has_input_on(input_port: int, input_idx: int = 0) -> bool:
	var input_size: int = _input_nodes[input_port]["connections"].size()
	return 0 <= input_idx and 0 < input_size and input_idx < input_size


func get_target_node_uuid(port_mode: PortMode, port: int, connection_index: int = 0) -> String:
	match port_mode:
		PortMode.INPUT:
			if has_input_on(port, connection_index):
				return get_node_connected_to_port(port_mode, port, connection_index).get_node_uuid()
			else:
				return ""
		PortMode.OUTPUT:
			if has_output_on(port, connection_index):
				return get_node_connected_to_port(port_mode, port, connection_index).get_node_uuid()
			else:
				return ""
		PortMode.NONE:
			return ""
		_:
			return ""


func is_connected_to_input(input_idx: int, node: DiscourseGraphNode) -> bool:
	for item in _input_nodes[input_idx]["connections"]:
		if item["target_node"] == node:
			return true
	return false


#func get_node_connected_to_output_port(output_idx: int, connection_idx: int = 0) -> DiscourseGraphNode:
	#return _output_nodes[output_idx]["connections"][connection_idx]["target_node"]


func has_any_output(output_idx: int) -> bool:
	var output_count: int = _output_nodes.size()
	if output_count == 0 or output_idx < 0 or output_count <= output_idx:
		return false
	return not _output_nodes[output_idx]["connections"].is_empty()


func has_output_on(output_port: int, output_idx: int = 0) -> bool:
	var output_size: int = _output_nodes[output_port]["connections"].size()
	return 0 <= output_idx and 0 < output_size and output_idx < output_size


func is_connected_to_output(output_idx: int, node: DiscourseGraphNode) -> bool:
	for item in _output_nodes[output_idx]["connections"]:
		if item["target_node"] == node:
			return true
	return false


func get_port_connected_to(port_type: PortMode, target_node: DiscourseGraphNode, target_port: int) -> int:
	if port_type == PortMode.NONE:
		return -1
	
	var idx: int = -1
	var target_dict: Array[Dictionary] = _input_nodes if port_type == PortMode.INPUT else _output_nodes
	for item:Dictionary in target_dict:
		idx += 1
		for connection: Dictionary in item["connections"]:
			if connection["target_node"] == target_node and connection["target_port"] == target_port:
				return idx
	return -1


func get_connection_index(port_mode: PortMode, port: int, node: DiscourseGraphNode, target_port: int) -> int:
	if port_mode == PortMode.NONE:
		return -1
	
	var idx: int = -1
	var target_dict: Array[Dictionary] = _input_nodes[port]["connections"] if port_mode == PortMode.INPUT else _output_nodes[port]["connections"]
	for item:Dictionary in target_dict:
		idx += 1
		if item["target_node"] == node and item["target_port"] == target_port:
			return idx
	return -1


func get_input_connection_idx(on_input: int, input_node: DiscourseGraphNode) -> int:
	var idx: int = -1
	for connection:DiscourseGraphNode in _input_nodes[on_input]["connections"]:
		idx += 1
		if input_node == connection:
			return idx
	return -1


func get_output_connection_count(output_port: int) -> int:
	return _output_nodes[output_port]["connections"].size()


## Gets which connection index does a node have.
func get_output_connection_idx(on_output: int, output_node: DiscourseGraphNode) -> int:
	var idx: int = -1
	for connection:DiscourseGraphNode in _output_nodes[on_output]["connections"]:
		idx += 1
		if output_node == connection:
			return idx
	return -1


func get_uuid_and_port_connected_to(port_mode: PortMode, port: int, connection_index: int = 0) -> Dictionary[String, Variant]:
	var data: Dictionary[String, Variant] = {
		"target_node_uuid": &"",
		"target_port": -1,
		"from_port": -1}
	
	match port_mode:
		PortMode.INPUT:
			if has_input_on(port, connection_index):
				var node: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, port, connection_index)
				data["target_node_uuid"] = node.get_node_uuid()
				data["target_port"] = get_target_port_connected_to_port(PortMode.INPUT, port, connection_index)
				data["from_port"] = port
		PortMode.OUTPUT:
			if has_output_on(port, connection_index):
				var node: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, port, connection_index)
				data["target_node_uuid"] = node.get_node_uuid()
				data["target_port"] = get_target_port_connected_to_port(PortMode.OUTPUT, port, connection_index)
				data["from_port"] = port
	
	return data


func get_target_port_connected_to_self(port_mode: PortMode, port: int, connection_index: int = 0) -> int:
	match port_mode:
		PortMode.INPUT:
			if has_input_on(port, connection_index):
				return get_node_connected_to_port(port_mode, port, connection_index).get_port_connected_to(PortMode.OUTPUT, self, port)
			else:
				return -1
		PortMode.OUTPUT:
			if has_output_on(port, connection_index):
				return get_node_connected_to_port(port_mode, port, connection_index).get_port_connected_to(PortMode.INPUT, self, port)
			else:
				return -1
		PortMode.NONE:
			return -1
		_:
			return -1


func has_recursion(_caller: DiscourseGraphNode = null) -> bool:
	if _caller == null:
		_caller = self
	else:
		if _caller == self:
			return true
	
	match parent_mode:
		PortMode.NONE:
			return false
		PortMode.INPUT:
			for input:DiscourseGraphNode in _input_nodes[parent_port]["connections"]:
				if input == null:
					continue
				if input.has_recursion(_caller):
					return true
			return false
		PortMode.OUTPUT:
			for output:DiscourseGraphNode in _output_nodes[parent_port]["connections"]:
				if output == null:
					continue
				if output.input.has_recursion(_caller):
					return true
			return false
		_:
			return false


## Add a new field to the node. [param field] must not be in the tree for it to
## be added. Returns the index of the new slot added. -1 if the field couldn't
## be added. Left & rigth slot type must be equal or greater than 0 to be enabled.
func add_field(field_id: StringName, field_node: Control, expand: bool = false, left_slot_type: int = -1, right_slot_type: int = -1, left_icon: Texture2D = null, right_icon: Texture2D = null) -> int:
	if field_node.is_inside_tree() or field_id.is_empty():
		return -1
	
	var new_index: int = get_child_count()
	
	var field_box: HBoxContainer = HBoxContainer.new()
	var left_rect: TextureRect = TextureRect.new()
	var right_rect: TextureRect = TextureRect.new()
	var input_slot: int = -1
	var output_slot: int = -1
	
	field_box.set_meta(&"field_id", field_id)
	field_box.name = field_id
	
	left_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	right_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	field_box.custom_minimum_size = Vector2(16, 16)
	left_rect.custom_minimum_size = Vector2(16, 16)
	right_rect.custom_minimum_size = Vector2(16, 16)
	
	field_box.add_theme_constant_override(&"separation", 12)
	
	left_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	left_rect.texture = left_icon
	right_rect.texture = right_icon
	
	left_rect.visible = left_icon != null
	right_rect.visible = right_icon != null
	
	if expand:
		field_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	add_child(field_box)
	field_box.add_child(left_rect)
	field_box.add_child(field_node)
	field_box.add_child(right_rect)
	
	if 0 <= left_slot_type:
		set_slot_enabled_left(new_index, true)
		set_slot_type_left(new_index, left_slot_type)
		input_slot = _input_nodes.size() # Graphs are so bugged, let's use this
		_input_nodes.append({
			"multicon": false,
			"connections": Array([], TYPE_DICTIONARY, &"", null)})
	
	if 0 <= right_slot_type:
		set_slot_enabled_right(new_index, true)
		set_slot_type_right(new_index, right_slot_type)
		output_slot = _output_nodes.size() # Graphs are so bugged, let's use this
		_output_nodes.append({
					"multicon": false,
					"connections": Array([], TYPE_DICTIONARY, &"", null)
		})
	
	field_box.set_meta(&"input_slot", input_slot)
	field_box.set_meta(&"output_slot", output_slot)
	
	return new_index


func map_field(field_id: StringName, identifier: String, node: Control) -> bool:
	var field: Control = get_field(field_id)
	
	if field == null or identifier.is_empty() or not field.is_ancestor_of(node):
		return false
	
	if not _node_map.has(field_id):
		_node_map[field_id] = {}
	
	_node_map[field_id][identifier] = node
	
	return true


func get_mapped_field(field_id: StringName, identifier: String) -> Control:
	if _node_map.has(field_id) and _node_map[field_id].has(identifier):
		return _node_map[field_id][identifier]
	return null


func set_field_visible(field_id: StringName, field_visible: bool) -> void:
	if field_id.is_empty():
		return
	for child in get_children():
		if child.get_meta(&"field_id", &"") == field_id:
			if not field_visible:
				var slot: int = child.get_index()
				var in_port: int = child.get_meta(&"input_slot")
				var out_port: int = child.get_meta(&"input_slot")
				if is_slot_enabled_left(slot) and has_any_input(in_port):
					var from_graph: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, in_port)
					disconnect_requested.emit(
						from_graph.name,
						from_graph.get_port_connected_to(PortMode.OUTPUT, self, in_port),
						name,
						in_port)
				if is_slot_enabled_right(slot) and has_any_output(out_port):
					var to_graph: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, out_port)
					disconnect_requested.emit(
							name,
							out_port,
							to_graph.name,
							to_graph.get_port_connected_to(PortMode.INPUT, self, out_port))
			child.visible = field_visible
			break


func has_field(field_id: StringName) -> bool:
	if field_id.is_empty():
		return false
	
	for child in get_children():
		if child.get_meta(&"field_id", &"") == field_id:
			return true
	return false


func has_any_field_output(field_id: StringName) -> bool:
	if field_id.is_empty():
		return false
	
	for child in get_children():
		if child.get_meta(&"field_id", &"") == field_id:
			var output_port: int = child.get_meta(&"output_slot", -1)
			if output_port == -1:
				return false
			else:
				return not _input_nodes[output_port]["connections"].is_empty()
	
	return false


func has_any_field_input(field_id: StringName) -> bool:
	if field_id.is_empty():
		return false
	
	for child in get_children():
		if child.get_meta(&"field_id", &"") == field_id:
			var input_port: int = child.get_meta(&"output_slot", -1)
			if input_port == -1:
				return false
			else:
				return not _input_nodes[input_port]["connections"].is_empty()
	
	return false


func get_field(field_id: StringName) -> Control:
	if field_id.is_empty():
		return null
	
	for node:Control in get_children():
		if node.get_meta(&"field_id", &"") == field_id:
			return node.get_child(1)
	return null


func get_field_input_slot(field_id: StringName) -> int:
	if field_id.is_empty():
		return -1
	
	for node:Control in get_children():
		if node.get_meta(&"field_id", &"") == field_id:
			return node.get_meta(&"input_slot", -1)
	return -1


func get_field_output_slot(field_id: StringName) -> int:
	if field_id.is_empty():
		return -1
	
	for node:Control in get_children():
		if node.get_meta(&"field_id", &"") == field_id:
			return node.get_meta(&"output_slot", -1)
	return -1


func remove_field(field_id: StringName, size_change: int = 0) -> void:
	if field_id.is_empty():
		return
	
	var node: Control = null
	
	for child in get_children():
		if child.get_meta(&"field_id", &"") == field_id:
			node = child
			break
	
	if node == null:
		return
	
	var slot_index: int = node.get_index()
	
	if is_slot_enabled_left(slot_index): # Checking if input enabled
		if has_any_input(node.get_meta(&"input_slot")):
			#var in_target: DiscourseGraphNode = get_node_connected_to_input_port(node.get_meta(&"input_slot"))
			var in_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, node.get_meta(&"input_slot"))
			var target_slot: int = in_target.get_port_connected_to(PortMode.OUTPUT, self, node.get_meta(&"input_slot"))
			disconnect_requested.emit(
				in_target.name,
				target_slot,
				name,
				node.get_meta(&"input_slot"))
		_input_nodes.remove_at(
				node.get_meta(&"input_slot"))
	
	if is_slot_enabled_right(slot_index):
		var output_slot: int = node.get_meta(&"output_slot")
		if has_any_output(output_slot):
			var out_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, node.get_meta(&"output_slot"))
			var target_slot: int = out_target.get_port_connected_to(PortMode.INPUT, self, node.get_meta(&"output_slot"))
			disconnect_requested.emit(
					name,
					node.get_meta(&"output_slot"),
					out_target.name,
					target_slot)
		_output_nodes.remove_at(
				node.get_meta(&"output_slot"))
	
	remove_child(node)
	
	if 0 < size_change:
		size.y -= size_change
	else:
		size.y -= node.size.y + (get_theme_constant("separation") if 0 < get_child_count() else 0)
	
	node.queue_free()


func is_orphan() -> bool:
	match parent_mode:
		PortMode.NONE:
			return false
		PortMode.INPUT:
			return not has_any_input(parent_port)
		PortMode.OUTPUT:
			return not has_any_output(parent_port)
		_:
			return false


func disconnect_all() -> void:
	for input_port in range(_input_nodes.size()):
		for connection_idx in range(_input_nodes[input_port]["connections"].size()):
			var input_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, input_port, connection_idx)
			disconnect_requested.emit(
					input_target.name,
					input_target.get_port_connected_to(PortMode.OUTPUT, self, input_port),
					name,
					input_port)
	
	for output_port in range(_output_nodes.size()):
		for connection_idx in range(_output_nodes[output_port]["connections"].size()):
			var output_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, output_port, connection_idx)
			disconnect_requested.emit(
				name,
				output_port,
				output_target.name,
				output_target.get_port_connected_to(PortMode.INPUT, self, output_port))


func is_node_localized() -> bool:
	return _uses_localization


func get_node_uuid() -> StringName:
	return _uuid
