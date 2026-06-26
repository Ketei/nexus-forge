class_name RangeUtils
extends RefCounted
## A collection of static functions to move values within a given range.


## A int typed version of [@GlobalScope.move_toward].
static func move_towardi(from: float, to: float, by: float) -> int:
	return int(move_toward(from, to, by))


## Returns true if [param value] exist between the range [param a] and [param b].[br]
## [param a] and [param b] [b]don't[/b] need to to passed in a specific order.
static func is_between(value: float, a: float, b: float) -> bool:
	if a < b:
		return a <= value and value <= b
	else:
		return b <= value and value <= a
