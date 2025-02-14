@tool
extends EditorPlugin


const MAIN_SCENE = preload("res://addons/nexus_forge/scenes/NexusForgeMainScene.tscn")
const PLUGIN_NAME: String = "NexusForge"
const PLUGIN_ICON_PATH: String = "res://addons/nexus_forge/common_icons/temp_icon.svg"

static var SINGLETONS: Dictionary = {
	"main": {"name": "NexusForge", "path": "res://addons/nexus_forge/classes/autoload/nexus_forge_singleton.gd"}
}


var editor_view: Control = null


func _enter_tree() -> void:
	editor_view = MAIN_SCENE.instantiate()
	editor_view.visible = false
	get_editor_interface().get_editor_main_screen().add_child(editor_view)
	editor_view.init_load_splash()


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
	
	if not ProjectSettings.has_setting(NFFactionRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFFactionRes.SETTINGS_PATH, "")
		ProjectSettings.set_initial_value(NFFactionRes.SETTINGS_PATH, "")
	
	if not ProjectSettings.has_setting(NFRacesRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFRacesRes.SETTINGS_PATH, "")
		ProjectSettings.set_initial_value(NFRacesRes.SETTINGS_PATH, "")
	
	if not ProjectSettings.has_setting(NFTalentsRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFTalentsRes.SETTINGS_PATH, "")
		ProjectSettings.set_initial_value(NFTalentsRes.SETTINGS_PATH, "")
	
	if not ProjectSettings.has_setting(NFItemsRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFItemsRes.SETTINGS_PATH, "")
		ProjectSettings.set_initial_value(NFItemsRes.SETTINGS_PATH, "")
	
	if not ProjectSettings.has_setting(NFQuestRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFQuestRes.SETTINGS_PATH, "")
		ProjectSettings.set_initial_value(NFQuestRes.SETTINGS_PATH, "")
	
	if not ProjectSettings.has_setting(NFCharacterDBRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFCharacterDBRes.SETTINGS_PATH, "")
		ProjectSettings.set_initial_value(NFCharacterDBRes.SETTINGS_PATH, "")
	
	if not ProjectSettings.has_setting(NFVariablesRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFVariablesRes.SETTINGS_PATH, "")
		ProjectSettings.set_initial_value(NFVariablesRes.SETTINGS_PATH, "")
	
	ProjectSettings.save()


func _disable_plugin() -> void:
	for singleton in SINGLETONS:
		remove_autoload_singleton(SINGLETONS[singleton]["name"])
	
	if ProjectSettings.has_setting(NFFactionRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFFactionRes.SETTINGS_PATH, null)
	if ProjectSettings.has_setting(NFRacesRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFRacesRes.SETTINGS_PATH, null)
	if ProjectSettings.has_setting(NFTalentsRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFTalentsRes.SETTINGS_PATH, null)
	if ProjectSettings.has_setting(NFItemsRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFItemsRes.SETTINGS_PATH, null)
	if ProjectSettings.has_setting(NFQuestRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFQuestRes.SETTINGS_PATH, null)
	if ProjectSettings.has_setting(NFCharacterDBRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFCharacterDBRes.SETTINGS_PATH, null)
	if ProjectSettings.has_setting(NFVariablesRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFVariablesRes.SETTINGS_PATH, null)
	
	ProjectSettings.save()
