@tool
extends DiscourseGraphNode


const RandomGraphEntry = preload("res://addons/nexus_forge/scenes/discourse/dialog_nodes/random_graph_entry.gd")

var random_exits: Array[HBoxContainer] = []

@onready var rand_opt_spn_bx: SpinBox = $HBoxContainer/RandOptSpnBx
@onready var weights_chk_btn: CheckButton = $WeightsChkBtn


func _ready() -> void:
	graph_type = GraphType.RANDOM
	
	var default_rand := RandomGraphEntry.new()
	add_child(default_rand)
	default_rand.set_text("1")
	default_rand.use_weights(false)
	random_exits.append(default_rand)
	set_slot(
			2,
			false,
			0,
			Color.WHITE,
			true,
			0,
			Color(0.157, 0.784, 0))
	
	register_input_connection("previous", 0, false)
	register_output_connection("1", 0, true)
	add_utility()
	
	rand_opt_spn_bx.value_changed.connect(on_random_exits_changed)
	rand_opt_spn_bx.value_changed.connect(on_field_changed)
	weights_chk_btn.toggled.connect(on_toggle_use_weights)
	weights_chk_btn.toggled.connect(on_field_changed)


func _is_orphan() -> bool:
	if has_any_input_connection("previous"):
		for prev_con in get_input_connections("previous"):
			if not prev_con._is_orphan():
				return false
	return true


func _get_node_data() -> Dictionary:
	var exits: Array[Dictionary] = []
	
	for exit in random_exits:
		exits.append({
			"next": -1 if not has_any_output_connection(str(exit.get_index() - 1)) else get_output_connections(str(exit.get_index() - 1))[0].node_id,
			"weight": exit.get_weigth()
		})
	
	return {
		"use_weights": weights_chk_btn.button_pressed,
		"exits": exits,
		"_type": graph_type,
		"_offset": position_offset
	}


func on_field_changed(_arg: Variant = null) -> void:
	node_updated.emit()


func on_toggle_use_weights(use: bool) -> void:
	for node in random_exits:
		node.use_weights(use)


func on_random_exits_changed(new_exits: float) -> void:
	var desired_exits: int = int(new_exits)
	var current_exits: int = random_exits.size()
	
	if desired_exits < current_exits:
		for case_idx in range(desired_exits, current_exits):
			var case_id: String = str(case_idx)
			if has_any_output_connection(case_id):
				var output_node: DiscourseGraphNode = get_output_connections(case_id)[0]
				disconnect_signaled.emit(
					name,
					get_output_port(case_id),
					output_node.name,
					output_node.get_input_connection_port_by_id("previous"))
				disconnect_output_node(case_id, output_node)
			random_exits[case_idx].visible = false
			random_exits[case_idx].queue_free()
			random_exits.resize(desired_exits)
	elif current_exits < desired_exits:
		for _slot_idx in range(desired_exits - current_exits):
			var new_field := RandomGraphEntry.new()
			add_child(new_field)
			new_field.field_updated.connect(node_updated.emit)
			var slot_idx: int = new_field.get_index()
			var slot_id: String = str(slot_idx - 1)
			new_field.set_text(slot_id)
			new_field.use_weights(weights_chk_btn.button_pressed)
			set_slot(slot_idx, false, 0, Color.WHITE, true, 0, Color(0.157, 0.784, 0))
			register_output_connection(slot_id, slot_idx - 2, true) # Port 0, -> 2
			random_exits.append(new_field)
	else:
		return
	
	size.y = 121 + (34 * random_exits.size())


func set_random_exits(exits: int) -> void:
	rand_opt_spn_bx.value = exits


func set_use_weights(use_weights: bool) -> void:
	weights_chk_btn.button_pressed = use_weights


func set_random_with_weights(weights: Array[float]) -> void:
	set_random_exits(weights.size())
	
	for weight_idx in range(weights.size()):
		random_exits[weight_idx].set_weight(weights[weight_idx])
