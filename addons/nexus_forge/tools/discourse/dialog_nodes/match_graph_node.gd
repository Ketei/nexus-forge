@tool
extends DiscourseGraphNode


const MatchGraphElementScript = preload("res://addons/nexus_forge/tools/discourse/dialog_nodes/match_graph_element_script.gd")

var case_nodes: Array[PanelContainer] = []
var match_type: int = -1

@onready var cases_spn_bx: SpinBox = $HBoxContainer/CasesSpnBx


func _ready() -> void:
	graph_type = GraphType.MATCH
	cases_spn_bx.value_changed.connect(on_cases_updated)
	cases_spn_bx.value_changed.connect(on_field_updated)
	
	register_input_connection("previous", 0, true)
	register_input_connection("value", 1, true)
	register_output_connection("default", 0, true)
	add_utility()


func _connection_set(is_input: bool, connection_id: String, node: DiscourseGraphNode) -> void:
	if is_input and connection_id == "value":
		if node != null:
			match node.graph_type:
				GraphType.VALUE:
					set_match_type(node.get_type())
				#GraphType.CALL_RETURN:
				GraphType.MATH:
					set_match_type(TYPE_FLOAT)
				GraphType.EVAL:
					set_match_type(TYPE_BOOL)
		else:
			match_type = -1


func set_match_type(type: int) -> void:
	match_type = type
	for case in case_nodes:
		case.set_type(type)


func set_cases(case_count: int) -> void:
	cases_spn_bx.value = case_count


func set_case_values(cases: Array) -> void:
	set_cases(cases.size())
	
	if cases.is_empty():
		return
	
	set_match_type(typeof(cases[0]))
	
	for case_idx in range(cases.size()):
		case_nodes[case_idx].set_value(cases[case_idx])


func _is_orphan() -> bool:
	if has_any_input_connection("previous"):
		for prev_con in get_input_connections("previous"):
			if not prev_con._is_orphan():
				return false
	return true


func _get_node_data() -> Dictionary:
	var cases: Array[Dictionary] = [] # value: VARIANT, next: id(int)
	for case in case_nodes:
		cases.append({
			"value": case.get_value(),
			"next": -1 if not has_any_output_connection(str(case.get_index() - 2)) else get_output_connections(str(case.get_index() - 2))[0].node_id
		})
		
	return {
		"match": -1 if not has_any_input_connection("value") else get_input_connections("value")[0].node_id,
		"default": -1 if not has_any_output_connection("default") else get_output_connections("default")[0].node_id,
		"cases": cases,
		"_type": graph_type,
		"_offset": position_offset}


func on_field_updated(_arg: Variant = null) -> void:
	node_updated.emit()


func on_cases_updated(cases_number: float) -> void:
	var cases: int = int(cases_number) - 1 # We're excluding the _default
	var current_cases: int = case_nodes.size()
	
	if cases < current_cases:
		for case_idx in range(cases, case_nodes.size()):
			var case_id: String = str(case_idx + 1)
			if has_any_output_connection(case_id):
				var output_node: DiscourseGraphNode = get_output_connections(case_id)[0]
				disconnect_signaled.emit(
					name,
					get_output_port(case_id),
					output_node.name,
					output_node.get_input_connection_port_by_id("previous"))
				disconnect_output_node(case_id, output_node)
			case_nodes[case_idx].visible = false
			case_nodes[case_idx].queue_free()
			case_nodes.resize(cases)
	elif current_cases < cases:
		for _slot_idx in range(cases - current_cases):
			var new_field := MatchGraphElementScript.new()
			add_child(new_field)
			
			new_field.field_updated.connect(node_updated.emit)
			var slot_idx: int = new_field.get_index()
			set_slot(slot_idx, false, 0, Color.WHITE, true, 0, Color(0.157, 0.784, 0))
			register_output_connection(str(slot_idx - 2), slot_idx - 2, true)
			case_nodes.append(new_field)
			
			if 0 <= match_type:
				new_field.set_type(match_type)
	else:
		return
	
	size.y = 155 + (34 * case_nodes.size())
