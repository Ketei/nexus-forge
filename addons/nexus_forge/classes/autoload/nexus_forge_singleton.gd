class_name NexusForgeHandler
extends Node


var Variables: NexusForgeVariables = null

var Races: NexusForgeRaces = null

var Characters: NexusForgeCharacterDatabase = null

var Factions: Resource = null


func _ready() -> void:
	var variables_path: String = ProjectSettings.get_setting("nexus_forge/variables/resource_path", "")
	var races_path: String = ProjectSettings.get_setting("nexus_forge/characters/races_resource", "")
	
	if not variables_path.is_empty():
		var _preload: Resource = load(variables_path)
		if _preload is NexusForgeVariables:
			Variables = _preload
		else:
			Variables = NexusForgeVariables.new()
	
	if not races_path.is_empty():
		var _preload: Resource = load(variables_path)
		if _preload is NexusForgeRaces:
			Races = _preload
		else:
			Races = NexusForgeRaces.new()
