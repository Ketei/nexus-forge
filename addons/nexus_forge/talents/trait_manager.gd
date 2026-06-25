class_name NFTraitManager
extends RefCounted
## An object to keep track of trait's info and custom traits.
##
## This object can keep track of data of base and custom traits. Data
## can be accessed directly by using the ID of the trait eg. [code]Traits.my_trait[/code].
## If the trait isn't registered a fallback object will be returned. You can
## call is_valid() to verify a trait validity as well as is_custom() to
## see if the trait is custom.


## Emmited when a new trait is created.
signal trait_created(trait_id: StringName)
## Emmited when a trait is erased.
signal trait_erased(trait_id: StringName)

var _trait_entries: Dictionary[StringName, NFCatalogEntry] = {}
var _base_traits: Dictionary[StringName, Variant] = {}


func _init() -> void:
	for trait_id in TraitBlock.traits():
		var base_entry: NFCatalogEntry = NFCatalogEntry.new()
		base_entry.name = String(trait_id).capitalize()
		base_entry._flags = NFCatalogEntry._get_flags(true, false, true)
		_base_traits[trait_id] = null
		_trait_entries
	_base_traits.make_read_only()


## Loads a trait [param catalog] into this object. If [param clear_traits]
## is [code]true[/code] then previous traits are cleared.
func load_catalog(catalog: TraitCatalog, clear_traits: bool = true) -> void:
	if clear_traits:
		for entry in _trait_entries.keys():
			if _base_traits.has(entry):
				continue
			_trait_entries.erase(entry)
	
	for trait_id in catalog.traits():
		var entry: NFCatalogEntry = NFCatalogEntry.new()
		entry.name = catalog.get_trait_name(trait_id)
		entry.description = catalog.get_trait_description(trait_id)
		entry.custom_data.assign(catalog.get_trait_custom_data(trait_id))
		entry._flags = NFCatalogEntry._get_flags(true, not _base_traits.has(trait_id), true)
		_trait_entries[trait_id] = entry


func _get(property: StringName) -> Variant:
	if _trait_entries.has(property):
		return _trait_entries[property]
	var invalid: NFCatalogEntry = NFCatalogEntry.new()
	invalid._flags = NFCatalogEntry._get_flags(false, false, true)
	return invalid


#region Defined Traits

## Sets a trait's name. The trait must exist in a [TraitBlock].
func set_trait_name(trait_id: StringName, new_name: String) -> void:
	if _trait_entries.has(trait_id):
		_trait_entries[trait_id].name = new_name


## Returns the trait [param trait_id] name.
func get_trait_name(trait_id: StringName) -> String:
	if _trait_entries.has(trait_id):
		return _trait_entries[trait_id].name
	return ""


## Sets the trait [param trait_id] description. The trait must exist in a [TraitBlock].
func set_trait_description(trait_id: StringName, description: String) -> void:
	if _trait_entries.has(trait_id):
		_trait_entries[trait_id].description = description


## Returns the trait [trait_id] description.
func get_trait_description(trait_id: StringName) -> String:
	if _trait_entries.has(trait_id):
		return _trait_entries[trait_id].description
	return ""


## Sets the data with key [param data_key] to [param data] of the trait
## [param trait_id]. The trait must exist in a [TraitBlock].
func set_trait_data(trait_id: StringName, data_key: StringName, data: Variant) -> void:
	if not _trait_entries.has(trait_id):
		return
	
	if data == null:
		_trait_entries[trait_id].custom_data.erase(data_key)
	else:
		_trait_entries[trait_id].custom_data[data_key] = data


## Returns the data from the trait [param trait_id] with key [param data_key].[br]
## Returns [code]null[/code] if either the trait or the data don't exist.
func get_trait_data(trait_id: StringName, data_key: StringName) -> Variant:
	if _trait_entries.has(trait_id) and _trait_entries[trait_id].custom_data.has(data_key):
		return _trait_entries[trait_id].custom_data[data_key]
	return null


## Clears the data from trait [param trait_id].
func clear_trait_data(trait_id: StringName) -> void:
	if _trait_entries.has(trait_id):
		_trait_entries[trait_id].custom_data.clear()


## Returns the custom data keys from the trait [param trait_id].
func trait_data_keys(trait_id: StringName) -> Array[String]:
	var all_keys: Array[String] = []
	if _trait_entries.has(trait_id):
		all_keys.assign(_trait_entries[trait_id].custom_data.keys())
	return all_keys

#endregion

## Creates a custom trait with id [param trait_id] unless it already exists.
## It can after be accessed directly by calling [code]Traits.my_trait[/code][br]
## Creating a custom trait with this method will add them to all instantiated
## [TraitBlock]s and newly instantiated ones will include them too.
func create_trait(trait_id: StringName) -> void:
	if _trait_entries.has(trait_id):
		return
	
	var entry: NFCatalogEntry = NFCatalogEntry.new()
	
	entry.name = String(trait_id).capitalize()
	entry._valid = true
	entry._custom = true
	
	_trait_entries[trait_id] = entry
	
	trait_created.emit(trait_id)


## Returns whether a trait is custom or basic.
func is_custom(trait_id: StringName) -> bool:
	if _trait_entries.has(trait_id):
		return _trait_entries[trait_id].is_custom()
	return true


## Returns if a custom trait [param trait_id] is registered.
func has_trait(trait_id: StringName) -> bool:
	return _trait_entries.has(trait_id)

## Erases the custom trait [param trait_id].[br]
## Erasing a trait doesn't remove it globally from existing [TraitBlock]s,
## but prevents it from being added to newly instantiated ones.
func erase_trait(trait_id: StringName) -> void:
	if _base_traits.has(trait_id):
		NFPluginGameHandler._log_msg(
				"traits",
				"Erasing built-in traits is disallowed.",
				NFPluginGameHandler._LogLevel.WARNING)
		return
	
	if _trait_entries.erase(trait_id):
		trait_erased.emit(trait_id)


## Returns an array containing the IDs of the custom traits registered.
func traits() -> Array[StringName]:
	var all_traits: Array[StringName] = []
	all_traits.assign(_trait_entries.keys())
	return all_traits
