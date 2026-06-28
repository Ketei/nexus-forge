@tool
@icon("res://addons/nexus_forge/icons/currency_catalog.svg")
class_name CurrencyCatalog
extends Resource
## A resource holding data and values for a currency system.
##
## This object is designed to hold currency data, relative values and help with
## the management of currency conversion in case of a multi-currency system
## is implemented.[br][br]
## In order for the system to work properly a currency of value 1 must be provided
## and no two currencies should share the same value.


@export_storage var _currencies: Dictionary[StringName, Dictionary] = {}


## Creates a new currency with [param currency_id] unless it already exists.
func create_currency(currency_id: StringName, value: int = 0, name: String = "") -> void:
	if _currencies.has(currency_id):
		return
	var currency_data: Dictionary[String, Variant] = {}
	
	var new_entry: Dictionary = {
		"name": name,
		"value": value,
		"custom_data": currency_data}
	_currencies[currency_id] = new_entry
	
	return


## Returns true if the [param currency_id] is registered.
func has_currency(currency_id: StringName) -> bool:
	return _currencies.has(currency_id)


## Sets the value of [param currency_id] to be [param new_value].[br]
## The smallest value a currency can have is 1.
func set_currency_value(currency_id: StringName, new_value: int) -> void:
	if _currencies.has(currency_id):
		_currencies[currency_id]["value"] = maxi(1, new_value)


## Returns the value of [param currency_id]. Value returned won't be less
## than 1.
func get_currency_value(currency_id: StringName) -> int:
	var data = DictUtils.get_nested_value(
			_currencies,
			[currency_id, "value"],
			1)
	var type: int = typeof(data)
	if type == TYPE_INT or type == TYPE_FLOAT:
		return maxi(1, data)
	return 1


## Sets the name of [param currency_id] to be [param new_name].
func set_currency_name(currency_id: StringName, new_name: String) -> void:
	if _currencies.has(currency_id):
		_currencies[currency_id]["name"] = new_name


## Returns the name of [param currency_id] or an empty string if the currency
## isn't registered.
func get_currency_name(currency_id: StringName) -> String:
	return DictUtils.get_nested_value(
			_currencies,
			[currency_id, "name"],
			"",
			true)


## Sets the value of the custom data with key param data_key to [param data]
## on the given [param currency_id]. If param data is [code]null[/code] the
## entry will be erased instead.
func set_currency_data(currency_id: StringName, data_key: String, data: Variant) -> void:
	if not _currencies.has(currency_id):
		return
	
	if not _currencies[currency_id].has("custom_data"):
		_currencies[currency_id]["custom_data"] = DictUtils.create_typed(TYPE_STRING, TYPE_NIL)
	
	if data == null:
		_currencies[currency_id]["custom_data"].erase(data_key)
	else:
		_currencies[currency_id]["custom_data"][data_key] = data


## Returns the value of [param data_key] of the custom data of
## [param currency_id].
func get_currency_data(currency_id: StringName, data_key: String) -> Variant:
	return DictUtils.get_nested_value(
			_currencies,
			[currency_id, "custom_data", data_key])


func get_currency_custom_data(currency_id: StringName) -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = {}
	data.assign(DictUtils.get_nested_value(
			_currencies,
			[currency_id, "custom_data"],
			{},
			true))
	return data


## Returns the keys of the custom data that [param currency_id] has.
func currency_data_keys(currency_id: StringName) -> Array[String]:
	var keys: Array[String] = []
	keys.assign(DictUtils.get_nested_value(
			_currencies,
			[currency_id, "custom_data"],
			{},
			true).keys())
	return keys


## Clears the custom data of the currency with id [param currency_id]
func clear_currency_data(currency_id: StringName) -> void:
	if DictUtils.has_nested_path(_currencies, [currency_id, "custom_data"]):
		_currencies[currency_id]["custom_data"].clear()


## Returns an array containing the keys of all currencies.[br]
## The keys will be unsorted unless sort_ascendat is true, which will sort
## the array from lowest-value to highest-value.
func currencies(sort_ascendant: bool = false) -> Array[StringName]:
	var currency_keys: Array[StringName] = []
	currency_keys.assign(_currencies.keys())
	if sort_ascendant:
		currency_keys.sort_custom(func(a,b): return _currencies[a]["value"] < _currencies[b]["value"])
	return currency_keys


## Erases the currency with id [param currency_id].
func erase_currency(currency_id: String) -> void:
	_currencies.erase(currency_id)
