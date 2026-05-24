@tool
class_name EditorNFPlugin
extends EditorPlugin


const MAIN_SCENE = preload("res://addons/nexus_forge/NexusForgeMainScene.tscn")
const PLUGIN_NAME: String = "NexusForge"
const PLUGIN_ICON_PATH: String = "res://addons/nexus_forge/icons/nexus_forge_small.svg"
const HANDLED_CLASSES: Array[StringName] = [&"EditorDiscourseDialog", &"CharacterSheet", &"PhraseMap", &"Quest"]
const SETTINGS_PATHS: Dictionary[String, Dictionary] = {
	"discourse_enabled": {
		"setting_path": "nexus_forge/enabled_modules/discourse_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
	},
	"characters_enabled": {
		"setting_path": "nexus_forge/enabled_modules/characters_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	},
	"species_enabled": {
		"setting_path": "nexus_forge/enabled_modules/species_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	},
	"talents_enabled": {
		"setting_path": "nexus_forge/enabled_modules/talents_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	},
	"items_enabled": {
		"setting_path": "nexus_forge/enabled_modules/items_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	},
	"recipes_enabled": {
		"setting_path": "nexus_forge/enabled_modules/recipes_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	},
	"quests_enabled": {
		"setting_path": "nexus_forge/enabled_modules/quests_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	},
	"currencies_enabled": {
		"setting_path": "nexus_forge/enabled_modules/currencies_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""},
	"phrases_enabled": {
		"setting_path": "nexus_forge/enabled_modules/phrase_maps_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""},
	"recompile_documentation": {
		"setting_path": "nexus_forge/settings/recompile_documentation_on_start",
		"default_value": false,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"restart_required": false},
	"discourse_custom_dialog_debug_scene": {
		"setting_path": "nexus_forge/settings/custom_dialog_debug_scene",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres",
		"restart_required": false},
	"discourse_panning_scheme": {
		"setting_path": "nexus_forge/settings/discourse_scroll_wheel_pans",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""},
	"discourse_base_language": {
		"setting_path": "nexus_forge/settings/discourse_base_language",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_LOCALE_ID,
		"hint_string": ""},
	"discourse_use_languages": {
		"setting_path": "nexus_forge/settings/discourse_use_languages",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""},
	"use_disabled_modules": {
		"setting_path": "nexus_forge/settings/instantiate_disabled_modules",
		"default_value": true,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"restart_required": false,
		"sort_string": "nexus_forge/settings/aaa_instantiate_disabled_modules"
	},
	"discourse": {
		"setting_path": "nexus_forge/export/localization_directory",
		"default_value": "res://localization/",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"hint_string": "",
		"is_basic": false,
		"restart_required": false},
	"variables": {
		"setting_path": "nexus_forge/paths/blackboard_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"traits": {
		"setting_path": "nexus_forge/paths/traits_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"skills": {
		"setting_path": "nexus_forge/paths/skills_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"species": {
		"setting_path": "nexus_forge/paths/species_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"items": {
		"setting_path": "nexus_forge/paths/items_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"currency": {
		"setting_path": "nexus_forge/paths/currency_path",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"recipes": {
		"setting_path": "nexus_forge/paths/recipes_path",
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


# Earlier versions of godot had an issue where documentation wouldn't show
# unless recompiled. This forces a recompilation. Adds to load time.
func recompile_script_docs() -> void:
	const SCRIPT_DOC: Array[String] = [
		"res://addons/nexus_forge/classes/autoload/nexus_forge_singleton.gd",
		"res://addons/nexus_forge/classes/cache/cache_system.gd",
		"res://addons/nexus_forge/classes/cache/resource_cache.gd",
		"res://addons/nexus_forge/classes/resources/bit_flags.gd",
		"res://addons/nexus_forge/classes/resources/value_range.gd",
		"res://addons/nexus_forge/classes/resources/range_float.gd",
		"res://addons/nexus_forge/classes/resources/range_integer.gd",
		"res://addons/nexus_forge/classes/static/array_utils.gd",
		"res://addons/nexus_forge/classes/static/bit_utils.gd",
		"res://addons/nexus_forge/classes/static/dict_utils.gd",
		"res://addons/nexus_forge/classes/static/math.gd",
		"res://addons/nexus_forge/classes/static/random_weight_pool.gd",
		"res://addons/nexus_forge/classes/static/ranges.gd",
		"res://addons/nexus_forge/classes/static/strings.gd",
		"res://addons/nexus_forge/classes/static/uuid.gd",
		"res://addons/nexus_forge/resources/skill_set.gd",
		"res://addons/nexus_forge/resources/stat_block.gd",
		"res://addons/nexus_forge/resources/trait_block.gd",
		"res://addons/nexus_forge/resources/dialog_storage/dialog_locale.gd",
		"res://addons/nexus_forge/resources/dialog_storage/parsed_dialog.gd",
		"res://addons/nexus_forge/resources/localization/phrase_map.gd",
		"res://addons/nexus_forge/resources/parser/discouse_parser_base.gd",
		"res://addons/nexus_forge/resources/character_sheet.gd",
		"res://addons/nexus_forge/resources/item_sheet.gd",
		"res://addons/nexus_forge/resources/quest_objective.gd",
		"res://addons/nexus_forge/resources/quest_stage.gd",
		"res://addons/nexus_forge/resources/quest_resource.gd",
		"res://addons/nexus_forge/resources/quest_manager.gd",
		"res://addons/nexus_forge/resources/recipe_item.gd",
		"res://addons/nexus_forge/resources/recipe_sheet.gd",
		"res://addons/nexus_forge/resources/species.gd",
		"res://addons/nexus_forge/resources/currency_catalog.gd",
		"res://addons/nexus_forge/resources/item_catalog.gd",
		"res://addons/nexus_forge/resources/recipe_catalog.gd",
		"res://addons/nexus_forge/resources/skill_catalog.gd",
		"res://addons/nexus_forge/resources/species_catalog.gd",
		"res://addons/nexus_forge/resources/stat_catalog.gd",
		"res://addons/nexus_forge/resources/trait_catalog.gd",
		"res://addons/nexus_forge/resources/var_db_script.gd"]
	
	for file in SCRIPT_DOC:
		ResourceSaver.save(load(file))


func _enter_tree() -> void:
	export_plugin = preload("res://addons/nexus_forge/export_plugin.gd").new()
	add_export_plugin(export_plugin)
	verify_project_settings()
	if ProjectSettings.has_setting("autoload/NexusForge") and ProjectSettings.get_setting(get_project_settings_path("recompile_documentation"), false):
		recompile_script_docs.call_deferred()
	editor_view = MAIN_SCENE.instantiate()
	editor_view.visible = false
	EditorInterface.get_editor_main_screen().add_child(editor_view)
	if not editor_view.is_node_ready():
		await editor_view.ready
	var use_discourse: bool = ProjectSettings.get_setting(get_project_settings_path("discourse_enabled"), true)
	var use_characters: bool = ProjectSettings.get_setting(get_project_settings_path("characters_enabled"), true)
	var use_species: bool = ProjectSettings.get_setting(get_project_settings_path("species_enabled"), true)
	var use_talents: bool = ProjectSettings.get_setting(get_project_settings_path("talents_enabled"), true)
	var use_items: bool = ProjectSettings.get_setting(get_project_settings_path("items_enabled"), true)
	var use_currencies: bool = ProjectSettings.get_setting(get_project_settings_path("currencies_enabled"), true)
	var use_recipes: bool = ProjectSettings.get_setting(get_project_settings_path("recipes_enabled"), true)
	var use_quests: bool = ProjectSettings.get_setting(get_project_settings_path("quests_enabled"), true)
	var use_phrases: bool = ProjectSettings.get_setting(get_project_settings_path("phrases_enabled"), true)
	var discourse_base_lang: String = ProjectSettings.get_setting(get_project_settings_path("discourse_base_language"), OS.get_locale_language())
	editor_view.ready_plugin(
			use_discourse,
			use_characters,
			use_species,
			use_talents,
			use_items,
			use_currencies,
			use_recipes,
			use_quests,
			use_phrases,
			discourse_base_lang)
	resource_saved.connect(_on_resource_saved, CONNECT_DEFERRED)
	EditorInterface.get_file_system_dock().resource_removed.connect(_on_resource_removed)
	EditorInterface.get_file_system_dock().files_moved.connect(_on_files_moved, CONNECT_DEFERRED)


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
	if ProjectSettings.get_setting(get_project_settings_path("recompile_documentation"), false):
		recompile_script_docs.call_deferred()


func _get_window_layout(configuration: ConfigFile) -> void:
	var discourse_id_visible: bool = editor_view.discourse.display_dialog_id_checked() if editor_view.discourse != null else false
	var discourse_open_files: Array[String] = editor_view.discourse.get_open_files() if editor_view.discourse != null else Array([], TYPE_STRING, &"", null)
	var open_characters: Array[String] = editor_view.characters.get_open_characters() if editor_view.characters != null else Array([], TYPE_STRING, &"", null)
	var open_maps: Array[String] = editor_view.phrase_maps.get_open_maps() if editor_view.phrase_maps != null else Array([], TYPE_STRING, &"", null)
	var open_quests: Array[String] = editor_view.quests.get_open_files() if editor_view.quests != null else Array([], TYPE_STRING, &"", null)
	
	configuration.set_value("NexusForge", "discourse_show_id", discourse_id_visible)
	configuration.set_value("NexusForge", "open_dialogs", discourse_open_files)
	configuration.set_value("NexusForge", "open_characters", open_characters)
	configuration.set_value("NexusForge", "open_phrase_maps", open_maps)
	configuration.set_value("NexusForge", "open_quests", open_quests)
	configuration.set_value("NexusForge", "active_tab", editor_view.current_tab)
	
	configuration.set_value("NexusForge", "blackboard_folder_layout", editor_view.variables.get_folder_layout())
	configuration.set_value("NexusForge", "blackboard_sort_column", editor_view.variables.get_sorting_column())


func _set_window_layout(configuration: ConfigFile) -> void:
	const empty: Array[String] = []
	var maps: Array[String] = configuration.get_value("NexusForge", "open_phrase_maps", empty)
	var characters: Array[String] = configuration.get_value("NexusForge", "open_characters", empty)
	var dialogs: Array[String] = configuration.get_value("NexusForge", "open_dialogs", empty)
	var folder_layout: Dictionary = configuration.get_value("NexusForge", "blackboard_folder_layout", {})
	var black_sorting_column: int = configuration.get_value("NexusForge", "blackboard_sort_column", 0)
	var open_quests: Array[String] = configuration.get_value("NexusForge", "open_quests", empty)
	var discourse_display_id: bool = configuration.get_value("NexusForge", "discourse_show_id", false)
	var tab: int = configuration.get_value("NexusForge", "active_tab", 0)
	
	editor_view.go_to_tab(tab)
	editor_view.variables.set_folder_layout(folder_layout)
	editor_view.variables.set_sorting_column(black_sorting_column)
	
	if editor_view.discourse != null:
		editor_view.discourse.load_dialog_files(dialogs)
		editor_view.discourse.set_display_dialog_id_checked(discourse_display_id)
	if editor_view.characters != null:
		editor_view.characters.load_character_files(characters)
	if editor_view.phrase_maps != null:
		editor_view.phrase_maps.open_map_files(maps)
	if editor_view.quests != null:
		editor_view.quests.open_files(open_quests)


func _sort_custom_settings(a: String, b: String) -> bool:
	var a_string: String = SETTINGS_PATHS[a]["sort_string"] if SETTINGS_PATHS[a].has("sort_string") else SETTINGS_PATHS[a]["setting_path"]
	var b_string: String = SETTINGS_PATHS[b]["sort_string"] if SETTINGS_PATHS[b].has("sort_string") else SETTINGS_PATHS[b]["setting_path"]
	return a_string < b_string


func verify_project_settings() -> void:
	var setting_order: Array[String] = []
	setting_order.assign(SETTINGS_PATHS.keys())
	#setting_order.sort_custom(
			#func (a,b): return SETTINGS_PATHS[a]["setting_path"].naturalnocasecmp_to(
					#SETTINGS_PATHS[b]["setting_path"]) < 0)
	setting_order.sort_custom(_sort_custom_settings)
	
	for tool_id in setting_order:
		if not ProjectSettings.has_setting(SETTINGS_PATHS[tool_id]["setting_path"]):
			ProjectSettings.set_setting(
				SETTINGS_PATHS[tool_id]["setting_path"],
				SETTINGS_PATHS[tool_id]["default_value"] if tool_id != "discourse_base_language" else OS.get_locale_language())
		
		if tool_id == "discourse_base_language":
			var set_setting: String = TranslationServer.standardize_locale(ProjectSettings.get_setting(SETTINGS_PATHS[tool_id]["setting_path"], ""))
			if not set_setting.is_empty():
				var parts: PackedStringArray = set_setting.split("_", false)
				var language: String = parts[0]
				var region: String = ""
				
				for part in range(1, parts.size()):
					if parts[part].length() != 2:
						continue
					region = parts[part]
					break
				
				var final_locale: String = language if region.is_empty() else language + "_" + region
				
				if final_locale != set_setting:
					ProjectSettings.set_setting(
					SETTINGS_PATHS[tool_id]["setting_path"],
					final_locale)
			else:
				ProjectSettings.set_setting(
					SETTINGS_PATHS[tool_id]["setting_path"],
					OS.get_locale_language())
		elif tool_id == "discourse_use_languages":
			var set_setting: String = ProjectSettings.get_setting(SETTINGS_PATHS[tool_id]["setting_path"], "")
			if not set_setting.is_empty():
				var locales: PackedStringArray = StringUtils.split_and_strip(set_setting, ",", false)
				var valid_locales: Dictionary[String, Variant] = {}
				
				for locale in locales:
					var valid_code: String = TranslationServer.standardize_locale(locale)
					if valid_code.is_empty():
						continue
					
					var parts: PackedStringArray = valid_code.split("_", false)
					var lang: String = parts[0]
					var region: String = ""
					for idx in range(1, parts.size()):
						if parts[idx].length() == 2:
							region = parts[idx]
							break
					
					var locale_code: String = lang if region.is_empty() else lang + "_" + region
					
					if not valid_locales.has(locale_code):
						valid_locales[locale_code] = null
				
				ProjectSettings.set_setting(
						SETTINGS_PATHS[tool_id]["setting_path"],
						", ".join(PackedStringArray(valid_locales.keys())))
			
		ProjectSettings.set_initial_value(
				SETTINGS_PATHS[tool_id]["setting_path"],
				SETTINGS_PATHS[tool_id]["default_value"] if tool_id != "discourse_base_language" else OS.get_locale_language())
		
		ProjectSettings.set_restart_if_changed(
				SETTINGS_PATHS[tool_id]["setting_path"],
				SETTINGS_PATHS[tool_id]["restart_required"] if SETTINGS_PATHS[tool_id].has("restart_required") else true)
		
		var property_info = {
			"name": SETTINGS_PATHS[tool_id]["setting_path"],
			"type": SETTINGS_PATHS[tool_id]["type"],
			"hint": SETTINGS_PATHS[tool_id]["hint"],
			"hint_string": SETTINGS_PATHS[tool_id]["hint_string"]}

		ProjectSettings.add_property_info(property_info)
		ProjectSettings.set_as_basic(
				SETTINGS_PATHS[tool_id]["setting_path"],
				SETTINGS_PATHS[tool_id]["is_basic"] if SETTINGS_PATHS[tool_id].has("is_basic") else true)
	
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
	if object is not Resource or object == null:
		return false
	
	var script: Script = object.get_script()
	if script == null:
		return false
		
	var script_global_name: StringName = script.get_global_name()
	var tool_available: bool = false
	
	match script_global_name:
		&"EditorDiscourseDialog":
			tool_available = editor_view.discourse != null
		&"CharacterSheet":
			tool_available = editor_view.characters != null
		&"PhraseMap":
			tool_available = editor_view.phrase_maps != null
		&"Quest":
			tool_available = editor_view.quests != null
	
	return HANDLED_CLASSES.has(script_global_name) and tool_available


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
	elif script_class == &"Quest":
		editor_view.reload_quest_data_types()
	elif script_class == &"QuestStage":
		editor_view.reload_quest_stage_types()
	elif script_class == &"QuestObjective":
		editor_view.reload_quest_objective_types()
	elif script_class == &"DiscourseAPI":
		editor_view.reload_discourse_api()


func _on_files_moved(old_file: String, new_file: String) -> void:
	if old_file.get_extension() != "tres" or load(new_file) is not Quest:
		return
	
	var md5: String = old_file.md5_text()
	var file: String = old_file.get_file() + "-treestate-" + md5 + ".cfg"
	var path: String = "res://.godot/editor/".path_join(file)
	if FileAccess.file_exists(path):
		var new_md5: String = new_file.md5_text()
		var new_path: String = "res://.godot/editor/".path_join(new_file.get_file() + "-treestate-" + new_md5 + ".cfg")
		DirAccess.rename_absolute(old_file, new_path)


func _on_resource_removed(object: Resource) -> void:
	if object == null:
		return
	if object is EditorDiscourseDialog:
		editor_view.discourse.filesystem_resource_removed(object)
	elif object is CharacterSheet:
		editor_view.characters.filesystem_resource_removed(object)
	elif object is PhraseMap:
		editor_view.phrase_maps.filesystem_resource_removed(object)
	elif object is Quest:
		editor_view.quests.filesystem_resource_removed(object)
	elif object is BlackboardData:
		if editor_view.variables._variables_resource == object:
			ProjectSettings.set_setting(
					get_project_settings_path("variables"),
					"")
			ProjectSettings.save()
			editor_view.variables.reload_resource()
	elif object is SpeciesCatalog:
		if editor_view.species._species_resource == object:
			ProjectSettings.set_setting(
					get_project_settings_path("species"),
					"")
			ProjectSettings.save()
			editor_view.species.reload_resource()
	elif object is SkillCatalog:
		if editor_view.talents._skills_resource == object:
			ProjectSettings.set_setting(
					get_project_settings_path("skills"),
					"")
			ProjectSettings.save()
			editor_view.talents.reload_skill_resource()
	elif object is TraitCatalog:
		if editor_view.talents._traits_resource == object:
			ProjectSettings.set_setting(
				get_project_settings_path("traits"),
				"")
			ProjectSettings.save()
			editor_view.talents.reload_trait_resource()
	elif object is ItemCatalog:
		if editor_view.recipes_link.items == object:
			ProjectSettings.set_setting(
				get_project_settings_path("items"),
				"")
			ProjectSettings.save()
			editor_view.items.items_container.reload_item_resource()
			editor_view.recipes.reload_items(null)
	elif object is CurrencyCatalog:
		if editor_view.items.items_container.currency_resource == object:
			ProjectSettings.set_setting(
				get_project_settings_path("currency"),
				"")
			ProjectSettings.save()
			editor_view.items.items_container.reload_currency_resource()
	elif object is RecipeCatalog:
		if editor_view.recipes_link.recipes == object:
			ProjectSettings.set_setting(
				get_project_settings_path("recipes"),
				"")
			ProjectSettings.save()
			editor_view.recipes.reload_recipe_resource()
