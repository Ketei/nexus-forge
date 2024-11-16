@tool
extends DiscourseGraphNode

signal output_port_disconnected(from_node: DiscourseGraphNode, from_port: int, to_node: DiscourseGraphNode, to_port: int)
signal input_port_disconnected(from_node: DiscourseGraphNode, from_port: int, to_node: DiscourseGraphNode, to_port: int)

@onready var reply_count_box: SpinBox = $VBoxContainer/CountContainer/ReplyCountBox
@onready var reply_cancel_box: SpinBox = $VBoxContainer/ExitContainer/ReplyCancelBox
@onready var keep_dialog_check: CheckBox = $VBoxContainer/KeepDialogCheck

@onready var id_line: LineEdit = $IDContainer/IDLine


var replies: Array[Control] = []


func _ready() -> void:
	node_type = DialogData.DialogType.OPTIONS
	create_input_connection("next", 0)
	reply_count_box.value_changed.connect(on_reply_amount_changed)
	
	var new_hbox_node := HBoxContainer.new()
	new_hbox_node.name = &"GraphButtonsNode"
	new_hbox_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_hbox_node.alignment = BoxContainer.ALIGNMENT_END
	
	var close_button := Button.new()
	close_button.name = &"CloseButton"
	close_button.text = "x"
	close_button.flat = true
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.pressed.connect(close_node)
	
	var title_bar: HBoxContainer = get_titlebar_hbox()
	title_bar.add_child(new_hbox_node)
	new_hbox_node.add_child(close_button)
	
	#id_line.text_changed.connect(on_id_line_changed)
	reply_cancel_box.value_changed.connect(on_val_selected)
	keep_dialog_check.toggled.connect(on_keep_dialog_toggled)
	id_line.text_submitted.connect(on_id_submitted)
	id_line.focus_exited.connect(on_id_focus_lost)


func on_id_focus_lost() -> void:
	id_submitted.emit(id_line.text.strip_edges())


func on_id_submitted(_text: String = "") -> void:
	id_line.release_focus()


func set_id_text(new_text: String) -> void:
	id_line.text = new_text
	if id_line.has_focus():
		id_line.caret_column = id_line.text.length()


func on_reply_amount_changed(new_reply_count: float) -> void:
	var replies_size: int = replies.size()
	reply_cancel_box.max_value = new_reply_count
	
	if replies_size == new_reply_count:
		return
	
	elif replies_size < new_reply_count: # We need to add nodes.
		var nodes_to_add: int = Math.distancei(replies_size, new_reply_count)
		for node in range(nodes_to_add):
			var new_node: Label = Label.new()
			var reply_idx: int = replies.size()
			new_node.text = "Option #" + str(reply_idx + 1)
			new_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			new_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			new_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			add_child(new_node)
			replies.append(new_node)
			set_slot(
					new_node.get_index(),
					true,
					6,
					Color(0.881, 0.646, 1),
					true,
					0,
					Color(0.294, 0.8, 0.248))
			create_input_connection(str(reply_idx), get_input_port_count() - 1)
			create_output_connection(str(reply_idx), get_output_port_count() - 1)
			
	else: # We need to remove nodes.
		for idx_to_remove in range(replies.size() - 1, new_reply_count - 1, -1):
			var port_id: String = str(idx_to_remove)
			if has_output_connection(port_id):
				output_port_disconnected.emit(self, port_id)
			
			if has_input_connection(port_id):
				input_port_disconnected.emit(self, port_id)
			
			erase_output_connection(port_id)
			erase_input_connection(str(idx_to_remove))
			
			replies[idx_to_remove].visible = false
			replies[idx_to_remove].queue_free()
		replies.resize(new_reply_count)
		size.y = 190 + (24 * replies.size())
	node_updated.emit()


func get_connector_index(option_index: int) -> int:
	if option_index < 0 or replies.size() < option_index or replies.is_empty():
		return -1
	return replies[option_index].get_index()


func _is_root() -> bool:
	return not has_output_connection("next")


func generate_node_dictionary() -> Dictionary:
	var reply_data: Dictionary = DialogData.get_replies_structure()
	reply_data["cancel"] = reply_cancel_box.value - 1
	reply_data["keep_dialog"] = keep_dialog_check.button_pressed
	reply_data["offset"] = position_offset
	
	for reply in range(replies.size()):
		var reply_input: Dictionary = {}
		var reply_next: Dictionary = {}
		
		if has_input_connection(str(reply)):
			reply_input = get_input_port_connection_by_id(str(reply)).generate_node_dictionary()
		
		if has_output_connection(str(reply)):
			var next_node := get_output_port_connection_by_id(str(reply))
			var next_class := DialogData.NextType.END
			var next_structure = DialogData.get_next_structure()
			var next_dict_data: Dictionary = {}
			
			if next_node.node_type == DialogData.DialogType.DIALOG or next_node.node_type == DialogData.DialogType.OPTIONS:
				next_class = DialogData.NextType.ID
				next_dict_data = DialogData.get_next_by_id()
				next_dict_data["next"] = next_node.node_id
				next_dict_data["use_shortcut"] = next_node.node_type == DialogData.DialogType.ID
				next_dict_data["offset"] = next_node.position_offset
			elif next_node.node_type == DialogData.DialogType.ID:
				next_class = DialogData.NextType.ID
				next_dict_data = next_node.generate_node_dictionary()
			elif next_node.node_type == DialogData.DialogType.RANDOM:
				next_class = DialogData.NextType.RANDOM
				next_dict_data = next_node.generate_node_dictionary()
			elif next_node.node_type == DialogData.DialogType.CONDITION:
				next_class = DialogData.NextType.CONDITION
				next_dict_data = next_node.generate_node_dictionary()
			elif next_node.node_type == DialogData.DialogType.END:
				next_class = DialogData.NextType.END
				next_dict_data = next_node.generate_node_dictionary()
			
			next_structure["type"] = next_class
			next_structure["data"] = next_dict_data
			reply_next = next_structure
		else:
			var next_dict: Dictionary = DialogData.get_next_structure()
			next_dict["type"] = DialogData.NextType.END
			reply_next = next_dict
		
		reply_data["options"].append(reply_input)
		reply_data["targets"].append(reply_next)
	
	return reply_data


func on_val_selected(_new_val: float) -> void:
	node_updated.emit()


func on_keep_dialog_toggled(_is_toggled: bool) -> void:
	node_updated.emit()
