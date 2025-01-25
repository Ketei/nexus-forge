@tool
class_name NFTalentsRes
extends Resource


signal skill_created(skill_id: String)
signal skill_deleted(skill_id: String)
signal skill_edited(skill_id: String)
signal skill_data_changed(skill_id: String, data_key: String)

const SETTINGS_PATH: String = "nexus_forge/talents_resource"

@export var _skill_data: Dictionary = {}

#@export var perks: Dictionary = {
	#"perk_id": {
		#"name": "",
		#"desc": "",
		#"levels": 2,
		#"requirements": [
			#{ # IDX 0, requirements for level 1. Since it has none it's free
				#"values": {},
				#"perks": {},
				#"variables": {}
			#},
			#{ # This is idx 1, so it's for the level 2 perk
				#"values": {
					#"hp": {
						#"value": 100,
						#"match": OperatorValue.EQUAL_OR_MORE},
					#"mp": {
						#"value": 100,
						#"match": OperatorValue.LESS_THAN
					#}
				#},
				#"perks": {
					#"perk_id": {
						#"level": 1,
						#"match": OperatorValue.EQUAL
					#}, # This means it must have it on the first level
					#"perk_id2": {
						#"level": 1,
						#"match": OperatorValue.LESS_THAN # OperatorValue.EQUAL with 0 works too
					#} # This means it must NOT have it.
				#},
				#"variables": {
					#"path": {
						#"value": 69.69,
						#"match": OperatorValue.EQUAL
					#}
				#}
			#},
		#]
	#}
#}

#region Skills

## Creates a skill with [param skill_id], if the skill exists it gets overwritten.
func create_skill(skill_id: String, skill_name: String = "", description: String = "", starting_val: int = 0, skill_limit: int = 1) -> void:
	var limit: int = maxi(0, skill_limit)
	_skill_data[skill_id] = {
		"name": skill_name,
		"description": description,
		"starting_value": clampi(starting_val, 0, limit),
		"limit": limit,
		"data": {}}
	skill_created.emit(skill_id)


## Returns true if a skill with [param skill_id] exists.
func skill_exists(skill_id: String) -> bool:
	return _skill_data.has(skill_id)


## Deletes skill_id if it exists.
func erase_skill(skill_id: String) -> void:
	_skill_data.erase(skill_id)
	skill_deleted.emit()


## Returns all the skill IDs
func get_skills() -> PackedStringArray:
	return PackedStringArray(_skill_data.keys())


## Sets [param skill_id] name.
func set_skill_name(skill_id: String, skill_name: String) -> void:
	_skill_data[skill_id]["name"] = skill_name
	skill_edited.emit(skill_id)


## Returns the skill [param skill_id] name.
func get_skill_name(skill_id: String) -> String:
	return _skill_data[skill_id]["name"]


## Sets [param skill_id] description.
func set_skill_description(skill_id: String, skill_description: String) -> void:
	_skill_data[skill_id]["description"] = skill_description
	skill_edited.emit(skill_id)


## Returns the skill [param skill_id] description.
func get_skill_description(skill_id: String) -> String:
	return _skill_data[skill_id]["description"]


## Sets [param skill_id] starting value.
func set_skill_starting_value(skill_id: String, starting_value: int) -> void:
	_skill_data[skill_id]["starting_value"] = mini(
			starting_value, _skill_data[skill_id]["limit"])
	skill_edited.emit(skill_id)


## Returns the skill [param skill_id] initial value.
func get_skill_starting_value(skill_id: String) -> int:
	return _skill_data[skill_id]["starting_value"]


## Sets [param skill_id] max value.
func set_skill_limit(skill_id: String, limit: int) -> void:
	_skill_data[skill_id]["limit"] = maxi(0, limit)
	skill_edited.emit(skill_id)


## Returns the skill [param skill_id] max value.
func get_skill_limit(skill_id: String) -> int:
	return _skill_data[skill_id]["limit"]


## Sets the value of [param data_id] on the skill [param skill_id].
func set_skill_data(skill_id: String, data_id: String, data: Variant) -> void:
	_skill_data[skill_id]["data"][data_id] = data
	skill_data_changed.emit(skill_id, data_id)


## Returns the value of [param data_id] on the skill [param skill_id].
func get_skill_data(skill_id: String, data_id: String) -> Variant:
	return _skill_data[skill_id]["data"][data_id]


## Returns if the [param skill_id] has data with key [param data_id].
func has_skill_data(skill_id: String, data_id: String) -> bool:
	if _skill_data.has(skill_id):
		return _skill_data[skill_id]["data"].has(data_id)
	return false


func get_skill_data_keys(skill_id: String) -> PackedStringArray:
	return PackedStringArray(_skill_data[skill_id]["data"].keys())

#endregion


func _save() -> void:
	var path: String = ProjectSettings.get_setting(SETTINGS_PATH, "res://talents_resource.tres")
	ResourceSaver.save(self, path)
	emit_changed()
