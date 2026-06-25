class_name NFSkillManager
extends RefCounted
## An object to keep track of skill's info and custom skills.
##
## This object can keep track skill data of base skills and custom ones. Data
## can be accessed directly by using the ID of the skill eg.[code]Skills.my_skill[/code].
## If the skill isn't registered a fallback object will be returned. You can
## call is_valid() to verify a skill validity as well as is_custom() to
## see if the skill isn't a basic one.


## Emmited when a new custom skill is created.
signal skill_created(id: StringName)
## Emmited when a custom skill is erased.
signal skill_erased(id: StringName)


var _skills: Dictionary[StringName, NFCatalogEntry] = {}
var _base_skills: Dictionary[StringName, Variant] = {}


func _init() -> void:
	for skill_id in SkillSet.skills():
		var base_entry: NFCatalogEntry = NFCatalogEntry.new()
		base_entry.name = String(skill_id)
		base_entry._flags = NFCatalogEntry._get_flags(true, false, true)
		_base_skills[skill_id] = null
		_skills[skill_id] = base_entry
		
	_base_skills.make_read_only()


func _get(property: StringName) -> Variant:
	if _skills.has(property):
		return _skills[property]
	var invalid: NFCatalogEntry = NFCatalogEntry.new()
	invalid._flags = NFCatalogEntry._get_flags(false, false, true)
	return invalid


## Loads a skill param catalog into this object. If param clear_skills
## is [code]true[/code] then previous skills data is cleared.
func load_catalog(catalog: SkillCatalog, clear_skills: bool = true) -> void:
	if clear_skills:
		for entry in _skills.keys():
			if _base_skills.has(entry):
				continue
			_skills.erase(entry)
	
	for skill in catalog.skills():
		var entry: NFCatalogEntry = NFCatalogEntry.new()
		entry.name = catalog.get_skill_name(skill)
		entry.description = catalog.get_skill_description(skill)
		entry.custom_data.assign(catalog.get_skill_custom_data(skill))
		entry._flags = NFCatalogEntry._get_flags(true, not _base_skills.has(skill), true)
		_skills[skill] = entry


## Returns all the IDs of the registered skills.
func skills() -> Array[StringName]:
	return ArrayUtils.create_typed(TYPE_STRING_NAME, _skills.keys())


## Creates a custom skill with [param skill_id]. Creating a custom skill using
## this method will add it to all initialized and new [SkillSet] objects.
func create_skill(skill_id: StringName) -> void:
	if _skills.has(skill_id):
		return
	
	var item: NFCatalogEntry = NFCatalogEntry.new()
	item.name = String(skill_id).capitalize()
	item._valid = true
	item._custom = true
	_skills[skill_id] = item
	
	skill_created.emit(skill_id)


## Returns wether a skill is a basic one or a custom one.
func is_base_skill(skill_id: StringName) -> bool:
	return _base_skills.has(skill_id)


## Sets the name of a custom skill [param skill_id]
func set_skill_name(skill_id: StringName, skill_name: String) -> void:
	if _skills.has(skill_id):
		_skills[skill_id].name = skill_name


## Returns the custom skill [param skill_id] name.
func get_skill_name(skill_id: StringName) -> String:
	if _skills.has(skill_id):
		return _skills[skill_id].name
	return ""


## Sets the custom skill [param skill_id] description.
func set_skill_description(skill_id: StringName, skill_description: String) -> void:
	if _skills.has(skill_id):
		_skills[skill_id].description = skill_description


## Returns the custom skill [param skill_id] description.
func get_skill_description(skill_id: String) -> String:
	if _skills.has(skill_id):
		return _skills[skill_id].description
	return ""


## Returns true if a custom skill with [param skill_id] exists.
func has_skill(skill_id: String) -> bool:
	return _skills.has(skill_id)


## Deletes the custom [param skill_id] if it exists.
func erase_skill(skill_id: String) -> void:
	if _base_skills.has(skill_id):
		NFPluginGameHandler._log_msg(
				"skills",
				"Erasing built-in skills is disallowed.",
				NFPluginGameHandler._LogLevel.WARNING)
		return
	
	if _skills.erase(skill_id):
		skill_erased.emit(skill_id)


## Sets the value of [param data_id] on the custom skill [param skill_id].
func set_skill_data(skill_id: StringName, data_key: String, data: Variant) -> void:
	if not _skills.has(skill_id):
		return
	
	if data == null:
		_skills[skill_id].custom_data.erase(data_key)
	else:
		_skills[skill_id].custom_data[data_key] = data


## Returns the value of [param data_id] on the custom skill [param skill_id].
func get_skill_data(skill_id: StringName, data_id: String) -> Variant:
	if _skills.has(skill_id) and _skills[skill_id].custom_data.has(data_id):
		return _skills[skill_id].custom_data[data_id]
	return null


## Returns if the custom [param skill_id] has data with key [param data_id].
func has_skill_data(skill_id: StringName, data_id: String) -> bool:
	if _skills.has(skill_id):
		return _skills[skill_id].custom_data.has(data_id)
	return false


## Clears all the custom data of custom skill [param skill_id]
func clear_skill_data(skill_id: StringName) -> void:
	if _skills.has(skill_id):
		_skills[skill_id].custom_data.clear()


## Returns all the data keys of the custom skill [param skill_id]
func skill_data_keys(skill_id: StringName) -> Array[String]:
	var data_keys: Array[String] = []
	if _skills.has(skill_id):
		data_keys.assign(_skills[skill_id].custom_data.keys())
	return data_keys


#endregion
