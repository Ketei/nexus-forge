class_name NFFactionRes
extends Resource


enum FactionRelation {
	NEUTRAL,
	ALLY,
	ENEMY,
}

enum FactionFlags {
	HIDDEN,
	CAN_JOIN
}

const FACTIONS_RESOURCE_PATH: String = "nexus_forge/factions_resource"

var factions: Dictionary = {
	"fac_id": {
		"name": "",
		"desc": "",
		"flags": 0,
		"ranks": {
			"rank_id": {
				"name": "",
				"level": 0}
		},
		"relationship": {},
	}
}


func create_faction(faction_id: String) -> void:
	factions[faction_id] = {
		"name": "",
		"desc": "",
		"flags": 0,
		"ranks": {},
		"relationship": {}
	}


func delete_faction(faction_id: String) -> void:
	factions.erase(faction_id)


func get_factions() -> Array:
	return factions.keys()


func get_faction_name(faction_id: String) -> String:
	return factions[faction_id]["name"]


func get_faction_description(faction_id: String) -> String:
	return factions[faction_id]["desc"]


func get_faction_flags(faction_id: String) -> int:
	return factions[faction_id]["flags"]


func get_faction_ranks(faction_id: String) -> Dictionary:
	return factions[faction_id]["ranks"]


func get_factions_relationships(faction_id: String) -> Dictionary:
	return factions[faction_id]["relationship"]


func set_faction_name(faction_id: String, faction_name: String) -> void:
	factions[faction_id]["name"] = faction_name


func set_faction_description(faction_id: String, faction_desc: String) -> void:
	factions[faction_id]["desc"] = faction_desc


func set_faction_flag(faction_id: String, faction_flag: int, is_enabled: bool) -> void:
	if is_enabled:
		factions[faction_id]["flags"] |= 1 << faction_flag
	else:
		factions[faction_id]["flags"] ^= 1 << faction_flag


func create_faction_rank(faction_id: String, faction_rank: String, faction_level: int) -> void:
	factions[faction_id]["ranks"][faction_id] = {
		"name": "",
		"level": faction_level}


func set_faction_rank_level(faction_id: String, faction_rank: String, faction_level: int) -> void:
	factions[faction_id]["ranks"][faction_id]["level"] = faction_level


func set_faction_rank_name(faction_id: String, faction_rank: String, faction_name: String) -> void:
	factions[faction_id]["ranks"][faction_id]["name"] = faction_name


func set_faction_relationship(faction: String, considers_faction: String, relationship: FactionRelation) -> void:
	factions[faction]["relationship"][considers_faction] = relationship


func has_faction(faction_id: String) -> bool:
	return factions.has(faction_id)


func has_rank(faction_id: String, rank_id: String) -> bool:
	return factions[faction_id]["ranks"].has(rank_id)


func save() -> void:
	var res_path: String = ProjectSettings.get_setting(FACTIONS_RESOURCE_PATH, "res://factions_resource.tres")
	ResourceSaver.save(self, res_path)
