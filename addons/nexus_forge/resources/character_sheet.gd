@tool
@icon("res://addons/nexus_forge/icons/character_sheet.svg")
class_name CharacterSheet
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


## Custom constructor for the class. Ensures the returned object has
## [member CharacterSheet.stats], [member CharacterSheet.skills] and
## [member CharacterSheet.traits] initialized, as well as
## [member CharacterSheet.custom_data] filled with the
## [const CharacterSheet.DEFAULT_DATA].
static func new_character() -> CharacterSheet:
	var new_sheet: CharacterSheet = CharacterSheet.new()
	if new_sheet.stats == null:
		new_sheet.stats = StatBlock.new(true)
	if new_sheet.skills == null:
		new_sheet.skills = SkillSet.new()
	if new_sheet.traits == null:
		new_sheet.traits = TraitBlock.new()
	
	return new_sheet
