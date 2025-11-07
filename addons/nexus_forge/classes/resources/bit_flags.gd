class_name BitFlags
extends Resource

## The amount of flags BitFlags can hold. Must be a value between 1 and 64 inclusive.
const MAX_BITMASK: int = 63

@export_storage var _bit_store: int = 0
@export_storage var _flag_data: Dictionary[StringName, int] = {}


func _find_next_available_bit() -> int:
	var _assigned_bits: int = 0
	
	for value in _flag_data.values():
		_assigned_bits += value
	
	for index in range(MAX_BITMASK):
		if ( _assigned_bits & ( 1 << index ) ) == 0:
			return index
	return -1


## Creates a flag with [param flag_id]. Returns [code]true[/code]
## if the flag was created.
func create_flag(flag_id: StringName) -> bool:
	if _flag_data.has(flag_id):
		return false
	
	var next_bit: int = _find_next_available_bit()
	
	if next_bit == -1:
		return false
	
	_flag_data[flag_id] = 1 << next_bit
	
	return true


## Removes flag_id from the registry.
func release_flag(flag_id: StringName) -> void:
	if _flag_data.has(flag_id):
		_bit_store = BitUtils.set_bits(
				_bit_store,
				_flag_data[flag_id],
				false)
		_flag_data.erase(flag_id)


## Returns [code]true[/code] if [param flag_id] is registered.
func has_flag(flag_id: StringName) -> bool:
	return _flag_data.has(flag_id)


## Returns an array of all the flags registered.
func get_flags() -> Array[StringName]:
	var all_flags: Array[StringName] = []
	all_flags.assign(_flag_data.keys())
	return all_flags


## Returns [code]true[/code] if all 64 flags are assigned.
func is_full() -> bool:
	return MAX_BITMASK <= _flag_data.size()


## Sets the flag assigned to [param flag_id] to [param value].
func set_flag(flag_id: String, value: bool) -> void:
	if not _flag_data.has(flag_id):
		return
	
	if value:
		_bit_store |= 1 << _flag_data[flag_id]
	else:
		_bit_store ^= 1 << ~_flag_data[flag_id]


## Sets an array of [param flags] to value. If a flag is
## missing it won't be set.
func set_flags(flags: Array[StringName], value: bool) -> void:
	var combined_mask: int = 0
	
	for flag in flags:
		if _flag_data.has(flag):
			combined_mask |= _flag_data[flag]
	
	if combined_mask == 0:
		return
	
	if value:
		_bit_store |= combined_mask
	else:
		_bit_store &= ~combined_mask


## Returns true if [param flag] is set to [param value].
func is_flag(flag: StringName, value: bool) -> bool:
	if not _flag_data.has(flag):
		return false
	
	return ( ( _bit_store & _flag_data[flag] ) != 0 ) == value


## Returns true if all all the [param flags] match [param value].
func are_flags(flags: Array[StringName], value: bool) -> bool:
	if not _flag_data.has_all(flags):
		return false
	
	var combined_mask: int = 0
	
	for flag in flags:
		if _flag_data.has(flag):
			combined_mask |= _flag_data[flag]
		else:
			return false
	
	if combined_mask == 0:
		return false
	
	var result: int = _bit_store & combined_mask
	
	if value:
		return result == combined_mask
	else:
		return result == 0


## Clears all the set flags.
func clear_flags() -> void:
	_bit_store = 0
	_flag_data.clear()
