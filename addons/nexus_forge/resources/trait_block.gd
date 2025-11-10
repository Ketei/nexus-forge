@tool
@icon("res://addons/nexus_forge/icons/rune_stones.svg")
class_name TraitBlock
extends Resource
## A resource holding a character's traits.
##
## To add new traits and make them appear on NexusForge you need to add
## a new variable with an export flag and type the trait as an integer.
## Initializing a trait is not required.[br]
## Example: 
## [codeblock]
## @export var my_trait: int = 0
## [/codeblock]


@export var bear_resist: int = 0

var _custom_traits: Dictionary[StringName, int] = {}


## Constructor for a new TraitBlock with NexusForge custom traits included.[br]
## Also ensures that when a custom trait is created with NexusForge's singleton
## the new stat block also registers it.
static func new_trait_block() -> TraitBlock:
	var new_block: TraitBlock = TraitBlock.new()
	for custom_trait in NexusForge.Traits.custom_traits():
		new_block._custom_traits[custom_trait] = 0
	
	NexusForge.Traits.custom_trait_created.connect(new_block._on_custom_trait_created)
	
	return new_block


## Returns an array with the exported traits in this object.[br]
## Does NOT include custom traits.
static func traits() -> Array[StringName]:
	const MASK: int = PROPERTY_USAGE_SCRIPT_VARIABLE + PROPERTY_USAGE_STORAGE
	var block: TraitBlock = TraitBlock.new()
	var all_traits: Array[StringName] = []
	var data: Array[Dictionary] = block.get_script().get_script_property_list()
	
	for item in data:
		if item["type"] != TYPE_INT or not BitUtils.are_bits(item["usage"], MASK, true):
			continue
		all_traits.append(StringName(item["name"]))
	
	return all_traits


func _on_custom_trait_created(trait_id: StringName) -> void:
	if _custom_traits.has(trait_id):
		return
	_custom_traits[trait_id] = 0


## Returns an array with only the custom traits in this object.
func custom_traits() -> Array[StringName]:
	var all_traits: Array[StringName] = []
	all_traits.assign(_custom_traits.keys())
	return all_traits


## Adds a custom trait to the block.[br]
## Custom traits are tracked individually with exception of the traits
## registered on runtime with [method TraitCatalog.create_custom_trait] on the
## [code]NexusForge.Traits[/code] singleton.
func create_custom(trait_id: StringName) -> void:
	if _custom_traits.has(trait_id):
		return
	_custom_traits[trait_id] = 0


## Returns the level of a custom trait or -1 if no trait is found.
func custom_trait_level(trait_id: StringName) -> int:
	if _custom_traits.has(trait_id):
		return _custom_traits[trait_id]
	return -1


## Returns true if the custom trait [param trait_id] exists.
func has_custom_trait(trait_id: StringName) -> bool:
	return _custom_traits.has(trait_id)


## Sets the level of custom trait [param trait_id] to [param level] if it exists.
func set_custom_trait_level(trait_id: StringName, level: int) -> void:
	if _custom_traits.has(trait_id):
		_custom_traits[trait_id] = level


## Erases the custom trait [param trait_id].
func erase_custom_trait(trait_id: StringName) -> void:
	if _custom_traits.has(trait_id):
		_custom_traits.erase(trait_id)
