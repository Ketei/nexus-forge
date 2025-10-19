class_name CharacterCatalog
extends Resource
# Unused
var _characters: Dictionary[StringName, Dictionary] = {
	&"ketei": {
		"name": "",
		"type": &"", # Species ID
		"gender": 0,
		"data": {},
		"stats": {
			&"health": 10,
			&"stamina": 10},
		"custom_stats": {},
		"skills": {
			&"arcana": 10},
		"traits": {&"sunlight_sensitivity": 1} # trait: level
	}
}


func characters() -> Array[StringName]:
	var all_chars: Array[StringName] = []
	all_chars.assign(_characters.keys())
	return all_chars


func create_character(character_id: StringName) -> void:
	pass
