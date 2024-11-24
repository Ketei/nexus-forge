class_name CharacterDefinition
extends Resource


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
@export var character_gender := NFRacesRes.Genders.MALE
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

@export var factions: Dictionary = {}

## The stats this character has. It's reccomended you only add/remove stats
## this character has through [method add_stat] and [method remove_stat].
## The stat values can be safely modified directly.
@export var stats: Dictionary = {}
@export var skills: Dictionary = {}
@export var perks: Dictionary = {}
@export var sprite_sheets: Dictionary = {}
## The variants of this character. It is reccomended you only tweak variants
## with the methods [method create_variant], [method delete_variant], 
## [method set_variant_sprite_sheet] and [method set_variant_stat].
@export var variants: Dictionary = {}


# Main Mods


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


func get_variant_sprite_sheet(variant_id: String) -> String:
	return variants[variant_id]["sheet"]


func get_variant_stat_ids(variant_id: String) -> String:
	return variants[variant_id]["stats"].keys()


func get_variant_stat_mod(variant_id: String, stat_id: String) -> int:
	return variants[variant_id]["stats"][stat_id]


func get_variant_mods(variant_id: String) -> Dictionary:
	return variants[variant_id]["stats"]


## Removes [member variant_id] from this character's variants
func delete_variant(variant_id: String) -> void:
	if has_variant(variant_id):
		variants.erase(variant_id)


## Sets the sprite sheet for this variant to use.
func set_variant_sprite_sheet(variant_id: String, sprite_sheet: String) -> void:
	variants[variant_id]["sheet"] = sprite_sheet


## Sets one of the stats for variant_id. The total stat of this variant will be
## the base stat plus [member stat_mod].
func set_variant_stat_mod(variant_id: String, stat_id: String, stat_mod: int) -> void:
	variants[variant_id]["stats"][stat_id] = stat_mod

# -----------
# --- Sprite Sheets ---
func add_sprite_sheet(sprite_id: String, sprite_path: String) -> void:
	sprite_sheets[sprite_id] = sprite_path


func remove_sprite_sheet(sprite_id: String) -> void:
	sprite_sheets.erase(sprite_id)


func get_sprite_sheet_path(sprite_id: String) -> String:
	return sprite_sheets[sprite_id]


func has_sprite_sheet(sprite_id: String) -> bool:
	return sprite_sheets.has(sprite_id)


func clear_sprite_sheets() -> void:
	sprite_sheets.clear()


func get_sprite_sheet_ids() -> Array:
	return sprite_sheets.keys()

# ---------------------
# --- Custom Data ---
func set_custom_data(data_key: String, data: Variant) -> void:
	custom_data[data_key] = data


func get_custom_data_ids() -> Array:
	return custom_data.keys()


func get_custom_data(data_id: String) -> Variant:
	return custom_data[data_id]


## Returns true if the character has [param data_id], you can also pass a
## [enum Variant.Type] to further compare the custom data type.
func has_custom_data(data_id: String, data_type: int = -1) -> bool:
	if 0 <= data_type :
		return custom_data.has(data_id) and typeof(custom_data[data_id]) == data_type
	return custom_data.has(data_id)


func clear_custom_data() -> void:
	custom_data.clear()


# -------------------
# --- Factions ---
func add_to_faction(faction_id: String, rank: int) -> void:
	factions[faction_id] = {"rank": maxi(0, rank)}


func remove_from_faction(faction_id: String) -> void:
	factions.erase(faction_id)


func is_in_faction(faction_id: String) -> bool:
	return factions.has(faction_id)


func get_faction_rank(faction_id: String) -> int:
	if factions.has(faction_id):
		return factions[faction_id]["rank"]
	return -1


func set_faction_rank(faction_id: String, rank: int) -> void:
	factions[faction_id]["rank"] = maxi(0, rank)


func get_characer_factions() -> Array:
	return factions.keys()


func clear_factions() -> void:
	factions.clear()

# ----------------
# --- Stats ---
## Adds [param stat_id] to the character and to all variants. Variants will have
## the stat mod set to 0.
func add_stat(stat_id: String, stat_min: int, stat_max: int) -> void:
	stats[stat_id] = {"min": stat_min, "max": stat_max}
	for variant in variants:
		variants[variant]["stats"][stat_id] = 0


## Removes [param stat_id] from the charracter and from all variants.
func remove_stat(stat_id: String) -> void:
	stats.erase(stat_id)
	for variant in variants:
		variants[variant]["stats"].erase(stat_id)


func get_stat_ids() -> Array:
	return stats.keys()


func get_stat_range(stat_id: String) -> Dictionary:
	return {"min": stats[stat_id]["min"], "max": stats[stat_id]["max"]}


func get_stat_min(stat_id: String) -> int:
	return stats[stat_id]["min"]


func get_stat_max(stat_id: String) -> int:
	return stats[stat_id]["max"]

# -------------
# --- Perks ---
func set_perk(perk_id: String, perk_level: int) -> void:
	perks[perk_id] = {"level": maxi(perk_level, 0)}


func has_perk(perk_id: String) -> bool:
	return perks.has(perk_id)


func get_perk_level(perk_id) -> int:
	return perks[perk_id]["level"]


func remove_perk(perk_id: String) -> void:
	perks.erase(perk_id)


func get_perk_ids() -> Array:
	return perks.keys()

# -------------
# --- Skills ---
func set_skill(skill_id: String, skill_level: int) -> void:
	skills[skill_id] = {"level": skill_level}


func get_skill_ids() -> Array:
	return skills.keys()


func remove_skill(skill_id: String) -> void:
	skills.erase(skill_id)


func get_skill_level(skill_id: String) -> int:
	return skills[skill_id]["level"]


func clear_skills() -> void:
	skills.clear()

# --------------
# Data loaders
## Loads the portrait sprite frame resource and returns it.
func load_portrait_frames() -> SpriteFrames:
	return load(sprite_frames_path)


## Loads the typing sound resource and returns it.
func load_typing_sound() -> AudioStream:
	return load(typing_sound_path)


## Adds a character flag. Check [enum NexusForgeRaces.Flags] for flags.
func set_flag(flag: NFRacesRes.Flags) -> void:
	flags |= 1 << flag


## Removes a flag from the character.
func clear_flag(flag: NFRacesRes.Flags) -> void:
	flags ^= 1 << flag


## Check if this character has a flag.
func has_flag(flag: NFRacesRes.Flags) -> bool:
	return (flags & (1 << flag)) != 0
