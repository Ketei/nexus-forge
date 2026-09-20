class_name NFCatalogEntry
extends RefCounted
## An entry object for a catalog.

## The name of the entry.
var name: String = ""
## The description of the entry.
var description: String = ""
var _flags: int = 0:
	set(f):
		if _flags == 0:
			_flags = f
## Custom data assigned to this entry.
var custom_data: Dictionary[StringName, Variant] = {}


## Returns if this entry is from a built-in item, or was added in programatically.
func is_custom() -> bool:
	return NFBitUtils.is_bit_index(_flags, 0, true)


static func _get_flags(custom: bool, lock: bool) -> int:
	var flags: int = 0
	if custom:
		flags = NFBitUtils.set_bit_index(flags, 0, true)
	if lock:
		flags = NFBitUtils.set_bit_index(flags, 63, true)
	return flags
