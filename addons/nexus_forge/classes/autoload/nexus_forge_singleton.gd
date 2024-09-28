class_name NFHandler
extends Node


var Variables: NFVariablesRes = null

var Races: NFRacesRes = null

var Characters: NFCharacterDBRes = null

var Factions: Resource = null


func _ready() -> void:
	var variables_path: String = ProjectSettings.get_setting("nexus_forge/variables/resource_path", "")
	var races_path: String = ProjectSettings.get_setting("nexus_forge/characters/races_resource", "")
	
	if not variables_path.is_empty() and ResourceLoader.exists(variables_path):
		var _preload: Resource = load(variables_path)
		if _preload is NFVariablesRes:
			Variables = _preload
	
	if not races_path.is_empty() and ResourceLoader.exists(races_path):
		var _preload: Resource = load(variables_path)
		if _preload is NFRacesRes:
			Races = _preload
