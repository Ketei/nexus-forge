class_name NexusForgeRaces
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


## A dictionary of species. Right now it only holds names but it can hold traits
## and other information.
var species: Dictionary = {
	"humanoid": {
		"name": "humanoid",
		"races": {
			"ilusk": {"name": "illuskan", "genders": [Genders.FEMALE]},
			"human": {"name": "human", "genders": [Genders.MALE, Genders.FEMALE]},
			"goblin": {"name": "goblin", "genders": [Genders.MALE]},
			"sheeb": {
				"name": "sheebs",
				"genders": [Genders.GYNOMORPH],
				"desc": "",
				},
		}
	},
	"pokemon": {
		"name": "pokemon",
		"races": {
			"sparky": {
				"name": "jolteon",
				"genders": [Genders.MALE, Genders.FEMALE],
				"stats": ["health", "stamina", "lust"]},
			"nidoking": {
				"name": "nidoking",
				"genders": [Genders.MALE],
				"stats": ["health", "stamina", "lust"]}
		}
	}
}


func get_species_ids() -> Array:
	return species.keys()


func get_species_name(species_id: String) -> String:
	return species[species_id]["name"]


func get_races(species_id: String) -> Array:
	return species[species_id]["subspecies"].keys()


func get_race_name(species_id: String, race_id: String) -> String:
	return species[species_id]["races"][race_id]["name"]


func get_race_genders(species_id: String, race_id: String) -> Array[Genders]:
	var races_genders: Array[Genders] = []
	races_genders.assign(species[species_id]["races"][race_id]["genders"])
	return races_genders


func get_gender_name(gender_id: Genders) -> String:
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


func create_new_species(species_id: String, species_name: String) -> void:
	species[species_id] = {
			"name": species_name,
			"races": {}
		}


func create_race(species_id: String, race_id: String, race_name: String) -> void:
	var genders_array: Array[Genders] = []
	species[species_id]["races"][race_id] = {
		"name": race_name,
		"genders": genders_array,
		"desc": ""
	}


func add_race_gender(species_id: String, race_id: String, gender: Genders) -> void:
	if not species[species_id]["races"][race_id]["genders"].has(gender):
		species[species_id]["races"][race_id]["genders"].append(gender)


func set_race_description(species_id: String, race_id: String, description: String) -> void:
	species[species_id]["races"][race_id]["desc"] = description


func add_race_stat(species_id: String, race_id: String, stat_id: String) -> void:
	if not species[species_id]["races"][race_id]["stats"].has(stat_id):
		species[species_id]["races"][race_id]["stats"].append(stat_id)
