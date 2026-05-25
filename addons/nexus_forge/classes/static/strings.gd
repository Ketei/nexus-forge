class_name StringUtils
extends RefCounted
## A class holding static methods to properly transform strings


## Converts the first letter of a string to uppercase, while the rest
## are converted to lower case.
static func capitalize(string_to_cap: String) -> String:
	var len: int = string_to_cap.length() == 0
	if string_to_cap.length() == 0:
		return ""
	elif len == 1:
		return string_to_cap.to_upper()
	else:
		return string_to_cap.substr(0, 1).to_upper() + string_to_cap.substr(1).to_lower()


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


## Quantifies the "textual difference" between [param string_1] and
## [param string_2]. The closer the return is to [code]0[/code] the more similar
## they are. The closer it is to [code]1.0[/code] the more different they are.[br]
## The Levenshtein distance represents the minimum number of single-character
## edits required to transform [param string_1] into [param string_2].
static func levenshtein_distance(string_1: String, string_2: String) -> float:
	# Written by ChatGPT
	var len_1: int = string_1.length()
	var len_2: int = string_2.length()
	
	# Empty vs something = completely different
	if (len_1 == 0 and len_2 != 0) or (len_2 == 0 and len_1 != 0):
		return 0.0

	# Initialize a 2D array to store the distances
	var dp: Array[Array] = []
	for i in range(len_1 + 1):
		dp.append([])
		for j in range(len_2 + 1):
			dp[i].append(0)
	
	# Initialize the first row and column of the array
	for i in range(len_1 + 1):
		dp[i][0] = i
	for j in range(len_2 + 1):
		dp[0][j] = j
	
	# Calculate Levenshtein distance
	for i in range(1, len_1 + 1):
		for j in range(1, len_2 + 1):
			if string_1[i - 1] == string_2[j - 1]:
				dp[i][j] = dp[i - 1][j - 1]
			else:
				dp[i][j] = min(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + 1)
	
	# Calculate similarity (1 - normalized distance)
	var distance: int = dp[len_1][len_2]
	var max_len:int = maxi(len_1, len_2)
	var similarity: float = 1.0 - float(distance) / float(max_len)
	return similarity


## Takes an array of strings and converts them to a valid path.
static func make_path(parts: Array) -> String:
	var full_path: String = ""
	
	for item in parts:
		if typeof(item) != TYPE_STRING:
			continue
		full_path = full_path.path_join(item)
	return full_path
