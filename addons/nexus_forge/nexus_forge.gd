@tool
extends EditorPlugin

static var SINGLETONS: Dictionary = {
	"chars": {"name": "Characters", "path": "res://addons/nexus_forge/tools/discourse/scripts/singleton/character_manager.gd"},
	"vars": {"name": "Variables", "path": "res://addons/nexus_forge/tools/discourse/scripts/singleton/variables.gd"}
}


func _enter_tree() -> void:
	for singleton in SINGLETONS:
		add_autoload_singleton(SINGLETONS[singleton]["name"], SINGLETONS[singleton]["path"])


func _exit_tree() -> void:
	for singleton in SINGLETONS:
		remove_autoload_singleton(SINGLETONS[singleton]["name"])
		
