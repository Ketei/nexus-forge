class_name NFCurrencyManager
extends RefCounted


## Emitted when a currency is created.
signal currency_created(id: StringName)
## Emitted when a currency is erased.
signal currency_erased(id: StringName)
## Emitted when the value of currencu [param id] was changed through
## this object.
signal value_changed(id: StringName)
## Emitted when the catalog is rebuilt by using [method NFCurrencyManager.load_catalog]
signal catalog_loaded


var _currencies: Dictionary[StringName, NFCurrencyEntry] = {}


## Loads a [param catalog] into this object. You can choose to
## [param clear_currencies] held in this object before loading the data.
func load_catalog(catalog: NFCurrencyCatalog, clear_currencies: bool = true) -> void:
	if clear_currencies:
		_currencies.clear()
	
	for currency_id in catalog.currencies():
		var entry: NFCurrencyEntry = NFCurrencyEntry.new()
		entry.id = currency_id
		entry.name = catalog.get_currency_name(currency_id)
		entry.value = maxi(1, catalog.get_currency_value(currency_id))
		entry.custom_data.assign(catalog.get_currency_custom_data(currency_id))
		entry._flags = NFCurrencyEntry._get_flags(false, true)
		_currencies[currency_id] = entry
	
	catalog_loaded.emit()


## Creates a new currency with [param currency_id] unless it already exists.
func create_currency(currency_id: StringName, value: int = 1, name: String = "") -> void:
	if _currencies.has(currency_id):
		return
	
	var new_entry: NFCurrencyEntry = NFCurrencyEntry.new()
	
	new_entry.id = currency_id
	new_entry.name = name
	new_entry.value = maxi(1, value)
	new_entry._flags = NFCurrencyEntry._get_flags(true, true)
	
	_currencies[currency_id] = new_entry
	
	currency_created.emit(currency_id)


## Returns true if the [param currency_id] is registered.
func has_currency(currency_id: StringName) -> bool:
	return _currencies.has(currency_id)


## Sets the value of [param currency_id] to be [param new_value].[br]
## The smallest value a currency can have is 1.
func set_currency_value(currency_id: StringName, new_value: int) -> void:
	new_value = maxi(1, new_value)
	if _currencies.has(currency_id) and _currencies[currency_id].value != new_value:
		var curr: NFCurrencyEntry = _currencies[currency_id]
		curr._flags = NFBitUtils.set_bit_index(curr._flags, 63, false)
		curr.value = new_value
		curr._flags = NFBitUtils.set_bit_index(curr._flags, 63, true)
		value_changed.emit(currency_id)


## Returns the value of [param currency_id] or [code]0[/code] if the curency
## isn't registered.
func get_currency_value(currency_id: StringName) -> int:
	if _currencies.has(currency_id):
		return _currencies[currency_id].value
	return 0


## Sets the name of [param currency_id] to be [param new_name].
func set_currency_name(currency_id: StringName, new_name: String) -> void:
	if _currencies.has(currency_id):
		_currencies[currency_id].name = new_name


## Returns the name of [param currency_id] or an empty string if the currency
## isn't registered.
func get_currency_name(currency_id: StringName) -> String:
	if _currencies.has(currency_id):
		return _currencies[currency_id].name
	return ""


## Sets the value of the custom data with key param data_key to [param data]
## on the given [param currency_id]. If param data is [code]null[/code] the
## entry will be erased instead.
func set_currency_data(currency_id: StringName, data_key: StringName, data: Variant) -> void:
	if not _currencies.has(currency_id):
		return
	
	if data == null:
		_currencies[currency_id].custom_data.erase(data_key)
	else:
		_currencies[currency_id].custom_data[data_key] = data


## Returns the value of [param data_key] of the custom data of
## [param currency_id].
func get_currency_data(currency_id: StringName, data_key: StringName) -> Variant:
	if _currencies.has(currency_id) and _currencies[currency_id].custom_data.has(data_key):
		return _currencies[currency_id].custom_data[data_key]
	return null


## Returns the keys of the custom data that [param currency_id] has.
func currency_data_keys(currency_id: StringName) -> Array[String]:
	var keys: Array[String] = []
	if _currencies.has(currency_id):
		keys.assign(_currencies[currency_id].custom_data.keys())
	return keys


## Clears the custom data of the currency with id [param currency_id]
func clear_currency_data(currency_id: StringName) -> void:
	if _currencies.has(currency_id):
		_currencies[currency_id].custom_data.clear()


## Returns an array containing the keys of all currencies.[br]
## The keys will be unsorted unless sort_ascendat is true, which will sort
## the array from lowest-value to highest-value.
func currencies(sort_ascendant: bool = false) -> Array[StringName]:
	var currency_keys: Array[StringName] = []
	currency_keys.assign(_currencies.keys())
	if sort_ascendant:
		currency_keys.sort_custom(func(a,b):
			if _currencies[a].value == _currencies[b].value:
				return false
			return _currencies[a].value < _currencies[b].value)
	return currency_keys


## Erases the currency with id [param currency_id].
func erase_currency(currency_id: String) -> void:
	if _currencies.erase(currency_id):
		currency_erased.emit(currency_id)


#region Utility

## Subtracts the amount from [param substract] to the pool [param from] and
## returns the remainder.[br]
func subtract_value(from: Dictionary[StringName, int], substract: Dictionary[StringName, int]) -> Dictionary[StringName, int]:
	var final_inventory: Dictionary[StringName, int] = {}
	
	for key in from:
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
			var amount_to_use: int = (deficit_value + c_value - 1) / c_value
			var total_spent: int = amount_to_use * c_value
			var change: int = total_spent - deficit_value
			
			final_inventory[currency_id] -= amount_to_use
		
			if 0 < change:
				var change_result: NFCurrencyDenominationResult = maximize_from_value(
						change)
				for change_coin in change_result.converted_currencies:
					if not final_inventory.has(change_coin):
						final_inventory[change_coin] = 0
					final_inventory[change_coin] += change_result.converted_currencies[change_coin]
		
			deficit_value = 0
			break
		else:
			deficit_value -= c_total_value
			final_inventory[currency_id] = 0
	
	return final_inventory


## Returns the total value of the currencies provided in [param currencies].[br]
## Currencies need to be provided with key-value:[br]
## [code]{currency id: currency amount}[/code][br]
## [b]Note:[/b] If the value of the sum of the currencies exceeds the maximum
## integer, it'll return the maximum integer instead of the total sum.
func currency_value(currency:Dictionary[StringName, int]) -> int:
	var total_value: int = 0
	
	for currency_id in currency:
		if not _currencies.has(currency_id):
			continue
		
		var curr_val: int = _currencies[currency_id]["value"]
		var curr_amount: int = currency[currency_id]
		
		var step_value: int = NFMath.safe_multiply(
				curr_val,
				curr_amount)
		
		total_value = NFMath.safe_sum(total_value, step_value)
	
	return total_value


## Converts a specified [param amount] of a [param from] currency into a
## [param to] currency based on their values.
## [br][br]
## If [param allow_loss] is [code]true[/code], the method maximizes
## the target currency yield, which may result in indivisible
## value being lost.[br]
## If [code]false[/code], it ensures that there is no lost value.
## [br][br]
## [b]Example:[/b]
## [codeblock]
## # Assuming "Bronze" has a value of 2, and "Silver" has a value of 3.
## # This will try to convert 5 bronze (total value of 10) to silver,
## # while allowing loss.
## var exchange = convert_currency(&"Bronze", &"Silver", 5, true)
## print(exchange.converted)  # Prints 3 (9 value)
## print(exchange.remainder)  # Prints 0 (Not enough remaining value for a Bronze coin)
## print(exchange.lost_value) # Prints 1 (value lost to conversion)
##
## var strict = convert_currency(&"Bronze", &"Silver", 5, false) # Or ommit the last argument
## print(strict.converted)  # Prints 2 (6 value)
## print(strict.remainder)  # Prints 2 (4 value)
## print(strict.lost_value) # Prints 0 (Zero loss)
## [/codeblock]
func convert_currency(from: StringName, to: StringName, amount: int, allow_loss: bool = false) -> NFCurrencyConversionResult:
	var result: NFCurrencyConversionResult = NFCurrencyConversionResult.new()
	result.origin_currency = from
	result.target_currency = to
	
	if not _currencies.has_all([from, to]):
		NFPluginGameHandler._log_msg(
				"currencies",
				"An invalid currency can't be converted: '%s' to '%s'" % [from, to],
				NFPluginGameHandler._LogLevel.ERROR)
		result.remainder = amount
		return result

	var from_value: int = _currencies[from].value
	var to_value: int = _currencies[to].value
	
	if from_value <= 0 or to_value <= 0:
		result.remainder = amount
		NFPluginGameHandler._log_msg(
			"currencies",
			"Currency values must be greater than 0: '%s' (%d), '%s' (%d)" % [from, from_value, to, to_value],
			NFPluginGameHandler._LogLevel.ERROR)
		return result
	
	var total_value: int = amount * from_value
	var converted_amount: int = total_value / to_value
	
	if not allow_loss:
		var common_divisor: int = NFMath.gcd(from_value, to_value)
		var step: int = from_value / common_divisor
		converted_amount = (converted_amount / step) * step
	
	var remainder_value: int = total_value - (converted_amount * to_value)
	
	result.converted = converted_amount
	result.remainder = remainder_value / from_value
	result.lost_value = remainder_value % from_value
	
	return result


## Converts an [param amount] of a [param currency_type] to be the highest
## denomination possible.
func maximize_from_currency(currency_type: StringName, amount: int) -> NFCurrencyDenominationResult:
	var out := NFCurrencyDenominationResult.new()
	out.origin_currency = currency_type
	out.was_maximized = true
	out.origin_amount = amount
	
	var result: Dictionary[StringName, int] = {}
	
	if not _currencies.has(currency_type):
		result[currency_type] = amount
		NFPluginGameHandler._log_msg(
				"currencies",
				"Invalid currency provided '%s'" % currency_type,
				NFPluginGameHandler._LogLevel.ERROR)
		out.converted_currencies = result
		out.lost_value = 0
		return out
	
	var denominations: Array[StringName] = []
	var input_value: int = _currencies[currency_type]["value"]
	
	for key in _currencies:
		if _currencies[key]["value"] <= input_value:
			continue
		denominations.append(key)
	
	denominations.sort_custom(func(a, b): return _currencies[b]["value"] < _currencies[a]["value"])
	
	var remaining_value: int = amount * input_value
	
	for denom in denominations:
		var denom_value: int = _currencies[denom]["value"]
		var exchangeable_amount: int = remaining_value / denom_value

		if 0 < exchangeable_amount:
			result[denom] = exchangeable_amount
			remaining_value -= exchangeable_amount * denom_value
	
	var leftover_input: int = remaining_value / input_value
	
	if 0 < leftover_input:
		result[currency_type] = leftover_input
		remaining_value -= leftover_input * input_value
	
	out.converted_currencies = result
	out.lost_value = remaining_value
	
	return out


## Returns an [NFCurrencyMinMaxResult] containing the highest currency amount 
## converted from a base [param value].
func maximize_from_value(value: int) -> NFCurrencyDenominationResult:
	var out := NFCurrencyDenominationResult.new()
	out.origin_currency = &""
	out.origin_amount = value
	out.was_maximized = true
	
	var maximized: Dictionary[StringName, int] = {}
	
	if value < 0:
		out.converted_currencies = maximized
		out.lost_value = 0
		return out
	
	var currency_ids: Array = _currencies.keys()
	
	currency_ids.sort_custom(func(a,b): return _currencies[b]["value"] < _currencies[a]["value"])
	
	var remainder: int = value
	
	for currency_id in currency_ids:
		var val: int = _currencies[currency_id]["value"]
		
		if val <= remainder:
			var amount: int = remainder / val
			if 0 < amount:
				maximized[currency_id] = amount
				remainder -= amount * val
		
		if remainder <= 0:
			break
	
	out.converted_currencies = maximized
	out.lost_value = remainder
	
	return out


## Converts an [param amount] of a [param currency_type] to be the lowest
## denomination possible.
func minimize_from_currency(currency_type: StringName, amount: int) -> NFCurrencyDenominationResult:
	var out := NFCurrencyDenominationResult.new()
	out.origin_currency = currency_type
	out.origin_amount = amount
	out.was_maximized = false
	
	var result: Dictionary[StringName, int] = {}
	
	if not _currencies.has(currency_type):
		NFPluginGameHandler._log_msg(
				"currencies",
				"Invalid currency can't be minimized '%s'" % currency_type,
				NFPluginGameHandler._LogLevel.ERROR)
		result[currency_type] = amount
		out.converted_currencies = result
		out.lost_value = 0
		return out

	var denominations: Array[StringName] = []
	var input_value: int = _currencies[currency_type]["value"]

	for key in _currencies:
		if input_value <= _currencies[key]["value"]:
			continue
		denominations.append(key)

	denominations.sort_custom(func(a, b): return _currencies[a]["value"] < _currencies[b]["value"])
	
	var remaining_value: int = amount * input_value

	for denom in denominations:
		var denom_value: int = _currencies[denom]["value"]
		var exchangeable_amount: int = remaining_value / denom_value

		if 0 < exchangeable_amount:
			result[denom] = exchangeable_amount
			remaining_value -= exchangeable_amount * denom_value
	
	var leftover_input: int = remaining_value / input_value
	if 0 < leftover_input:
		result[currency_type] = leftover_input
		remaining_value -= leftover_input * input_value
	
	out.converted_currencies = result
	out.lost_value = remaining_value
	
	return out

#endregion

## An object returned as the result after calling 
## [method NFCurrencyManager.convert_currency]
class NFCurrencyConversionResult extends RefCounted:
	## The currency that was converted.
	var origin_currency: StringName
	## The amount of [member target_currency] successfully
	## converted from [member origin_currency].
	var converted: int
	## The currency that [member origin_currency] was converted to.
	var target_currency: StringName
	## How much [member origin_currency] was left after conversion.
	var remainder: int
	## How much value was lost due to an indivisible value of
	## [member origin_currency] by [member target_currency]
	var lost_value: int
	
	## Returns the currency as a balance.
	## [br][br]
	## Note: Any [member lost_value] will not be carried over to the balance.
	func as_balance() -> NFCurrencyBalance:
		var new_balance := NFCurrencyBalance.new()
		new_balance.set_currency(origin_currency, remainder)
		new_balance.set_currency(target_currency, converted)
		return new_balance


## An object returning when minimizing or maximizing the value of
## a currency when calling [method NFCurrencyManager.minimize_from_currency],
## or [method NFCurrencyManager.maximize_from_currency]
## [method NFCurrencyManager.maximize_from_value]
class NFCurrencyDenominationResult extends RefCounted:
	## The original ID the currency was converted from
	var origin_currency: StringName
	## The amount of [member origin_currency] that was converted.
	var origin_amount: int
	## Whether the [member origin_currency] was maximized or minimized
	var was_maximized: bool
	## The currencies and total values after the conversion
	var converted_currencies: Dictionary[StringName, int]
	## How much value was lost due to an indivisible value
	## between currencies.
	var lost_value: int
	
	
	## Returns the currencies as a balance.
	## [br][br]
	## Note: Any [member lost_value] will not be carried over to the balance.
	func as_balance() -> NFCurrencyBalance:
		var new_balance := NFCurrencyBalance.new(converted_currencies)
		return new_balance
