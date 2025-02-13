@tool
class_name NFCharacterDBRes
extends Resource


const SETTINGS_PATH: String = "nexus_forge/characters_resource"

@export var _characters: Dictionary = {}

var genders: Dictionary = {
	"male": {"name": "Male", "data": {}},
	"female": {"name": "Female", "data": {}},
}


func create_character(character_id: String) -> void:
	_characters[character_id] = {
		"name": "",
		"color": Color.WHITE,
		"species": "",
		"race": "",
		"gender": "",
		"factions": {},
		"skills": {},
		"variants": {},
		"data": {}}


func has_character(character_id: String) -> bool:
	return _characters.has(character_id)


func get_characters() -> PackedStringArray:
	return PackedStringArray(_characters.keys())


func erase_character(character_id: String) -> void:
	_characters.erase(character_id)


func set_character_name(character_id: String, new_name: String) -> void:
	_characters[character_id]["name"] = new_name


func get_character_name(character_id: String) -> String:
	return _characters[character_id]["name"]


func get_character_color(character_id: String) -> Color:
	return _characters[character_id]["color"]


func set_character_color(character_id: String, color: Color) -> void:
	_characters[character_id]["color"] = color


func get_character_species(character_id: String) -> String:
	return _characters[character_id]["species"]


func set_character_species(character_id: String, species: String) -> void:
	_characters[character_id]["species"] = species


func get_character_race(character_id: String) -> String:
	return _characters[character_id]["race"]


func set_character_race(character_id: String, race: String) -> void:
	_characters[character_id]["race"] = race


# Gender functions
func get_genders() -> PackedStringArray:
	return PackedStringArray(genders.keys())


func get_gender_name(gender_id: String) -> String:
	return genders[gender_id]["name"]


func set_gender_name(gender_id: String) -> void:
	genders[gender_id]["name"] = gender_id


func create_gender(gender_id: String) -> void:
	genders[gender_id] = {"name": "", "data": {}}


func has_gender(gender_id: String) -> void:
	return genders.has(gender_id)


func erase_gender(gender_id: String) -> void:
	genders.erase(gender_id)
 

func set_gender_data(gender_id: String, data_key: String, data: Variant) -> void:
	genders[gender_id]["data"][data_key] = data


func get_gender_data(gender_id: String, data_key: String) -> Variant:
	return genders[gender_id]["data"][data_key]


func has_gender_data(gender_id: String, data_key: String) -> bool:
	return genders[gender_id]["data"].has(data_key)


func erase_gender_data(gender_id: String, data_key: String) -> void:
	genders[gender_id]["data"].erase(data_key)


func set_character_gender(character_id: String, gender_id: String) -> void:
	_characters[character_id]["gender"] = gender_id


func get_character_gender(character_id: String) -> String:
	return _characters[character_id]["gender"]


# Factions functions
func get_character_factions(character_id: String) -> PackedStringArray:
	return PackedStringArray(_characters[character_id]["factions"].keys())


func get_character_faction_rank(character_id: String, faction_id: String) -> int:
	return _characters[character_id]["factions"][faction_id]


func set_character_faction_rank(character_id: String, faction_id: String, rank: int):
	_characters[character_id]["factions"][faction_id] = rank


func has_character_faction(character_id: String, faction_id: String) -> bool:
	return _characters[character_id]["factions"].has(faction_id)


# Skills functions
func get_character_skills(character_id: String) -> PackedStringArray:
	return PackedStringArray(_characters[character_id]["skills"].keys())


func get_character_skill_level(character_id: String, skill_id: String) -> int:
	return _characters[character_id]["skills"][skill_id]


func set_character_skill_level(character_id: String, skill_id: String, level: int):
	_characters[character_id]["skills"][skill_id] = level


func has_character_skill(character_id: String, skill_id: String) -> bool:
	return _characters[character_id]["skills"].has(skill_id)


# Data functions
func get_character_data_keys(character_id: String) -> PackedStringArray:
	return PackedStringArray(_characters[character_id]["data"].keys())


func get_character_data(character_id: String, data_key: String) -> Variant:
	return _characters[character_id]["data"][data_key]


func set_character_data(character_id: String, data_key: String, value: Variant):
	_characters[character_id]["data"][data_key] = value


func has_character_data(character_id: String, data_key: String) -> bool:
	return _characters[character_id]["data"].has(data_key)


# Variants functions
func create_character_variant(character_id: String, variant_id: String) -> void:
	_characters[character_id]["variants"][variant_id] = {}


func has_character_variant(character_id: String, variant_id: String) -> bool:
	return _characters[character_id]["variants"].has(variant_id)


func erase_character_variant(character_id: String, variant_id: String) -> void:
	_characters[character_id]["variants"].erase(variant_id)


func get_character_variants(character_id: String) -> PackedStringArray:
	return PackedStringArray(_characters[character_id]["variants"].keys())


func get_character_variant_data(character_id: String, variant_id: String, variant_data_key: String) -> Variant:
	return _characters[character_id]["variants"][variant_id][variant_data_key]


func set_character_variant_data(character_id: String, variant_id: String, variant_data_key: String, value: Variant):
	_characters[character_id]["variants"][variant_id][variant_data_key] = value


func get_character_variant_data_keys(character_id: String, variant_id: String) -> PackedStringArray:
	return PackedStringArray(_characters[character_id]["variants"][variant_id].keys())


func erase_character_variant_data(character_id: String, variant_id: String, variant_data_key: String) -> void:
	_characters[character_id]["variants"][variant_id].erase(variant_data_key)


func save() -> void:
	var save_path: String = ProjectSettings.get_setting(SETTINGS_PATH, "res://character_database.tres")
	ResourceSaver.save(self, save_path)
