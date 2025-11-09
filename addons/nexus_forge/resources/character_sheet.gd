@tool
@icon("res://addons/nexus_forge/icons/character_icon.svg")
class_name CharacterSheet
extends Resource

# Must always have one item.
enum Gender {
	MALE,
	FEMALE,
}


@export var id: StringName = &""
@export var name: String = ""
@export var species: StringName = &""
@export var gender: Gender = Gender.MALE
@export var custom_data: Dictionary[String, Variant] = {}
@export var stats: StatBlock = StatBlock.new()
@export var skills: SkillSet = SkillSet.new()
@export var traits: TraitBlock = TraitBlock.new()
