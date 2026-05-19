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
	
	var blackboard_path: String = ProjectSettings.get_setting(
			EditorNFPlugin.get_project_settings_path("variables"), "")
	var species_path: String = ProjectSettings.get_setting(
			EditorNFPlugin.get_project_settings_path("species"), "")
	var items_path: String = ProjectSettings.get_setting(
			EditorNFPlugin.get_project_settings_path("items"), "")
	var currency_path: String = ProjectSettings.get_setting(
			EditorNFPlugin.get_project_settings_path("currency"), "")
	var recipe_path: String = ProjectSettings.get_setting(
			EditorNFPlugin.get_project_settings_path("recipes"), "")
	
	if not blackboard_path.is_empty() and ResourceLoader.exists(blackboard_path):
		var res_pre: Resource = load(blackboard_path)
		if res_pre is BlackboardData:
			Blackboard = res_pre
		else:
			printerr("[NEXUS FORGE] ProjectSettings: Invalid Blackboard.")
	
	if not species_path.is_empty() and ResourceLoader.exists(species_path):
		var res_pre: Resource = load(species_path)
		if res_pre is SpeciesCatalog:
			Species = res_pre
		else:
			printerr("[NEXUS FORGE] ProjectSettings: Invalid Species.")
	
	if not items_path.is_empty() and ResourceLoader.exists(items_path):
		var res_pre: Resource = load(items_path)
		if res_pre is ItemCatalog:
			Items = res_pre
		else:
			printerr("[NEXUS FORGE] ProjectSettings: Invalid Items.")
	
	if not currency_path.is_empty() and ResourceLoader.exists(currency_path):
		var res_pre: Resource = load(currency_path)
		if res_pre is CurrencyCatalog:
			Currency = res_pre
		else:
			printerr("[NEXUS FORGE] ProjectSettings: Invalid Currency.")
	
	if not recipe_path.is_empty() and ResourceLoader.exists(recipe_path):
		var res_pre: Resource = load(recipe_path)
		if res_pre is RecipeCatalog:
			Recipes = res_pre
		else:
			printerr("[NEXUS FORGE] ProjectSettings: Invalid Recipes.")
	
	if Discourse == null:
		Discourse = EditorDialogParser.new()
		if use_discourse:
			Discourse.generate_locale_map()
	if Blackboard == null:
		Blackboard = BlackboardData.new()
	if Stats == null:
		Stats = StatCatalog.new()
	if Traits == null:
		Traits = TraitCatalog.new()
	if Skills == null:
		Skills = SkillCatalog.new()
	if Quests == null:
		Quests = QuestManager.new()
	if Species == null:
		Species = SpeciesCatalog.new()
	if Items == null:
		Items = ItemCatalog.new()
	if Currency == null:
		Currency = CurrencyCatalog.new()
	if Recipes == null:
		Recipes = RecipeCatalog.new()
	
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Discourse._clear_cache() # Clearing discourse cache to prevent leaked resources.
