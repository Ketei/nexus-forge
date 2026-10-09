class_name NFMath
extends RefCounted
## Class to perform math operations in a more convenient way.

## The maximum positive value a 64-bit signed integer can hold in Godot
## [code](2^63 - 1)[/code].
const INT_MAX: int = 9223372036854775807
## The minimum negative value a 64-bit signed integer can hold in Godot
## [code](-2^63)[/code].
const INT_MIN: int = -9223372036854775808


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


## Sums all the numerical values inside an array and returns
## the result as an integer.
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


## Sums [param a] and [param b] without causing an integer overflow.
static func safe_sum(a: int, b: int) -> int:
	if 0 < a and 0 < b and INT_MAX - b < a:
		return INT_MAX
	
	if a < 0 and b < 0 and a < INT_MIN - b:
		return INT_MIN
	
	return a + b


## Multiplies [param a] and [param b] without causing an integer overflow.
static func safe_multiply(a: int, b: int) -> int:
	if a == 0 or b == 0:
		return 0
	
	var a_pos: bool = 0 < a
	var b_pos: bool = 0 < b
	
	if a_pos and b_pos:
		if INT_MAX / b < a:
			return INT_MAX
	
	elif a_pos and not b_pos:
		if b < INT_MIN / a:
			return INT_MIN
	
	elif not a_pos and b_pos:
		if a < INT_MIN / b:
			return INT_MIN
	
	else:
		if a < INT_MAX / b:
			return INT_MAX
	
	return a * b


## Divides [param a] by [param b] without causing an integer overflow.
static func safe_divide(a: int, b: int) -> int:
	# 1. Prevent division by zero (causes a runtime crash in Godot)
	if b == 0:
		NFPluginGameHandler._log_msg(
			"math",
			"Attempted to divide by 0",
			NFPluginGameHandler._LogLevel.ERROR)
		return 0
	
	if a == INT_MIN and b == -1:
		return INT_MAX
	
	return a / b


## Sums [param a] and [param b] and returns a result that's not bigger than
## [param maximum] nor smaller than [param minimum].
static func safe_sum_range(a: int, b: int, minimum: int, maximum: int) -> int:
	var real_max: int = maxi(minimum, maximum)
	
	var total_sum: int = safe_sum(a, b)
	
	return clampi(total_sum, minimum, real_max)


## Returns the Greatest Common Divisor (gdc) which is the largest
## positive integer that divides both [param a] and [param b].
## The returned value is always positive.
## [br][b]
## [br][b]Note:[/b] Safely handles [const NFMath.INT_MIN] edge cases 
## by clamping the result to [const NFMath.INT_MAX] to prevent overflow.
static func gcd(a: int, b: int) -> int:
	while b != 0:
		var temp: int = b
		b = a % b
		a = temp
	
	if a == INT_MIN:
		return INT_MAX
		
	return abs(a)
