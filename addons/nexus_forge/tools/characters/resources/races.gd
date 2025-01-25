@tool
class_name NFRacesRes
extends Resource

const SETTINGS_PATH: String = "nexus_forge/races_resource"

## A dictionary of species. Right now it only holds names but it can hold traits
## and other information.
@export var species: Dictionary = {
	#"humanoid": {
		#"name": "humanoid",
		#"races": {
			#"ilusk": {"name": "illuskan", "data": {},
			#"human": {"name": "human", "data": {}},
			#"goblin": {"name": "goblin", "data": {}},
			#"sheeb": {
				#"name": "sheebs",
				#"data:" : {}
				#},
		#}
	#},
}

func create_species(species_id: String) -> void:
	species[species_id] = {
			"name": "",
			"races": {},
			"data": {}}


func has_species(species_id: String) -> bool:
	return species.has(species_id)


func erase_species(species_id: String) -> void:
	species.erase(species_id)


func get_species() -> PackedStringArray:
	return PackedStringArray(species.keys())


func get_species_name(species_id: String) -> String:
	return species[species_id]["name"]


func set_species_name(species_id: String, new_name: String) -> void:
	species[species_id]["name"] = new_name


func get_species_data_keys(species_id: String) -> PackedStringArray:
	return PackedStringArray(species[species_id]["data"].keys())


func get_species_data(species_id: String, data_key: String) -> Variant:
	return species[species_id]["data"][data_key]


func set_species_data(species_id: String, data_key: String, data: Variant) -> void:
	species[species_id]["data"][data_key] = data


func erase_species_data(species_id: String, data_key: String) -> void:
	species[species_id]["data"].erase(data_key)


func create_race(on_species: String, race_id: String) -> void:
	species[on_species]["races"][race_id] = {
		"name": "",
		"data": {}}


func has_race(on_species: String, race_id: String) -> bool:
	return species[on_species]["races"].has(race_id)


func erase_race(on_species: String, race_id: String) -> void:
	species[on_species]["races"].erase(race_id)


func get_races(on_species: String) -> PackedStringArray:
	return PackedStringArray(species[on_species]["races"].keys())


func get_race_name(on_species: String, race_id: String) -> String:
	return species[on_species]["races"][race_id]["name"]


func set_race_name(on_species: String, race_id: String, new_name: String) -> void:
	species[on_species]["races"][race_id]["name"] = new_name


func get_race_data_keys(on_species: String, race_id: String) -> PackedStringArray:
	return PackedStringArray(species[on_species]["races"][race_id]["data"].keys())


func get_race_data(on_species: String, race_id: String, data_key: String) -> Variant:
	return species[on_species]["races"][race_id]["data"][data_key]


func set_race_data(on_species: String, race_id: String, data_key: String, data: Variant) -> void:
	species[on_species]["races"][race_id]["data"][data_key] = data


func erase_race_data(on_species: String, race_id: String, data_key: String) -> void:
	species[on_species]["races"][race_id]["data"].erase(data_key)


func save() -> void:
	ResourceSaver.save(self, ProjectSettings.get_setting(SETTINGS_PATH, "res://races_resource.tres"))
	emit_changed()
