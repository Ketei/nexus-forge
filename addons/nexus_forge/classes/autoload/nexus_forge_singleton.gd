extends Node
## NexusForge singleton.
##
## Contains subresources designed to parse and provide data from NexusForge's
## custom resources.


## The dialog parser in charge of loading dialogs.[br]
## The object notifies of dialog data and events through signals.
var Discourse: DialogParser
## An object containing globally-accessible variables.[br]
## The variables are nested into a folder-like structure which can also contain
## folders.
var Blackboard: BlackboardData
## A resource containing the game's item definitions.
var Items: ItemCatalog
## A resource containing custom stats data.[br]
## Custom stats will be included in all [StatBlock]'s custom stats instantiated
## with [method StatBlock.new_stat_block].
var Stats: StatCatalog
## A resource containing common and custom trait data.[br]
## Custom traits created here will also be included in all instances of
## [TraitBlock] that were created via [method TraitBlock.new_trait_block].
var Traits: TraitCatalog
## A resource containing common and custom skill data.[br]
## Custom skill created here will also be included in all instances of
## [SkillSet] that were created via [method SkillSet.new_skill_set].
var Skills: SkillCatalog
## A resource containing the game's species data.
var Species: SpeciesCatalog
## A resource containing the game's quests data.
var Quests: QuestManager
## A resource containing the game's currency data and helper methods to manage
## different currency systems.
var Currency: CurrencyCatalog
## A resource containing the game's crafting recipes.
var Recipes: RecipeCatalog

var _phrase_api: PhraseAPI = PhraseAPI.new()

func _ready() -> void:
	var use_discourse: bool = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("discourse_enabled"), true)
	var use_items: bool = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("items_enabled"), true)
	var use_talents: bool = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("talents_enabled"), true)
	var use_species: bool = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("species_enabled"), true)
	var use_quests: bool = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("quests_enabled"), true)
	var use_currencies: bool = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("currencies_enabled"), true)
	var use_recipes: bool = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("recipes_enabled"), true)
	var instantiate_disabled: bool = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("use_disabled_modules"), true)
	
	var blackboard_path: String = ProjectSettings.get_setting(
			EditorNFPlugin.get_project_settings_path("variables"), "")
	if not blackboard_path.is_empty() and ResourceLoader.exists(blackboard_path):
		var res_pre: Resource = load(blackboard_path)
		if res_pre is BlackboardData:
			Blackboard = res_pre
		else:
			printerr("[NEXUS FORGE] ProjectSettings: Invalid Blackboard.")
	
	if use_species:
		var species_path: String = ProjectSettings.get_setting(
				EditorNFPlugin.get_project_settings_path("species"), "")
		if not species_path.is_empty() and ResourceLoader.exists(species_path):
			var res_pre: Resource = load(species_path)
			if res_pre is SpeciesCatalog:
				Species = res_pre
			else:
				printerr("[NEXUS FORGE] ProjectSettings: Invalid Species.")
	
	if use_items:
		var items_path: String = ProjectSettings.get_setting(
				EditorNFPlugin.get_project_settings_path("items"), "")
		if not items_path.is_empty() and ResourceLoader.exists(items_path):
			var res_pre: Resource = load(items_path)
			if res_pre is ItemCatalog:
				Items = res_pre
			else:
				printerr("[NEXUS FORGE] ProjectSettings: Invalid Items.")
	
	if use_currencies:
		var currency_path: String = ProjectSettings.get_setting(
				EditorNFPlugin.get_project_settings_path("currency"), "")
		if not currency_path.is_empty() and ResourceLoader.exists(currency_path):
			var res_pre: Resource = load(currency_path)
			if res_pre is CurrencyCatalog:
				Currency = res_pre
			else:
				printerr("[NEXUS FORGE] ProjectSettings: Invalid Currency.")
	
	if use_recipes:
		var recipe_path: String = ProjectSettings.get_setting(
				EditorNFPlugin.get_project_settings_path("recipes"), "")
		if not recipe_path.is_empty() and ResourceLoader.exists(recipe_path):
			var res_pre: Resource = load(recipe_path)
			if res_pre is RecipeCatalog:
				Recipes = res_pre
			else:
				printerr("[NEXUS FORGE] ProjectSettings: Invalid Recipes.")
	
	if Discourse == null:
		if instantiate_disabled or use_discourse:
			Discourse = EditorDialogParser.new() if OS.has_feature("editor") else DialogParser.new()
			if use_discourse:
				Discourse.generate_locale_map()
	else:
		if use_discourse:
			Discourse.generate_locale_map()

	if Blackboard == null:
		Blackboard = BlackboardData.new()
	
	if use_talents or instantiate_disabled:
		if Stats == null:
			Stats = StatCatalog.new()
		if Traits == null:
			Traits = TraitCatalog.new()
		if Skills == null:
			Skills = SkillCatalog.new()
	
	if Quests == null and ( use_quests or instantiate_disabled ):
		Quests = QuestManager.new()
	if Species == null and ( use_species or instantiate_disabled ):
		Species = SpeciesCatalog.new()
	if Items == null and ( use_items or instantiate_disabled):
		Items = ItemCatalog.new()
	if Currency == null and ( use_currencies or instantiate_disabled ):
		Currency = CurrencyCatalog.new()
	if Recipes == null and ( use_recipes or instantiate_disabled ):
		Recipes = RecipeCatalog.new()
	
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Discourse._clear_cache() # Clearing discourse cache to prevent leaked resources.
	elif what == NOTIFICATION_TRANSLATION_CHANGED:
		if not ProjectSettings.get_setting(
				EditorNFPlugin.get_project_settings_path("discourse_sync_locale"),
				true):
			return
		
		if not is_node_ready():
			await ready
		
		if Discourse == null:
			return
		
		Discourse.locale = TranslationServer.get_locale()
		Discourse.refresh()
