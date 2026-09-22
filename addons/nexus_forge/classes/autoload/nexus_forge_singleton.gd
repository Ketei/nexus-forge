class_name NFPluginGameHandler
extends Node
## NexusForge singleton.
##
## Contains subresources designed to parse and provide data from NexusForge's
## custom resources.
## [br][br]
## The dictionaries: Items, Stats, Traits, Skills, Species, Quests, 
## Currencies, and Recipes; are the primary, read-only access points for all 
## data loaded by their respective managers.
## [br][br]
## You can access the data in two ways:
## [br]
## 1. [b]Direct Access[/b]: 
## Use brackets or dot-notation when you know the ID. This provides
## autocomplete in the editor and throws an error if the ID is missing.
## [codeblock]
## var potion = Items.HealthPotion
## var sword = Items[&"Sword"]
## [/codeblock]
## [br]
## 2. [b]Safe Access:[/b][br]
## Use the [method Dictionary.get] method when dealing with dynamic variables. 
## This safely returns [code]null[/code] (or a custom fallback) if the ID
## is missing.
## [codeblock]
## for loot_id in monster_loot:
##    var loot = Items.get(loot_id)
##    if loot:
##        print(loot.get_item_name())
## [/codeblock]
## [br]
## [b]Note:[/b] These dictionaries are read-only to protect internal state. 
## To load, add, or remove data, you must use the corresponding Manager objects.

enum _LogLevel{
	INFO,
	WARNING,
	ERROR,
	EDITOR}

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
		"hint_string": "*.tscn",
		"restart_required": false},
	"discourse_localization_preview_scene": {
		"setting_path": "nexus_forge/editor/localization_live_preview_scene",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tscn"},
	"discourse_panning_scheme": {
		"setting_path": "nexus_forge/editor/discourse_scroll_wheel_pans",
		"default_value": true,
		"type": TYPE_BOOL},
	"discourse_base_language": {
		"setting_path": "nexus_forge/editor/discourse_base_language",
		"default_value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_LOCALE_ID},
	"discourse_fallback_mode": {
		"setting_path": "nexus_forge/settings/discourse_locale_fallback_mode",
		"default_value": 2,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "No Fallback:0,Direct Fallback:1,Cascade:2",
		"restart_required": false},
	"discourse_use_languages": {
		"setting_path": "nexus_forge/editor/discourse_use_languages",
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
		"restart_required": false},
	"quests_format_strings": {
		"setting_path": "nexus_forge/settings/format_quest_strings_with_blackboard",
		"default_value": false,
		"type": TYPE_BOOL,
		"restart_required": false},
	"use_discourse_parser": {
		"setting_path": "nexus_forge/settings/parse_discourse_strings",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false},
	"discourse_sync_locale": {
		"setting_path": "nexus_forge/settings/update_discourse_locale_with_godot",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false},
	"plugin_log_info": {
		"setting_path": "nexus_forge/logging/log_info",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false,
		"sort_string": "nexus_forge/logging/b_log_info"},
	"plugin_log_warning": {
		"setting_path": "nexus_forge/logging/log_warnings",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false,
		"sort_string": "nexus_forge/logging/c_log_info"},
	"plugin_log_error": {
		"setting_path": "nexus_forge/logging/log_errors",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false,
		"sort_string": "nexus_forge/logging/d_log_info",
		"is_basic": false},
	"plugin_log_editor": {
		"setting_path": "nexus_forge/logging/log_editor_info",
		"default_value": true,
		"type": TYPE_BOOL,
		"restart_required": false,
		"sort_string": "nexus_forge/logging/a_log_info",
		"is_basic": true},
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
var Discourse: NFDialogParser
## An object containing globally-accessible variables.[br]
## The variables are nested into a folder-like structure which can also contain
## folders.
var Blackboard: NFBlackboardData

## An object for registering and loading [NFCharacterSheet]s and applying
## modifications to them.
var CharacterManager: NFCharacterManager

## A read-only dictionary containing all registered [NFItemSheet] resources.
## [br][br]
## [b]Note:[/b] This registry is populated automatically. To add or remove items, use [member ItemManager].
var Items: Dictionary[StringName, NFItemSheet] = {}
## A resource containing the game's item definitions.
var ItemManager: NFItemManager:
	set(m):
		if is_instance_valid(ItemManager):
			if ItemManager.item_created.is_connected(_on_item_list_changed):
				ItemManager.item_created.disconnect(_on_item_list_changed)
			if ItemManager.item_erased.is_connected(_on_item_list_changed):
				ItemManager.item_erased.disconnect(_on_item_list_changed)
		ItemManager = m
		if is_instance_valid(m):
			_rebuild_item_cache()
			m.item_created.connect(_on_item_list_changed)
			m.item_erased.connect(_on_item_list_changed)
		else:
			Items = {}
			Items.make_read_only()

## A read-only dictionary containing all registered [NFCatalogEntryStat] resources.
## [br][br]
## [b]Note:[/b] This registry is populated automatically. To add or remove stats, use [member StatManager].
var Stats: Dictionary[StringName, NFCatalogEntryStat] = {}
## A resource containing custom stats data.[br]
var StatManager: NFStatManager:
	set(s):
		if is_instance_valid(StatManager):
			if StatManager.stat_created.is_connected(_on_stat_list_changed):
				StatManager.stat_created.disconnect(_on_stat_list_changed)
			if StatManager.stat_erased.is_connected(_on_stat_list_changed):
				StatManager.stat_erased.disconnect(_on_stat_list_changed)
		StatManager = s
		if is_instance_valid(s):
			s.stat_created.connect(_on_stat_list_changed)
			s.stat_erased.connect(_on_stat_list_changed)
			_rebuild_stat_cache()
		else:
			Stats = {}
			Stats.make_read_only()

## A read-only dictionary containing all registered trait [NFCatalogEntry] resources.
## [br][br]
## [i]Note: This registry is populated automatically. To add or remove traits, use [member TraitManager].[/i]
var Traits: Dictionary[StringName, NFCatalogEntry] = {}
## A resource containing basic and custom trait data.[br]
var TraitManager: NFTraitManager:
	set(t):
		if is_instance_valid(TraitManager):
			if TraitManager.trait_created.is_connected(_on_trait_list_changed):
				TraitManager.trait_created.disconnect(_on_trait_list_changed)
			if TraitManager.trait_erased.is_connected(_on_trait_list_changed):
				TraitManager.trait_erased.disconnect(_on_trait_list_changed)
		TraitManager = t
		if is_instance_valid(t):
			t.trait_created.connect(_on_trait_list_changed)
			t.trait_erased.connect(_on_trait_list_changed)
			_rebuild_trait_cache()
		else:
			Traits = {}
			Traits.make_read_only()

## A read-only dictionary containing all registered skill [NFCatalogEntry] resources.
## [br][br]
## [b]Note:[/b] This registry is populated automatically. To add or remove skills, use [member SkillManager].
var Skills: Dictionary[StringName, NFCatalogEntry] = {}
## A resource containing common and custom skill data.[br]
var SkillManager: NFSkillManager:
	set(s):
		if is_instance_valid(SkillManager):
			if SkillManager.skill_created.is_connected(_on_skill_list_changed):
				SkillManager.skill_created.disconnect(_on_skill_list_changed)
			if SkillManager.skill_erased.is_connected(_on_skill_list_changed):
				SkillManager.skill_erased.disconnect(_on_skill_list_changed)
		SkillManager = s
		if is_instance_valid(s):
			s.skill_created.connect(_on_skill_list_changed)
			s.skill_erased.connect(_on_skill_list_changed)
			_rebuild_skill_cache()
		else:
			Skills = {}
			Skills.make_read_only()

## A read-only dictionary containing all registered [NFSpeciesSheet] resources.
## [br][br]
## [b]Note:[/b] This registry is populated automatically. To add or remove species, use [member SpeciesManager].
var Species: Dictionary[StringName, NFSpeciesSheet] = {}
## A resource containing the game's species data.
var SpeciesManager: NFSpeciesManager:
	set(s):
		if is_instance_valid(SpeciesManager):
			if SpeciesManager.species_created.is_connected(_on_species_list_changed):
				SpeciesManager.species_created.disconnect(_on_species_list_changed)
			if SpeciesManager.species_erased.is_connected(_on_species_list_changed):
				SpeciesManager.species_erased.disconnect(_on_species_list_changed)
		SpeciesManager = s
		if is_instance_valid(s):
			s.species_created.connect(_on_species_list_changed)
			s.species_erased.connect(_on_species_list_changed)
			_rebuild_species_cache()
		else:
			Species = {}
			Species.make_read_only()
## A resource containing the game's quests data.

## A read-only dictionary containing all active [NFQuest] resources.
## [br][br]
## [b]Note:[/b] This registry is populated automatically. To manage active quests, use [member QuestManager].
var Quests: Dictionary[StringName, NFQuest] = {}
var QuestManager: NFQuestManager:
	set(q):
		if is_instance_valid(QuestManager):
			if QuestManager._quests_modified.is_connected(_on_quests_list_changed):
				QuestManager._quests_modified.disconnect(_on_quests_list_changed)
		QuestManager = q
		if is_instance_valid(q):
			q._quests_modified.connect(_on_quests_list_changed)
			_rebuild_quest_cache()
		else:
			Quests = {}
			Quests.make_read_only()
## A resource containing the game's currency data and helper methods to manage
## different currency systems.

## A read-only dictionary containing all registered [NFCurrencyEntry] resources.
## [br][br]
## [b]Note:[/b] This registry is populated automatically. To add or remove currencies, use [member CurrencyManager].
var Currencies: Dictionary[StringName, NFCurrencyEntry] = {}
var CurrencyManager: NFCurrencyManager:
	set(c):
		if is_instance_valid(CurrencyManager):
			if CurrencyManager.currency_created.is_connected(_on_currency_list_changed):
				CurrencyManager.currency_created.disconnect(_on_currency_list_changed)
			if CurrencyManager.currency_erased.is_connected(_on_currency_list_changed):
				CurrencyManager.currency_erased.disconnect(_on_currency_list_changed)
		CurrencyManager = c
		if is_instance_valid(c):
			c.currency_created.connect(_on_currency_list_changed)
			c.currency_erased.connect(_on_currency_list_changed)
			_rebuild_currency_cache()
		else:
			Currencies = {}
			Currencies.make_read_only()

## A read-only dictionary containing all registered [NFRecipeSheet] resources.
## [br][br]
## [b]Note:[/b] This registry is populated automatically. To add or remove recipes, use [member RecipeManager].
var Recipes: Dictionary[StringName, NFRecipeSheet] = {}
## A resource containing the game's crafting recipes.
var RecipeManager: NFRecipeManager:
	set(r):
		if is_instance_valid(RecipeManager):
			if RecipeManager.recipe_created.is_connected(_on_recipe_list_changed):
				RecipeManager.recipe_created.disconnect(_on_recipe_list_changed)
			if RecipeManager.recipe_erased.is_connected(_on_recipe_list_changed):
				RecipeManager.recipe_erased.disconnect(_on_recipe_list_changed)
		RecipeManager = r
		if is_instance_valid(r):
			r.recipe_created.connect(_on_recipe_list_changed)
			r.recipe_erased.connect(_on_recipe_list_changed)
			_rebuild_recipe_cache()
		else:
			Recipes = {}
			Recipes.make_read_only()

var _phrase_api: NFPhraseAPI = NFPhraseAPI.new()


## Gets the path to a ProjecSetting registered by NexusForge by using its ID.
static func get_setting_path(module: String) -> String:
	if _SETTINGS_PATHS.has(module):
		return _SETTINGS_PATHS[module]["setting_path"]
	return ""


static func _log_msg(module: String, msg: String, log_level: _LogLevel = _LogLevel.INFO) -> void:
	var full_msg: String = ""
	
	if module.is_empty():
		full_msg = "[NEXUS FORGE] %s"
	else:
		full_msg = "[NEXUS FORGE - %s] %s" % [module.to_upper(), msg]
	
	if log_level == _LogLevel.INFO:
		if ProjectSettings.get_setting(get_setting_path("plugin_log_info"), true):
			print(full_msg)
	elif log_level == _LogLevel.WARNING:
		if ProjectSettings.get_setting(get_setting_path("plugin_log_warning"), true):
			push_warning(full_msg)
	elif log_level == _LogLevel.ERROR:
		if ProjectSettings.get_setting(get_setting_path("plugin_log_error"), true):
			push_error(full_msg)
	elif log_level == _LogLevel.EDITOR:
		if ProjectSettings.get_setting(get_setting_path("plugin_log_editor"), true):
			print_rich("[color=web_gray]" + msg + "[/color]")


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
		if res_pre is NFBlackboardData:
			Blackboard = res_pre
		else:
			_log_msg(
					"",
					"Invalid Blackboard resource '%s'" % blackboard_path,
					_LogLevel.ERROR)
	
	if use_species:
		SpeciesManager = NFSpeciesManager.new()
		var species_path: String = ProjectSettings.get_setting(
				get_setting_path("species"), "")
		if not species_path.is_empty() and ResourceLoader.exists(species_path):
			var res_pre = load(species_path)
			if res_pre is NFSpeciesCatalog:
				SpeciesManager.load_catalog(res_pre, true)
				_rebuild_species_cache()
			else:
				_log_msg(
						"",
						"Inavalid NFSpeciesCataglog resource '%s'" % species_path,
						NFPluginGameHandler._LogLevel.ERROR)
	
	if use_items:
		if ItemManager == null:
			ItemManager = NFItemManager.new()
		var items_path: String = ProjectSettings.get_setting(
				get_setting_path("items"), "")
		if not items_path.is_empty() and ResourceLoader.exists(items_path):
			var res_pre: Resource = load(items_path)
			if res_pre is NFItemCatalog:
				ItemManager.load_catalog(res_pre)
				_rebuild_item_cache()
			else:
				NFPluginGameHandler._log_msg(
						"",
						"Invalid NFItemCatalog resource '%s'" % items_path,
						NFPluginGameHandler._LogLevel.ERROR)
	
	if use_currencies:
		CurrencyManager = NFCurrencyManager.new()
		var currency_path: String = ProjectSettings.get_setting(
				get_setting_path("currency"), "")
		if not currency_path.is_empty() and ResourceLoader.exists(currency_path):
			var res_pre: Resource = load(currency_path)
			if res_pre is NFCurrencyCatalog:
				CurrencyManager.load_catalog(res_pre, true)
				_rebuild_currency_cache()
			else:
				NFPluginGameHandler._log_msg(
						"",
						"Invalid NFCurrencyCatalog resource '%s'" % currency_path,
						NFPluginGameHandler._LogLevel.ERROR)
	
	if use_recipes:
		RecipeManager = NFRecipeManager.new()
		var recipe_path: String = ProjectSettings.get_setting(
				get_setting_path("recipes"), "")
		if not recipe_path.is_empty() and ResourceLoader.exists(recipe_path):
			var res_pre: Resource = load(recipe_path)
			if res_pre is NFRecipeCatalog:
				RecipeManager.load_catalog(res_pre)
				_rebuild_recipe_cache()
			else:
				NFPluginGameHandler._log_msg(
						"",
						"Invalid NFRecipeCatalog resource '%s'" % recipe_path,
						NFPluginGameHandler._LogLevel.ERROR)
	
	if use_stats:
		if StatManager == null:
			StatManager = NFStatManager.new()
		var stats_path: String = ProjectSettings.get_setting(
				get_setting_path("stats"), "")
		
		if not stats_path.is_empty() and ResourceLoader.exists(stats_path):
			var st_load = load(stats_path)
			if st_load != null and st_load is NFStatCatalog:
				StatManager.load_catalog(st_load)
				_rebuild_stat_cache()
	
	if use_skills:
		if SkillManager == null:
			SkillManager = NFSkillManager.new()
		var skills_path: String = ProjectSettings.get_setting(
				get_setting_path("skills"), "")
		if not skills_path.is_empty() and ResourceLoader.exists(skills_path):
			var skill_pre = load(skills_path)
			if skill_pre != null and skill_pre is NFSkillCatalog:
				SkillManager.load_catalog(skill_pre)
				_rebuild_skill_cache()
	
	if use_traits:
		if TraitManager == null:
			TraitManager = NFTraitManager.new()
		var traits_path: String = ProjectSettings.get_setting(
				get_setting_path("traits"), "")
		
		if not traits_path.is_empty() and ResourceLoader.exists(traits_path):
			var pre_trait = load(traits_path)
			
			if pre_trait is NFTraitCatalog:
				TraitManager.load_catalog(pre_trait)
				_rebuild_trait_cache()
	
	if Discourse == null:
		if instantiate_disabled or use_discourse:
			Discourse = NFEditorDialogParser.new() if OS.has_feature("editor") else NFDialogParser.new()
			if use_discourse:
				Discourse._generate_locale_map()

	if Blackboard == null:
		Blackboard = NFBlackboardData.new()
	
	if StatManager == null and instantiate_disabled:
		StatManager = NFStatManager.new()
	if TraitManager == null and instantiate_disabled:
		TraitManager = NFTraitManager.new()
	if SkillManager == null and instantiate_disabled:
		SkillManager = NFSkillManager.new()
	
	if CharacterManager == null and (use_characters or instantiate_disabled):
		CharacterManager = NFCharacterManager.new()
		if ProjectSettings.get_setting(get_setting_path("character_register_ids"), true):
			if OS.has_feature("editor"):
				if FileAccess.file_exists("user://nexus_forge/persona_settings.cfg"):
					var cfg: ConfigFile = ConfigFile.new()
					if cfg.load("user://nexus_forge/persona_settings.cfg") == OK:
						var data = cfg.get_value("RUNTIME", "CharacterMap")
						if typeof(data) == TYPE_ARRAY:
							var map: Dictionary[StringName, String] = {}
							for entry in data:
								if typeof(entry) == TYPE_DICTIONARY and entry.has_all(["character_id", "path"]):
									var path = entry["path"]
									var id = entry["character_id"]
									var id_type: int = typeof(id)
									if typeof(path) != TYPE_STRING:
										continue
									elif id_type != TYPE_STRING_NAME and id_type != TYPE_STRING:
										continue
									
									if map.has(id):
										_log_msg(
												"",
												"Resource '%s' is using the ID (%s) of an already registered resource '%s'. Skipping." % [
														entry["path"],
														entry["character_id"],
														id],
												NFPluginGameHandler._LogLevel.WARNING)
									else:
										map[id] = path
							
							CharacterManager._characters.assign(map)
			else:
				if FileAccess.file_exists("res://addons/nexus_forge/settings.cfg"):
					var cfg: ConfigFile = ConfigFile.new()
					if cfg.load("res://addons/nexus_forge/settings.cfg") == OK:
						var data = cfg.get_value("PERSONA", "CharacterMap")
						if typeof(data) == TYPE_ARRAY:
							var map: Dictionary[StringName, String] = {}
							for entry in data:
								if typeof(entry) == TYPE_DICTIONARY and entry.has_all(["character_id", "path"]):
									var path = entry["path"]
									var id = entry["character_id"]
									var id_type: int = typeof(id)
									if typeof(path) != TYPE_STRING:
										continue
									elif id_type != TYPE_STRING_NAME and id_type != TYPE_STRING:
										continue
							CharacterManager._characters.assign(map)
						else:
							_log_msg(
									"",
									"Failed to load NexusForge settings",
									NFPluginGameHandler._LogLevel.WARNING)
	if QuestManager == null and ( use_quests or instantiate_disabled ):
		QuestManager = NFQuestManager.new()
	if SpeciesManager == null and instantiate_disabled:
		SpeciesManager = NFSpeciesManager.new()
	if ItemManager == null and instantiate_disabled:
		ItemManager = NFItemManager.new()
	if CurrencyManager == null and instantiate_disabled:
		CurrencyManager = NFCurrencyManager.new()
	if RecipeManager == null and instantiate_disabled:
		RecipeManager = NFRecipeManager.new()
	
	for folder_path in Blackboard._variables:
		Blackboard._variables[folder_path].make_read_only()
	
	Blackboard._variables.make_read_only()


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


func _on_item_list_changed(_id: StringName) -> void:
	_rebuild_item_cache()


func _rebuild_item_cache() -> void:
	if is_instance_valid(ItemManager):
		var new_cache: Dictionary[StringName, NFItemSheet] =\
				ItemManager._items.duplicate()
		new_cache.make_read_only()
		Items = new_cache


func _on_stat_list_changed(_id: StringName) -> void:
	_rebuild_stat_cache()


func _rebuild_stat_cache() -> void:
	if is_instance_valid(StatManager):
		var new_cache: Dictionary[StringName, NFCatalogEntryStat] =\
				StatManager._stat_entries.duplicate()
		new_cache.make_read_only()
		Stats = new_cache


func _on_trait_list_changed(_id: StringName) -> void:
	_rebuild_trait_cache()


func _rebuild_trait_cache() -> void:
	if is_instance_valid(TraitManager):
		var new_cache: Dictionary[StringName, NFCatalogEntry] =\
				TraitManager._trait_entries.duplicate()
		new_cache.make_read_only()
		Traits = new_cache


func _on_skill_list_changed(_id: StringName) -> void:
	_rebuild_skill_cache()


func _rebuild_skill_cache() -> void:
	if is_instance_valid(SkillManager):
		var new_cache: Dictionary[StringName, NFCatalogEntry] =\
				SkillManager._skills.duplicate()
		new_cache.make_read_only()
		Skills = new_cache


func _on_species_list_changed(_id: StringName) -> void:
	_rebuild_species_cache()


func _rebuild_species_cache() -> void:
	if is_instance_valid(SpeciesManager):
		var new_cache: Dictionary[StringName, NFSpeciesSheet] =\
				SpeciesManager._species.duplicate()
		new_cache.make_read_only()
		Species = new_cache


func _on_quests_list_changed() -> void:
	_rebuild_quest_cache()


func _rebuild_quest_cache() -> void:
	if is_instance_valid(QuestManager):
		var new_cache: Dictionary[StringName, NFQuest] = {}
		
		for quest_id in QuestManager._active_quests:
			new_cache[quest_id] = QuestManager._active_quests[quest_id].resource
		new_cache.make_read_only()
		Quests = new_cache


func _on_currency_list_changed(_id: StringName) -> void:
	_rebuild_currency_cache()


func _rebuild_currency_cache() -> void:
	if is_instance_valid(CurrencyManager):
		var new_cache: Dictionary[StringName, NFCurrencyEntry] =\
				CurrencyManager._currencies.duplicate()
		new_cache.make_read_only()
		Currencies = new_cache


func _on_recipe_list_changed(_id: StringName) -> void:
	_rebuild_recipe_cache()


func _rebuild_recipe_cache() -> void:
	if is_instance_valid(RecipeManager):
		var new_cache: Dictionary[StringName, NFRecipeSheet] =\
				RecipeManager._recipe_sheets.duplicate()
		new_cache.make_read_only()
		Recipes = new_cache
