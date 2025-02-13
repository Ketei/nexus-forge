@tool
#class_name NFDiscourseTool
extends PanelContainer

#@warning_ignore("unused_signal")
#signal signal_name(age: int, gender: String) # Put in Discourse
#const signals: Dictionary = {&"signal_name": [{"type": TYPE_INT, "name": "Age"}, {"type": TYPE_STRING, "name": "Gender"}]}

# --------------------- Good -----------------------------------------
# ------------------------------ SCENES ------------------------------
const CHOICE_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/choice_graph_node.tscn")
const CONDITION_SET_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/condition_set_graph_node.tscn")
const COND_DIALOG_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/cond_dialog_graph_node.tscn")
const DIALOG_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/dialog_graph_node.tscn")
const END_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/end_graph_node.tscn")
const ENTRY_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/entry_graph_node.tscn")
const EVAL_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/eval_graph_node.tscn")
const EVENT_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/event_graph_node.tscn")
const JUMPER_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/jumper_graph_node.tscn")
const JUMP_TARGET_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/jump_target_node.tscn")
const MATCH_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/match_graph_node.tscn")
const MATH_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/math_graph_node.tscn")
const PAUSE_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/pause_graph_node.tscn")
const RANDOM_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/random_graph_node.tscn")
const SET_VAR_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/set_var_graph_node.tscn")
const SIGNAL_EMIT_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/signal_emit_graph_node.tscn")
const VALUE_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/value_graph_node.tscn")
const WAIT_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/wait_graph_node.tscn")
const CALL_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/call_graph_node.tscn")
const CALL_RETURN_GRAPH_NODE = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/call_return_graph_node.tscn")
# ------------------------------ SCRIPTS ------------------------------
const ResourceFileDialog = preload("res://addons/nexus_forge/classes/resource_file_dialog.gd")
const UnsavedDialogScript = preload("res://addons/nexus_forge/scenes/discourse/unsaved_dialog_script.gd")
# ---------------------------------------------------------------------

var targets: Array[DiscourseGraphNode] = []
var jumpers: Array[DiscourseGraphNode] = []
var menu_choices: Array[String] = []
var basic_nodes_submenu: PopupMenu = null
var advanced_nodes_submenu: PopupMenu = null
var logic_nodes_submenu: PopupMenu = null
#var unsaved_changes: bool = false
var open_conversations: Array[Dictionary] = [] # path: askldjalskjd, resource: Res, unsaved: false
var current_conv: int = -1:
	set(new_conv):
		current_conv = new_conv
		add_graph_mn_btn.disabled = current_conv == -1
var jumping: bool = false

@onready var dialog_graph_edit: GraphEdit = $MainContainer/NodesContainer/GraphPanel/DialogGraphEdit
@onready var add_graph_mn_btn: MenuButton = $MainContainer/NodesContainer/MenuContainer/AddGraphMnBtn
@onready var to_empty_pp_mn: PopupMenu = $ToEmptyPPMn
@onready var conversations_tree: Tree = $MainContainer/PanelsContainer/ConvContainer/OpenConversations
@onready var main_mn_btn: MenuButton = $MainContainer/NodesContainer/MenuContainer/MainMnBtn
@onready var no_conv_panel: PanelContainer = $MainContainer/NodesContainer/GraphPanel/NoConvPanel
@onready var jump_target_tree: Tree = $MainContainer/PanelsContainer/JumpTargetContainer/JumpTargetTree
@onready var issues_panel: PanelContainer = $MainContainer/NodesContainer/IssuesPanel
@onready var close_button: Button = $MainContainer/NodesContainer/IssuesPanel/MainContainer/MenuContainer/CloseButton
@onready var issues_tree: Tree = $MainContainer/NodesContainer/IssuesPanel/MainContainer/IssuesTree


func _ready() -> void:
	# --- Menus ---
	var popup := add_graph_mn_btn.get_popup()
	
	popup.clear(true)
	
	basic_nodes_submenu = PopupMenu.new()
	advanced_nodes_submenu = PopupMenu.new()
	logic_nodes_submenu = PopupMenu.new()
	
	basic_nodes_submenu.add_item("Dialog", 0)
	basic_nodes_submenu.add_item("Choices", 1)
	basic_nodes_submenu.add_item("Random", 2)
	basic_nodes_submenu.add_separator("Timing", 100)
	basic_nodes_submenu.add_item("Wait", 3)
	basic_nodes_submenu.add_item("Pause", 4)
	basic_nodes_submenu.add_separator("Jumps", 101)
	basic_nodes_submenu.add_item("Jump To", 5)
	basic_nodes_submenu.add_item("Jump Marker", 6)
	basic_nodes_submenu.add_separator("", 102)
	basic_nodes_submenu.add_item("End", 7)
	menu_choices.append("Dialog")
	menu_choices.append("Choices")
	menu_choices.append("Random")
	menu_choices.append("Wait")
	menu_choices.append("Pause")
	menu_choices.append("Jump To")
	menu_choices.append("Jump Marker")
	menu_choices.append("End")
	
	advanced_nodes_submenu.add_item("Conditional Dialog", 15)
	advanced_nodes_submenu.add_item("Event", 8)
	advanced_nodes_submenu.add_item("Value", 10)
	advanced_nodes_submenu.add_separator("Events", 100)
	advanced_nodes_submenu.add_item("Signal", 9)
	advanced_nodes_submenu.add_item("Set Variable", 11)
	advanced_nodes_submenu.add_item("Conditional Variable Set", 12)
	advanced_nodes_submenu.add_separator("Calls", 101)
	advanced_nodes_submenu.add_item("Call", 13)
	advanced_nodes_submenu.add_item("Call with return", 14)
	
	menu_choices.append("Event")
	menu_choices.append("Signal")
	menu_choices.append("Value")
	menu_choices.append("Set Variable")
	menu_choices.append("Conditional Variable Set")
	menu_choices.append("Call Function")
	menu_choices.append("Call Return")
	menu_choices.append("Conditional Dialog")
	
	logic_nodes_submenu.add_item("Match", 16)
	logic_nodes_submenu.add_item("Comparation", 17)
	logic_nodes_submenu.add_item("Math", 18)
	menu_choices.append("Match")
	menu_choices.append("Comparation")
	menu_choices.append("Math")
	
	popup.add_submenu_node_item("Basic Nodes", basic_nodes_submenu)
	popup.add_submenu_node_item("Advanced Nodes", advanced_nodes_submenu)
	popup.add_submenu_node_item("Logic Nodes", logic_nodes_submenu)
	# -------------
	
	issues_panel.visible = false
	
	#var entry_node := create_new_start_node()
	#await get_tree().process_frame
	#dialog_graph_edit.scroll_offset = -(dialog_graph_edit.size / 2.0) + Vector2(entry_node.size.x, entry_node.size.y / 2.0)
	
	dialog_graph_edit.connection_request.connect(on_connection_request)
	dialog_graph_edit.connection_drag_started.connect(on_connection_drag_started)
	dialog_graph_edit.connection_to_empty.connect(on_connection_to_empty.bind(true))
	dialog_graph_edit.connection_from_empty.connect(on_connection_to_empty.bind(false))
	basic_nodes_submenu.id_pressed.connect(on_add_graph_id_pressed)
	advanced_nodes_submenu.id_pressed.connect(on_add_graph_id_pressed)
	logic_nodes_submenu.id_pressed.connect(on_add_graph_id_pressed)
	to_empty_pp_mn.about_to_popup.connect(fix_menu_position)
	
	conversations_tree.conversation_selected.connect(on_conv_selected)
	
	main_mn_btn.get_popup().id_pressed.connect(_on_main_menu_mnbtn_id_selected)
	
	jump_target_tree.jump_target_selected.connect(on_jump_to_graph_target)
	
	issues_tree.issue_pressed.connect(on_jump_to_graph_target)
	close_button.pressed.connect(on_close_issues_pressed)


func clear_nodes() -> void:
	dialog_graph_edit.clear_connections()
	for child in dialog_graph_edit.get_children():
		if child is not DiscourseGraphNode:
			continue
		child.queue_free()
	dialog_graph_edit.zoom = 1.0
	dialog_graph_edit.scroll_offset = Vector2.ZERO


func register_target(target_node: DiscourseGraphNode) -> void:
	targets.append(target_node)
	target_node.target_changed.connect(on_target_changed)
	target_node.set_current_id(
			get_jump_valid_id(
					target_node.get_current_id(),
					target_node))
	jump_target_tree.add_target(target_node.get_current_id(), target_node)
	for jump in jumpers:
		if jump.jump_target_opt_btn.item_count == 0:
			jump.jump_target = target_node
		jump.add_target(target_node.get_current_id())


func on_jump_target_delete_requested(target: DiscourseGraphNode) -> void:
	var idx: int = targets.find(target)
	targets.remove_at(idx)
	jump_target_tree.remove_target(idx)
	for jumper in jumpers:
		jumper.remove_target(idx)
		if jumper.jump_target == target:
			jumper.jump_target = null


func on_jump_target_selected(jumper: DiscourseGraphNode, target_idx: int) -> void:
	jumper.jump_target = targets[target_idx]
	on_something_changed()


func register_jumper(target_node: DiscourseGraphNode) -> void:
	jumpers.append(target_node)
	target_node.clear_targets()
	if not targets.is_empty():
		for target in targets:
			target_node.add_target(target.get_current_id())
		target_node.jump_target = targets[0]
	target_node.jump_target_selected.connect(on_jump_target_selected)


func on_target_changed(target_node: DiscourseGraphNode) -> void: # Jump target node
	var valid_id: String = get_jump_valid_id(
			target_node.get_current_id() if not target_node.get_current_id().is_empty() else "target",
			target_node)
	var target_idx: int = targets.find(target_node)
	target_node.set_current_id(valid_id)
	jump_target_tree.update_target(target_idx, valid_id)
	
	for jump in jumpers:
		jump.change_id_name(target_idx, valid_id)
	on_something_changed()


func get_jump_valid_id(desired_id: String, skip_node: DiscourseGraphNode) -> String:
	var target_id: String = desired_id
	var counter: int = 0
	
	while has_target_id(target_id, skip_node):
		counter += 1
		target_id = desired_id + str(counter)
	
	return target_id


func has_target_id(target_id: String, skip: DiscourseGraphNode) -> bool:
	for target in targets:
		if target == skip:
			continue
		if target.get_current_id() == target_id:
			return true
	return false


func create_new_dialog_node(dialog_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_dialog := DIALOG_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_dialog)
	
	if dialog_data.has("_offset"):
		new_dialog.position_offset = dialog_data["_offset"]
	if dialog_data.has("_size"):
		new_dialog.size = dialog_data["_size"]
	
	if dialog_data.has_all(["text", "speed", "character_id"]):
		new_dialog.set_dialog_data(dialog_data["text"], dialog_data["speed"], dialog_data["character_id"])
	
	new_dialog.node_updated.connect(on_something_changed)
	new_dialog.close_requested.connect(delete_node)
	new_dialog.duplicate_requested.connect(on_duplicate_node)
	
	return new_dialog


func create_new_choices_node(choices_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_choices := CHOICE_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_choices)
	
	if choices_data.has("_offset"):
		new_choices.position_offset = choices_data["_offset"]
	
	if choices_data.has("choices"):
		var choices: Array[String] = []
		for dict_choice in choices_data["choices"]:
			choices.append(dict_choice["text"])
		new_choices.set_choices(choices)
	
	if choices_data.has("keep_text"):
		new_choices.set_keep_text(choices_data["keep_text"])
	
	new_choices.node_updated.connect(on_something_changed)
	new_choices.close_requested.connect(delete_node)
	new_choices.duplicate_requested.connect(on_duplicate_node)
	
	return new_choices


func create_new_random_node(random_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_random := RANDOM_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_random)
	
	if random_data.has("_offset"):
		new_random.position_offset = random_data["_offset"]
	
	if random_data.has("exits"):
		var random_weights: Array[float] = []
		for weight in random_data["exits"]:
			random_weights.append(weight["weight"])
		new_random.set_random_with_weights(random_weights)
	
	if random_data.has("use_weights"):
		new_random.set_use_weights(random_data["use_weights"])
	
	new_random.node_updated.connect(on_something_changed)
	new_random.close_requested.connect(delete_node)
	new_random.duplicate_requested.connect(on_duplicate_node)
	
	return new_random


func create_new_wait_node(wait_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_wait := WAIT_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_wait)
	
	if wait_data.has("wait_time"):
		new_wait.set_wait_time(wait_data["wait_time"])
	if wait_data.has("_offset"):
		new_wait.position_offset = wait_data["_offset"]
	
	new_wait.node_updated.connect(on_something_changed)
	new_wait.close_requested.connect(delete_node)
	new_wait.duplicate_requested.connect(on_duplicate_node)
	
	return new_wait


func create_new_pause_node(pause_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_wait := PAUSE_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_wait)
	
	if pause_data.has("_offset"):
		new_wait.position_offset = pause_data
	
	new_wait.node_updated.connect(on_something_changed)
	new_wait.close_requested.connect(delete_node)
	new_wait.duplicate_requested.connect(on_duplicate_node)
	
	return new_wait


# Jump to
func create_new_jump_pointer(jump_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_pointer := JUMPER_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_pointer)
	register_jumper(new_pointer)
	
	if jump_data.has("_offset"):
		new_pointer.position_offset = jump_data["_offset"]
	
	new_pointer.node_updated.connect(on_something_changed)
	new_pointer.close_requested.connect(delete_node)
	new_pointer.duplicate_requested.connect(on_duplicate_node)
	
	return new_pointer


func create_new_jump_target(jump_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_target := JUMP_TARGET_NODE.instantiate()
	dialog_graph_edit.add_child(new_target)
	register_target(new_target)
	
	if jump_data.has("_offset"):
		new_target.position_offset = jump_data["_offset"]
	if jump_data.has("name"):
		new_target.set_current_id(jump_data["name"])
	
	on_target_changed(new_target)
	
	new_target.close_requested.connect(delete_node)
	new_target.duplicate_requested.connect(on_duplicate_node)
	
	return new_target


func create_new_start_node(start_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_start := preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/entry_graph_node.tscn").instantiate()
	dialog_graph_edit.add_child(new_start)
	
	if start_data.has("_offset"):
		new_start.position_offset = start_data["_offset"]
	
	return new_start


func create_new_end_node(end_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_end := END_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_end)
	
	if end_data.has("_offset"):
		new_end.position_offset = end_data["_offset"]
	
	new_end.close_requested.connect(delete_node)
	new_end.duplicate_requested.connect(on_duplicate_node)
	
	return new_end


func create_new_event_node(event_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_event := EVENT_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_event)
	
	if event_data.has("_offset"):
		new_event.position_offset = event_data["_offset"]
	
	new_event.close_requested.connect(delete_node)
	new_event.duplicate_requested.connect(on_duplicate_node)
	
	return new_event


func create_new_signal_node(signal_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_signal := SIGNAL_EMIT_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_signal)
	
	if signal_data.has("signal"):
		new_signal.select_signal(signal_data["signal"])
	if signal_data.has("arguments") and not signal_data["arguments"].is_empty():
		var arg_idx: int = 0
		for signal_arg in signal_data["arguments"]:
			arg_idx += 1
			new_signal.set_argument_value(arg_idx, signal_arg["value"])
	if signal_data.has("_offset"):
		new_signal.position_offset = signal_data["_offset"]
	
	new_signal.node_updated.connect(on_something_changed)
	new_signal.close_requested.connect(delete_node)
	new_signal.duplicate_requested.connect(on_duplicate_node)
	
	return new_signal


func create_new_value_node(value_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_value := VALUE_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_value)
	
	if value_data.has("_offset"):
		new_value.position_offset = value_data["_offset"]
	if value_data.has_all(["var_type", "value"]):
		new_value.set_type(value_data["var_type"])
		new_value.set_value(value_data["value"])
	
	new_value.node_updated.connect(on_something_changed)
	new_value.close_requested.connect(delete_node)
	new_value.duplicate_requested.connect(on_duplicate_node)
	
	return new_value


func create_new_set_var_node(var_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_set_var := SET_VAR_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_set_var)
	
	if var_data.has("_offset"):
		new_set_var.position_offset = var_data["_offset"]
	if var_data.has("var_type"):
		new_set_var.set_type(var_data["var_type"])
	if var_data.has("path"):
		new_set_var.set_var_path(var_data["path"])
	new_set_var.node_updated.connect(on_something_changed)
	new_set_var.close_requested.connect(delete_node)
	new_set_var.duplicate_requested.connect(on_duplicate_node)
	return new_set_var


func create_new_cond_var_node(cond_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_cond_var := CONDITION_SET_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_cond_var)
	
	if cond_data.has("_offset"):
		new_cond_var.position_offset = cond_data["_offset"]
	new_cond_var.node_updated.connect(on_something_changed)
	new_cond_var.close_requested.connect(delete_node)
	new_cond_var.duplicate_requested.connect(on_duplicate_node)
	return new_cond_var


func create_new_cond_dialog_node(cond_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_cond_dialog := COND_DIALOG_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_cond_dialog)
	
	if cond_data.has("_offset"):
		new_cond_dialog.position_offset = cond_data["_offset"]
	new_cond_dialog.close_requested.connect(delete_node)
	new_cond_dialog.duplicate_requested.connect(on_duplicate_node)
	return new_cond_dialog


func create_new_match_node(match_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_match := MATCH_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_match)
	
	if match_data.has("_offset"):
		new_match.position_offset = match_data["_offset"]
	if match_data.has("cases"):
		new_match.set_case_values(match_data["cases"])
	new_match.node_updated.connect(on_something_changed)
	new_match.close_requested.connect(delete_node)
	new_match.duplicate_requested.connect(on_duplicate_node)
	return new_match


func create_new_comparation_node(comp_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_comp := EVAL_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_comp)
	
	if comp_data.has("_offset"):
		new_comp.position_offset = comp_data["_offset"]
	if comp_data.has("operator"):
		new_comp.set_operator(comp_data["operator"])
	new_comp.node_updated.connect(on_something_changed)
	new_comp.close_requested.connect(delete_node)
	new_comp.duplicate_requested.connect(on_duplicate_node)
	return new_comp


func create_new_math_node(math_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_math := MATH_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_math)
	
	if math_data.has("_offset"):
		new_math.position_offset = math_data["_offset"]
	if math_data.has("operator"):
		new_math.set_math_operator(math_data["operator"])
	new_math.node_updated.connect(on_something_changed)
	new_math.close_requested.connect(delete_node)
	new_math.duplicate_requested.connect(on_duplicate_node)
	return new_math


func create_new_call_node(call_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_call := CALL_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_call)
	
	if call_data.has("_offset"):
		new_call.position_offset = call_data["_offset"]
	
	if call_data.has_all(["call_id", "call_args"]):
		new_call.set_call(call_data["call_id"])
		new_call.set_call_args(call_data["call_args"])
	
	new_call.node_updated.connect(on_something_changed)
	new_call.close_requested.connect(delete_node)
	new_call.duplicate_requested.connect(on_duplicate_node)
	
	return new_call


func create_new_return_call_node(call_data: Dictionary = {}) -> DiscourseGraphNode:
	var new_return := CALL_RETURN_GRAPH_NODE.instantiate()
	dialog_graph_edit.add_child(new_return)
	
	if call_data.has("_offset"):
		new_return.position_offset = call_data["_offset"]
	
	if call_data.has_all(["call_id", "call_args"]):
		new_return.set_call(call_data["call_id"])
		new_return.set_call_args(call_data["call_args"])
	
	new_return.node_updated.connect(on_something_changed)
	new_return.close_requested.connect(delete_node)
	new_return.duplicate_requested.connect(on_duplicate_node)
	
	return new_return


func get_dialog_graph_center_offset() -> Vector2:
	return Vector2((dialog_graph_edit.scroll_offset / dialog_graph_edit.zoom) + ((dialog_graph_edit.size / 2) / dialog_graph_edit.zoom))


func snap_to_graph_grid(target_node: DiscourseGraphNode) -> void:
	if not dialog_graph_edit.snapping_enabled:
		return
	target_node.position_offset = target_node.position_offset.snappedf(dialog_graph_edit.snapping_distance)


func delete_node(graph_node: DiscourseGraphNode) -> void:
	var disconnection_requests: Array[Dictionary] = []
	for input_id in graph_node.get_input_ids():
		if graph_node.has_any_input_connection(input_id):
			for from_node in graph_node.get_input_connections(input_id):
				var from_port := from_node.get_output_port(from_node.get_output_id_by_connection(graph_node))
				var to_port := graph_node.get_input_port(graph_node.get_input_id_by_connection(from_node))
				disconnection_requests.append(
					{
						"from_node": from_node.name,
						"from_port": from_port,
						"to_node": graph_node.name,
						"to_port": to_port
					})
	
	for output_id in graph_node.get_output_ids():
		if graph_node.has_any_output_connection(output_id):
			for to_node in graph_node.get_output_connections(output_id):
				var from_port := graph_node.get_output_port(graph_node.get_output_id_by_connection(to_node))
				var to_port := to_node.get_input_port(to_node.get_input_id_by_connection(graph_node))
				disconnection_requests.append(
					{
						"from_node": graph_node.name,
						"from_port": from_port,
						"to_node": to_node.name,
						"to_port": to_port
					})
	
	for disconnect_dict in disconnection_requests:
		on_disconnection_request(
				disconnect_dict["from_node"],
				disconnect_dict["from_port"],
				disconnect_dict["to_node"],
				disconnect_dict["to_port"])
	
	if graph_node.graph_type == DiscourseGraphNode.GraphType.JUMP_TARGET:
		on_jump_target_delete_requested(graph_node)
	
	graph_node.queue_free()
	on_something_changed()


func on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(from_node))
	var to_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(to_node))
	
	var from_id: String = from_graph.get_output_id_by_port(from_port)
	var to_id: String = to_graph.get_input_id_by_port(to_port)
	
	if to_graph.has_any_input_connection(to_id) and not to_graph.input_allows_multiple_connections(to_id):
		var _from := to_graph.get_input_connections(to_id)[0]
		dialog_graph_edit.disconnect_node(
			_from.name,
			_from.get_output_port(_from.get_output_id_by_connection(to_graph)),
			to_graph.name,
			to_port)
	
	dialog_graph_edit.connect_node(
			from_node,
			from_port,
			to_node,
			to_port)
	
	from_graph.connect_output_node(from_id, to_graph)
	to_graph.connect_input_node(to_id, from_graph)
	on_something_changed()


func on_connection_drag_started(from_node: StringName, from_port: int, is_output: bool) -> void:
	var graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(from_node))
	var id: String = graph.get_output_id_by_port(from_port) if is_output else graph.get_input_id_by_port(from_port)
	if is_output and graph.has_any_output_connection(id) and not graph.output_allows_multiple_connections(id):
		var to_graph: DiscourseGraphNode = graph.get_output_connections(id)[0]
		var to_id: String = to_graph.get_input_id_by_connection(graph)
		dialog_graph_edit.disconnect_node(
			from_node,
			from_port,
			to_graph.name,
			to_graph.get_input_port(to_id))
		graph.disconnect_output_node(id, to_graph)
		to_graph.disconnect_input_node(to_id, graph)
	elif not is_output and graph.has_any_input_connection(id) and not graph.input_allows_multiple_connections(id):
		var from_graph: DiscourseGraphNode = graph.get_input_connections(id)[0]
		var from_id: String = from_graph.get_output_id_by_connection(graph)
		dialog_graph_edit.disconnect_node(
			from_graph.name,
			from_graph.get_output_port(from_id),
			from_node,
			from_port)
		from_graph.disconnect_output_node(from_id, graph)
		graph.disconnect_input_node(id, from_graph)


func on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(from_node))
	var to_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(to_node))
	var from_id: String = from_graph.get_output_id_by_port(from_port)
	var to_id: String = to_graph.get_input_id_by_port(to_port)
	
	dialog_graph_edit.disconnect_node(
			from_node,
			from_port,
			to_node,
			to_port)
	
	from_graph.disconnect_output_node(from_id, to_graph)
	to_graph.disconnect_input_node(to_id, from_graph)
	on_something_changed()


func on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2, to_empty: bool) -> void:
	if not Input.is_key_pressed(KEY_CTRL):
		return
	
	const separators: Array[String] = ["Dialog", "Timing", "Jumps", "Events", "Calls", "Logic", "Variables"]
	
	const to_next: Array[int] = [100, 0, 15, 1, 2, 101, 3, 4, 102, 5, 103, 8, 105, 16, 7]
	const to_var: Array[int] = [8, 12] #12 has 2 ports.
	const to_call: Array[int] = [8]
	const to_signal: Array[int] = [8]
	const to_val: Array[int] = [100, 1, 15, 106, 11, 12, 105, 16, 17, 18] # 17,18 A,B
	
	const from_next: Array[int] = [100, 0, 15, 1, 101, 3, 4, 102, 6, 103, 8, 105, 16] # 15 has 2 ports
	const from_var: Array[int] = [11, 12] 
	const from_val: Array[int] = [10, 104, 14, 105, 17, 18]
	
	var from_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(from_node))
	
	to_empty_pp_mn.reset_menu()
	to_empty_pp_mn.to_input = to_empty
	
	if to_empty:
		to_empty_pp_mn.from_node = from_graph
		to_empty_pp_mn.from_port = from_port
	else:
		to_empty_pp_mn.to_node = from_graph
		to_empty_pp_mn.to_port = from_port
	
	to_empty_pp_mn.at = Vector2((release_position / dialog_graph_edit.zoom) + (dialog_graph_edit.scroll_offset / dialog_graph_edit.zoom))
	
	match from_graph.get_output_port_type(from_port) if to_empty else from_graph.get_input_port_type(from_port):
		0: # Next
			if to_empty:
				for idx in to_next:
					if idx < 100:
						to_empty_pp_mn.add_item(menu_choices[idx], idx)
					else:
						to_empty_pp_mn.add_separator(separators[idx - 100], idx)
			else:
				for idx in from_next:
					if idx < 100:
						if idx == 15:
							var bool_submenu := PopupMenu.new()
							bool_submenu.add_item("True", 151)
							bool_submenu.add_item("False", 150)
							bool_submenu.size.x = 72
							to_empty_pp_mn.add_submenu_node_item("To Cond. Dialog", bool_submenu, 100)
							bool_submenu.id_pressed.connect(on_connect_empty_next)
						else:
							to_empty_pp_mn.add_item(menu_choices[idx], idx)
					else:
						to_empty_pp_mn.add_separator(separators[idx - 100], idx)
			to_empty_pp_mn.id_pressed.connect(on_connect_empty_next)
		1: # callable
			if not to_empty: # Instantiate instead
				var new_call := create_new_call_node()
				new_call.position_offset = to_empty_pp_mn.at - new_call.get_output_port_position(0)
				on_connection_request(new_call.name, 0, from_node, from_port)
				snap_to_graph_grid(new_call)
				return
			for idx in to_call:
				to_empty_pp_mn.add_item(menu_choices[idx], idx)
			to_empty_pp_mn.id_pressed.connect(on_connect_empty_call)
		2: # Variable
			if to_empty:
				for idx in to_var:
					if idx < 100:
						if idx == 12:
							to_empty_pp_mn.add_item(menu_choices[idx], 100)
							var bool_submenu := PopupMenu.new()
							bool_submenu.add_item("True", 121)
							bool_submenu.add_item("False", 120)
							bool_submenu.size.x = 72
							to_empty_pp_mn.add_submenu_node_item(menu_choices[idx], bool_submenu)
							bool_submenu.id_pressed.connect(on_connect_empty_var)
						else:
							to_empty_pp_mn.add_item(menu_choices[idx], idx)
					else:
						to_empty_pp_mn.add_separator(separators[idx - 100], idx)
			else:
				for idx in from_var:
					if idx < 100:
						to_empty_pp_mn.add_item(menu_choices[idx], idx)
					else:
						to_empty_pp_mn.add_separator(separators[idx - 100], idx)
			to_empty_pp_mn.id_pressed.connect(on_connect_empty_var)
		3: # Signal
			if not to_empty:
				var new_signal := create_new_signal_node()
				new_signal.position_offset = release_position - new_signal.get_output_port_position(0)
				snap_to_graph_grid(new_signal)
				on_connection_request(new_signal.name, 0, from_node, from_port)
				return
			for idx in to_signal:
				to_empty_pp_mn.add_item(menu_choices[idx], idx)
			to_empty_pp_mn.id_pressed.connect(on_connect_empty_signal)
		4: #Value
			if to_empty:
				for idx in to_val:
					if idx < 100:
						if idx == 17 or idx == 18:
							var new_eval_submenu := PopupMenu.new()
							new_eval_submenu.add_item("To Value: A", idx * 10)
							new_eval_submenu.add_item("To Value: B", (idx * 10) + 1)
							to_empty_pp_mn.add_submenu_node_item(
								"Comparation" if idx == 17 else "Math",
								new_eval_submenu,
								100 + idx - 17)
							new_eval_submenu.id_pressed.connect(on_connect_empty_val)
						else:
							to_empty_pp_mn.add_item(menu_choices[idx], idx)
					else:
						to_empty_pp_mn.add_separator(separators[idx - 100], idx)
			else:
				for idx in from_val:
					if idx < 100:
						to_empty_pp_mn.add_item(menu_choices[idx], idx)
					else:
						to_empty_pp_mn.add_separator(separators[idx - 100], idx)
			to_empty_pp_mn.id_pressed.connect(on_connect_empty_val)
	to_empty_pp_mn.position = get_viewport().get_mouse_position()
	to_empty_pp_mn.show()
	fix_menu_position()


func on_connect_empty_next(id: int) -> void:
	var new_node: DiscourseGraphNode = null
	var at: Vector2 = to_empty_pp_mn.at
	
	match id:
		0:
			new_node = create_new_dialog_node()
			if to_empty_pp_mn.to_input:
				at -= new_node.get_input_port_position(0)
				on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
			else:
				at -= new_node.get_output_port_position(0)
				on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
				
		1:
			new_node = create_new_choices_node()
			if to_empty_pp_mn.to_input:
				at -= new_node.get_input_port_position(0)
				on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
			else:
				at -= new_node.get_output_port_position(0)
				on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		2:
			new_node = create_new_random_node()
			if to_empty_pp_mn.to_input:
				at -= new_node.get_input_port_position(0)
				on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
			else:
				at -= new_node.get_output_port_position(0)
				on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		3:
			new_node = create_new_wait_node()
			if to_empty_pp_mn.to_input:
				at -= new_node.get_input_port_position(0)
				on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
			else:
				at -= new_node.get_output_port_position(0)
				on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		4:
			new_node = create_new_pause_node()
			if to_empty_pp_mn.to_input:
				at -= new_node.get_input_port_position(0)
				on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
			else:
				at -= new_node.get_output_port_position(0)
				on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		5:
			new_node = create_new_jump_pointer()
			at -= new_node.get_input_port_position(0)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
		6:
			new_node = create_new_jump_target()
			at -= new_node.get_output_port_position(0)
			on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		7:
			new_node = create_new_end_node()
			at -= new_node.get_input_port_position(0)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
		8:
			new_node = create_new_event_node()
			if to_empty_pp_mn.to_input:
				at -= new_node.get_input_port_position(0)
				on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
			else:
				at -= new_node.get_output_port_position(0)
				on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		15:
			new_node = create_new_cond_dialog_node()
			at -= new_node.get_input_port_position(0)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
		150:
			new_node = create_new_cond_dialog_node()
			at -= new_node.get_output_port_position(1)
			on_connection_request(new_node.name, 1, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		151:
			new_node = create_new_cond_dialog_node()
			at -= new_node.get_output_port_position(0)
			on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		16:
			new_node = create_new_match_node()
			if to_empty_pp_mn.to_input:
				at -= new_node.get_input_port_position(0)
				on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
			else:
				at -= new_node.get_output_port_position(0)
				on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
	
	new_node.position_offset = at
	snap_to_graph_grid(new_node)


func on_connect_empty_call(id: int) -> void:
	var new_node: DiscourseGraphNode = null
	var at: Vector2 = to_empty_pp_mn.at
	match id:
		8: # Event
			new_node = create_new_event_node()
			at -= new_node.get_input_port_position(1)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 1)
		
	new_node.position_offset = at
	snap_to_graph_grid(new_node)


func on_connect_empty_var(id: int) -> void:
	var new_node: DiscourseGraphNode = null
	var at: Vector2 = to_empty_pp_mn.at
	match id:
		8: # Event
			new_node = create_new_event_node()
			at -= new_node.get_input_port_position(2)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 2)
		11:
			new_node = create_new_set_var_node()
			at -= new_node.get_output_port_position(0)
			on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		12:# 2 Cond set
			new_node = create_new_cond_var_node()
			at -= new_node.get_output_port_position(0)
			on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		121:# Cond set true
			new_node = create_new_cond_var_node()
			at -= new_node.get_input_port_position(1)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 1)
		120: # Cond set dalse
			new_node = create_new_cond_var_node()
			at -= new_node.get_input_port_position(2)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 2)
	new_node.position_offset = at
	snap_to_graph_grid(new_node)


func on_connect_empty_signal(id: int) -> void:
	var new_node: DiscourseGraphNode = null
	var at: Vector2 = to_empty_pp_mn.at
	match id:
		8: # Event
			new_node = create_new_event_node()
			at -= new_node.get_input_port_position(3)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 3)
	new_node.position_offset = at
	snap_to_graph_grid(new_node)


func on_connect_empty_val(id: int) -> void:
	var new_node: DiscourseGraphNode = null
	var at: Vector2 = to_empty_pp_mn.at

	match id:
		1:
			new_node = create_new_choices_node()
			at -= new_node.get_input_port_position(1)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 1)
		10:
			new_node = create_new_value_node()
			at -= new_node.get_output_port_position(0)
			on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		11:
			new_node = create_new_set_var_node()
			at -= new_node.get_input_port_position(0)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
		12:
			new_node = create_new_cond_var_node()
			at -= new_node.get_input_port_position(0)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
		14:
			new_node = create_new_return_call_node()
			at -= new_node.get_output_port_position(0)
			on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		15:
			new_node = create_new_cond_dialog_node()
			at -= new_node.get_input_port_position(1)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 1)
		16:
			new_node = create_new_match_node()
			at -= new_node.get_input_port_position(1)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 1)
		17:# Eval output
			new_node = create_new_comparation_node()
			at -= new_node.get_output_port_position(0)
			on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		170: # Eval input A
			new_node = create_new_comparation_node()
			at -= new_node.get_input_port_position(0)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
		171: # Eval input B
			new_node = create_new_comparation_node()
			at -= new_node.get_input_port_position(1)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 1)
		18: # math output
			new_node = create_new_math_node()
			at -= new_node.get_output_port_position(0)
			on_connection_request(new_node.name, 0, to_empty_pp_mn.to_node.name, to_empty_pp_mn.to_port)
		180: # Math input A
			new_node = create_new_math_node()
			at -= new_node.get_input_port_position(0)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 0)
		181: # Math input B
			new_node = create_new_math_node()
			at -= new_node.get_input_port_position(1)
			on_connection_request(to_empty_pp_mn.from_node.name, to_empty_pp_mn.from_port, new_node.name, 1)
		
	new_node.position_offset = at
	snap_to_graph_grid(new_node)



func on_add_graph_id_pressed(id: int) -> void:
	var new_graph_node: DiscourseGraphNode = null
	
	match id:
		0:
			new_graph_node = create_new_dialog_node()
		1:
			new_graph_node = create_new_choices_node()
		2:
			new_graph_node = create_new_random_node()
		3:
			new_graph_node = create_new_wait_node()
		4:
			new_graph_node = create_new_pause_node()
		5:
			new_graph_node = create_new_jump_pointer()
		6:
			new_graph_node = create_new_jump_target()
		7:
			new_graph_node = create_new_end_node()
		8:
			new_graph_node = create_new_event_node()
		9:
			new_graph_node = create_new_signal_node()
		10:
			new_graph_node = create_new_value_node()
		11:
			new_graph_node = create_new_set_var_node()
		12:
			new_graph_node = create_new_cond_var_node()
		13:
			new_graph_node = create_new_call_node()
		14:
			new_graph_node = create_new_return_call_node()
		15:
			new_graph_node = create_new_cond_dialog_node()
		16:
			new_graph_node = create_new_match_node()
		17:
			new_graph_node = create_new_comparation_node()
		18:
			new_graph_node = create_new_math_node()
	
	if new_graph_node != null:
		new_graph_node.position_offset = get_dialog_graph_center_offset() - (new_graph_node.size / 2)
		snap_to_graph_grid(new_graph_node)


func on_duplicate_node(target_node: DiscourseGraphNode) -> void:
	var target_data: Dictionary = target_node._get_node_data()
	var dupe_node: DiscourseGraphNode = null
	match target_data["_type"]:
		DiscourseGraphNode.GraphType.DIALOG:
			dupe_node = create_new_dialog_node(target_data)
		DiscourseGraphNode.GraphType.CHOICES:
			dupe_node = create_new_choices_node(target_data)
		DiscourseGraphNode.GraphType.SIGNAL:
			dupe_node = create_new_signal_node(target_data)
		DiscourseGraphNode.GraphType.VALUE:
			dupe_node = create_new_value_node(target_data)
		DiscourseGraphNode.GraphType.WAIT:
			dupe_node = create_new_wait_node(target_data)
		DiscourseGraphNode.GraphType.PAUSE:
			dupe_node = create_new_pause_node(target_data)
		DiscourseGraphNode.GraphType.CONDITIONAL_VALUE:
			dupe_node = create_new_cond_var_node(target_data)
		DiscourseGraphNode.GraphType.CONDITIONAL_DIALOG:
			dupe_node = create_new_cond_dialog_node(target_data)
		DiscourseGraphNode.GraphType.MATCH:
			dupe_node = create_new_match_node(target_data)
		DiscourseGraphNode.GraphType.MATH:
			dupe_node = create_new_math_node(target_data)
		DiscourseGraphNode.GraphType.EVAL:
			dupe_node = create_new_comparation_node(target_data)
		DiscourseGraphNode.GraphType.RANDOM:
			dupe_node = create_new_random_node(target_data)
		DiscourseGraphNode.GraphType.VAR_SET:
			dupe_node = create_new_set_var_node(target_data)
		DiscourseGraphNode.GraphType.JUMP:
			dupe_node = create_new_jump_pointer(target_data)
		DiscourseGraphNode.GraphType.JUMP_TARGET:
			dupe_node = create_new_jump_target(target_data)
		DiscourseGraphNode.GraphType.CALL:
			pass
		DiscourseGraphNode.GraphType.RETURN_CALL:
			pass
		DiscourseGraphNode.GraphType.END:
			dupe_node = create_new_end_node(target_data)
	dupe_node.position_offset.x += dupe_node.size.x + mini(40, dialog_graph_edit.snapping_distance)
	snap_to_graph_grid(dupe_node)


func on_something_changed() -> void:
	if current_conv != -1 and not open_conversations[current_conv]["unsaved"]:
		#unsaved_changes = true
		open_conversations[current_conv]["unsaved"] = true
	#if not unsaved_changes:
		#unsaved_changes = true


func _on_main_menu_mnbtn_id_selected(id: int) -> void:
	match id:
		0: # New
			var new_loader := ResourceFileDialog.new()
			new_loader.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
			add_child(new_loader)
			new_loader.show()
			
			var result: Array = await new_loader.dialog_finished
			
			if result[0]:
				for idx in range(open_conversations.size()):
					if open_conversations[idx]["path"] == result[1]:
						open_conversations[idx]["resource"] = DialogResource.new()
						open_conversations[idx]["unsaved"] = true
						conversations_tree.select(idx)
						new_loader.queue_free()
						return
				if current_conv != -1:
					current_to_memory()
				var new_res := DialogResource.new()
				if ResourceSaver.save(new_res, result[1]) == OK:
					open_conversations.append({
						"path": result[1],
						"resource": new_res, # Any unsaved changes will be stored here.
						"unsaved": true,
						"offset": Vector2(),
						"zoom": 1.0})
					conversations_tree.add_conversation(result[1].get_file())
					clear_nodes()
					load_conversation(new_res)
					current_conv = open_conversations.size() - 1
					conversations_tree.select_no_signal(current_conv)
				else:
					push_error("Couldn't Save File")
				if no_conv_panel.visible:
					no_conv_panel.visible = false
			new_loader.queue_free()
		1: # Open
			var new_loader := ResourceFileDialog.new()
			new_loader.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
			add_child(new_loader)
			new_loader.show()
			var result = await new_loader.dialog_finished
			if result[0]:
				for idx in range(open_conversations.size()):
					if open_conversations[idx]["path"] == result[1]:
						conversations_tree.select(idx)
						new_loader.queue_free()
						return
				var res_preload: Resource = load(result[1])
				if res_preload is DialogResource:
					open_conversations.append(
							{
								"path": result[1],
								"resource": res_preload, # Any unsaved changes will be stored here.
								"unsaved": false, # Will turn to true if on switching unsaved_changes is true.
								"offset": Vector2(),
								"zoom": 1.0
								})
					conversations_tree.add_conversation(result[1].get_file())
					current_conv = open_conversations.size() - 1
					conversations_tree.select_no_signal(current_conv)
					clear_nodes()
					load_conversation(res_preload)
					if no_conv_panel.visible:
						no_conv_panel.visible = false
				else:
					push_error("Selected Resource isn't DialogResource")
			new_loader.queue_free()
		2: # Save Current
			save_current()
		3: # Save All
			save_all()
		4: # Close Current
			if is_current_unsaved():
				var new_warning := UnsavedDialogScript.new()
				add_child(new_warning)
				new_warning.show()
				var action = await new_warning.dialog_finished
				if action == 0:
					save_current()
				elif action == 2:
					return
				new_warning.queue_free()
			close_conversation(current_conv)
		5: # Close All
			close_all_conversations()
		6: # Check for issues
			check_for_errors()
			


func on_jump_to_graph_target(target: DiscourseGraphNode) -> void:
	if jumping:
		return
	
	jumping = true
	
	var new_tween: Tween = get_tree().create_tween()
	var target_position := Vector2(
			((target.position_offset * dialog_graph_edit.zoom) -\
			(dialog_graph_edit.size / 2)) +\
			((target.size / 2) * dialog_graph_edit.zoom))
	
	await new_tween.tween_property(
		dialog_graph_edit,
		"scroll_offset",
		target_position,
		1.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).finished
	
	jumping = false


# Use clear_nodes before this or chaos ensues.
func load_conversation(conversation: DialogResource) -> void:
	clear_targets()
	var entry_node := create_new_start_node()
	entry_node.position_offset = conversation.entry_offset
	dialog_graph_edit.scroll_offset = -(dialog_graph_edit.size / 2.0) + Vector2(entry_node.size.x, entry_node.size.y / 2.0)
	var nodes: Array[DiscourseGraphNode] = []
	for conv_dict in conversation.conversation: # First loop to instantiate
		var new_node: DiscourseGraphNode = null
		match conv_dict["_type"]:
			DiscourseGraphNode.GraphType.DIALOG:
				new_node = create_new_dialog_node(conv_dict)
			DiscourseGraphNode.GraphType.CHOICES:
				new_node = create_new_choices_node(conv_dict)
			DiscourseGraphNode.GraphType.SIGNAL:
				new_node = create_new_signal_node(conv_dict)
			DiscourseGraphNode.GraphType.VALUE:
				new_node = create_new_value_node(conv_dict)
			DiscourseGraphNode.GraphType.WAIT:
				new_node = create_new_wait_node(conv_dict)
			DiscourseGraphNode.GraphType.PAUSE:
				new_node = create_new_pause_node(conv_dict)
			DiscourseGraphNode.GraphType.CONDITIONAL_VALUE:
				new_node = create_new_cond_var_node(conv_dict)
			DiscourseGraphNode.GraphType.CONDITIONAL_DIALOG:
				new_node = create_new_cond_dialog_node(conv_dict)
			DiscourseGraphNode.GraphType.MATCH:
				new_node = create_new_match_node(conv_dict)
			DiscourseGraphNode.GraphType.MATH:
				new_node = create_new_math_node(conv_dict)
			DiscourseGraphNode.GraphType.EVAL:
				new_node = create_new_comparation_node(conv_dict)
			DiscourseGraphNode.GraphType.RANDOM:
				new_node = create_new_random_node(conv_dict)
			DiscourseGraphNode.GraphType.VAR_SET:
				new_node = create_new_set_var_node(conv_dict)
			DiscourseGraphNode.GraphType.JUMP:
				new_node = create_new_jump_pointer(conv_dict)
			DiscourseGraphNode.GraphType.JUMP_TARGET:
				new_node = create_new_jump_target(conv_dict)
			DiscourseGraphNode.GraphType.CALL:
				new_node = create_new_call_node(conv_dict)
			DiscourseGraphNode.GraphType.RETURN_CALL:
				new_node = create_new_return_call_node(conv_dict)
			DiscourseGraphNode.GraphType.EVENT:
				new_node = create_new_event_node(conv_dict)
			DiscourseGraphNode.GraphType.END:
				new_node = create_new_end_node(conv_dict)
		nodes.append(new_node)
	
	if conversation.entry_index != -1:
		on_connection_request(entry_node.name, 0, nodes[conversation.entry_index].name, nodes[conversation.entry_index].get_input_port("previous"))
	
	var idx: int = -1
	# Second loop to set jumps & connect nodes
	for conv_dict in conversation.conversation:
		idx += 1
		match conv_dict["_type"]:
			DiscourseGraphNode.GraphType.DIALOG:
				if conv_dict["next"] != -1:
					on_connection_request(
						nodes[idx].name,
						nodes[idx].get_output_port("next"),
						nodes[conv_dict["next"]].name,
						nodes[conv_dict["next"]].get_input_port("previous"))
			DiscourseGraphNode.GraphType.CHOICES:
				if conv_dict["choices"].is_empty():
					continue
				var choice_idx: int = 0
				for choice in conv_dict["choices"]:
					choice_idx += 1
					if choice["next"] != -1:
						on_connection_request(
							nodes[idx].name,
							nodes[idx].get_output_port(str(choice_idx)),
							nodes[choice["next"]].name,
							nodes[choice["next"]].get_input_port("previous"))
					if choice["condition"] != -1:
						on_connection_request(
							nodes[choice["condition"]].name,
							nodes[choice["condition"]].get_output_port("value"),
							nodes[idx].name,
							nodes[idx].get_input_port(str(choice_idx)))
			DiscourseGraphNode.GraphType.SIGNAL:
				if not conv_dict["arguments"].is_empty():
					var sign_arg: int = 0
					for arg in conv_dict["arguments"]:
						sign_arg += 1
						if arg["id"] != -1:
							on_connection_request(
									nodes[arg["id"]].name,
									nodes[arg["id"]].get_output_port("value"),
									nodes[idx].name,
									nodes[idx].get_input_port(str(sign_arg)))
			DiscourseGraphNode.GraphType.WAIT:
				if conv_dict["next"] != -1:
					on_connection_request(
						nodes[idx].name,
						nodes[idx].get_output_port("next"),
						nodes[conv_dict["next"]].name,
						nodes[conv_dict["next"]].get_input_port("previous"))
			DiscourseGraphNode.GraphType.PAUSE:
				if conv_dict["next"] != -1:
					on_connection_request(
						nodes[idx].name,
						nodes[idx].get_output_port("next"),
						nodes[conv_dict["next"]].name,
						nodes[conv_dict["next"]].get_input_port("previous"))
			DiscourseGraphNode.GraphType.CONDITIONAL_VALUE:
				if conv_dict["result"] != -1:
					on_connection_request(
						nodes[conv_dict["result"]].name,
						nodes[conv_dict["result"]].get_output_port("value"),
						nodes[idx].name,
						nodes[idx].get_input_port("value"))
				if conv_dict["true"] != -1:
					on_connection_request(
						nodes[conv_dict["true"]].name,
						nodes[conv_dict["true"]].get_output_port("variable"),
						nodes[idx].name,
						nodes[idx].get_input_port("true"))
				if conv_dict["false"] != -1:
					on_connection_request(
						nodes[conv_dict["false"]].name,
						nodes[conv_dict["false"]].get_output_port("variable"),
						nodes[idx].name,
						nodes[idx].get_input_port("false"))
			DiscourseGraphNode.GraphType.CONDITIONAL_DIALOG:
				if conv_dict["true"] != -1:
					on_connection_request(
						nodes[idx].name,
						nodes[idx].get_output_port("true"),
						nodes[conv_dict["true"]].name,
						nodes[conv_dict["true"]].get_input_port("previous"))
				if conv_dict["false"] != -1:
					on_connection_request(
						nodes[idx].name,
						nodes[idx].get_output_port("false"),
						nodes[conv_dict["false"]].name,
						nodes[conv_dict["false"]].get_input_port("previous"))
				if conv_dict["result"] != -1:
					on_connection_request(
						nodes[conv_dict["result"]].name,
						nodes[conv_dict["result"]].get_output_port("value"),
						nodes[idx].name,
						nodes[idx].get_input_port("value"))
			DiscourseGraphNode.GraphType.MATCH:
				if conv_dict["default"] != -1:
					on_connection_request(
						nodes[idx].name,
						nodes[idx].get_output_port("default"),
						nodes[conv_dict["default"]].name,
						nodes[conv_dict["default"]].get_input_port("previous"))
				if conv_dict["match"] != -1:
					on_connection_request(
						nodes[conv_dict["match"]].name,
						nodes[conv_dict["match"]].get_output_port("value"),
						nodes[idx].name,
						nodes[idx].get_input_port("value"))
				var case_idx: int = 0
				for case in conv_dict["cases"]:
					case_idx += 1
					if case["next"] == -1:
						continue
					on_connection_request(
						nodes[idx].name,
						nodes[idx].get_output_port(str(case_idx)),
						nodes[case["next"]].name,
						nodes[case["next"]].get_input_port("next"))
			DiscourseGraphNode.GraphType.MATH:
				if conv_dict["a"] != -1:
					on_connection_request(
						nodes[conv_dict["a"]].name,
						nodes[conv_dict["a"]].get_output_port("value"),
						nodes[idx].name,
						nodes[idx].get_input_port("a"))
				if conv_dict["b"] != -1:
					on_connection_request(
						nodes[conv_dict["b"]].name,
						nodes[conv_dict["b"]].get_output_port("value"),
						nodes[idx].name,
						nodes[idx].get_input_port("b"))
			DiscourseGraphNode.GraphType.EVAL:
				if conv_dict["a"] != -1:
					on_connection_request(
						nodes[conv_dict["a"]].name,
						nodes[conv_dict["a"]].get_output_port("value"),
						nodes[idx].name,
						nodes[idx].get_input_port("a"))
				if conv_dict["b"] != -1:
					on_connection_request(
						nodes[conv_dict["b"]].name,
						nodes[conv_dict["b"]].get_output_port("value"),
						nodes[idx].name,
						nodes[idx].get_input_port("b"))
			DiscourseGraphNode.GraphType.RANDOM:
				var rand_idx: int = 0
				for exit in conv_dict["exits"]:
					rand_idx += 1
					if exit["next"] == -1:
						continue
					on_connection_request(
						nodes[idx].name,
						nodes[idx].get_output_port(str(rand_idx)),
						nodes[exit["next"]].name,
						nodes[exit["next"]].get_input_port("previous"))
			DiscourseGraphNode.GraphType.VAR_SET:
				if not conv_dict["direct"] and conv_dict["value"] != -1:
					on_connection_request(
						nodes[conv_dict["value"]].name,
						nodes[conv_dict["value"]].get_output_port("value"),
						nodes[idx].name,
						nodes[idx].get_input_port("value"))
			DiscourseGraphNode.GraphType.JUMP:
				if conv_dict["jump_target"] != -1:
					nodes[idx].set_jump_idx(targets.find(nodes[conv_dict["jump_target"]]))
			DiscourseGraphNode.GraphType.JUMP_TARGET:
				if conv_dict["next"] != -1:
					on_connection_request(
						nodes[idx].name,
						nodes[idx].get_output_port("next"),
						nodes[conv_dict["next"]].name,
						nodes[conv_dict["next"]].get_input_port("previous"))
			DiscourseGraphNode.GraphType.EVENT:
				if conv_dict["next"] != -1:
					on_connection_request(
						nodes[idx].name,
						nodes[idx].get_output_port("next"),
						nodes[conv_dict["next"]].name,
						nodes[conv_dict["next"]].get_input_port("previous"))
				for sign_id in conv_dict["signals"]:
					on_connection_request(
						nodes[sign_id].name,
						nodes[sign_id].get_output_port("signal"),
						nodes[idx].name,
						nodes[idx].get_input_port("signal"))
				for var_id in conv_dict["variables"]:
					on_connection_request(
						nodes[var_id].name,
						nodes[var_id].get_output_port("variable"),
						nodes[idx].name,
						nodes[idx].get_input_port("variable"))
				for call_id in conv_dict["callables"]:
					on_connection_request(
						nodes[call_id].name,
						nodes[call_id].get_output_port("call"),
						nodes[idx].name,
						nodes[idx].get_input_port("call"))
			DiscourseGraphNode.GraphType.CALL:
				if conv_dict.has("call_args"):
					var call_id: int = 0
					for call_arg in conv_dict["call_args"]:
						call_id += 1
						if call_arg["id"] != -1:
							on_connection_request(
								nodes[call_arg["id"]].name,
								nodes[call_arg["id"]].get_output_port("value"),
								nodes[idx].name,
								nodes[idx].get_input_port(str(call_id)))
			DiscourseGraphNode.GraphType.RETURN_CALL:
				if conv_dict.has("call_args"):
					var call_id: int = 0
					for call_arg in conv_dict["call_args"]:
						call_id += 1
						if call_arg["id"] != -1:
							on_connection_request(
								nodes[call_arg["id"]].name,
								nodes[call_arg["id"]].get_output_port("value"),
								nodes[idx].name,
								nodes[idx].get_input_port(str(call_id)))


func fix_menu_position():
	# Get the PopupMenu's global position and size
	var popup_pos: Vector2i = to_empty_pp_mn.position
	var popup_size: Vector2i = to_empty_pp_mn.size

	# Get the viewport size
	var viewport_size: Vector2i = get_viewport().size

	# Calculate the bottom-right corner of the PopupMenu
	var popup_bottom_right: Vector2i = popup_pos + popup_size

	# Calculate the offset needed to keep the PopupMenu inside the viewport
	var offset := Vector2i.ZERO
	
	if popup_bottom_right.x > viewport_size.x:
		offset.x = viewport_size.x - popup_bottom_right.x
	if popup_bottom_right.y > viewport_size.y:
		offset.y = viewport_size.y - popup_bottom_right.y

	# Apply the offset to the PopupMenu's position
	to_empty_pp_mn.position += offset


func get_conversation_data() -> DialogResource:
	var nodes: Array[DiscourseGraphNode] = []
	var assigned_id: int = -1
	var entry_node: DiscourseGraphNode = null
	var conversation := DialogResource.new()
	
	for node in dialog_graph_edit.get_children():
		if node is DiscourseGraphNode:
			if node.graph_type == DiscourseGraphNode.GraphType.ENTRY:
				entry_node = node
				conversation.entry_offset = entry_node.position_offset
				continue
			nodes.append(node)
			assigned_id += 1
			node.node_id = assigned_id
	
	conversation.entry_index = entry_node.get_entry_id()
	
	for node in nodes:
		conversation.conversation.append(node._get_node_data())
	
	return conversation


func save_all() -> void:
	if is_current_unsaved():
		save_current()
	
	for res_dict in open_conversations:
		if res_dict["unsaved"]:
			ResourceSaver.save(res_dict["resource"], res_dict["path"])
			res_dict["unsaved"] = false


func save_current() -> void:
	if is_current_unsaved():
		ResourceSaver.save(
			get_conversation_data(),
			open_conversations[current_conv]["path"])
		set_current_unsaved(false)


func current_to_memory() -> void:
	open_conversations[current_conv]["resource"] = get_conversation_data()
	open_conversations[current_conv]["offset"] = dialog_graph_edit.scroll_offset
	open_conversations[current_conv]["zoom"] = dialog_graph_edit.zoom


func close_conversation(idx: int) -> void:
	open_conversations.remove_at(idx)
	conversations_tree.remove_conversation(idx)
	
	if current_conv == idx:
		clear_nodes()
		var nearest_conv: int = conversations_tree.get_nearest_conv_id(idx)
		if nearest_conv != -1:
			conversations_tree.select_no_signal(nearest_conv)
			load_conversation(open_conversations[nearest_conv]["resource"])
		else:
			no_conv_panel.visible = true
		current_conv = nearest_conv
		clear_targets()


func clear_targets() -> void:
	jump_target_tree.clear_targets()
	targets.clear()
	jumpers.clear()


func close_all_conversations() -> void:
	clear_nodes()
	clear_targets()
	open_conversations.clear()
	conversations_tree.clear_conversations()
	current_conv = -1
	no_conv_panel.visible = true


func on_close_issues_pressed() -> void:
	issues_panel.visible = false


func on_conv_selected(conv_id: int) -> void:
	if is_current_unsaved():
		current_to_memory()
	current_conv = conv_id
	clear_nodes()
	load_conversation(open_conversations[conv_id]["resource"])
	dialog_graph_edit.zoom = open_conversations[conv_id]["zoom"]
	dialog_graph_edit.scroll_offset = open_conversations[conv_id]["offset"]


func check_for_errors() -> void:
	var orphans: Array[DiscourseGraphNode] = []
	var unreachable_signals: Array[DiscourseGraphNode] = []
	var missing_data: Array[DiscourseGraphNode] = []
	
	issues_tree.clear_issues()
	
	for node in dialog_graph_edit.get_children():
		if node is DiscourseGraphNode:
			if node._is_orphan():
				orphans.append(node)
			
			if node.graph_type == DiscourseGraphNode.GraphType.CONDITIONAL_VALUE:
				if not node.has_any_input_connection("true") or not node.has_any_input_connection("false"):
					missing_data.append(node)
			elif node.graph_type == DiscourseGraphNode.GraphType.CONDITIONAL_DIALOG:
				if not node.has_any_input_connection("value"):
					missing_data.append(node)
			elif node.graph_type == DiscourseGraphNode.GraphType.EVAL:
				if not node.has_any_input_connection("a") or not node.has_any_input_connection("b"):
					missing_data.append(node)
			elif node.graph_type == DiscourseGraphNode.GraphType.MATH:
				if not node.has_any_input_connection("a") or not node.has_any_input_connection("b"):
					missing_data.append(node)
			elif node.graph_type == DiscourseGraphNode.GraphType.SIGNAL:
				pass # Check if all args are filled
			elif node.graph_type == DiscourseGraphNode.GraphType.CALL:
				pass # Check if all args are filled
			elif node.graph_type == DiscourseGraphNode.GraphType.RETURN_CALL:
				pass # Check if all args are filled
	
	for target in targets:
		var jumper_found: bool = false
		for jumper in jumpers:
			if jumper.jump_target == target:
				jumper_found = true
				break
		if not jumper_found:
			unreachable_signals.append(target)
	
	for orphan in orphans:
		issues_tree.log_issue("A node is unreachable", orphan)
	for un_sig in unreachable_signals:
		issues_tree.log_issue("A jump target was never used", un_sig)
	for mis_dat in missing_data:
		issues_tree.log_issue("A graph is missing required data.", mis_dat)
	
	issues_panel.visible = true


func is_current_unsaved() -> bool:
	if current_conv == -1:
		return false
	return open_conversations[current_conv]["unsaved"]


func set_current_unsaved(unsaved_status: bool) -> void:
	open_conversations[current_conv]["unsaved"] = unsaved_status


func has_unsaved_changes() -> bool:
	for open_conv in open_conversations:
		if open_conv["unsaved"]:
			return true
	return false
