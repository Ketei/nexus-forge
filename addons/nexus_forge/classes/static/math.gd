class_name Math
extends Node
## Class to perform math operations in a more convenient way.



## Calculates jump gravity.
static func calculate_jump_gravity(jump_height: int, time_to_apex: float, up_negative: bool = true) -> float:
	return ( (-2.0 * jump_height) / pow(time_to_apex, 2.0) ) * (1.0 - ( 2 * float(up_negative) ) )


## Calculates jump velocity.
static func calculate_jump_velocity(jump_height: int, time_to_apex: float, up_negative: bool = true) -> float:
	return ( (2.0 * jump_height) / time_to_apex ) * (1.0 - ( 2 * float(up_negative) ) )


## Calculates normal gravity.
static func calculate_normal_gravity(jump_height: int, time_to_floor: float, up_negative: bool = true) -> float:
	return ( (-2.0 * jump_height) / pow(time_to_floor, 2.0) ) * (1.0 - ( 2 * float(up_negative) ) )


## Exponential decay function
static func exp_decay(from: float, to: float, rate: float, delta: float) -> float:
	return to + (from - to) * exp(-rate * delta)


## Logic xnor gate.
static func xnor(input_a: bool, input_b: bool) -> bool:
	return input_a == input_b


## Logic xor gate.
static func xor(input_a: bool, input_b: bool) -> bool:
	return input_a != input_b


## Returns true if both numbers are positive or both negative. 0 acts as
## a neutral number and will always match with the other.
static func sign_comparison(n_1: float, n_2: float) -> bool:
	if n_1 == 0 or n_2 == 0:
		return true
	return signf(n_1) == signf(n_2)


## Takes 2 numbers and returns the one closest to 0
static func closest_to_zero(numb_a: float, numb_b: float) -> float:
	if absf(numb_a) < absf(numb_b):
		return numb_a
	return numb_b


## Sums all the numerical values inside an array.
static func sum_arrayf(values_array: Array) -> float:
	var type_arg: int = typeof(values_array)
	
	if type_arg < 28 or 38 < type_arg:
		push_error("Can't iterate non-array")
		return 0
	
	var total_value: float = 0
	for item in values_array:
		var type: int = typeof(item)
		if type != TYPE_INT and type != TYPE_FLOAT:
			continue
		total_value += item
	return total_value


static func sum_arrayi(values_array: Array) -> int:
	var type_arg: int = typeof(values_array)
	
	if type_arg < 28 or 33 < type_arg:
		push_error("Can't iterate non-array")
		return 0
	
	var total_value: float = 0
	for item in values_array:
		var type: int = typeof(item)
		if type != TYPE_INT and type != TYPE_FLOAT:
			continue
		total_value += item
	return int(total_value)


## Returns the distance between 2 numbers. Typed as float.
static func distancef(n_1: float, n_2: float) -> float:
	return absf(n_1 - n_2)


## Returns the distance between 2 numbers. Typed as integer.
static func distancei(n_1: float, n_2: float) -> int:
	var sum: float = n_1 - n_2
	return absi(sum)


## Returns true if [param value] is between 2 numbers.
static func is_in_range(what: float, range_a: float, range_b: float) -> bool:
	if range_a < range_b:
		return range_a <= what and what <= range_b
	else:
		return range_b <= what and what <= range_a


## [method @GlobalScope.signf] but returns the value as an integer.
static func signfi(x: float) -> int:
	return int(signf(x))


## Sets the bit on the index [param bit_index] of the [param on] value
## to [param value].
static func set_bit(on: int, bit_index: int, value: bool) -> int:
	if bit_index < 0 or 63 < bit_index:
		return 0
	
	if value:
		on |= 1 << bit_index
	else:
		on ^= 1 << bit_index
	
	return on


## Turns the bits defined in [param bits] on the value [param on] to 1.
static func or_bits(on: int, bits: int) -> int:
	return on | bits


## Turns the bits defined in [param bits] on the value [param on] to 0.
static func not_bits(on: int, bits: int) -> int:
	return on ^ bits


## Returns true if the bit of [param on] on index [param bit_index]
## is set to [param enabled].
static func is_bit(on: int, bit_index: int, enabled: bool) -> bool:
	if bit_index < 0 or 63 < bit_index:
		return false
	
	var bit_on: bool = (on & (1 << bit_index))
	
	return bit_on == enabled


## Will check if the enabled bits on [param mask] are [code]1[/code]
## on [param on] if enabled is [code]true[/code] or [code]0[/code]
## if enabled is [code]false[/code].
static func are_bits(on: int, mask: int, enabled: bool) -> bool:
	if enabled:
		return (on & mask) == mask
	else:
		return (on & mask) == 0


## An object whose only function is to keep track of bit-flags.[br]
## Each BitFlag object can only keep track of 64 flags.
static func create_bitflags() -> BitFlags:
	return BitFlags.new()


## An object made to track bit-flags via IDs.
class BitFlags extends Resource:
	const MAX_BITMASK: int = 63 # Must be a value between 1 and 64 inclusive.
	@export var _bit_store: int = 0
	@export var _flag_data: Dictionary[StringName, int] = {}
	
	
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
			_bit_store = Math.set_bit(
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
