@tool
class_name NFFactionRes
extends Resource


enum FactionFlags {
	HIDDEN,
	CAN_JOIN
}

const SETTINGS_PATH: String = "nexus_forge/factions_resource"

@export var factions: Dictionary = {
	#"fac_id": {
		#"name": "",
		#"desc": "",
		#"flags": 0,
		#"ranks": {
			#"rank_id": {
				#"name": "",
				#"level": 0}
		#},
		#"allies": [],
		#"enemies": []
	#}
}


func create_faction(faction_id: String) -> void:
	factions[faction_id] = {
		"name": "",
		"desc": "",
		"flags": 0,
		"ranks": [],
		"allies": [],
		"enemies": []
	}


func delete_faction(faction_id: String) -> void:
	factions.erase(faction_id)
	for faction in factions:
		var ally_idx: int = faction[faction_id]["allies"].find(faction_id)
		var enemy_idx: int = faction[faction_id]["enemies"].find(faction_id)
		if ally_idx != -1:
			factions[faction_id]["allies"].remove_at(ally_idx)
		if enemy_idx != -1:
			factions[faction_id]["enemies"].remove_at(enemy_idx)


func get_factions() -> Array:
	return factions.keys()


func get_faction_name(faction_id: String) -> String:
	return factions[faction_id]["name"]


func get_faction_description(faction_id: String) -> String:
	return factions[faction_id]["desc"]


func get_faction_flags(faction_id: String) -> int:
	return factions[faction_id]["flags"]


func get_faction_ranks(faction_id: String) -> Array:
	var all_factions: Array = []
	for rank in factions[faction_id]["ranks"]:
		all_factions.append(rank["id"])
	return all_factions


func get_factions_relationships(faction_id: String) -> Dictionary:
	return {
		"allies": factions[faction_id]["allies"].duplicate(),
		"enemies": factions[faction_id]["enemies"].duplicate()}


func get_faction_relationship(faction: String, considers_faction: String) -> int:
	if factions[faction]["allies"].has(considers_faction):
		return 1
	elif factions[faction]["enemies"].has(considers_faction):
		return -1
	else:
		return 0


func set_faction_name(faction_id: String, faction_name: String) -> void:
	factions[faction_id]["name"] = faction_name


func set_faction_description(faction_id: String, faction_desc: String) -> void:
	factions[faction_id]["desc"] = faction_desc


func set_faction_flag(faction_id: String, faction_flag: int, is_enabled: bool) -> void:
	if is_enabled:
		factions[faction_id]["flags"] |= 1 << faction_flag
	else:
		factions[faction_id]["flags"] ^= 1 << faction_flag


func set_faction_flags(faction_id: String, flags: int) -> void:
	factions[faction_id]["flags"] = flags


func create_faction_rank(faction_id: String, faction_rank: String, faction_level: int) -> void:
	if 0 <= faction_level:
		factions[faction_id]["ranks"].insert(
				clampi(faction_level, 0, factions[faction_id]["ranks"].size()),
				{"id": faction_rank, "name": ""})
	else:
		factions[faction_id]["ranks"].append({"id": faction_rank})


func get_rank_level(faction: String, rank: String) -> int:
	for rank_idx in range(factions[faction]["ranks"].size()):
		if factions[faction]["ranks"][rank_idx]["id"] == rank:
			return rank_idx
	return -1


func get_rank_id(faction: String, rank: int) -> String:
	return factions[faction]["ranks"][rank]["id"]


func get_rank_name(faction: String, rank: int) -> String:
	return factions[faction]["ranks"][rank]["name"]


func set_faction_ally(faction_id: String, allied_faction: String) -> void:
	if not factions[faction_id]["allies"].has(allied_faction):
		factions[faction_id]["allies"].append(allied_faction)
	var enemy_idx: int = factions[faction_id]["enemies"].find(allied_faction)
	if enemy_idx != -1:
		factions[faction_id]["enemies"].remove_at(enemy_idx)


func set_faction_enemy(faction_id: String, enemy_faction: String) -> void:
	if not factions[faction_id]["enemies"].has(enemy_faction):
		factions[faction_id]["enemies"].append(enemy_faction)
	var ally_idx: int = factions[faction_id]["allies"].find(enemy_faction)
	if ally_idx != -1:
		factions[faction_id]["enemies"].remove_at(ally_idx)


func clear_allied_factions(faction_id: String) -> void:
	factions[faction_id]["allies"].clear()


func clear_enemy_factions(faction_id: String) -> void:
	factions[faction_id]["enemies"].clear()


func clear_faction_relationships(faction_id: String) -> void:
	clear_allied_factions(faction_id)
	clear_enemy_factions(faction_id)


func set_faction_rank_level(faction_id: String, faction_rank: String, faction_level: int) -> void:
	var from_idx: int = -1
	var to: int = clampi(faction_level, 0, factions[faction_id]["ranks"].size())
	
	for rank in range(factions[faction_id]["ranks"].size()):
		if factions[faction_id]["ranks"][rank]["id"] == faction_rank:
			from_idx = rank
			break
	
	if 0 <= from_idx:
		Arrays.move_item(
			factions[faction_id]["ranks"],
			from_idx,
			to)


func set_faction_rank_name(faction_id: String, rank: int, faction_name: String) -> void:
	#var rank_idx: int = get_rank_level(faction_id, faction_rank)
	factions[faction_id]["ranks"][rank]["name"] = faction_name


func has_faction(faction_id: String) -> bool:
	return factions.has(faction_id)


func has_rank(faction_id: String, rank_id: String) -> bool:
	for rank in factions[faction_id]["ranks"]:
		if rank["id"] == rank_id:
			return true
	return false


func is_rank(faction: String, rank: String, rank_level: int) -> bool:
	return factions[faction]["ranks"][rank_level]["id"] == rank


func save() -> void:
	var res_path: String = ProjectSettings.get_setting(SETTINGS_PATH, "res://factions_resource.tres")
	ResourceSaver.save(self, res_path)
	emit_changed()
