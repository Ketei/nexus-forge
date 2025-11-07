@tool
class_name EditorNFPlugin
extends EditorPlugin


const MAIN_SCENE = preload("res://addons/nexus_forge/NexusForgeMainScene.tscn")
const PLUGIN_NAME: String = "NexusForge"
const PLUGIN_ICON_PATH: String = "res://addons/nexus_forge/icons/plugin_icon.svg"
const HANDLED_CLASSES: Array[StringName] = [&"EditorDiscourseDialog", &"CharacterSheet", &"PhraseMap"]
const SETTINGS_PATHS: Dictionary[String, Dictionary] = {
	"discourse": {
		"setting_path": "nexus_forge/localization_directory",
		"default_value": "res://localization/"},
	"variables": {
		"setting_path": "nexus_forge/blackboard_path",
		"default_value": ""},
	"stats": {
		"setting_path": "nexus_forge/stats_path",
		"default_value": ""},
	"traits": {
		"setting_path": "nexus_forge/traits_path",
		"default_value": ""},
	"skills": {
		"setting_path": "nexus_forge/skills_path",
		"default_value": ""},
	"quests": {
		"setting_path": "nexus_forge/quests_path",
		"default_value": ""},
	"species": {
		"setting_path": "nexus_forge/species_path",
		"default_value": ""},
	"items": {
		"setting_path": "nexus_forge/items_path",
		"default_value": ""},
	"currency": {
		"setting_path": "nexus_forge/currency_path",
		"default_value": ""},
	"recipes": {
		"setting_path": "nexus_forge/recipes_path",
		"default_value": ""
	}
}

var editor_view: Control = null
var export_plugin: EditorExportPlugin = null


static func get_project_settings_path(module: String) -> String:
	if SETTINGS_PATHS.has(module):
		return SETTINGS_PATHS[module]["setting_path"]
	return ""


func _enter_tree() -> void:
	export_plugin = preload("res://addons/nexus_forge/export_plugin.gd").new()
	add_export_plugin(export_plugin)
	verify_project_settings()
	editor_view = MAIN_SCENE.instantiate()
	editor_view.visible = false
	EditorInterface.get_editor_main_screen().add_child(editor_view)
	resource_saved.connect(_on_resource_saved)


func _build() -> bool:
	var path: String = ProjectSettings.get_setting(
			get_project_settings_path("discourse"), "res://localization/").strip_edges()
	
	var valid_path: bool = path != "" and path.is_absolute_path() and path.begins_with("res://") and path.get_extension() == ""
	
	if not valid_path:
		printerr("[ERROR] NexusForge: Discourse needs a valid folder path for localization files on project settings.")
	
	return valid_path


func _save_external_data() -> void:
	if _editor_ready():
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
	resource_saved.disconnect(_on_resource_saved)


func _get_plugin_icon() -> Texture2D:
	return load(PLUGIN_ICON_PATH)


func _get_plugin_name() -> String:
	return PLUGIN_NAME


func _make_visible(visible):
	if editor_view != null:
		editor_view.visible = visible


func _enable_plugin() -> void:
	add_autoload_singleton(
			"NexusForge",
			"res://addons/nexus_forge/classes/autoload/nexus_forge_singleton.gd")


func verify_project_settings() -> void:
	var save_settings: bool = false
	for tool_id in SETTINGS_PATHS.keys():
		if not ProjectSettings.has_setting(SETTINGS_PATHS[tool_id]["setting_path"]):
			ProjectSettings.set_setting(
					SETTINGS_PATHS[tool_id]["setting_path"],
					SETTINGS_PATHS[tool_id]["default_value"])
			ProjectSettings.set_initial_value(
					SETTINGS_PATHS[tool_id]["setting_path"],
					SETTINGS_PATHS[tool_id]["default_value"])
			if save_settings == false:
				save_settings = true
	
	if save_settings:
		ProjectSettings.save()


func _disable_plugin() -> void:
	remove_autoload_singleton("NexusForge")
	
	for tool_id in SETTINGS_PATHS.keys():
		if ProjectSettings.has_setting(SETTINGS_PATHS[tool_id]["setting_path"]):
			ProjectSettings.set_setting(
					SETTINGS_PATHS[tool_id]["setting_path"],
					null)
	
	ProjectSettings.save()


func _handles(object: Object) -> bool:
	if object is Resource and object != null:
		var script: Script = object.get_script()
		if script != null:
			return HANDLED_CLASSES.has(script.get_global_name())
	return false


func _edit(object: Object) -> void:
	if _editor_ready() and object != null:
		_make_visible(true)
		editor_view.handle_resource(object)


func _editor_ready() -> bool:
	return editor_view != null and editor_view.is_node_ready()


func _on_resource_saved(resource: Resource) -> void:
	if resource is StatBlock:
		editor_view.reload_stats()
	elif resource is SkillSet:
		editor_view.reload_skills()
	elif resource is TraitBlock:
		editor_view.reload_traits()
	elif resource is CharacterSheet:
		editor_view.reload_character_sheet()
	elif resource is Script:
		if resource.get_global_name() == &"ItemSheet":
			editor_view.reload_items()
