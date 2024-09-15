class_name CharacterManager
extends Node
## A singleton in charge of tracking and loading _characters.
##
## This node provides methods to load and unload _characters to/from memory for
## quick access.

var _characters: Dictionary = {}


func get_character_data(character_id: StringName) -> CharacterDefinition:
	return _characters[character_id]["resource"]


## Returns if a charcter is registered in the database.
func character_exists(character_id: StringName) -> bool:
	return _characters.has(character_id)


## Returns true if the character data is loaded in memory and ready for access.
func is_character_loaded(character_id: StringName) -> bool:
	return _characters[character_id]["resource"] != null


## Registers a character resource to be accessed.
func register_character(character_res: CharacterDefinition) -> void:
	_characters[character_res.character_id] = {
		"path": character_res.resource_path,
		"resource": null
	}


## Loads a character data into memory. This includes things such as portraits,
## sounds, etc. Reccomended to only load what you need.
func load_character(character_id: StringName) -> void:
	if not character_exists(character_id):
		return
	_characters[character_id]["resource"] = load(_characters[character_id]["path"])


## Releases the reference of the resource of a character.
func unload_character(character_id: StringName) -> void:
	if not character_exists(character_id):
		return
	_characters[character_id]["resource"] = null


## Similar to [method load_character[] but can load more than 1 character at a time.
func load_characters(character_ids: Array) -> void:
	for character in character_ids:
		load_character(character)


## Similar to [method unload_character] but can unload more than 1 character at a
## time.
func unload_characters(character_ids: Array) -> void:
	for character in character_ids:
		unload_character(character)


## Releases all character references.
func unload_all_characters() -> void:
	unload_characters(_characters.keys())
