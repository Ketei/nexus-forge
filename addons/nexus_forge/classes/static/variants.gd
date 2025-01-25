class_name Variants
extends Node


static func is_same_type(var_a: Variant, var_b: Variant) -> bool:
	return typeof(var_a) == typeof(var_b)


static func is_comparable(var_a: Variant, var_b: Variant) -> bool:
	if typeof(var_a) == TYPE_INT or typeof(var_a) == TYPE_FLOAT:
		if typeof(var_b) == TYPE_INT or typeof(var_b) == TYPE_FLOAT:
			return true
	
	return is_same_type(var_a, var_b)
