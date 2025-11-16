@icon("res://addons/nexus_forge/classes/resources/range_float.gd")
class_name RangeFloat
extends ValueRange


## The minimum value this range can hold.
@export var min_value: int = 0:
	set(new_min):
		min_value = new_min
		if max_value < new_min:
			max_value = new_min
		_fix_value()
## The maximum value this range can hold.
@export var max_value: int = 0:
	set(new_max):
		if new_max < min_value:
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
@export var allow_greater: bool = false
## If value can go below [member min_value].
@export var allow_lesser: bool = false


func _fix_value() -> void:
	if value < min_value:
		if allow_lesser == false:
			value = min_value
	elif max_value < value:
		if allow_greater == false:
			value = max_value


func range_type() -> int:
	return TYPE_FLOAT
