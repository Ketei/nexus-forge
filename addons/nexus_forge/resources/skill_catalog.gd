@tool
@icon("res://addons/nexus_forge/icons/star.svg")
class_name SkillCatalog
extends Resource
## A resource containing common data about skills and custom skills.
##
## Common data includes name, description and custom data for each skill.


@export_storage var _skill_data: Dictionary[StringName, Dictionary] = {}


## Returns all the IDs of the registered skills.
func skills() -> Array[StringName]:
	return Array(_skill_data.keys(), TYPE_STRING_NAME, &"", null)


## Creates a custom skill with [param skill_id]. Creating a custom skill using
## this method will add it to all initialized and new [SkillSet] objects.
func create_skill(skill_id: StringName) -> void:
	if _skill_data.has(skill_id):
		return
	
	var skill_data: Dictionary[String, Variant] = {
		"name": "",
		"description": "",
		"custom_data": DictUtils.create_typed(TYPE_STRING, TYPE_NIL)}
	
	_skill_data[skill_id] = skill_data


## Sets the name of a custom skill [param skill_id]
func set_skill_name(skill_id: StringName, skill_name: String) -> void:
	if _skill_data.has(skill_id):
		_skill_data[skill_id]["name"] = skill_name


## Returns the custom skill [param skill_id] name.
func get_skill_name(skill_id: StringName) -> String:
	return DictUtils.get_nested_value(
			_skill_data,
			[skill_id, "name"],
			"",
			true)


## Sets the custom skill [param skill_id] description.
func set_skill_description(skill_id: StringName, skill_description: String) -> void:
	if _skill_data.has(skill_id):
		_skill_data[skill_id]["description"] = skill_description


## Returns the custom skill [param skill_id] description.
func get_skill_description(skill_id: String) -> String:
	return DictUtils.get_nested_value(
			_skill_data,
			[skill_id, "description"],
			"",
			true)


## Returns true if a custom skill with [param skill_id] exists.
func has_skill(skill_id: String) -> bool:
	return _skill_data.has(skill_id)


## Deletes the custom [param skill_id] if it exists.
func erase_skill(skill_id: String) -> void:
	_skill_data.erase(skill_id)


## Sets the value of [param data_id] on the custom skill [param skill_id].
func set_skill_data(skill_id: StringName, data_key: String, data: Variant) -> void:
	if not _skill_data.has(skill_id):
		return
	
	if data == null:
		_skill_data[skill_id]["custom_data"].erase(data_key)
	else:
		_skill_data[skill_id]["custom_data"][data_key] = data


## Returns the value of [param data_id] on the custom skill [param skill_id].
func get_skill_data(skill_id: StringName, data_id: String) -> Variant:
	if _skill_data.has(skill_id) and _skill_data[skill_id]["custom_data"].has(data_id):
		return _skill_data[skill_id]["custom_data"][data_id]
	return null


func get_skill_custom_data(skill_id: StringName) -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = {}
	data.assign(DictUtils.get_nested_value(
			_skill_data,
			[skill_id, "custom_data"],
			{},
			true))
	return data


## Returns if the custom [param skill_id] has data with key [param data_id].
func has_skill_data(skill_id: StringName, data_id: String) -> bool:
	if _skill_data.has(skill_id):
		return _skill_data[skill_id]["custom_data"].has(data_id)
	return false


## Clears all the custom data of custom skill [param skill_id]
func clear_skill_data(skill_id: StringName) -> void:
	if _skill_data.has(skill_id):
		_skill_data[skill_id]["custom_data"].clear()


## Returns all the data keys of the custom skill [param skill_id]
func skill_data_keys(skill_id: StringName) -> Array[String]:
	var data_keys: Array[String] = []
	if _skill_data.has(skill_id):
		data_keys.assign(_skill_data[skill_id]["custom_data"].keys())
	return data_keys


#endregion
