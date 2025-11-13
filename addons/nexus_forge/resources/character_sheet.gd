@tool
@icon("res://addons/nexus_forge/icons/character_sheet.svg")
class_name CharacterSheet
extends Resource
## A resource holding a character's data.

## Possible genders of a character.
enum Gender { # Must ALWAYS have one item.
	MALE,
	FEMALE,
}

## The unique ID of a character
@export var id: StringName = &""
## The name of a character
@export var name: String = ""
## The ID of the character's species. The species is registered on
## NexusForge [SpeciesCatalog] accessed via [code]NexusForge.Species[/code].
@export var species: StringName = &""
## The gender of the character.
@export var gender: Gender = Gender.MALE
## Custom data unique to this character.
@export var custom_data: Dictionary[String, Variant] = {}
## The stats of the character.
@export var stats: StatBlock
## The skills of the character.
@export var skills: SkillSet
## The traits of the character.
@export var traits: TraitBlock


func _init(new_stats: StatBlock = null, new_skills: SkillSet = null, new_traits: TraitBlock = null) -> void:
	stats = StatBlock.new() if new_stats == null else new_stats
	skills = SkillSet.new() if new_skills == null else new_skills
	traits = TraitBlock.new() if new_traits == null else new_traits
