@icon("res://addons/nexus_forge/icons/wallet_bag_icon.svg")
class_name NFCurrencyWallet
extends RefCounted
## An object used for holding the currencies registered on
## Nexus Forge's currency manager.
##
## This object keeps track of the amount of each currency stored and
## provides helper method to change them safely. Whenever a value changes
## the signal [signal NFCurrencyWallet.wallet_changed] is emmited.[br]
## The amounts, if handled through the methods, will always perform safe
## operations and never overflow.

## Emitted when the wallet is updated
signal wallet_changed


var _wallet: Dictionary[StringName, int] = {}


## Adds currencies to the wallet in bulk.[br]
## [b]Note:[/b] This method sums the currencies safely, meaning that if
## a currency amount passed in [param funds] would've overflown the data,
## it'll keep it at the max possible integer.
func add_funds(funds: Dictionary[StringName, int]) -> void:
	var updated: bool = false
	
	for fund in funds.keys():
		if not NexusForge.CurrencyManager.has_currency(fund) or funds[fund] <= 0:
			continue
		
		if _wallet.has(fund):
			_wallet[fund] = NFMath.safe_sum(_wallet[fund], funds[fund])
			updated = true
		else:
			_wallet[fund] = funds[fund]
			updated = true
	
	if updated:
		wallet_changed.emit()


## Adds a [param currency] to the wallet by the specified [param amount].[br]
## [b]Note:[/b] This method sums the currency safely, meaning that if
## [param value] would've overflown the data, it'll keep it at the max
## possible integer.
func add_currency(currency: StringName, value: int) -> void:
	if not NexusForge.CurrencyManager.has_currency(currency) or value <= 0:
		return
	
	if _wallet.has(currency):
		var prev: int = _wallet[currency]
		_wallet[currency] = NFMath.safe_sum(_wallet[currency], value)
		if prev != _wallet[currency]:
			wallet_changed.emit()
	else:
		_wallet[currency] = value
		wallet_changed.emit()


## Returns [code]true[/code] if this wallet has equal or more [param amount]
## of [param currency]
func has_enough(currency: StringName, amount: int) -> bool:
	amount = maxi(0, amount)
	return amount <= _wallet.get(currency, 0)


## Returns [code]true[/code] if this wallet has equal or more funds matching
## [param to_match] multiplied by [param times].
func has_enough_funds(to_match: Dictionary[StringName, int], times: int = 1) -> bool:
	if times < 1:
		return true
	
	var valid_currencies: Dictionary[StringName, int] = {}
	
	for id in to_match:
		if to_match[id] <= 0:
			continue
		valid_currencies[id] = to_match[id]
	
	for currency in valid_currencies:
		var cost: int = valid_currencies[currency]
		
		if NFMath.INT_MAX / cost < times:
			return false
		
		if _wallet.get(currency, 0) < cost * times:
			return false
	
	return true


## Returns the total amount [param of_currency] in this wallet.
func current_amount(of_currency: StringName) -> int:
	return _wallet.get(of_currency, 0)


## Removes [param currency] from this wallet by the specified [param amount].
func remove_currency(currency: StringName, amount: int) -> bool:
	amount = maxi(0, amount)
	if amount <= 0:
		return true
	
	if not has_enough(currency, amount):
		return false
	
	if _wallet[currency] == amount:
		_wallet.erase(currency)
	else:
		_wallet[currency] -= amount
	
	wallet_changed.emit()
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
	
	wallet_changed.emit()
	return true


## Returns the total value of the wallet. Just like with
## [method NexusForge.CurrencyManager.currency_value] if the combined value exceed
## the maximum integer, it'll return the maximum integer value instead of the
## total combined value.
func total_value() -> int:
	return NexusForge.CurrencyManager.currency_value(_wallet)


## Clears the wallet of all currencies.
func clear() -> void:
	if _wallet.is_empty():
		return
	
	_wallet.clear()
	wallet_changed.emit()


## Returns the current state of the wallet for serialization.
## This is functionally identical to [method NFCurrencyWallet.as_dictionary]
## but aligns with the plugin's serialization standards.
func get_state() -> Dictionary[StringName, int]:
	return _wallet.duplicate()


## Restores the wallet to a given [param state] dictionary.[br]
## [b]Note:[/b] Using this method won't emit the
## [signal NFCurrencyWallet.wallet_changed] signal.
func set_state(state: Dictionary) -> void:
	_wallet.clear()
	
	for key in state:
		var key_type: int = typeof(key)
		var val_type: int = typeof(state[key])
		if key_type != TYPE_STRING_NAME and key_type != TYPE_STRING:
			continue
		if val_type != TYPE_INT and val_type != TYPE_FLOAT:
			continue
		
		var curr_key: StringName = StringName(key)
		var curr_am: int = int(state[key])
		if NexusForge.CurrencyManager.has_currency(curr_key) and 0 < curr_am:
			_wallet[curr_key] = curr_am
