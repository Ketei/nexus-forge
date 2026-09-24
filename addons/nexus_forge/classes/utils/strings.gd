class_name NFStringUtils
extends RefCounted
## A class holding static methods to properly transform strings


## Converts the first letter of a string to uppercase, while the rest
## are converted to lower case.
static func capitalize(string_to_cap: String) -> String:
	if string_to_cap.is_empty():
		return ""
	elif string_to_cap.length() == 1:
		return string_to_cap.to_upper()
	else:
		return string_to_cap.left(1).to_upper() + string_to_cap.substr(1).to_lower()


## Converts the first and every other letter after a space to uppercase
## the rest are lowercased
static func title_case(string_to_title: String) -> String:
	var return_string: String = ""
	var title_parts: PackedStringArray = string_to_title.split(" ", false)
	
	if title_parts.is_empty():
		return return_string
	
	for piece in title_parts:
		return_string += capitalize(piece) + " "
	
	return return_string.trim_suffix(" ")


## Returns true if param string is between the [param prefix] and [param suffix].
static func is_between(string: String, prefix: String, suffix: String) -> bool:
	return string.begins_with(prefix) and string.ends_with(suffix)


## Splits [param string] using the given [param delimeter]. Performs
## [method String.strip_edges] on the results.
static func split_and_strip(string: String, delimeter: String, allow_empty: bool = true, max_split: int = 0) -> PackedStringArray:
	var split_pie: PackedStringArray = []
	for part in string.split(delimeter, allow_empty, max_split):
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


## Takes param value and returns a string of the same value but with commas[br]
## Example: 123456789 -> "123,456,789"
static func beautify_int(value: int) -> String:
	var formatted_number: String = str(value) # Convert the number to a string
	var count: int = 0
	var result: String = ""

	for char_idx in range(len(formatted_number) - 1, -1, -1): # Iterate backwards through the string
		result = formatted_number[char_idx] + result
		count += 1
		if count % 3 == 0 and char_idx != 0:
			result = "," + result # Add a comma every three digits

	return result


## Quantifies the textual similarity between [param string_1] and
## [param string_2]. The closer the return is to [code]1.0[/code] the more similar
## they are. The closer it is to [code]0.0[/code] the more different they are.[br]
## This calculates the Levenshtein distance using an O(N) memory optimization.
static func levenshtein_similarity(string_1: String, string_2: String) -> float:
	var len_1: int = string_1.length()
	var len_2: int = string_2.length()
	
	if len_1 == 0 and len_2 == 0:
		return 1.0 # Both empty means they are identical
	if len_1 == 0 or len_2 == 0:
		return 0.0 # One empty means completely different
	
	if len_1 < len_2:
		var temp_str: String = string_1
		string_1 = string_2
		string_2 = temp_str
		
		var temp_len: int = len_1
		len_1 = len_2
		len_2 = temp_len
	
	var v0: Array[int] = []
	var v1: Array[int] = []
	v0.resize(len_2 + 1)
	v1.resize(len_2 + 1)
	
	for j in range(len_2 + 1):
		v0[j] = j
	
	# Calculate distance
	for i in range(len_1):
		v1[0] = i + 1
		var c1: String = string_1[i]
		for j in range(len_2):
			var cost: int = 0 if c1 == string_2[j] else 1
			v1[j + 1] = mini(v1[j] + 1, mini(v0[j + 1] + 1, v0[j] + cost))
		
		var temp: Array[int] = v0
		v0 = v1
		v1 = temp
	
	var distance: int = v0[len_2]
	var max_len: int = len_1
	
	# Return as a similarity percentage (1.0 = identical, 0.0 = completely different)
	return 1.0 - (float(distance) / float(max_len))


## Takes an array of strings and converts them to a valid path.
static func make_path(parts: Array) -> String:
	var full_path: String = ""
	
	for item in parts:
		if typeof(item) != TYPE_STRING or item.is_empty():
			continue
		full_path = full_path.path_join(item)
	return full_path


## Gets the integer at the end of a string. Returns it as a dictionary with
## 2 keys:[br]
## [code]has_integer[/code] contains a boolean representing if the string
## had an integer.[br]
## [code]integer[/code] is the integer that was found. If not found it'll be zero.
static func get_trailing_integer(text: String) -> Dictionary[String, Variant]:
	var clean_text: String = text.strip_edges()
	var data: Dictionary[String, Variant] = {"has_integer": false, "integer": 0}
	
	if clean_text.is_empty():
		return data
	
	var regex = RegEx.new()
	
	regex.compile("\\d+$") 
	
	var match_result:RegExMatch = regex.search(text)
	
	if match_result != null:
		data["has_integer"] = true
		data["integer"] = match_result.get_string().to_int()
	
	return data


## Returns an array of all items that could be formatted by [method String.format]
static func get_all_format_arguments(text: String, trim_brackets: bool = false, strip_edges: bool = false) -> Array[String]:
	var all_formats: Array[String] = []
	if text.is_empty():
		return all_formats
	
	var entries_found: Dictionary[String, Variant] = {}
	var rgx: RegEx = RegEx.new()
	rgx.compile("\\{([^\\}]+)\\}")
	
	for entry in rgx.search_all(text):
		var hit: String = entry.get_string()
		if trim_brackets:
			hit = hit.trim_prefix("{").trim_suffix("}")
			if strip_edges:
				hit = hit.strip_edges()
		entries_found[hit] = null
	
	all_formats.assign(entries_found.keys())
	return all_formats
