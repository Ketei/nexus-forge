@tool
class_name DiscourseGraphNode
extends GraphNode


signal disconnect_requested(from: StringName, out_port: int, to: StringName, in_port: int, caller: DiscourseGraphNode)
signal close_requested(node: DiscourseGraphNode)
signal duplicate_requested(node: DiscourseGraphNode)
signal localize_node_toggled(toggled_on: bool, node: DiscourseGraphNode)
signal node_updated
signal node_disconnected


enum PortMode {
	NONE, ## The node has no parents, hence it acts as one.
	INPUT, ## The node's parent is an input.
	OUTPUT, ## The node's parent is an output.
}

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
	METADATA,
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
	"setting": Color(0.853, 0.55, 0.379),
	"metadata": Color(0.541, 0.624, 0.82)} # Light-Orange/Gold

const LOCALIZED_COLOR: Color = Color.LIME_GREEN

@onready var flow_icon: Texture2D = preload("res://addons/nexus_forge/icons/right_arrow.png")

var node_type: DialogueNodeType = DialogueNodeType.DIALOG

var _uuid: StringName = &""
var _uses_localization: bool = false
var parent_mode: PortMode = PortMode.INPUT
var parent_port: int = 0
var graph_icon: Texture2D = null:
	set(new_icon):
		graph_icon = new_icon
		if _icon_rect != null:
			_icon_rect.texture = new_icon
			_icon_rect.visible = new_icon != null

var _icon_rect: TextureRect = null
var _input_nodes: Array[Dictionary] = []
var _output_nodes: Array[Dictionary] = []


func _init(uuid: StringName = &"", theme_variant: StringName = &"", with_duplicate: bool = true, with_close: bool = true, localization: bool = false) -> void:
	_uuid = StringName(UUID.generate_new()) if uuid.is_empty() else uuid
	var _hbox: HBoxContainer = get_titlebar_hbox()
	var title_label: Label = _hbox.get_child(0)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hbox.custom_minimum_size.y = 26
	
	_icon_rect = TextureRect.new()
	_icon_rect.name = &"GraphIcon"
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.custom_minimum_size = Vector2(20, 20)
	_icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_hbox.add_child(_icon_rect)
	_hbox.move_child(_icon_rect, 0)
	
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
	
	var localize_btn: Button = Button.new()
	localize_btn.visible = localization
	localize_btn.name = &"LocalizeBtn"
	localize_btn.flat = true
	localize_btn.toggle_mode = true
	localize_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	localize_btn.custom_minimum_size = Vector2(22.0, 22.0)
	localize_btn.tooltip_text = "Use Localization"
	_button_box.add_child(localize_btn)
	_ready_localize_icon(localize_btn)
	localize_btn.toggled.connect(_on_localization_toggled)
	
	var dup_btn := Button.new()
	dup_btn.visible = with_duplicate
	dup_btn.name = &"DuplicateBtn"
	dup_btn.flat = true
	dup_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dup_btn.custom_minimum_size = Vector2(22, 22)
	dup_btn.tooltip_text = "Duplicate node"
	_button_box.add_child(dup_btn)
	_ready_duplicate_icon(dup_btn)
	dup_btn.pressed.connect(duplicate_requested.emit.bind(self))
	
	var close_btn := Button.new()
	close_btn.visible = with_close
	close_btn.name = &"CloseBtn"
	close_btn.flat = true
	close_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_btn.custom_minimum_size = Vector2(22, 22)
	close_btn.tooltip_text = "Remove node"
	_button_box.add_child(close_btn)
	_ready_close_icon(close_btn)
	close_btn.pressed.connect(close_requested.emit.bind(self))
	
	_post_init()


func _ready_localize_icon(localize_btn: Button) -> void:
	if not is_node_ready():
		await ready
	localize_btn.icon = get_theme_icon("Translation", "EditorIcons")


func _ready_duplicate_icon(dup_btn: Button) -> void:
	if not is_node_ready():
		await ready
	dup_btn.icon = get_theme_icon("Duplicate", "EditorIcons")


func _get_localize_button() -> Button:
	var hbox: HBoxContainer = get_titlebar_hbox()
	var button_box: Control = hbox.get_node_or_null(^"GraphButtonsNode")
	
	if button_box == null:
		return null
	
	var btn: Control = button_box.get_node_or_null(^"LocalizeBtn")
	
	return btn if btn is Button else null


func _get_duplicate_button() -> Button:
	var hbox: HBoxContainer = get_titlebar_hbox()
	var button_box: Control = hbox.get_node_or_null(^"GraphButtonsNode")
	
	if button_box == null:
		return null
	
	var btn: Control = button_box.get_node_or_null(^"DuplicateBtn")
	
	return btn if btn is Button else null


func _get_close_button() -> Button:
	var hbox: HBoxContainer = get_titlebar_hbox()
	var button_box: Control = hbox.get_node_or_null(^"GraphButtonsNode")
	
	if button_box == null:
		return null
	
	var btn: Control = button_box.get_node_or_null(^"CloseBtn")
	
	return btn if btn is Button else null



func _ready_close_icon(close_btn: Button) -> void:
	if not is_node_ready():
		await ready
	close_btn.icon = get_theme_icon("Close", "EditorIcons")


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


func _build_node_data(metadata: Dictionary = {}, output_connections: Dictionary = {}, input_connections: Dictionary = {}) -> Dictionary:
	var meta: Dictionary = {"position": position_offset, "localized": is_node_localized()}
	var data: Dictionary = {"name": name, "type": node_type, "metadata": meta}
	
	if not metadata.is_empty():
		meta.merge(metadata, true)
	if not output_connections.is_empty():
		data.set("output_connections", output_connections)
	if not input_connections.is_empty():
		data.set("input_connections", input_connections)
	
	return data


func _get_node_data() -> Dictionary:
	return _build_node_data()


## Use to set data on the node
func _set_node_data(data: Dictionary) -> void:
	var data_name = data.get("name")
	var metadata = data.get("metadata")
	
	if typeof(data_name) == TYPE_STRING_NAME:
		name = data_name
	
	if typeof(metadata) != TYPE_DICTIONARY:
		return
	
	var pos = metadata.get("position")
	if typeof(pos) == TYPE_VECTOR2:
		position_offset = pos


func _on_localization_toggled(toggle: bool) -> void:
	var node: Button = _get_localize_button()
	if node == null:
		return
	node.disabled = true
	node.modulate = LOCALIZED_COLOR if toggle else Color.WHITE
	_uses_localization = toggle
	localize_node_toggled.emit(toggle, self)
	node_updated.emit()


func get_node_state() -> Dictionary:
	var data: Dictionary = _get_node_data()
	var input_connections: Dictionary = {}
	var output_connections: Dictionary = {}
	
	var state: Dictionary = {
		"data": data,
		"input_connections": input_connections,
		"output_connections": output_connections}
	
	var fields: Array[StringName] = []
	var field_nodes: Array[Node] = get_children()
	
	field_nodes.sort_custom(func (a:Control,b: Control): return a.get_index() < b.get_index())
	
	for field in field_nodes:
		fields.append(field.name)
	
	var port: int = -1
	for input_connection in _input_nodes:
		port += 1
		var slot: int = fields.find(input_connection["field_id"])
		var connections: Array[Dictionary] = []
		
		for connection_index in input_connection["connections"].size():
			connections.append(
					get_uuid_and_port_connected_to(PortMode.INPUT, port, connection_index))
		input_connections[input_connection["field_id"]] = {
			"port": port, # Port ID
			"slot": slot, # Slot Index,
			"connections": connections}
	port = -1
	for output_connection in _output_nodes:
		port += 1
		var slot: int = fields.find(output_connection["field_id"])
		var connections: Array[Dictionary] = []
		for connection_index in output_connection["connections"].size():
			connections.append(
					get_uuid_and_port_connected_to(PortMode.OUTPUT, port, connection_index))
		
		output_connections[output_connection["field_id"]] = {
			"port": port,
			"slot": slot,
			"connections": connections}
	
	return state


func set_node_localized(is_localized: bool) -> void:
	_uses_localization = is_localized
	var localization_button: Button = _get_localize_button()
	if localization_button == null:
		return
	localization_button.set_pressed_no_signal(is_localized)
	localization_button.disabled = is_localized
	localization_button.modulate = LOCALIZED_COLOR if is_localized else Color.WHITE


func set_localization_enabled(enable: bool) -> void:
	var btn: Button = _get_localize_button()
	if btn == null:
		return
	
	btn.visible = enable
	
	if enable:
		btn.toggled.connect(_on_localization_toggled)
	else:
		if btn.toggled.is_connected(_on_localization_toggled):
			btn.toggled.disconnect(_on_localization_toggled)


func set_input_connection_icon(field_id: StringName, icon: Texture2D) -> void:
	if field_id.is_empty():
		return
	
	for node in get_children():
		if node.name == field_id:
			var txrct: TextureRect = node.get_child(0)
			txrct.texture = icon
			txrct.visible = icon != null
			break


func set_output_connection_icon(field_id: StringName, icon: Texture2D) -> void:
	for node in get_children():
		if node.name != field_id:
			continue
		var txtrct: TextureRect = node.get_child(2)
		txtrct.texture = icon
		txtrct.visible = icon != null


func set_field_connection_icons(field_id: StringName, input_icon: Texture2D, output_icon: Texture2D) -> void:
	var field: Control = null
	
	for child in get_children():
		if child.name == field_id:
			field = child
			break
	
	if field == null:
		return
	
	var input: TextureRect = field.get_child(0)
	var output: TextureRect = field.get_child(2)
	input.texture = input_icon
	output.texture = output_icon

	input.visible = input_icon != null
	output.visible = output_icon != null


## Call when an input was connected/disconnected from a node.
func set_input_connection(input_port: int, from_output: DiscourseGraphNode, from_port: int, is_connection: bool) -> void:
	if from_output == null:
		return
		
	if is_connection:
		if can_input_multiple(input_port):
			_input_nodes[input_port]["connections"].append({
				"target_node": from_output,
				"target_port": from_port})
			_on_input_connected(input_port, from_output, from_port)
		else:
			if has_any_input(input_port):
				for input_item:Dictionary in _input_nodes[input_port]["connections"]:
					_on_input_disconnected(
						input_port,
						input_item["target_node"],
						input_item["target_port"])
				_input_nodes[input_port]["connections"].clear()
			_input_nodes[input_port]["connections"].append({
				"target_node": from_output,
				"target_port": from_port
			})
			_on_input_connected(input_port, from_output, from_port)
	else:
		var connextion_index: int = get_connection_index(PortMode.INPUT, input_port, from_output, from_port)
		if connextion_index != -1:
			_input_nodes[input_port]["connections"].remove_at(connextion_index)
			_on_input_disconnected(input_port, from_output, from_port)


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
	_input_nodes[input_idx]["multi_connection"] = allow_multiple_inputs


func set_output_allow_multiple(input_idx: int, allow_multiple_inputs: bool) -> void:
	_output_nodes[input_idx]["multi_connection"] = allow_multiple_inputs


func can_input_multiple(input_idx: int) -> bool:
	return _input_nodes[input_idx]["multi_connection"]


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
	return _output_nodes[output_idx]["multi_connection"]


func get_input_connection_count(input_port: int) -> int:
	return _input_nodes[input_port]["connections"].size()


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
	if input_count <= 0 or input_idx < 0 or input_count <= input_idx:
		return false
	return not _input_nodes[input_idx]["connections"].is_empty()


func has_input_on(input_port: int, input_idx: int = 0) -> bool:
	if input_port < 0 or input_idx < 0 or _input_nodes.size() - 1 < input_port:
		return false
	var input_size: int = _input_nodes[input_port]["connections"].size()
	return 0 < input_size and input_idx < input_size


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
	if _input_nodes.size() <= input_idx:
		return false
	
	for item in _input_nodes[input_idx]["connections"]:
		if item["target_node"] == node:
			return true
	return false


func has_any_output(output_idx: int) -> bool:
	var output_count: int = _output_nodes.size()
	if output_count == 0 or output_idx < 0 or output_count <= output_idx:
		return false
	return not _output_nodes[output_idx]["connections"].is_empty()


func has_output_on(output_port: int, output_idx: int = 0) -> bool:
	if output_idx < 0:
		return false
	var output_size: int = _output_nodes[output_port]["connections"].size()
	return output_idx < output_size


func is_connected_to_output(output_idx: int, node: DiscourseGraphNode) -> bool:
	if _output_nodes.size() <= output_idx:
		return false
	
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
		"from_port": port}
	
	match port_mode:
		PortMode.INPUT:
			if has_input_on(port, connection_index):
				var node: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, port, connection_index)
				data["target_node_uuid"] = node.get_node_uuid()
				data["target_port"] = get_target_port_connected_to_port(PortMode.INPUT, port, connection_index)
		PortMode.OUTPUT:
			if has_output_on(port, connection_index):
				var node: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, port, connection_index)
				data["target_node_uuid"] = node.get_node_uuid()
				data["target_port"] = get_target_port_connected_to_port(PortMode.OUTPUT, port, connection_index)
	
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


func _create_field(main_field: Control) -> HBoxContainer:
	var field_box: HBoxContainer = HBoxContainer.new()
	var left_rect: TextureRect = TextureRect.new()
	var right_rect: TextureRect = TextureRect.new()
	
	left_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	right_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	field_box.custom_minimum_size = Vector2(16, 16)
	left_rect.custom_minimum_size = Vector2(16, 16)
	right_rect.custom_minimum_size = Vector2(16, 16)
	
	left_rect.visible = false
	right_rect.visible = false
	
	field_box.add_theme_constant_override(&"separation", 8)
	
	left_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	add_child(field_box)
	field_box.add_child(left_rect)
	field_box.add_child(main_field)
	field_box.add_child(right_rect)
	
	return field_box


## Add a new field to the node. [param field] must not be in the tree for it to
## be added. Returns the index of the new slot added. -1 if the field couldn't
## be added. Left & rigth slot type must be equal or greater than 0 to be enabled.
func add_field(field_id: StringName, field_node: Control, expand: bool = false, left_slot_type: int = -1, right_slot_type: int = -1) -> int:
	if field_node.is_inside_tree() or field_id.is_empty() or has_field(field_id):
		return -1
	
	var new_index: int = get_child_count()
	var field_box: HBoxContainer = _create_field(field_node)
	
	# Getting the port count directly is bugged, let's grab data instead.
	var input_slot: int = -1 if left_slot_type < 0 else _input_nodes.size()
	var output_slot: int = -1 if right_slot_type < 0 else _output_nodes.size()
	
	field_box.name = field_id
	
	if expand:
		field_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	if 0 <= left_slot_type:
		set_slot_enabled_left(new_index, true)
		set_slot_type_left(new_index, left_slot_type)
		_input_nodes.append({
			"field_id": field_id,
			"multi_connection": false,
			"connections": Array([], TYPE_DICTIONARY, &"", null)})
	
	if 0 <= right_slot_type:
		set_slot_enabled_right(new_index, true)
		set_slot_type_right(new_index, right_slot_type)
		_output_nodes.append({
			"field_id": field_id,
			"multi_connection": false,
			"connections": Array([], TYPE_DICTIONARY, &"", null)})
	
	field_box.set_meta(&"input_slot", input_slot)
	field_box.set_meta(&"output_slot", output_slot)
	
	return new_index


func map_field(field_id: StringName, identifier: StringName, node: Control) -> bool:
	var field: Control = get_field(field_id)
	
	if field == null or identifier.is_empty() or not field.is_ancestor_of(node):
		return false
	
	field.set_meta(identifier, node)
	return true


func get_mapped_field(field_id: StringName, identifier: StringName) -> Control:
	var field: Control = get_field(field_id)
	if field != null and field.has_meta(identifier):
		return field.get_meta(identifier)
	return null


func set_field_visible(field_id: StringName, field_visible: bool) -> void:
	if field_id.is_empty():
		return
		
	var field = get_field(field_id)
	
	if field == null:
		return
	
	if field_visible:
		field.visible = field_visible
		return
	
	var slot: int = field.get_index()
	var in_port: int = field.get_meta(&"input_slot")
	var out_port: int = field.get_meta(&"input_slot")
	if is_slot_enabled_left(slot) and has_any_input(in_port):
		var from_graph: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, in_port)
		disconnect_requested.emit(
			from_graph.get_node_uuid(),
			from_graph.get_port_connected_to(PortMode.OUTPUT, self, in_port),
			get_node_uuid(),
			in_port,
			self)
		await node_disconnected
	if is_slot_enabled_right(slot) and has_any_output(out_port):
		var to_graph: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, out_port)
		disconnect_requested.emit(
			get_node_uuid(),
			out_port,
			to_graph.get_node_uuid(),
			to_graph.get_port_connected_to(PortMode.INPUT, self, out_port),
			self)
		await node_disconnected
	field.visible = field_visible


func has_field(field_id: StringName) -> bool:
	if field_id.is_empty():
		return false
	
	for child in get_children():
		if child.name == field_id:
			return true
	return false


func has_any_field_output(field_id: StringName) -> bool:
	if field_id.is_empty():
		return false
	
	var field = get_field(field_id)
	
	if field == null:
		return false
	
	var output_port: int = field.get_meta(&"output_slot", -1)
	
	if output_port <= -1:
		return false
	else:
		return not _input_nodes[output_port]["connections"].is_empty()


func has_any_field_input(field_id: StringName) -> bool:
	if field_id.is_empty():
		return false
	
	var field = get_field(field_id)
	
	if field == null:
		return false
	
	var input_port: int = field.get_meta(&"output_slot", -1)
	
	if input_port <= -1:
		return false
	else:
		return not _input_nodes[input_port]["connections"].is_empty()


func get_field(field_id: StringName) -> Control:
	if field_id.is_empty():
		return null
	
	for node:Control in get_children():
		if node.name == field_id:
			return node.get_child(1)
	return null


func get_index_field(field_index: int) -> Control:
	if field_index < 0 or get_child_count() <= field_index:
		return null
	
	return get_child(field_index).get_child(1)


func get_field_input_slot(field_id: StringName) -> int:
	if field_id.is_empty():
		return -1
	
	var node = get_field(field_id)
	
	return -1 if node == null else node.get_meta(&"input_slot", -1)


func get_field_output_slot(field_id: StringName) -> int:
	if field_id.is_empty():
		return -1
	
	var node = get_field(field_id)
	
	return -1 if node == null else node.get_meta(&"output_slot", -1)


var resizing: bool = false
var size_change: int = 0

func remove_field(field_id: StringName, size_change: int = 0) -> void:
	if field_id.is_empty():
		return
	
	var node: Control = null
	
	for child in get_children():
		if child.name != field_id:
			continue
		node = child
		break
	
	if node == null:
		return
	
	var slot_index: int = node.get_index()
	
	if is_slot_enabled_left(slot_index): # Checking if input enabled
		if has_any_input(node.get_meta(&"input_slot")):
			var in_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, node.get_meta(&"input_slot"))
			var target_slot: int = in_target.get_port_connected_to(PortMode.OUTPUT, self, node.get_meta(&"input_slot"))
			disconnect_requested.emit(
				in_target.get_node_uuid(),
				target_slot,
				get_node_uuid(),
				node.get_meta(&"input_slot"),
				self)
			await node_disconnected
			await get_tree().process_frame
		_input_nodes.remove_at(
			node.get_meta(&"input_slot"))
		
	if is_slot_enabled_right(slot_index):
		var output_slot: int = node.get_meta(&"output_slot")
		if has_any_output(output_slot):
			var out_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, node.get_meta(&"output_slot"))
			var target_slot: int = out_target.get_port_connected_to(PortMode.INPUT, self, node.get_meta(&"output_slot"))
			disconnect_requested.emit(
				get_node_uuid(),
				node.get_meta(&"output_slot"),
				out_target.get_node_uuid(),
				target_slot,
				self)
			await node_disconnected
			await get_tree().process_frame
		_output_nodes.remove_at(
			node.get_meta(&"output_slot"))
	
	#remove_child(node)
	var node_size: Vector2 = node.size
	#var field_idx: int = node.get_index()
	#set_slot(field_idx, false, -1, Color.BLACK, false, -1, Color.BLACK, null, null)
	if 0 < size_change:
		size.y -= size_change
		#deferred_resizing(size_change)
	elif size_change < 0:
		size.y = 0
	else:
		size.y -= node_size.y + (get_theme_constant("separation") if 0 < get_child_count() else 0)
		#deferred_resizing(node.size.y + (get_theme_constant("separation") if 0 < get_child_count() else 0))
	#node.free()
	node.queue_free()
	#node.visible = false


func remove_fields(field_ids: Array[StringName], size_change: int = 0) -> void:
	if field_ids.is_empty():
		return
	
	var target_nodes: Array[Control] = []
	var compound_size: float = 0.0
	
	for child in get_children():
		if field_ids.has(child.name):
			target_nodes.append(child)
	
	if target_nodes.is_empty():
		return
	
	target_nodes.sort_custom(func (a:Control,b:Control): return b.get_index() < a.get_index())
	
	for node in target_nodes:
		var slot_index: int = node.get_index()
		
		if is_slot_enabled_left(slot_index): # Checking if input enabled
			if has_any_input(node.get_meta(&"input_slot")):
				var in_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, node.get_meta(&"input_slot"))
				var target_slot: int = in_target.get_port_connected_to(PortMode.OUTPUT, self, node.get_meta(&"input_slot"))
				disconnect_requested.emit(
					in_target.get_node_uuid(),
					target_slot,
					get_node_uuid(),
					node.get_meta(&"input_slot"),
					self)
				await node_disconnected
				#await get_tree().process_frame
			_input_nodes.remove_at(
				node.get_meta(&"input_slot"))
			
		if is_slot_enabled_right(slot_index):
			var output_slot: int = node.get_meta(&"output_slot")
			if has_any_output(output_slot):
				var out_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, node.get_meta(&"output_slot"))
				var target_slot: int = out_target.get_port_connected_to(PortMode.INPUT, self, node.get_meta(&"output_slot"))
				disconnect_requested.emit(
					get_node_uuid(),
					node.get_meta(&"output_slot"),
					out_target.get_node_uuid(),
					target_slot,
					self)
				await node_disconnected
				#await get_tree().process_frame
			_output_nodes.remove_at(
				node.get_meta(&"output_slot"))
		compound_size += node.size.y
	#remove_child(node)
	for node in target_nodes:
		node.free()
	
	#await get_tree().process_frame
	#var field_idx: int = node.get_index()
	#set_slot(field_idx, false, -1, Color.BLACK, false, -1, Color.BLACK, null, null)
	if 0 < size_change:
		size.y -= size_change
		#deferred_resizing(size_change)
	elif size_change < 0:
		size.y = 0
	else:
		size.y -= compound_size + (get_theme_constant("separation") * (target_nodes.size() - 1) if 0 < target_nodes.size() else 0)
		#deferred_resizing(node.size.y + (get_theme_constant("separation") if 0 < get_child_count() else 0))
	#node.queue_free()
	#node.visible = false


func deferred_resizing(amount: int) -> void:
	size_change += amount
	if not resizing:
		resizing = true
		ress.call_deferred()


func ress() -> void:
	resizing = false
	size.y -= size_change
	size_change = 0
	



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


func disconnect_port(port_mode: PortMode, port_idx: int, connection_idx: int = 0) -> void:
	if port_mode == PortMode.INPUT:
		if port_idx < _input_nodes.size() and connection_idx < _input_nodes[port_idx]["connections"].size():
			var input_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, port_idx, connection_idx)
			disconnect_requested.emit(
				input_target.get_node_uuid(),
				input_target.get_port_connected_to(PortMode.OUTPUT, self, port_idx),
				get_node_uuid(),
				port_idx,
				self)
	elif port_mode == PortMode.OUTPUT:
		if port_idx < _output_nodes.size() and connection_idx < _output_nodes[port_idx]["connections"].size():
			var output_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, port_idx, connection_idx)
			disconnect_requested.emit(
				get_node_uuid(),
				port_idx,
				output_target.get_node_uuid(),
				output_target.get_port_connected_to(PortMode.INPUT, self, port_idx),
				self)


#func disconnect_all() -> void:
	#for input_port in range(_input_nodes.size()):
		#for connection_idx in range(_input_nodes[input_port]["connections"].size()):
			#var input_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, input_port, connection_idx)
			#disconnect_requested.emit(
				#input_target.get_node_uuid(),
				#input_target.get_port_connected_to(PortMode.OUTPUT, self, input_port),
				#get_node_uuid(),
				#input_port,
				#self)
	#
	#for output_port in range(_output_nodes.size()):
		#for connection_idx in range(_output_nodes[output_port]["connections"].size()):
			#var output_target: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, output_port, connection_idx)
			#disconnect_requested.emit(
				#get_node_uuid(),
				#output_port,
				#output_target.get_node_uuid(),
				#output_target.get_port_connected_to(PortMode.INPUT, self, output_port),
				#self)


func is_node_localized() -> bool:
	return _uses_localization


func get_node_uuid() -> StringName:
	return _uuid
