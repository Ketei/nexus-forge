extends Control


const DIALOG_NODE = preload("res://addons/nexus_forge/tools/discourse/scenes/dialog_node/dialog_gnode.tscn")
const CHARACTER_NODE = preload("res://addons/nexus_forge/tools/discourse/scenes/character_node/character_gnode.tscn")
const SIGNAL_EMIT_NODE = preload("res://addons/nexus_forge/tools/discourse/scenes/signal_emmiter/signal_emit_gnode.tscn")
const SET_VARIABLE_GNODE = preload("res://addons/nexus_forge/tools/discourse/scenes/set_variable/set_variable_gnode.tscn")
const METHOD_CALL_GNODE = preload("res://addons/nexus_forge/tools/discourse/scenes/call_node/method_call_gnode.tscn")
const REPLY_SELECTOR_NODE = preload("res://addons/nexus_forge/tools/discourse/scenes/reply_selector/reply_selector_gnode.tscn")
const REPLY_NODE = preload("res://addons/nexus_forge/tools/discourse/scenes/reply_selector/reply_grnode.tscn")
const COMPARATION_NODE = preload("res://addons/nexus_forge/tools/discourse/scenes/comparation/comparation_gnode.tscn")
const VAL_SELECTOR_NODE = preload("res://addons/nexus_forge/tools/discourse/scenes/value_selector/val_selector_gnode.tscn")
const RANDOM_SELECT_GNODE = preload("res://addons/nexus_forge/tools/discourse/scenes/random_selector/random_select_gnode.tscn")
const CONDITIONAL_SPLIT_NODE = preload("res://addons/nexus_forge/tools/discourse/scenes/condition_split/conditional_split_gnode.tscn")
const GO_TO_ID_GNODE = preload("res://addons/nexus_forge/tools/discourse/scenes/utility/go_to_id_gnode.tscn")
const RETURN_CALL_NODE = preload("res://addons/nexus_forge/tools/discourse/scenes/call_node/return_call_gnode.tscn")
const COMMENT_GRAPH_NODE = preload("res://addons/nexus_forge/tools/discourse/scenes/utility/comment_graph_node.tscn")

var current_dialog: TreeItem
var entry_node: DiscourseGraphNode = null
var root_nodes: Array[DiscourseGraphNode] = []
var _is_traveling: bool = false

@onready var dialog_graph_edit: GraphEdit = %DialogGraphEdit
@onready var no_dialog_container: CenterContainer = %NoDialogContainer
@onready var open_dialog_list: Tree = %OpenDialogList
@onready var id_nodes: Tree = %IDNodes

@onready var from_next: DiscoursePopupMenu = $MenuWindowPopup/FromNext
@onready var to_value: DiscoursePopupMenu = $MenuWindowPopup/ToValue
@onready var to_result: DiscoursePopupMenu = $MenuWindowPopup/ToResult

@onready var add_node_button: MenuButton = $Dialogues/TreeContainer/MenuContainer/AddNodeButton

@onready var discourse_save_dialog: FileDialog = $DiscourseSaveDialog

@onready var test_save_button: Button = $Dialogues/TreeContainer/MenuContainer/Button


func _ready() -> void:
	await get_tree().process_frame
	dialog_graph_edit.scroll_offset = -(dialog_graph_edit.size / 2)
	dialog_graph_edit.add_valid_connection_type(8, 9)
	dialog_graph_edit.connection_request.connect(on_connection_request)
	dialog_graph_edit.disconnection_request.connect(on_disconnection_request)
	dialog_graph_edit.connection_to_empty.connect(on_connection_to_empty)
	dialog_graph_edit.connection_from_empty.connect(on_connection_from_empty)
	to_value.index_pressed.connect(on_to_type_selected)
	from_next.index_pressed.connect(on_from_next_selected)
	to_result.index_pressed.connect(on_to_result_selected)
	add_node_button.get_popup().index_pressed.connect(on_add_node_selected)
	id_nodes.center_dialog_pressed.connect(center_node)
	test_save_button.pressed.connect(on_test_save_pressed)
	
	entry_node = $Dialogues/TreeContainer/DialogNodes/DialogGraphEdit/EntryDialogGraphNode


func on_test_save_pressed() -> void:
	print(get_current_conversation_data())


func get_dialog_graph_center() -> Vector2:
	return Vector2((dialog_graph_edit.scroll_offset / dialog_graph_edit.zoom) + ((dialog_graph_edit.size / 2) / dialog_graph_edit.zoom))


func on_add_node_selected(selected_idx: int) -> void:
	var target_pos := get_dialog_graph_center()
	var new_node: DiscourseGraphNode
	
	match selected_idx:
		1:
			new_node = spawn_dialog_node(
					"",
					DialogData.get_dialog_structure(),
					null,
					true,
					target_pos)
		2:
			new_node = spawn_charcter_node(
					DialogData.get_character_structure(),
					true,
					target_pos)
			
		4:
			new_node = spawn_reply_options_node(
					"",
					DialogData.get_replies_structure(),
					null,
					true,
					target_pos)
		5:
			new_node = spawn_conditional_split_node(
					DialogData.get_condition_structure(),
					true,
					target_pos)
		6:
			new_node = spawn_random_select_node(
					DialogData.get_random_select_structure(),
					true,
					target_pos)
		8:
			new_node = spawn_call_node(
					DialogData.get_call_structure(),
					true,
					target_pos)
		9:
			new_node = spawn_return_call_node(
					DialogData.get_call_structure(),
					true,
					target_pos)
		10:
			new_node = spawn_comparator_node(
					DialogData.get_comparation_structure(),
					true,
					target_pos)
		11:
			new_node = spawn_variables_node(
					DialogData.get_set_var_structure(),
					true,
					target_pos)
		12:
			new_node = spawn_signal_node(
				DialogData.get_signal_structure(),
				true,
				target_pos)
		13:
			new_node = spawn_element_node(
					DialogData.get_element_structure(),
					true,
					target_pos)
		15:
			new_node = spawn_id_shortcut(target_pos)
		16:
			new_node = spawn_comment_node(DialogData.get_comment_structure())
	
	if new_node != null:
		new_node.position_offset -= new_node.size / 2


func on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	if not Input.is_action_pressed("control_key"):
		return
	
	var from_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(from_node))
	var port_type = from_graph.get_output_port_type(from_port)
	
	if port_type != 0:
		return

	from_next.position = get_viewport().get_mouse_position()
	from_next.node = from_graph
	from_next.at = Vector2((release_position / dialog_graph_edit.zoom) + (dialog_graph_edit.scroll_offset / dialog_graph_edit.zoom))
	from_next.port_idx = from_port
	from_next.show()


func on_from_next_selected(index: int) -> void:
	var target_position = from_next.at
	var from_graph: DiscourseGraphNode = from_next.node
	var from_port: int = from_next.port_idx
	
	match index:
		0:
			var new_dialog := spawn_dialog_node(
					"",
					DialogData.get_dialog_structure(),
					null,
					true,
					target_position)
			new_dialog.position_offset -= new_dialog.get_input_port_position(0)
			if from_graph.node_type == DialogData.DialogType.RANDOM or from_graph.node_type == DialogData.DialogType.OPTIONS:
				connect_nodes_specific(
					from_graph,
					str(from_port),
					new_dialog,
					"next")
			elif from_graph.node_type == DialogData.DialogType.CONDITION:
				if from_port == 0:
					connect_nodes_specific(
							from_graph,
							"true",
							new_dialog,
							"next")
				else:
					connect_nodes_specific(
							from_graph,
							"false",
							new_dialog,
							"next")
			else:
				connect_nodes(from_graph, new_dialog, "next")
		1:
			var new_replies := spawn_reply_options_node(
					"",
					DialogData.get_replies_structure(),
					null,
					true,
					target_position)
			new_replies.position_offset -= new_replies.get_input_port_position(0)
			if from_graph.node_type == DialogData.DialogType.RANDOM or from_graph.node_type == DialogData.DialogType.OPTIONS:
				connect_nodes_specific(
					from_graph,
					str(from_port),
					new_replies,
					"next")
			elif from_graph.node_type == DialogData.DialogType.CONDITION:
				if from_port == 0:
					connect_nodes_specific(
							from_graph,
							"true",
							new_replies,
							"next")
				else:
					connect_nodes_specific(
							from_graph,
							"false",
							new_replies,
							"next")
			else:
				connect_nodes(from_graph, new_replies, "next")
		2:
			var new_shortcut := spawn_id_shortcut(target_position)
			new_shortcut.position_offset -= new_shortcut.get_input_port_position(0)
			if from_graph.node_type == DialogData.DialogType.RANDOM or from_graph.node_type == DialogData.DialogType.OPTIONS:
				connect_nodes_specific(
					from_graph,
					str(from_port),
					new_shortcut,
					"next")
			elif from_graph.node_type == DialogData.DialogType.CONDITION:
				if from_port == 0:
					connect_nodes_specific(
							from_graph,
							"true",
							new_shortcut,
							"next")
				else:
					connect_nodes_specific(
							from_graph,
							"false",
							new_shortcut,
							"next")
			else:
				connect_nodes(from_graph, new_shortcut, "next")
		3:
			var new_cond := spawn_conditional_split_node(
					DialogData.get_condition_structure(),
					true,
					target_position)
			new_cond.position_offset -= new_cond.get_input_port_position(0)
			if from_graph.node_type == DialogData.DialogType.RANDOM or from_graph.node_type == DialogData.DialogType.OPTIONS:
				connect_nodes_specific(
					from_graph,
					str(from_port),
					new_cond,
					"next")
			elif from_graph.node_type == DialogData.DialogType.CONDITION:
				if from_port == 0:
					connect_nodes_specific(
							from_graph,
							"true",
							new_cond,
							"next")
				else:
					connect_nodes_specific(
							from_graph,
							"false",
							new_cond,
							"next")
			else:
				connect_nodes(from_graph, new_cond, "next")
		4:
			var new_random := spawn_random_select_node(
					DialogData.get_random_select_structure(),
					true,
					target_position)
			new_random.position_offset -= new_random.get_input_port_position(0)
			if from_graph.node_type == DialogData.DialogType.RANDOM or from_graph.node_type == DialogData.DialogType.OPTIONS:
				connect_nodes_specific(
					from_graph,
					str(from_port),
					new_random,
					"next")
			elif from_graph.node_type == DialogData.DialogType.CONDITION:
				if from_port == 0:
					connect_nodes_specific(
							from_graph,
							"true",
							new_random,
							"next")
				else:
					connect_nodes_specific(
							from_graph,
							"false",
							new_random,
							"next")
			else:
				connect_nodes(from_graph, new_random, "next")


func on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	if not Input.is_action_pressed("control_key"):
		return
	
	var to_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(to_node))
	var port_type = to_graph.get_input_port_type(to_port)
	var target_position := Vector2((release_position / dialog_graph_edit.zoom) + (dialog_graph_edit.scroll_offset / dialog_graph_edit.zoom))
	match port_type:
		1:
			var char_node := spawn_charcter_node(
					DialogData.get_character_structure(),
					true,
					target_position)
			char_node.position_offset -= char_node.get_output_port_position(0)
			connect_nodes(char_node, to_graph, "character")
		3:
			var signal_node := spawn_signal_node(
					DialogData.get_signal_structure(),
					true,
					target_position)
			signal_node.position_offset -= signal_node.get_output_port_position(0)
			connect_nodes(signal_node, to_graph, "signal")
		4:
			var variable_node := spawn_variables_node(
					DialogData.get_set_var_structure(),
					true,
					target_position)
			variable_node.position_offset -= variable_node.get_output_port_position(0)
			connect_nodes(variable_node, to_graph, "variables")
		5:
			var call_node := spawn_call_node(
					DialogData.get_call_structure(),
					true,
					target_position)
			call_node.position_offset -= call_node.get_output_port_position(0)
			connect_nodes(call_node, to_graph, "call")
		6:
			var new_reply := spawn_reply_node(
					DialogData.get_option_structure(),
					true,
					target_position)
			new_reply.position_offset -= new_reply.get_output_port_position(0)
			connect_nodes_specific(
					new_reply,
					"reply",
					to_graph,
					str(to_port - 1))
		8:
			to_result.position = get_viewport().get_mouse_position()
			to_result.node = to_graph
			to_result.at = target_position
			to_result.port_idx = to_port
			to_result.show()
		9:
			to_value.position = get_viewport().get_mouse_position()
			to_value.node = to_graph
			to_value.at = target_position
			to_value.port_idx = to_port
			to_value.show()


func on_to_result_selected(selected: int) -> void:
	var target_pos: Vector2 = to_result.at
	var to_graph: DiscourseGraphNode = to_result.node
	
	match selected:
		0:
			var new_comparation := spawn_comparator_node(
					DialogData.get_comparation_structure(),
					true,
					target_pos)
			new_comparation.position_offset -= new_comparation.get_output_port_position(0)
			connect_nodes(new_comparation, to_graph, "result")
		1:
			var new_return_call := spawn_return_call_node(
					DialogData.get_call_structure(),
					true,
					target_pos)
			new_return_call.position_offset -= new_return_call.get_output_port_position(0)
			connect_nodes(new_return_call, to_graph, "result")


func on_to_type_selected(selected: int) -> void:
	var target_position = to_value.at
	var to_graph: DiscourseGraphNode = to_value.node
	var to_port: int = to_value.port_idx
	
	match selected:
		0:
			var new_value := spawn_element_node(
					DialogData.get_element_structure(),
					true,
					target_position)
			new_value.position_offset -= new_value.get_output_port_position(0)
			if to_port == 0:
				connect_nodes_specific(
					new_value,
					"value",
					to_graph,
					"value_a")
			else:
				connect_nodes_specific(
						new_value,
						"value",
						to_graph,
						"value_b")
		1:
			var new_comparation := spawn_comparator_node(
					DialogData.get_comparation_structure(),
					true,
					target_position)
			new_comparation.position_offset -= new_comparation.get_output_port_position(0)
			if to_port == 0:
				connect_nodes_specific(
					new_comparation,
					"result",
					to_graph,
					"value_a")
			else:
				connect_nodes_specific(
						new_comparation,
						"result",
						to_graph,
						"value_b")


func on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(from_node))
	var to_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(to_node))
	var from_id: String = from_graph.get_output_port_id_by_idx(from_port)
	var to_id: String = to_graph.get_input_port_id_by_idx(to_port)
	
	if from_graph.has_output_connection(from_id):
		# We have a from previous connection
		disconnect_output_port(from_graph, from_id)
	
	if to_graph.has_input_connection(to_id):
		disconnect_input_port(to_graph, to_id)


func has_connection_from(from: StringName, port: int) -> bool:
	for connection in dialog_graph_edit.get_connection_list():
		if connection["from_port"] == port and connection["from_node"] == from:
			return true
	return false


func on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	#print(str("From node: ", from_node, " from port ", from_port, " to node: ", to_node, " to port ", to_port))
	var from_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(from_node))
	var to_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(to_node))
	var from_id: String = from_graph.get_output_port_id_by_idx(from_port)
	var to_id: String = to_graph.get_input_port_id_by_idx(to_port)
	
	if from_graph.has_output_connection(from_id):
		# We have a from previous connection
		disconnect_output_port(from_graph, from_id)
	
	if to_graph.has_input_connection(to_id):
		disconnect_input_port(to_graph, to_id)
	
	connect_nodes_specific(from_graph, from_id, to_graph, to_id)


func on_options_input_disconnected(to_node: DiscourseGraphNode, port_id: String) -> void:
	disconnect_input_port(to_node, port_id)


func on_options_output_disconnected(to_node: DiscourseGraphNode, port_id: String) -> void:
	disconnect_output_port(to_node, port_id)


func on_close_requested(graph_node: DiscourseGraphNode) -> void:
	
	for connected_input in graph_node.get_connected_input_ports():
		disconnect_input_port(graph_node, connected_input)
	
	for connected_output in graph_node.get_connected_output_ports():
		disconnect_output_port(graph_node, connected_output)
	
	graph_node.queue_free()


func on_resource_selected(resource_path: String) -> void:
	if not FileAccess.file_exists(resource_path):
		return
	
	var dialog: Resource = load(resource_path)
	
	if dialog is not DialogData:
		return
	
	var tree_item: TreeItem = open_dialog_list.add_file(resource_path.get_file())
	
	tree_item.set_metadata(
			0,
			{
			"path": resource_path,
			"resource": dialog,
			"data": {"tree": {}, "orphans": [], "entry": ""}, # Used when unsaved data exists.
			"unsaved": false})

	on_dialog_selected(tree_item)


func on_dialog_selected(tree_item: TreeItem) -> void:
	if current_dialog != null:
		if current_dialog.get_metadata(0)["unsaved"]:
			current_dialog.get_metadata(0)["temp"] = get_current_conversation_data()
		
		dialog_graph_edit.clear_connections()
		root_nodes.clear()
	
		for child in dialog_graph_edit.get_children():
			if child is not DiscourseGraphNode:
				continue
			if child.node_type == DialogData.DialogType.START:
				continue
			
			child.queue_free()
	
	var item_metadata: Dictionary = tree_item.get_metadata(0)
	
	dialog_graph_edit.zoom = 1.0
	dialog_graph_edit.scroll_offset.x = -dialog_graph_edit.size.x / 2
	dialog_graph_edit.scroll_offset.y = -dialog_graph_edit.size.y / 2
	
	if entry_node == null:
		entry_node = load("res://addons/nexus_forge/tools/discourse/scenes/entry_dialog_gnode.tscn").instantiate()
		dialog_graph_edit.add_child(entry_node)
	
	entry_node.position_offset = Vector2.ZERO
	
	dialog_graph_edit.visible = true
	no_dialog_container.visible = false
	
	var data_tree: Dictionary = {}
	var orphan_nodes: Array[Dictionary]
	var entry_node_id: String = ""
	
	if item_metadata["unsaved"]:
		data_tree = item_metadata["temp"]["tree"]
		orphan_nodes = item_metadata["temp"]["orphans"]
		entry_node_id = item_metadata["temp"]["entry"]
	else:
		data_tree = item_metadata["resource"].conversation
		orphan_nodes = item_metadata["resource"].orphans
		entry_node_id = item_metadata["resource"].dialog_entry
	
	# First loop to instantiate all id_nodes
	for dialog_id:String in data_tree:
		match data_tree[dialog_id]["type"]:
			DialogData.DialogType.DIALOG:
				var dialog_node: DiscourseGraphNode = DIALOG_NODE.instantiate()
				dialog_graph_edit.add_child(dialog_node)
				dialog_node.node_id = dialog_id
				root_nodes.append(dialog_node)
				id_nodes.add_node(dialog_node)
			
			DialogData.DialogType.OPTIONS:
				var reply_selector: DiscourseGraphNode = REPLY_SELECTOR_NODE.instantiate()
				dialog_graph_edit.add_child(reply_selector)
				reply_selector.node_id = dialog_id
				id_nodes.add_node(reply_selector)
			_:
				continue # We skip it because it's not typed
	
	# Second loop to connect all nodes.
	for dialog_id:String in data_tree:
		match data_tree[dialog_id]["type"]:
			DialogData.DialogType.DIALOG:
				spawn_dialog_node(dialog_id, data_tree[dialog_id], get_root_with_id(dialog_id))
			DialogData.DialogType.OPTIONS:
				spawn_reply_options_node(dialog_id, data_tree[dialog_id], get_root_with_id(dialog_id))
			_:
				continue # We skip it because it's not typed
	
	for dialog_id:Dictionary in orphan_nodes:
		pass # Spawn the orphans. Can be any type but dialog and options.
	
	if not entry_node_id.is_empty():
		var target_entry := get_root_with_id(entry_node_id)
		if target_entry != null:
			connect_nodes(entry_node, target_entry, "next")
	
	current_dialog = tree_item


func connect_nodes(from: DiscourseGraphNode, to: DiscourseGraphNode, port_id: String) -> void:
	dialog_graph_edit.connect_node(
			from.name,
			from.get_output_port_idx_by_id(port_id),
			to.name,
			to.get_input_port_idx_by_id(port_id))
	
	from.connect_output_port(port_id, to)
	to.connect_input_port(port_id, from)


func connect_nodes_specific(from_node: DiscourseGraphNode, from_port: String, to_node: DiscourseGraphNode, to_port: String) -> void:
	dialog_graph_edit.connect_node(
			from_node.name,
			from_node.get_output_port_idx_by_id(from_port),
			to_node.name,
			to_node.get_input_port_idx_by_id(to_port))
	
	from_node.connect_output_port(from_port, to_node)
	to_node.connect_input_port(to_port, from_node)


## Disconnects from_node connection and the node it was connected to.
func disconnect_output_port(from_node: DiscourseGraphNode, from_port: String) -> void:
	if not from_node.has_output_connection(from_port):
		return
	
	# Returns the stringname of what from_node is connected to
	var to_node: DiscourseGraphNode = from_node.get_output_port_connection_by_id(from_port)
	# The port to what from_node is connected to.
	var to_port: String = to_node.get_input_port_id_by_connection(from_node)

	dialog_graph_edit.disconnect_node(
			from_node.name,
			from_node.get_output_port_idx_by_id(from_port),
			to_node.name,
			to_node.get_input_port_idx_by_id(to_port))
	
	from_node.disconnect_output_port(from_port)
	to_node.disconnect_input_port(to_port)


## Disconnects to_node connection and the node it was connected to.
func disconnect_input_port(to_node: DiscourseGraphNode, to_port: String) -> void:
	if not to_node.has_input_connection(to_port):
		return
	
	# Returns the stringname of what to_node is connected to
	var from_node: DiscourseGraphNode = to_node.get_input_port_connection_by_id(to_port)
	
	# The port to what from_node is connected to.
	var from_port: String = from_node.get_output_port_id_by_connection(to_node)

	dialog_graph_edit.disconnect_node(
			from_node.name,
			from_node.get_output_port_idx_by_id(from_port),
			to_node.name,
			to_node.get_input_port_idx_by_id(to_port))
	
	from_node.disconnect_output_port(from_port)
	to_node.disconnect_input_port(to_port)


func spawn_dialog_node(dialog_id: String, dialog_dict: Dictionary, target_node: DiscourseGraphNode = null, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var dialog_node: DiscourseGraphNode
	
	if target_node == null:
		dialog_node = DIALOG_NODE.instantiate()
		dialog_graph_edit.add_child(dialog_node)
		root_nodes.append(dialog_node)
		id_nodes.add_node(dialog_node)
	else:
		dialog_node = target_node
	
	if override_offset:
		dialog_node.position_offset = offset_override
	else:
		dialog_node.position_offset = dialog_dict["offset"]
	
	dialog_node.dialog_id_line.text = dialog_id
	dialog_node.text_edit.text = dialog_dict["dialog"]["text"]
	dialog_node.seconds_spin_box.value = dialog_dict["dialog"]["seconds_per_letter"]
	dialog_node.pause_check_box.button_pressed = dialog_dict["pause"]
	dialog_node.close_requested.connect(on_close_requested)
	
	if not dialog_dict["character"].is_empty():
		var character_node := spawn_charcter_node(dialog_dict["character"])
		connect_nodes(character_node, dialog_node, "character")
	
	if not dialog_dict["signal"].is_empty():
		var signal_node := spawn_signal_node(dialog_dict["signal"])
		connect_nodes(signal_node, dialog_node, "signal")
		
	if not dialog_dict["set_variable"].is_empty():
		var variables_node: DiscourseGraphNode = spawn_variables_node(dialog_dict["set_variable"])
		connect_nodes(variables_node, dialog_node, "variables")
	
	if not dialog_dict["call"].is_empty():
		var call_node: DiscourseGraphNode = null
		if dialog_dict["call"]["is_return"]:
			call_node = spawn_return_call_node(dialog_dict["call"])
		else:
			call_node = spawn_call_node(dialog_dict["call"])
		connect_nodes(call_node, dialog_node, "call")
	
	if not dialog_dict["next"].is_empty():
		if dialog_dict["next"]["type"] == DialogData.NextType.RANDOM:
			var new_rand := spawn_random_select_node(dialog_dict["next"]["data"])
			connect_nodes(dialog_node, new_rand, "next")
		
		elif dialog_dict["next"]["type"] == DialogData.NextType.CONDITION:
			var new_cond := spawn_conditional_split_node(dialog_dict["next"]["data"])
			connect_nodes(dialog_node, new_cond, "next")
		
		#elif dialog_dict["next"]["type"] == DialogData.NextType.OPTIONS:
			#var new_options := spawn_reply_options_node("", dialog_dict["next"]["data"])
			#connect_nodes(dialog_node, new_options, "next")
		
		elif dialog_dict["next"]["type"] == DialogData.NextType.ID:
			var connect_to: DiscourseGraphNode
			
			if dialog_dict["next"]["data"]["use_shortcut"]:
				connect_to = spawn_id_shortcut(dialog_dict["next"]["data"]["offset"])
			else:
				connect_to = get_root_with_id(dialog_dict["next"]["data"]["next"])
			if connect_to != null:
				connect_nodes(dialog_node, connect_to, "next")
	
	return dialog_node


func spawn_charcter_node(character_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var character_node: DiscourseGraphNode = CHARACTER_NODE.instantiate()
	dialog_graph_edit.add_child(character_node)
	
	character_node.position_offset = offset_override if override_offset else character_data["offset"]
	
	character_node.close_requested.connect(on_close_requested)
	character_node.char_id_line.text = character_data["id"]
	character_node.idle_line.text = character_data["idle"]["animation"]
	character_node.play_idle_check_button.button_pressed = character_data["idle"]["play"]
	character_node.talking_idle.text = character_data["talking"]["animation"]
	character_node.play_talking_check_button.button_pressed = character_data["talking"]["play"]
	
	return character_node


func spawn_id_shortcut(offset: Vector2) -> DiscourseGraphNode:
	var new_short: DiscourseGraphNode = GO_TO_ID_GNODE.instantiate()
	dialog_graph_edit.add_child(new_short)
	new_short.position_offset = offset
	new_short.close_requested.connect(on_close_requested)
	new_short.go_to_dialog.connect(on_center_dialog_called)
	return new_short


func spawn_conditional_split_node(split_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_conditional: DiscourseGraphNode = CONDITIONAL_SPLIT_NODE.instantiate()
	dialog_graph_edit.add_child(new_conditional)
	new_conditional.position_offset = offset_override if override_offset else split_data["offset"]
	new_conditional.close_requested.connect(on_close_requested)
	
	if not split_data["comparation"].is_empty():
		var comp_node := spawn_comparator_node(split_data["comparation"])
		connect_nodes(comp_node, new_conditional, "result")
	
	return new_conditional


func spawn_random_select_node(random_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_rand: DiscourseGraphNode = RANDOM_SELECT_GNODE.instantiate()
	var opt_size: int = random_data["options"].size()
	dialog_graph_edit.add_child(new_rand)
	
	new_rand.position_offset = offset_override if override_offset else random_data["offset"]
	new_rand.exit_count_box.value = opt_size
	
	new_rand.port_removed.connect(on_options_output_disconnected)
	new_rand.close_requested.connect(on_close_requested)
	
	for opt_idx in range(opt_size):
		new_rand.set_exit_weigth(opt_idx, random_data["options"][opt_idx]["weight"])
		if random_data["options"][opt_idx]["next"]["type"] == DialogData.NextType.ID:
			if not has_dialog_root(random_data["options"][opt_idx]["next"]["data"]):
				continue
			
			var target_node: DiscourseGraphNode
			
			if random_data["options"][opt_idx]["next"]["use_shortcut"]:
				target_node = spawn_id_shortcut(random_data["options"][opt_idx]["next"]["offset"])
			else:
				target_node = get_root_with_id(random_data["options"][opt_idx]["next"]["data"])
			
			if target_node != null:
				connect_nodes_specific(new_rand, str(opt_idx), target_node, "next")
			
		elif random_data["options"][opt_idx]["next"]["type"] == DialogData.NextType.RANDOM:
			var new_rand_reloaded := spawn_random_select_node(random_data["options"][opt_idx]["next"])
			connect_nodes_specific(new_rand, str(opt_idx), new_rand_reloaded, "next")
			
		elif random_data["options"][opt_idx]["next"]["type"] == DialogData.NextType.CONDITION:
			var new_cond := spawn_conditional_split_node(random_data["options"][opt_idx]["next"])
			connect_nodes_specific(new_rand, str(opt_idx), new_cond, "next")
			
	return new_rand


func spawn_reply_options_node(dialog_id: String, options_dict: Dictionary, target_node: DiscourseGraphNode = null, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var reply_selector: DiscourseGraphNode
	
	if target_node == null:
		reply_selector = REPLY_SELECTOR_NODE.instantiate()
		dialog_graph_edit.add_child(reply_selector)
		root_nodes.append(reply_selector)
		id_nodes.add_node(reply_selector)
	else:
		reply_selector = target_node
	
	reply_selector.output_port_disconnected.connect(on_options_output_disconnected)
	reply_selector.input_port_disconnected.connect(on_options_input_disconnected)
	
	reply_selector.id_line.text = dialog_id
	reply_selector.position_offset = offset_override if override_offset else options_dict["offset"]
	reply_selector.keep_dialog_check.button_pressed = options_dict["keep_dialog"]
	reply_selector.close_requested.connect(on_close_requested)
	
	if not options_dict["options"].is_empty():
		reply_selector.reply_count_box.value = options_dict["options"].size()
		
		for option_idx in range(options_dict["options"].size()):
			# If the input ins't empty
			if not options_dict["options"][option_idx].is_empty():
				var new_reply := spawn_reply_node(options_dict["options"][option_idx])
				var connection_idx: int = reply_selector.get_connector_index(option_idx)
			
				if connection_idx != -1:
					connect_nodes_specific(new_reply, "reply", reply_selector, str(option_idx))
			
			# If the output isn't empty
			if not options_dict["targets"][option_idx].is_empty():
				# Forward Connections
				if options_dict["targets"][option_idx]["type"] == DialogData.NextType.ID:
					var target_shortcut: DiscourseGraphNode = null
					
					if options_dict["targets"][option_idx]["data"]["use_shortcut"]:
						target_shortcut = spawn_id_shortcut(options_dict["targets"][option_idx]["data"]["offset"])
						target_shortcut.set_short_id(options_dict["targets"][option_idx]["data"]["next"])
					else:
						target_shortcut = get_root_with_id(options_dict["targets"][option_idx]["data"]["next"])
					if target_shortcut != null:
						connect_nodes_specific(reply_selector, str(option_idx), target_shortcut, "next")
						
				elif options_dict["options"][option_idx]["next"]["type"] == DialogData.NextType.RANDOM:
					var random_node: DiscourseGraphNode = spawn_random_select_node(options_dict["options"][option_idx]["next"])
					connect_nodes_specific(reply_selector, str(option_idx), random_node, "next")
					
				elif options_dict["options"][option_idx]["next"]["type"] == DialogData.NextType.CONDITION:
					var new_cond := spawn_conditional_split_node(options_dict["options"][option_idx]["next"])
					connect_nodes_specific(reply_selector, str(option_idx), new_cond, "next")
				
				#elif options_dict["options"][option_idx]["next"]["type"] == DialogData.NextType.END:
					#pass
	
	reply_selector.reply_cancel_box.value = options_dict["cancel"]
	
	return reply_selector


func spawn_reply_node(reply_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var option_node: DiscourseGraphNode = REPLY_NODE.instantiate()
	dialog_graph_edit.add_child(option_node)
	
	option_node.position_offset = offset_override if override_offset else reply_data["offset"]
	option_node.reply_line.text = reply_data["text"] 
	option_node.close_requested.connect(on_close_requested)
	
	if not reply_data["signal"].is_empty():
		var signal_node := spawn_signal_node(reply_data["signal"])
		connect_nodes(signal_node, option_node, "signal")
	
	if not reply_data["conditions"].is_empty():
		var comparation := spawn_comparator_node(reply_data["conditions"])
		connect_nodes(comparation, option_node, "result")
	
	if not reply_data["set_variable"].is_empty():
		var set_vars := spawn_variables_node(reply_data["set_variable"])
		connect_nodes(set_vars, option_node, "variables")
	
	if not reply_data["call"].is_empty():
		var call_node: DiscourseGraphNode = null
		if reply_data["call"]["is_return"]:
			call_node = spawn_return_call_node(reply_data["call"])
		else:
			call_node = spawn_call_node(reply_data["call"])
		connect_nodes(call_node, option_node, "call")
	
	return option_node


func spawn_comparator_node(comparation_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_comparator: DiscourseGraphNode = COMPARATION_NODE.instantiate()
	dialog_graph_edit.add_child(new_comparator)
	
	new_comparator.position_offset = offset_override if override_offset else comparation_data["offset"]
	new_comparator.select_by_text(comparation_data["operator"])
	new_comparator.close_requested.connect(on_close_requested)
	
	if not comparation_data["var_a"].is_empty():
		if comparation_data["var_a"]["type"] == DialogData.DialogType.COMPARATION:
			var a_comp := spawn_comparator_node(comparation_data["var_a"])
			connect_nodes_specific(a_comp, "result", new_comparator, "value_a")
		elif comparation_data["var_a"]["type"] == DialogData.DialogType.ELEMENT:
			var a_el := spawn_element_node(comparation_data["var_a"])
			connect_nodes_specific(a_el, "value", new_comparator, "value_a")
			dialog_graph_edit.connect_node(a_el.name, 0, new_comparator.name, 2)
	
	if not comparation_data["var_b"].is_empty():
		if comparation_data["var_b"]["type"] == DialogData.DialogType.COMPARATION:
			var b_comp := spawn_comparator_node(comparation_data["var_b"])
			connect_nodes_specific(b_comp, "result", new_comparator, "value_b")
		elif comparation_data["var_b"]["type"] == DialogData.DialogType.ELEMENT:
			var b_el := spawn_element_node(comparation_data["var_b"])
			connect_nodes_specific(b_el, "value", new_comparator, "value_b")
	
	return new_comparator


func spawn_element_node(element_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_element: DiscourseGraphNode = VAL_SELECTOR_NODE.instantiate()
	dialog_graph_edit.add_child(new_element)
	new_element.position_offset = offset_override if override_offset else element_data["offset"]
	new_element.close_requested.connect(on_close_requested)
	if not element_data["value"].is_empty():
		new_element.select_by_resource(element_data["value"]["element_type"])
		new_element.set_value(element_data["value"]["value"])
	return new_element


func spawn_signal_node(signal_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_signal_node: DiscourseGraphNode = SIGNAL_EMIT_NODE.instantiate()
	dialog_graph_edit.add_child(new_signal_node)
	new_signal_node.position_offset = offset_override if override_offset else signal_data["offset"]
	new_signal_node.signal_val_line.text = signal_data["signal"]
	new_signal_node.close_requested.connect(on_close_requested)
	return new_signal_node


func spawn_variables_node(variables_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var variables_node: DiscourseGraphNode = SET_VARIABLE_GNODE.instantiate()
	dialog_graph_edit.add_child(variables_node)
	variables_node.position_offset = offset_override if override_offset else variables_data["offset"]
	variables_node.close_requested.connect(on_close_requested)
	for variable in variables_data["variables"]:
		variables_node.add_variable_type(
				variable,
				variables_data["variables"][variable])
	return variables_node


func spawn_call_node(call_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_node: DiscourseGraphNode = METHOD_CALL_GNODE.instantiate()
	dialog_graph_edit.add_child(new_node)
	new_node.position_offset = offset_override if override_offset else call_data["offset"]
	new_node.select_by_callable(call_data["object"], call_data["method"])
	new_node.set_args(call_data["args"])
	new_node.close_requested.connect(on_close_requested)
	return new_node


func spawn_return_call_node(call_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_node: DiscourseGraphNode = RETURN_CALL_NODE.instantiate()
	dialog_graph_edit.add_child(new_node)
	new_node.position_offset = offset_override if override_offset else call_data["offset"]
	new_node.select_by_key(call_data["key"])
	new_node.set_args(call_data["args"])
	new_node.close_requested.connect(on_close_requested)
	return new_node


func spawn_comment_node(comment_data: Dictionary) -> DiscourseGraphNode:
	var new_comment: DiscourseGraphNode = COMMENT_GRAPH_NODE.instantiate()
	new_comment.close_requested.connect(on_close_requested)
	dialog_graph_edit.add_child(new_comment)
	new_comment.position_offset = comment_data["offset"]
	new_comment.size = comment_data["size"]
	new_comment.comment_text.text = comment_data["text"]
	return new_comment


func on_center_dialog_called(dialog_id: String) -> void:
	var target_dialog: DiscourseGraphNode = get_root_with_id(dialog_id)
	if target_dialog != null:
		center_node(target_dialog)


## Centers a node in the NodeEdit.
func center_node(dialog_node: DiscourseGraphNode) -> void:
	if _is_traveling:
		return
	_is_traveling = true # We prevent crazy movement
	var new_tween: Tween = get_tree().create_tween()
	var target := Vector2(
			((dialog_node.position_offset * dialog_graph_edit.zoom) -\
			(dialog_graph_edit.size / 2)) +\
			((dialog_node.size / 2) * dialog_graph_edit.zoom))
	await new_tween.tween_property(
		dialog_graph_edit,
		"scroll_offset",
		target,
		1.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).finished
	_is_traveling = false


func get_root_with_id(node_id: String) -> DiscourseGraphNode:
	for node in root_nodes:
		if node._get_node_id() == node_id:
			return node
	return null


func has_dialog_root(node_id: String) -> bool:
	for node in root_nodes:
		if node._get_node_id() == node_id:
			return true
	return false


func on_save_resources() -> void:
	for dialog_item:TreeItem in open_dialog_list.tree_root.get_children():
		
		var dialog_metadata: Dictionary = dialog_item.get_metadata(0)
		
		if not dialog_metadata["unsaved"]:
			continue # No need to waste time saving unchanged resources.
		
		#on_dialog_selected(dialog_item)
		
		if dialog_metadata["path"].is_empty():
			discourse_save_dialog.conv_data = dialog_metadata
			discourse_save_dialog.current_file = dialog_item.get_text(0)
			discourse_save_dialog.show()
		else:
			var entry: String = ""
			var conv_data: Dictionary = {}
			
			if dialog_item == current_dialog:
				conv_data = get_current_conversation_data()
			else:
				conv_data = dialog_metadata["temp"]
			
			if entry_node.has_output_connection("next"):
				entry = entry_node.get_output_port_connection_by_id("next").node_id
				
			save_onversation(conv_data, dialog_metadata["path"])


func on_save_folder_selected(file_path: String) -> void:
	save_onversation(
			discourse_save_dialog.conv_data,
			file_path)


func save_onversation(conversation_data: Dictionary, resource_path: String) -> void:
	var new_resource := DialogData.new()
	new_resource.dialog_entry = conversation_data["entry"]
	new_resource.conversation = conversation_data["tree"]
	new_resource.orphans = conversation_data["orphans"]
	conversation_data["unsaved"] = false
	conversation_data["resource"] = new_resource
	ResourceSaver.save(new_resource, resource_path)


func get_current_conversation_data() -> Dictionary:
	var entry: String = ""
	# Node references
	var id_orphans: Array[DiscourseGraphNode] = []
	var id_tree_nodes: Array[DiscourseGraphNode] = []
	
	# Dialog Data
	var full_data_dict: Dictionary = {}
	var orphans: Array[Dictionary] = []
	
	if entry_node.has_output_connection("next"):
		entry = entry_node.get_output_port_connection_by_id("next").node_id
	
	for node in dialog_graph_edit.get_children():
		if node is not DiscourseGraphNode:
			continue # We ignore the connection nodes.
		
		if node.node_type == DialogData.DialogType.START:
			continue # We can ignore the start node
		
		if node._is_root():
			if node.node_type == DialogData.DialogType.DIALOG or node.node_type == DialogData.DialogType.OPTIONS:
				id_tree_nodes.append(node)
			else:
				id_orphans.append(node)
	
	for node in id_tree_nodes:
		full_data_dict[node.node_id] = node.generate_node_dictionary()
	
	for node in id_orphans:
		orphans.append(node.generate_node_dictionary())
	
	return {"tree": full_data_dict, "orphans": orphans, "entry": entry}
