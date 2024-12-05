@tool
class_name NFCharacterDBRes
extends Resource


const SETTINGS_PATH: String = "nexus_forge/characters_resource"

@export var _characters: Dictionary = {}


func has_character(character_id: String) -> bool:
	return _characters.has(character_id)


func get_character(character_id: String) -> CharacterDefinition:
	return load(_characters[character_id])


func validate_characters() -> void:
	var invalid_chars: Dictionary = {}
	
	for character in _characters.keys():
		if not ResourceLoader.exists(_characters[character]):
			invalid_chars[character] = _characters[character]
			_characters.erase(character)
			continue
		
		var preload_res: Resource = load(_characters[character])
		
		if preload_res is not CharacterDefinition:
			invalid_chars[character] = _characters[character]
			_characters.erase(character)
			continue
	
	if not invalid_chars.is_empty():
		for invalid in invalid_chars:
			printerr(str("[CHARACTERS] Character \"", invalid, "\" was not found or not a CharacterDefinition: ", invalid_chars[invalid]))
		printerr("[CHARACTERS] Some characters were not found and have been removed")


func remove_character(character_id: String) -> void:
	_characters.erase(character_id)


func register_character(character_id: String, res_path: String) -> void:
	_characters[character_id] = res_path


func get_characters() -> Array:
	return _characters.keys()


func get_character_path(character_id: String) -> String:
	return _characters[character_id]


func save() -> void:
	var save_path: String = ProjectSettings.get_setting(SETTINGS_PATH, "res://character_database.tres")
	ResourceSaver.save(self, save_path)
