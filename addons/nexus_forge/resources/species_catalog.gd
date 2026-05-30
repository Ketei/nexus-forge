@tool
@icon("res://addons/nexus_forge/icons/dna.svg")
class_name SpeciesCatalog
extends Resource
## A resource holding species basic data.
##
## This resource holds values for names, description, data, stats, skills and
## traits in a raw form(String, int, float, etc.)[br]
## For stats, skills and traits it can hold the values for inexistent properties
## but these will be ignored when calling a method that returns an object.


# This is not meant to be edited manually, as the exporter will clean it,
# losing any custom species stats/skills/traits added manually.
@export_storage var _species: Dictionary[StringName, Dictionary] = {}


func _species_stat_data(species_id: StringName, use_inheritance: bool) -> Dictionary[StringName, float]:
	var stats: Dictionary[StringName, float] = {}
	
	if not _species.has(species_id):
		return stats
	
	stats.assign(_species[species_id]["stats"])
	
	if not use_inheritance:
		return stats
	
	var recessive_parent: StringName = _species[species_id]["parent_recessive"]
	var dominant_parent: StringName = _species[species_id]["parent_dominant"]
	var explored_species: Dictionary[StringName, Variant] = {
		dominant_parent: null}
	
	if not recessive_parent.is_empty():
		var dominant_genes: Dictionary[StringName, float] = _species[dominant_parent]["stats"]
		var recessive_genes: Dictionary[StringName, float] = _species[recessive_parent]["stats"]
		var hybrid_genes: Dictionary[StringName, float] = {}
		
		for stat_id in dominant_genes.keys():
			if recessive_genes.has(stat_id):
				hybrid_genes[stat_id] = roundf(( dominant_genes[stat_id] * 0.75) + ( recessive_genes[stat_id] / 4.0 ))
			else:
				hybrid_genes[stat_id] = dominant_genes[stat_id]
		
		for stat_id in recessive_genes.keys():
			if hybrid_genes.has(stat_id):
				continue
			hybrid_genes[stat_id] = roundf(recessive_genes[stat_id] / 2.0)
		
		stats.merge(hybrid_genes)
		explored_species[recessive_parent] = null
	else:
		stats.merge(_species[dominant_parent]["stats"])
	
	dominant_parent = _species[dominant_parent]["parent_dominant"]
	
	var dilution_multiplier: float = 1.0
	var dilution_factor: float = clampf(ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("species_genetic_dilution"), 0.0), 0.0, 1.0)
	
	if dilution_multiplier <= dilution_factor:
		return stats
	
	while 0 < dilution_multiplier and not dominant_parent.is_empty() and not explored_species.has(dominant_parent):
		dilution_multiplier -= dilution_factor
		explored_species[dominant_parent] = null
		for stat in _species[dominant_parent]["stats"].keys():
			if stats.has(stat):
				continue
			stats[stat] = roundf( _species[dominant_parent]["stats"][stat] * dilution_multiplier )
		
		dominant_parent = _species[dominant_parent]["parent_dominant"]
	
	return stats


func _species_skill_data(species_id: StringName, use_inheritance: bool) -> Dictionary[StringName, int]:
	var skills: Dictionary[StringName, int] = {}
	
	if not _species.has(species_id):
		return skills
	
	skills.assign(_species[species_id]["skills"])
	
	if not use_inheritance:
		return skills
	
	var recessive_parent: StringName = _species[species_id]["parent_recessive"]
	var dominant_parent: StringName = _species[species_id]["parent_dominant"]
	var explored_species: Dictionary[StringName, Variant] = {
		dominant_parent: null}
	
	if not recessive_parent.is_empty():
		var dominant_genes: Dictionary[StringName, int] = _species[dominant_parent]["skills"]
		var recessive_genes: Dictionary[StringName, int] = _species[recessive_parent]["skills"]
		var hybrid_genes: Dictionary[StringName, int] = {}
		
		for skill_id in dominant_genes.keys():
			if recessive_genes.has(skill_id):
				hybrid_genes[skill_id] = roundf(( dominant_genes[skill_id] * 0.75) + ( recessive_genes[skill_id] / 4.0 ))
			else:
				hybrid_genes[skill_id] = dominant_genes[skill_id]
		
		for skill_id in recessive_genes.keys():
			if hybrid_genes.has(skill_id):
				continue
			hybrid_genes[skill_id] = roundi(recessive_genes[skill_id] / 2.0)
		
		skills.merge(hybrid_genes)
		explored_species[recessive_parent] = null
	else:
		skills.merge(_species[dominant_parent]["skills"])
	
	dominant_parent = _species[dominant_parent]["parent_dominant"]
	
	var dilution_multiplier: float = 1.0
	var dilution_factor: float = clampf(ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("species_genetic_dilution"), 0.0), 0.0, 1.0)
	
	while 0 < dilution_multiplier and not dominant_parent.is_empty() and not explored_species.has(dominant_parent):
		dilution_multiplier -= dilution_factor
		for skill in _species[dominant_parent]["skills"].keys():
			if skills.has(skill):
				continue
			skills[skill] = roundi(_species[dominant_parent]["skills"][skill] * dilution_multiplier)
			
		dominant_parent = _species[dominant_parent]["parent_dominant"]
	
	return skills


func _species_trait_data(species_id: StringName, use_inheritance: bool) -> Dictionary[StringName, int]:
	var traits: Dictionary[StringName, int] = {}
	if not _species.has(species_id):
		return traits
	
	traits.assign(_species[species_id]["traits"])
	
	if not use_inheritance:
		return traits
	
	var recessive_parent: StringName = _species[species_id]["parent_recessive"]
	var dominant_parent: StringName = _species[species_id]["parent_dominant"]
	var explored_species: Dictionary[StringName, Variant] = {
		dominant_parent: null}
	
	if not recessive_parent.is_empty():
		var dominant_genes: Dictionary[StringName, int] = _species[dominant_parent]["traits"]
		var recessive_genes: Dictionary[StringName, int] = _species[recessive_parent]["traits"]
		var hybrid_genes: Dictionary[StringName, int] = {}
		
		for trait_id in dominant_genes.keys():
			if recessive_genes.has(trait_id):
				hybrid_genes[trait_id] = roundf(( dominant_genes[trait_id] * 0.75) + ( recessive_genes[trait_id] / 4.0 ))
			else:
				hybrid_genes[trait_id] = dominant_genes[trait_id]
		
		for trait_id in recessive_genes.keys():
			if hybrid_genes.has(trait_id):
				continue
			hybrid_genes[trait_id] = roundi(recessive_genes[trait_id] / 2.0)
		
		traits.merge(hybrid_genes)
		explored_species[recessive_parent] = null
	else:
		traits.merge(_species[dominant_parent]["traits"])
	
	dominant_parent = _species[dominant_parent]["parent_dominant"]
	
	var dilution_multiplier: float = 1.0
	var dilution_factor: float = clampf(ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("species_genetic_dilution"), 0.0), 0.0, 1.0)
	
	while 0 < dilution_multiplier and not dominant_parent.is_empty() and not explored_species.has(dominant_parent):
		dilution_multiplier -= dilution_factor
		for trait_id in _species[dominant_parent]["traits"].keys():
			if traits.has(trait_id):
				continue
			traits[trait_id] = _species[dominant_parent]["traits"][trait_id]
			
		dominant_parent = _species[dominant_parent]["parent_dominant"]
	
	return traits


## Returns a [SpeciesSheet] with data, stats, skills and traits of the species.
## Stats, skills and traits will have inherited values from the parent species.[br]
## Returns [code]null[/code] if the species is not found.
func get_species(species_id: StringName, with_inheritance: bool) -> SpeciesSheet:
	if not _species.has(species_id):
		return null
	
	var new_species: SpeciesSheet = SpeciesSheet.new()
	
	var stats: Dictionary[StringName, float] = _species_stat_data(species_id, with_inheritance)
	var skills: Dictionary[StringName, int] = _species_skill_data(species_id, with_inheritance)
	var traits: Dictionary[StringName, int] = _species_trait_data(species_id, with_inheritance)
	
	new_species.id = species_id
	new_species.name = _species[species_id]["name"]
	new_species.description = _species[species_id]["description"]
	new_species.custom_data = _species[species_id]["data"].duplicate(true)
	new_species.stats = get_species_stats(species_id)
	new_species.skills = get_species_skills(species_id)
	new_species.traits = get_species_traits(species_id)
	
	return new_species


## Returns an array of all registered species.
func species() -> Array[StringName]:
	var all_species: Array[StringName] = []
	all_species.assign(_species.keys())
	return all_species


## Creates a new species with [param species_id] unless it already exists.
func create_species(species_id: StringName, parent_species: StringName = &"", recessive_species: StringName = &"") -> void:
	if _species.has(species_id):
		return
	var data: Dictionary[String, Variant] = {}
	var stats: Dictionary[StringName, float] = {}
	var skills: Dictionary[StringName, int] = {}
	var traits: Dictionary[StringName, int] = {}
	var default_data: Dictionary = SpeciesSheet.new().custom_data.duplicate(true)
	
	data.assign(default_data)
	
	var new_species: Dictionary[String, Variant] = {
		"parent_dominant": parent_species,
		"parent_recessive": recessive_species,
		"name": "",
		"description": "",
		"data": data,
		"stats": stats,
		"skills": skills,
		"traits": traits}
	
	_species[species_id] = new_species


## Creates a new species using a [SpeciesSheet]. Creation will fail if the species
## already exists.[br]
## [param subspecies_of] will allow you to set [param species_sheet] as a subspecies
## as long as [param subspecies_of] exists. If not it'll be set as a "top-level"
## species.
func register_species(species_sheet: SpeciesSheet, subspecies_of: StringName = &"", recessive_subspecies: StringName = &"") -> void:
	if _species.has(species_sheet.id):
		return
	
	var stats: Dictionary[StringName, float] = {}
	var skills: Dictionary[StringName, int] = {}
	var traits: Dictionary[StringName, int] = {}
	
	if species_sheet.stats != null:
		var stat_block: Dictionary[StringName, int] = StatBlock.stats()
		for stat_id in stat_block.keys():
			var stat_value = species_sheet.stats.get(stat_id)
			if stat_value == null or 0 == stat_value:
				continue
			stats[stat_id] = stat_value
	
	if species_sheet.skills != null:
		for skill_id in SkillSet.skills():
			var skill_value = species_sheet.skills.get(skill_id)
			if skill_value == null or 0 == skill_value:
				continue
			skills[skill_id] = int(skill_value)
	
	if species_sheet.traits != null:
		for trait_id in TraitBlock.traits():
			var trait_value = species_sheet.traits.get(trait_id)
			if trait_value == null or 0 == trait_value:
				continue
			traits[trait_id] = int(trait_value)
	
	var new_species: Dictionary[String, Variant] = {
		"parent_dominant": subspecies_of,
		"parent_recessive": recessive_subspecies,
		"name": species_sheet.name,
		"description": species_sheet.description,
		"data": species_sheet.custom_data.duplicate(true),
		"stats":stats,
		"skills": skills,
		"traits": traits}
	
	_species[species_sheet.id] = new_species


## Erases the given species and clears the link of all subspecies linked
## to [param species_id].
func erase_species(species_id: StringName) -> void:
	if _species.erase(species_id):
		for remaining_species in _species.keys():
			if _species[remaining_species]["parent_dominant"] == species_id:
				_species[remaining_species]["parent_dominant"] = &""
			if _species[remaining_species]["parent_recessive"] == species_id:
				_species[remaining_species]["parent_recessive"] = &""


## Sets the [param species_id] to be a subspecies of [param parent_species].
func link_species(species_id: StringName, parent_species: StringName, recessive_species: StringName = &"") -> void:
	if not _species.has_all([species_id, parent_species]):
		return
	
	_species[species_id]["parent_dominant"] = parent_species
	
	if not recessive_species.is_empty() and _species.has(recessive_species):
		_species[species_id]["parent_recessive"] = recessive_species


## Returns the parent species of [param of_species].
func get_dominant_species_of(species_id: StringName) -> StringName:
	if _species.has(species_id):
		return _species[species_id]["parent_dominant"]
	return &""


func get_recessive_species_of(species_id: StringName) -> StringName:
	if _species.has(species_id):
		return _species[species_id]["parent_recessive"]
	return &""


## Returns [code]true[/code] if [param species_id] is registered.
func has_species(species_id: StringName) -> bool:
	return _species.has(species_id)


## Returns the name of [param species_id]. Returns an empty string if the species
## isn't registered.
func get_species_name(species_id: StringName) -> String:
	if _species.has(species_id):
		return _species[species_id]["name"]
	return ""


## Sets the species name of [param species_id] to [param new_name]
func set_species_name(species_id: StringName, new_name: String) -> void:
	if _species.has(species_id):
		_species[species_id]["name"] = new_name


## Returns the description of [param species_id]. Returns an empty string if
## the species isn't registered.
func get_species_description(species_id: StringName) -> String:
	if _species.has(species_id):
		return _species[species_id]["description"]
	return ""


## Sets the description of [param species_id] to [param new_name].
func set_species_description(species_id: StringName, description: String) -> void:
	if _species.has(species_id):
		_species[species_id]["description"] = description


## Sets the value of [param data_key] to [param data] of the [param species_id].
## If [param data] is [code]null[/code] then [param data_key] is erased.
func set_species_data(species_id: StringName, data_key: String, data: Variant) -> void:
	if not _species.has(species_id):
		return
	
	if data == null:
		if _species[species_id]["data"].has(data_key):
			_species[species_id]["data"].erase(data_key)
	else:
		_species[species_id]["data"][data_key] = data


## Returns the data with [param data_key] from the [param species_id] or
## [code]null[/code] if the species isn't registered or key doesn't exist.
func get_species_data(species_id: StringName, data_key: String) -> Variant:
	if _species.has(species_id) and _species[species_id]["data"].has(data_key):
		return _species[species_id]["data"][data_key]
	return null


## Returns [code]true[/code] if [param species_id] has custom data with key
## [param data_key].
func has_species_data(species_id: StringName, data_key: String) -> bool:
	return _species.has(species_id) and _species[species_id]["data"].has(data_key)


## Returns an array with all custom data keys that [param species_id] has.
func species_data_keys(species_id: StringName) -> Array[String]:
	var all_keys: Array[String] = []
	if _species.has(species_id):
		all_keys.assign(_species[species_id]["data"].keys())
	return all_keys


## Clears all the custom data from [param species_id].
func clear_species_data(species_id: StringName) -> void:
	if _species.has(species_id):
		_species[species_id]["data"].clear()


## Returns the value of [param stat_id] assigned to the species with
## [param species_id] or 0 if the stat isn't assigned on the species.
func get_species_stat_value(species_id: StringName, stat_id: StringName) -> float:
	if _species.has(species_id) and _species[species_id]["stats"].has(stat_id):
		return _species[species_id]["stats"][stat_id]
	return 0


## Returns a [StatBlock] with the stats of the [param species_id].[br]
## The species will have inherited the stats of the parent species if
## [param inherit] is [code]true[/code].
func get_species_stats(species_id: StringName, inherit: bool = true) -> StatBlock:
	var new_block: StatBlock = StatBlock.new()
	var data_stats: Dictionary[StringName, float] = _species_stat_data(species_id, inherit)
	
	var properties: Dictionary[StringName, int] = StatBlock.stats()
	
	for stat in data_stats.keys():
		if not properties.has(stat):
			continue
		
		var val_range: ValueRange = new_block.get(stat)
		if val_range == null:
			val_range = RangeInt.new() if properties[stat] == TYPE_INT else RangeFloat.new()
			new_block.set(stat, val_range)
		
		val_range.allow_greater = true
		val_range.allow_lesser = true
		
		if properties[stat] == TYPE_INT:
			val_range.value = int(data_stats[stat])
		elif properties[stat] == TYPE_FLOAT:
			val_range.value = data_stats[stat]
	
	return new_block


## Sets the stat [param stat_id] to [param value] on the [param species_id].
func set_species_stat_value(species_id: StringName, stat_id: StringName, value: float) -> void:
	if _species.has(species_id):
		_species[species_id]["stats"][stat_id] = value


## Sets [param species_id] stats to match the values on [param stats].[br]
## Stats with a value of 0 are ignored.
func set_species_stats(species_id: StringName, stats: StatBlock) -> void:
	if not _species.has(species_id):
		return
	
	var stat_data: Dictionary[StringName, int] = StatBlock.stats()
	
	for stat_id in stat_data.keys():
		var stat_value: float = stats.get(stat_id).value
		if stat_value != 0:
			_species[species_id]["stats"][stat_id] = stat_value


## Returns [code]true[/code] if [param species_id] has [param stat_id] assigned.
func species_has_stat(species_id: StringName, stat_id: StringName) -> bool:
	return _species.has(species_id) and _species[species_id]["stats"].has(stat_id)


## Removes the [param stat_id] from the [param species_id] if it had it assigned.
func erase_species_stat(species_id: StringName, stat_id: StringName) -> void:
	if _species.has(species_id) and _species[species_id]["stats"].has(stat_id):
		_species[species_id]["stats"].erase(stat_id)


## Sets the [param skill_id] to [param value] on [param species_id].
func set_species_skill_value(species_id: StringName, skill_id: StringName, value: int) -> void:
	if _species.has(species_id):
		_species[species_id]["skills"][skill_id] = value


## Sets [param species_id] skills to match the values on [param skills].[br]
## Skills with a value of 0 are ignored.
func set_species_skills(species_id: StringName, skills: SkillSet) -> void:
	if not _species.has(species_id):
		return
	
	for skill in SkillSet.skills():
		var value: int = skills.get(skill)
		if value != 0:
			_species[species_id]["skills"][skill] = value


## Returns the value of [param skill_id] assigned to the species with
## [param species_id] or 0 if the skill isn't assigned on the species.
func get_species_skill_value(species_id: StringName, skill_id: StringName) -> int:
	if _species.has(species_id) and _species[species_id]["skills"].has(skill_id):
		return _species[species_id]["skills"][skill_id]
	return 0


## Returns a [SkillSet] with the skills of the [param species_id].[br]
## The species will have inherited the skills of the parent species if
## [param inherit] is [code]true[/code].
func get_species_skills(species_id: StringName, inherit: bool = true) -> SkillSet:
	var new_set: SkillSet = SkillSet.new()
	var data_stats: Dictionary[StringName, int] = _species_skill_data(species_id, inherit)
	
	var properties: Array[StringName] = SkillSet.skills()
	
	for stat in data_stats.keys():
		if not properties.has(stat):
			continue
		new_set.set(stat, data_stats[stat])
	
	return new_set


## Returns true if [param species_id] has a [param skill_id] assigned.
func species_has_skill(species_id: StringName, skill_id: StringName) -> bool:
	return _species.has(species_id) and _species[species_id]["skills"].has(skill_id)


## Erases the assigned [param skill_id] from the [param species_id].
func erase_species_skill(species_id: StringName, skill_id: StringName) -> void:
	if _species.has(species_id) and _species[species_id]["skills"].has(skill_id):
		_species[species_id]["skills"].erase(skill_id)


## Sets [param trait_id] to [param value] on the [param species_id].
func set_species_trait_value(species_id: StringName, trait_id: StringName, value: int) -> void:
	if _species.has(species_id):
		_species[species_id]["traits"][trait_id] = value


## Sets [param species_id] traits to match the values on [param traits].[br]
## Traits with a value of 0 are ignored.
func set_species_traits(species_id: StringName, traits: TraitBlock) -> void:
	if not _species.has(species_id):
		return
	
	for trait_id in TraitBlock.traits():
		var trait_value: int = traits.get(trait_id)
		if trait_value != 0:
			_species[species_id]["traits"][trait_id] = trait_value


## Returns the value of [param trait_id] assigned to the species with
## [param species_id] or 0 if the trait isn't assigned on the species.
func get_species_trait_value(species_id: StringName, trait_id: StringName) -> int:
	if _species.has(species_id) and _species[species_id]["traits"].has(trait_id):
		return _species[species_id]["traits"][trait_id]
	return 0

## Returns a [TraitBlock] with the traits of the [param species_id].[br]
## The species will have inherited the traits of the parent species if
## [param inherit] is [code]true[/code].
func get_species_traits(species_id: StringName, inherit: bool = true) -> TraitBlock:
	var new_block: TraitBlock = TraitBlock.new()
	var data_stats: Dictionary[StringName, int] = _species_trait_data(species_id, inherit)
	
	var properties: Array[StringName] = TraitBlock.traits()
	
	for trait_id in data_stats.keys():
		if not properties.has(trait_id):
			continue
		new_block.set(trait_id, data_stats[trait_id])
	
	return new_block


## Returns [code]true[/code] if [param species_id] has an assigned [param trait_id].
func species_has_trait(species_id: StringName, trait_id: StringName) -> bool:
	return _species.has(species_id) and _species[species_id]["traits"].has(trait_id)


## Erases the assigned [param trait_id] from the [param species_id].
func erase_species_trait(species_id: StringName, trait_id: StringName) -> void:
	if _species.has(species_id) and _species[species_id]["traits"].has(trait_id):
		_species[species_id]["traits"].erase(trait_id)


## Erases all the assigned stats of [param species_id].
func clear_species_stats(species_id: StringName) -> void:
	if _species.has(species_id):
		_species[species_id]["stats"].clear()


## Erases all the assigned skills of [param species_id].
func clear_species_skills(species_id: StringName) -> void:
	if _species.has(species_id):
		_species[species_id]["skills"].clear()


## Erases all the assigned traits of [param species_id].
func clear_species_traits(species_id: StringName) -> void:
	if _species.has(species_id):
		_species[species_id]["traits"].clear()
