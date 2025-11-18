@tool
@icon("res://addons/nexus_forge/icons/currency_catalog.svg")
class_name CurrencyCatalog
extends Resource


## Data that all newly created currencies will have.
const CURRENCY_DEFAULT_DATA: Dictionary[String, Variant] = {}

@export_storage var _currencies: Dictionary[StringName, Dictionary] = {
	#&"copper": {"name": "CP", "value": 1, "data": null},
	#&"silver": {"name": "SP", "value": 10, "data": null},
	#&"electrum": {"name": "EP", "value": 50, "data": null},
	#&"gold": {"name": "GP", "value": 100, "data": null},
	#&"platinum": {"name": "PP", "value": 1000, "data": null},
}


## Creates a new currency with [param currency_id] unless it already exists.
func create_currency(currency_id: StringName) -> void:
	if _currencies.has(currency_id):
		return
	var currency_data: Dictionary[String, Variant] = {}
	currency_data.assign(CURRENCY_DEFAULT_DATA)
	
	var new_entry: Dictionary = {
		"name": "",
		"value": 0,
		"data": currency_data}
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


## Returns the value of [param currency_id] or [code]0[/code] if the curency
## isn't registered.
func get_currency_value(currency_id: StringName) -> int:
	if _currencies.has(currency_id):
		return _currencies[currency_id]["value"]
	return 0


## Sets the name of [param currency_id] to be [param new_name].
func set_currency_name(currency_id: StringName, new_name: String) -> void:
	if _currencies.has(currency_id):
		_currencies[currency_id]["name"] = new_name


## Returns the name of [param currency_id] or an empty string if the currency
## isn't registered.
func get_currency_name(currency_id: StringName) -> String:
	if _currencies.has(currency_id):
		return _currencies[currency_id]["name"]
	return ""


## Sets the value of the custom data with key param data_key to [param data]
## on the given [param currency_id]. If param data is [code]null[/code] the
## entry will be erased instead.
func set_currency_data(currency_id: StringName, data_key: String, data: Variant) -> void:
	if not _currencies.has(currency_id):
		return
	
	if data == null:
		if _currencies[currency_id]["data"].has(data_key):
			_currencies[currency_id]["data"].erase(data_key)
	else:
		_currencies[currency_id]["data"][data_key] = data


## Returns the value of [param data_key] of the custom data of
## [param currency_id].
func get_currency_data(currency_id: StringName, data_key: String) -> Variant:
	if _currencies.has(currency_id) and _currencies[currency_id]["data"].has(data_key):
		return _currencies[currency_id]["data"][data_key]
	return null


## Returns the keys of the custom data that [param currency_id] has.
func currency_data_keys(currency_id: StringName) -> Array[String]:
	var keys: Array[String] = []
	if _currencies.has(currency_id):
		keys.assign(_currencies[currency_id]["data"].keys())
	return keys


## Clears the custom data of the currency with id [param currency_id]
func clear_currency_data(currency_id: StringName) -> void:
	if _currencies.has(currency_id):
		_currencies[currency_id]["data"].clear()


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


# ----- Utility -----
## Substracts the amount from [param substract] to the pool [param from] and
## returns the remainder.[br]
func substract_value(from: Dictionary[StringName, int], substract: Dictionary[StringName, int]) -> Dictionary[StringName, int]:
	var final_inventory: Dictionary[StringName, int] = {}
	
	for key in from.keys():
		if _currencies.has(key):
			final_inventory[key] = from[key]
	
	var total_value: int = currency_value(from)
	var deficit_value: int = currency_value(substract)
	
	if deficit_value <= 0:
		return final_inventory
	elif total_value < deficit_value:
		return {}
	
	var sorted_keys: Array[StringName] = []
	sorted_keys.assign(final_inventory.keys())
	sorted_keys.sort_custom(func(a,b): return _currencies[a]["value"] < _currencies[b]["value"])
	
	for currency_id in sorted_keys:
		var c_value: int = _currencies[currency_id]["value"]
		var c_amount: int = final_inventory[currency_id]
		var c_total_value: int = c_amount * c_value
		if deficit_value <= c_total_value:
			var amount_to_use: int = ceili(deficit_value / float(c_value))
			var total_spent: int = amount_to_use * c_value
			var change: int = total_spent - deficit_value
			
			final_inventory[currency_id] -= amount_to_use
		
			if 0 < change:
				var change_coins: Dictionary[StringName, int] = maximize_from_value(change)
				for change_coin in change_coins.keys():
					if not final_inventory.has(change_coin):
						final_inventory[change_coin] = 0
					final_inventory[change_coin] += change_coins[change_coin]
		
			deficit_value = 0
			break
		else:
			deficit_value -= c_total_value
			final_inventory.erase(currency_id)
	
	return final_inventory


## Returns the total value of the currencies provided in [param currencies].[br]
## Currencies need to be provided with key-value:[br]
## [code]currency id[/code]: [code]currency amount[/code]
func currency_value(currency:Dictionary[StringName, int]) -> int:
	var total_value: int = 0
	
	for currency_id in currency.keys():
		if not _currencies.has(currency_id):
			continue
		total_value += _currencies[currency_id]["value"] * currency[currency_id]
	
	return total_value


## Converts an [param amount] currency [param from] a type [param to] another.[br]
## The returned dictionary cotnains 2 keys:[br]
## [param from] which will contain the remainder.[br]
## [param to] which will contain the converted amount.
func convert_currency(from: StringName, to: StringName, amount: int) -> Dictionary[StringName, int]:
	if not _currencies.has_all([from, to]):
		printerr("An invalid currency was given: ", from, "/", to)
		return {from: amount, to: 0}

	var from_value: int = _currencies[from]["value"]
	var to_value: int = _currencies[to]["value"]

	var converted_amount: int = floori((amount * from_value) / to_value)
	var remainder: int = floori( ( (amount * from_value) - (converted_amount * to_value) ) / from_value )

	var result: Dictionary[StringName, int] = {from: remainder, to: converted_amount}
	
	return result


## Converts an [param amount] of a [param currency_type] to be the highest
## denomination possible.
func maximize_from_currency(currency_type: StringName, amount: int) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	if not _currencies.has(currency_type):
		result[currency_type] = amount
		printerr("Invalid currency type: ", currency_type)
		return result
	
	var denominations: Array[StringName] = []
	var input_value: int = _currencies[currency_type]["value"]
	
	# Extract denominations and sort in descending order (important for maximizing)
	for key in _currencies.keys():
		# We skip lower or equally denominated currencies.
		if _currencies[key]["value"] <= input_value:
			continue
		denominations.append(key)

	denominations.sort_custom(func(a, b): return _currencies[b]["value"] < _currencies[a]["value"]) # Sort descending

	var current_amount: int = amount # Start with the initial amount

	for denom in denominations:
		var denom_value: int = _currencies[denom]["value"]
		var exchangeable_amount: int = floori(float(current_amount * input_value) / denom_value)

		if 0 < exchangeable_amount:
			result[denom] = exchangeable_amount
			current_amount -= floori((exchangeable_amount * denom_value) / input_value)
	
	if 0 < current_amount:
		result[currency_type] = current_amount

	return result


## Returns a dictionary containing the highest currency amount converted from
## a base [param currency_value].[br]
## If there is a remainder that couldn't be converted (due to a lack of a 
## currency with a value of 1) the returned dictionary will contain a key
## [code]_remainder[/code] with the remainder of the conversion.
func maximize_from_value(currency_value: int) -> Dictionary[StringName, int]:
	var maximized: Dictionary[StringName, int] = {}
	if currency_value < 0:
		return maximized
	
	var currency_ids: Array = _currencies.keys()
	
	currency_ids.sort_custom(func(a,b): return _currencies[b]["value"] < _currencies[a]["value"])
	
	var remainder: int = currency_value
	
	for currency_id in currency_ids:
		var value: int = _currencies[currency_id]["value"]
		
		if value <= remainder :
			var amount: int = floori(remainder / float(value))
			if 0 < amount:
				maximized[currency_id] = amount
				remainder -= amount * value
		
		if remainder <= 0:
			break
	
	if 0 < remainder:
		maximized[&"_remainder"] = remainder
	
	return maximized


## Converts an [param amount] of a [param currency_type] to be the lowest
## denomination possible.
func minimize_from_currency(currency_type: StringName, amount: int) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}  # Start with the initial amount
	
	if not _currencies.has(currency_type):
		printerr("An invalid currency was given: ", currency_type)
		result[currency_type] = amount
		return result

	var denominations: Array[StringName] = []
	var input_value: int = _currencies[currency_type]["value"]

	# Extract denominations and sort in ascending order (important for minimizing)
	for key in _currencies:
		# We skip higher or equally denominated currencies.
		if input_value <= _currencies[key]["value"]:
			continue
		denominations.append(key)

	denominations.sort_custom(func(a, b): return _currencies[a]["value"] < _currencies[b]["value"]) # Sort ascending

	var current_amount: int = amount

	for denom in denominations:
		var denom_value: int = _currencies[denom]["value"]
		var exchangeable_amount: int = floori(float(current_amount * input_value) / denom_value)

		if 0 < exchangeable_amount:
			result[denom] = exchangeable_amount
			current_amount -= floori( (exchangeable_amount * denom_value) / input_value )
	
	if 0 < current_amount:
		result[currency_type] = current_amount
	
	return result
