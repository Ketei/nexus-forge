@tool
extends Tree
#perk_id: String, perk_level: int, stat_id: String, value: int, operator: int


enum StatOperators {
	EQUAL,
	NOT_EQUAL,
	LESS_THAN,
	MORE_THAN,
}

const MAX_SKILL: int = 9999

var root_tree: TreeItem
var skills_enabled: bool = true : set = set_skills_enabled


func _ready() -> void:
	root_tree = create_item()
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, false)
	
	set_column_custom_minimum_width(1, 48)
	set_column_custom_minimum_width(2, 80)
	
	skills_enabled = false


func has_id(id: String, omit_tree: TreeItem) -> bool:
	for stat in root_tree.get_children():
		if stat == omit_tree:
			continue
		if stat.get_metadata(0) == id:
			return true
	return false


func set_skills_enabled(is_enabled: bool) -> void:
	skills_enabled = is_enabled
	
	for skill in root_tree.get_children():
		skill.set_editable(0, skills_enabled)
		skill.set_editable(1, skills_enabled)
		skill.set_editable(2, skills_enabled)


func add_skill(skill_id: String, value: int, stat_op: int) -> void:
	var new_stat: TreeItem = create_item(root_tree)
	
	new_stat.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	new_stat.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_stat.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_stat.set_range_config(1, 0, 5, 1.0)
	new_stat.set_text(1, "==,!=,<=,>=,<,>")
	new_stat.set_range_config(2, 0, MAX_SKILL, 1.0)
	
	new_stat.set_text(0, skill_id)
	new_stat.set_range(1, operator_to_range(stat_op))
	new_stat.set_range(2, value)
	
	new_stat.set_editable(0, skills_enabled)
	new_stat.set_editable(1, skills_enabled)
	new_stat.set_editable(2, skills_enabled)


func set_requirement(skill_id: String, enabled: bool, value: int, operator: int) -> void:
	for skill in root_tree.get_children():
		if skill.get_text(0) == skill_id:
			skill.set_checked(0, enabled)
			skill.set_range(1, operator_to_range(operator))
			skill.set_range(2, value)
			break


func operator_to_range(operator: int) -> int:
	match operator:
		OP_EQUAL: # ==
			return 0
		OP_NOT_EQUAL: # !=
			return 1
		OP_LESS: # <
			return 4
		OP_LESS_EQUAL: # <=
			return 2
		OP_GREATER: # >
			return 5
		OP_GREATER_EQUAL: # >=
			return 3
		_:
			return 0


func range_to_operator(operator: int) -> int:
	match operator:
		0: # ==
			return OP_EQUAL
		1: # !=
			return OP_NOT_EQUAL
		4: # <
			return OP_LESS
		2: # <=
			return OP_LESS_EQUAL
		5: # >
			return OP_GREATER
		3: # >=
			return OP_GREATER_EQUAL
		_:
			return OP_EQUAL


func get_current_skill_data() -> Dictionary:
	var return_dict: Dictionary = {}
	for stat in root_tree.get_children():
		if not stat.is_checked(0):
			continue
		return_dict[stat.get_text(0)] = {
			"value": stat.get_range(2),
			"operator": range_to_operator(stat.get_range(1))}
	return return_dict


func reset_skills() -> void:
	for skill in root_tree.get_children():
		skill.set_checked(0, false)
		skill.set_range(1, 0)
		skill.set_range(2, 0)


func clear_skills() -> void:
	for stat in root_tree.get_children():
		stat.free()
