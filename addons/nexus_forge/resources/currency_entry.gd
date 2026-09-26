class_name NFCurrencyEntry
extends RefCounted


## The ID of the currency.
var id: StringName = &"":
	set(new_id):
		if NFBitUtils.is_bit_index(_flags, 63, false):
			id = new_id
## The name of the currency.
var name: String = ""
## The unitary value of the currency.
var value: int = 1:
	set(v):
		if NFBitUtils.is_bit_index(_flags, 63, false):
			value = maxi(1, v)
## The custom data of the currency.
var custom_data: Dictionary[StringName, Variant] = {}
var _flags: int = 0:
	set(f):
		if _flags == 0:
			_flags = f


## Converts [param total_value] to this currency.
func from_value(total_value: int) -> int:
	if total_value < value:
		return 0
	elif total_value == value:
		return 1
	else:
		return floori(total_value / float(value))


func is_custom() -> bool:
	return NFBitUtils.is_bit_index(_flags, 0, true)


static func _get_flags(custom: bool, lock: bool) -> int:
	var flags: int = 0
	if custom:
		flags = NFBitUtils.set_bit_index(flags, 0, true)
	if lock:
		flags = NFBitUtils.set_bit_index(flags, 63, true)
	return flags
