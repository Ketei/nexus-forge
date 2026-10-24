class_name NFCurrencyBalance
extends RefCounted
## An object used for currency operations

var _balance: Dictionary[StringName, int] = {}


func _init(initial_balance: Dictionary[StringName, int] = {}) -> void:
	for currency_id in initial_balance:
		set_currency(currency_id, initial_balance[currency_id])


## Sums the param amount of the param currency from this balance.[br]
## Returns this same object in case further operations are required.
func add_currency(currency: StringName, amount: int) -> NFCurrencyBalance:
	if amount <= 0 or not NexusForge.Currencies.has(currency):
		return self
	 
	var new_value: int = NFMath.safe_sum(_balance.get(currency, 0), amount)
	_balance[currency] = new_value
	return self


## Removes the param amount of the param currency from this balance.[br]
## Returns this same object in case further operations are required.
func subtract_currency(currency: StringName, amount: int) -> NFCurrencyBalance:
	if not _balance.has(currency) or amount <= 0:
		return self
	
	var new_value: int = NFMath.safe_sum(_balance[currency], -amount)
	if new_value <= 0:
		_balance.erase(currency)
	else:
		_balance[currency] = new_value
	return self


## Sets the currency [param id] to be [param to].[br]
## Returns this same object in case further operations are required.
func set_currency(id: StringName, to: int) -> NFCurrencyBalance:
	if to < 0 or not NexusForge.Currencies.has(id):
		return self
	
	if to == 0:
		_balance.erase(id)
	else:
		_balance[id] = to
	
	return self


## Returns the currency value of [param id].
func get_currency(id: StringName) -> int:
	return _balance.get(id, 0)


## Removes all currencies from this balance
func clear() -> void:
	_balance.clear()


## Adds the currencies (not the value) of the [param from] balance.[br]
## Returns this same object in case further operations are required.
func add_balance(from: NFCurrencyBalance) -> NFCurrencyBalance:
	if from == null: # Instance checks are safer but might be excessive?
		return self
	
	for curr_id in from._balance:
		add_currency(curr_id, from._balance[curr_id])
	return self


## Removes the currencies (not the value) of the [param from] balance.[br]
## Returns this same object in case further operations are required.
func subtract_balance(from: NFCurrencyBalance) -> NFCurrencyBalance:
	if from == null: # Instance checks are safer but might be excessive?
		return self
	
	for curr_id in from._balance:
		subtract_currency(curr_id, from._balance[curr_id])
	return self


## Returns the currency as a dictionary.
func as_dictionary() -> Dictionary[StringName, int]:
	return _balance.duplicate() # Useful for serialization


## Returns the absolute value that this balance represents.
func as_value() -> int:
	var final_value: int = 0
	for curr_id in _balance:
		var currency_amount: int = _balance[curr_id]
		var currency: NFCurrencyEntry = NexusForge.Currencies.get(curr_id)
		if currency == null or currency_amount <= 0:
			continue
		final_value = NFMath.safe_sum(
				final_value,
				currency.value * currency_amount)
	return final_value
