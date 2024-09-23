class_name CharacterDefinition
extends Resource

enum Gender {
	MALE,
	FEMALE,
	GYNO,
	ANDRO,
	HERM,
}

enum Form {
	ANTHRO,
	FERAL,
	TAUR,
	HUMANOID,
	HUMAN,
}

enum Age {
	BABY,
	TODDLER,
	CHILD,
	ADOLESCENT,
	ADULT,
	ELDER,
}


@export var character_id: StringName = &""
@export var character_name: String = ""
@export var character_portrait: SpriteFrames = null
@export var character_gender := Gender.MALE
@export var character_age := Age.ADULT
@export var character_form := Form.ANTHRO
