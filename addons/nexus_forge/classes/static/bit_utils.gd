class_name BitUtils
extends RefCounted
## Provides a collection of helper functions for performing common bitwise
## operations on integers.
##
## A static class that takes integers, changes bits and returns the modified
## integer. It also contains functions to check the state of bits.


## Returns the bits using a mask.[br]
## Example: get_bits(10, 3) will return 2. This is because:[br]
## 10 = 0101 and 3 = 1100. This means it'll return the first 2 bits: 01
## Which has a value of 2
static func get_bits(from: int, mask: int) -> int:
	return from & mask


## Sets the bit on the index [param bit_index] of the [param on] value
## to [param value].
static func set_bit_index(on: int, bit_index: int, value: bool) -> int:
	if bit_index < 0 or 63 < bit_index:
		return 0
	
	if value:
		on |= 1 << bit_index
	else:
		on &= ~( 1 << bit_index )
	
	return on


## Turns the bits defined on [param mask] on the value [param on] to [param enabled]
static func set_bits(on: int, mask: int, enabled: bool) -> int:
	if enabled:
		return on | mask
	else:
		return on & ~mask


## Returns true if the bit of [param on] on index [param bit_index]
## is set to [param enabled].
static func is_bit_index(on: int, bit_index: int, enabled: bool) -> bool:
	if bit_index < 0 or 63 < bit_index:
		return false
	
	var bit_on: bool = (on & (1 << bit_index)) != 0
	
	return bit_on == enabled


## Will check if the enabled bits on [param mask] are [code]1[/code]
## on [param on] if enabled is [code]true[/code] or [code]0[/code]
## if enabled is [code]false[/code].
static func are_bits(on: int, mask: int, enabled: bool) -> bool:
	if enabled:
		return (on & mask) == mask
	else:
		return (on & mask) == 0
