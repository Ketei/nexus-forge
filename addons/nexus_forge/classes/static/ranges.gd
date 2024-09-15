class_name Ranges
extends Node
## A collection of static functions to move values within a given range.


## A int typed version of the move_toward
static func move_towardi(from: float, to: float, by: float) -> int:
	return int(move_toward(from, to, by))
