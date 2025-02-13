@tool
class_name NFFactionRes
extends Resource

const SETTINGS_PATH: String = "nexus_forge/factions_resource"

@export var factions: Dictionary = {
	#"fac_id": {
		#"name": "",
		#"relations": {"fac_id": 0/1/-1},
		#"ranks": [
			#{"name": "Junior", "data": {}],
		#"data": {},
	#}
}


func create_faction(faction_id: String) -> void:
	factions[faction_id] = {
		"name": "",
		"relations": {},
		"ranks": Array([], TYPE_DICTIONARY, &"", null),
		"data": {}}


func faction_exists(faction_id: String) -> bool:
	return factions.has(faction_id)


func erase_faction(faction_id: String) -> void:
	factions.erase(faction_id)
	for faction in factions:
		if faction["relations"].has(faction_id):
			faction["relations"].erase(faction_id)


func set_faction_data(faction_id: String, data_key: String, data: Variant) -> void:
	factions[faction_id]["data"][data_key] = data


func get_faction_data(faction_id: String, data_key: String) -> Variant:
	return factions[faction_id]["data"][data_key]


func has_faction_data(faction_id: String, data_key: String) -> bool:
	return factions[faction_id]["data"].has(data_key)


func get_faction_data_keys(faction_id: String) -> PackedStringArray:
	return PackedStringArray(factions[faction_id]["data"].keys())


func erase_faction_data(faction_id: String, data_key: String) -> void:
	factions[faction_id]["data"].erase(data_key)


func get_factions() -> PackedStringArray:
	return PackedStringArray(factions.keys())


func get_faction_name(faction_id: String) -> String:
	return factions[faction_id]["name"]


func get_faction_rank_count(faction_id) -> int:
	return factions[faction_id]["ranks"].size()


func get_faction_relationship(faction: String, with: String) -> int:
	if factions[faction]["relations"].has(with):
		return factions[faction]["relations"][with]
	return 0


func set_faction_name(faction_id: String, faction_name: String) -> void:
	factions[faction_id]["name"] = faction_name


func create_faction_rank(faction_id: String, rank_name: String, rank_idx: int = -1) -> void:
	if 0 <= rank_idx:
		factions[faction_id]["ranks"].insert(
				rank_idx,
				{"name": rank_name, "data": {}})
	else:
		factions[faction_id]["ranks"].append({"name": rank_name, "data":{}})


func erase_faction_rank(faction_id: String, rank_idx: int) -> void:
	factions[faction_id]["ranks"].remove_at(rank_idx)


func has_faction_rank(faction_id: String, rank: int) -> bool:
	return rank <= factions[faction_id]["ranks"].size() and 0 <= rank


func get_rank_name(faction: String, rank: int) -> String:
	return factions[faction]["ranks"][rank]["name"]


func set_rank_data(faction: String, rank: int, data_key: String, data: Variant) -> void:
	factions[faction]["ranks"][rank]["data"][data_key] = data


func get_rank_data(faction: String, rank: int, data_key: String) -> Variant:
	if factions[faction]["ranks"][rank]["data"].has(data_key):
		return factions[faction]["ranks"][rank]["data"][data_key]
	return null


func has_rank_data(faction: String, rank: int, data_key: String) -> Variant:
	return factions[faction]["ranks"][rank]["data"].has(data_key)


func erase_rank_data(faction: String, rank: int, data_key: String) -> void:
	factions[faction]["ranks"][rank]["data"].erase(data_key)


func get_rank_data_keys(faction: String, rank: int) -> PackedStringArray:
	return PackedStringArray(factions[faction]["ranks"][rank]["data"].keys())


func clear_faction_relationships(faction_id: String) -> void:
	factions[faction_id]["relations"].clear()


func save() -> void:
	var res_path: String = ProjectSettings.get_setting(SETTINGS_PATH, "res://factions_resource.tres")
	ResourceSaver.save(self, res_path)
	emit_changed()
