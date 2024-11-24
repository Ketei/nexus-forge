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


static func nocasecmp_equal(string_a: String, string_b: String) -> bool:
	return string_a.to_upper() == string_b.to_upper()


static func random_string(length: int, slice: int) -> String:
	const RANDOM_UNICODE: Array[int] = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122] 
	var unicode_items: Array[int] = []
	
	for _ignore in range(length):
		unicode_items.append(RANDOM_UNICODE.pick_random())
	
	if 0 < slice:
		var unicode_groups: Array[String] = []
		
		for item_index in range(0, unicode_items.size(), slice):
			var pair = unicode_items.slice(item_index, item_index + slice)
			var u_slice: String = ""
			for uchar in pair:
				u_slice += char(uchar)
			unicode_groups.append(u_slice)
		
		return "-".join(unicode_groups)
	else:
		var full_string: String = ""
		for uchar in unicode_items:
			full_string += char(uchar)
		return full_string
