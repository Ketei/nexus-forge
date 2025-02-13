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
static func sum_array(values_array: Array) -> float:
	var total_value: float = 0
	for item in values_array:
		var type: int = typeof(item)
		if type != TYPE_INT and type != TYPE_FLOAT:
			continue
		total_value += item
	return total_value


## Returns the distance between 2 numbers. Typed as float.
static func distancef(n_1: float, n_2: float) -> float:
	return absf(n_1 - n_2)


## Returns the distance between 2 numbers. Typed as integer.
static func distancei(n_1: float, n_2: float) -> int:
	var sum: float = n_1 - n_2
	return absi(sum)


## Returns true if [param value] is between 2 numbers.
static func is_in_range(what: float, range_a: float, range_b: float) -> bool:
	var small: float = minf(range_a, range_b)
	var large: float = maxf(range_a, range_b)
	
	return small <= what and what <= large


## [method @GlobalScope.signf] but returns the value as an integer.
static func signfi(x: float) -> int:
	return int(signf(x))


## Sets the bit on the index [param bit_index] of the [param on] value
## to [param value].
static func set_bit(on: int, bit_index: int, value: bool) -> int:
	bit_index = clampi(bit_index, 0, 63)
	
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
	bit_index = clampi(bit_index, 0, 63)
	
	var bit_on: bool = (on & (1 << bit_index))
	
	if enabled:
		return bit_on
	else:
		return not bit_on


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
class BitFlags extends RefCounted:
	var _bit_store: int = 0
	var _flag_data: Dictionary = {}
	
	
	## Creates a flag with [param flag_id]. Returns [code]true[/code]
	## if the flag was created.
	func create_flag(flag_id: String) -> bool:
		if is_full():
			return false
		
		var used_indexes: Array[int] = Array(_flag_data.values(), TYPE_INT, &"", null)
		used_indexes.sort()
		
		for bit_idx in range(64):
			if Arrays.binary_search(used_indexes, bit_idx) == -1:
				_flag_data[flag_id] = bit_idx
				break
		
		return true
	
	
	## Sets [param flag_id] to be the bit index [param flag_index].[br]
	## [param flag_index] can only be a value between 0 and 63.[br]
	func assign_flag(flag_index: int, flag_id: String) -> void:
		flag_index = clampi(flag_index, 0, 63)
		_flag_data[flag_id] = flag_index
	
	
	## Removes flag_id from the registry.
	func release_flag(flag_id: String) -> void:
		if _flag_data.has(flag_id):
			_bit_store = Math.set_bit(
					_bit_store,
					_flag_data[flag_id],
					false)
			_flag_data.erase(flag_id)
	
	
	## Returns [code]true[/code] if [param flag_id] is registered.
	func is_assigned(flag_id: String) -> bool:
		return _flag_data.has(flag_id)
	
	
	## Return the bit index of the flag assigned to [param flag_id].
	## If the flag doesn't exist it'll return [code]-1[/code].
	func get_assigned_index(flag_id: String) -> int:
		if _flag_data.has(flag_id):
			return _flag_data[flag_id]
		return -1
	
	
	## Returns [code]true[/code] if the [param index] isn't assigned
	## to any id.
	func is_index_free(index: int) -> bool:
		return !( _flag_data.values().has(index) )
	
	
	## Returns an array of all the flags registered.
	func get_flags() -> Array[String]:
		return Array(_flag_data.keys(), TYPE_STRING, &"", null)
	
	
	## Returns [code]true[/code] if all 64 flags are assigned.
	func is_full() -> bool:
		return 64 <= _flag_data.size()
	
	
	## Sets the flag assigned to [param flag_id] to [param value].
	func set_flag(flag_id: String, value: bool) -> void:
		if not _flag_data.has(flag_id):
			return
		
		if value:
			_bit_store |= 1 << _flag_data[flag_id]
		else:
			_bit_store ^= 1 << _flag_data[flag_id]
	
	
	## Sets an array of [param flags] to value. If a flag is
	## missing it won't be set.
	func set_flags(flags: Array[String], value: bool) -> void:
		var add_flags: int = 0
		
		for flag in flags:
			if _flag_data.has(flag):
				add_flags = Math.set_bit(add_flags, _flag_data[flag], value)
		
		_bit_store = Math.or_bits(_bit_store, add_flags)
	
	
	## Returns true if [param flag] is set to [param value].
	func is_flag(flag: String, value: bool) -> bool:
		if not _flag_data.has(flag):
			return false
		
		return Math.is_bit(_bit_store, _flag_data[flag], value)
	
	
	## Returns true if all all the [param flags] match [param value].
	func are_flags(flags: Array[String], value: bool) -> bool:
		if not _flag_data.has_all(flags):
			return false
		
		var mask: int = 0
		
		for flag in flags:
			mask = Math.set_bit(mask, _flag_data[flag], true)
		
		return Math.are_bits(_bit_store, mask, value)
	
	
	## Clears all the set flags.
	func clear_flags() -> void:
		_bit_store = 0
