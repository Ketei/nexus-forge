@tool
class_name SkillSet
extends Resource


@export var one_handed: int

@export var _custom_skills: Dictionary[StringName, int] = {}


static func new_skill_set() -> SkillSet:
	var new_set: SkillSet = SkillSet.new()
	for skill_id in NexusForge.Skills.custom_skills():
		if new_set._custom_skills.has(skill_id):
			continue
		new_set._custom_skills[skill_id] = 0
	
	NexusForge.Skills.custom_skill_created.connect(new_set._on_custom_skill_created)
	NexusForge.Skills.custom_skill_erased.connect(new_set._on_custom_skill_erased)
	return new_set


func _on_custom_skill_created(skill_id: StringName) -> void:
	if _custom_skills.has(skill_id):
		return
	
	_custom_skills[skill_id] = 0


func _on_custom_skill_erased(skill_id: StringName) -> void:
	if _custom_skills.has(skill_id):
		_custom_skills.erase(skill_id)


func skills() -> Array[StringName]:
	var all_skills: Array[StringName] = []
	var data: Array[Dictionary] = get_script().get_script_property_list()
	
	for item in data:
		if item["type"] != TYPE_INT or item["usage"] != PROPERTY_USAGE_SCRIPT_VARIABLE + PROPERTY_USAGE_EDITOR + PROPERTY_USAGE_STORAGE:
			continue
		all_skills.append(StringName(item["name"]))
	
	return all_skills


func custom_skills() -> Array[StringName]:
	var all_skills: Array[StringName] = []
	all_skills.assign(_custom_skills.keys())
	return all_skills


func create_custom(skill_id: StringName) -> void:
	if _custom_skills.has(skill_id):
		return
	_custom_skills[skill_id] = 0


func get_custom(skill_id: StringName) -> int:
	if _custom_skills.has(skill_id):
		return _custom_skills[skill_id]
	return 0


func has_custom(skill_id: StringName) -> int:
	return _custom_skills.has(skill_id)
