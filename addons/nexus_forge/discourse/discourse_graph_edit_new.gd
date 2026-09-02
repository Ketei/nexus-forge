@tool
extends GraphEdit

# Emmited when a node is created.
signal node_created(node: DiscourseGraphNode)
# Emitted when nodes are created.
signal nodes_created(node_uuids: Array[StringName], action_name: String)
# When a change has happened. Used for applying unsaved status
signal dialog_changed
# When a node has been localized. Main window needs to update other elements
signal localization_enabled(node: DiscourseGraphNode)
# When a node is selected. Useful for highlithing the node in the menu tree.
signal discourse_node_selected(node_uuid: StringName)
# When nodes need to be duplicated
signal node_duplication_requested(nodes: Array[DiscourseGraphNode])
# When a node movement finished and the movement it made. If substracted from
# position offset, it would return to where it was initially
signal nodes_moved(state: Dictionary[String, Dictionary])
# When nodes are removed, along with the node data
signal nodes_removed(action: String, nodes_data: Dictionary)

# --- Forward Signals ---
signal node_resized(node_uuid: StringName, from: Vector2, to: Vector2)
signal comment_node_text_changed(uuid: StringName, old_comment: String, new_comment: String)
signal comparation_node_operator_changed(uuid: StringName, old_operator: int, new_operator: int)
signal dialog_node_character_id_changed(uuid: StringName, from: String, to: String)
signal dialog_node_text_changed(uuid: StringName, from: String, to: String)
signal dialog_node_presist_toggled(uuid: StringName, is_toggled: bool)
signal choice_node_text_changed(node_uuid: StringName, choice_idx: int, old_text: String, new_text: String)
signal choices_node_resized(node_uuid: StringName, old_snapshot: Dictionary, new_snapshot: Dictionary)
signal shortcut_node_target_changed(node_uuid: StringName, old_anchor: StringName, new_anchor: StringName)
signal shortcut_node_id_changed(node_uuid: String, old_id: String, new_id: String)
signal localized_node_text_changed(uuid: StringName, old_value: String, new_value: String)
signal match_node_cases_resized(uuid: StringName, old_snapshot: Dictionary, new_snapshot: Dictionary)
signal match_node_field_updated(uuid: StringName, field_id: int, from: Variant, to: Variant)
signal match_node_mode_changed(uuid: StringName, old_state: Dictionary, new_state: Dictionary)
signal metadata_node_key_changed(node_uuid: StringName, index: int, from: String, to: String)
signal call_node_method_changed(node_uuid: StringName, from_state: Dictionary, to_state: Dictionary)
signal call_return_method_changed(node_uuid: StringName, old_state: Dictionary, new_state: Dictionary)
signal random_node_count_state_changed(uuid: StringName, old_state: Dictionary, new_state: Dictionary)
signal random_val_node_mode_changed(uuid: StringName, old_state: Dictionary, new_state: Dictionary)
signal random_val_node_range_changed(uuid: StringName, from_min: float, from_max: float, to_min: float, to_max: float)
signal resource_node_path_changed(uuid: StringName, from: String, to: String)
signal signal_node_signal_changed(uuid: StringName, old_state: Dictionary, new_state: Dictionary)
signal guard_node_fallback_changed(uuid: StringName, from: Variant, to: Variant)
signal value_node_value_changed(uuid: StringName, from: Variant, to: Variant)
signal value_node_type_changed(uuid: StringName, old_state: Dictionary, new_state: Dictionary)
signal variable_node_type_changed(uuid: StringName, old_state: Dictionary, new_state: Dictionary)
signal variable_node_path_changed(uuid: StringName, from: String, to: String)

signal close_frame_requested(uuid: StringName)
signal frame_title_changed(uuid: StringName, from: String, to: String)
signal frame_color_changed(uuid: StringName, from: Color, to: Color)
# ----------------------------

# -- Connections ---
signal node_connected(from_node: StringName, from_port: int, to_node: StringName, to_port: int)
signal node_disconnected(from_node: StringName, from_port: int, to_node: StringName, to_port: int, from_state: Dictionary, to_state: Dictionary)
signal node_connection_switched(origin_ports: Dictionary, new_node: StringName, new_port: int, original_from_state: Dictionary, original_to_state: Dictionary, new_from_state: Dictionary, new_to_state: Dictionary)
# --- Actions ---
signal use_code_editor_requested(target_control: TextEdit)
signal browse_character_requested(node_uuid: StringName, target_control: LineEdit)

# --- Mutations (UndoRedo) ---


# --- Move to parent control ---
signal paste_nodes_requested


# Enum to differentiate dialog nodes
const DialogNodes = NFDialogParser.NodeTypes
# Enum to differentiate connection types
const ConnectionType = DiscourseGraphNode.SlotConnectionType
# Enum to differentiate port directions
const PortFlow = DiscourseGraphNode.PortMode

# Dictionary with data about compatible nodes. Could be a const
var compatible_connections: Dictionary = {
	ConnectionType.DIALOG: {
		"output": Array([
			{
				"name": "Dialog",
				"type": DialogNodes.DIALOG,
				"ports": [{"port": 0}]},
			{
				"name": "Choices",
				"type": DialogNodes.CHOICES,
				"ports": [{"port": 0}]},
			{
				"name": "Event",
				"type": DialogNodes.EVENT,
				"ports": [{"port": 0}]},
			{
				"name": "Random",
				"type": DialogNodes.RANDOM,
				"ports": [{"port": 0}]},
			{
				"name": "Match",
				"type": DialogNodes.MATCH,
				"ports": [{"port": 0}]},
			{
				"name": "Branch",
				"type": DialogNodes.BRANCH,
				"ports": [{"port": 0}]},
			{
				"name": "Anchor Pointer",
				"type": DialogNodes.SHORTCUT,
				"ports": [{"port": 0}]},
			{
				"name": "Dialog Merge",
				"type": DialogNodes.DIALOG_MERGE,
				"ports": [{"port": 0}]},
			{
				"name": "Pause",
				"type": DialogNodes.PAUSE,
				"ports": [{"port": 0}]},
			{
				"name": "Dialog End",
				"type": DialogNodes.DIALOG_END,
				"ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null),
		"input": Array([
			{
				"name": "Dialog",
				"type": DialogNodes.DIALOG,
				"ports": [{"port": 0}]},
			{
				"name": "Choices",
				"type": DialogNodes.CHOICES,
				"ports": [{"port": 0}]},
			{
				"name": "Event",
				"type": DialogNodes.EVENT,
				"ports": [{"port": 0}]},
			{
				"name": "Random",
				"type": DialogNodes.RANDOM,
				"ports": [{"port": 0}]},
			{
				"name": "Match",
				"type": DialogNodes.MATCH,
				"ports": [
					{"port": 0, "name": "Default"},
					{"port": 1, "name": "Case 1"}]},
			{
				"name": "Branch",
				"type": DialogNodes.BRANCH,
				"ports": [
					{"port": 0, "name": "True Branch"},
					{"port": 1, "name": "False Branch"}]},
			{
				"name": "Anchor",
				"type": DialogNodes.SHORTCUT_TARGET,
				"ports": [{"port": 0}]},
			{
				"name": "Dialog Merge",
				"type": DialogNodes.DIALOG_MERGE,
				"ports": [{"port": 0}]},
			{
				"name": "Pause",
				"type": DialogNodes.PAUSE,
				"ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)},
	ConnectionType.METADATA: {
		"input": Array([
			{
				"name": "Metadata",
				"type": DialogNodes.METADATA,
				"ports": [{"port": 0}]}
		], TYPE_DICTIONARY, &"", null)},
	ConnectionType.VAR_STRING: {
		"input": Array([
			{
				"name": "Value",
				"type": DialogNodes.VALUE,
				"ports": [{"port": 0,"data": {"value": ""}}]},
			{
				"name": "Localized Text",
				"type": DialogNodes.LOCALIZED_TEXT,
				"ports": [{"port": 0}]},
			{
				"name": "Type Guard",
				"type": DialogNodes.TYPE_GUARD,
				"ports": [{"port": 0}]},
			{
				"name": "Variable",
				"type": DialogNodes.VARIABLE_GET,
				"ports": [{"port": 0, "data": {"variable_type": TYPE_STRING}}]}], TYPE_DICTIONARY, &"", null)},
	ConnectionType.VAR_INT: {
		"input": Array([
			{
				"name": "Value",
				"type": DialogNodes.VALUE,
				"ports": [{"port": 0, "data": {"value": 0}}]},
			{
				"name": "Random",
				"type": DialogNodes.RANDOM_VALUE,
				"ports": [{"port": 0, "data": {"mode": TYPE_INT}}]},
			{
				"name": "Type Guard",
				"type": DialogNodes.TYPE_GUARD,
				"ports": [{"port": 0}]},
			{
				"name": "Variable",
				"type": DialogNodes.VARIABLE_GET,
				"ports": [{"port": 0, "data": {"variable_type": TYPE_INT}}]}], TYPE_DICTIONARY, &"", null)},
	ConnectionType.VAR_BOOL: {
		"input": Array([
			{
				"name": "Value",
				"type": DialogNodes.VALUE,
				"ports": [{"port": 0, "data": {"value": false}}]},
			{
				"name": "Random",
				"type": DialogNodes.RANDOM_VALUE,
				"ports": [{
					"port": 0,
					"data": {
						"mode": TYPE_BOOL,
						"values": {"base": 50.0, "max": 50.0}}}]},
			{
				"name": "Type Guard",
				"type": DialogNodes.TYPE_GUARD,
				"ports": [{"port": 0}]},
			{
				"name": "Variable",
				"type": DialogNodes.VARIABLE_GET,
				"ports": [{"port": 0, "data": {"variable_type": TYPE_BOOL}}]},
			{
				"name": "Comparation",
				"type": DialogNodes.COMPARATION,
				"ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)},
	ConnectionType.SIGNAL: {
		"input": Array([{
			"name": "Signal",
			"type": DialogNodes.SIGNAL,
			"ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)},
	ConnectionType.CALL: {
		"input": Array([{
			"name": "Signal",
			"type": DialogNodes.CALLABLE,
			"ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)},
		
	ConnectionType.SETTINGS_CHARACTER: {
		"input": Array([{
			"name": "Settings",
			"type": DialogNodes.SETTINGS_CHARACTER,
			"ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)},
	ConnectionType.SETTINGS_DIALOG: {
		"input": Array([{
			"name": "Settings",
			"type": DialogNodes.SETTINGS_DIALOG,
			"ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)},
	ConnectionType.SETTINGS_OPTION: {
		"input": Array([{
			"name": "Settings",
			"type": DialogNodes.SETTINGS_OPTION,
			"ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)},
	ConnectionType.RESOURCE: {
		"input": Array([{
			"name": "",
			"type": DialogNodes.RESOURCE,
			"ports": [{"port": 0}]}], TYPE_DICTIONARY, &"", null)},
	ConnectionType.VAR_ANY: {
		"input": Array([{
			"name": "Value",
			"type": DialogNodes.VALUE, "ports": [
				{"name": "Integer", "port": 0, "data": {"value": 0}},
				{"name": "Float", "port": 0, "data": {"value": 0.0}},
				{"name": "Bool", "port": 0, "data": {"value": false}},
				{"name": "String", "port": 0, "data": {"value": ""}}]},
			{
				"name": "Random Value",
				"type": DialogNodes.RANDOM_VALUE,
				"ports": [{"port": 0}]},
			{
				"name": "Localized Text",
				"type": DialogNodes.LOCALIZED_TEXT,
				"ports": [{"port": 0}]},
			{
				"name": "Type Guard",
				"type": DialogNodes.TYPE_GUARD,
				"ports": [{"port": 0}]},
			{
				"name": "Variable",
				"type": DialogNodes.VARIABLE_GET,
				"ports": [{"port": 0}]},
			{
				"name": "Comparation",
				"type": DialogNodes.COMPARATION,
				"ports": [{"port": 0}]},
			{
				"name": "Conditional Value",
				"type": DialogNodes.CONDITION_SELECT,
				"ports": [{"port": 0}]
			}
		], TYPE_DICTIONARY, &"", null)
	}
}

# Tween to move the graph edit when focusing a node. Slides instead of a jump
var focus_tween: Tween = null
# Clipboard data
var node_clipboard: Array[Dictionary] = []
# Entry node. Useful to keep track of since it's the only "constant" node.
var entry_node: DiscourseGraphNode = null
# Popup that shows when connects to empty. Useful for connection flow
var connection_popup: PopupMenu = null
# All anchor pointers. We keep track of them because we need to update all of them
# when an anchor is updated. Much better than iterating through the entire node
# collection.
var anchor_pointers: Array[DiscourseGraphNode] = []
var anchor_targets: Array[DiscourseGraphNode] = []
# All of the spawned graph nodes. More straightforward since get_children also
# returns the connection nodes
var graph_nodes: Dictionary[StringName, DiscourseGraphNode] = {}
var node_frames: Dictionary[StringName, GraphFrame] = {}
# Tracking all method callers and signalers since we need to update them everytime
# the API script is saved. Better than iterating through all the collection.
var method_callers: Array[DiscourseGraphNode] = []
var signalers: Array[DiscourseGraphNode] = []

# Data for the mouse release.
var release_data: Dictionary = {}
var movement_data: Dictionary[String, Dictionary] = {
	"nodes": DictUtils.create_typed(TYPE_STRING_NAME, TYPE_DICTIONARY),
	"frames": DictUtils.create_typed(TYPE_STRING_NAME, TYPE_DICTIONARY)}
# {
	#"reference": null,
	#"nodes": [],
	#"starting_position": Vector2.ZERO,
	#"ending_position": Vector2.ZERO
	#}

enum ConnectionChangeType{
	SWITCH_DISCONNECT,
	NEW_CONNECTION,
}
var _pending_connection_change: Dictionary = {}



func _ready() -> void:
	compatible_connections.make_read_only()
	
	connection_popup = PopupMenu.new()
	connection_popup.name = &"ConnectionsPopupMenu"
	connection_popup.visible = false
	add_child(connection_popup)
	
	panning_scheme = GraphEdit.SCROLL_PANS
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
	
	entry_node = spawn_node(DialogNodes.ENTRY)
	
	begin_node_move.connect(_on_begin_node_move)
	end_node_move.connect(_on_end_node_move, CONNECT_DEFERRED)
	node_selected.connect(_on_node_selected)
	graph_elements_linked_to_frame_request.connect(_on_graph_elements_linked_to_frame_request)
	copy_nodes_request.connect(_on_copy_nodes_requested)
	cut_nodes_request.connect(_on_cut_nodes_requested)
	paste_nodes_request.connect(_on_paste_nodes_requested)
	duplicate_nodes_request.connect(_on_graph_edit_keyboard_duplicate_pressed)
	delete_nodes_request.connect(_on_delete_nodes_request)
	
	connection_request.connect(_on_connection_request, CONNECT_DEFERRED)
	connection_popup.index_pressed.connect(_on_popup_index_pressed.bind(connection_popup))
	connection_drag_started.connect(_on_connection_drag_started, CONNECT_DEFERRED)
	
	connection_to_empty.connect(_on_connection_to_empty, CONNECT_DEFERRED)
	connection_from_empty.connect(_on_connection_from_empty, CONNECT_DEFERRED)
	connection_drag_ended.connect(_on_connection_drag_ended, CONNECT_DEFERRED)


## Creates a dialog node ready to be added. Connected to all relevant signals
func new_dialog_node(node_type: DialogNodes, uuid: StringName = &"") -> DiscourseGraphNode:
	var created_node: DiscourseGraphNode = null
	
	match node_type:
		DialogNodes.ENTRY:
			if entry_node == null:
				created_node = preload("res://addons/nexus_forge/discourse/nodes/dialog_entry.gd").new(uuid, &"", false, false, false)
			else:
				if not uuid.is_empty():
					entry_node._uuid = uuid
				return entry_node
		DialogNodes.DIALOG:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/dialog_graph_node.gd").new(uuid, &"", true, true, true)
			created_node.use_code_editor_pressed.connect(_on_use_code_editor_requested)
			created_node.select_character_pressed.connect(_on_use_character_selector_pressed)
			created_node.character_id_changed.connect(dialog_node_character_id_changed.emit)
			created_node.dialog_text_changed.connect(dialog_node_text_changed.emit)
			created_node.dialog_presist_toggled.connect(dialog_node_presist_toggled.emit)
		DialogNodes.CHOICES:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/dialog_options.gd").new(uuid, &"", true, true, true)
			created_node.use_code_editor_pressed.connect(_on_use_code_editor_requested)
			created_node.choices_resized.connect(choices_node_resized.emit)
			created_node.choice_text_changed.connect(choice_node_text_changed.emit)
		DialogNodes.BRANCH:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/dialog_branch.gd").new(uuid)
		DialogNodes.CONDITION_SELECT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/conditional_select.gd").new(uuid, &"TypeData")
		DialogNodes.COMPARATION:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/comparation_node.gd").new(uuid, &"TypeData")
			created_node.operator_changed.connect(comparation_node_operator_changed.emit)
		DialogNodes.EVENT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/event_node.gd").new(uuid)
		DialogNodes.MATCH:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/match_node.gd").new(uuid)
			created_node.match_node_resized.connect(match_node_cases_resized.emit)
			created_node.match_field_updated.connect(match_node_field_updated.emit)
			created_node.match_mode_changed.connect(match_node_mode_changed.emit)
		DialogNodes.PAUSE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/pause_node.gd").new(uuid)
		DialogNodes.RANDOM:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/random_select.gd").new(uuid)
			created_node.choice_count_state_changed.connect(random_node_count_state_changed.emit)
		DialogNodes.TYPE_GUARD:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/type_guard.gd").new(uuid, &"TypeData")
			created_node.fallback_changed.connect(guard_node_fallback_changed.emit)
		DialogNodes.VALUE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/value_node.gd").new(uuid, &"TypeData")
			created_node.value_changed.connect(value_node_value_changed.emit)
			created_node.data_type_changed.connect(value_node_type_changed.emit)
		DialogNodes.SIGNAL:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/signal_node.gd").new(uuid, &"TypeData")
			created_node.signal_changed.connect(signal_node_signal_changed.emit)
			signalers.append(created_node)
		DialogNodes.CALLABLE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/method_call_node.gd").new(uuid, &"TypeData")
			created_node.method_changed.connect(call_node_method_changed.emit)
			method_callers.append(created_node)
		DialogNodes.CALLABLE_RETURN:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/method_call_return.gd").new(uuid, &"TypeData")
			created_node.method_changed.connect(call_return_method_changed.emit)
			method_callers.append(created_node)
		DialogNodes.VARIABLE_GET:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/var_getter.gd").new(uuid, &"TypeData")
			created_node.type_changed.connect(variable_node_type_changed.emit)
			created_node.path_changed.connect(variable_node_path_changed.emit)
		DialogNodes.SHORTCUT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/jump_to_node.gd").new(uuid)
			anchor_pointers.append(created_node)
			created_node.go_to_anchor_pressed.connect(_on_go_to_node_pressed, CONNECT_DEFERRED)
			created_node.selected_shortcut_changed.connect(shortcut_node_target_changed.emit)
			for anchor in anchor_targets:
				created_node.add_anchor(anchor.get_node_uuid(), anchor.current_id)
		DialogNodes.SHORTCUT_TARGET:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/jump_target_node.gd").new(uuid)
			var valid_id: String = get_valid_shortcut_id("shortcut", created_node)
			created_node.set_anchor_id(valid_id)
			created_node.id_changed.connect(_on_anchor_id_changed.bind(created_node), CONNECT_DEFERRED)
			anchor_targets.append(created_node)
			for anchor in anchor_pointers:
				anchor.add_anchor(created_node.get_node_uuid(), valid_id)
		DialogNodes.DIALOG_END:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/end_node.gd").new(uuid)
		DialogNodes.DIALOG_MERGE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/dialog_joiner.gd").new(uuid)
		DialogNodes.COMMENT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/comment_node.gd").new(uuid, &"TypeMisc")
			created_node.comment_changed.connect(comment_node_text_changed.emit)
		DialogNodes.SETTINGS_CHARACTER:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/char_settings_node.gd").new(uuid, &"TypeSettings")
		DialogNodes.SETTINGS_DIALOG:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/settings_dialog.gd").new(uuid, &"TypeSettings")
		DialogNodes.SETTINGS_OPTION:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/settings_option.gd").new(uuid, &"TypeSettings")
		DialogNodes.RANDOM_VALUE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/random_value.gd").new(uuid, &"TypeData")
			created_node.mode_changed.connect(random_val_node_mode_changed.emit)
			created_node.range_changed.connect(random_val_node_range_changed.emit)
		DialogNodes.RESOURCE:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/resource_loader_graph.gd").new(uuid, &"TypeObject")
			created_node.resource_path_changed.connect(resource_node_path_changed.emit)
		DialogNodes.DATA_EVENT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/data_event.gd").new(uuid, &"TypeData")
		DialogNodes.LOCALIZED_TEXT:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/localized_text.gd").new(uuid)
			created_node.text_changed.connect(localized_node_text_changed.emit)
		DialogNodes.METADATA:
			created_node = preload("res://addons/nexus_forge/discourse/nodes/metadata_node.gd").new(uuid, &"TypeData")
			created_node.metadata_id_changed.connect(metadata_node_key_changed.emit)
	
	created_node.node_updated.connect(dialog_changed.emit, CONNECT_DEFERRED)
	created_node.disconnect_requested.connect(_on_disconnection_request, CONNECT_DEFERRED)
	created_node.close_requested.connect(_close_requested, CONNECT_DEFERRED)
	created_node.duplicate_requested.connect(_on_duplicate_node_button_pressed, CONNECT_DEFERRED)
	created_node.localize_node_toggled.connect(_on_localize_node_toggled, CONNECT_DEFERRED)
	if created_node.resizable:
		created_node.node_resized.connect(node_resized.emit)
	
	created_node.set_node_id(get_unique_node_name(created_node.get_node_id()))
	
	return created_node


func new_node_frame(uuid: StringName = &"") -> GraphFrame:
	var new_frame: GraphFrame = preload("res://addons/nexus_forge/discourse/nodes/dialog_graph_frame.gd").new(uuid)
	new_frame.close_frame_requested.connect(close_frame_requested.emit)
	new_frame.frame_title_changed.connect(frame_title_changed.emit)
	new_frame.frame_color_changed.connect(frame_color_changed.emit)
	return new_frame


func get_unique_node_name(desired: StringName, skip_uuid: StringName = &"") -> StringName:
	var names: Dictionary[StringName, Variant] = {}
	
	for node in graph_nodes.values():
		if node.get_node_uuid() == skip_uuid:
			continue
		names[node.get_node_id()] = null
		
	var desired_string: String = String(desired).strip_edges()
	var desired_stringname: StringName = StringName(desired_string)
	
	if not names.has(desired_stringname):
		return StringName(desired_stringname)
	
	var trailing_data: Dictionary = StringUtils.get_trailing_integer(desired_string)
	var iteration: int = trailing_data["integer"]
	var base: String = desired_string
	if trailing_data["has_integer"]:
		base = base.trim_suffix(str(iteration))
	
	var edited: StringName = desired_stringname
	while names.has(edited):
		iteration += 1
		edited = StringName(base + str(iteration))
	return edited


#region Spawners / Removers

func spawn_node(node_type: DialogNodes, uuid: StringName = &"", data: Dictionary = {}) -> DiscourseGraphNode:
	var new_node: DiscourseGraphNode = new_dialog_node(node_type, uuid)
	if not data.is_empty():
		var overwrite_data: Dictionary = new_node._get_node_data()
		overwrite_data.merge(data, true)
		new_node._set_node_data(overwrite_data)
	
	add_child(new_node)
	graph_nodes[new_node.get_node_uuid()] = new_node
	return new_node


func spawn_frame(uuid: StringName = &"", frame_position: Vector2 = Vector2.ZERO) -> GraphFrame:
	var new_frame: GraphFrame = new_node_frame(uuid)
	add_child(new_frame)
	node_frames[new_frame.get_frame_uuid()] = new_frame
	new_frame.position_offset = frame_position
	return new_frame

# ----------------------


func paste_node_clipboard(clipboard: Array[Dictionary], uuid_map: Dictionary[StringName, StringName]) -> void:
	if clipboard.is_empty():
		return
	
	var created_nodes: Array[StringName] = []
	var new_connections: Array[Dictionary] = [] 
	var uuid_equivalences: Dictionary[StringName, DiscourseGraphNode] = {}
	
	var current_offset: Vector2 = clipboard[0]["state"]["data"]["metadata"]["position"]
	var center_scroll_offset: Vector2 = get_center_offset()
	for clipboard_data in clipboard:
		if not uuid_map.has(clipboard_data["node_uuid"]):
			continue
		
		var node_data: Dictionary = clipboard_data["state"]["data"]
		var node_meta: Dictionary = node_data["metadata"]
		var new_name: StringName = get_unique_node_name(node_data["name"])
		var new_data: Dictionary = node_data.duplicate(true)
		new_data["name"] = new_name
		
		var pasted_node: DiscourseGraphNode = spawn_node(
				new_data["type"],
				uuid_map[clipboard_data["node_uuid"]],
				new_data)
		pasted_node.position_offset = get_center_offset() - (pasted_node.size / 2.0) + (pasted_node.position_offset - current_offset)
		
		uuid_equivalences[clipboard_data["node_uuid"]] = pasted_node
	
		var _new_connections: Array[Dictionary] = get_connection_dictionary(
				clipboard_data["node_uuid"],
				new_data)
		
		if not _new_connections.is_empty():
			new_connections.append_array(_new_connections)
		
		node_created.emit(pasted_node)
		created_nodes.append(pasted_node.get_node_uuid())
	
	for output_connection in new_connections:
		if not uuid_equivalences.has(output_connection["from"]) or not uuid_equivalences.has(output_connection["to"]):
			continue
		connect_discourse_nodes(
				uuid_equivalences[output_connection["from"]].get_node_uuid(),
				output_connection["from_port"],
				uuid_equivalences[output_connection["to"]].get_node_uuid(),
				output_connection["to_port"])
	
	if not created_nodes.is_empty():
		nodes_created.emit(created_nodes, "Paste Nodes")


func _on_duplicate_node_button_pressed(node: DiscourseGraphNode) -> void:
	var node_array: Array[StringName] = [node.get_node_uuid()]
	node_duplication_requested.emit(node_array)


func _on_graph_edit_keyboard_duplicate_pressed() -> void:
	var uid_array: Array[StringName] = []
	for node in get_selected_graph_nodes():
		uid_array.append(node.get_node_uuid())
	node_duplication_requested.emit(uid_array)


func duplicate_single(node_uuid: StringName, new_uuid: StringName) -> void:
	if not graph_nodes.has(node_uuid):
		return
	
	var node: DiscourseGraphNode = graph_nodes[node_uuid]
	var data: Dictionary = node._get_node_data()
	var new_name: StringName = get_unique_node_name(node.get_node_id())
	data["name"] = new_name
	DictUtils.set_nested_value(
			data,
			["metadata", "position"],
			node.position_offset + Vector2(100.0, 100.0))
	
	var new_node: DiscourseGraphNode = spawn_node(
			node.node_type,
			new_uuid,
			data)
	
	var frame: GraphFrame = get_element_frame(node.name)
	
	if new_node.node_type == DialogNodes.SHORTCUT_TARGET:
		var cloned_id: String = new_node.get_anchor_id()
		var new_id: String = get_valid_shortcut_id(cloned_id, new_node)
		
		new_node.set_anchor_id(new_id)
		
		for existing_anchor in anchor_pointers:
			existing_anchor.add_anchor(new_uuid, new_id)
	
	if frame != null:
		attach_graph_element_to_frame(new_node.name, frame.name)
	
	var str_arr: Array[StringName] = [new_node.get_node_uuid()]
	node_created.emit(new_node)
	nodes_created.emit(str_arr, "Duplicate Node")


# Used for the Ctrl+D signal with undo-redo. Key = node to be duplicated
# value = new UUID to be assigned to it.
func duplicate_multiple(duplicate_targets: Dictionary[StringName, StringName]) -> void:
	var nodes_to_duplicate: Array[Dictionary] = []
	
	for uuid in duplicate_targets.keys():
		if graph_nodes.has(uuid):
			nodes_to_duplicate.append({
				"node": graph_nodes[uuid],
				"new_uuid": duplicate_targets[uuid]})
	
	if nodes_to_duplicate.is_empty():
		return
	
	var new_connections: Array[Dictionary] = []
	var created_nodes: Array[StringName] = []
	var uuid_equivalences: Dictionary[String, DiscourseGraphNode] = {}
	
	for node_data in nodes_to_duplicate:
		var node: DiscourseGraphNode = node_data["node"]
		var new_name: StringName = get_unique_node_name(node.get_node_id())
		var old_data: Dictionary = node._get_node_data()
		old_data["name"] = new_name
		DictUtils.set_nested_value(
				old_data,
				["metadata", "position"],
				node.position_offset + Vector2(100.0, 100.0))
		var new_node: DiscourseGraphNode = spawn_node(
				node.node_type,
				node_data["new_uuid"],
				old_data)
		
		var frame: GraphFrame = get_element_frame(node.name)
		uuid_equivalences[node.get_node_uuid()] = new_node
		
		var node_connections: Array[Dictionary] = get_connection_dictionary(
				node.get_node_uuid(),
				old_data)
		if not node_connections.is_empty():
			new_connections.append_array(node_connections)
		
		new_node.selected = true
		node.selected = false
		if frame != null:
			attach_graph_element_to_frame(new_node.name, frame.name)
		node_created.emit(new_node)
		created_nodes.append(new_node.get_node_uuid())
	
	for output_connection in new_connections:
		if not uuid_equivalences.has(output_connection["from"]) or not uuid_equivalences.has(output_connection["to"]):
			continue
		connect_discourse_nodes(
				uuid_equivalences[output_connection["from"]].get_node_uuid(),
				output_connection["from_port"],
				uuid_equivalences[output_connection["to"]].get_node_uuid(),
				output_connection["to_port"])
	
	if not created_nodes.is_empty():
		nodes_created.emit(created_nodes, "Duplicate Nodes")


func remove_node(node_uuid: StringName) -> void:
	if not graph_nodes.has(node_uuid):
		return
	
	var target: DiscourseGraphNode = graph_nodes[node_uuid]
	
	disconnect_all_node_connections(node_uuid)
	
	match target.node_type:
		DialogNodes.CALLABLE, DialogNodes.CALLABLE_RETURN:
			method_callers.erase(target)
		DialogNodes.SHORTCUT_TARGET:
			for pointer in anchor_pointers:
				pointer.remove_anchor(node_uuid)
			anchor_targets.erase(target)
		DialogNodes.SHORTCUT:
			anchor_pointers.erase(target)
		DialogNodes.DIALOG:
			target.use_code_editor_pressed.disconnect(_on_use_code_editor_requested)
		DialogNodes.CHOICES:
			target.use_code_editor_pressed.disconnect(_on_use_code_editor_requested)
	
	graph_nodes.erase(node_uuid)
	target.queue_free()


func get_valid_shortcut_id(desired_id: String, skip: DiscourseGraphNode = null) -> String:
	var modified: String = desired_id
	var existing_ids: Array[StringName] = []
	
	for item in anchor_targets:
		if item == skip:
			continue
		existing_ids.append(item.current_id)
	
	var iteration: int = 0
	
	while existing_ids.has(modified):
		iteration += 1
		modified = modified + str(iteration)
	
	return modified


func remove_nodes(node_uuids: Array[StringName]) -> void:
	if node_uuids.is_empty():
		return
	
	var status_data: Dictionary[StringName, Variant] = {}
	
	for node in node_uuids:
		if not graph_nodes.has(node):
			continue
		status_data[node] = null
	
	var removed_targets: Array[StringName] = []
	
	for node_uuid in status_data.keys():
		var target: DiscourseGraphNode = graph_nodes[node_uuid]
	
		disconnect_all_node_connections(node_uuid)
		
		match target.node_type:
			DialogNodes.CALLABLE, DialogNodes.CALLABLE_RETURN:
				method_callers.erase(target)
			DialogNodes.SHORTCUT_TARGET:
				removed_targets.append(node_uuid)
				anchor_targets.erase(target)
			DialogNodes.SHORTCUT:
				anchor_pointers.erase(target)
			DialogNodes.DIALOG:
				target.use_code_editor_pressed.disconnect(_on_use_code_editor_requested)
			DialogNodes.CHOICES:
				target.use_code_editor_pressed.disconnect(_on_use_code_editor_requested)
		
		graph_nodes.erase(node_uuid)
		target.queue_free()
	
	if not removed_targets.is_empty():
		for pointer in anchor_pointers:
			for uuid in removed_targets:
				pointer.remove_anchor(uuid)


func remove_frame(frame_uuid: StringName) -> void:
	if not node_frames.has(frame_uuid):
		return
	var frame: GraphFrame = node_frames[frame_uuid]
	for attatched_node in get_attached_nodes_of_frame(frame.name):
		detach_graph_element_from_frame(attatched_node)
	
	node_frames.erase(frame_uuid)
	frame.queue_free()


func clear_dialog_nodes(recreate_entry: bool = true) -> void:
	clear_connections()
	for node:DiscourseGraphNode in graph_nodes.values():
		remove_child(node)
		node.queue_free()
	for frame in node_frames.values():
		remove_child(frame)
		frame.queue_free()
	graph_nodes.clear()
	node_frames.clear()
	anchor_pointers.clear()
	anchor_targets.clear()
	method_callers.clear()
	signalers.clear()
	entry_node = null
	if recreate_entry:
		entry_node = spawn_node(DialogNodes.ENTRY, &"", {"name": &"Entry"})
		var arr: Array[StringName] = [entry_node.get_node_uuid()]
		node_created.emit(entry_node)

#endregion

#region Selectors

func get_selected_graph_nodes(include_start: bool = false) -> Array[DiscourseGraphNode]:
	var selected_nodes: Array[DiscourseGraphNode] = []
	for node:DiscourseGraphNode in graph_nodes.values():
		if not node.selected:
			continue
		
		if node.node_type == DialogNodes.ENTRY and not include_start:
			continue
		
		selected_nodes.append(node)
	return selected_nodes


func get_selected_graph_elements(include_start: bool = false) -> Array[GraphElement]:
	var selected_nodes: Array[GraphElement] = []
	
	for node:DiscourseGraphNode in graph_nodes.values():
		if not node.selected:
			continue
		
		if node.node_type == DialogNodes.ENTRY and not include_start:
			continue
		
		selected_nodes.append(node)
	
	for frame:GraphFrame in node_frames.values():
		if frame.selected:
			selected_nodes.append(frame)
	
	return selected_nodes

#endregion

#region Getters

func get_compatible_node_overwrite_data(connection_type: ConnectionType, node_side: String, node_type: DialogNodes, item_index: int) -> Dictionary:
	if compatible_connections.has(connection_type):
		for type:Dictionary in compatible_connections[connection_type][node_side]:
			if type["type"] == node_type:
				if type["ports"][item_index].has("data"):
					return type["ports"][item_index]["data"]
				else:
					return {}
	return {}


func get_conversation_file(current_locale: String = "") -> EditorDiscourseDialog:
	var convo: EditorDiscourseDialog = EditorDiscourseDialog.new()
	
	for frame_uuid in node_frames:
		var frame: GraphFrame = node_frames[frame_uuid]
		convo.register_frame(
				frame_uuid,
				frame.title,
				frame.position_offset,
				frame.size,
				frame.tint_color)
	
	for node_uuid in graph_nodes.keys():
		var node: DiscourseGraphNode = graph_nodes[node_uuid]
		var node_data: Dictionary = node._get_node_data()
		node_data["metadata"]["localized"] = node.is_node_localized()
		var frame: GraphFrame = get_element_frame(node.name)
		var frame_uuid: String = "" if frame == null else frame.get_frame_uuid()
		
		convo.register_node(node, frame_uuid)
		
		if node.node_type == DialogNodes.DIALOG:
			convo.set_dialog_text(
					node_uuid,
					node.get_dialog_text(),
					current_locale)
		elif node.node_type == DialogNodes.CHOICES:
			convo.set_choices_array(
					node_uuid,
					node.get_options(),
					current_locale)
		elif node.node_type == DialogNodes.LOCALIZED_TEXT:
			convo.set_dialog_text(
					node_uuid,
					node.get_text(),
					current_locale)
	
	return convo


func update_conversation_file(on_file: EditorDiscourseDialog, current_locale: String = "") -> void:
	if on_file == null:
		return
	
	for frame_uuid in node_frames.keys():
		var frame: GraphFrame = node_frames[frame_uuid]
		on_file.register_frame(
				frame_uuid,
				frame.title,
				frame.position_offset,
				frame.size,
				frame.tint_color)
	
	for node_uuid in graph_nodes.keys():
		var node: DiscourseGraphNode = graph_nodes[node_uuid]
		var node_data: Dictionary = node._get_node_data()
		var frame: GraphFrame = get_element_frame(node.name)
		var frame_uuid: String = "" if frame == null else frame.get_frame_uuid()
		
		on_file.register_node(node, frame_uuid)
		
		if node.node_type == DialogNodes.DIALOG:
			on_file.set_dialog_text(
					node_uuid,
					node.get_dialog_text(),
					current_locale if node.is_node_localized() else "")
		elif node.node_type == DialogNodes.CHOICES:
			on_file.set_choices_array(
					node_uuid,
					node.get_options(),
					current_locale if node.is_node_localized() else "")
		elif node.node_type == DialogNodes.LOCALIZED_TEXT:
			on_file.set_dialog_text(
					node_uuid,
					node.get_text(),
					current_locale)


## Returns the offset vector value specific to the center based on zoom value.
func get_center_offset() -> Vector2:
	return Vector2((scroll_offset / zoom) + ((size / 2.0) / zoom))


func get_discourse_node(node_uuid: StringName) -> DiscourseGraphNode:
	return graph_nodes.get(node_uuid, null)


func get_discourse_frame(frame_uuid: StringName) -> GraphFrame:
	return node_frames.get(frame_uuid, null)


func has_discourse_node(node_uuid: StringName) -> bool:
	return graph_nodes.has(node_uuid)


func has_discourse_frame(frame_uuid: StringName) -> bool:
	return node_frames.has(frame_uuid)


func get_connection_dictionary(node_uuid: StringName, node_data: Dictionary) -> Array[Dictionary]:
	var node_connections: Array[Dictionary] = []
	var meta = node_data["metadata"]
	
	match node_data["type"] as DialogNodes:
		DialogNodes.CHOICES:
			for option in meta["choices"]:
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
			for match_value in meta["cases"]:
				if match_value["output_connections"]["next_node"]["target_node_uuid"].is_empty():
					continue
				node_connections.append({
					"from": node_uuid,
					"to": match_value["output_connections"]["next_node"]["target_node_uuid"],
					"from_port": match_value["output_connections"]["next_node"]["from_port"],
					"to_port": match_value["output_connections"]["next_node"]["target_port"]})
		DialogNodes.RANDOM:
			for option in meta["options"]:
				if option["output_connections"]["next_node"]["target_node_uuid"].is_empty():
					continue
				
				node_connections.append({
					"from": node_uuid,
					"to": option["output_connections"]["next_node"]["target_node_uuid"],
					"from_port": option["output_connections"]["next_node"]["from_port"],
					"to_port": option["output_connections"]["next_node"]["target_port"]})
			node_connections.sort_custom(func(a,b): return a["from_port"] < b["from_port"])
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


func get_issues() -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	
	for node:DiscourseGraphNode in graph_nodes.values():
		var node_issues: PackedStringArray = node._get_issues()
		if not node_issues.is_empty():
			issues.append({
				"node": node.get_node_uuid(),
				"issues": node_issues})
	
	return issues


func get_nodes_in_frame(frame_uuid: StringName) -> Array[StringName]:
	var node_uuids: Array[StringName] = []
	
	if not node_frames.has(frame_uuid):
		return node_uuids
	
	var frame: GraphFrame = node_frames[frame_uuid]
	
	for attatched_node in get_attached_nodes_of_frame(frame.name):
		var node = get_node_or_null(NodePath(attatched_node))
		if node == null or node is not DiscourseGraphNode:
			continue
		node_uuids.append(node.get_node_uuid())
	
	return node_uuids


func get_elements_in_frame(frame_uuid: StringName) -> Dictionary[String, Array]:
	var elements: Dictionary[String, Array] = {
		"nodes": ArrayUtils.create_typed(TYPE_STRING_NAME),
		"frames": ArrayUtils.create_typed(TYPE_STRING_NAME)}
	
	if not node_frames.has(frame_uuid):
		return elements
	
	var frame: GraphFrame = node_frames[frame_uuid]
	
	for attatched_node in get_attached_nodes_of_frame(frame.name):
		var node = get_node_or_null(NodePath(attatched_node))
		if node == null:
			continue
		if node is GraphNode:
			elements["nodes"].append(node.get_node_uuid())
		elif node is GraphFrame:
			elements["frames"].append(node.get_frame_uuid())
	
	return elements


func get_compatible_node_count(connection_type: ConnectionType, node_side: String) -> int:
	if not compatible_connections.has(connection_type) or not compatible_connections[connection_type].has(node_side):
		return 0
	return compatible_connections[connection_type][node_side].size()


func get_compatible_nodes(connection_type: ConnectionType, node_side: String) -> Array[Dictionary]:
	if not compatible_connections.has(connection_type) or not compatible_connections[connection_type].has(node_side):
		return Array([], TYPE_DICTIONARY, &"", null)
	return compatible_connections[connection_type][node_side]

#endregion

#region Setters / Updaters

func set_localization_data(localization: Dictionary) -> void:
	for node_uuid in graph_nodes.keys():
		var node: DiscourseGraphNode = graph_nodes[node_uuid]
		if not node.is_node_localized() or not localization.has(node_uuid):
			continue
		if node.node_type == DialogNodes.DIALOG:
			if typeof(localization[node_uuid]) == TYPE_STRING:
				node.set_dialog_text(localization[node_uuid])
		elif node.node_type == DialogNodes.CHOICES:
			if typeof(localization[node_uuid]) == TYPE_ARRAY:
				var idx: int = 0
				for choice in localization[node_uuid]:
					idx += 1
					node.set_choice_text(idx, choice)
		elif node.node_type == DialogNodes.LOCALIZED_TEXT:
			if typeof(localization[node_uuid]) == TYPE_STRING:
				node.set_text(localization[node_uuid])


func update_localization_data(dialog: EditorDiscourseDialog, for_locale: String) -> void:
	for node:DiscourseGraphNode in graph_nodes.values():
		if not node.is_node_localized():
			continue
		
		if node.node_type == DialogNodes.DIALOG:
			dialog.set_dialog_text(
					node.get_node_uuid(),
					node.get_dialog_text(),
					for_locale)
		elif node.node_type == DialogNodes.CHOICES:
			dialog.set_choices_array(
					node.get_node_uuid(),
					node.get_options(),
					for_locale)
		elif node.node_type == DialogNodes.LOCALIZED_TEXT:
			dialog.set_dialog_text(
					node.get_node_uuid(),
					node.get_text(),
					for_locale)


func update_methods() -> void:
	for node in method_callers:
		node.reload_methods()


func update_signals() -> void:
	for node in signalers:
		node.reload_signals()


func localize_node(node_uuid: StringName, set_localized: bool) -> void:
	if not graph_nodes.has(node_uuid):
		return
	var target: DiscourseGraphNode = graph_nodes[node_uuid]
	target.set_localization_enabled(set_localized)

#endregion

#region Connectors

func connect_discourse_nodes(from_node_uuid: StringName, from_port: int, to_node_uuid: StringName, to_port: int) -> bool:
	if from_node_uuid == to_node_uuid or not graph_nodes.has_all([from_node_uuid, to_node_uuid]):
		return false

	var to_graph: DiscourseGraphNode = graph_nodes[to_node_uuid]
	var from_graph: DiscourseGraphNode = graph_nodes[from_node_uuid]
	
	if from_graph.is_connected_to_output(from_port, to_graph) and to_graph.is_connected_to_input(to_port, from_graph):
		var is_ghost_reconnect: bool =\
			_pending_connection_change.has_all(["from_node", "from_port", "to_node", "to_port"]) and\
			_pending_connection_change["from_node"] == from_node_uuid and\
			_pending_connection_change["from_port"] == from_port and\
			_pending_connection_change["to_node"] == to_node_uuid and\
			_pending_connection_change["to_port"] == to_port
		if is_ghost_reconnect:
			rollback_disconnection()
		return true
	
	if not from_graph.has_port(PortFlow.OUTPUT, from_port) or not to_graph.has_port(PortFlow.INPUT, to_port):
		return false
	
	var from_type: int = from_graph.get_slot_type_right(from_graph.get_slot_from_port(PortFlow.OUTPUT, from_port))
	var to_type: int = to_graph.get_slot_type_left(to_graph.get_slot_from_port(PortFlow.INPUT, to_port))
	
	var from_port_ghost_disconnect: bool = _pending_connection_change.has_all(["from_node", "from_port"]) and _pending_connection_change["from_node"] == from_node_uuid and _pending_connection_change["from_port"] == from_port
	
	var can_connect: bool = \
			(from_graph.is_port_available(
					DiscourseGraphNode.PortMode.OUTPUT,
					from_port) or from_port_ghost_disconnect) and\
			to_graph.is_port_available(
					DiscourseGraphNode.PortMode.INPUT,
					to_port) and \
			( from_type == to_type or is_valid_connection_type(from_type, to_type) )
	
	if not can_connect:
		return false
	
	connect_node(from_graph.name, from_port, to_graph.name, to_port)
	
	to_graph.set_input_connection(
			to_port,
			from_graph,
			from_port,
			true)
	
	from_graph.set_output_connection(
		from_port, to_graph, to_port, true)
	
	return true


func disconnect_discourse_nodes(from_node_uuid: StringName, from_port: int, to_node_uuid: StringName, to_port: int) -> void:
	if not graph_nodes.has_all([from_node_uuid, to_node_uuid]):
		return
	
	var output_node: DiscourseGraphNode = graph_nodes[from_node_uuid]
	var input_node: DiscourseGraphNode = graph_nodes[to_node_uuid]
	
	if not output_node.is_connected_to_output(from_port, input_node):
		return
	
	input_node.set_input_connection(
			to_port,
			output_node,
			from_port,
			false)
	
	output_node.set_output_connection(
			from_port,
			input_node,
			to_port,
			false)
	
	disconnect_node(output_node.name, from_port, input_node.name, to_port)


func disconnect_all_node_connections(for_uuid: StringName) -> void:
	if not graph_nodes.has(for_uuid):
		return
	
	var target: DiscourseGraphNode = graph_nodes[for_uuid]
	
	for input_port in range(target._input_nodes.size() - 1, -1, -1):
		if not target.has_any_input(input_port):
			continue
		for connection_idx in range(target._input_nodes[input_port]["connections"].size() - 1, -1, -1):
			var input_target: DiscourseGraphNode = target.get_node_connected_to_port(PortFlow.INPUT, input_port, connection_idx)
			disconnect_discourse_nodes(
					input_target.get_node_uuid(),
					input_target.get_port_connected_to(PortFlow.OUTPUT, target, input_port),
					target.get_node_uuid(),
					input_port)
	
	for output_port in range(target._output_nodes.size() - 1, -1, -1):
		if not target.has_any_output(output_port):
			continue
		
		for connection_idx in range(target._output_nodes[output_port]["connections"].size() - 1, -1, -1):
			var output_target: DiscourseGraphNode = target.get_node_connected_to_port(PortFlow.OUTPUT, output_port, connection_idx)
			disconnect_discourse_nodes(
				target.get_node_uuid(),
				output_port,
				output_target.get_node_uuid(),
				output_target.get_port_connected_to(PortFlow.INPUT, target, output_port))


func disconnect_all_outputs_of(for_node: StringName) -> void:
	if not has_discourse_node(for_node):
		return
	
	var target: DiscourseGraphNode = get_discourse_node(for_node)
	
	for output_port in range(target._output_nodes.size() - 1, -1, -1):
		if not target.has_any_output(output_port):
			continue
		
		for connection_idx in range(target._output_nodes[output_port]["connections"].size() - 1, -1, -1):
			var output_target: DiscourseGraphNode = target.get_node_connected_to_port(PortFlow.OUTPUT, output_port, connection_idx)
			disconnect_discourse_nodes(
				target.get_node_uuid(),
				output_port,
				output_target.get_node_uuid(),
				output_target.get_port_connected_to(PortFlow.INPUT, target, output_port))

#endregion

#region UI Actions / Listeners


func _on_use_code_editor_requested(node_uuid: StringName, target_node: TextEdit) -> void:
	use_code_editor_requested.emit(node_uuid, target_node)


func _on_use_character_selector_pressed(node_uuid: StringName, target: LineEdit) -> void:
	browse_character_requested.emit(node_uuid, target)


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	var nodes_to_remove: Dictionary[StringName, Dictionary] = {}
	var node_uuids: Array[StringName] = []
	for selected_node in nodes:
		var node: Control = get_node(NodePath(selected_node))
		if node is DiscourseGraphNode:
			if node.node_type == DiscourseGraphNode.DialogueNodeType.ENTRY:
				continue
			nodes_to_remove[node.get_node_uuid()] = node.get_node_state()
			node_uuids.append(node.get_node_uuid())
	
	if node_uuids.is_empty():
		return
	
	nodes_removed.emit("remove", nodes_to_remove)


func set_node_in_frame(node_uuid: StringName, frame: StringName) -> void:
	if not graph_nodes.has(node_uuid) or not node_frames.has(frame) or get_element_frame(graph_nodes[node_uuid].name) == node_frames[frame]:
		return
	attach_graph_element_to_frame(graph_nodes[node_uuid].name, node_frames[frame].name)


func _on_anchor_id_changed(uuid: String, old_id: String, new_id: String, source: DiscourseGraphNode) -> void:
	var valid_id: String = get_valid_shortcut_id(new_id, source)

	source.set_anchor_id(valid_id)
	
	for anchor in anchor_pointers:
		anchor.update_anchor(uuid, valid_id)
	
	shortcut_node_id_changed.emit(uuid, old_id, new_id)
	dialog_changed.emit()


func _on_popup_index_pressed(index: int, menu: PopupMenu) -> void:
	var from: DiscourseGraphNode = graph_nodes[release_data["from_node"]]
	var from_port: int = release_data["from_port"]
	var data: Dictionary = menu.get_item_metadata(index)
	var connection_type = menu.get_item_id(index)
	var target_position: Vector2 = Vector2((release_data["release_position"] / zoom) + (scroll_offset / zoom))
	
	var node_data: Dictionary = get_compatible_node_overwrite_data(
			connection_type,
			data["flow"],
			data["target_type"],
			0 if menu == connection_popup else index).duplicate(true)
	
	DictUtils.set_nested_value(
			node_data,
			["metadata", "position"],
			target_position)
	
	var new_node: DiscourseGraphNode = spawn_node(data["target_type"], &"", node_data)

	var frame: GraphFrame = get_element_frame(from.name)
	
	new_node.position_offset -= new_node.get_input_port_position(data["target_port"]) if data["flow"] == "output" else new_node.get_output_port_position(data["target_port"])
	snap_node_to_grid(new_node)
	
	if data["flow"] == "input":
		if new_node.node_type == DialogNodes.VALUE:
			var port
			new_node.set_mode(port_type_to_var_type(release_data["target_type"]))
		elif new_node.node_type == DialogNodes.VARIABLE_GET:
			new_node.set_node_type(release_data["target_type"])
		
		connect_discourse_nodes(
				new_node.get_node_uuid(),
				data["target_port"],
				from.get_node_uuid(),
				from_port)
	else:
		connect_discourse_nodes(
				from.get_node_uuid(),
				from_port,
				new_node.get_node_uuid(),
				data["target_port"])
	
	if frame != null:
		attach_graph_element_to_frame(new_node.name, frame.name)
	
	var node_arr: Array[StringName] = [new_node.get_node_uuid()]
	node_created.emit(new_node)
	nodes_created.emit(node_arr, "Create Node")
	dialog_changed.emit()


func port_type_to_var_type(port_type: int) -> int:
	match port_type:
		ConnectionType.VAR_BOOL:
			return TYPE_BOOL
		ConnectionType.VAR_STRING:
			return TYPE_STRING
		ConnectionType.VAR_INT:
			return TYPE_INT
		ConnectionType.VAR_FLOAT:
			return TYPE_FLOAT
		_:
			return TYPE_NIL

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
		set_diconnection(
				from_graph.get_node_uuid(),
				from_port,
				to_graph.get_node_uuid(),
				to_port)
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

		disconnect_node(
				to_graph.name,
				to_port,
				from_node,
				from_port)


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from: DiscourseGraphNode = get_node(NodePath(from_node))
	var to: DiscourseGraphNode = get_node(NodePath(to_node))
	
	var has_type: bool = _pending_connection_change.has("type")
	if has_type:
		var same_origin: bool = from.get_node_uuid() == _pending_connection_change["from_node"] and from_port == _pending_connection_change["from_port"]
		var same_destination: bool = to.get_node_uuid() == _pending_connection_change["to_node"] and to_port == _pending_connection_change["to_port"]
		var switch_disconnect: bool = _pending_connection_change["type"] == ConnectionChangeType.SWITCH_DISCONNECT
		
		if same_origin and same_destination:
			rollback_disconnection()
		else:
			var change: Dictionary = _pending_connection_change.duplicate()
			var original_from_node: DiscourseGraphNode = get_discourse_node(change["from_node"])
			var original_from_state: Dictionary = original_from_node._get_node_data()
			var original_to_node: DiscourseGraphNode = get_discourse_node(change["to_node"])
			var original_to_state: Dictionary = original_to_node._get_node_data()
			commit_disconnection()
			# Was the connection successful?
			var con_success: bool = connect_discourse_nodes(from.get_node_uuid(), from_port, to.get_node_uuid(), to_port)
			
			if con_success:
				var new_from_state: Dictionary = from._get_node_data()
				var new_to_state: Dictionary = to._get_node_data()
				node_connection_switched.emit(change, to.get_node_uuid(), to_port, original_from_state, original_to_state, new_from_state, new_to_state)
			else:
				node_disconnected.emit(
					change["from_node"],
					change["from_port"],
					change["to_node"],
					change["to_port"],
					original_from_state,
					original_to_state)
			
			dialog_changed.emit()
		return
	
	if connect_discourse_nodes(
			from.get_node_uuid(),
			from_port,
			to.get_node_uuid(),
			to_port):
		node_connected.emit(from.get_node_uuid(), from_port, to.get_node_uuid(), to_port)
		dialog_changed.emit()


func _on_connection_drag_ended() -> void:
	if _pending_connection_change.has("type"):
		var change: Dictionary = _pending_connection_change.duplicate()
		var origin_node: DiscourseGraphNode = get_discourse_node(change["from_node"])
		var from_state: Dictionary = origin_node._get_node_data()
		var to_node: DiscourseGraphNode = get_discourse_node(change["to_node"])
		var to_state: Dictionary = to_node._get_node_data()
		commit_disconnection()
		if change["type"] == ConnectionChangeType.SWITCH_DISCONNECT:
			node_disconnected.emit(
				change["from_node"],
				change["from_port"],
				change["to_node"],
				change["to_port"],
				from_state,
				to_state)
		dialog_changed.emit()


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	if _pending_connection_change.has("type"):
		commit_disconnection()
		if _pending_connection_change["type"] == ConnectionChangeType.SWITCH_DISCONNECT:
			dialog_changed.emit()
	
	if not Input.is_key_pressed(KEY_CTRL):
		return
	
	var port_node: DiscourseGraphNode = get_node(NodePath(from_node))
	var port_type: int = port_node.get_output_port_type(from_port)
	var node_count: int = get_compatible_node_count(port_type, "output")
	
	if node_count == 0:
		return
	elif node_count == 1 and compatible_connections[port_type]["output"][0]["ports"].size() == 1:
		var to_info: Dictionary = get_compatible_nodes(port_type, "output")[0]
		var data: Dictionary = {
			"metadata": {
				"position": Vector2(
						(release_position / zoom) +\
						(scroll_offset / zoom))}}
		if to_info.has("data"):
			data.merge(to_info["data"])
		var to_graph: DiscourseGraphNode = spawn_node(
				to_info["type"],
				&"",
				data)
		
		var frame: GraphFrame = get_element_frame(from_node)
		to_graph.position_offset -= to_graph.get_output_port_position(to_info["ports"][0]["port"])
		snap_node_to_grid(to_graph)
		connect_discourse_nodes(
				port_node.get_node_uuid(),
				from_port,
				to_graph.get_node_uuid(),
				to_info["ports"][0]["port"])
		if frame != null:
			attach_graph_element_to_frame(to_graph.name, frame.name)
		var node_arr: Array[StringName] = [to_graph.get_node_uuid()]
		node_created.emit(to_graph)
		nodes_created.emit(node_arr, "Create Node")
		dialog_changed.emit()
		return
	
	populate_popup(port_type, "output")
	
	release_data["from_node"] = port_node.get_node_uuid()
	release_data["from_port"] = from_port
	release_data["release_position"] = release_position
	release_data["target_type"] = port_node.get_output_port_type(from_port)
	
	show_connection_popup_at(get_global_mouse_position())


func _on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	if _pending_connection_change.has("type"):
		commit_disconnection()
	
	if not Input.is_key_pressed(KEY_CTRL):
		return
	
	var to_graph: DiscourseGraphNode = get_node(NodePath(to_node))
	var port_type: ConnectionType = to_graph.get_input_port_type(to_port) as ConnectionType
	var node_count: int = get_compatible_node_count(port_type, "input")
	
	if node_count == 0:
		return
	elif node_count == 1 and compatible_connections[port_type]["input"][0]["ports"].size() == 1:
		var from_info: Dictionary = get_compatible_nodes(port_type, "input")[0]
		var frame: GraphFrame = get_element_frame(to_node)
		var data: Dictionary = {
			"metadata": {
				"position": Vector2(
						(release_position / zoom) +\
						(scroll_offset / zoom))}}
		if from_info.has("data"):
			data.merge(from_info["data"])
		
		var from_graph: DiscourseGraphNode = spawn_node(
				from_info["type"],
				&"",
				data)
		
		graph_nodes[from_graph.get_node_uuid()] = from_graph
		
		from_graph.position_offset -= from_graph.get_output_port_position(from_info["ports"][0]["port"])
		snap_node_to_grid(from_graph)
		connect_discourse_nodes(
				from_graph.get_node_uuid(),
				from_info["ports"][0]["port"],
				to_graph.get_node_uuid(),
				to_port)
		if frame != null:
			attach_graph_element_to_frame(from_graph.name, frame.name)
		var node_arr: Array[StringName] = [from_graph.get_node_uuid()]
		node_created.emit(from_graph)
		nodes_created.emit(node_arr, "Create Node")
		dialog_changed.emit()
		return

	populate_popup(port_type, "input")
	
	release_data["from_node"] = to_graph.get_node_uuid()
	release_data["from_port"] = to_port
	release_data["release_position"] = release_position
	release_data["target_type"] = to_graph.get_input_port_type(to_port)
	
	show_connection_popup_at(get_global_mouse_position())


func _on_node_selected(node: GraphElement) -> void:
	if node is DiscourseGraphNode:
		if 1 == get_selected_graph_nodes(true).size():
			discourse_node_selected.emit(node.get_node_uuid())


func _on_begin_node_move() -> void:
	var selected_nodes: Array[GraphElement] = get_selected_graph_elements(true)
	
	movement_data["nodes"].clear()
	movement_data["frames"].clear()
	
	for node in selected_nodes:
		if node is DiscourseGraphNode:
			var frame: GraphFrame = get_element_frame(node.name)
			movement_data["nodes"][node.get_node_uuid()] = {
				"previous_position": node.position_offset,
				"current_position": Vector2.ZERO,
				"previous_frame": &"" if frame == null else frame.get_frame_uuid(),
				"current_frame": &""}
		else:
			movement_data["frames"][node.get_frame_uuid()] = {
				"previous_position": node.position_offset,
				"current_position": Vector2.ZERO}
	
	if not Input.is_key_pressed(KEY_ALT):
		return
	
	for node in selected_nodes:
		var frame: GraphFrame = get_element_frame(node.name)
		if frame != null and not frame.selected: # If frame is selected, we don't detatch inner nodes because everything is selected, maybe
			detach_graph_element_from_frame(node.name)


func _on_end_node_move() -> void:
	for node_uuid in movement_data["nodes"]:
		var node: DiscourseGraphNode = graph_nodes[node_uuid]
		var curr_frame: GraphFrame = get_element_frame(node.name)
		movement_data["nodes"][node_uuid]["current_position"] =\
				node.position_offset
		if curr_frame != null:
			movement_data["nodes"][node_uuid]["current_frame"] =\
					curr_frame.get_frame_uuid()
	
	for frame_uuid in movement_data["frames"]:
		movement_data["frames"][frame_uuid]["current_position"] =\
				node_frames[frame_uuid].position_offset
	
	nodes_moved.emit(movement_data.duplicate(true))
	dialog_changed.emit()


func snap_node_to_grid(target_node: DiscourseGraphNode) -> void:
	if not snapping_enabled:
		return
	target_node.position_offset = target_node.position_offset.snappedf(snapping_distance)


func _on_graph_elements_linked_to_frame_request(elements: Array, frame: StringName) -> void:
	var frame_node: StringName = get_node_or_null(NodePath(frame)).get_frame_uuid()
	var element_uuids: Array[StringName] = []
	
	for element in elements:
		attach_graph_element_to_frame(element, frame)
	
	dialog_changed.emit()


func _on_localize_node_toggled(is_pressed: bool, node: DiscourseGraphNode) -> void:
	if not is_pressed:
		return
	localization_enabled.emit(node)
	dialog_changed.emit()


func _close_requested(node: DiscourseGraphNode) -> void:
	var node_data: Dictionary[StringName, Dictionary] = {
		node.get_node_uuid(): node.get_node_state()}
	nodes_removed.emit("remove", node_data)
	dialog_changed.emit()


func _close_frame_requested(frame: StringName) -> void:
	#remove_frame(frame.get_frame_uuid())
	#dialog_changed.emit()
	pass


func _on_disconnection_request(from_node_uuid: StringName, from_port: int, to_node_uuid: StringName, to_port: int, caller: DiscourseGraphNode) -> void:
	disconnect_discourse_nodes(from_node_uuid, from_port, to_node_uuid, to_port)
	caller.node_disconnected.emit()
	# I don't think this is required as this is only done when a node state
	# changes and that's already handled by other methods.
	#node_disconnected.emit(from_node_uuid, from_port, to_node_uuid, to_port)


func _on_go_to_node_pressed(uuid: StringName) -> void:
	focus_graph_node(uuid)


func stop_focus_animation() -> void:
	if not is_instance_valid(focus_tween):
		return
	# Grabbing reference as signaling "finished" could set focus_tween to null
	var tween: Tween = focus_tween
	tween.stop()
	tween.finished.emit()
	tween.kill()
	focus_tween = null


## Focuses the child node in the graph node.
func focus_graph_node(node_uuid: StringName, animate: bool = true) -> void:
	if not graph_nodes.has(node_uuid):
		return
	
	var node: DiscourseGraphNode = graph_nodes[node_uuid]
	
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


func reset_scroll_offset() -> void:
	var target_size: Vector2 = -Vector2(size.x / 4.0, size.y / 2.0) + Vector2(entry_node.size.x, entry_node.size.y / 2.0)
	scroll_offset = target_size


func _on_copy_nodes_requested() -> void:
	copy_selected_to_clipboard()


func _on_cut_nodes_requested() -> void:
	copy_selected_to_clipboard()
	var nodes_to_remove: Array[StringName] = []
	var removed_nodes_data: Dictionary[StringName, Dictionary] = {}
	for selected_node in get_selected_graph_nodes():
		nodes_to_remove.append(selected_node.get_node_uuid())
		removed_nodes_data[selected_node.get_node_uuid()] =\
				selected_node.get_node_state()
	
	nodes_removed.emit("cut", removed_nodes_data)


func _on_paste_nodes_requested() -> void:
	paste_nodes_requested.emit()

#endregion

#region Others
# Disconnects a node in the graphedit but doesn't notify the nodes yet. To
# apply the disconnection use commit_disconnection or to cancel the disconnection
# use rollback disconnection.
# If there is no to_node or to_port, then there is no disconnection.
func set_diconnection(from_node: StringName, from_port: int, to_node: StringName = &"", to_port: int = -1) -> void:
	if 0 <= to_port:
		_pending_connection_change = {
				"type": ConnectionChangeType.SWITCH_DISCONNECT,
				"from_node": from_node,
				"from_port": from_port,
				"to_node": to_node,
				"to_port": to_port}
		disconnect_node(
				graph_nodes[from_node].name,
				from_port,
				graph_nodes[to_node].name,
				to_port)
	else:
		_pending_connection_change = {
			"type": ConnectionChangeType.NEW_CONNECTION,
			"from_node": from_port,
			"to_node": to_port}


# Notifies the involved nodes of the disconnection. No signals are emmited.
func commit_disconnection() -> void:
	if not _pending_connection_change.has("type"):
		return
	elif _pending_connection_change["type"] == ConnectionChangeType.NEW_CONNECTION:
		_pending_connection_change.clear()
		return
	
	var from: DiscourseGraphNode = graph_nodes[_pending_connection_change["from_node"]]
	var to: DiscourseGraphNode = graph_nodes[_pending_connection_change["to_node"]]
	
	from.set_output_connection(
			_pending_connection_change["from_port"],
			to,
			_pending_connection_change["to_port"],
			false)
	to.set_input_connection(
			_pending_connection_change["to_port"],
			from,
			_pending_connection_change["from_port"],
			false)
	
	_pending_connection_change.clear()


# Rollbacks a disconnection without sending signals or notyfing the nodes.
func rollback_disconnection() -> void:
	if not _pending_connection_change.has("type") or _pending_connection_change["type"] != ConnectionChangeType.SWITCH_DISCONNECT:
		return
	connect_node(
			graph_nodes[_pending_connection_change["from_node"]].name,
			_pending_connection_change["from_port"],
			graph_nodes[_pending_connection_change["to_node"]].name,
			_pending_connection_change["to_port"])
	_pending_connection_change.clear()


func show_connection_popup_at(new_position: Vector2i):
	# Get the PopupMenu's global size
	var popup_size: Vector2i = Vector2i(connection_popup.get_contents_minimum_size())
	
	connection_popup.position = DisplayServer.mouse_get_position()#new_position + offset
	connection_popup.popup()


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


func copy_selected_to_clipboard() -> void:
	var selected_nodes: Array[DiscourseGraphNode] = get_selected_graph_nodes()
	if selected_nodes.is_empty():
		return
	node_clipboard.clear()
	var copy_data: Array[Dictionary] = []
	for selected_node in selected_nodes:
		var data: Dictionary = {
			"node_uuid": selected_node.get_node_uuid(),
			"state": selected_node.get_node_state()}
		copy_data.append(data)
	copy_data.sort_custom(sort_clipboard_custom)
	node_clipboard.clear()
	node_clipboard.assign(copy_data)


func sort_clipboard_custom(item_a: Dictionary, item_b: Dictionary) -> bool:
	return item_a["state"]["data"]["metadata"]["position"] < item_b["state"]["data"]["metadata"]["position"]


func spawn_node_at_center(node_type: DialogNodes, uuid: String = "") -> StringName:
	var new_node: DiscourseGraphNode = spawn_node(node_type, uuid)
	var node_arr: Array[StringName] = [new_node.get_node_uuid()]
	new_node.position_offset = get_center_offset() - (new_node.size / 2.0)
	node_created.emit(new_node)
	nodes_created.emit(node_arr, "Create Node")
	return new_node.get_node_uuid()


func spawn_frame_at_center(uuid: String = "") -> StringName:
	var new_frame: GraphFrame = spawn_frame(uuid)
	new_frame.position_offset = get_center_offset() - ( new_frame.size / 2.0 )
	return new_frame.get_frame_uuid()


func refresh_anchors() -> void:
	for anchor in anchor_pointers:
		for target in anchor_targets:
			anchor.update_anchor(
					target.get_node_uuid(),
					target.get_anchor_id())

#endregion


# --- UndoRedo restore ---

func resize_node(node_uuid: StringName, to_size: Vector2) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null:
		node.size = to_size


func set_comment_node_text(node_uuid: StringName, text: String) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.COMMENT:
		node.set_comment_text(text)


func set_comparation_node_operator(node_uuid: StringName, operator: int) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.COMPARATION:
		node.set_operator(operator)


func set_dialog_node_character_id(node_uuid: StringName, character_id: String) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.DIALOG:
		node.set_character_id(character_id)


func set_dialog_node_dialog_text(node_uuid: StringName, text: String) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.DIALOG:
		node.set_dialog_text(text)


func set_dialog_node_persist_enabled(node_uuid: StringName, persist: bool) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.DIALOG:
		node.set_persist_dialog(persist)


func set_choice_node_text(node_uuid: StringName, choice_id: int, to: String) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.CHOICES:
		node.set_choice_text(choice_id, to)


func set_choices_node_state(node_uuid: StringName, state: Dictionary) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.CHOICES:
		node._set_node_data(state)
		for option in state["metadata"]["choices"]:
			if has_discourse_node(option["output_connections"]["next_node"]["target_node_uuid"]):
				connect_discourse_nodes(
						node_uuid,
						option["output_connections"]["next_node"]["from_port"],
						option["output_connections"]["next_node"]["target_node_uuid"],
						option["output_connections"]["next_node"]["target_port"])
			if has_discourse_node(option["input_connections"]["settings"]["target_node_uuid"]):
				connect_discourse_nodes(
						option["input_connections"]["settings"]["target_node_uuid"],
						option["input_connections"]["settings"]["target_port"],
						node_uuid,
						option["input_connections"]["settings"]["from_port"])


func set_shortcut_node_target(node_uuid: StringName, target_uuid: StringName) -> void:
	if not has_discourse_node(node_uuid) or not has_discourse_node(target_uuid):
		return
	
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.SHORTCUT:
		node.select_target(target_uuid)


func set_shortcut_target_id(node_uuid: StringName, id: String) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node == null or node.node_type != DialogNodes.SHORTCUT_TARGET:
		return
	
	var valid_id: String = get_valid_shortcut_id(id, node)
	node.set_anchor_id(valid_id)
	for anchor in anchor_pointers:
		anchor.update_anchor(
				node_uuid,
				id)


func set_localized_text_node_text(node_uuid: StringName, text: String) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.LOCALIZED_TEXT:
		node.set_text(text)


# For match_node_resized
func set_match_node_cases(node_uuid: StringName, state: Dictionary) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.MATCH:
		node._set_node_data(state)
		for case in state["metadata"]["cases"]:
			var output_connection: Dictionary = case["output_connections"]["next_node"]
			if not has_discourse_node(output_connection["target_node_uuid"]):
				continue
			connect_discourse_nodes(
					node_uuid,
					output_connection["from_port"],
					output_connection["target_node_uuid"],
					output_connection["target_port"])


# Cases IDs start from 1. IDs are Case index + 1
func set_match_node_field(node_uuid: StringName, case_id: int, value: Variant) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.MATCH:
		node.set_match_value(case_id, value)


# Used for match_mode_changed
func set_match_node_state(node_uuid: StringName, state: Dictionary) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	if node == null or node.node_type != DialogNodes.MATCH:
		return
	
	var has_input: bool = node.has_any_input(1)
	var inputs_match: bool = false
	
	if has_input:
		var connection: DiscourseGraphNode = node.get_node_connected_to_port(
				DiscourseGraphNode.PortMode.INPUT,
				1)
		inputs_match = connection.get_node_uuid() == state["input_connections"]["match_value_source"]["target_node_uuid"]
	else:
		inputs_match = state["input_connections"]["match_value_source"]["target_node_uuid"].is_empty()
	
	if has_input and not inputs_match:
		var from_node: DiscourseGraphNode = node.get_node_connected_to_port(
				DiscourseGraphNode.PortMode.INPUT,
				1)
		var from_uuid: StringName = from_node.get_node_uuid()
		var from_port: int = node.get_target_port_connected_to_self(
				DiscourseGraphNode.PortMode.INPUT,
				1)
		disconnect_discourse_nodes(
				from_uuid,
				from_port,
				node_uuid,
				1)
	
	disconnect_all_outputs_of(node_uuid)
	
	node._set_node_data(state)
	
	if not inputs_match:
		if not state["input_connections"]["match_value_source"]["target_node_uuid"].is_empty() and has_discourse_node(state["input_connections"]["match_value_source"]["target_node_uuid"]):
			connect_discourse_nodes(
					state["input_connections"]["match_value_source"]["target_node_uuid"],
					state["input_connections"]["match_value_source"]["target_port"],
					node_uuid,
					state["input_connections"]["match_value_source"]["from_port"]) # Should be 1
		
	var port_idx: int = -1
	for case in state["metadata"]["cases"]:
		var output_connection: Dictionary = case["output_connections"]["next_node"]
		port_idx += 1
		if not has_discourse_node(output_connection["target_node_uuid"]):
			continue
		connect_discourse_nodes(
				node_uuid,
				output_connection["from_port"],
				output_connection["target_node_uuid"],
				output_connection["target_port"])


func set_metadata_node_key(node_uuid: StringName, key_index: int, to: String) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	if node != null and node.node_type == DialogNodes.METADATA:
		node.set_metadata_id(key_index, to)


func set_call_node_state(node_uuid: StringName, state: Dictionary) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.CALLABLE:
		await node.set_method(state["metadata"]["method"])
		for arg_connection in state["metadata"]["arguments"]:
			if not has_discourse_node(arg_connection["target_node_uuid"]):
				continue
			connect_discourse_nodes(
					arg_connection["target_node_uuid"],
					arg_connection["target_port"],
					node_uuid,
					arg_connection["from_port"])


func set_call_return_node_state(node_uuid: StringName, state: Dictionary) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.CALLABLE_RETURN:
		await node.set_method(state["metadata"]["method"])
		var caller_state: Dictionary = state["output_connections"]["caller"]
		if has_discourse_node(caller_state["target_node_uuid"]):
			connect_discourse_nodes(
					caller_state["target_node_uuid"],
					caller_state["target_port"],
					node_uuid,
					caller_state["from_port"])
		
		for arg_connection in state["metadata"]["arguments"]:
			if not has_discourse_node(arg_connection["target_node_uuid"]):
				continue
			connect_discourse_nodes(
					node_uuid,
					arg_connection["from_port"],
					arg_connection["target_node_uuid"],
					arg_connection["target_port"])


# Used for choice_count_state_changed
func set_random_path_node_state(node_uuid: StringName, state: Dictionary) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.RANDOM:
		node.set_random_exit_number(state["metadata"]["options"].size())
		for connection in state["metadata"]["options"]:
			if has_discourse_node(connection["input_connections"]["weight"]["target_node_uuid"]):
				connect_discourse_nodes(
						connection["input_connections"]["weight"]["target_node_uuid"],
						connection["input_connections"]["weight"]["target_port"],
						node_uuid,
						connection["input_connections"]["weight"]["from_port"])
			if has_discourse_node(connection["output_connections"]["next_node"]["target_node_uuid"]):
				connect_discourse_nodes(
						node_uuid,
						connection["output_connections"]["next_node"]["from_port"],
						connection["output_connections"]["next_node"]["target_node_uuid"],
						connection["output_connections"]["next_node"]["target_port"])


func set_random_value_node_range(node_uuid: StringName, base: float, ceil: float) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.RANDOM_VALUE:
		node.set_range(base, ceil)


func set_random_value_state(node_uuid: StringName, state: Dictionary) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.RANDOM_VALUE:
		var meta: Dictionary = state["metadata"]
		node.set_mode(meta["mode"])
		node.set_range(meta["values"]["base"], meta["values"]["max"])
		if has_discourse_node(state["input_connections"]["base_value"]["target_node_uuid"]):
			connect_discourse_nodes(
					state["input_connections"]["base_value"]["target_node_uuid"],
					state["input_connections"]["base_value"]["target_port"],
					node_uuid,
					state["input_connections"]["base_value"]["from_port"])
		if has_discourse_node(state["input_connections"]["max_value"]["target_node_uuid"]):
			connect_discourse_nodes(
					state["input_connections"]["max_value"]["target_node_uuid"],
					state["input_connections"]["max_value"]["target_port"],
					node_uuid,
					state["input_connections"]["max_value"]["from_port"])
		if has_discourse_node(state["output_connections"]["next_node"]["target_node_uuid"]):
			connect_discourse_nodes(
					node_uuid,
					state["output_connections"]["next_node"]["from_port"],
					state["output_connections"]["next_node"]["target_node_uuid"],
					state["output_connections"]["next_node"]["target_port"])


func set_resource_node_path(node_uuid: StringName, path: String) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.RESOURCE:
		node.set_resource_path(path)


func set_emit_signal_node_state(node_uuid: StringName, state: Dictionary) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.SIGNAL:
		await node.set_signal(state["metadata"]["signal"])
		for signal_argument in state["metadata"]["arguments"]:
			if not has_discourse_node(signal_argument["target_node_uuid"]):
				continue
			connect_discourse_nodes(
					signal_argument["target_node_uuid"],
					signal_argument["target_port"],
					node_uuid,
					signal_argument["from_port"])


func set_shield_node_fallback(node_uuid: StringName, fallback: Variant) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.TYPE_GUARD:
		node.set_fallback_value(fallback)


func set_value_node_state(node_uuid: StringName, state: Dictionary) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.VALUE:
		if node.set_mode(typeof(state["metadata"]["value"])):
			node.set_value(state["metadata"]["value"])
			if has_discourse_node(state["output_connections"]["next_node"]["target_node_uuid"]):
				connect_discourse_nodes(
						node_uuid,
						state["output_connections"]["next_node"]["from_port"],
						state["output_connections"]["next_node"]["target_node_uuid"],
						state["output_connections"]["next_node"]["target_port"])


func set_value_node_value(node_uuid: StringName, value: Variant) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.VALUE:
		node.set_value(value)


func set_variable_node_state(node_uuid: StringName, state: Dictionary) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.VARIABLE_GET:
		node.set_node_type(state["metadata"]["variable_type"])
		if has_discourse_node(state["output_connections"]["target"]["target_node_uuid"]):
			connect_discourse_nodes(
					node_uuid,
					state["output_connections"]["target"]["from_port"],
					state["output_connections"]["target"]["target_node_uuid"],
					state["output_connections"]["target"]["target_port"])


func set_variable_node_path(node_uuid: StringName, path: String) -> void:
	var node: DiscourseGraphNode = get_discourse_node(node_uuid)
	
	if node != null and node.node_type == DialogNodes.VARIABLE_GET:
		node.set_variable_path(path)


func set_frame_title(frame_uuid: StringName, title: String) -> void:
	if node_frames.has(frame_uuid):
		node_frames[frame_uuid].title = title


func set_frame_tint(frame_uuid: StringName, tint: Color) -> void:
	if node_frames.has(frame_uuid):
		node_frames[frame_uuid].set_frame_tint(tint)

# --- Node Signalers ---
