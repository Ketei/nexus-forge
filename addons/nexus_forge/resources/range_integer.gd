@icon("res://addons/nexus_forge/icons/range_int.svg")
class_name NFRangeInt
extends NFValueRange
## An object representing an integer numerical range.


## The minimum value this range can hold. Will push [member max_value] if
## it is larger than it.
@export var min_value: int = 0:
	set(new_min):
		min_value = new_min
		if max_value < new_min:
			max_value = new_min
		_fix_value()
## The maximum value this range can hold. Can't go below [member min_value].[br]
## To assign a range safely see [method NFRangeFloat.set_bounds].
@export var max_value: int = 0:
	set(new_max):
		if  new_max < min_value:
			new_max = min_value
		max_value = new_max
		_fix_value()
## The current value of this range.
@export var value: int = 0:
	set(v):
		if v < min_value:
			if allow_lesser == false:
				v = min_value
		elif max_value < v:
			if allow_greater == false:
				v = max_value
		value = v
@export_category("Options")
## If value can go above [member max_value].
@export var allow_greater: bool = true:
	set(a):
		allow_greater = a
		if not a:
			_fix_value()
## If value can go below [member min_value].
@export var allow_lesser: bool = true:
	set(a):
		allow_lesser = a
		if not a:
			_fix_value()


## Safely applies new range boundaries. [param new_min] will be used
## as the floor for [param new_max].
func set_bounds(new_min: int, new_max: int) -> void:
	var clamped_max = maxi(new_min, new_max)
	
	if max_value < new_min:
		max_value = clamped_max
		min_value = new_min
	else:
		min_value = new_min
		max_value = clamped_max


func _fix_value() -> void:
	if not allow_lesser and value < min_value:
		value = min_value
	if not allow_greater and max_value < value:
		value = max_value

## Returns [code]TYPE_INT[/code]
func range_type() -> int:
	return TYPE_INT
