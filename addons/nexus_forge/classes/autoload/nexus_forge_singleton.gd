class_name NFPluginGameHandler
extends Node
## NexusForge singleton.
##
## Contains subresources designed to parse and provide data from NexusForge's
## custom resources.

enum _LogLevel{
	INFO,
	WARNING,
	ERROR}

const _SETTINGS_PATHS: Dictionary[String, Dictionary] = {
	"discourse_enabled": {
		"setting_path": "nexus_forge/enabled_modules/dialogs_enabled",
		"default_value": true,
		"type": TYPE_BOOL},
	"characters_enabled": {
		"setting_path": "nexus_forge/enabled_modules/characters_enabled",
		"default_value": true,
		"type": TYPE_BOOL},
	"species_enabled": {
		"setting_path": "nexus_forge/enabled_modules/species_enabled",
		"default_value": true,
		"type": TYPE_BOOL},
	"stats_enabled": {
		"setting_path": "nexus_forge/enabled_modules/stats_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"sort_string": "nexus_forge/enabled_modules/stats_enabled_a"},
	"skills_enabled": {
		"setting_path": "nexus_forge/enabled_modules/skills_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"sort_string": "nexus_forge/enabled_modules/stats_enabled_b"},
	"traits_enabled": {
		"setting_path": "nexus_forge/enabled_modules/traits_enabled",
		"default_value": true,
		"type": TYPE_BOOL,
		"sort_string": "nexus_forge/enabled_modules/stats_enabled_c"},
	"items_enabled": {
		"setting_path": "nexus_forge/enabled_modules/items_enabled",
		"default_value": true,
		"type": TYPE_BOOL},
	"recipes_enabled": {
		"setting_path": "nexus_forge/enabled_modules/recipes_enabled",
		"default_value": true,
		"type": TYPE_BOOL},
	"quests_enabled": {
		"setting_path": "nexus_forge/enabled_modules/quests_enabled",
		"default_value": true,
		"type": TYPE_BOOL},
	"currencies_enabled": {
		"setting_path": "nexus_forge/enabled_modules/currencies_enabled",
		"default_value": true,
		"type": TYPE_BOOL},
	"phrases_enabled": {
		"setting_path": "nexus_forge/enabled_modules/phrase_maps_enabled",
		"default_value": true,
		"type": TYPE_BOOL},
	"recompile_documentation": {
		"setting_path": "nexus_forge/settings/recompile_documentation_on_start",
		"default_value": false,
		"type": TYPE_BOOL,
		"restart_required": false},
	"discourse_custom_dialog_debug_scene": {
		"setting_path": "nexus_forge/settings/custom_dialog_debug_scene",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres",
		"restart_required": false},
	"discourse_localization_preview_scene": {
		"setting_path": "nexus_forge/settings/localization_preview_scene",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres"},
	"discourse_panning_scheme": {
		"setting_path": "nexus_forge/settings/discourse_scroll_wheel_pans",
		"default_value": true,
		"type": TYPE_BOOL},
	"discourse_base_language": {
		"setting_path": "nexus_forge/settings/discourse_base_language",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_LOCALE_ID},
	"discourse_use_languages": {
		"setting_path": "nexus_forge/settings/discourse_use_languages",
		"default_value": "",
		"type": TYPE_STRING},
	"use_disabled_modules": {
		"setting_path": "nexus_forge/settings/instantiate_disabled_modules",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false,
		"sort_string": "nexus_forge/settings/aaa_instantiate_disabled_modules"},
	"items_format_strings": {
		"setting_path": "nexus_forge/settings/format_item_strings_with_blackboard",
		"default_value": false,
		"type": TYPE_BOOL,
		"restart_required": false},
	"species_genetic_dilution": {
		"setting_path": "nexus_forge/settings/species_genetic_dilution",
		"default_value": 0.0,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,1",
		"restart_required": false,
		"sort_string": "nexus_forge/settings/species_use_genetic_inheritance_a"},
	"species_use_inheritance": {
		"setting_path": "nexus_forge/settings/species_use_genetic_inheritance",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false,
		"sort_string": "nexus_forge/settings/species_use_genetic_inheritance_b"},
	"quests_format_strings": {
		"setting_path": "nexus_forge/settings/format_quest_strings_with_blackboard",
		"default_value": false,
		"type": TYPE_BOOL,
		"restart_required": false},
	"discourse_sync_locale": {
		"setting_path": "nexus_forge/settings/update_discourse_locale_with_godot",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false},
	"plugin_log_info": {
		"setting_path": "nexus_forge/settings/log_info",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false,
		"sort_string": "zzznexus_forge/setting/a_log_info"},
	"plugin_log_warning": {
		"setting_path": "nexus_forge/settings/log_warnings",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false,
		"sort_string": "zzznexus_forge/setting/b_log_info"},
	"plugin_log_error": {
		"setting_path": "nexus_forge/settings/log_errors",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false,
		"sort_string": "zzznexus_forge/setting/c_log_info",
		"is_basic": false},
	"character_register_ids": {
		"setting_path": "nexus_forge/export/register_character_ids",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false},
	"discourse": {
		"setting_path": "nexus_forge/export/localization_directory",
		"default_value": "res://localization/",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
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
	"stats": {
		"setting_path": "nexus_forge/paths/stats_path",
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
		"hint_string": "*.tres"}
}


## The dialog parser in charge of loading dialogs.[br]
## The object notifies of dialog data and events through signals.
var Discourse: DialogParser
## An object containing globally-accessible variables.[br]
## The variables are nested into a folder-like structure which can also contain
## folders.
var Blackboard: BlackboardData

## An object for registering and loading [CharacterSheet]s and applying
## modifications to them.
var Characters: NFCharacterManager

## A resource containing the game's item definitions.
var Items: NFItemManager
## A resource containing custom stats data.[br]
## Custom stats will be included in all [StatBlock]'s custom stats instantiated
## with [method StatBlock.new_stat_block].
var Stats: NFStatManager
## A resource containing common and custom trait data.[br]
## Custom traits created here will also be included in all instances of
## [TraitBlock] that were created via [method TraitBlock.new_trait_block].
var Traits: NFTraitManager
## A resource containing common and custom skill data.[br]
## Custom skill created here will also be included in all instances of
## [SkillSet] that were created via [method SkillSet.new_skill_set].
var Skills: NFSkillManager
## A resource containing the game's species data.
var Species: NFSpeciesManager
## A resource containing the game's quests data.
var Quests: QuestManager
## A resource containing the game's currency data and helper methods to manage
## different currency systems.
var Currency: CurrencyCatalog
## A resource containing the game's crafting recipes.
var Recipes: RecipeCatalog

var _phrase_api: PhraseAPI = PhraseAPI.new()


static func get_setting_path(module: String) -> String:
	if _SETTINGS_PATHS.has(module):
		return _SETTINGS_PATHS[module]["setting_path"]
	return ""


static func _log_msg(module: String, msg: String, log_level: _LogLevel = _LogLevel.INFO) -> void:
	var full_msg: String = "[NEXUS FORGE - %s] %s" % [module.to_upper(), msg]
	
	if log_level == _LogLevel.INFO:
		if ProjectSettings.get_setting(get_setting_path("plugin_log_info"), true):
			print(full_msg)
	elif log_level == _LogLevel.WARNING:
		if not ProjectSettings.get_setting(get_setting_path("plugin_log_warning"), true):
			push_warning(full_msg)
	elif log_level == _LogLevel.ERROR:
		if not ProjectSettings.get_setting(get_setting_path("plugin_log_error"), true):
			push_error(full_msg)


func _ready() -> void:
	var use_discourse: bool = ProjectSettings.get_setting(get_setting_path("discourse_enabled"), true)
	var use_items: bool = ProjectSettings.get_setting(get_setting_path("items_enabled"), true)
	var use_stats: bool = ProjectSettings.get_setting(get_setting_path("stats_enabled"), true)
	var use_skills: bool = ProjectSettings.get_setting(get_setting_path("skills_enabled"), true)
	var use_traits: bool = ProjectSettings.get_setting(get_setting_path("traits_enabled"), true)
	var use_species: bool = ProjectSettings.get_setting(get_setting_path("species_enabled"), true)
	var use_quests: bool = ProjectSettings.get_setting(get_setting_path("quests_enabled"), true)
	var use_currencies: bool = ProjectSettings.get_setting(get_setting_path("currencies_enabled"), true)
	var use_recipes: bool = ProjectSettings.get_setting(get_setting_path("recipes_enabled"), true)
	var use_characters: bool = ProjectSettings.get_setting(get_setting_path("characters_enabled"), true)
	var instantiate_disabled: bool = ProjectSettings.get_setting(get_setting_path("use_disabled_modules"), true)
	
	var blackboard_path: String = ProjectSettings.get_setting(
			get_setting_path("variables"), "")
	if not blackboard_path.is_empty() and ResourceLoader.exists(blackboard_path):
		var res_pre: Resource = load(blackboard_path)
		if res_pre is BlackboardData:
			Blackboard = res_pre
		else:
			printerr("[NEXUS FORGE] ProjectSettings: Invalid Blackboard.")
	
	if use_species:
		Species = NFSpeciesManager.new()
		var species_path: String = ProjectSettings.get_setting(
				get_setting_path("species"), "")
		if not species_path.is_empty() and ResourceLoader.exists(species_path):
			var res_pre = load(species_path)
			if res_pre is SpeciesCatalog:
				Species.load_catalog(res_pre, true)
			else:
				printerr("[NEXUS FORGE] ProjectSettings: Invalid Species.")
	
	if use_items:
		if Items == null:
			Items = NFItemManager.new()
		var items_path: String = ProjectSettings.get_setting(
				get_setting_path("items"), "")
		if not items_path.is_empty() and ResourceLoader.exists(items_path):
			var res_pre: Resource = load(items_path)
			if res_pre is ItemCatalog:
				Items.load_catalog(res_pre)
			else:
				NFPluginGameHandler._log_msg(
						"singleton",
						"Invalid ItemCatalog resource '%s'" % items_path,
						NFPluginGameHandler._LogLevel.ERROR)
	
	if use_currencies:
		var currency_path: String = ProjectSettings.get_setting(
				get_setting_path("currency"), "")
		if not currency_path.is_empty() and ResourceLoader.exists(currency_path):
			var res_pre: Resource = load(currency_path)
			if res_pre is CurrencyCatalog:
				Currency = res_pre
			else:
				printerr("[NEXUS FORGE] ProjectSettings: Invalid Currency.")
	
	if use_recipes:
		var recipe_path: String = ProjectSettings.get_setting(
				get_setting_path("recipes"), "")
		if not recipe_path.is_empty() and ResourceLoader.exists(recipe_path):
			var res_pre: Resource = load(recipe_path)
			if res_pre is RecipeCatalog:
				Recipes = res_pre
			else:
				printerr("[NEXUS FORGE] ProjectSettings: Invalid Recipes.")
	
	if use_stats:
		if Stats == null:
			Stats = NFStatManager.new()
		var stats_path: String = ProjectSettings.get_setting(
				get_setting_path("stats"), "")
		
		if not stats_path.is_empty() and ResourceLoader.exists(stats_path):
			var st_load = load(stats_path)
			if st_load != null and st_load is StatCatalog:
				Stats.load_catalog(st_load)
	
	if use_skills:
		if Skills == null:
			Skills = NFSkillManager.new()
		var skills_path: String = ProjectSettings.get_setting(
				get_setting_path("skills"), "")
		if not skills_path.is_empty() and ResourceLoader.exists(skills_path):
			var skill_pre = load(skills_path)
			if skill_pre != null and skill_pre is SkillCatalog:
				Skills.load_catalog(skill_pre)
	
	if use_traits:
		if Traits == null:
			Traits = NFTraitManager.new()
		var traits_path: String = ProjectSettings.get_setting(
				get_setting_path("traits"), "")
		
		if not traits_path.is_empty() and ResourceLoader.exists(traits_path):
			var pre_trait = load(traits_path)
			
			if pre_trait is TraitCatalog:
				Traits.load_catalog(pre_trait)
	
	if Discourse == null:
		if instantiate_disabled or use_discourse:
			Discourse = EditorDialogParser.new() if OS.has_feature("editor") else DialogParser.new()
			if use_discourse:
				Discourse.generate_locale_map()

	if Blackboard == null:
		Blackboard = BlackboardData.new()
	
	if Stats == null and instantiate_disabled:
		Stats = NFStatManager.new()
	if Traits == null and instantiate_disabled:
		Traits = NFTraitManager.new()
	if Skills == null and instantiate_disabled:
		Skills = NFSkillManager.new()
	
	if Characters == null and (use_characters or instantiate_disabled):
		Characters = NFCharacterManager.new()
		if ProjectSettings.get_setting(get_setting_path("character_register_ids"), true):
			if OS.has_feature("editor"):
				if FileAccess.file_exists("user://nexus_forge/persona_settings.cfg"):
					var cfg: ConfigFile = ConfigFile.new()
					if cfg.load("user://nexus_forge/persona_settings.cfg") == OK:
						var data = cfg.get_value("RUNTIME", "CharacterMap")
						if typeof(data) == TYPE_DICTIONARY:
							var map: Dictionary[StringName, String] = {}
							for key in data.keys():
								if typeof(key) == TYPE_STRING and typeof(data[key]) == TYPE_STRING_NAME:
									if map.has(data[key]):
										_log_msg(
												"singleton",
												"Resource '%s' is using the ID (%s) of an already registered resource '%s'. Skipping." % [key, data[key], map[data[key]]])
									map[data[key]] = key
							Characters._characters.assign(map)
			else:
				if FileAccess.file_exists("res://addons/nexus_forge/settings.cfg"):
					var cfg: ConfigFile = ConfigFile.new()
					if cfg.load("res://addons/nexus_forge/settings.cfg") == OK:
						var data = cfg.get_value("PERSONA", "CharacterMap")
						if typeof(data) == TYPE_DICTIONARY:
							var map: Dictionary[StringName, String] = {}
							for key in data.keys():
								if typeof(key) == TYPE_STRING_NAME and typeof(data[key]) == TYPE_STRING:
									map[key] = data[key]
							Characters._characters.assign(map)
						else:
							_log_msg(
									"singleton",
									"Failed to load NexusForge settings",
									NFPluginGameHandler._LogLevel.WARNING)
	if Quests == null and ( use_quests or instantiate_disabled ):
		Quests = QuestManager.new()
	if Species == null and instantiate_disabled:
		Species = NFSpeciesManager.new()
	if Items == null and instantiate_disabled:
		Items = NFItemManager.new()
	if Currency == null and ( use_currencies or instantiate_disabled ):
		Currency = CurrencyCatalog.new()
	if Recipes == null and ( use_recipes or instantiate_disabled ):
		Recipes = RecipeCatalog.new()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Discourse._clear_cache() # Clearing discourse cache to prevent leaked resources.
	elif what == NOTIFICATION_TRANSLATION_CHANGED:
		if not ProjectSettings.get_setting(
				get_setting_path("discourse_sync_locale"),
				true):
			return
		
		if not is_node_ready():
			await ready
		
		if Discourse == null:
			return
		
		Discourse.locale = TranslationServer.get_locale()
		
		if Discourse.is_dialog_active():
			Discourse.refresh()
