class_name Strings
extends Node
## A class holding static methods to properly transform strings


## Converts the first letter of a string to uppercase, while the rest
## are converted to lower case.
static func capitalize(string_to_cap: String) -> String:
	return string_to_cap.left(1).to_upper() + string_to_cap.right(-1).to_lower()


## Converts the first and every other letter after a space to uppercase
## the rest are lowercased
static func title_case(string_to_title: String) -> String:
	var return_string: String = ""
	var title_parts: PackedStringArray = string_to_title.split(" ", false)
	
	if title_parts.is_empty():
		return return_string
	
	for piece in title_parts:
		return_string += Strings.capitalize(piece)
		if piece != title_parts[-1]:
			return_string += " "
	
	return return_string


static func is_between(string: String, prefix: String, suffix: String) -> bool:
	return string.begins_with(prefix) and string.ends_with(suffix)


## Same as the default slice function but you can use negative numbers to
## select backwards. -1 will return the last slice. If out of bounds it'll
## return an empty string.
static func get_slice_index(string: String, delimiter: String, index: int) -> String:
	var slices: PackedStringArray = string.split(delimiter, false)
	var size: int = slices.size()
	
	if index < -size - 1 or size < index:
		return ""
	return slices[index]


static func split_and_strip(string: String, delimeter: String) -> PackedStringArray:
	var split_pie: PackedStringArray = []
	for part in string.split(delimeter, false):
		split_pie.append(part.strip_edges())
	return split_pie


## A function that can turn a string to a float, an int or a bool. If no
## types match it'll return the string itself.
static func string_to_variant(string: String) -> Variant:
	var clean_string: String = string.to_lower().strip_edges()
	
	if clean_string.is_valid_float():
		if clean_string.contains("."):
			return clean_string.to_float()
		else:
			return clean_string.to_int()
	elif clean_string == "true":
		return true
	elif clean_string == "false":
		return false
	else:
		return string
