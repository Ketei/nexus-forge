@tool
class_name SpeciesCatalog
extends Resource


const DEFAULT_DATA: Dictionary[String, Variant] = {}


@export_storage var _species: Dictionary[StringName, Dictionary] = {
	#&"human": {
		#"parent_key": &"",
		#"name": "Human",
		#"description": "Clasic Hooman",
		#"data": {},
		#"stats": {
			#&"health": 100},
		#"skills": {
			#&"one_handed": 15},
		#"traits": {
			#&"bear_resist": 1}
	#}
}



func _species_tree_data(species_id) -> Dictionary[String, Dictionary]:
	var data: Dictionary[String, Dictionary] = {}
	var stats: Dictionary[StringName, float] = _species[species_id]["stats"].duplicate()
	var skills: Dictionary[StringName, int] = _species[species_id]["skills"].duplicate()
	var traits: Dictionary[StringName, int] = _species[species_id]["traits"].duplicate()
	
	var current_species: StringName = _species[species_id]["parent_key"]
	
	while current_species != &"" and current_species != species_id:
		for stat in _species[current_species]["stats"].keys():
			if stats.has(stat):
				continue
			stats[stat] = _species[current_species]["stats"][stat]
		
		for skill in _species[current_species]["skills"].keys():
			if skills.has(skill):
				continue
			skills[skill] = _species[current_species]["skills"][skill]
		
		for trait_id in _species[current_species]["traits"].keys():
			if traits.has(trait_id):
				continue
			traits[trait_id] = _species[current_species]["traits"][trait_id]
		
		current_species = _species[current_species]["parent_key"]
	
	data["stats"] = stats
	data["skills"] = skills
	data["traits"] = traits
	
	return data


func get_species(species_id: StringName) -> SpeciesSheet:
	if not _species.has(species_id):
		return null
	
	var new_species: SpeciesSheet = SpeciesSheet.new()
	
	var data: Dictionary[String, Dictionary] = _species_tree_data(species_id)
	var stats: Dictionary[StringName, int] = data["stats"]
	var skills: Dictionary[StringName, int] = data["skills"]
	var traits: Dictionary[StringName, int] = data["traits"]
	
	
	new_species.id = species_id
	new_species.name = _species[species_id]["name"]
	new_species.description = _species[species_id]["description"]
	new_species.data = _species[species_id]["data"].duplicate(true)
	
	for stat_property in stats.keys():
		new_species.stats.set(
				stat_property,
				stats[stat_property])
	
	for skill_property in skills.keys():
		new_species.skills.set(
				skill_property,
				skills[skill_property])
	
	for trait_property in traits.keys():
		new_species.traits.set(
				trait_property,
				traits[trait_property])
	
	return new_species


func species() -> Array[StringName]:
	var all_species: Array[StringName] = []
	all_species.assign(_species.keys())
	return all_species


func create_species(species_id: StringName) -> void:
	if _species.has(species_id):
		return
	var data: Dictionary[String, Variant] = {}
	var stats: Dictionary[StringName, float] = {}
	var skills: Dictionary[StringName, int] = {}
	var traits: Dictionary[StringName, int] = {}
	
	data.assign(DEFAULT_DATA)
	
	var new_species: Dictionary[String, Variant] = {
		"parent_key": &"",
		"name": "",
		"description": "",
		"data": data,
		"stats": stats,
		"skills": skills,
		"traits": traits}
	
	_species[species_id] = new_species


func erase_species(species_id: StringName) -> void:
	if _species.erase(species_id):
		for remaining_species in _species.keys():
			if _species[remaining_species]["parent_key"] == species_id:
				_species[remaining_species]["parent_key"] = &""


func link_species(species_id: StringName, subspecies: StringName) -> void:
	if ( species_id.is_empty() or _species.has(species_id) ) and _species.has(subspecies):
		_species[subspecies]["parent_key"] = species_id


func get_parent_species(from_species: StringName) -> StringName:
	if _species.has(from_species):
		return _species[from_species]["parent_key"]
	return &""


func has_species(species_id: StringName) -> bool:
	return _species.has(species_id)


func get_species_name(species_id: StringName) -> String:
	if _species.has(species_id):
		return _species[species_id]["name"]
	return ""


func set_species_name(species_id: StringName, new_name: String) -> void:
	if _species.has(species_id):
		_species[species_id]["name"] = new_name


func get_species_description(species_id: StringName) -> String:
	if _species.has(species_id):
		return _species[species_id]["description"]
	return ""


func set_species_description(species_id: StringName, description: String) -> void:
	if _species.has(species_id):
		_species[species_id]["description"] = description


func set_species_data(species_id: StringName, data_key: String, data: Variant) -> void:
	if not _species.has(species_id):
		return
	
	if data == null:
		if _species[species_id]["data"].has(data_key):
			_species[species_id]["data"].erase(data_key)
	else:
		_species[species_id]["data"][data_key] = data


func get_species_data(species_id: StringName, data_key: String) -> Variant:
	if _species.has(species_id) and _species[species_id]["data"].has(data_key):
		return _species[species_id]["data"][data_key]
	return null


func has_species_data(species_id: StringName, data_key: String) -> bool:
	return _species.has(species_id) and _species[species_id]["data"].has(data_key)


func species_data_keys(species_id: StringName) -> Array[String]:
	var all_keys: Array[String] = []
	if _species.has(species_id):
		all_keys.assign(_species[species_id]["data"].keys())
	return all_keys


func clear_species_data(species_id: StringName) -> void:
	if _species.has(species_id):
		_species[species_id]["data"].clear()


func get_species_stat(species_id: StringName, stat_id: StringName) -> float:
	if _species.has(species_id) and _species[species_id]["stats"].has(stat_id):
		return _species[species_id]["stats"][stat_id]
	return 0


func set_species_stat(species_id: StringName, stat_id: StringName, value: float) -> void:
	if _species.has(species_id):
		_species[species_id]["stats"][stat_id] = value


func species_has_stat(species_id: StringName, stat_id: StringName) -> bool:
	return _species.has(species_id) and _species[species_id]["stats"].has(stat_id)


func erase_species_stat(species_id: StringName, stat_id: StringName) -> void:
	if _species.has(species_id) and _species[species_id]["stats"].has(stat_id):
		_species[species_id]["stats"].erase(stat_id)


func set_species_skill(species_id: StringName, skill_id: StringName, value: int) -> void:
	if _species.has(species_id):
		_species[species_id]["skills"][skill_id] = value


func get_species_skill(species_id: StringName, skill_id: StringName) -> int:
	if _species.has(species_id) and _species[species_id]["skills"].has(skill_id):
		return _species[species_id]["skills"][skill_id]
	return 0


func species_has_skill(species_id: StringName, skill_id: StringName) -> bool:
	return _species.has(species_id) and _species[species_id]["skills"].has(skill_id)


func erase_species_skill(species_id: StringName, skill_id: StringName) -> void:
	if _species.has(species_id) and _species[species_id]["skills"].has(skill_id):
		_species[species_id]["skills"].erase(skill_id)


func set_species_trait(species_id: StringName, trait_id: StringName, value: int) -> void:
	if _species.has(species_id):
		_species[species_id]["traits"][trait_id] = value


func get_species_trait(species_id: StringName, trait_id: StringName) -> int:
	if _species.has(species_id) and _species[species_id]["traits"].has(trait_id):
		return _species[species_id]["traits"][trait_id]
	return 0


func species_has_trait(species_id: StringName, trait_id: StringName) -> bool:
	return _species.has(species_id) and _species[species_id]["traits"].has(trait_id)


func erase_species_trait(species_id: StringName, trait_id: StringName) -> void:
	if _species.has(species_id) and _species[species_id]["traits"].has(trait_id):
		_species[species_id]["traits"].erase(trait_id)


func clear_species_stats(species_id: StringName) -> void:
	if _species.has(species_id):
		_species[species_id]["stats"].clear()


func clear_species_skills(species_id: StringName) -> void:
	if _species.has(species_id):
		_species[species_id]["skills"].clear()


func clear_species_traits(species_id: StringName) -> void:
	if _species.has(species_id):
		_species[species_id]["traits"].clear()
