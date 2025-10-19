class_name Variants
extends Node


static func is_same_type(var_a: Variant, var_b: Variant) -> bool:
	return typeof(var_a) == typeof(var_b)


static func is_comparable(var_a: Variant, var_b: Variant) -> bool:
	var type_a: int = typeof(var_a)
	var type_b: int = typeof(var_b)
	
	if type_a == type_b:
		return true
	elif type_a == TYPE_INT or type_a == TYPE_FLOAT:
		return type_b == TYPE_INT or type_b == TYPE_FLOAT
	else:
		return false
