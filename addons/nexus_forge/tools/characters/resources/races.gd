class_name NFRacesRes
extends Resource


## A list of the different valid genders among species
enum Genders {
	MALE, ## Penis and pecs
	FEMALE, ## Pussy and breasts
	GYNOMORPH, ## Penis and breasts
	ANDROMORPH, ## Pussy and pecs
}

enum Flags {
	ESSENTIAL,
	RESPAWN,
	INVULNERABLE,
	TEST,
	CHILD,
	FERTILE,
	VIRILE,
}

const GENDER_DATA: Dictionary = {
	Genders.MALE: {"icon": ""},
	Genders.FEMALE: {"icon": ""},
	Genders.GYNOMORPH: {"icon": ""},
	Genders.ANDROMORPH: {"icon": ""},
}

const STATS: Dictionary = {
	"hp": {"name": "health"},
	"stam": {"name": "stamina"},
	"mp": {"name": "mana"},
}


const RACE_RES_PATH: String = "nexus_forge/races_resource_path"

## A dictionary of species. Right now it only holds names but it can hold traits
## and other information.
@export var species: Dictionary = {
	#"humanoid": {
		#"name": "humanoid",
		#"races": {
			#"ilusk": {"name": "illuskan", "genders": [Genders.FEMALE]},
			#"human": {"name": "human", "genders": [Genders.MALE, Genders.FEMALE]},
			#"goblin": {"name": "goblin", "genders": [Genders.MALE]},
			#"sheeb": {
				#"name": "sheebs",
				#"genders": [Genders.GYNOMORPH],
				#"desc": "",
				#},
		#}
	#},
	#"pokemon": {
		#"name": "pokemon",
		#"races": {
			#"sparky": {
				#"name": "jolteon",
				#"desc": "",
				#"genders": [Genders.MALE, Genders.FEMALE],
				#"custom_data": {},
				#"stats": ["health", "stamina", "lust"]}
		#}
	#}
}


func get_species() -> Array:
	return species.keys() 


func get_species_name(species_id: String) -> String:
	return species[species_id]["name"]


func get_races(species_id: String) -> Array:
	return species[species_id]["races"].keys()


func get_race_stats(species_id: String, race_id: String) -> Array:
	return species[species_id]["races"][race_id]["stats"]


func get_race_name(species_id: String, race_id: String) -> String:
	return species[species_id]["races"][race_id]["name"]


func get_race_desc(species_id: String, race_id: String) -> String:
	return species[species_id]["races"][race_id]["desc"]


func get_race_genders(species_id: String, race_id: String) -> Array[int]:
	var races_genders: Array[int] = []
	races_genders.assign(species[species_id]["races"][race_id]["genders"])
	return races_genders


func create_species(species_id: String) -> void:
	species[species_id] = {
			"name": "",
			"races": {}
		}


func set_species_name(species_id:String, new_name: String) -> void:
	species[species_id]["name"] = new_name


func create_race(species_id: String, race_id: String) -> void:
	species[species_id]["races"][race_id] = {
		"name": "",
		"genders": [],
		"desc": "",
		"stats": [],
		"custom_data": {}
	}


func set_race_custom_data(species_id: String, race_id: String, data_key: String, data_val: Variant) -> void:
	species[species_id]["races"][race_id]["custom_data"][data_key] = data_val


func delete_race_custom_data(species_id: String, race_id: String, data_key: String) -> void:
	species[species_id]["races"][race_id]["custom_data"].erase(data_key)


func has_race_custom_data(species_id: String, race_id: String, data_key: String) -> bool:
	return species[species_id]["races"][race_id]["custom_data"].has(data_key)


func get_race_custom_data_dict(species_id: String, race_id: String) -> Dictionary:
	return species[species_id]["races"][race_id]["custom_data"]


func set_race_custom_data_dict(species_id: String, race_id: String, data_dict: Dictionary) -> void:
	species[species_id]["races"][race_id]["custom_data"] = data_dict


func clear_race_custom_data(species_id: String, race_id: String) -> void:
	species[species_id]["races"][race_id]["custom_data"].clear()


func assign_race_genders(species_id: String, race_id: String, genders: Array) -> void:
	species[species_id]["races"][race_id]["genders"].assign(genders)


func assign_race_stats(species_id: String, race_id: String, stats: Array) -> void:
	species[species_id]["races"][race_id]["stats"].assign(stats)


func get_race_custom_data(species_id: String, race_id: String, data_key: String) -> Variant:
	return species[species_id]["races"][race_id]["custom_data"][data_key]


func set_race_name(species_id: String, race_id: String, new_name: String) -> void:
	species[species_id]["races"][race_id]["name"] = new_name


func add_race_gender(species_id: String, race_id: String, gender: Genders) -> void:
	if not species[species_id]["races"][race_id]["genders"].has(gender):
		species[species_id]["races"][race_id]["genders"].append(gender as int)


func set_race_description(species_id: String, race_id: String, description: String) -> void:
	species[species_id]["races"][race_id]["desc"] = description


func add_race_stat(species_id: String, race_id: String, stat_id: String) -> void:
	if not species[species_id]["races"][race_id]["stats"].has(stat_id):
		species[species_id]["races"][race_id]["stats"].append(stat_id)


func has_race(species_id: String, race_id: String) -> bool:
	return species[species_id]["races"].has(race_id)


func has_species(species_id: String) -> bool:
	return species.has(species_id)


func remove_race(species_id: String, race_id: String) -> void:
	species[species_id]["races"].erase(race_id)


func remove_species(species_id: String) -> void:
	species.erase(species_id)


func save() -> void:
	ResourceSaver.save(self, ProjectSettings.get_setting(RACE_RES_PATH, "res://races_resource.tres"))


static func get_stat_name(stat_id: String) -> String:
	if STATS.has(stat_id):
		return STATS[stat_id]["name"]
	return ""


static func get_gender_name(gender_id: Genders) -> String:
	match gender_id:
		Genders.MALE:
			return "male"
		Genders.FEMALE:
			return "female"
		Genders.GYNOMORPH:
			return "gynomorph"
		Genders.ANDROMORPH:
			return "andromorph"
		_:
			return "unknown"
