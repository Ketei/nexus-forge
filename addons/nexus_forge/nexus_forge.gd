@tool
class_name EditorNFPlugin
extends EditorPlugin


const MAIN_SCENE = preload("res://addons/nexus_forge/NexusForgeMainScene.tscn")
const PLUGIN_NAME: String = "NexusForge"
const PLUGIN_ICON_PATH: String = "res://addons/nexus_forge/common_icons/temp_icon.svg"
# Setting_path: default_value
const SETTINGS_PATHS: Array[Dictionary] = [
	{"module": "discourse", "setting_path": "nexus_forge/localization_directory", "default_value": "res://localization/"},
	{"module": "variables", "setting_path": "nexus_forge/variables_resource", "default_value": ""},
	{"module": "stats", "setting_path": "nexus_forge/stats_resource", "default_value": ""},
	{"module": "traits", "setting_path": "nexus_forge/traits_resource", "default_value": ""},
	{"module": "skills", "setting_path": "nexus_forge/skills_resource", "default_value": ""},
	{"module": "quests", "setting_path": "nexus_forge/quests_resource", "default_value": ""},
	{"module": "species", "setting_path": "nexus_forge/species_resource", "default_value": ""},
	{"module": "characters", "setting_path": "nexus_forge/characters_resource", "default_value": ""},
	{"module": "items", "setting_path": "nexus_forge/items_resource", "default_value": ""},
	{"module": "currency", "setting_path": "nexus_forge/currency_resource", "default_value": ""},
	{"module": "recipes", "setting_path": "nexus_forge/recipes_resource", "default_value": ""},
]


static func get_project_settings_path(module: String) -> String:
	for setting in SETTINGS_PATHS:
		if setting["module"] == module:
			return setting["setting_path"]
	return ""

var editor_view: Control = null
var export_plugin: EditorExportPlugin = null


func _enter_tree() -> void:
	editor_view = MAIN_SCENE.instantiate()
	editor_view.visible = false
	export_plugin = preload("res://addons/nexus_forge/export_plugin.gd").new()
	get_editor_interface().get_editor_main_screen().add_child(editor_view)
	editor_view.init_load_splash()
	var new_export: EditorExportPlugin = EditorExportPlugin.new()
	add_export_plugin(export_plugin)


func _build() -> bool:
	var path: String = ProjectSettings.get_setting(
			get_project_settings_path("discourse")).strip_edges()
	
	var valid_path: bool = path != "" and path.is_valid_filename() and path.begins_with("res://") and path.get_extension() == ""
	
	if not valid_path:
		printerr("[ERROR] NexusForge: Discourse needs a valid folder path for localization files on project settings.")
	
	return valid_path


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
	remove_export_plugin(export_plugin)
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
	add_autoload_singleton(
			"NexusForge",
			"res://addons/nexus_forge/classes/autoload/nexus_forge_singleton.gd")
	
	var trigger_setting_save: bool = false
	
	if not ProjectSettings.has_setting("nexus_forge/localization_directory"):
		ProjectSettings.set_setting(
				"nexus_forge/localization_directory",
				"res://localization/")
		ProjectSettings.set_initial_value(
				"nexus_forge/localization_directory",
				"res://localization/")
	
	#if not ProjectSettings.has_setting(NFFactionRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFFactionRes.SETTINGS_PATH, "")
		#ProjectSettings.set_initial_value(NFFactionRes.SETTINGS_PATH, "")
	
	#if not ProjectSettings.has_setting(NFRacesRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFRacesRes.SETTINGS_PATH, "")
		#ProjectSettings.set_initial_value(NFRacesRes.SETTINGS_PATH, "")
	
	#if not ProjectSettings.has_setting(NFTalentsRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFTalentsRes.SETTINGS_PATH, "")
		#ProjectSettings.set_initial_value(NFTalentsRes.SETTINGS_PATH, "")
	
	#if not ProjectSettings.has_setting(NFItemsRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFItemsRes.SETTINGS_PATH, "")
		#ProjectSettings.set_initial_value(NFItemsRes.SETTINGS_PATH, "")
	
	#if not ProjectSettings.has_setting(NFQuestRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFQuestRes.SETTINGS_PATH, "")
		#ProjectSettings.set_initial_value(NFQuestRes.SETTINGS_PATH, "")
	
	#if not ProjectSettings.has_setting(NFCharacterDBRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFCharacterDBRes.SETTINGS_PATH, "")
		#ProjectSettings.set_initial_value(NFCharacterDBRes.SETTINGS_PATH, "")
	
	#if not ProjectSettings.has_setting(NFVariablesRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFVariablesRes.SETTINGS_PATH, "")
		#ProjectSettings.set_initial_value(NFVariablesRes.SETTINGS_PATH, "")
	
	ProjectSettings.save()


func _disable_plugin() -> void:
	remove_autoload_singleton("NexusForge")
	
	if ProjectSettings.has_setting("nexus_forge/localization_directory"):
		ProjectSettings.set_setting("nexus_forge/localization_directory", null)
	#if ProjectSettings.has_setting(NFFactionRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFFactionRes.SETTINGS_PATH, null)
	#if ProjectSettings.has_setting(NFRacesRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFRacesRes.SETTINGS_PATH, null)
	#if ProjectSettings.has_setting(NFTalentsRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFTalentsRes.SETTINGS_PATH, null)
	#if ProjectSettings.has_setting(NFItemsRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFItemsRes.SETTINGS_PATH, null)
	#if ProjectSettings.has_setting(NFQuestRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFQuestRes.SETTINGS_PATH, null)
	if ProjectSettings.has_setting(NFCharacterDBRes.SETTINGS_PATH):
		ProjectSettings.set_setting(NFCharacterDBRes.SETTINGS_PATH, null)
	#if ProjectSettings.has_setting(NFVariablesRes.SETTINGS_PATH):
		#ProjectSettings.set_setting(NFVariablesRes.SETTINGS_PATH, null)
	
	ProjectSettings.save()
