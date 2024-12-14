@tool
extends DiscourseGraphNode


signal jump_target_selected(jumper: DiscourseGraphNode, target_idx: int)

var jump_target: DiscourseGraphNode = null
@onready var jump_target_opt_btn: OptionButton = $JumpTargetOptBtn


func _ready() -> void:
	graph_type = GraphType.JUMP
	register_input_connection("previous", 0, false)
	add_utility()
	jump_target_opt_btn.item_selected.connect(on_item_selected)


func _is_orphan() -> bool:
	if has_any_input_connection("previous"):
		for in_con in get_input_connections("previous"):
			if not in_con._is_orphan():
				return false
	return true


func _get_node_data() -> Dictionary:
	return {
		"jump_target": -1 if jump_target == null else jump_target.node_id,
		"_type": graph_type,
		"_offset": position_offset
	}


func set_jump_idx(idx: int) -> void:
	jump_target_opt_btn.select(idx)
	on_item_selected(idx)


func on_item_selected(idx: int) -> void:
	jump_target_selected.emit(self, idx)


func remove_target(idx: int) -> void:
	jump_target_opt_btn.remove_item(idx)


func change_id_name(id: int, new_name: String) -> void:
	print(str("Changing ", id, " for ", new_name))
	print(jump_target_opt_btn.item_count)
	jump_target_opt_btn.set_item_text(
			jump_target_opt_btn.get_item_index(id),
			new_name)


func clear_targets() -> void:
	jump_target_opt_btn.clear()


func add_target(target_name: String) -> void:
	jump_target_opt_btn.add_item(target_name)
