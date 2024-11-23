class_name NFHandler
extends Node


var Variables: NFVariablesRes = null

var Races: NFRacesRes = null

var Characters: NFCharacterDBRes = null

var Factions: NFFactionRes = null

var Items: NFItemsRes = null

var Talents: NFTalentsRes = null

var Callables: NFCallablesRes = null


func _ready() -> void:
	var variables_path: String = ProjectSettings.get_setting(NFVariablesRes.SETTINGS_PATH, "")
	var races_path: String = ProjectSettings.get_setting(NFRacesRes.SETTINGS_PATH, "")
	var character_path: String = ProjectSettings.get_setting(NFCharacterDBRes.SETTINGS_PATH, "")
	var factions_path: String = ProjectSettings.get_setting(NFFactionRes.SETTINGS_PATH, "")
	var talents_path: String = ProjectSettings.get_setting(NFTalentsRes.SETTINGS_PATH, "")
	var items_path: String = ProjectSettings.get_setting(NFItemsRes.SETTINGS_PATH, "")
	
	if not variables_path.is_empty() and ResourceLoader.exists(variables_path):
		var _preload: Resource = load(variables_path)
		if _preload is NFVariablesRes:
			Variables = _preload
		else:
			printerr("[NEXUS FORGE] Variables resource provided in variables isn't NFVariablesRes")
	
	if not races_path.is_empty() and ResourceLoader.exists(races_path):
		var _preload: Resource = load(races_path)
		if _preload is NFRacesRes:
			Races = _preload
		else:
			printerr("[NEXUS FORGE] Race resource provided in variables isn't NFRacesRes")
	
	if not character_path.is_empty() and ResourceLoader.exists(character_path):
		var _preload: Resource = load(character_path)
		if _preload is NFCharacterDBRes:
			Characters = _preload
		else:
			printerr("[NEXUS FORGE] Character resource provided in variables isn't NFCharacterDBRes")
	
	if not factions_path.is_empty() and ResourceLoader.exists(factions_path):
		var _preload: Resource = load(factions_path)
		if _preload is NFFactionRes:
			Factions = _preload
		else:
			printerr("[NEXUS FORGE] Factions resource provided in variables isn't NFFactionRes")
	
	if not talents_path.is_empty() and ResourceLoader.exists(talents_path):
		var _preload: Resource = load(talents_path)
		if _preload is NFTalentsRes:
			Talents = _preload
		else:
			printerr("[NEXUS FORGE] Talents resource provided in variables isn't NFTalentsRes")
	
	if not items_path.is_empty() and ResourceLoader.exists(items_path):
		var _preload: Resource = load(items_path)
		if _preload is NFItemsRes:
			Items = _preload
		else:
			printerr("[NEXUS FORGE] Talents resource provided in variables isn't NFItemsRes")
	
	if Variables == null:
		Variables = NFVariablesRes.new()
	if Races == null:
		Races = NFRacesRes.new()
	if Characters == null:
		Characters = NFCharacterDBRes.new()
	if Factions == null:
		Factions = NFFactionRes.new()
	if Talents == null:
		Talents = NFTalentsRes.new()
	if Items == null:
		Items = NFItemsRes.new()
	
	Callables = NFCallablesRes.new()
