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


@export var cold_resist: int = 0

@export_storage var _custom_traits: Dictionary[StringName, int] = {}


func _init(use_nexus_forge: bool = true) -> void:
	if not use_nexus_forge or Engine.is_editor_hint():
		return
	
	for custom_trait in NexusForge.Traits.traits():
		if _custom_traits.has(custom_trait) or not NexusForge.Traits.is_custom(custom_trait):
			continue
		_custom_traits[custom_trait] = 0
	
	NexusForge.Traits.trait_created.connect(_on_custom_trait_created)


func _set(property: StringName, value: Variant) -> bool:
	var val_type: int = typeof(value)
	if _custom_traits.has(property) and (val_type == TYPE_INT or val_type == TYPE_FLOAT):
		_custom_traits[property] = value
		return true
	return false


func _get(property: StringName) -> Variant:
	if _custom_traits.has(property):
		return _custom_traits[property]
	return -1


## Returns an array with the exported traits in this object.[br]
## Does NOT include custom traits.
static func traits() -> Array[StringName]:
	const MASK: int = PROPERTY_USAGE_SCRIPT_VARIABLE + PROPERTY_USAGE_STORAGE
	var block: TraitBlock = TraitBlock.new(false)
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


## Creates a custom trait and sets it to [param value] which can then be
## accessed and modified directly like
## [code]TraitBlock.my_custom_trait[/code].[br]
## Custom traits are tracked individually with exception of the traits
## registered on runtime with [method TraitCatalog.create_custom_trait] on the
## [code]NexusForge.Traits[/code] singleton which are added to all [TraitBlock]s
func create_custom(trait_id: StringName, value: int = 0) -> void:
	if _custom_traits.has(trait_id):
		return
	_custom_traits[trait_id] = value


## Returns the value of a custom trait or -1 if no trait is found.
func get_custom(trait_id: StringName) -> int:
	if _custom_traits.has(trait_id):
		return _custom_traits[trait_id]
	return -1


## Returns true if the custom trait [param trait_id] exists.
func has_custom(trait_id: StringName) -> bool:
	return _custom_traits.has(trait_id)


## Erases the custom trait [param trait_id].
func erase_custom(trait_id: StringName) -> void:
	if _custom_traits.has(trait_id):
		_custom_traits.erase(trait_id)
