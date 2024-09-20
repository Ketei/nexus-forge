class_name NexusForgeHandler
extends Node


var Variables: NexusForgeVariables = null




func _ready() -> void:
	var variables_path: String = ProjectSettings.get_setting("nexus_forge/variables/resource_path", "")
	
	if variables_path.is_empty():
		Variables = NexusForgeVariables.new()
	else:
		var _preload: Resource = load(variables_path)
		if _preload is NexusForgeVariables:
			Variables = _preload
		else:
			Variables = NexusForgeVariables.new()
