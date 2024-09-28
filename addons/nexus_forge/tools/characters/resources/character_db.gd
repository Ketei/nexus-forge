class_name NFCharacterDBRes
extends Resource


const RES_PATH_SETTING: String = "nexus_forge/characters/resource_path"

@export var _characters: Dictionary = {}


func has_character(character_id: StringName) -> bool:
	return _characters.has(character_id)


func get_character(character_id: StringName) -> CharacterDefinition:
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


func set_character(character_id: StringName, res_path: String) -> void:
	_characters[character_id] = res_path


func save() -> void:
	var save_path: String = ProjectSettings.get_setting(RES_PATH_SETTING, "")
	if save_path.is_empty():
		save_path = "res://character_database.tres"
	ResourceSaver.save(self, save_path)
