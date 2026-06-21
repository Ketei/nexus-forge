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


@export var persuasion: int

@export_storage var _custom_skills: Dictionary[StringName, int] = {}


func _get(property: StringName) -> Variant:
	if _custom_skills.has(property):
		return _custom_skills[property]
	return -1


func _set(property: StringName, value: Variant) -> bool:
	var val_type: int = typeof(value)
	if _custom_skills.has(property) and (val_type == TYPE_INT or val_type == TYPE_FLOAT):
		_custom_skills[property] = value
		return true
	return false


func _init(use_nexus_forge: bool = true) -> void:
	if not use_nexus_forge or not NexusForge.is_inside_tree():
		return
	
	for skill_id in NexusForge.Skills.custom_skills():
		if _custom_skills.has(skill_id):
			continue
		_custom_skills[skill_id] = 0
	
	NexusForge.Skills.custom_skill_created.connect(_on_custom_skill_created)
	NexusForge.Skills.custom_skill_erased.connect(_on_custom_skill_erased)


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
	var sk_st: SkillSet = SkillSet.new(false)
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


## Creates a custom skill and sets it to [param value] which can then be
## accessed and modified directly like
## [code]SkillSet.my_custom_trait[/code].[br]
## Custom skills are tracked individually with exception of the custom skills
## registered on runtime with [method SkillCatalog.create_custom_skill] on the
## [code]NexusForge.Skills[/code] singleton which all SkillSets contain.
func create_custom(skill_id: StringName, value: int = 0) -> void:
	_custom_skills[skill_id] = value


## Gets the value of the custom skill [param skill_id].
func get_custom(skill_id: StringName) -> int:
	if _custom_skills.has(skill_id):
		return _custom_skills[skill_id]
	return 0


## Returns true if this SkillSet contains the custom skill [param skill_id].
func has_custom(skill_id: StringName) -> bool:
	return _custom_skills.has(skill_id)


## Removes a custom skill with ID [param skill_id]
func erase_custom(skill_id: StringName) -> void:
	_custom_skills.erase(skill_id)
