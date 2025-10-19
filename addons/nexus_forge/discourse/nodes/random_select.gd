extends DiscourseGraphNode


var custom_default_weight: int = -1:
	set(new_default):
		custom_default_weight = new_default
		update_weights()


func update_weights() -> void:
	if custom_default_weight == 0:
		for node in range(2, get_child_count()):
			get_child(node).get_child(1).text = "Weight ??.??%"
	else:
		var base_weight: int = DialogParser.RANDOM_DEFAULT_WEIGHT if custom_default_weight < 0 else custom_default_weight
		var total_weight: int = 0
		var weights: Array[int] = []
		var labels: Array[Label] = []
		
		for node in range(2, get_child_count()):
			if has_any_input(node):
				var input: DiscourseGraphNode = get_node_connected_to_port(PortMode.INPUT, node)
				match input.node_type:
					DialogueNodeType.VALUE:
						if input.mode == TYPE_INT:
							var clamped_weight: int = maxi(-1, input.get_current_value(base_weight))
							weights.append(clamped_weight)
							if 0 <= clamped_weight:
								total_weight += clamped_weight
					_:
						weights.append(-1)
			else:
				weights.append(base_weight)
				total_weight += base_weight
			labels.append(get_child(node).get_child(1))
		
		var idx: int = -1
		for label in labels:
			idx += 1
			if weights[idx] == -1:
				label.text = "Weight ??.??%"
			else:
				var weight: float = snappedf(( weights[idx] / float(total_weight) * 100.0 ), 0.01 )
				@warning_ignore("incompatible_ternary")
				label.text = "Weight " + str( weight if 0 < step_decimals(weight) else int(weight) ) + "%"


func _post_init() -> void:
	name = &"RandomSelect"
	custom_id = "RandomSelect"
	title = "Random Select"
	size = Vector2(200.0, 146.0)
	parent_mode = PortMode.INPUT
	parent_port = 0
	node_type = DialogueNodeType.RANDOM
	
	#var con_con: Control = Control.new()
	var options_container: HBoxContainer = HBoxContainer.new()
	var options_lbl: Label = Label.new()
	var options_spn: SpinBox = SpinBox.new()
	var default_weight: Label = Label.new()
	var first_random: Label = Label.new()
	
	#con_con.custom_minimum_size.y = 24
	#con_con.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_lbl.text = "Options"
	options_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_spn.min_value = 1.0
	options_spn.step = 1.0
	options_spn.value = 1.0
	
	first_random.text = "Weight 100%"
	first_random.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	first_random.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	
	default_weight.text = "Default Weight"
	default_weight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	options_container.add_child(options_lbl)
	options_container.add_child(options_spn)
	
	add_field(
			&"options",
			options_container,
			false,
			SlotConnectionType.DIALOG)
	map_field(&"options", "count", options_spn)
	
	add_field(
			&"weight_default",
			default_weight,
			false,
			SlotConnectionType.VAR_INT)
	add_field(
		&"option_1",
		first_random,
		false,
		SlotConnectionType.VAR_INT,
		SlotConnectionType.DIALOG,
		get_theme_icon("int", "EditorIcons"))
	
	
	set_slot_color_left(0, COLORS["dialog"])
	set_slot_color_left(1, COLORS["integer"])
	set_slot_color_left(2, COLORS["integer"])
	set_slot_color_right(2, COLORS["dialog"])
	set_slot_custom_icon_left(0, flow_icon)
	
	set_slot_custom_icon_right(2, flow_icon)
	
	options_spn.value_changed.connect(_on_random_exit_changed)


func _get_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if is_orphan():
		issues.append("Warning: Node is orphan.")
	for choice in range(get_child_count() - 2):
		if not has_any_output(choice):
			issues.append(str("Warning: Output ", choice, " has no connection."))
	return issues


func _on_input_disconnected(input_port: int, from_node: DiscourseGraphNode, _from_port: int) -> void:
	if input_port <= 0:
		return
	
	if input_port == 1:
		custom_default_weight = -1
	else:
		update_weights()
	
	if from_node.node_type == DialogueNodeType.VALUE:
		if from_node.value_changed.is_connected(update_weights):
			from_node.value_changed.disconnect(update_weights)
		from_node.clamp_range(0.0, 100.0, true, true)


func _on_input_connected(input_port: int, from_node: DiscourseGraphNode, _from_port: int) -> void:
	if input_port <= 0:
		return
	
	if from_node.node_type == DialogueNodeType.VALUE:
		if not from_node.value_changed.is_connected(update_weights):
			from_node.value_changed.connect(update_weights)
		from_node.clamp_range(0.0, 100.0, false, true)
	
	if input_port == 1:
		match from_node.node_type:
			DialogueNodeType.VALUE:
				if from_node.mode == TYPE_INT:
					custom_default_weight = from_node.get_current_value(0)
			_:
				custom_default_weight = 0
	else:
		update_weights()



func _on_random_exit_changed(target_options: int) -> void:
	set_random_exit_number(target_options)
	node_updated.emit()


func set_random_exit_number(target_options: int) -> void:
	var current_options: int = get_child_count() - 2
	
	if current_options == target_options:
		return
	
	if current_options < target_options:
		# New option is the index of the new item
		for new_option in range(current_options + 1, target_options + 1):
			var new_random := Label.new()
			new_random.text = "Weight ??.??%"
			new_random.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			new_random.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
			add_field(
				&"option_" + StringName(str(int(new_option))),
				new_random,
				false,
				SlotConnectionType.VAR_INT,
				SlotConnectionType.DIALOG,
				get_theme_icon("int", "EditorIcons"))
			set_slot_color_right(
				new_option + 1,
				COLORS["dialog"])
			
			set_slot_color_left(
				new_option + 1,
				COLORS["integer"])
			
			set_slot_custom_icon_right(
					new_option + 1,
					flow_icon)
	else:
		for extra_option in range(current_options, target_options, -1):
			var port_id: StringName = &"option_" + StringName(str(int(extra_option)))
			remove_field(port_id, 31)
	
	update_weights()


func _set_node_data(data: Dictionary) -> void:
	var options: int = data["options"].size()
	position_offset = data["position"]
	get_mapped_field(&"options", "count").set_value_no_signal(options)
	set_random_exit_number(options)


func _get_node_data() -> Dictionary:
	var data: Dictionary = {}
	var random_outputs: Array[Dictionary] = []
	
	for option_number in range(get_mapped_field(&"options", "count").value):
		random_outputs.append(
			{
				"input_connections": {
					"weight": get_uuid_and_port_connected_to(
							PortMode.INPUT,
							option_number + 2)},
				"output_connections": {
					"next_node": get_uuid_and_port_connected_to(
							PortMode.OUTPUT,
							option_number)}
			}
		)
	
	data["input_connections"] = {
		"default_weight": get_uuid_and_port_connected_to(PortMode.INPUT, 1)
	}
	data["options"] = random_outputs
	data["node_type"] = node_type
	data["position"] = position_offset
	
	return data
