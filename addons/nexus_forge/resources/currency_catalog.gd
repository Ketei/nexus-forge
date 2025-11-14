@tool
@icon("res://addons/nexus_forge/icons/currency_catalog.svg")
class_name CurrencyCatalog
extends Resource


const CURRENCY_DEFAULT_DATA: Dictionary[String, Variant] = {}

@export_storage var _currencies: Dictionary[StringName, Dictionary] = {
	#&"copper": {"name": "CP", "value": 1, "data": null},
	#&"silver": {"name": "SP", "value": 10, "data": null},
	#&"electrum": {"name": "EP", "value": 50, "data": null},
	#&"gold": {"name": "GP", "value": 100, "data": null},
	#&"platinum": {"name": "PP", "value": 1000, "data": null},
}


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


func has_currency(currency_id: StringName) -> bool:
	return _currencies.has(currency_id)


func set_currency_value(currency_id: StringName, new_value: int) -> void:
	if _currencies.has(currency_id):
		_currencies[currency_id]["value"] = new_value


func get_currency_value(currency_id: StringName) -> int:
	if _currencies.has(currency_id):
		return _currencies[currency_id]["value"]
	return 0


func set_currency_name(currency_id: StringName, new_name: String) -> void:
	if _currencies.has(currency_id):
		_currencies[currency_id]["name"] = new_name


func get_currency_name(currency_id: StringName) -> String:
	if _currencies.has(currency_id):
		return _currencies[currency_id]["name"]
	return ""


## Sets data. If [param data] is [code]null[/code] it will erase the data instead.
func set_currency_data(currency_id: StringName, data_key: String, data: Variant) -> void:
	if not _currencies.has(currency_id):
		return
	
	if data == null:
		if _currencies[currency_id]["data"].has(data_key):
			_currencies[currency_id]["data"].erase(data_key)
	else:
		_currencies[currency_id]["data"][data_key] = data


func get_currency_data(currency_id: StringName, data_key: String) -> Variant:
	if _currencies.has(currency_id) and _currencies[currency_id]["data"].has(data_key):
		return _currencies[currency_id]["data"][data_key]
	return null


func currency_data_keys(currency_id: StringName) -> Array[String]:
	var keys: Array[String] = []
	if _currencies.has(currency_id):
		keys.assign(_currencies[currency_id]["data"].keys())
	return keys


func clear_currency_data(currency_id: StringName) -> void:
	if _currencies.has(currency_id):
		_currencies[currency_id]["data"].clear()


func currencies() -> Array[StringName]:
	var currencies: Array[StringName] = []
	currencies.assign(_currencies.keys())
	return currencies


func erase_currency(currency_id: String) -> void:
	_currencies.erase(currency_id)


# ----- Utility -----
func convert_currency(from: StringName, to: StringName, amount: int) -> Dictionary:
	if not _currencies.has_all([from, to]):
		printerr("An invalid currency was given: ", from, "/", to)
		return {from: amount, to: 0}

	var from_value: int = _currencies[from]["value"]
	var to_value: int = _currencies[to]["value"]

	var converted_amount: int = floori((amount * from_value) / to_value)
	var remainder: int = floori( ( (amount * from_value) - (converted_amount * to_value) ) / from_value )

	var result: Dictionary = {from: remainder, to: converted_amount}
	
	return result


func maximize_currency(currency_type: StringName, amount: int) -> Dictionary[StringName, int]:
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


func minimize_currency(currency_type: StringName, amount: int) -> Dictionary[StringName, int]:
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
