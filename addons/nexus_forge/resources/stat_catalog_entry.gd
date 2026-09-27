class_name NFCatalogEntryStat
extends NFCatalogEntry
## A catalog entry specific for stats.


var max_value: float = 0.0:
	set(m):
		if NFBitUtils.is_bit_index(_flags, 63, false):
			max_value = maxf(min_value, m)
var min_value: float = 0.0:
	set(m):
		if NFBitUtils.is_bit_index(_flags, 63, true):
			return
		if max_value < m:
			max_value = m
		min_value = m

var allow_lesser: bool = true:
	set(a):
		if NFBitUtils.is_bit_index(_flags, 63, false):
			allow_lesser = a
var allow_greater: bool = true:
	set(a):
		if NFBitUtils.is_bit_index(_flags, 63, false):
			allow_greater = a

## The stat type this entry is.
var is_float: bool = true:
	set(f):
		if NFBitUtils.is_bit_index(_flags, 63, false):
			is_float = f


## Returns the [param value] clamped based on the configuration.
func get_clamped_value(value: float) -> float:
	# Neither bounds apply
	if allow_greater and allow_lesser:
		return value if is_float else floorf(value)
	
	elif allow_greater:
		return maxf(min_value, value) if is_float else floorf(maxf(min_value, value))
	
	elif allow_lesser:
		return minf(max_value, value) if is_float else floorf(minf(max_value, value))
	
	else:
		return clampf(value, min_value, max_value) if is_float else floorf(clampf(value, min_value, max_value))
