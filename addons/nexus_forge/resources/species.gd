@icon("res://addons/nexus_forge/icons/dna_sheet.svg")
class_name SpeciesSheet
extends Resource
## A resource containing the basic information of a species.


## The ID of the species.
@export var id: StringName = &""
## The name of the species.
@export var name: String = ""
## The description of the species.
@export var description: String = ""
## The custom data of the species.
@export var data: Dictionary[String, Variant] = {}
## The stats of the species.
@export var stats: StatBlock = StatBlock.new(true)
## The skills of the species.
@export var skills: SkillSet = SkillSet.new()
## The traits of the species.
@export var traits: TraitBlock = TraitBlock.new()
