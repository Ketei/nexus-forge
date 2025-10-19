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
@export var stats: StatBlock
@export var skills: SkillSet
@export var traits: TraitBlock
