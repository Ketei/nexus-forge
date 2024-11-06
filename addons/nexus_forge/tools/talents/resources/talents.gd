@tool
class_name NFTalentsRes
extends Resource


enum PerkFlags {
	UNIQUE_BRANCHING,
	REQUIRE_PARENTS,
}


enum OperatorValue {
	EQUAL = 1,
	NOT = 2,
	LESS_THAN = 4,
	MORE_THAN = 8,
	EQUAL_OR_LESS = 5,
	EQUAL_OR_MORE = 9, 
}


const SETTINGS_PATH: String = "nexus_forge/talents_resource"


@export var skills: Dictionary = {
	#"skill_id": {
		#"name": "Test skill",
		#"icon": "path",
		#"limit": 100,
		#"desc": ""
	#}
}
@export var perks: Dictionary = {
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
}



func create_skill(skill_id: String, name: String = "", desc: String = "", limit: int = 1, icon: String = "") -> void:
	skills[skill_id] = {
		"name": name,
		"icon": icon,
		"limit": maxi(1, limit),
		"desc": desc
		}


func set_skill_name(skill_id: String, skill_name: String) -> void:
	skills[skill_id]["name"] = skill_name


func set_skill_icon_path(skill_id: String, icon_path: String) -> void:
	skills[skill_id]["icon"] = icon_path


func set_skill_desc(skill_id: String, skill_desc: String) -> void:
	skills[skill_id]["desc"] = skill_desc


func set_skill_limit(skill_id: String, skill_limit: int) -> void:
	skills[skill_id]["limit"] = skill_limit


func create_perk(perk_id: String, name: String = "", desc: String = "", levels: int = 1, flags: int = 0) -> void:
	perks[perk_id] = {
		"name": name,
		"desc": desc,
		"flags": flags,
		"levels": 0,
		"requirements": []}
	set_perk_levels(perk_id, levels)


func has_perk(perk_id: String) -> bool:
	return perks.has(perk_id)


func get_perks() -> Array:
	return perks.keys()


func erase_perk(perk_id: String) -> void:
	perks.erase(perk_id)


func get_perk_requirements(perk_id: String, level: int) -> Dictionary:
	return perks[perk_id]["requirements"][level].duplicate(true)


func get_perk_name(perk_id: String) -> String:
	return perks[perk_id]["name"]


func get_perk_desc(perk_id: String) -> String:
	return perks[perk_id]["desc"]


func get_perk_flags(perk_id: String) -> int:
	return perks[perk_id]["flags"]


func get_perk_level(perk_id: String) -> int:
	return perks[perk_id]["levels"]


func set_perk_name(perk_id: String, perk_name: String) -> void:
	perks[perk_id]["name"] = perk_name


func set_perk_desc(perk_id: String, perk_desc: String) -> void:
	perks[perk_id]["desc"] = perk_desc


func set_perk_flags(perk_id: String, perk_flags: int) -> void:
	perks[perk_id]["flags"] = perk_flags


func set_perk_levels(perk_id: String, perk_levels: int) -> void:
	perks[perk_id]["levels"] = maxi(1, perk_levels)
	perks[perk_id]["requirements"].resize(perks[perk_id]["levels"])
	for idx in range(perks[perk_id]["levels"]):
		if typeof(perks[perk_id]["requirements"][idx]) != TYPE_DICTIONARY:
			perks[perk_id]["requirements"][idx] = get_perk_req_structure()


func set_perk_value_requirement(perk_id: String, perk_level: int, id: String, value: int, operator: int) -> void:
	perks[perk_id]["requirements"][perk_level]["values"][id] = {
		"value": value,
		"match": operator}


func set_perk_perk_requirement(perk_id: String, perk_level: int, req_perk: String, level: int, operator: int) -> void:
	perks[perk_id]["requirements"][perk_level]["perks"][req_perk] = {
		"level": level,
		"match": operator}


func set_perk_var_requirement(perk_id: String, perk_level: int, var_id: String, value: Variant, operator: int) -> void:
	perks[perk_id]["requirements"][perk_level]["variables"][var_id] = {
		"value": value,
		"operator": operator}


func clear_perk_value_requirements(perk: String, level: int) -> void:
	perks[perk]["requirements"][level]["stats"].clear()


func clear_perk_perks_requirements(perk: String, level: int) -> void:
	perks[perk]["requirements"][level]["perks"].clear()


func clear_perk_var_requirements(perk: String, level: int) -> void:
	perks[perk]["requirements"][level]["variables"].clear()


func clear_perk_level_requirements(perk: String, level: int) -> void:
	clear_perk_value_requirements(perk, level)
	clear_perk_perks_requirements(perk, level)
	clear_perk_var_requirements(perk, level)


func erase_skill(skill_id: String) -> void:
	skills.erase(skill_id)


func has_skill(skill_id: String) -> bool:
	return skills.has(skill_id)


func get_skills() -> Array:
	return skills.keys()


func get_skill_name(skill_id: String) -> String:
	return skills[skill_id]["name"]


func get_skill_icon_path(skill_id: String) -> String:
	return skills[skill_id]["icon"]


func get_skill_desc(skill_id: String) -> String:
	return skills[skill_id]["desc"]


func get_skill_limit(skill_id: String) -> int:
	return skills[skill_id]["limit"]


func get_perk_req_structure() -> Dictionary:
	return {
		"values": {},
		"perks": {},
		"variables": {}
	}


func save() -> void:
	var path: String = ProjectSettings.get_setting(SETTINGS_PATH, "res://talents_resource.tres")
	ResourceSaver.save(self, path)
	emit_changed()
