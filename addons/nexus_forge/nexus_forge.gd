@tool
extends EditorPlugin


const MAIN_SCENE = preload("res://addons/nexus_forge/scenes/main/NexusForgeMainScene.tscn")
const PLUGIN_NAME: String = "NexusForge"
const PLUGIN_ICON_PATH: String = "res://addons/nexus_forge/common_icons/temp_icon.svg"

static var SINGLETONS: Dictionary = {
	"main": {"name": "NexusForge", "path": "res://addons/nexus_forge/classes/autoload/nexus_forge_singleton.gd"}
}

static var SETTINGS_PATHS: Dictionary = {
	"variables_resource": "",
	"races_resource": "",
	"characters_resource": "",
	"factions_resource": "",
	"talents_resource": ""
}

var editor_view: Control = null


func _enter_tree() -> void:
	editor_view = MAIN_SCENE.instantiate()
	editor_view.visible = false
	get_editor_interface().get_editor_main_screen().add_child(editor_view)


func _save_external_data() -> void:
	if editor_view:
		editor_view.save_resources()


func _has_main_screen() -> bool:
	return true


func _get_unsaved_status(for_scene: String) -> String:
	if for_scene.is_empty() and editor_view.has_unsaved_changes():
		return "Save changes in NexusForge before closing?"
	return ""


func _exit_tree() -> void:
	if editor_view:
		editor_view.queue_free()


func _get_plugin_icon() -> Texture2D:
	return load(PLUGIN_ICON_PATH)


func _get_plugin_name() -> String:
	return PLUGIN_NAME


func _make_visible(visible):
	if editor_view:
		editor_view.visible = visible


func _enable_plugin() -> void:
	for singleton in SINGLETONS:
		add_autoload_singleton(SINGLETONS[singleton]["name"], SINGLETONS[singleton]["path"])
	
	var trigger_setting_save: bool = false
	
	for category in SETTINGS_PATHS:
		var setting_path: String = str("nexus_forge/", category)
		if not ProjectSettings.has_setting(setting_path):
			ProjectSettings.set_setting(setting_path, SETTINGS_PATHS[category])
			ProjectSettings.set_initial_value(setting_path, SETTINGS_PATHS[category])
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
