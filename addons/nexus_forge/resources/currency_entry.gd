class_name NFCurrencyEntry
extends RefCounted


var name: String = ""
var value: int = 1:
	set(v):
		value = maxi(1, v)
var custom_data: Dictionary[StringName, Variant] = {}
var _flags: int = 0:
	set(f):
		if _flags == 0:
			_flags = f


func _set(property: StringName, value: Variant) -> bool:
	if custom_data.has(property):
		if typeof(value) != TYPE_NIL:
			custom_data[property] = value
		else:
			custom_data.erase(property)
		return true
	return false


func _get(property: StringName) -> Variant:
	if custom_data.has(property):
		return custom_data[property]
	return null


func from_value(total_value: int) -> int:
	if total_value < value:
		return 0
	elif total_value == value:
		return 1
	else:
		return floori(total_value / float(value))


func is_valid() -> bool:
	return BitUtils.is_bit_index(_flags, 0, true)


func is_custom() -> bool:
	return BitUtils.is_bit_index(_flags, 1, true)


static func _get_flags(valid: bool, custom: bool, lock: bool) -> int:
	var flags: int = 0
	if valid:
		flags = BitUtils.set_bit_index(flags, 0, true)
	if custom:
		flags = BitUtils.set_bit_index(flags, 1, true)
	if lock:
		flags = BitUtils.set_bit_index(flags, 63, true)
	return flags
