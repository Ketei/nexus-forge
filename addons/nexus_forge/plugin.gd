@tool
class_name EditorNFPlugin
extends EditorPlugin


const MAIN_SCENE = preload("res://addons/nexus_forge/NexusForgeMainScene.tscn")
const PLUGIN_NAME: String = "NexusForge"
const PLUGIN_ICON_PATH: String = "res://addons/nexus_forge/icons/nexus_forge_small.svg"
const HANDLED_CLASSES: Array[StringName] = [&"EditorDiscourseDialog", &"CharacterSheet", &"PhraseMap"]
const SETTINGS_PATHS: Dictionary[String, Dictionary] = {
	"discourse": {
		"setting_path": "nexus_forge/localization_directory",
		"default_value": "res://localization/",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"hint_string": ""},
	"variables": {
		"setting_path": "nexus_forge/blackboard_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"traits": {
		"setting_path": "nexus_forge/traits_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"skills": {
		"setting_path": "nexus_forge/skills_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"quests": {
		"setting_path": "nexus_forge/quests_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"species": {
		"setting_path": "nexus_forge/species_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"items": {
		"setting_path": "nexus_forge/items_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"currency": {
		"setting_path": "nexus_forge/currency_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"recipes": {
		"setting_path": "nexus_forge/recipes_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"
	}
}

var editor_view: Control = null
var export_plugin: EditorExportPlugin = null


static func get_project_settings_path(module: String) -> String:
	if SETTINGS_PATHS.has(module):
		return SETTINGS_PATHS[module]["setting_path"]
	return ""


# Forces a recompilation of all scripts that contain documentation. Until
# Godot fixes the documentation generation, this will be necessary.
func recompile_script_docs() -> void:
	const SCRIPT_DOC: Array[String] = [
		"res://addons/nexus_forge/classes/autoload/nexus_forge_singleton.gd",
		"res://addons/nexus_forge/classes/cache/cache_system.gd",
		"res://addons/nexus_forge/classes/cache/resource_cache.gd",
		"res://addons/nexus_forge/classes/resources/bit_flags.gd",
		"res://addons/nexus_forge/classes/resources/range_float.gd",
		"res://addons/nexus_forge/classes/resources/range_integer.gd",
		"res://addons/nexus_forge/classes/static/array_utils.gd",
		"res://addons/nexus_forge/classes/static/bit_utils.gd",
		"res://addons/nexus_forge/classes/static/math.gd",
		"res://addons/nexus_forge/classes/static/random_weight_pool.gd",
		"res://addons/nexus_forge/classes/static/ranges.gd",
		"res://addons/nexus_forge/classes/static/strings.gd",
		"res://addons/nexus_forge/classes/static/uuid.gd",
		"res://addons/nexus_forge/resources/dialog_storage/dialog_locale.gd",
		#"res://addons/nexus_forge/resources/dialog_storage/dialog_storage_base.gd",
		#"res://addons/nexus_forge/resources/dialog_storage/dialog_storage_editor.gd",
		#"res://addons/nexus_forge/resources/dialog_storage/dialog_storage_release.gd",
		"res://addons/nexus_forge/resources/dialog_storage/parsed_dialog.gd",
		"res://addons/nexus_forge/resources/localization/phrase_map.gd",
		"res://addons/nexus_forge/resources/parser/discouse_parser_base.gd",
		"res://addons/nexus_forge/resources/character_sheet.gd",
		"res://addons/nexus_forge/resources/currency_catalog.gd",
		"res://addons/nexus_forge/resources/item_catalog.gd",
		"res://addons/nexus_forge/resources/item_sheet.gd",
		"res://addons/nexus_forge/resources/quest_catalog.gd",
		"res://addons/nexus_forge/resources/quest_data.gd",
		"res://addons/nexus_forge/resources/quest_stage.gd",
		"res://addons/nexus_forge/resources/quest_step.gd",
		"res://addons/nexus_forge/resources/recipe_catalog.gd",
		"res://addons/nexus_forge/resources/recipe_item.gd",
		"res://addons/nexus_forge/resources/recipe_sheet.gd",
		"res://addons/nexus_forge/resources/skill_catalog.gd",
		"res://addons/nexus_forge/resources/skill_set.gd",
		"res://addons/nexus_forge/resources/species.gd",
		"res://addons/nexus_forge/resources/species_catalog.gd",
		"res://addons/nexus_forge/resources/stat_block.gd",
		"res://addons/nexus_forge/resources/stat_catalog.gd",
		"res://addons/nexus_forge/resources/trait_block.gd",
		"res://addons/nexus_forge/resources/trait_catalog.gd",
		"res://addons/nexus_forge/resources/var_db_script.gd"]
	
	for file in SCRIPT_DOC:
		ResourceSaver.save(load(file))


func _enter_tree() -> void:
	export_plugin = preload("res://addons/nexus_forge/export_plugin.gd").new()
	add_export_plugin(export_plugin)
	verify_project_settings()
	editor_view = MAIN_SCENE.instantiate()
	editor_view.visible = false
	EditorInterface.get_editor_main_screen().add_child(editor_view)
	recompile_script_docs()
	resource_saved.connect(_on_resource_saved, CONNECT_DEFERRED)


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


func _get_window_layout(configuration: ConfigFile) -> void:
	var discourse_open_files: Array[String] = editor_view.discourse.get_open_files()
	var open_characters: Array[String] = editor_view.characters.get_open_characters()
	var open_maps: Array[String] = editor_view.phrase_maps.get_open_maps()
	
	configuration.set_value("NexusForge", "open_dialogs", discourse_open_files)
	configuration.set_value("NexusForge", "open_characters", open_characters)
	configuration.set_value("NexusForge", "open_phrase_maps", open_maps)


func _set_window_layout(configuration: ConfigFile) -> void:
	const empty: Array[String] = []
	var maps: Array[String] = configuration.get_value("NexusForge", "open_phrase_maps", empty)
	var characters: Array[String] = configuration.get_value("NexusForge", "open_characters", empty)
	var dialogs: Array[String] = configuration.get_value("NexusForge", "open_dialogs", empty)
	
	editor_view.discourse.load_dialog_files(dialogs)
	editor_view.characters.load_character_files(characters)
	editor_view.phrase_maps.open_map_files(maps)


func verify_project_settings() -> void:
	var setting_order: Array[String] = []
	setting_order.assign(SETTINGS_PATHS.keys())
	setting_order.sort_custom(
			func (a,b): return SETTINGS_PATHS[a]["setting_path"].naturalnocasecmp_to(
					SETTINGS_PATHS[b]["setting_path"]) < 0)
	
	var save_settings: bool = false
	for tool_id in setting_order:
		if ProjectSettings.has_setting(SETTINGS_PATHS[tool_id]["setting_path"]):
			continue
		ProjectSettings.set_setting(
				SETTINGS_PATHS[tool_id]["setting_path"],
				SETTINGS_PATHS[tool_id]["default_value"])
		ProjectSettings.set_initial_value(
				SETTINGS_PATHS[tool_id]["setting_path"],
				SETTINGS_PATHS[tool_id]["default_value"])
		
		ProjectSettings.set_restart_if_changed(
				SETTINGS_PATHS[tool_id]["setting_path"],
				tool_id != "discourse")
		
		var property_info = {
			"name": SETTINGS_PATHS[tool_id]["setting_path"],
			"type": SETTINGS_PATHS[tool_id]["type"],
			"hint": SETTINGS_PATHS[tool_id]["hint"],
			"hint_string": SETTINGS_PATHS[tool_id]["hint_string"]}

		ProjectSettings.add_property_info(property_info)
		ProjectSettings.set_as_basic(
				SETTINGS_PATHS[tool_id]["setting_path"],
				tool_id == "discourse")
		
		if save_settings == false:
			save_settings = true
	
	if save_settings:
		var idx: int = -1
		for setting in setting_order:
			idx += 1
			ProjectSettings.set_order(SETTINGS_PATHS[setting]["setting_path"], idx)
		
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
	if resource is not Script:
		return
	
	var script_class: StringName = resource.get_global_name()
	
	if script_class.is_empty():
		return
	elif script_class == &"StatBlock":
		editor_view.reload_stats()
	elif script_class == &"SkillSet":
		editor_view.reload_skills()
	elif script_class == &"TraitBlock":
		editor_view.reload_traits()
	elif script_class == &"CharacterSheet":
		editor_view.reload_character_sheet()
	elif script_class == &"ItemSheet":
		editor_view.reload_items()
	elif script_class == &"QuestData":
		editor_view.reload_quest_data()
	elif script_class == &"QuestStage":
		editor_view.reload_quest_stage()
	elif script_class == &"QuestStep":
		editor_view.reload_quest_step()
	elif script_class == &"DiscourseAPI":
		editor_view.reload_discourse_api()
