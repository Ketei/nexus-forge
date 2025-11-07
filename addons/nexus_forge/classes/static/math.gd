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
