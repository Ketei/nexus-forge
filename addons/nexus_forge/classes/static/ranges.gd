class_name Ranges
extends Node
## A collection of static functions to move values within a given range.


## A int typed version of the move_toward
static func move_towardi(from: float, to: float, by: float) -> int:
	return int(move_toward(from, to, by))


static func is_between(value: float, a: float, b: float) -> bool:
	var min_val: float = minf(a, b)
	var max_val: float = maxf(a, b)
	
	return min_val <= value and value <= max_val
