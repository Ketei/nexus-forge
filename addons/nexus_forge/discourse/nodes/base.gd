@tool
class_name DiscourseGraphNode
extends GraphNode


## Signal emitted when a disconnection needs to be made. Used
## for the Discourse [GraphEdit].
signal disconnect_requested(from: StringName, out_port: int, to: StringName, in_port: int, caller: DiscourseGraphNode)
## Emitted when the user presses the close button.
signal close_requested(node: DiscourseGraphNode)
## Emitted when the user presses the duplicate button.
signal duplicate_requested(node: DiscourseGraphNode)
## Emitted when the user presses the localize button.
signal localize_node_toggled(toggled_on: bool, node: DiscourseGraphNode)
## Signals when the node was resized.
## [br][br]
## Note: For this signal to emit [member resizable] has to be
## [code]true[/code] BEFORE the node is ready
## (normally by being added to the scene).[br]
signal node_resized(node_uuid: StringName, from: Vector2, to: Vector2)
## Emitted when a non-specific change is made to the node. Used
## to trigger the unsaved file flag on Discourse without creating
## an undo/redo action.
signal node_updated
## Signal used INTERNALLY to know when the Discourse [GraphEdit]
## disconnected nodes after a request was made.
signal node_disconnected


## Used to define port modes in multiple methods.
enum PortMode {
	NONE, ## Signals to no port.
	INPUT, ## Signals that it is referring to an input port.
	OUTPUT, ## Signals that it is referring to an output port.
}

## Defines the connection types for Discourse [GraphEdit]
enum SlotConnectionType {
	DIALOG, ## Dialogue flow.
	CALL, ## Method node.
	SIGNAL, ## Signal node.
	VAR_BOOL, ## Boolean data type.
	VAR_STRING, ## String data type.
	VAR_INT, ## Integer data type.
	VAR_FLOAT, ## Float data type.
	VAR_ANY, ## Connects to any data type.
	VAR_GUARD, ## Connects to any input. Used for compatibility.
	VAR_FORWARD, ## Inputs to any data, outputs same data type.
	SETTINGS_CHARACTER, ## Character settings.
	SETTINGS_DIALOG, ## Dialogue settings.
	SETTINGS_OPTION, ## Choice entry settings.
	RESOURCE, ## Represents a resource path.
	METADATA, ## Metadata node.
}

## Types of issue.
enum IssueLevel {
	ERROR = 0, ## Represents a critical issue that will cause problems.
	WARNING = 1 ## Represents a non-critical issue.
}

## The different types a node can be.
const DialogueNodeType := NFDialogParser.NodeTypes

## Colours used on the ports based on their types.
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
	"metadata": Color(0.541, 0.624, 0.82)}

## Color to tint the localization button when it is toggled.
const LOCALIZED_COLOR: Color = Color.LIME_GREEN

## The arrow icon that indicates dialogue flow
@onready var flow_icon: Texture2D = preload("res://addons/nexus_forge/icons/right_arrow.png")

## The type of node this graph represents
var node_type: DialogueNodeType = DialogueNodeType.DIALOG

var _uuid: StringName = &""
var _node_id: StringName = &""
var _uses_localization: bool = false
var _prev_size: Vector2 = Vector2.ZERO
var _resizing: bool = false
## Which port side connects to the "owner" of this node.
## Which is the node that utilizes this node
var parent_mode: PortMode = PortMode.INPUT
## Which port the "owner" of this node is connected to
var parent_port: int = 0
## The icon used by this node.
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
	_uuid = StringName(NFUUID.generate_new()) if uuid.is_empty() else uuid
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
	
	ready.connect(_ready_signaled, CONNECT_ONE_SHOT)


func _ready_signaled() -> void:
	if resizable:
		resize_request.connect(_on_resize_requested)
		resize_end.connect(_on_resize_end)


func _on_resize_requested(new_size: Vector2) -> void:
	if _resizing:
		return
	_resizing = true
	_prev_size = size


func _on_resize_end(new_size: Vector2) -> void:
	_resizing = false
	
	if _prev_size == new_size:
		return
	
	node_resized.emit(
			get_node_uuid(),
			_prev_size,
			new_size)


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
	var data: Dictionary = {"name": _node_id, "type": node_type, "metadata": meta}
	
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
	if data.has("name") and typeof(data["name"]) == TYPE_STRING_NAME:
		_node_id = data["name"]
	
	if not data.has("metadata") or typeof(data["metadata"]) != TYPE_DICTIONARY:
		return
	
	var metadata: Dictionary = data["metadata"]
	
	if metadata.has("position") and typeof(metadata["position"]) == TYPE_VECTOR2:
		position_offset = metadata["position"]
	
	if metadata.has("localized") and typeof(metadata["localized"]) == TYPE_BOOL:
		set_node_localized(metadata["localized"])


func _on_localization_toggled(toggle: bool) -> void:
	var node: Button = _get_localize_button()
	if node == null:
		return
	node.disabled = true
	node.modulate = LOCALIZED_COLOR if toggle else Color.WHITE
	_uses_localization = toggle
	localize_node_toggled.emit(toggle, self)


## Returns a complete snapshot of this node state. Including
## internal data and input/output connections.
func get_node_state() -> Dictionary:
	var data: Dictionary = _get_node_data()
	var input_connections: Dictionary = {}
	var output_connections: Dictionary = {}
	
	var state: Dictionary = {
		"data": data,
		"input_connections": input_connections,
		"output_connections": output_connections}
	
	var port: int = -1
	for input_connection in _input_nodes:
		port += 1
		var slot: int = get_slot_from_port(PortMode.INPUT, port)
		var connections: Array[Dictionary] = []
		
		for connection_index in input_connection["connections"].size():
			connections.append(
					get_uuid_and_port_connected_to(
							PortMode.INPUT,
							port,
							connection_index))
		input_connections[input_connection["field_id"]] = {
			"port": port, # Port ID
			"slot": slot, # Slot Index,
			"connections": connections}
	port = -1
	for output_connection in _output_nodes:
		port += 1
		var slot: int = get_slot_from_port(PortMode.OUTPUT, port)
		var connections: Array[Dictionary] = []
		for connection_index in output_connection["connections"].size():
			connections.append(
					get_uuid_and_port_connected_to(PortMode.OUTPUT, port, connection_index))
		
		output_connections[output_connection["field_id"]] = {
			"port": port,
			"slot": slot,
			"connections": connections}
	
	return state


## Sets if this node is localized or not.
func set_node_localized(is_localized: bool) -> void:
	_uses_localization = is_localized
	var localization_button: Button = _get_localize_button()
	if localization_button == null:
		return
	localization_button.set_pressed_no_signal(is_localized)
	localization_button.disabled = is_localized
	localization_button.modulate = LOCALIZED_COLOR if is_localized else Color.WHITE


## Shows/hides the localization buton of the node. If the
## button does not exist, does nothing.
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


## Sets the [param icon] of an input connection that was mapped to
## [param field_id].
func set_input_connection_icon(field_id: StringName, icon: Texture2D) -> void:
	if field_id.is_empty():
		return
	
	for node in get_children():
		if node.name == field_id:
			var txrct: TextureRect = node.get_child(0)
			txrct.texture = icon
			txrct.visible = icon != null
			break


## Sets the [param icon] of an output connection that was mapped to
## [param field_id].
func set_output_connection_icon(field_id: StringName, icon: Texture2D) -> void:
	for node in get_children():
		if node.name != field_id:
			continue
		var txtrct: TextureRect = node.get_child(2)
		txtrct.texture = icon
		txtrct.visible = icon != null


## Sets both the [param input_icon] and [param input_icon] of the
## field mapped to [param field_id].
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


## Enables/disables the ability to connect multiple connections
## to a single input port.
## [br][br]
## [color=yellow]Warning:[/color] This feature has [b]NOT[/b] been
## tested.
func set_input_allow_multiple(input_idx: int, allow_multiple_inputs: bool) -> void:
	_input_nodes[input_idx]["multi_connection"] = allow_multiple_inputs


## Enables/disables the ability to connect multiple connections
## to a single input port.
## [br][br]
## [color=yellow]Warning:[/color] This feature has [b]NOT[/b] been
## tested.
func set_output_allow_multiple(input_idx: int, allow_multiple_inputs: bool) -> void:
	_output_nodes[input_idx]["multi_connection"] = allow_multiple_inputs


## Returns if the port with index [param input_idx] can accept
## multiple connections.
func can_input_multiple(input_idx: int) -> bool:
	return _input_nodes[input_idx]["multi_connection"]


## Returns wheter a port can accept a connection or not.[br]
## [param port_type] refers if it's an input/output port, while
## [param port] is the port index to check.
## [br][br]
## A port might not be able to accept a connection if it has already
## one and can't connect multiple, the port is disabled or not visible,
## or the port isn't enabled or doesn't exist.
func is_port_available(port_type: PortMode, port: int) -> bool:
	var slot: int = get_slot_from_port(port_type, port)
	
	if not get_child(slot).visible:
		return false
	
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


## Returns if the port with index [param input_idx] can extend
## multiple connections.
func can_output_multiple(output_idx: int) -> bool:
	return _output_nodes[output_idx]["multi_connection"]


## Returns how many connections are established to
## the node's [param input_port] index.
func get_input_connection_count(input_port: int) -> int:
	var port_count: int = _input_nodes.size()
	var max_port_index: int = port_count - 1
	if max_port_index < 0:
		return 0
	if not NFRangeUtils.is_between(input_port, -port_count, max_port_index):
		return 0
	return _input_nodes[input_port]["connections"].size()


## Returns how many connections are established to or from
## the node's [param port] index.
func get_connection_count(port_type: PortMode, port: int) -> int:
	if port_type == PortMode.INPUT:
		return get_input_connection_count(port)
	elif port_type == PortMode.OUTPUT:
		return get_output_connection_count(port)
	else:
		return 0


## Returns the [DiscourseGraphNode] node connected to this node's
## input/output [param port]. An optional [param connection_index]
## exists for nodes that accept multiple connections.
func get_node_connected_to_port(port_type: PortMode, port: int, connection_index: int = 0) -> DiscourseGraphNode:
	var connection_count: int = get_connection_count(port_type, port)
	
	if connection_count == 0:
		return null
	
	if port_type == PortMode.INPUT:
		var in_connections_size: int = _input_nodes[port]["connections"].size()
		var max_in_connection_index: int = in_connections_size - 1
		if not NFRangeUtils.is_between(connection_index, -in_connections_size, max_in_connection_index):
			return null
		return _input_nodes[port]["connections"][connection_index]["target_node"]
		
	elif port_type == PortMode.OUTPUT:
		var out_connections_size: int = _output_nodes[port]["connections"].size()
		var max_out_connection_index: int = out_connections_size - 1
		if not NFRangeUtils.is_between(connection_index, -out_connections_size, max_out_connection_index):
			return null
		return _output_nodes[port]["connections"][connection_index]["target_node"]
	else:
		return null


## Returns the port type that this node's [param port] index is connected to.[br]
## If this node's port isn't connected it returns [code]-1[/code].[br]
## An optional [param connection_index] exists for nodes
## that accept multiple connections.
func get_target_port_connected_to_port(port_type: PortMode, port:int, connection_index: int = 0) -> int:
	if port_type == PortMode.INPUT:
		var port_count: int = _input_nodes.size()
		if port_count == 0:
			return -1
		
		if NFRangeUtils.is_between(port, -port_count, port_count - 1):
			var conn_arr: Array = _input_nodes[port]["connections"]
			var connections: int = conn_arr.size()
			if connections == 0:
				return -1
			
			if NFRangeUtils.is_between(connection_index, -connections, connections - 1):
				return conn_arr[connection_index]["target_port"]
	
	elif port_type == PortMode.OUTPUT:
		var out_port_count: int = _output_nodes.size()
		if out_port_count == 0:
			return -1
		
		if NFRangeUtils.is_between(port, -out_port_count, out_port_count - 1):
			var out_conn_arr: Array = _output_nodes[port]["connections"]
			var out_con_size: int = out_conn_arr.size()
			if out_con_size == 0:
				return -1
			
			if NFRangeUtils.is_between(connection_index, -out_con_size, out_con_size - 1):
				return out_conn_arr[connection_index]["target_port"]
	
	return -1


## Returns if the port's [param input_idx] has ANY connection.
func has_any_input(input_idx: int) -> bool:
	var input_count: int = _input_nodes.size()
	if input_count == 0:
		return false
	var max_index: int = input_count - 1
	if not NFRangeUtils.is_between(input_idx, -input_count, max_index):
		return false
	return not _input_nodes[input_idx]["connections"].is_empty()


## Returns if there is a connection on the [param input_port] index
## AND on the specific [param connection_index].
func has_input_on(input_port: int, connection_index: int = 0) -> bool:
	var port_count: int = _input_nodes.size()
	if port_count == 0:
		return false
	var max_port_index: int = port_count - 1
	
	if not NFRangeUtils.is_between(input_port, -port_count, max_port_index):
		return false
	
	var connection_count: int = _input_nodes[input_port]["connections"].size()
	if connection_count == 0:
		return false
	var max_connection_index: int = connection_count - 1
	return NFRangeUtils.is_between(connection_index, -connection_count , max_connection_index)


## Returns the UUID of the node that is connected to this node's [param port].
## An optional [param connection_index] argument is available for nodes
## that allow multiple connections.
func get_target_node_uuid(port_mode: PortMode, port: int, connection_index: int = 0) -> StringName:
	if port_mode == PortMode.INPUT:
		if has_input_on(port, connection_index):
			return get_node_connected_to_port(
					port_mode,
					port,
					connection_index).get_node_uuid()
	elif port_mode == PortMode.OUTPUT:
		if has_output_on(port, connection_index):
			return get_node_connected_to_port(
					port_mode,
					port,
					connection_index).get_node_uuid()
	return &""


## Returns if the [param node] is connected to this node's input
## [param port] index.
func is_connected_to_input(port: int, node: DiscourseGraphNode) -> bool:
	if not is_instance_valid(node):
		return false
	
	var port_count: int = _input_nodes.size()
	if port_count == 0:
		return false
	var max_port_index: int = port_count - 1
	
	if not NFRangeUtils.is_between(port, -port_count, max_port_index):
		return false
	
	for item in _input_nodes[port]["connections"]:
		if item["target_node"] == node:
			return true
	return false


## Returns if the port's [param output_idx] has ANY connection.
func has_any_output(output_idx: int) -> bool:
	var output_count: int = _output_nodes.size()
	if output_count == 0:
		return false
	var max_index: int = output_count - 1
	if not NFRangeUtils.is_between(output_idx, -output_count, max_index):
		return false
	
	return not _output_nodes[output_idx]["connections"].is_empty()


## Returns if there is a connection on the [param output_port] index
## AND on the specific [param connection_index].
func has_output_on(output_port: int, connection_index: int = 0) -> bool:
	var port_count: int = _output_nodes.size()
	if port_count == 0:
		return false
	var max_port_index: int = port_count - 1
	
	if not NFRangeUtils.is_between(output_port, -port_count, max_port_index):
		return false
	
	var connection_count: int = _output_nodes[output_port]["connections"].size()
	if connection_count == 0:
		return false
	var max_connection_index: int = connection_count - 1
	return NFRangeUtils.is_between(connection_index, 0, max_connection_index)


## Returns if an input/output port exists on index [param idx].
func has_port(mode: PortMode, idx: int) -> bool:
	if mode == PortMode.INPUT:
		var in_size: int = _input_nodes.size()
		if in_size == 0:
			return false
		return NFRangeUtils.is_between(idx, -in_size, in_size - 1)
	elif mode == PortMode.OUTPUT:
		var out_size: int = _output_nodes.size()
		if out_size == 0:
			return false
		return NFRangeUtils.is_between(idx, -out_size, out_size - 1)
	
	return false


## Returns if the [param node] is connected to this node's output
## [param port] index.
func is_connected_to_output(port: int, node: DiscourseGraphNode) -> bool:
	if not is_instance_valid(node):
		return false
	
	var port_count: int = _output_nodes.size()
	if port_count == 0:
		return false
	var max_port_index: int = port_count - 1
	if not NFRangeUtils.is_between(port, -port_count, max_port_index):
		return false
	
	for item in _output_nodes[port]["connections"]:
		if item["target_node"] == node:
			return true
	return false


## Returns if the [param node] is connected to this node's
## [param port] index.
func is_node_connected_to(port_mode: PortMode, port: int, node: DiscourseGraphNode) -> bool:
	if port_mode == PortMode.INPUT:
		return is_connected_to_input(port, node)
	elif port_mode == PortMode.OUTPUT:
		return is_connected_to_output(port, node)
	else:
		return false


## Returns the port index of this node that is connected to the
## [param target_node] on the target's [param target_port].[br]
## Returns [code]-1[/code] if the connection wasn't found.
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


## Gets this node's connection index of the connection from the [param port]
## to the [param node]'s [param target_port].
func get_connection_index(port_mode: PortMode, port: int, node: DiscourseGraphNode, target_port: int) -> int:
	if port_mode == PortMode.NONE:
		return -1
	
	var target_array: Array[Dictionary] = _input_nodes if port_mode == PortMode.INPUT else _output_nodes
	
	var port_count: int = target_array.size()
	
	if port_count == 0:
		return -1
	
	var max_index: int = port_count - 1
	
	if not NFRangeUtils.is_between(port, -port_count, max_index):
		return -1
	
	var idx: int = -1
	var target_dict: Array[Dictionary] = target_array[port]["connections"]
	for item:Dictionary in target_dict:
		idx += 1
		if item["target_node"] == node and item["target_port"] == target_port:
			return idx
	return -1


## Returns the connection index on the input port index [param on_input]
## that is connected to the node [param input_node].
func get_input_connection_idx(on_input: int, input_node: DiscourseGraphNode) -> int:
	var input_connections: int = _input_nodes.size()
	if input_connections == 0:
		return -1
	elif not NFRangeUtils.is_between(on_input, -input_connections, input_connections - 1):
		return -1
	
	var idx: int = -1
	for connection:DiscourseGraphNode in _input_nodes[on_input]["connections"]:
		idx += 1
		if input_node == connection:
			return idx
	return -1


## Returns the current amount of connections coming out of the
## [param output_port] index of this node.
func get_output_connection_count(output_port: int) -> int:
	var port_count: int = _output_nodes.size()
	if port_count == 0:
		return 0
	elif not NFRangeUtils.is_between(output_port, -port_count, port_count - 1):
		return 0
	
	return _output_nodes[output_port]["connections"].size()


## Gets which connection index does a node have.
func get_output_connection_idx(on_output: int, output_node: DiscourseGraphNode) -> int:
	var idx: int = -1
	for connection:DiscourseGraphNode in _output_nodes[on_output]["connections"]:
		idx += 1
		if output_node == connection:
			return idx
	return -1


## Returns a dictionary containing the UUID and port of the node that this
## node's [param port] is connected to.[br]
## A [param connection_index] can specify the index of the connection.
## [br][br]
## Key [code]"target_node_uuid"[/code] contains the UUID of the connected
## node.[br]
## Key [code]"target_port"[/code] contains the node's port index that the
## connection reaches to[br]
## Key [code]"from_port"[/code] will always match to [param port]
## regardless if it's an input or output.
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


## Gets the port that is connected to this node's [param port] with the given
## [param connection_index].
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
			"slot": new_index,
			"multi_connection": false,
			"connections": Array([], TYPE_DICTIONARY, &"", null)})
	
	if 0 <= right_slot_type:
		set_slot_enabled_right(new_index, true)
		set_slot_type_right(new_index, right_slot_type)
		_output_nodes.append({
			"field_id": field_id,
			"slot": new_index,
			"multi_connection": false,
			"connections": Array([], TYPE_DICTIONARY, &"", null)})
	
	field_box.set_meta(&"input_slot", input_slot)
	field_box.set_meta(&"output_slot", output_slot)
	
	return new_index


## Sets the visibility of the field with [param field_id] to
## [param field_visible].
func set_field_visible(field_id: StringName, field_visible: bool) -> void:
	if field_id.is_empty():
		return
		
	var field = get_node_or_null(NodePath(field_id))
	
	if field == null:
		return
	
	if field_visible:
		field.visible = field_visible
		return
	
	var slot: int = field.get_index()
	var in_port: int = field.get_meta(&"input_slot", -1)
	var out_port: int = field.get_meta(&"output_slot", -1)
	if -1 < in_port and is_slot_enabled_left(slot) and has_any_input(in_port):
		var from_graph: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, in_port)
		disconnect_requested.emit(
			from_graph.get_node_uuid(),
			from_graph.get_port_connected_to(PortMode.OUTPUT, self, in_port),
			get_node_uuid(),
			in_port,
			self)
		await node_disconnected
	if -1 < out_port and is_slot_enabled_right(slot) and has_any_output(out_port):
		var to_graph: DiscourseGraphNode = get_node_connected_to_port(PortMode.OUTPUT, out_port)
		disconnect_requested.emit(
			get_node_uuid(),
			out_port,
			to_graph.get_node_uuid(),
			to_graph.get_port_connected_to(PortMode.INPUT, self, out_port),
			self)
		await node_disconnected
	field.visible = field_visible


## Returns if the given [param field_id] exists within this node.
func has_field(field_id: StringName) -> bool:
	if field_id.is_empty():
		return false
	return has_node(NodePath(field_id))


## Returns whether the [param field_id] has any output.
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
		return not _output_nodes[output_port]["connections"].is_empty()


## Returns whether the [param field_id] has any input.
func has_any_field_input(field_id: StringName) -> bool:
	if field_id.is_empty():
		return false
	
	var field = get_field(field_id)
	
	if field == null:
		return false
	
	var input_port: int = field.get_meta(&"input_slot", -1)
	
	if input_port <= -1:
		return false
	else:
		return not _input_nodes[input_port]["connections"].is_empty()


## Returns the node that was registered with [param field_id].
func get_field(field_id: StringName) -> Control:
	if field_id.is_empty():
		return null
	var child: Control = get_node_or_null(NodePath(field_id))
	
	return null if child == null else child.get_child(1)


## Returns the node of a field using the index [param field_index].
func get_index_field(field_index: int) -> Control:
	var child_count: int = get_child_count()
	
	if child_count == 0:
		return null
	
	if not NFRangeUtils.is_between(field_index, -child_count, child_count - 1):
		return null
	
	var true_index: int = wrapi(field_index, 0, child_count)
	
	return get_child(true_index).get_child(1)


## Returns the input port index of the field [param field_id]
## if it is enabled.
func get_field_input_port(field_id: StringName) -> int:
	if field_id.is_empty():
		return -1
	
	var node = get_field(field_id)
	
	return -1 if node == null else node.get_meta(&"input_slot", -1)


## Returns the input slot index of the field [param field_id]
## if it is enabled.
func get_field_input_slot(field_id: StringName) -> int:
	if field_id.is_empty():
		return -1
	
	var node = get_field(field_id)
	
	return -1 if node == null else node.get_index()


## Returns the slot index using its [param port].
func get_slot_from_port(mode: PortMode, port: int) -> int:
	if mode == PortMode.INPUT:
		if _input_nodes.size() <= port:
			return -1
		return _input_nodes[port]["slot"]
	elif mode == PortMode.OUTPUT:
		if _output_nodes.size() <= port:
			return -1
		return _output_nodes[port]["slot"]
	else:
		return -1


## Returns the output slot index of the field [param field_id].
func get_field_output_slot(field_id: StringName) -> int:
	if field_id.is_empty():
		return -1
	
	var node = get_field(field_id)
	
	return -1 if node == null else node.get_meta(&"output_slot", -1)


## Removes the field with the id [param field_id].[br]
## If [param size_change] is greater than [code]0[/code], it'll
##try to change the node's size after removing the field by that amount.[br]
## If the size is less than [code]0[/code], it'll try to reset the
## node's size.[br]
## If it's [code]0[/code], it'll try to reduce the field's size from
## the height.
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
	
	var node_size: Vector2 = node.size
	
	if 0 < size_change:
		size.y -= size_change
	elif size_change < 0:
		size.y = 0
	else:
		size.y -= node_size.y + (get_theme_constant("separation") if 0 < get_child_count() else 0)
	
	node.queue_free()


## Removes all the fields specified on [param field_ids].[br]
## param size_change behaves similar to [method DiscourseGraphNode.remove_field]
## size_change after removing all fields.
func remove_fields(field_ids: Array[StringName], size_change: int = 0) -> void:
	if field_ids.is_empty():
		return
	
	var target_nodes: Array[Control] = []
	var compound_size: float = 0.0
	
	for child in get_children():
		if not is_instance_valid(child) or child.is_queued_for_deletion():
			continue
		if field_ids.has(child.name):
			target_nodes.append(child)
	
	if target_nodes.is_empty():
		return
	
	var target_count: int = target_nodes.size()
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
			_output_nodes.remove_at(
				node.get_meta(&"output_slot"))
		compound_size += node.size.y
	for node in target_nodes:
		clear_slot(node.get_index())
		node.free()
	
	if 0 < size_change:
		size.y -= size_change
	elif size_change < 0:
		size.y = 0
	else:
		size.y -= compound_size + (get_theme_constant("separation") * (target_count - 1) if 0 < target_count else 0)


## Returns if this node is an orphan. To do so it takes into account the
## data sent on [member parent_mode] and [member parent_port].
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


## Emits the disconnection signal
## [signal DiscourseGraphNode.disconnect_requested] to be used by a
## [GraphEdit].
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


## Returns wheter this node is localized or not.
func is_node_localized() -> bool:
	return _uses_localization


## Returns the UUID assigned to this node.
func get_node_uuid() -> StringName:
	return _uuid


## Returns the custom ID assigned to this node.
func get_node_id() -> StringName:
	return _node_id


## Sets this node's ID.
func set_node_id(new_id: StringName) -> void:
	_node_id = new_id
