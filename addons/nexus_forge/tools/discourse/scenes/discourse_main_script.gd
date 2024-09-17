extends Control


signal current_changed

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
const END_GNODE = preload("res://addons/nexus_forge/tools/discourse/scenes/end_node/end_gnode.tscn")

const ERROR_TEXT: String = "The next dialog has a critical issue:\n{0}\nPlease [Review] the dialog for issues\nand try again."

var current_dialog: TreeItem:
	set(new_dialog):
		current_dialog = new_dialog
		var popup := file_menu_button.get_popup()
		var set_disabled: bool = current_dialog == null
		popup.set_item_disabled(2, set_disabled)
		popup.set_item_disabled(3, set_disabled)
		popup.set_item_disabled(4, set_disabled)
		add_node_button.disabled = set_disabled
		review_menu_button.disabled = set_disabled
var entry_node: DiscourseGraphNode = null
var root_nodes: Array[DiscourseGraphNode] = []
var shortcut_nodes: Array[DiscourseGraphNode] = []
var _is_traveling: bool = false
var _is_loading: bool = false
var _block_change_current: bool = false

@onready var dialog_graph_edit: GraphEdit = %DialogGraphEdit
@onready var no_dialog_container: CenterContainer = %NoDialogContainer
@onready var open_dialog_list: Tree = %OpenDialogList
@onready var id_nodes: Tree = %IDNodes
@onready var info_container: Tree = %InfoContainer
@onready var log_panel: PanelContainer = %LogPanel

@onready var from_next: DiscoursePopupMenu = $MenuWindowPopup/FromNext
@onready var to_value: DiscoursePopupMenu = $MenuWindowPopup/ToValue
@onready var to_result: DiscoursePopupMenu = $MenuWindowPopup/ToResult
@onready var unsaved_confirmation: ConfirmationDialog = $MenuWindowPopup/UnsavedConfirmation
@onready var critical_error_dialog: AcceptDialog = $MenuWindowPopup/CriticalErrorDialog

@onready var add_node_button: MenuButton = $Dialogues/TreeContainer/MenuContainer/AddNodeButton
@onready var file_menu_button: MenuButton = $Dialogues/TreeContainer/MenuContainer/FileMenuButton
@onready var review_menu_button: MenuButton = $Dialogues/TreeContainer/MenuContainer/ReviewMenuButton

@onready var discourse_save_dialog: FileDialog = $DiscourseSaveDialog
@onready var discourse_open_dialog: FileDialog = $DiscourseOpenDialog


func _ready() -> void:
	dialog_graph_edit.add_valid_connection_type(8, 9)
	dialog_graph_edit.connection_request.connect(on_connection_request)
	dialog_graph_edit.disconnection_request.connect(on_disconnection_request)
	dialog_graph_edit.connection_to_empty.connect(on_connection_to_empty)
	dialog_graph_edit.connection_from_empty.connect(on_connection_from_empty)
	id_nodes.center_dialog_pressed.connect(center_node)
	info_container.center_dialog_pressed.connect(center_node)
	# Modification notifications
	current_changed.connect(on_current_changed)
	dialog_graph_edit.end_node_move.connect(notify_change)
	# Popups
	to_value.index_pressed.connect(on_to_type_selected)
	from_next.index_pressed.connect(on_from_next_selected)
	to_result.index_pressed.connect(on_to_result_selected)
	# Menus
	add_node_button.get_popup().id_pressed.connect(on_add_node_selected)
	file_menu_button.get_popup().index_pressed.connect(on_file_menu_selected)
	review_menu_button.get_popup().index_pressed.connect(on_review_option_selected)
	
	discourse_save_dialog.file_selected.connect(on_save_folder_selected)
	discourse_open_dialog.file_selected.connect(on_resource_selected)
	
	open_dialog_list.conversation_selected.connect(on_dialog_selected)


func is_connected_to_entry(node: DiscourseGraphNode, _caller_node: DiscourseGraphNode = null) -> bool:
	#var is_node_connected: bool = node.is_connected_to_root()
	var caller_node = node if _caller_node == null else _caller_node
	
	if _caller_node == node: # Prevent infinite recursion.
		return false
	
	if node.is_connected_to_root():
		return true
	
	var earliest_node: DiscourseGraphNode = node.get_earliest_connected_node()
	
	if earliest_node.node_type == DialogData.DialogType.DIALOG or earliest_node.node_type == DialogData.DialogType.OPTIONS:
		for shortcut in shortcut_nodes:
			if shortcut.get_connection_id() == earliest_node.node_id:
				var connected_to_entry: bool = is_connected_to_entry(shortcut, caller_node)
				# Allows to check all shortcuts.
				if connected_to_entry:
					return true

	# earliest node is not ID'd so we can't shortcut it.
	return false


func has_connection_from(from: StringName, port: int) -> bool:
	for connection in dialog_graph_edit.get_connection_list():
		if connection["from_port"] == port and connection["from_node"] == from:
			return true
	return false


func has_dialog_root(node_id: String) -> bool:
	for node in root_nodes:
		if node._get_node_id() == node_id:
			return true
	return false


## Returns true if the dialog has a mistake that will cause data loss.
func has_critical_mistake() -> bool:
	var used_ids: Array[String] = []
	
	for root_node in root_nodes:
		if root_node.node_id.is_empty():
			return true
		elif used_ids.has(root_node.node_id):
			return true
		else:
			used_ids.append(root_node.node_id)
	return false


func get_dialog_graph_center() -> Vector2:
	return Vector2((dialog_graph_edit.scroll_offset / dialog_graph_edit.zoom) + ((dialog_graph_edit.size / 2) / dialog_graph_edit.zoom))


func get_root_with_id(node_id: String) -> DiscourseGraphNode:
	for node in root_nodes:
		if node.node_id == node_id:
			return node
	return null


func get_root_with_local_name(node_name: StringName) -> DiscourseGraphNode:
	for node in root_nodes:
		if node.name == node_name:
			return node
	return null


func get_current_conversation_data() -> Dictionary:
	var entry: String = ""
	# Node references
	var id_orphans: Array[DiscourseGraphNode] = []
	var id_tree_nodes: Array[DiscourseGraphNode] = []
	
	# Dialog Data
	var full_data_dict:Array[Dictionary] = []
	var orphans: Array[Dictionary] = []
	
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
	
	var used_ids: Array[String] = []
	var pads: int = 1
	
	for node in id_tree_nodes:
		node._debug_naming = true
		
		if node.node_id.is_empty():
			node.node_id = "".rpad(pads)
			pads += 1
			node._clear_on_load = true
		elif used_ids.has(node.node_id):
			node.node_id = node.node_id + "".rpad(pads)
			pads += 1
			node._clear_on_load = true
		else:
			used_ids.append(node.node_id)
			node._clear_on_load = false
		node._debug_naming = false
	
	if entry_node.has_output_connection("next"):
		entry = entry_node.get_output_port_connection_by_id("next").node_id
	
	for node in id_tree_nodes:
		full_data_dict.append({"id": node.node_id, "data": node.generate_node_dictionary(), "clear_on_load": node._clear_on_load})
	
	for node in id_orphans:
		orphans.append(node.generate_node_dictionary())
		
	return {"tree": full_data_dict, "orphans": orphans, "entry": entry, "entry_offset": entry_node.position_offset}


func close_all_files() -> void:
	for file:TreeItem in open_dialog_list.get_tree_children():
		var confirm_close: bool = true
		var final_idx: int = -1
		if file.get_metadata(0)["unsaved"]:
			
			on_dialog_selected(file)
			unsaved_confirmation.show()
			
			var confirmation: int = await unsaved_confirmation.option_selected
			
			match confirmation:
				0: #save
					open_save_dialog(current_dialog, true)
					confirm_close = true
				1: # Discard
					confirm_close = true
				2: # Cancel. Don't close this one.
					confirm_close = false
					final_idx = file.get_index()
		
		if confirm_close:
			file.free()
			
		if 0 <= final_idx:
			on_dialog_selected(
					open_dialog_list.get_file_child(final_idx))
		else:
			dialog_graph_edit.visible = false
			no_dialog_container.visible = true
	
	current_dialog = null


func notify_change() -> void:
	current_changed.emit()


func check_for_mistakes() -> void:
	var roots: Array[DiscourseGraphNode] = []
	
	var orphans: Array[DiscourseGraphNode] = []
	var unreachable: Array[DiscourseGraphNode] = []
	var missing_ids: Array[DiscourseGraphNode] = []
	var duplicate_ids: Array[DiscourseGraphNode] = []
	
	var used_ids: Array[String] = []
	
	info_container.clear_logs()
	
	for node in dialog_graph_edit.get_children():
		if node is not DiscourseGraphNode:
			continue # We ignore the connection nodes.
		
		if node.node_type == DialogData.DialogType.START:
			continue # We can ignore the start node
		
		if node._is_root():
			if node.node_type == DialogData.DialogType.DIALOG or node.node_type == DialogData.DialogType.OPTIONS:
				roots.append(node)
				if node.node_id.is_empty():
					missing_ids.append(node)
				elif used_ids.has(node.node_id):
					duplicate_ids.append(node)
				else:
					used_ids.append(node.node_id)
			else:
				orphans.append(node)
	
	for root in roots:
		if not is_connected_to_entry(root):
			unreachable.append(root)
	
	for unreachable_root in unreachable:
		info_container.log_item(
		"[UNREACHABLE] The dialog is not normally reachable.",
		unreachable_root)
	
	for empty_id_node in missing_ids:
		info_container.log_item(
			"[MISSING_ID] The dialog doesn't have an assigned ID",
			empty_id_node)
	
	for duplicated_id_node in duplicate_ids:
		info_container.log_item(
			"[DUPLICATED ID] The dialog uses a duplicated ID",
			duplicated_id_node)
	
	for orphan in orphans:
		if orphan.node_type != DialogData.DialogType.COMMENT:
			info_container.log_item(
				"[ORPHAN NODE] This node isn't connected to an ID'd node.",
				orphan)
	
	if info_container.get_log_count() == 0:
		info_container.log_item(
				"[OK] No issues exist for the current dialog.",
				null)


func clear_nodes() -> void:
	dialog_graph_edit.clear_connections()
	root_nodes.clear()
	shortcut_nodes.clear()
	id_nodes.remove_all_nodes()
	info_container.clear_logs()
	
	for child in dialog_graph_edit.get_children():
		if child is not DiscourseGraphNode:
			continue
		if child.node_type == DialogData.DialogType.START:
			continue
		
		child.queue_free()


func connect_nodes(from: DiscourseGraphNode, to: DiscourseGraphNode, port_id: String) -> void:
	dialog_graph_edit.connect_node(
			from.name,
			from.get_output_port_idx_by_id(port_id),
			to.name,
			to.get_input_port_idx_by_id(port_id))
	
	from.connect_output_port(port_id, to)
	to.connect_input_port(port_id, from)
	current_changed.emit()


func connect_nodes_specific(from_node: DiscourseGraphNode, from_port: String, to_node: DiscourseGraphNode, to_port: String) -> void:
	dialog_graph_edit.connect_node(
			from_node.name,
			from_node.get_output_port_idx_by_id(from_port),
			to_node.name,
			to_node.get_input_port_idx_by_id(to_port))
	
	from_node.connect_output_port(from_port, to_node)
	to_node.connect_input_port(to_port, from_node)
	current_changed.emit()


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
	current_changed.emit()


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
	current_changed.emit()


## Centers a node in the NodeEdit.
func center_node(dialog_node: DiscourseGraphNode) -> void:
	if dialog_node == null or _is_traveling:
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


func save_conversation(target_tree: TreeItem, resource_path: String) -> void:
	if target_tree == null or resource_path.is_empty():
		printerr("Couldn't save")
		return
	
	var new_resource := DialogData.new()
	var conversation_data: Dictionary = target_tree.get_metadata(0)
	new_resource.dialog_entry = conversation_data["data"]["entry"]
	for tree_dict in conversation_data["data"]["tree"]:
		new_resource.conversation[tree_dict["id"]] = tree_dict["data"]
	new_resource.orphans = conversation_data["data"]["orphans"]
	new_resource._entry_offset = conversation_data["data"]["entry_offset"]
	conversation_data["path"] = resource_path
	ResourceSaver.save(new_resource, resource_path)
	
	if conversation_data["unsaved"]:
		conversation_data["unsaved"] = false
		if target_tree.get_text(0) == "[UNSAVED DIALOG](*)":
			target_tree.set_text(0, resource_path.get_file())
		else:
			target_tree.set_text(0, target_tree.get_text(0).trim_suffix("(*)"))


func open_save_dialog(save_item: TreeItem, close_on_save: bool = false) -> void:
	discourse_save_dialog.target_tree = save_item
	discourse_save_dialog.show()
	var item_saved: bool = await discourse_save_dialog.finished
	if item_saved and close_on_save:
		save_item.free()


func on_current_changed() -> void:
	if current_dialog == null or _block_change_current:
		return
	if not current_dialog.get_metadata(0)["unsaved"]:
		current_dialog.set_text(0, current_dialog.get_text(0) + "(*)")
		current_dialog.get_metadata(0)["unsaved"] = true


func on_file_menu_selected(idx: int) -> void:
	match idx:
		0: # New
			on_new_dialog_selected()
		1: # Open
			discourse_open_dialog.show()
		2: # Save Current
			if has_critical_mistake():
				critical_error_dialog.dialog_text = ERROR_TEXT.format([current_dialog.get_text(0)])
				critical_error_dialog.show()
			elif current_dialog.get_metadata(0)["unsaved"]:
				if current_dialog.get_metadata(0)["path"].is_empty():
					discourse_save_dialog.target_tree = current_dialog
					discourse_save_dialog.show()
				else:
					save_conversation(current_dialog, current_dialog.get_metadata(0)["path"])
		3: # Save All
			on_save_resources()
		4: # Close Current
			if current_dialog != null:
				var selected_idx: int = current_dialog.get_index()
				var confirm_close := true
				
				if current_dialog.get_metadata(0)["unsaved"]:
					unsaved_confirmation.show()
					var confirmation: int = await unsaved_confirmation.option_selected
					match confirmation:
						0: #save
							open_save_dialog(current_dialog, true)
						1: # Discard
							confirm_close = true
						2: # Cancel. Don't close this one.
							confirm_close = false
				
				if confirm_close:
					current_dialog.deselect(0)
					current_dialog.free()
					clear_nodes()
					var new_index: int = clampi(selected_idx, -1, open_dialog_list.get_open_file_count() - 1)
					
					if 0 <= new_index:
						on_dialog_selected(
								open_dialog_list.get_file_child(new_index))
					else:
						dialog_graph_edit.visible = false
						no_dialog_container.visible = true
						current_dialog = null
		5:
			close_all_files()


func on_add_node_selected(selected_id: int) -> void:
	var target_pos := get_dialog_graph_center()
	var new_node: DiscourseGraphNode
	
	match selected_id:
		1: # Dialog
			new_node = spawn_dialog_node(
					"",
					DialogData.get_dialog_structure(),
					null,
					true,
					target_pos)
		2: # Reply Selector
			new_node = spawn_reply_selector_node(
					"",
					DialogData.get_replies_structure(),
					null,
					true,
					target_pos)
		3: # End
			new_node = spawn_end_node(
					DialogData.get_end_structure(),
					true,
					target_pos)
		4: # Character
			new_node = spawn_character_node(
					DialogData.get_character_structure(),
					true,
					target_pos)
		5: # Variables
			new_node = spawn_variables_node(
					DialogData.get_set_var_structure(),
					true,
					target_pos)
		6: # Call Normal
			new_node = spawn_call_node(
					DialogData.get_call_structure(),
					true,
					target_pos)
		7: # Call Return
			new_node = spawn_return_call_node(
					DialogData.get_call_structure(),
					true,
					target_pos)
		8: # Element/Variant
			new_node = spawn_element_node(
					DialogData.get_element_structure(),
					true,
					target_pos)
		9: # Signal
			new_node = spawn_signal_node(
				DialogData.get_signal_structure(),
				true,
				target_pos)
		10: # Comparator
			new_node = spawn_comparator_node(
					DialogData.get_comparation_structure(),
					true,
					target_pos)
		11: # Conditional Split/Cond. Path
			new_node = spawn_conditional_split_node(
					DialogData.get_condition_structure(),
					true,
					target_pos)
		12: # Random
			new_node = spawn_random_select_node(
					DialogData.get_random_select_structure(),
					true,
					target_pos)
		13: # Go to ID/
			new_node = spawn_id_shortcut(target_pos)
		14: # Comment
			new_node = spawn_comment_node(
					DialogData.get_comment_structure(),
					true,
					target_pos)
		_:
			new_node = null
			
	
	if new_node != null:
		new_node.position_offset -= new_node.size / 2
		current_changed.emit()


func on_review_option_selected(selected_idx: int) -> void:
	match selected_idx:
		0: # Check for errors
			if not log_panel.visible:
				log_panel.visible = true
			check_for_mistakes()
		1: # Open LogPanel
			if not log_panel.visible:
				log_panel.visible = true


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
			var new_replies := spawn_reply_selector_node(
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
		5:
			var new_end := spawn_end_node(
					DialogData.get_end_structure(),
					true,
					target_position)
			new_end.position_offset -= new_end.get_input_port_position(0)
			connect_nodes(from_graph, new_end, "next")


func on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	if not Input.is_action_pressed("control_key"):
		return
	
	var to_graph: DiscourseGraphNode = dialog_graph_edit.get_node(NodePath(to_node))
	var port_type = to_graph.get_input_port_type(to_port)
	var target_position := Vector2((release_position / dialog_graph_edit.zoom) + (dialog_graph_edit.scroll_offset / dialog_graph_edit.zoom))
	
	match port_type:
		1:
			var char_node := spawn_character_node(
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
	var _changed: bool = false
	
	if from_graph.has_output_connection(from_id):
		disconnect_output_port(from_graph, from_id)
		_changed = true
	
	if to_graph.has_input_connection(to_id):
		disconnect_input_port(to_graph, to_id)
		_changed = true
	
	if _changed:
		current_changed.emit()


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
	current_changed.emit()


func on_options_input_disconnected(to_node: DiscourseGraphNode, port_id: String) -> void:
	disconnect_input_port(to_node, port_id)


func on_options_output_disconnected(to_node: DiscourseGraphNode, port_id: String) -> void:
	disconnect_output_port(to_node, port_id)


func on_close_requested(graph_node: DiscourseGraphNode) -> void:
	
	for connected_input in graph_node.get_connected_input_ports():
		disconnect_input_port(graph_node, connected_input)
	
	for connected_output in graph_node.get_connected_output_ports():
		disconnect_output_port(graph_node, connected_output)
	
	if graph_node.node_type == DialogData.DialogType.DIALOG or graph_node.node_type == DialogData.DialogType.OPTIONS:
		id_nodes.remove_node(graph_node)
	
	graph_node.queue_free()
	current_changed.emit()


func on_resource_selected(resource_path: String) -> void:
	if not FileAccess.file_exists(resource_path):
		printerr(str("[DISCOURSE] File \"", resource_path, "\" not found."))
		return
	
	var dialog: Resource = load(resource_path)
	
	if dialog is not DialogData:
		printerr(str("[DISCOURSE] File \"", resource_path, "\" is not a dialog."))
		return
	
	var tree_item: TreeItem = open_dialog_list.add_file(resource_path.get_file())
	var tree_tree: Array = []
	var orphans: Array = []
	
	for conv_id in dialog.conversation:
		tree_tree.append({"id": conv_id, "data": dialog.conversation[conv_id].duplicate(true)})
	
	orphans = dialog.orphans.duplicate(true)
	
	tree_item.set_metadata(
			0,
			{
			"path": resource_path,
			"original_data": {
				"tree": tree_tree,
				"orphans": orphans,
				"entry": "",
				"entry_offset": Vector2()},
			"data": {"tree": [], "orphans": [], "entry": "", "entry_offset": dialog._entry_offset}, # Used when unsaved data exists.
			"unsaved": false,
			"scroll_offset": null,
			"zoom": 0.0})

	on_dialog_selected(tree_item)


func on_new_dialog_selected() -> void:
	var new_dialog := DialogData.new()
	var tree_item: TreeItem = open_dialog_list.add_file("[UNSAVED DIALOG](*)")
	tree_item.set_metadata(
			0,
			{
				"path": "",
				"original_data": {"tree": [], "orphans": [], "entry": "", "entry_offset": Vector2.ZERO},
				"data": {"tree": [], "orphans": [], "entry": "", "entry_offset": Vector2()},
				"unsaved": true,
				"scroll_offset": null,
				"zoom": 0.0})
	on_dialog_selected(tree_item)


func on_dialog_selected(tree_item: TreeItem) -> void:
	if _is_loading:
		return # Preveinting infinite loading
	
	_block_change_current = true
	_is_loading = true
	
	if current_dialog != null:
		current_dialog.deselect(0)
		if current_dialog.get_metadata(0)["unsaved"]:
			var item_metadata: Dictionary = current_dialog.get_metadata(0)
			item_metadata["data"] = get_current_conversation_data()
			item_metadata["scroll_offset"] = dialog_graph_edit.scroll_offset
			item_metadata["zoom"] = dialog_graph_edit.zoom
		clear_nodes()
	
	var item_metadata: Dictionary = tree_item.get_metadata(0)
	
	if entry_node == null:
		entry_node = load("res://addons/nexus_forge/tools/discourse/scenes/entry/entry_dialog_gnode.tscn").instantiate()
		dialog_graph_edit.add_child(entry_node)
	
	dialog_graph_edit.visible = true
	no_dialog_container.visible = false
	
	var data_tree: Array = []
	var orphan_nodes: Array = []
	var entry_node_id: String = ""
	
	if item_metadata["unsaved"]:
		data_tree = item_metadata["data"]["tree"]
		orphan_nodes = item_metadata["data"]["orphans"]
		entry_node_id = item_metadata["data"]["entry"]
		entry_node.position_offset = item_metadata["data"]["entry_offset"]
	else:
		data_tree = item_metadata["original_data"]["tree"]
		orphan_nodes = item_metadata["original_data"]["orphans"]
		entry_node_id = item_metadata["original_data"]["entry"]
		entry_node.position_offset = item_metadata["original_data"]["entry_offset"]
	
	# Used to prevent data loss when IDs are repeated.
	var clear_on_load: Array[DiscourseGraphNode] = []
	
	# First loop to instantiate all id_nodes
	for dialog_id:Dictionary in data_tree:
		match dialog_id["data"]["type"]:
			DialogData.DialogType.DIALOG:
				var dialog_node: DiscourseGraphNode = DIALOG_NODE.instantiate()
				dialog_graph_edit.add_child(dialog_node)
				if dialog_id["clear_on_load"]:
					clear_on_load.append(dialog_node)
					dialog_node._debug_naming = true
				dialog_node.node_id = dialog_id["id"]
				root_nodes.append(dialog_node)
				id_nodes.add_node(dialog_node)
			
			DialogData.DialogType.OPTIONS:
				var reply_selector: DiscourseGraphNode = REPLY_SELECTOR_NODE.instantiate()
				dialog_graph_edit.add_child(reply_selector)
				if dialog_id["clear_on_load"]:
					clear_on_load.append(reply_selector)
					reply_selector._debug_naming = true
				reply_selector.node_id = dialog_id["id"]
				root_nodes.append(reply_selector)
				id_nodes.add_node(reply_selector)
			_:
				continue # We skip it because it's not typed
	
	# Second loop to connect all nodes.
	for dialog_id:Dictionary in data_tree:
		match dialog_id["data"]["type"]:
			DialogData.DialogType.DIALOG:
				spawn_dialog_node(
					dialog_id["id"],
					dialog_id["data"],
					get_root_with_id(dialog_id["id"]))
			DialogData.DialogType.OPTIONS:
				spawn_reply_selector_node(
					dialog_id["id"], 
					dialog_id["data"],
					get_root_with_id(dialog_id["id"]))
			_:
				continue # We skip it because it's not typed
	
	for dialog_id:Dictionary in orphan_nodes:
		match dialog_id["type"]:
			DialogData.DialogType.CHARACTER:
				spawn_character_node(dialog_id)
			DialogData.DialogType.VARIABLES:
				spawn_variables_node(dialog_id)
			DialogData.DialogType.CALL:
				spawn_call_node(dialog_id)
			DialogData.DialogType.VALUE:
				spawn_element_node(dialog_id)
			DialogData.DialogType.SIGNAL:
				spawn_signal_node(dialog_id)
			DialogData.DialogType.COMPARATION:
				spawn_comparator_node(dialog_id)
			DialogData.DialogType.CONDITION:
				spawn_conditional_split_node(dialog_id)
			DialogData.DialogType.RANDOM:
				spawn_random_select_node(dialog_id)
			DialogData.DialogType.ID:
				spawn_id_shortcut(dialog_id["offset"])
			DialogData.DialogType.COMMENT:
				spawn_comment_node(dialog_id)
			_:
				continue
	
	if not entry_node_id.is_empty():
		var target_entry := get_root_with_id(entry_node_id)
		if target_entry != null:
			connect_nodes(entry_node, target_entry, "next")
	
	for temp_id_dialog in clear_on_load:
		temp_id_dialog._debug_naming = false
		temp_id_dialog.node_id = temp_id_dialog.node_id
	
	current_dialog = tree_item
	tree_item.select(0)
	_block_change_current = false
	_is_loading = false
	await get_tree().process_frame
	
	if item_metadata["zoom"] == 0:
		dialog_graph_edit.zoom = 1
	else:
		dialog_graph_edit.zoom = item_metadata["zoom"]
	
	if item_metadata["scroll_offset"] == null:
		dialog_graph_edit.scroll_offset = -dialog_graph_edit.size/2 + (entry_node.size / 2)
	else:
		dialog_graph_edit.scroll_offset = item_metadata["scroll_offset"]


func on_center_dialog_called(dialog_id: String) -> void:
	var target_dialog: DiscourseGraphNode = get_root_with_id(dialog_id)
	if target_dialog != null:
		center_node(target_dialog)


func on_save_resources() -> void:
	for dialog_item:TreeItem in open_dialog_list.get_tree_children():
		
		var dialog_metadata: Dictionary = dialog_item.get_metadata(0)
		var used_ids: Array[String] = []
		
		var _skip_file: bool = false
		
		for dialog_id in dialog_metadata["data"]["tree"].keys():
			if dialog_id.is_empty():
				critical_error_dialog.dialog_text = ERROR_TEXT.format([dialog_item.get_text(0)])
				critical_error_dialog.show()
				_skip_file = true
				break
			elif used_ids.has(dialog_id):
				critical_error_dialog.dialog_text = ERROR_TEXT.format([dialog_item.get_text(0)])
				critical_error_dialog.show()
				_skip_file = true
				break
			else:
				used_ids.append(dialog_id)
		
		if not dialog_metadata["unsaved"] or _skip_file:
			continue # No need to waste time saving unchanged resources.

		if dialog_metadata["path"].is_empty():
			discourse_save_dialog.conv_data = dialog_metadata
			discourse_save_dialog.current_file = dialog_item.get_text(0)
			discourse_save_dialog.show()
		else:
			save_conversation(dialog_item, dialog_metadata["path"])


func on_save_folder_selected(file_path: String) -> void:
	save_conversation(
			discourse_save_dialog.target_tree,
			file_path)


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
	
	if not dialog_dict["expand"]:
		dialog_node.minimized = true
		dialog_node.minimize()
	
	dialog_node.dialog_id_line.text = dialog_id
	dialog_node.text_edit.text = dialog_dict["dialog"]["text"]
	dialog_node.seconds_spin_box.value = dialog_dict["dialog"]["seconds_per_letter"]
	dialog_node.pause_check_box.button_pressed = dialog_dict["pause"]
	dialog_node.close_requested.connect(on_close_requested)
	dialog_node.node_updated.connect(notify_change)
	
	if not dialog_dict["character"].is_empty():
		var character_node := spawn_character_node(dialog_dict["character"])
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
			#var new_options := spawn_reply_selector_node("", dialog_dict["next"]["data"])
			#connect_nodes(dialog_node, new_options, "next")
		
		elif dialog_dict["next"]["type"] == DialogData.NextType.ID:
			var connect_to: DiscourseGraphNode
			
			if dialog_dict["next"]["data"]["use_shortcut"]:
				connect_to = spawn_id_shortcut(dialog_dict["next"]["data"]["offset"])
			else:
				connect_to = get_root_with_id(dialog_dict["next"]["data"]["next"])
			if connect_to != null:
				connect_nodes(dialog_node, connect_to, "next")
		
		elif dialog_dict["next"]["type"] == DialogData.NextType.END:
			if not dialog_dict["next"]["data"].is_empty():
				var new_end := spawn_end_node(dialog_dict["next"]["data"])
				connect_nodes(dialog_node, new_end, "next")
	
	return dialog_node


func spawn_character_node(character_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var character_node: DiscourseGraphNode = CHARACTER_NODE.instantiate()
	dialog_graph_edit.add_child(character_node)
	
	if not character_data["expand"]:
		character_node.minimized = true
		character_node.minimize()
	
	character_node.position_offset = offset_override if override_offset else character_data["offset"]
	
	character_node.close_requested.connect(on_close_requested)
	character_node.char_id_line.text = character_data["id"]
	character_node.idle_line.text = character_data["idle"]["animation"]
	character_node.play_idle_check_button.button_pressed = character_data["idle"]["play"]
	character_node.talking_idle.text = character_data["talking"]["animation"]
	character_node.play_talking_check_button.button_pressed = character_data["talking"]["play"]
	character_node.node_updated.connect(notify_change)
	
	return character_node


func spawn_id_shortcut(offset: Vector2) -> DiscourseGraphNode:
	var new_short: DiscourseGraphNode = GO_TO_ID_GNODE.instantiate()
	dialog_graph_edit.add_child(new_short)
	shortcut_nodes.append(new_short)
	new_short.position_offset = offset
	new_short.close_requested.connect(on_close_requested)
	new_short.go_to_dialog.connect(on_center_dialog_called)
	new_short.node_updated.connect(notify_change)
	return new_short


func spawn_conditional_split_node(split_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_conditional: DiscourseGraphNode = CONDITIONAL_SPLIT_NODE.instantiate()
	dialog_graph_edit.add_child(new_conditional)
	new_conditional.position_offset = offset_override if override_offset else split_data["offset"]
	new_conditional.close_requested.connect(on_close_requested)
	new_conditional.node_updated.connect(notify_change)
	
	if not split_data["comparation"].is_empty():
		var comp_node := spawn_comparator_node(split_data["comparation"])
		connect_nodes(comp_node, new_conditional, "result")
	
	if not split_data["true"].is_empty():
		if split_data["true"]["type"] == DialogData.NextType.ID:
			var next_id_node: DiscourseGraphNode
			if split_data["true"]["data"]["use_shortcut"]:
				next_id_node = spawn_id_shortcut(split_data["true"]["data"]["offset"])
			else:
				next_id_node = get_root_with_id(split_data["true"]["data"]["next"])
			if next_id_node != null:
				connect_nodes_specific(new_conditional, "true", next_id_node, "next")
		elif split_data["true"]["type"] == DialogData.NextType.RANDOM:
			var new_rand := spawn_random_select_node(split_data["true"]["data"])
			connect_nodes_specific(new_conditional, "true", new_rand, "next")
		elif split_data["true"]["type"] == DialogData.NextType.CONDITION:
			var new_cond_reloaded := spawn_conditional_split_node(split_data["true"]["data"])
			connect_nodes_specific(new_conditional, "true", new_cond_reloaded, "next")
		elif split_data["true"]["type"] == DialogData.NextType.END:
			if not split_data["true"]["data"].is_empty():
				var new_end := spawn_end_node(split_data["true"]["data"])
				connect_nodes_specific(new_conditional, "true", new_end, "next")
		
	if not split_data["false"].is_empty():
		if split_data["false"]["type"] == DialogData.NextType.ID:
			var next_id_node: DiscourseGraphNode
			if split_data["false"]["data"]["use_shortcut"]:
				next_id_node = spawn_id_shortcut(split_data["false"]["data"]["offset"])
			else:
				next_id_node = get_root_with_id(split_data["false"]["data"]["next"])
			if next_id_node != null:
				connect_nodes_specific(new_conditional, "false", next_id_node, "next")
		elif split_data["false"]["type"] == DialogData.NextType.RANDOM:
			var new_rand := spawn_random_select_node(split_data["false"]["data"])
			connect_nodes_specific(new_conditional, "false", new_rand, "next")
		elif split_data["false"]["type"] == DialogData.NextType.CONDITION:
			var new_cond_reloaded := spawn_conditional_split_node(split_data["false"]["data"])
			connect_nodes_specific(new_conditional, "false", new_cond_reloaded, "next")
		elif split_data["false"]["type"] == DialogData.NextType.END:
			if not split_data["false"]["data"].is_empty():
				var new_end := spawn_end_node(split_data["false"]["data"])
				connect_nodes_specific(new_conditional, "false", new_end, "next")
	
	return new_conditional


func spawn_random_select_node(random_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_rand: DiscourseGraphNode = RANDOM_SELECT_GNODE.instantiate()
	var opt_size: int = random_data["options"].size()
	dialog_graph_edit.add_child(new_rand)
	
	new_rand.position_offset = offset_override if override_offset else random_data["offset"]
	new_rand.exit_count_box.value = opt_size
	
	new_rand.port_removed.connect(on_options_output_disconnected)
	new_rand.close_requested.connect(on_close_requested)
	new_rand.node_updated.connect(notify_change)
	
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
		
		elif random_data["options"][opt_idx]["next"]["type"] == DialogData.NextType.END and not random_data["options"][opt_idx]["next"]["data"].is_empty():
			var new_end := spawn_end_node(random_data["options"][opt_idx]["next"]["data"])
			connect_nodes_specific(new_rand, str(opt_idx), new_end, "next")
			
	return new_rand


func spawn_reply_selector_node(dialog_id: String, options_dict: Dictionary, target_node: DiscourseGraphNode = null, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
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
	reply_selector.node_updated.connect(notify_change)
	
	if not options_dict["options"].is_empty():
		reply_selector.reply_count_box.value = options_dict["options"].size()
		
		for option_idx in range(options_dict["options"].size()):
			# If the input ins't empty
			if not options_dict["options"][option_idx].is_empty():
				var new_reply := spawn_reply_node(options_dict["options"][option_idx])
				
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
						
				elif options_dict["targets"][option_idx]["type"] == DialogData.NextType.RANDOM:
					var random_node: DiscourseGraphNode = spawn_random_select_node(options_dict["targets"][option_idx]["next"])
					connect_nodes_specific(reply_selector, str(option_idx), random_node, "next")
					
				elif options_dict["targets"][option_idx]["type"] == DialogData.NextType.CONDITION:
					var new_cond := spawn_conditional_split_node(options_dict["targets"][option_idx]["next"])
					connect_nodes_specific(reply_selector, str(option_idx), new_cond, "next")
				elif options_dict["targets"][option_idx]["type"] == DialogData.NextType.END:
					if not options_dict["targets"][option_idx]["data"].is_empty():
						var new_end := spawn_end_node(options_dict["targets"][option_idx]["data"])
						connect_nodes_specific(reply_selector, str(option_idx), new_end, "next")
	
	reply_selector.reply_cancel_box.value = options_dict["cancel"]
	
	return reply_selector


func spawn_reply_node(reply_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var option_node: DiscourseGraphNode = REPLY_NODE.instantiate()
	dialog_graph_edit.add_child(option_node)
	
	option_node.position_offset = offset_override if override_offset else reply_data["offset"]
	option_node.reply_line.text = reply_data["text"] 
	option_node.close_requested.connect(on_close_requested)
	option_node.node_updated.connect(notify_change)
	
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
	new_comparator.node_updated.connect(notify_change)
	
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
	new_element.node_updated.connect(notify_change)
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
	new_signal_node.node_updated.connect(notify_change)
	return new_signal_node


func spawn_variables_node(variables_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var variables_node: DiscourseGraphNode = SET_VARIABLE_GNODE.instantiate()
	dialog_graph_edit.add_child(variables_node)
	variables_node.position_offset = offset_override if override_offset else variables_data["offset"]
	if not variables_data["expand"]:
		variables_node.minimized = true
		variables_node.minimize()
	
	variables_node.close_requested.connect(on_close_requested)
	variables_node.node_updated.connect(notify_change)
	
	for variable in variables_data["variables"]:
		variables_node.add_variable_type(
				variable,
				variables_data["variables"][variable])
	return variables_node


func spawn_call_node(call_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_node: DiscourseGraphNode = METHOD_CALL_GNODE.instantiate()
	dialog_graph_edit.add_child(new_node)
	new_node.position_offset = offset_override if override_offset else call_data["offset"]
	if not call_data["expand"]:
		new_node.minimized = true
		new_node.minimize()
	
	new_node.select_by_callable(call_data["object"], call_data["method"])
	new_node.set_args(call_data["args"])
	new_node.close_requested.connect(on_close_requested)
	new_node.node_updated.connect(notify_change)
	return new_node


func spawn_return_call_node(call_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_node: DiscourseGraphNode = RETURN_CALL_NODE.instantiate()
	dialog_graph_edit.add_child(new_node)
	new_node.position_offset = offset_override if override_offset else call_data["offset"]
	if not call_data["expand"]:
		new_node.minimized = true
		new_node.minimize()
	new_node.select_by_callable(call_data["object"], call_data["method"])
	new_node.set_args(call_data["args"])
	new_node.close_requested.connect(on_close_requested)
	new_node.node_updated.connect(notify_change)
	return new_node


func spawn_comment_node(comment_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_comment: DiscourseGraphNode = COMMENT_GRAPH_NODE.instantiate()
	new_comment.close_requested.connect(on_close_requested)
	dialog_graph_edit.add_child(new_comment)
	new_comment.position_offset = offset_override if override_offset else comment_data["offset"]
	new_comment.size = comment_data["size"]
	new_comment.comment_text.text = comment_data["text"]
	new_comment.node_updated.connect(notify_change)
	return new_comment


func spawn_end_node(end_data: Dictionary, override_offset := false, offset_override: Vector2 = Vector2.ZERO) -> DiscourseGraphNode:
	var new_end: DiscourseGraphNode = END_GNODE.instantiate()
	dialog_graph_edit.add_child(new_end)
	new_end.close_requested.connect(on_close_requested)
	new_end.position_offset = offset_override if override_offset else end_data["offset"]
	return new_end
