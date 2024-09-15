class_name Math
extends Node


static func get_actor_jump_velocity(jump_height: float, time_to_peak: float) -> float:
	var jump_vel: float = (2.0 * jump_height) / time_to_peak
	return jump_vel


static func get_actor_jump_gravity(jump_height: float, time_to_peak: float) -> float:
	var jump_grav: float = (-2.0 * jump_height) / pow(time_to_peak, 2)
	return jump_grav


static func get_actor_fall_gravity(jump_height: float, time_to_descent: float) -> float:
	var fall_grav: float = (-2.0 * jump_height) / pow(time_to_descent, 2)
	return fall_grav


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
static func polarity_comparison(n_1: float, n_2: float) -> bool:
	if n_1 == 0 or n_2 == 0:
		return true
	return xnor(n_1 < 0, n_2 < 0)


## Takes 2 numbers and returns the one closest to 0
static func closest_to_zero(numb_a: float, numb_b: float) -> float:
	if absf(numb_a) < absf(numb_b):
		return numb_a
	return numb_b


static func sum_array(values_array: Array) -> float:
	var total_value: float = 0
	for item in values_array:
		if item is not int and item is not float:
			continue
		total_value += item
	return total_value


static func distancef(n_1: float, n_2: float) -> float:
	return absf(n_1 - n_2)


static func distancei(n_1: float, n_2: float) -> int:
	return absi(int(n_1) - int(n_2))
