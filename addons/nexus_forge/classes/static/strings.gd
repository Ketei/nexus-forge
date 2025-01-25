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


static func begins_with_nocasecmp(what: String, begins_with: String) -> bool:
	return what.to_upper().begins_with(begins_with.to_upper())


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


# Random string based on time. Less probability of collission
static func random_string64() -> String:
	var random_array: PackedByteArray = var_to_bytes(Time.get_unix_time_from_system())
	for _a in range(36): # Each 3 adds 4 more characters
		random_array.append(randi() & 0xFF)
	
	return Marshalls.raw_to_base64(random_array).replace("+", "-").replace("/", "_")


static func random_string(num_chars: int) -> String:
	var byte_array := PackedByteArray()
	
	for _a in range(num_chars):
		byte_array.append(randi() & 0xFF)
	
	return (Marshalls.raw_to_base64(byte_array)
		.replace("+", "-")
		.replace("/", "_")
		.replace("=", "")
		.substr(0, num_chars))
