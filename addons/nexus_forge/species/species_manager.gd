class_name NFSpeciesManager
extends RefCounted


signal species_registered(species_id: StringName)
signal species_erased(species_id: StringName)

var _species: Dictionary[StringName, SpeciesSheet] = {}


func _get(property: StringName) -> Variant:
	if _species.has(property):
		return _species[property]
	return null


func load_catalog(catalog: SpeciesCatalog, clear_species: bool = true) -> void:
	var use_inheritance: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("species_use_inheritance"), true)
	if clear_species:
		_species.clear()
	
	for species_id in catalog.species():
		var sheet: SpeciesSheet = SpeciesSheet.new()
		sheet.id = species_id
		sheet.name = catalog.get_species_name(species_id)
		sheet.description = catalog.get_species_description(species_id)
		sheet.dominant_species = catalog.get_dominant_species_of(species_id)
		sheet.recessive_species = catalog.get_recessive_species_of(species_id)
		sheet.custom_data.assign(catalog.get_species_custom_data(species_id))
		sheet.stats = catalog.get_species_stats(species_id, use_inheritance)
		sheet.skills = catalog.get_species_skills(species_id, use_inheritance)
		sheet.traits = catalog.get_species_traits(species_id, use_inheritance)
		_species[species_id] = sheet



## Returns a [SpeciesSheet] with data, stats, skills and traits of the species.
## Stats, skills and traits will have inherited values from the parent species
## if [code]settings/species_use_genetic_inheritance[/code] is enabled on 
## [code]ProjectSettings/NexusForge[/code].[br]
## Returns [code]null[/code] if the species is not found.
func get_species(species_id: StringName) -> SpeciesSheet:
	if _species.has(species_id):
		return _species[species_id]
	return null


## Returns an array of all registered species.
func species() -> Array[StringName]:
	var all_species: Array[StringName] = []
	all_species.assign(_species.keys())
	return all_species


## Creates a new species with [param species_id] unless it already exists.
func register_species(new_species: SpeciesSheet) -> void:
	if _species.has(new_species.id) or new_species.id.is_empty():
		return
	
	_species[new_species.id] = new_species
	
	if new_species.stats == null:
		new_species.stats = NFSpeciesStatCatalog.new()
	if new_species.skills == null:
		new_species.skills = NFSpeciesStatCatalog.new()
	if new_species.traits == null:
		new_species.traits = NFSpeciesStatCatalog.new()
	
	species_registered.emit(new_species.id)


## Erases the given species and clears the link of all subspecies linked
## to [param species_id].
func erase_species(species_id: StringName) -> void:
	if not _species.erase(species_id):
		return
	
	for remaining_species in _species.keys():
		var emit_update: bool = false
		if _species[remaining_species].dominant_species == species_id:
			_species[remaining_species].dominant_species = &""
			emit_update = true
		if _species[remaining_species].recessive_species == species_id:
			_species[remaining_species].recessive_species = &""
			emit_update = true
		if emit_update:
			_species[remaining_species].emit_changed()
	species_erased.emit(species_id)


## Sets the [param species_id] to be a subspecies of [param parent_species].
func link_species(species_id: StringName, parent_species: StringName, recessive_species: StringName = &"") -> void:
	if not _species.has_all([species_id, parent_species]):
		return
	
	var emit_change: bool = false
	if _species[species_id].dominant_species != parent_species:
		_species[species_id].dominant_species = parent_species
		emit_change = true
	
	if not recessive_species.is_empty() and _species.has(recessive_species):
		_species[species_id].recessive_species = recessive_species
		emit_change = true
	
	if emit_change:
		_species[species_id].emit_changed()


## Returns the parent species of [param of_species].
func get_dominant_species_of(species_id: StringName) -> StringName:
	if _species.has(species_id):
		return _species[species_id].dominant_species
	return &""


func get_recessive_species_of(species_id: StringName) -> StringName:
	if _species.has(species_id):
		return _species[species_id].recessive_species
	return &""


## Returns [code]true[/code] if [param species_id] is registered.
func has_species(species_id: StringName) -> bool:
	return _species.has(species_id)


## Returns the name of [param species_id]. Returns an empty string if the species
## isn't registered.
func get_species_name(species_id: StringName) -> String:
	if _species.has(species_id):
		return _species[species_id].name
	return ""


## Sets the species name of [param species_id] to [param new_name]
func set_species_name(species_id: StringName, new_name: String) -> void:
	if _species.has(species_id) and _species[species_id].name != new_name:
		_species[species_id].name = new_name
		_species[species_id].emit_changed()


## Returns the description of [param species_id]. Returns an empty string if
## the species isn't registered.
func get_species_description(species_id: StringName) -> String:
	if _species.has(species_id):
		return _species[species_id].description
	return ""


## Sets the description of [param species_id] to [param new_name].
func set_species_description(species_id: StringName, description: String) -> void:
	if not _species.has(species_id) or _species[species_id].description == description:
		return
	
	_species[species_id]["description"] = description
	_species[species_id].emit_changed()


## Sets the value of [param data_key] to [param data] of the [param species_id].
## If [param data] is [code]null[/code] then [param data_key] is erased.
func set_species_data(species_id: StringName, data_key: StringName, data: Variant) -> void:
	if not _species.has(species_id):
		return
	
	var update: bool = true
	
	if data == null:
		update = _species[species_id].custom_data.erase(data_key)
	else:
		_species[species_id].custom_data[data_key] = data
	
	if update:
		_species[species_id].emit_changed()


## Returns the data with [param data_key] from the [param species_id] or
## [code]null[/code] if the species isn't registered or key doesn't exist.
func get_species_data(species_id: StringName, data_key: StringName) -> Variant:
	if _species.has(species_id) and _species[species_id].custom_data.has(data_key):
		return _species[species_id]["data"][data_key]
	return null


## Returns [code]true[/code] if [param species_id] has custom data with key
## [param data_key].
func species_has_data(species_id: StringName, data_key: StringName) -> bool:
	return _species.has(species_id) and _species[species_id].custom_data.has(data_key)


## Returns an array with all custom data keys that [param species_id] has.
func species_data_keys(species_id: StringName) -> Array[String]:
	var all_keys: Array[String] = []
	if _species.has(species_id):
		all_keys.assign(_species[species_id].custom_data.keys())
	return all_keys


## Clears all the custom data from [param species_id].
func clear_species_data(species_id: StringName) -> void:
	if not _species.has(species_id) or _species[species_id].custom_data.is_empty():
		return
	_species[species_id].custom_data.clear()
	_species[species_id].emit_changed()
## Returns the value of [param stat_id] assigned to the species with
## [param species_id] or 0 if the stat isn't assigned on the species.


## Sets the stat [param stat_id] to [param value] on the [param species_id].
func set_species_stat_value(species_id: StringName, stat_id: StringName, value: float) -> void:
	if not _species.has(species_id):
		return
	
	var update: bool = not _species[species_id].stats.has(stat_id) or _species[species_id].stats.get_entry(stat_id) != value
	_species[species_id].stats.set_entry(stat_id, value)
	if update:
		_species[species_id].emit_changed()


## Returns [code]true[/code] if [param species_id] has [param stat_id] assigned.
func species_has_stat(species_id: StringName, stat_id: StringName) -> bool:
	return _species.has(species_id) and _species[species_id].stats.has(stat_id)


## Removes the [param stat_id] from the [param species_id] if it had it assigned.
func erase_species_stat(species_id: StringName, stat_id: StringName) -> void:
	if _species.has(species_id) and _species[species_id].stats.erase(stat_id):
		_species[species_id].emit_changed()


## Sets the [param skill_id] to [param value] on [param species_id].
func set_species_skill_value(species_id: StringName, skill_id: StringName, value: int) -> void:
	if not _species.has(species_id):
		return
	
	var update: bool = not _species[species_id].skills.has(skill_id) or _species[species_id].skills.get_entry(skill_id) != value
	
	_species[species_id].skills.set_entry(skill_id, value)
	if update:
		_species[species_id].emit_changed()


## Returns the value of [param skill_id] assigned to the species with
## [param species_id] or 0 if the skill isn't assigned on the species.
func get_species_skill_value(species_id: StringName, skill_id: StringName) -> int:
	if _species.has(species_id) and _species[species_id].skills.has(skill_id):
		return _species[species_id].skills.get_entry(species_id)
	return 0


## Returns true if [param species_id] has a [param skill_id] assigned.
func species_has_skill(species_id: StringName, skill_id: StringName) -> bool:
	return _species.has(species_id) and _species[species_id].skills.has(skill_id)


## Erases the assigned [param skill_id] from the [param species_id].
func erase_species_skill(species_id: StringName, skill_id: StringName) -> void:
	if _species.has(species_id) and _species[species_id]["skills"].has(skill_id):
		_species[species_id]["skills"].erase(skill_id)


## Sets [param trait_id] to [param value] on the [param species_id].
func set_species_trait_value(species_id: StringName, trait_id: StringName, value: int) -> void:
	if not _species.has(species_id):
		return
	
	var update: bool = not _species[species_id].traits.has(trait_id) or _species[species_id].traits.get_entry(trait_id) != value
	
	_species[species_id].traits.set_entry(trait_id, value)
	if update:
		_species[species_id].emit_changed()


## Returns the value of [param trait_id] assigned to the species with
## [param species_id] or 0 if the trait isn't assigned on the species.
func get_species_trait_value(species_id: StringName, trait_id: StringName) -> int:
	if _species.has(species_id) and _species[species_id].traits.has(trait_id):
		return _species[species_id].traits.get_entry(trait_id)
	return 0


## Returns [code]true[/code] if [param species_id] has an assigned [param trait_id].
func species_has_trait(species_id: StringName, trait_id: StringName) -> bool:
	return _species.has(species_id) and _species[species_id].traits.has(trait_id)


## Erases the assigned [param trait_id] from the [param species_id].
func erase_species_trait(species_id: StringName, trait_id: StringName) -> void:
	if _species.has(species_id) and _species[species_id].traits.erase(trait_id):
		_species[species_id].emit_changed()


## Erases all the assigned stats of [param species_id].
func clear_species_stats(species_id: StringName) -> void:
	if _species.has(species_id) and not _species[species_id].stats.is_empty():
		_species[species_id].stats.clear()
		_species[species_id].emit_changed()


## Erases all the assigned skills of [param species_id].
func clear_species_skills(species_id: StringName) -> void:
	if _species.has(species_id) and not _species[species_id].skills.is_empty():
		_species[species_id].skills.clear()
		_species[species_id].emit_changed()


## Erases all the assigned traits of [param species_id].
func clear_species_traits(species_id: StringName) -> void:
	if _species.has(species_id) and not _species[species_id].traits.is_empty():
		_species[species_id].traits.clear()
		_species[species_id].emit_changed()
