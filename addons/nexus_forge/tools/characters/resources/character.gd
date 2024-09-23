class_name NexusForgeCharacterDefinition
extends Resource


## The id of the character. Meant to be unique.
@export var character_id: StringName = &""
## The display name of the character.
@export var character_name: String = ""
## The color the character name will appear as on the textbox.
@export var character_name_color := Color.WHITE
## The species of this character. The species are contained within the project's
## NexusForgeRaces resource.
@export var character_species: String = ""
## The race of this character. The races are contained within the project's
## NexusForgeRaces resource.
@export var character_race: String = ""
## The gender of the character.
@export var character_gender := NexusForgeRaces.Genders.MALE
## The flags this character has enabled.
@export var flags: int = 0
## Custom data set by the user.
@export var custom_data: Dictionary = {}

## Path to the [SpriteFrames] resource that this character uses for it's text
## portrait.
@export var sprite_frames_path: String = ""
## Path to the [AudioStream] resource that this character uses for the sounds
## when letters are appearing on a textbox.
@export var typing_sound_path: String = ""

## The stats this character has. It's reccomended you only add/remove stats
## this character has through [method add_stat] and [method remove_stat].
## The stat values can be safely modified directly.
@export var stats: Dictionary = {}
@export var skills: Dictionary = {}
@export var perks: Dictionary = {}
## The variants of this character. It is reccomended you only tweak variants
## with the methods [method create_variant], [method delete_variant], 
## [method set_variant_sprite_sheet] and [method set_variant_stat].
@export var variants: Dictionary = {}


# Main Mods
## Adds [param stat_id] to the character and to all variants. Variants will have
## the stat mod set to 0.
func add_stat(stat_id: String, stat_value: int) -> void:
	stats[stat_id] = stat_value
	for variant in variants:
		variants[variant]["stats"][stat_id] = 0


## Removes [param stat_id] from the charracter and from all variants.
func remove_stat(stat_id: String) -> void:
	stats.erase(stat_id)
	for variant in variants:
		variants[variant]["stats"].erase(stat_id)


## Returns true if the character has [param data_id], you can also pass a
## [enum Variant.Type] to further compare the custom data type.
func has_custom_data(data_id: String, data_type: int = -1) -> bool:
	if 0 <= data_type :
		return custom_data.has(data_id) and typeof(custom_data[data_id]) == data_type
	return custom_data.has(data_id)


## Returns true if [member sprite_frames_path] isn't empty
func has_portrait_frames() -> bool:
	return not sprite_frames_path.is_empty()


## Returns true if [member typing_sound_path] isn't empty
func has_typing_sound() -> bool:
	return not typing_sound_path.is_empty()

#----------
# Variants
## Returns true if this character has any variants
func has_variants() -> bool:
	return not variants.is_empty()


## Returns an array with the ids of this character variants
func get_variants() -> Array:
	return variants.keys()


## Returns true if this character has a variant with [member variant_id]
func has_variant(variant_id: String) -> bool:
	return variants.has(variant_id)


## Creates an empty variant on the character for further editing. It'll also
## fill out the stat ids to match that of the character.
func create_variant(variant_id: String) -> void:
	if has_variant(variant_id):
		return
	variants[variant_id] = {
		"sheet": "",
		"stats": {}
	}
	
	for existing_stat in stats:
		variants[variant_id]["stats"][existing_stat] = 0


## Removes [member variant_id] from this character's variants
func delete_variant(variant_id: String) -> void:
	if has_variant(variant_id):
		variants.erase(variant_id)


## Sets the sprite sheet for this variant to use.
func set_variant_sprite_sheet(variant_id: String) -> void:
	variants[variant_id]["sheet"] = variant_id


## Sets one of the stats for variant_id. The total stat of this variant will be
## the base stat plus [member stat_mod].
func set_variant_stat(variant_id: String, stat_id: String, stat_mod: int) -> void:
	variants[variant_id]["stats"][stat_id] = stat_mod

# -----------
# Data loaders
## Loads the portrait sprite frame resource and returns it.
func load_portrait_frames() -> SpriteFrames:
	return load(sprite_frames_path)


## Loads the typing sound resource and returns it.
func load_typing_sound() -> AudioStream:
	return load(typing_sound_path)


## Adds a character flag. Check [enum NexusForgeRaces.Flags] for flags.
func set_flag(flag: NexusForgeRaces.Flags) -> void:
	flags |= 1 << flag


## Removes a flag from the character.
func clear_flag(flag: NexusForgeRaces.Flags) -> void:
	flags ^= 1 << flag


## Check if this character has a flag.
func has_flag(flag: NexusForgeRaces.Flags) -> bool:
	return (flags & (1 << flag)) != 0
