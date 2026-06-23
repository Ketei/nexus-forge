@tool
@icon("res://addons/nexus_forge/icons/rune_scroll.svg")
class_name TraitCatalog
extends Resource
## A catalog for holding common data about the traits from [TraitBlock] as well
## as global custom traits.
##
## Common data includes the name, description and custom data for each trait.


@export_storage var _trait_data: Dictionary[StringName, Dictionary] = {
	#&"a_trait": {
		#"name": "",
		#"description": "",
		#"data": {}
	#}
}


#region Defined Traits

## Sets a trait's name. The trait must exist in a [TraitBlock].
func set_trait_name(trait_id: StringName, new_name: String) -> void:
	if _trait_data.has(trait_id):
		_trait_data[trait_id]["name"] = new_name


## Returns the trait [param trait_id] name.
func get_trait_name(trait_id: StringName) -> String:
	return DictUtils.get_nested_value(
			_trait_data,
			[trait_id, "name"],
			"",
			true)


## Sets the trait [param trait_id] description. The trait must exist in a [TraitBlock].
func set_trait_description(trait_id: StringName, description: String) -> void:
	if _trait_data.has(trait_id):
		_trait_data[trait_id]["description"] = description


## Returns the trait [trait_id] description.
func get_trait_description(trait_id: StringName) -> String:
	return DictUtils.get_nested_value(
			_trait_data,
			[trait_id, "description"],
			"",
			true)


## Sets the data with key [param data_key] to [param data] of the trait
## [param trait_id]. The trait must exist in a [TraitBlock].
func set_trait_data(trait_id: StringName, data_key: String, data: Variant) -> void:
	if not _trait_data.has(trait_id):
		return
	
	if data == null:
		_trait_data[trait_id]["custom_data"].erase(data_key)
	else:
		_trait_data[trait_id]["custom_data"][data_key] = data


## Returns the data from the trait [param trait_id] with key [param data_key].[br]
## Returns [code]null[/code] if either the trait or the data don't exist.
func get_trait_data(trait_id: StringName, data_key: String) -> Variant:
	if _trait_data.has(trait_id) and _trait_data[trait_id]["custom_data"].has(data_key):
		return _trait_data[trait_id]["custom_data"][data_key]
	return null


func get_trait_custom_data(trait_id: StringName) -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = {}
	data.assign(DictUtils.get_nested_value(
			_trait_data,
			[trait_id, "custom_data"],
			{},
			true))
	return data


## Clears the data from trait [param trait_id].
func clear_trait_data(trait_id: StringName) -> void:
	if _trait_data.has(trait_id):
		_trait_data[trait_id]["custom_data"].clear()


## Returns the custom data keys from the trait [param trait_id].
func trait_data_keys(trait_id: StringName) -> Array[String]:
	var all_keys: Array[String] = []
	if _trait_data.has(trait_id):
		all_keys.assign(_trait_data[trait_id]["custom_data"].keys())
	return all_keys

#endregion

## Creates a custom trait with id [param trait_id] unless it already exists.
## It can after be accessed directly by calling [code]Traits.my_trait[/code][br]
## Creating a custom trait with this method will add them to all instantiated
## [TraitBlock]s and newly instantiated ones will include them too.
func create_trait(trait_id: StringName) -> void:
	if _trait_data.has(trait_id):
		return
	
	var entry: Dictionary[String, Variant] = {
		"name": String(trait_id).capitalize(),
		"dscription": "",
		"custom_data": DictUtils.create_typed(TYPE_STRING, TYPE_NIL)}
	
	_trait_data[trait_id] = entry


## Returns if a custom trait [param trait_id] is registered.
func has_trait(trait_id: StringName) -> bool:
	return _trait_data.has(trait_id)


## Erases the custom trait [param trait_id].[br]
## Erasing a trait doesn't remove it globally from existing [TraitBlock]s,
## but prevents it from being added to newly instantiated ones.
func erase_trait(trait_id: StringName) -> void:
	_trait_data.erase(trait_id)


## Returns an array containing the IDs of the custom traits registered.
func traits() -> Array[StringName]:
	var all_traits: Array[StringName] = []
	all_traits.assign(_trait_data.keys())
	return all_traits
