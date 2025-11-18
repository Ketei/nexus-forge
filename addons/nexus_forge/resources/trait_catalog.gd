@tool
@icon("res://addons/nexus_forge/icons/rune_scroll.svg")
class_name TraitCatalog
extends Resource
## A catalog for holding common data about the traits from [TraitBlock] as well
## as global custom traits.
##
## Common data includes the name, description and custom data for each trait.

## Emmited when a new custom trait is created.
signal custom_trait_created(trait_id: StringName)
## Emmited when a custom trait is erased.
signal custom_trait_erased(trait_id: StringName)

## Custom data which all created traits will have.
const DEFAULT_DATA: Dictionary[String, Variant] = {}

@export_storage var _traits: Dictionary[StringName, Dictionary] = {
	#&"a_trait": {
		#"name": "",
		#"description": "",
		#"data": {}
	#}
}

var _custom_traits: Dictionary[StringName, Dictionary] = {}


#region Defined Traits

## Sets a trait's name. The trait must exist in a [TraitBlock].
func set_trait_name(trait_id: StringName, new_name: String) -> void:
	if _traits.has(trait_id):
		_traits[trait_id]["name"] = new_name


## Returns the trait [param trait_id] name.
func get_trait_name(trait_id: StringName) -> String:
	if _traits.has(trait_id):
		return _traits[trait_id]["name"]
	return ""


## Sets the trait [param trait_id] description. The trait must exist in a [TraitBlock].
func set_trait_description(trait_id: StringName, description: String) -> void:
	if _traits.has(trait_id):
		_traits[trait_id]["description"] = description


## Returns the trait [trait_id] description.
func get_trait_description(trait_id: StringName) -> String:
	if _traits.has(trait_id):
		return _traits[trait_id]["description"]
	return ""


## Sets the data with key [param data_key] to [param data] of the trait
## [param trait_id]. The trait must exist in a [TraitBlock].
func set_trait_data(trait_id: StringName, data_key: String, data: Variant) -> void:
	if not _traits.has(trait_id):
		return
	
	if data == null:
		if  _traits[trait_id]["data"].has(data_key):
			_traits[trait_id]["data"].erase(data_key)
	else:
		_traits[trait_id]["data"][data_key] = data


## Clears the data from trait [param trait_id].
func clear_trait_data(trait_id: StringName) -> void:
	if _traits.has(trait_id):
		_traits[trait_id]["data"].clear()


## Returns the custom data keys from the trait [param trait_id].
func trait_data_keys(trait_id: StringName) -> Array[String]:
	var all_keys: Array[String] = []
	if _traits.has(trait_id):
		all_keys.assign(_traits[trait_id]["data"].keys())
	return all_keys

#endregion

## Creates a custom trait with id [param trait_id] unless it already exists.[br]
## Creating a custom trait with this method will add them to all instantiated
## [TraitBlock]s and newly instantiated ones will include them too.
func create_custom_trait(trait_id: StringName) -> void:
	if _custom_traits.has(trait_id):
		return
	
	var data: Dictionary[String, Variant] = {}
	data.assign(DEFAULT_DATA.duplicate(true))
	
	_custom_traits[trait_id] = {
		"name": "",
		"description": "",
		"data": data}
	
	custom_trait_created.emit(trait_id)


## Returns if a custom trait [param trait_id] is registered.
func has_custom_trait(trait_id: StringName) -> bool:
	return _custom_traits.has(trait_id)

## Erases the custom trait [param trait_id].[br]
## Erasing a trait doesn't remove it globally from existing [TraitBlock]s,
## but prevents it from being added to newly instantiated ones.
func erase_custom_trait(trait_id: StringName) -> void:
	if _custom_traits.erase(trait_id):
		custom_trait_erased.emit(trait_id)


## Returns an array containing the IDs of the custom traits registered.
func custom_traits() -> Array[StringName]:
	var all_traits: Array[StringName] = []
	all_traits.assign(_custom_traits.keys())
	return all_traits


## Sets the custom trait [param trait_id]'s name to [param new_name].
func set_custom_trait_name(trait_id: StringName, new_name: String) -> void:
	if _custom_traits.has(trait_id):
		_custom_traits[trait_id]["name"] = new_name


## Returns the name of the custom trait [param trait_id].
func get_custom_trait_name(trait_id: StringName) -> String:
	if _custom_traits.has(trait_id):
		return _custom_traits[trait_id]["name"]
	return ""


## Sets the custom trait [param trait_id]'s description to [param description].
func set_custom_trait_description(trait_id: StringName, description: String) -> void:
	if _custom_traits.has(trait_id):
		_custom_traits[trait_id]["description"] = description


## Returns the description of the custom trait [param trait_id].
func get_custom_trait_description(trait_id: StringName) -> String:
	if _custom_traits.has(trait_id):
		return _custom_traits[trait_id]["description"]
	return ""


## Sets the custom trait [param trait_id]'s data with key [param data_key] to
## [param data].
func set_custom_trait_data(trait_id: StringName, data_key: String, data: Variant) -> void:
	if not _custom_traits.has(trait_id):
		return
	
	if data == null:
		if  _custom_traits[trait_id]["data"].has(data_key):
			_custom_traits[trait_id]["data"].erase(data_key)
	else:
		_custom_traits[trait_id]["data"][data_key] = data


## Clears the custom data from the custom trait [param trait_id].
func clear_custom_trait_data(trait_id: StringName) -> void:
	if _custom_traits.has(trait_id):
		_custom_traits[trait_id]["data"].clear()


## Returns the custom data keys from the custom trait [param trait_id].
func custom_trait_data_keys(trait_id: StringName) -> Array[String]:
	var all_keys: Array[String] = []
	if _custom_traits.has(trait_id):
		all_keys.assign(_custom_traits[trait_id]["data"].keys())
	return all_keys
