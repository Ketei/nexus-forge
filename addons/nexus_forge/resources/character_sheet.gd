@tool
@icon("res://addons/nexus_forge/icons/character_sheet.svg")
class_name NFCharacterSheet
extends Resource
## A resource holding a character's data.

## Possible genders of a character.
enum Gender {
	MALE,
	FEMALE}

## The unique ID of a character
@export var id: StringName = &""
## The name of a character
@export var name: String = ""
## The ID of the character's species. The species is registered on
## NexusForge [NFSpeciesCatalog] accessed via [code]NexusForge.Species[/code].
@export var species: StringName = &""
## The gender of the character.
@export var gender: Gender = Gender.MALE
## Custom data unique to this character.
@export var custom_data: Dictionary[String, Variant] = {}
## The stats of the character.
@export var stats: NFStatBlock
## The skills of the character.
@export var skills: NFSkillSet
## The traits of the character.
@export var traits: NFTraitBlock

var _mods_applied: bool = false


## Ensures that the object has [member NFCharacterSheet.stats],
## [member NFCharacterSheet.skills] and
## [member NFCharacterSheet.traits] initialized.
func initialize_objects() -> void:
	if not is_instance_valid(stats):
		stats = NFStatBlock.new()
	stats.initialize_ranges()
	if not is_instance_valid(skills):
		skills = NFSkillSet.new()
	if not is_instance_valid(traits):
		traits = NFTraitBlock.new()
