@icon("res://addons/nexus_forge/icons/wallet_bag_icon.svg")
class_name CurrencyWallet
extends Resource
## A resource used for holding the currencies registered on
## [member NexusForge.Currency].
##
## This resource keeps track of the amount of each currency stored and
## provides helper method to change them safely. Whenever a value changes
## the signal [signal Resource.changed] is emmited.[br]
## The amounts, if handled through the methods, will always perform safe
## operations and never overflow.[br]
## Currencies can also be accessed and set directly by using it's ID like
## CurrencyWallet.gold = 12. But unlike using the methods, if using assignment 
## operators (+=, -=, etc.) the currency can overflow and if such happens,
## it'll be reset to 0.


var _wallet: Dictionary[StringName, int] = {}


func _get(property: StringName) -> Variant:
	if _wallet.has(property):
		return _wallet[property]
	return 0


func _set(property: StringName, value: Variant) -> bool:
	var type: int = typeof(value)
	if type != TYPE_INT and type != TYPE_FLOAT:
		return false
	
	if not NexusForge.Currency.has_currency(property):
		return false
	
	if value <= 0:
		if _wallet.erase(property):
			emit_changed()
	else:
		var new_value: int = int(value)
		var update: bool = not _wallet.has(property) or _wallet[property] != new_value
		_wallet[property] = new_value
		if update:
			emit_changed()
	
	return true


## Assigns the currencies in [param values] to this wallet.[br]
## [b]Note:[/b] Using this method won't emit the [signal Resource.changed]
## signal.
func assign(values: Dictionary[StringName, int]) -> void:
	var valid_values: Dictionary[StringName, int] = {}
	
	for c_id in values.keys():
		if not NexusForge.Currency.has_currency(c_id) or values[c_id] <= 0:
			continue
		valid_values[c_id] = values[c_id]
	
	_wallet.assign(values)


## Adds currencies to the wallet in bulk.[br]
## [b]Note:[/b] This method sums the currencies safely, meaning that if
## a currency amount passed in [param funds] would've overflown the data,
## it'll keep it at the max possible integer.
func add_funds(funds: Dictionary[StringName, int]) -> void:
	var updated: bool = false
	
	for fund in funds.keys():
		if not NexusForge.Currency.has_currency(fund) or funds[fund] <= 0:
			continue
		
		if _wallet.has(fund):
			_wallet[fund] = Math.safe_sum(_wallet[fund], funds[fund])
			updated = true
		else:
			_wallet[fund] = funds[fund]
			updated = true
	
	if updated:
		emit_changed()


## Adds a [param currency] to the wallet by the specified [param amount].[br]
## [b]Note:[/b] This method sums the currency safely, meaning that if
## [param value] would've overflown the data, it'll keep it at the max
## possible integer.
func add_currency(currency: StringName, value: int) -> void:
	if not NexusForge.Currency.has_currency(currency) or value <= 0:
		return
	
	if _wallet.has(currency):
		var prev: int = _wallet[currency]
		_wallet[currency] = Math.safe_sum(_wallet[currency], value)
		if prev != _wallet[currency]:
			emit_changed()
	else:
		_wallet[currency] = value
		emit_changed()


## Returns [code]true[/code] if this wallet has equal or more [param amount]
## of [param currency]
func has_enough(currency: StringName, amount: int) -> bool:
	if _wallet.has(currency) and amount <= _wallet[currency]:
		return true
	return false


## Returns [code]true[/code] if this wallet has equal or more funds matching
## [param to_match] multiplied by [param times].
func has_enough_funds(to_match: Dictionary[StringName, int], times: int = 1) -> bool:
	if times < 1:
		return true
	
	var valid_currencies: Dictionary[StringName, int] = {}
	for id in to_match.keys():
		if to_match[id] <= 0:
			continue
		valid_currencies[id] = to_match[id]
	
	for currency in valid_currencies.keys():
		if not _wallet.has(currency) or _wallet[currency] < valid_currencies[currency] * times:
			return false
	return true


## Returns the total amount [param of_currency] in this wallet.
func current_amount(of_currency: StringName) -> int:
	if _wallet.has(of_currency):
		return _wallet[of_currency]
	return 0


## Removes [param currency] from this wallet by the specified [param amount].
func remove_currency(currency: StringName, amount: int) -> bool:
	if not has_enough(currency, amount):
		return false
	
	if _wallet[currency] == amount:
		_wallet.erase(currency)
	else:
		_wallet[currency] -= amount
	
	emit_changed()
	return true


## Removes the amount of currencies specified in [param amount] multiplied
## by [param times].
func remove_funds(amount: Dictionary[StringName, int], times: int = 1) -> bool:
	if times < 1 or not has_enough_funds(amount, times):
		return false
	
	for id in amount.keys():
		if amount[id] < 1:
			continue
		var total_to_remove: int = amount[id] * times
		if _wallet[id] == total_to_remove:
			_wallet.erase(id)
		else:
			_wallet[id] -= total_to_remove
	
	emit_changed()
	return true


## Returns the total value of the wallet. Just like with
## [method NexusForge.Currency.currency_value] if the combined value exceed
## the maximum integer, it'll return the maximum integer value instead of the
## total combined value.
func total_value() -> int:
	return NexusForge.Currency.currency_value(_wallet)


## Clears the wallet of all currencies.
func clear() -> void:
	if _wallet.is_empty():
		return
	
	_wallet.clear()
	emit_changed()


## Returns the wallet's currencies and amounts as a dictionary.
func as_dictionary() -> Dictionary[StringName, int]:
	return _wallet.duplicate()
