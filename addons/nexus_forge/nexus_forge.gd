@tool
extends EditorPlugin

static var SINGLETONS: Dictionary = {
	"main": {"name": "NexusForge", "path": "res://addons/nexus_forge/classes/autoload/nexus_forge_singleton.gd"}
}

static var SETTINGS_PATHS: Dictionary = {
	"variables": [{"path": "resource_path", "default": ""}]
}


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass


func _enable_plugin() -> void:
	for singleton in SINGLETONS:
		add_autoload_singleton(SINGLETONS[singleton]["name"], SINGLETONS[singleton]["path"])
	
	var trigger_setting_save: bool = false
	
	for category in SETTINGS_PATHS:
		for setting in SETTINGS_PATHS[category]:
			var setting_path: String = str(category, "/", setting["path"])
			if not ProjectSettings.has_setting(setting_path):
				ProjectSettings.set_setting(setting_path, setting["default"])
				ProjectSettings.set_initial_value(setting_path, setting["default"])
				if not trigger_setting_save:
					trigger_setting_save = true
	
	if trigger_setting_save:
		ProjectSettings.save()


func _disable_plugin() -> void:
	for singleton in SINGLETONS:
		remove_autoload_singleton(SINGLETONS[singleton]["name"])
	
	var trigger_setting_save: bool = false
	for category in SETTINGS_PATHS:
		for setting in SETTINGS_PATHS[category]:
			var setting_path: String = str(category, "/", setting["path"])
			if ProjectSettings.has_setting(setting_path):
				ProjectSettings.set_setting(setting_path, null)
				if not trigger_setting_save:
					trigger_setting_save = true
	if trigger_setting_save:
		ProjectSettings.save()
