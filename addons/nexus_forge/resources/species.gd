@icon("res://addons/nexus_forge/icons/dna_sheet.svg")
class_name SpeciesSheet
extends Resource
## A resource containing the basic information of a species.
##
## This resource contains all data of a species and if obtained via
## [method NexusForge.Species.get_species] it is shared by pointer.
## Changing stats on the resource however will NOT change the stats
## of the species data stored on the singleton. Changing the data on the
## singleton, however, will update the data on the resource and emit
## the [signal Resource.changed] signal.


## The ID of the species.
@export var id: StringName = &"":
	set(i):
		if id.is_empty():
			id = i
## The name of the species.
@export var name: String = ""
## The description of the species.
@export var description: String = ""
## The species' ID that provides the dominant gene. (Main Species)
@export var dominant_species: StringName = &""
## The species' ID that provides the recessive gene. (Secondary Species)
@export var recessive_species: StringName = &""
## The custom data of the species.
@export var custom_data: Dictionary[StringName, Variant] = {}
## The stats of the species.
@export var stats: NFSpeciesStatCatalog = NFSpeciesStatCatalog.new(TYPE_FLOAT)
## The skills of the species.
@export var skills: NFSpeciesStatCatalog = NFSpeciesStatCatalog.new(TYPE_INT)
## The traits of the species.
@export var traits: NFSpeciesStatCatalog = NFSpeciesStatCatalog.new(TYPE_INT)


func _get(property: StringName) -> Variant:
	if custom_data.has(property):
		return custom_data[property]
	return null
