@tool
@icon("res://addons/nexus_forge/icons/star.svg")
class_name SkillCatalog
extends Resource
## A resource containing common data about skills and custom skills.
##
## Common data includes name, description and custom data for each skill.

## Emmited when a new custom skill is created.
signal custom_skill_created(id: StringName)
## Emmited when a custom skill is erased.
signal custom_skill_erased(id: StringName)


# Only accepts int, float, bool and string as values.
const DEFAULT_DATA: Dictionary[String, Variant] = {}

@export_storage var _skills: Dictionary[StringName, Dictionary] = {}

var _custom_skills: Dictionary[StringName, Dictionary] = {}


#region Custom skills
## Returns an array containing all the registered custom skills.
func custom_skills() -> Array[StringName]:
	var all_skills: Array[StringName] = []
	all_skills.assign(_custom_skills.keys())
	return all_skills


## Creates a custom skill with [param skill_id]. Creating a custom skill using
## this method will add it to all initialized and new [SkillSet] objects.
func create_custom_skill(skill_id: StringName) -> void:
	if _custom_skills.has(skill_id):
		return
	
	var skill_data: Dictionary[String, Variant] = {}
	skill_data.assign(DEFAULT_DATA)
	_skills[skill_id] = {
		"name": "",
		"description": "",
		"data": skill_data}
	
	custom_skill_created.emit(skill_id)


## Sets the name of a custom skill [param skill_id]
func set_custom_skill_name(skill_id: StringName, skill_name: String) -> void:
	if custom_skill_exists(skill_id):
		_skills[skill_id]["name"] = skill_name


## Returns the custom skill [param skill_id] name.
func get_custom_skill_name(skill_id: StringName) -> String:
	if _custom_skills.has(skill_id):
		return _custom_skills[skill_id]["name"]
	return ""


## Sets the custom skill [param skill_id] description.
func set_custom_skill_description(skill_id: StringName, skill_description: String) -> void:
	if _custom_skills.has(skill_id):
		_custom_skills[skill_id]["description"] = skill_description


## Returns the custom skill [param skill_id] description.
func get_custom_skill_description(skill_id: String) -> String:
	if _custom_skills.has(skill_id):
		return _custom_skills[skill_id]["description"]
	return ""


## Returns true if a custom skill with [param skill_id] exists.
func custom_skill_exists(skill_id: String) -> bool:
	return _skills.has(skill_id)


## Deletes the custom [param skill_id] if it exists.
func erase_custom_skill(skill_id: String) -> void:
	_skills.erase(skill_id)
	custom_skill_erased.emit(skill_id)


## Sets the value of [param data_id] on the custom skill [param skill_id].
func set_custom_skill_data(skill_id: StringName, data_key: String, data: Variant) -> void:
	if not custom_skill_exists(skill_id):
		return
	
	if data == null:
		if _custom_skills[skill_id]["data"].has(data_key):
			_custom_skills[skill_id]["data"].erase(data_key)
	else:
		_custom_skills[skill_id]["data"][data_key] = data


## Returns the value of [param data_id] on the custom skill [param skill_id].
func get_custom_skill_data(skill_id: StringName, data_id: String) -> Variant:
	if _custom_skills.has(skill_id) and _custom_skills[skill_id]["data"].has(data_id):
		return _custom_skills[skill_id]["data"][data_id]
	return null


## Returns if the custom [param skill_id] has data with key [param data_id].
func has_custom_skill_data(skill_id: StringName, data_id: String) -> bool:
	if _custom_skills.has(skill_id):
		return _custom_skills[skill_id]["data"].has(data_id)
	return false


## Clears all the custom data of custom skill [param skill_id]
func clear_custom_skill_data(skill_id: StringName) -> void:
	if _custom_skills.has(skill_id):
		_custom_skills[skill_id]["data"].clear()



## Returns all the data keys of the custom skill [param skill_id]
func custom_skill_data_keys(skill_id: StringName) -> Array[String]:
	var data_keys: Array[String] = []
	if _custom_skills.has(skill_id):
		data_keys.assign(_custom_skills[skill_id]["data"].keys())
	return data_keys


#endregion

#region Skills

## Returns all the skill IDs
func skills() -> Array[StringName]:
	return Array(_skills.keys(), TYPE_STRING_NAME, &"", null)


## Sets [param skill_id] name.
func set_skill_name(skill_id: StringName, skill_name: String) -> void:
	if _skills.has(skill_id):
		_skills[skill_id]["name"] = skill_name


## Returns the skill [param skill_id] name.
func get_skill_name(skill_id: StringName) -> String:
	if _skills.has(skill_id):
		return _skills[skill_id]["name"]
	return ""


## Sets [param skill_id] description.
func set_skill_description(skill_id: StringName, skill_description: String) -> void:
	if _skills.has(skill_id):
		_skills[skill_id]["description"] = skill_description


## Returns the skill [param skill_id] description.
func get_skill_description(skill_id: String) -> String:
	if _skills.has(skill_id):
		return _skills[skill_id]["description"]
	return ""


## Sets the value of [param data_id] on the skill [param skill_id].
func set_skill_data(skill_id: StringName, data_key: String, data: Variant) -> void:
	if not _skills.has(skill_id):
		return
	if data == null:
		if _skills[skill_id]["data"].has(data_key):
			_skills[skill_id]["data"].erase(data_key)
	else:
		_skills[skill_id]["data"][data_key] = data


## Returns the value of [param data_id] on the skill [param skill_id].
func get_skill_data(skill_id: StringName, data_id: String) -> Variant:
	if _skills.has(skill_id) and _skills[skill_id]["data"].has(data_id):
		return _skills[skill_id]["data"][data_id]
	return null


## Returns if the [param skill_id] has data with key [param data_id].
func has_skill_data(skill_id: StringName, data_id: String) -> bool:
	if _skills.has(skill_id):
		return _skills[skill_id]["data"].has(data_id)
	return false


## Returns all the data keys of skill [param skill_id]
func skill_data_keys(skill_id: StringName) -> Array[String]:
	var data_keys: Array[String] = []
	if _skills.has(skill_id):
		data_keys.assign(_skills[skill_id]["data"].keys())
	return data_keys


## Clears all the custom data of skill [param skill_id]
func clear_skill_data(skill_id: StringName) -> void:
	if _skills.has(skill_id):
		_skills[skill_id]["data"].clear()

#endregion
