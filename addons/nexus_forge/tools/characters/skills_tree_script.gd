@tool
extends Tree


var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	
	set_column_title(0, "Skill ID")
	set_column_title(1, "Level")
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	
	set_column_custom_minimum_width(1, 75)


func add_skill(skill_id: String, skill_limit: int) -> void:
	var new_skill: TreeItem = create_item(root_tree)
	var fixed_skill: int = maxi(0, skill_limit)
	
	new_skill.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_skill.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	
	new_skill.set_editable(0, false)
	new_skill.set_editable(1, true)
	
	new_skill.set_selectable(0, false)
	new_skill.set_selectable(1, true)
	
	new_skill.set_range_config(
			1,
			0,
			fixed_skill,
			1.0)
	
	new_skill.set_text(0, skill_id)
	new_skill.set_range(1, 0)


func set_skill(skill_id: String, skill_value: int) -> void:
	for skill in root_tree.get_children():
		if skill.get_text(0) == skill_id:
			skill.set_range(1, maxi(0, skill_value))
			break


func get_skill_data() -> Dictionary:
	var current_config: Dictionary = {}
	for skill in root_tree.get_children():
		current_config[skill.get_text(0)] = int(skill.get_range(1))
	return current_config


func reset_skills() -> void:
	for skill in root_tree.get_children():
		skill.set_range(1, 0)


func clear_skills() -> void:
	for skill in root_tree.get_children():
		skill.free()
