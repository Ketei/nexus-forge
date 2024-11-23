@tool
extends DiscourseGraphNode


signal port_removed(node: DiscourseGraphNode, port_idx: int)

const WEIGTHED_EXIT = preload("res://addons/nexus_forge/tools/discourse/scenes/random_selector/weigthed_exit.tscn")

var exits: Array[Control] = []

@onready var exit_count_box: SpinBox = $SettingsContainer/ExitCountContainer/ExitCountBox
@onready var toggle_weights_check: CheckButton = $SettingsContainer/ToggleWeightsCheck
@onready var settings_container: VBoxContainer = $SettingsContainer


func _ready() -> void:
	node_type = DialogData.DialogType.RANDOM
	create_input_connection("next", 0)
	
	exit_count_box.value_changed.connect(on_exits_changed)
	toggle_weights_check.toggled.connect(on_use_weigths_toggled)
	
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


func on_use_weigths_toggled(is_toggled: bool) -> void:
	for exit in exits:
		if exit.option_weight.editable != is_toggled:
			exit.option_weight.editable = is_toggled
	node_updated.emit()


func on_exits_changed(new_exits: float) -> void:
	var exits_size: int = exits.size()

	if exits_size == new_exits:
		return
	
	elif exits_size < new_exits: # We need to add nodes.
		var nodes_to_add: int = Math.distancei(exits_size, new_exits)
		var exit_size_str: String = str(exits_size)
		
		for node in range(nodes_to_add):
			var new_node: HBoxContainer = WEIGTHED_EXIT.instantiate()
			var current_exit: String = str(get_output_port_count())
			#var out_index: int = exits.size()
			new_node.name = "WeigthExit" + current_exit
			add_child(new_node)
			new_node.weight_changed.connect(on_item_weight_changed)
			new_node.option_weight.editable = toggle_weights_check.button_pressed
			exits.append(new_node)
			set_slot(
					new_node.get_index(),
					false,
					0,
					Color.WHITE,
					true,
					0,
					Color(0.294, 0.8, 0.248))
			create_output_connection(current_exit, get_output_port_count() - 1)
	else: # We need to remove nodes.
		for idx_to_remove in range(exits.size() - 1, new_exits - 1, -1):
			port_removed.emit(self, get_output_port_idx_by_id(str(idx_to_remove)))
			erase_output_connection(str(idx_to_remove))
			exits[idx_to_remove].visible = false
			exits[idx_to_remove].queue_free()
		exits.resize(new_exits)
		size.y = 150 + (exits.size() * 29)
	node_updated.emit()


func on_item_weight_changed() -> void:
	node_updated.emit()


func get_node_index_by_opt(option_idx: int) -> int:
	if exits.is_empty() or option_idx < 0 or exits.size() < option_idx:
		return -1
	return exits[option_idx].get_index()


func set_exit_weigth(option_idx: int, weight: float) -> void:
	#var target: int = get_node_index_by_opt(option_idx)
	#if target == -1:
		#return
	exits[option_idx].option_weight.value = weight


func get_input_port_by_type(input_type: int) -> int:
	for port in range(get_child_count()):
		if not is_slot_enabled_left(port):
			continue
		if get_input_port_type(port) == input_type:
			return port
	return -1


func get_output_port_by_type(output_type: int) -> int:
	for port in range(get_child_count()):
		if not is_slot_enabled_right(port):
			continue
		if get_output_port_type(port) == output_type:
			return port
	return -1


func _is_root() -> bool:
	return not has_input_connection("next")


func generate_node_dictionary() -> Dictionary:
	var random_select: Dictionary = NFDiscourseTool.get_random_select_structure()
	
	random_select["use_weights"] = toggle_weights_check.button_pressed
	random_select["offset"] = position_offset
	
	for exit_idx in range(exits.size()):
		var option_random: Dictionary = NFDiscourseTool.get_random_select_opt_structure()
		var rand_next_struct: Dictionary = NFDiscourseTool.get_next_structure()
		option_random["weight"] = exits[exit_idx].option_weight.value
		
		if has_output_connection(str(exit_idx)):
			var rand_next: DiscourseGraphNode = get_output_port_connection_by_id(str(exit_idx))
			if rand_next.node_type == DialogData.DialogType.DIALOG or rand_next.node_type == DialogData.DialogType.OPTIONS or rand_next.node_type == DialogData.DialogType.ID:
				var next_id: Dictionary = NFDiscourseTool.get_next_by_id()
				next_id["next"] = rand_next.node_id
				next_id["use_shortcut"] = rand_next.node_type == DialogData.DialogType.ID
				next_id["offset"] = rand_next.position_offset
				
				rand_next_struct["type"] = DialogData.NextType.ID
				rand_next_struct["data"] = next_id
			else:
				if rand_next.node_type == DialogData.DialogType.CONDITION:
					rand_next_struct["type"] = DialogData.NextType.CONDITION
				elif rand_next.node_type == DialogData.DialogType.RANDOM:
					rand_next_struct["type"] = DialogData.NextType.RANDOM
				elif rand_next.node_type == DialogData.DialogType.END:
					rand_next_struct["type"] = DialogData.NextType.END
				rand_next_struct["data"] = rand_next.generate_node_dictionary()
		else:
			rand_next_struct["type"] = DialogData.NextType.END
		
		option_random["next"] = rand_next_struct
		
		random_select["options"].append(option_random)
		
	
	return random_select
