@icon("res://addons/nexus_forge/icons/dna_sheet.svg")
class_name SpeciesSheet
extends Resource


@export var id: StringName = &""
@export var name: String = ""
@export var description: String = ""
@export var data: Dictionary[String, Variant] = {}
@export var stats: StatBlock = StatBlock.new()
@export var skills: SkillSet = SkillSet.new()
@export var traits: TraitBlock = TraitBlock.new()
