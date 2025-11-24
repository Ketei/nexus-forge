@tool
extends GraphEdit


signal node_created(node: DiscourseGraphNode)
signal dialog_changed
signal anchor_created(anchor: DiscourseGraphNode)
signal localization_enabled(node: DiscourseGraphNode)
signal localized_text_created(node: DiscourseGraphNode)
signal node_deleted(uuid: StringName)

const DialogNodes = DialogParser.NodeTypes
const ConnectionType = DiscourseGraphNode.SlotConnectionType
const PortFlow = DiscourseGraphNode.PortMode

var compatible_connections: Dictionary = {}
var focus_tween: Tween = null
var node_clipboard: Array[Dictionary] = []
var entry_node: DiscourseGraphNode = null
var connection_popup: PopupMenu = null
var anchor_pointers: Array[DiscourseGraphNode] = []
var graph_nodes: Array[DiscourseGraphNode] = []
var method_callers: Array[DiscourseGraphNode] = []
var signalers: Array[DiscourseGraphNode] = []


func _ready() -> void:
	#if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		#print("Blocking ready")
		#return
	connection_popup = PopupMenu.new()
	connection_popup.name = &"ConnectionsPopupMenu"
	connection_popup.visible = false
	add_child(connection_popup)
	connection_popup.set_meta(&"release_data", {})
	setup_compatible_nodes()
	connection_popup.index_pressed.connect(_on_popup_index_pressed.bind(connection_popup))
	grid_pattern = GraphEdit.GRID_PATTERN_DOTS
	right_disconnects = true
	zoom_min = 0.2
	zoom_max = 2.0
	show_menu = true
	show_zoom_label = true
	show_zoom_buttons = true
	show_grid_buttons = false
	show_minimap_button = false
	show_arrange_button = false
	
	# -- Debug --
	#var nodes: Array[DiscourseGraphNode] = []
	#for type in DialogNodes.values():
		#var node: DiscourseGraphNode = create_dialog_node(type)
		#if node != null:
			#
	#
	#var frame = create_node_frame()
	#frame.name = &"Frame"
	#frame.position_offset = Vector2(400.0, 400.0)
	#add_child(frame)
	#
	#for node in nodes:
		#add_child(node)
	# -----------
	add_valid_connection_type(
			ConnectionType.VAR_INT,
			ConnectionType.VAR_ANY)
	add_valid_connection_type(
			ConnectionType.VAR_FLOAT,
			ConnectionType.VAR_ANY)
	add_valid_connection_type(
			ConnectionType.VAR_BOOL,
			ConnectionType.VAR_ANY)
	add_valid_connection_type(
			ConnectionType.VAR_STRING,
			ConnectionType.VAR_ANY)
	add_valid_connection_type(
			ConnectionType.VAR_GUARD,
			ConnectionType.VAR_INT)
	add_valid_connection_type(
			ConnectionType.VAR_GUARD,
			ConnectionType.VAR_FLOAT)
	add_valid_connection_type(
			ConnectionType.VAR_GUARD,
			ConnectionType.VAR_BOOL)
	add_valid_connection_type(
			ConnectionType.VAR_GUARD,
			ConnectionType.VAR_STRING)
	add_valid_connection_type(
			ConnectionType.VAR_INT,
			ConnectionType.VAR_FORWARD)
	add_valid_connection_type(
			ConnectionType.VAR_FLOAT,
			ConnectionType.VAR_FORWARD)
	add_valid_connection_type(
			ConnectionType.VAR_BOOL,
			ConnectionType.VAR_FORWARD)
	add_valid_connection_type(
			ConnectionType.VAR_STRING,
			ConnectionType.VAR_FORWARD)
	
	entry_node = create_dialog_node(DialogNodes.ENTRY)
	add_child(entry_node)
	graph_nodes.append(entry_node)
	
	connection_drag_started.connect(_on_connection_drag_started)
	begin_node_move.connect(_on_node_move_start)
	connection_request.connect(_on_connection_request)
	graph_elements_linked_to_frame_request.connect(_on_graph_elements_linked_to_frame_request)
	connection_to_empty.connect(_on_connection_to_empty)
	connection_from_empty.connect(_on_connection_from_empty)
	duplicate_nodes_request.connect(_on_duplicate_nodes_request)
	copy_nodes_request.connect(_on_copy_nodes_request)
	cut_nodes_request.connect(_on_cut_nodes_request)
	paste_nodes_request.connect(_on_paste_nodes_request)


func _on_copy_nodes_request() -> void:
	var selected_nodes: Array[DiscourseGraphNode] = get_selected_graph_nodes()
	if selected_nodes.is_empty():
		return
	node_clipboard.clear()
	var copy_data: Array[Dictionary] = []
	for selected_node in selected_nodes:
		var data: Dictionary = {"node_uuid": selected_node.get_node_uuid()}
		data.merge(selected_node._get_node_data())
		copy_data.append(data)
	copy_data.sort_custom(sort_clipboard_custom)
	node_clipboard.clear()
	node_clipboard.assign(copy_data)


func _on_cut_nodes_request() -> void:
	var cut_nodes: Array[DiscourseGraphNode] = get_selected_graph_nodes()
	if cut_nodes.is_empty():
		return
	var cut_data: Array[Dictionary] = []
	for cut_node in cut_nodes:
		var new_data: Dictionary = {
			"node_uuid": cut_node.get_node_uuid()}
		new_data.merge(cut_node._get_node_data())
		cut_data.append(new_data)
	for cut_node in cut_nodes:
		free_node(cut_node)
	cut_data.sort_custom(sort_clipboard_custom)
	node_clipboard.clear()
	node_clipboard.assign(cut_data)


func _on_paste_nodes_request() -> void:
	if node_clipboard.is_empty():
		return
	# {"from": original_uuid, "to": original_uuid, "to_port": 0, "from_port": 0}
	var new_connections: Array[Dictionary] = [] 
	# original uuid : new_node_pointer
	var uuid_equivalences: Dictionary[StringName, DiscourseGraphNode] = {}
	
	var current_offset: Vector2 = node_clipboard[0]["position"]
	var center_scroll_offset: Vector2 = get_center_offset()
	for node_data in node_clipboard:
		var new_data: Dictionary = node_data.duplicate(true)
		new_data["position"] = new_data["position"] - current_offset + center_scroll_offset
		var pasted_node: DiscourseGraphNode = create_dialog_node(new_data["node_type"])
		pasted_node._set_node_data(new_data)
		add_child(pasted_node)
		graph_nodes.append(pasted_node)
		pasted_node.position_offset -= pasted_node.size / 2.0
		uuid_equivalences[new_data["node_uuid"]] = pasted_node
	
		var _new_connections: Array[Dictionary] = get_connection_dictionary(
				new_data["node_uuid"],
				new_data)
		
		if not _new_connections.is_empty():
			new_connections.append_array(_new_connections)
		node_created.emit(pasted_node)
	
	for output_connection in new_connections:
		if not uuid_equivalences.has(output_connection["from"]) or not uuid_equivalences.has(output_connection["to"]):
			continue
		connect_nodes(
				uuid_equivalences[output_connection["from"]].name,
				output_connection["from_port"],
				uuid_equivalences[output_connection["to"]].name,
				output_connection["to_port"])
	
	dialog_changed.emit()


func _on_anchor_id_changed(uuid: String, new_id: String) -> void:
	var valid_id: String = DiscourseGraphAnchorPointer.get_available_id(new_id)
	DiscourseGraphAnchorPointer.update_anchor(uuid, valid_id)
	for anchor in anchor_pointers:
		anchor.reload_anchors()


func _close_requested(node: DiscourseGraphNode) -> void:
	graph_nodes.erase(node)
	node_deleted.emit(node.get_node_uuid())
	dialog_changed.emit()
	free_node(node)
	


func free_node(node: DiscourseGraphNode) -> void:
	if node.node_type == DialogNodes.ANCHOR:
		DiscourseGraphAnchorPointer.remove_anchor(node.get_node_uuid())
		for anchor_pointer in anchor_pointers:
			anchor_pointer.reload_anchors()
	
	node.disconnect_all()
	remove_child(node)
	
	node.queue_free()


func _on_duplicate_node_button_pressed(node: DiscourseGraphNode) -> void:
	var new_node: DiscourseGraphNode = create_dialog_node(node.node_type)
	var frame: GraphFrame = get_element_frame(node.name)
	new_node._set_node_data(node._get_node_data())
	new_node.position_offset += Vector2(100.0, 100.0)
	
	#if new_node.node_type == DialogNodes.ANCHOR_POINTER:
		#anchor_pointers.append(new_node)
	if new_node.node_type == DialogNodes.ANCHOR:
		var cloned_id: String = new_node.get_anchor_id()
		var new_id: String = DiscourseGraphAnchorPointer.get_available_id(cloned_id)
		
		DiscourseGraphAnchorPointer.update_anchor(new_node.get_node_uuid(), new_id)
		
		new_node.set_anchor_id(new_id)
		
		#for anchor_pointer in anchor_pointers:
			#anchor_pointer.reload_anchors()
		
		#new_node.id_changed.connect(_on_anchor_id_changed)
	#new_node.disconnect_requested.connect(_on_disconnection_request)
	#new_node.duplicate_requested.connect(_on_duplicate_node_button_pressed)
	#new_node.close_requested.connect(_close_requested)
	add_child(new_node)
	graph_nodes.append(new_node)
	if frame != null:
		attach_graph_element_to_frame(new_node.name, frame.name)
	node_created.emit(new_node)
	dialog_changed.emit()


func _on_duplicate_nodes_request() -> void:
	# {"from": original_uuid, "to": original_uuid, "to_port": 0, "from_port": 0}
	var new_connections: Array[Dictionary] = [] 
	# original uuid : new_node_pointer
	var uuid_equivalences: Dictionary[String, DiscourseGraphNode] = {}
	var sel_nodes := get_selected_graph_nodes()
	for node in sel_nodes:
		var new_node: DiscourseGraphNode = create_dialog_node(node.node_type)
		var old_data: Dictionary = node._get_node_data()
		var frame: GraphFrame = get_element_frame(node.name)
		new_node._set_node_data(old_data)
		new_node.position_offset += Vector2(100.0, 100.0)
		uuid_equivalences[node.get_node_uuid()] = new_node
		
		var node_connections: Array[Dictionary] = get_connection_dictionary(
				node.get_node_uuid(),
				old_data)
		if not node_connections.is_empty():
			new_connections.append_array(node_connections)
			
		add_child(new_node)
		graph_nodes.append(new_node)
		new_node.selected = true
		node.selected = false
		if frame != null:
			attach_graph_element_to_frame(new_node.name, frame.name)
		node_created.emit(new_node)
	
	for output_connection in new_connections:
		if not uuid_equivalences.has(output_connection["from"]) or not uuid_equivalences.has(output_connection["to"]):
			continue
		connect_nodes(
				uuid_equivalences[output_connection["from"]].name,
				output_connection["from_port"],
				uuid_equivalences[output_connection["to"]].name,
				output_connection["to_port"])
	dialog_changed.emit()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	get_node(NodePath(to_node)).set_input_connection(
			to_port,
			get_node(NodePath(from_node)),
			from_port,
			false)
	get_node(NodePath(from_node)).set_output_connection(
			from_port,
			get_node(NodePath(to_node)),
			to_port,
			false)
	disconnect_node(from_node, from_port, to_node, to_port)
	dialog_changed.emit()


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	connect_nodes(from_node, from_port, to_node, to_port)
	dialog_changed.emit()


func connect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if from_node == to_node:
		return
	var to_graph: DiscourseGraphNode = get_node(NodePath(to_node))
	var from_graph: DiscourseGraphNode = get_node(NodePath(from_node))
	var from_type: int = from_graph.get_slot_type_right(from_graph.get_output_port_slot(from_port))
	var to_type: int = to_graph.get_slot_type_left(to_graph.get_input_port_slot(to_port))
	
	var can_connect: bool = \
			from_graph.is_port_available(
					DiscourseGraphNode.PortMode.OUTPUT,
					from_port) and\
			to_graph.is_port_available(
					DiscourseGraphNode.PortMode.INPUT,
					to_port) and \
			( from_type == to_type or is_valid_connection_type(from_type, to_type) )
	
	if not can_connect:
		return
	connect_node(from_node, from_port, to_node, to_port)
	to_graph.set_input_connection(
			to_port,
			from_graph,
			from_port,
			true)
	from_graph.set_output_connection(
		from_port, to_graph, to_port, true)


func _on_graph_elements_linked_to_frame_request(elements: Array, frame: StringName) -> void:
	for element in elements:
		attach_graph_element_to_frame(element, frame)
	dialog_changed.emit()


func _on_node_move_start() -> void:
	dialog_changed.emit()
	if not Input.is_key_pressed(KEY_ALT):
		return
	for node in get_children():
		if node is GraphNode and node.selected and get_element_frame(node.name) != null:
			detach_graph_element_from_frame(node.name)


func _on_close_frame_pressed(frame: GraphFrame) -> void:
	for attatched_node in get_attached_nodes_of_frame(frame.name):
		detach_graph_element_from_frame(attatched_node)
	remove_child(frame)
	frame.queue_free()
	dialog_changed.emit()


func _on_connection_drag_started(from_node: StringName, from_port: int, is_output: bool) -> void:
	var from_graph: DiscourseGraphNode = get_node(NodePath(from_node))
	
	if is_output:
		if from_graph.is_port_available(DiscourseGraphNode.PortMode.OUTPUT, from_port):
			return
		var to_graph: DiscourseGraphNode = from_graph.get_node_connected_to_port(
				DiscourseGraphNode.PortMode.OUTPUT,
				from_port)
		var to_port: int = to_graph.get_port_connected_to(
				DiscourseGraphNode.PortMode.INPUT,
				from_graph,
				from_port)
		from_graph.set_output_connection(from_port, to_graph, to_port, false)
		to_graph.set_input_connection(to_port, from_graph, from_port, false)
		disconnect_node(
				from_node,
				from_port,
				to_graph.name,
				to_port)
		dialog_changed.emit()
	else: # is input
		if from_graph.is_port_available(DiscourseGraphNode.PortMode.INPUT, from_port):
			return
		
		var to_graph: DiscourseGraphNode = from_graph.get_node_connected_to_port(
					DiscourseGraphNode.PortMode.INPUT,
					from_port)
		var to_port: int = to_graph.get_port_connected_to(
				DiscourseGraphNode.PortMode.OUTPUT,
				from_graph,
				from_port)
		to_graph.set_output_connection(to_port, from_graph, from_port, false)
		from_graph.set_input_connection(from_port, to_graph, to_port, false)
		disconnect_node(
				to_graph.name,
				to_port,
				from_node,
				from_port)
		dialog_changed.emit()


## Creates a dialog node ready to be added. Connected to all relevant signals
func create_dialog_node(node_type: DialogNodes, uuid: String = "") -> DiscourseGraphNode:
	var created_node: DiscourseGraphNode = null
	
	match node_type:
		DialogNodes.ENTRY:
			if entry_node == null:
				created_node = preload("res://addons/nexus_forge/discourse/nodes/dialog_entry.gd").new(uuid, &"", false, false, false)
			else:
				if uuid != "":
					entry_node._uuid = uuid
				return entry_node
		DialogNodes.DIALOG:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/dialog_graph_node.gd").new(uuid, &"", true, true, true)
		DialogNodes.OPTIONS:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/dialog_options.gd").new(uuid, &"", true, true, true)
		DialogNodes.BRANCH:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/dialog_branch.gd").new(uuid)
		DialogNodes.CONDITION_SELECT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/conditional_select.gd").new(uuid, &"TypeData")
		DialogNodes.COMPARATION:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/comparation_node.gd").new(uuid, &"TypeData")
		DialogNodes.EVENT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/event_node.gd").new(uuid)
		DialogNodes.MATCH:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/match_node.gd").new(uuid)
		DialogNodes.PAUSE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/pause_node.gd").new(uuid)
		DialogNodes.RANDOM:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/random_select.gd").new(uuid)
		DialogNodes.TYPE_GUARD:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/type_guard.gd").new(uuid, &"TypeData")
		DialogNodes.VALUE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/value_node.gd").new(uuid, &"TypeData")
		DialogNodes.SIGNAL:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/signal_node.gd").new(uuid, &"TypeData")
			signalers.append(created_node)
		DialogNodes.CALLABLE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/method_call_node.gd").new(uuid, &"TypeData")
			method_callers.append(created_node)
		DialogNodes.CALLABLE_RETURN:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/method_call_return.gd").new(uuid, &"TypeData")
			method_callers.append(created_node)
		DialogNodes.VARIABLE_GET:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/var_getter.gd").new(uuid, &"TypeData")
		DialogNodes.ANCHOR_POINTER:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/jump_to_node.gd").new(uuid)
			anchor_pointers.append(created_node)
		DialogNodes.ANCHOR:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/jump_target_node.gd").new(uuid)
			var valid_id: String = DiscourseGraphAnchorPointer.get_available_id("anchor")
			DiscourseGraphAnchorPointer.add_anchor(created_node.get_node_uuid(), valid_id)
			created_node.set_anchor_id(valid_id)
			created_node.id_changed.connect(_on_anchor_id_changed)
			for anchor in anchor_pointers:
				anchor.reload_anchors()
		DialogNodes.DIALOG_END:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/end_node.gd").new(uuid)
		DialogNodes.DIALOG_MERGE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/dialog_joiner.gd").new(uuid)
		DialogNodes.COMMENT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/comment_node.gd").new(uuid)
		DialogNodes.SETTINGS_CHARACTER:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/char_settings_node.gd").new(uuid, &"TypeSettings")
		DialogNodes.SETTINGS_DIALOG:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/settings_dialog.gd").new(uuid, &"TypeSettings")
		DialogNodes.SETTINGS_OPTION:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/settings_option.gd").new(uuid, &"TypeSettings")
		DialogNodes.RANDOM_VALUE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/random_value.gd").new(uuid, &"TypeData")
		DialogNodes.RESOURCE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/resource_loader_graph.gd").new(uuid, &"TypeObject")
		DialogNodes.DATA_EVENT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/data_event.gd").new(uuid, &"TypeData")
		DialogNodes.LOCALIZED_TEXT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/localized_text.gd").new(uuid)
	
	created_node.node_updated.connect(dialog_changed.emit)
	created_node.disconnect_requested.connect(_on_disconnection_request)
	created_node.close_requested.connect(_close_requested)
	created_node.duplicate_requested.connect(_on_duplicate_node_button_pressed)
	created_node.localize_node_toggled.connect(_on_localize_node_toggled)
	
	created_node.name = get_unique_node_name(created_node.name)
	created_node.custom_id = get_unique_node_id(created_node.custom_id)
	
	return created_node


func get_unique_node_id(desired: String) -> String:
	var edited: String = desired
	var iteration: int = 0
	
	while has_node_id(edited):
		iteration += 1
		edited = desired + str(iteration)
	return edited


func get_unique_node_name(desired: StringName) -> StringName:
	var base: String = str(desired)
	var edited: String = base
	var iteration: int = 0
	while has_node(NodePath(edited)):
		iteration += 1
		edited = base + str(iteration)
	return StringName(edited)


func has_node_id(id: String) -> bool:
	for node in graph_nodes:
		if id == node.custom_id:
			return true
	return false


func _on_localize_node_toggled(is_pressed: bool, node: DiscourseGraphNode) -> void:
	if not is_pressed:
		return
	localization_enabled.emit(node)
	dialog_changed.emit()


func add_dialog_node_to_graph(node_type: DialogNodes, uuid: String = "") -> void:
	var new_node: DiscourseGraphNode = create_dialog_node(node_type, uuid)
	add_child(new_node)
	graph_nodes.append(new_node)
	new_node.position_offset = get_center_offset() - (new_node.size / 2.0)
	
	if node_type == DialogNodes.ANCHOR:
		anchor_created.emit(new_node)
	elif node_type == DialogNodes.LOCALIZED_TEXT:
		localized_text_created.emit(new_node)
	node_created.emit(new_node)


func add_frame_to_graph(uuid: String = "") -> void:
	var new_frame: GraphFrame = create_node_frame(uuid)
	add_child(new_frame)
	new_frame.position_offset = get_center_offset() - ( new_frame.size / 2.0 )


## Creates a node frame ready to be added. Connected to all relevant signals
func create_node_frame(uuid: String = "") -> GraphFrame:
	var new_frame: GraphFrame = preload("res://addons/nexus_forge/discourse/nodes/dialog_graph_frame.gd").new(uuid)
	new_frame.close_frame_pressed.connect(_on_close_frame_pressed)
	return new_frame


func snap_graph_to_grid(target_node: DiscourseGraphNode) -> void:
	if not snapping_enabled:
		return
	target_node.position_offset = target_node.position_offset.snappedf(snapping_distance)


## Focuses the child node in the graph node.
func focus_graph_node(node: DiscourseGraphNode, animate: bool = true) -> void:
	if focus_tween != null:
		stop_focus_animation()
	
	var target_position := Vector2(
			((node.position_offset * zoom) -\
			(size / 2)) +\
			((node.size / 2) * zoom))
	
	if target_position == scroll_offset:
		return
	
	if animate:
		var new_tween: Tween = get_tree().create_tween()
		focus_tween = new_tween
		new_tween.set_trans(Tween.TRANS_QUINT)
		new_tween.set_ease(Tween.EASE_OUT)
		new_tween.tween_property(self, "scroll_offset", target_position, 1.0)
		
		# Keeping references separate in case an animation is suddenly canceled
		await new_tween.finished
		
		focus_tween = null
	else:
		scroll_offset = target_position


## Returns the offset vector value specific to the center based on zoom value.
func get_center_offset() -> Vector2:
	return Vector2((scroll_offset / zoom) + ((size / 2.0) / zoom))


func get_compatible_nodes(connection_type: ConnectionType, node_side: String) -> Array[Dictionary]:
	if not compatible_connections.has(connection_type) or not compatible_connections[connection_type].has(node_side):
		return Array([], TYPE_DICTIONARY, &"", null)
	return compatible_connections[connection_type][node_side]


func get_compatible_node_count(connection_type: ConnectionType, node_side: String) -> int:
	if not compatible_connections.has(connection_type) or not compatible_connections[connection_type].has(node_side):
		return 0
	return compatible_connections[connection_type][node_side].size()


func get_compatible_node_overwrite_data(connection_type: ConnectionType, node_side: String, node_type: DialogNodes, item_index: int) -> Dictionary:
	if compatible_connections.has(connection_type):
		for type:Dictionary in compatible_connections[connection_type][node_side]:
			if type["type"] == node_type:
				if type["ports"][item_index].has("data"):
					return type["ports"][item_index]["data"]
				else:
					return {}
	return {}


func setup_compatible_nodes() -> void:
	compatible_connections[ConnectionType.DIALOG] = {
		"output": Array([
			{"name": "Dialog", "type": DialogNodes.DIALOG, "ports": [{"port": 0}]},
			{"name": "Choices", "type": DialogNodes.OPTIONS, "ports": [{"port": 0}]},
			{"name": "Event", "type": DialogNodes.EVENT, "ports": [{"port": 0}]},
			{"name": "Random", "type": DialogNodes.RANDOM, "ports": [{"port": 0}]},
			{"name": "Match", "type": DialogNodes.MATCH, "ports": [{"port": 0}]},
			{"name": "Branch", "type": DialogNodes.BRANCH, "ports": [{"port": 0}]},
			{"name": "Anchor Pointer", "type": DialogNodes.ANCHOR_POINTER, "ports": [{"port": 0}]},
			{"name": "Dialog Merge", "type": DialogNodes.DIALOG_MERGE, "ports": [{"port": 0}]},
			{"name": "Pause", "type": DialogNodes.PAUSE, "ports": [{"port": 0}]},
			{"name": "Dialog End", "type": DialogNodes.DIALOG_END, "ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null),
		"input": Array([
			{"name": "Dialog", "type": DialogNodes.DIALOG, "ports": [{"port": 0}]},
			{"name": "Choices", "type": DialogNodes.OPTIONS, "ports": [{"port": 0}]},
			{"name": "Event", "type": DialogNodes.EVENT, "ports": [{"port": 0}]},
			{"name": "Random", "type": DialogNodes.RANDOM, "ports": [{"port": 0}]},
			{"name": "Match", "type": DialogNodes.MATCH, "ports": [{"port": 0, "name": "Default"}, {"port": 1, "name": "Case 1"}]},
			{"name": "Branch", "type": DialogNodes.BRANCH, "ports": [{"port": 0, "name": "True Branch"}, {"port": 1, "name": "False Branch"}]},
			{"name": "Anchor", "type": DialogNodes.ANCHOR, "ports": [{"port": 0}]},
			{"name": "Dialog Merge", "type": DialogNodes.DIALOG_MERGE, "ports": [{"port": 0}]},
			{"name": "Pause", "type": DialogNodes.PAUSE, "ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)}
	
	compatible_connections[ConnectionType.VAR_STRING] = {
		"input": Array([
			{"name": "Value", "type": DialogNodes.VALUE, "ports": [{"port": 0,"data": {"value": ""}}]},
			{"name": "Localized Text", "type": DialogNodes.LOCALIZED_TEXT, "ports": [{"port": 0}]},
			{"name": "Type Guard", "type": DialogNodes.TYPE_GUARD, "ports": [{"port": 0}]},
			{"name": "Variable", "type": DialogNodes.VARIABLE_GET, "ports": [{"port": 0, "data": {"variable_type": TYPE_STRING}}]}], TYPE_DICTIONARY, &"", null)}
	
	compatible_connections[ConnectionType.VAR_INT] = {
		"input": Array([
			{"name": "Value", "type": DialogNodes.VALUE, "ports": [{"port": 0, "data": {"value": 0}}]},
			{"name": "Random", "type": DialogNodes.RANDOM_VALUE, "ports": [{"port": 0, "data": {"mode": TYPE_INT}}]},
			{"name": "Type Guard", "type": DialogNodes.TYPE_GUARD, "ports": [{"port": 0}]},
			{"name": "Variable", "type": DialogNodes.VARIABLE_GET, "ports": [{"port": 0, "data": {"variable_type": TYPE_INT}}]}], TYPE_DICTIONARY, &"", null)}
	
	compatible_connections[ConnectionType.VAR_BOOL] = {
		"input": Array([
			{"name": "Value", "type": DialogNodes.VALUE, "ports": [{"port": 0, "data": {"value": false}}]},
			{"name": "Random", "type": DialogNodes.RANDOM_VALUE, "ports": [{"port": 0, "data": {"mode": TYPE_BOOL, "values": {"base": 50.0, "max": 50.0}}}]},
			{"name": "Type Guard", "type": DialogNodes.TYPE_GUARD, "ports": [{"port": 0}]},
			{"name": "Variable", "type": DialogNodes.VARIABLE_GET, "ports": [{"port": 0, "data": {"variable_type": TYPE_BOOL}}]},
			{"name": "Comparation", "type": DialogNodes.COMPARATION, "ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)}
	
	compatible_connections[ConnectionType.SIGNAL] = {
		"input": Array([
			{"name": "Signal", "type": DialogNodes.SIGNAL, "ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)}

	compatible_connections[ConnectionType.CALL] = {
		"input": Array([
			{"name": "Signal", "type": DialogNodes.CALLABLE, "ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)}
		
	compatible_connections[ConnectionType.SETTINGS_CHARACTER] = {
		"input": Array([
			{"name": "Settings", "type": DialogNodes.SETTINGS_CHARACTER, "ports": [{"port": 0}]}
		], TYPE_DICTIONARY, &"", null)}
	compatible_connections[ConnectionType.SETTINGS_DIALOG] = {
		"input": Array([
			{"name": "Settings", "type": DialogNodes.SETTINGS_DIALOG, "ports": [{"port": 0}]}
		], TYPE_DICTIONARY, &"", null)}
	compatible_connections[ConnectionType.SETTINGS_OPTION] = {
		"input": Array([
			{"name": "Settings", "type": DialogNodes.SETTINGS_OPTION, "ports": [{"port": 0}]}
		], TYPE_DICTIONARY, &"", null)}
	
	compatible_connections[ConnectionType.RESOURCE] = {
		"input": Array([
			{"name": "", "type": DialogNodes.RESOURCE, "ports": [{"port": 0}]}
		], TYPE_DICTIONARY, &"", null)}
	
	compatible_connections[ConnectionType.VAR_ANY] = {
		"input": Array([
			{"name": "Value", "type": DialogNodes.VALUE, "ports": [
				{"name": "Integer", "port": 0, "data": {"value": 0}},
				{"name": "Float", "port": 0, "data": {"value": 0.0}},
				{"name": "Bool", "port": 0, "data": {"value": false}},
				{"name": "String", "port": 0, "data": {"value": ""}}]},
			{"name": "Random Value", "type": DialogNodes.RANDOM_VALUE, "ports": [{"port": 0}]},
			{"name": "Localized Text", "type": DialogNodes.LOCALIZED_TEXT, "ports": [{"port": 0}]},
			{"name": "Type Guard", "type": DialogNodes.TYPE_GUARD, "ports": [{"port": 0}]},
			{"name": "Variable", "type": DialogNodes.VARIABLE_GET, "ports": [{"port": 0}]},
			{"name": "Comparation", "type": DialogNodes.COMPARATION, "ports": [{"port": 0}]},
			{"name": "Conditional Value", "type": DialogNodes.CONDITION_SELECT, "ports": [{"port": 0}]},
				], TYPE_DICTIONARY, &"", null)}


func populate_popup(node_type: ConnectionType, port_direction: String) -> void:
	connection_popup.clear(true)
	connection_popup.size = Vector2.ZERO
	
	for node in get_compatible_nodes(node_type, port_direction):
		if node["ports"].size() == 1:
			connection_popup.add_item(node["name"], node_type)
			connection_popup.set_item_metadata(
					-1,
					{
						"flow": port_direction,
						"target_type": node["type"],
						"target_port": node["ports"][0]["port"]})
		else:
			var connection_submenu: PopupMenu = PopupMenu.new()
			for subitem:Dictionary in node["ports"]:
				connection_submenu.add_item(subitem["name"], node_type)
				connection_submenu.set_item_metadata(
						-1,
						{
							"flow": port_direction,
							"target_type": node["type"],
							"target_port": subitem["port"]})
			connection_popup.add_submenu_node_item(node["name"], connection_submenu)
			connection_submenu.index_pressed.connect(_on_popup_index_pressed.bind(connection_submenu))


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	if not Input.is_key_pressed(KEY_CTRL):
		return
	var port_node: DiscourseGraphNode = get_node(NodePath(from_node))
	var port_type: ConnectionType = port_node.get_output_port_type(from_port) as ConnectionType
	var node_count: int = get_compatible_node_count(port_type, "output")
	
	if node_count == 0:
		return
	elif node_count == 1 and compatible_connections[port_type]["output"][0]["ports"].size() == 1:
		var to_info: Dictionary = get_compatible_nodes(port_type, "output")[0]
		var to_graph: DiscourseGraphNode = create_dialog_node(to_info["type"])
		var to_data: Dictionary = to_graph._get_node_data()
		if to_info.has("data"):
			to_data.merge(to_info["data"], true)
		to_data["position"] = Vector2((release_position / zoom) + (scroll_offset / zoom))
		to_graph._set_node_data(to_data)
		add_child(to_graph)
		graph_nodes.append(to_graph)
		if to_info["type"] == DialogNodes.ANCHOR:
			anchor_created.emit(to_graph)
		elif to_info["type"] == DialogNodes.LOCALIZED_TEXT:
			localized_text_created.emit(true, to_graph)
		var frame: GraphFrame = get_element_frame(from_node)
		to_graph.position_offset -= to_graph.get_output_port_position(to_info["ports"][0]["port"])
		snap_graph_to_grid(to_graph)
		connect_nodes(
				from_node,
				from_port,
				to_graph.name,
				to_info["ports"][0]["port"])
		#_on_connection_request(
				#from_node,
				#from_port,
				#to_graph.name,
				#to_info["ports"][0]["port"])
		if frame != null:
			attach_graph_element_to_frame(to_graph.name, frame.name)
		node_created.emit(to_graph)
		dialog_changed.emit()
		return
	var popup_meta: Dictionary = connection_popup.get_meta(&"release_data")
	
	#connection_popup.position = release_position
	populate_popup(port_type, "output")
	
	popup_meta["from_node"] = from_node
	popup_meta["from_port"] = from_port
	popup_meta["release_position"] = release_position
	
	show_connection_popup_at(get_global_mouse_position())


func _on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	if not Input.is_key_pressed(KEY_CTRL):
		return
	var to_graph: DiscourseGraphNode = get_node(NodePath(to_node))
	var port_type: ConnectionType = to_graph.get_input_port_type(to_port) as ConnectionType
	var node_count: int = get_compatible_node_count(port_type, "input")
	
	if node_count == 0:
		return
	elif node_count == 1 and compatible_connections[port_type]["input"][0]["ports"].size() == 1:
		var from_info: Dictionary = get_compatible_nodes(port_type, "input")[0]
		var from_graph: DiscourseGraphNode = create_dialog_node(from_info["type"])
		var from_data: Dictionary = from_graph._get_node_data()
		var frame: GraphFrame = get_element_frame(to_node)
		if from_info.has("data"):
			from_data.merge(from_info["data"], true)
		from_data["position"] = Vector2((release_position / zoom) + (scroll_offset / zoom))
		from_graph._set_node_data(from_data)
		add_child(from_graph)
		graph_nodes.append(from_graph)
		if from_info["type"] == DialogNodes.ANCHOR:
			anchor_created.emit(to_graph)
		elif from_info["type"] == DialogNodes.LOCALIZED_TEXT:
			localized_text_created.emit(true, from_graph)
		from_graph.position_offset -= from_graph.get_output_port_position(from_info["ports"][0]["port"])
		snap_graph_to_grid(from_graph)
		connect_nodes(
				from_graph.name,
				from_info["ports"][0]["port"],
				to_node,
				to_port)
		#_on_connection_request(
				#from_graph.name,
				#from_info["ports"][0]["port"],
				#to_node,
				#to_port)
		if frame != null:
			attach_graph_element_to_frame(from_graph.name, frame.name)
		node_created.emit(from_graph)
		dialog_changed.emit()
		return
	var popup_meta: Dictionary = connection_popup.get_meta(&"release_data")
	
	populate_popup(port_type, "input")
	
	popup_meta["from_node"] = to_node
	popup_meta["from_port"] = to_port
	popup_meta["release_position"] = release_position
	
	show_connection_popup_at(get_global_mouse_position())


func _on_popup_index_pressed(index: int, menu: PopupMenu) -> void:
	var overall_metadata: Dictionary = connection_popup.get_meta(&"release_data")
	var from_node: StringName = overall_metadata["from_node"]
	var from_port: int = overall_metadata["from_port"]
	var data: Dictionary = menu.get_item_metadata(index)
	var connection_type = menu.get_item_id(index)
	var new_node: DiscourseGraphNode = create_dialog_node(data["target_type"])
	var node_data: Dictionary = new_node._get_node_data()
	var target_position: Vector2 = Vector2((overall_metadata["release_position"] / zoom) + (scroll_offset / zoom))
	var frame: GraphFrame = get_element_frame(from_node)
	
	node_data.merge(get_compatible_node_overwrite_data(connection_type, data["flow"], data["target_type"], 0 if menu == connection_popup else index), true)
	node_data["position"] = target_position
	new_node._set_node_data(node_data)
	add_child(new_node)
	graph_nodes.append(new_node)
	new_node.position_offset -= new_node.get_input_port_position(data["target_port"]) if data["flow"] == "output" else new_node.get_output_port_position(data["target_port"])
	snap_graph_to_grid(new_node)
	
	if data["flow"] == "input":
		connect_nodes(
				new_node.name,
				data["target_port"],
				from_node,
				from_port)
		#_on_connection_request(
			#new_node.name,
			#data["target_port"],
			#from_node,
			#from_port)
	else:
		connect_nodes(
				from_node,
				from_port,
				new_node.name,
				data["target_port"])
		#_on_connection_request(
				#from_node,
				#from_port,
				#new_node.name,
				#data["target_port"])
	
	if frame != null:
		attach_graph_element_to_frame(new_node.name, frame.name)
	
	node_created.emit(new_node)
	dialog_changed.emit()


func clear_dialog_nodes() -> void:
	clear_connections()
	for child in get_children():
		if child is not DiscourseGraphNode and child is not GraphFrame:
			continue
		remove_child(child)
		child.queue_free()
	graph_nodes.clear()
	entry_node = null


func show_connection_popup_at(new_position: Vector2i):
	# Get the PopupMenu's global size
	var popup_size: Vector2i = Vector2i(connection_popup.get_contents_minimum_size())

	# Get the viewport size
	var viewport_size: Vector2i = get_viewport().size

	# Calculate the bottom-right corner of the PopupMenu
	var popup_bottom_right: Vector2i = new_position + popup_size

	# Calculate the offset needed to keep the PopupMenu inside the viewport
	var offset: Vector2i = Vector2i.ZERO
	
	if popup_bottom_right.x > viewport_size.x:
		offset.x = viewport_size.x - popup_bottom_right.x
	if popup_bottom_right.y > viewport_size.y:
		offset.y = viewport_size.y - popup_bottom_right.y
	
	# Apply the offset to the PopupMenu's position
	connection_popup.position = new_position + offset
	connection_popup.show()


func get_selected_graph_nodes(include_start: bool = false) -> Array[DiscourseGraphNode]:
	var selected_nodes: Array[DiscourseGraphNode] = []
	for node in get_children():
		if node is not DiscourseGraphNode or not node.selected:
			continue
		
		if node.node_type == DialogNodes.ENTRY and not include_start:
			continue
		
		selected_nodes.append(node)
	return selected_nodes


func sort_clipboard_custom(item_a: Dictionary, item_b: Dictionary) -> bool:
	return item_a["position"] < item_b["position"]


func get_conversation_data(on_conversation: EditorDiscourseDialog = null) -> EditorDiscourseDialog:
	var convo: EditorDiscourseDialog = DiscourseDialog.new_dialog() if on_conversation == null else on_conversation
	
	if on_conversation != null:
		convo.clear()
	
	var frames: Array[GraphFrame] = []
	var nodes: Array[DiscourseGraphNode] = []
	
	for node in get_children():
		if node is DiscourseGraphNode:
			nodes.append(node)
		elif node is GraphFrame:
			frames.append(node)
	
	for frame in frames:
		convo.register_frame(
				frame.get_frame_uuid(),
				frame.title,
				frame.position_offset,
				frame.size,
				frame.tint_color)
	
	for node in nodes:
		var data: Dictionary = {
			"name": node.name,
			"custom_id": node.custom_id,
			"has_localization": node.is_node_localized()}
		var frame: GraphFrame = get_element_frame(node.name)
		var frame_uuid: String = "" if frame == null else frame.get_frame_uuid()
		data.merge(node._get_node_data())
		
		convo.register_node(
				node.get_node_uuid(),
				data,
				frame_uuid)
		
		if node.node_type == DialogNodes.DIALOG and not node.is_node_localized():
			convo.set_unlocalized_text(
					node.get_node_uuid(),
					node.get_dialog_text())
		elif node.node_type == DialogNodes.OPTIONS and not node.is_node_localized():
			convo.set_unlocalized_choices(
					node.get_node_uuid(),
					node.get_options())
	
	return convo


func get_connection_dictionary(node_uuid: StringName, node_data: Dictionary) -> Array[Dictionary]:
	var node_connections: Array[Dictionary] = []
	
	match node_data["node_type"] as DialogNodes:
		DialogNodes.OPTIONS:
			for option in node_data["options"]:
				if option["output_connections"]["next_node"]["target_node_uuid"].is_empty():
					continue
				node_connections.append({
					"from": node_uuid,
					"to": option["output_connections"]["next_node"]["target_node_uuid"],
					"from_port": option["output_connections"]["next_node"]["from_port"],
					"to_port": option["output_connections"]["next_node"]["target_port"]})
		DialogNodes.MATCH:
			if not node_data["output_connections"]["default"]["target_node_uuid"].is_empty():
				node_connections.append({
					"from": node_uuid,
					"to": node_data["output_connections"]["default"]["target_node_uuid"],
					"from_port": node_data["output_connections"]["default"]["from_port"],
					"to_port": node_data["output_connections"]["default"]["target_port"]})
			for match_value in node_data["cases"]:
				if match_value["next_node"]["target_node_uuid"].is_empty():
					continue
				node_connections.append({
					"from": node_uuid,
					"to": match_value["next_node"]["target_node_uuid"],
					"from_port": match_value["next_node"]["from_port"],
					"to_port": match_value["next_node"]["target_port"]})
		DialogNodes.RANDOM:
			for option in node_data["options"]:
				if option["output_connections"]["next_node"]["target_node_uuid"].is_empty():
					continue
				
				node_connections.append({
					"from": node_uuid,
					"to": option["output_connections"]["next_node"]["target_node_uuid"],
					"from_port": option["output_connections"]["next_node"]["from_port"],
					"to_port": option["output_connections"]["next_node"]["target_port"]})
			node_connections.sort_custom(func(a,b): return a["from_port"] < b["from_port"])
			print(node_connections)
		_:
			if node_data.has("output_connections"):
				for output_connection_key in node_data["output_connections"].keys():
					if node_data["output_connections"][output_connection_key]["target_node_uuid"].is_empty():
						continue
					node_connections.append({
						"from": node_uuid,
						"to": node_data["output_connections"][output_connection_key]["target_node_uuid"],
						"from_port": node_data["output_connections"][output_connection_key]["from_port"],
						"to_port": node_data["output_connections"][output_connection_key]["target_port"]})
	return node_connections


func load_conversation_data(conversation: EditorDiscourseDialog, language: String, region: String = "") -> bool:
	var needs_resaving: bool = false
	clear_dialog_nodes()
	
	var node_connections: Array[Dictionary] = []
	var graph_map: Dictionary[String, DiscourseGraphNode] = {}
	
	var node_relationships: Dictionary[String, GraphFrame] = {}
	
	for frame_uuid:String in conversation.get_frames_uuids():
		var frame: GraphFrame = create_node_frame(frame_uuid)
		var frame_data: Dictionary = conversation.get_frame_data(frame_uuid)
		frame.title = frame_data["title"]
		frame.position_offset = frame_data["position"]
		frame.size = frame_data["size"]
		frame.tint_color = frame_data["tint_color"]
		for child_node:String in frame_data["nodes"]:
			node_relationships[child_node] = frame
		add_child(frame)
	
	for node_stnm_uuid:StringName in conversation.get_node_uuids():
		var node_uuid: String = String(node_stnm_uuid)
		var data: Dictionary = conversation.get_node_data(node_stnm_uuid, language, region)
		var d_node: DiscourseGraphNode = create_dialog_node(data["node_type"], node_uuid)
		d_node._set_node_data(data)
		d_node.name = data["name"]
		d_node.custom_id = data["custom_id"]
		d_node.set_node_localized(data["has_localization"])
		add_child(d_node)
		if d_node.node_type == DialogNodes.ENTRY:
			entry_node = d_node
		elif d_node.node_type == DialogNodes.CALLABLE or d_node.node_type == DialogNodes.CALLABLE_RETURN:
			if not d_node.available_methods.has(data["method"]):
				needs_resaving = true
		elif d_node.node_type == DialogNodes.SIGNAL:
			if not d_node.available_signals.has(data["signal"]):
				needs_resaving = true
		graph_nodes.append(d_node)
		if node_relationships.has(node_uuid):
			attach_graph_element_to_frame(d_node.name, node_relationships[node_uuid].name)
		graph_map[node_uuid] = d_node
		var new_connections: Array[Dictionary] = get_connection_dictionary(
				node_uuid,
				data)
		if not new_connections.is_empty():
			node_connections.append_array(new_connections)
		node_created.emit(d_node)
		if d_node.is_node_localized():
			localization_enabled.emit(d_node)
	
	for output_connection in node_connections:
		if not graph_map.has(output_connection["from"]) or not graph_map.has(output_connection["to"]):
			continue
		connect_nodes(
				graph_map[output_connection["from"]].name,
				output_connection["from_port"],
				graph_map[output_connection["to"]].name,
				output_connection["to_port"])
	
	if entry_node == null:
		entry_node = create_dialog_node(DialogNodes.ENTRY)
		entry_node.name = &"Entry"
		node_created.emit(entry_node)
		add_child(entry_node)
		graph_nodes.append(entry_node)
	
	zoom = conversation.zoom
	scroll_offset = conversation.scroll_offset
	
	return needs_resaving


func get_discourse_nodes() -> Array[DiscourseGraphNode]:
	var all_nodes: Array[DiscourseGraphNode] = []
	
	for node in get_children():
		if node is DiscourseGraphNode:
			all_nodes.append(node)
	
	return all_nodes


func get_issues() -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	
	for node in get_children():
		if node is not DiscourseGraphNode:
			continue
		var node_issues: PackedStringArray = node._get_issues()
		if not node_issues.is_empty():
			issues.append({
				"node": node,
				"issues": node_issues})
	
	return issues


func fix_scroll_offset_for_new(new_size: Vector2) -> void:
	size = new_size
	var target_size: Vector2 = -Vector2(new_size.x / 4.0, new_size.y / 2.0) + Vector2(entry_node.size.x, entry_node.size.y / 2.0)
	scroll_offset = target_size


func stop_focus_animation() -> void:
	if focus_tween == null:
		return
	# Grabbing reference as signaling "finished" could set focus_tween to null
	var tween: Tween = focus_tween
	tween.pause()
	tween.finished.emit()
	tween.kill()
	focus_tween = null


func update_methods() -> void:
	for node in method_callers:
		node.reload_methods()


func update_signals() -> void:
	for node in signalers:
		node.reload_signals()

#func get_user_signals() -> Array[Dictionary]:
		#var user_signals: Array[Dictionary] = []
		#var singleton: DiscourseAPI = DiscourseAPI.new()
		#var prev_signals: DialogParser = DialogParser.new_parser()
		#
		#var existing_signals: Array[String] = []
		#
		#for parent_signal in prev_signals.get_signal_list():
			#existing_signals.append(parent_signal["name"])
		#
		#for reg_signal:Dictionary in singleton.get_signal_list():
			#if reg_signal["name"] in existing_signals:
				#continue
			#var args: Array[Dictionary] = []
			#for arg: Dictionary in reg_signal["args"]:
				#args.append({
					#"name": arg["name"],
					#"type": arg["type"]
				#})
			#
			#user_signals.append({
				#"name": reg_signal["name"],
				#"args": args
			#})
		#
		#prev_signals.free()
		#singleton.free()
		#
		#return user_signals
