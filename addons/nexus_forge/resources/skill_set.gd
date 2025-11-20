@tool
@icon("res://addons/nexus_forge/icons/stars.svg")
class_name SkillSet
extends Resource
## A resource holding a character's skills.
##
## To add new skills and make them appear on NexusForge you need to add
## a new variable with an export flag and type the skill as an integer.
## Initializing a skill is not required.[br]
## Example: 
## [codeblock]
## @export var my_skill: int = 0
## [/codeblock]


@export var one_handed: int

var _custom_skills: Dictionary[StringName, int] = {}


## Constructor for a new SkillSet with NexusForge's custom skills included.[br]
## Also ensures that when a new skill is registered via
## [method SkillCatalog.create_custom_skill] the returned skillset also registers it.
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


## Returns all the non-custom skills registered in the skill set.
static func skills() -> Array[StringName]:
	const MASK: int = PROPERTY_USAGE_SCRIPT_VARIABLE + PROPERTY_USAGE_STORAGE
	var sk_st: SkillSet = SkillSet.new()
	var all_skills: Array[StringName] = []
	var data: Array[Dictionary] = sk_st.get_script().get_script_property_list()
	
	for item in data:
		if item["type"] != TYPE_INT or not BitUtils.are_bits(item["usage"], MASK, true):
			continue
		all_skills.append(StringName(item["name"]))
	
	return all_skills


## Returns all the custom skills registered in the skill set.
func custom_skills() -> Array[StringName]:
	var all_skills: Array[StringName] = []
	all_skills.assign(_custom_skills.keys())
	return all_skills


## Registers a new custom skill with id [param skill_id] if it didn't exist and
## sets it to [param value].[br]
## Custom skills are tracked individually with exception of the custom skills
## registered on runtime with [method SkillCatalog.create_custom_skill] on the
## [code]NexusForge.Skills[/code] singleton which all SkillSets contain.
func set_custom_skill(skill_id: StringName, value: int) -> void:
	_custom_skills[skill_id] = value


## Gets the value of the custom skill [param skill_id].
func custom_skill_value(skill_id: StringName) -> int:
	if _custom_skills.has(skill_id):
		return _custom_skills[skill_id]
	return 0


## Returns true if this SkillSet contains the custom skill [param skill_id].
func has_custom_skill(skill_id: StringName) -> bool:
	return _custom_skills.has(skill_id)


func erase_custom_skill(skill_id: StringName) -> void:
	_custom_skills.erase(skill_id)
