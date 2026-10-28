class_name NFStringUtils
extends RefCounted
## A class holding static methods to properly transform strings

static var _LANG_CODES: Array[String] = []
static var _COUNTRY_CODES: Array[String] = []
static var _SCRIPT_CODES: Array[String] = []


static func _populate_locale_dicts() -> void:
	if not _LANG_CODES.is_read_only():
		_LANG_CODES.clear()
		_LANG_CODES.assign(TranslationServer.get_all_languages())
	
	if not _COUNTRY_CODES.is_read_only():
		_COUNTRY_CODES.clear()
		_COUNTRY_CODES.assign(TranslationServer.get_all_countries())
	
	if not _SCRIPT_CODES.is_read_only():
		_SCRIPT_CODES.clear()
		_SCRIPT_CODES.assign(TranslationServer.get_all_scripts())
	
	if not _LANG_CODES.is_empty():
		_LANG_CODES.sort()
		_LANG_CODES.make_read_only()
	
	if not _COUNTRY_CODES.is_empty():
		_COUNTRY_CODES.sort()
		_COUNTRY_CODES.make_read_only()
	
	if not _SCRIPT_CODES.is_empty():
		_SCRIPT_CODES.sort()
		_SCRIPT_CODES.make_read_only()


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
	
	if clean_string.is_valid_int():
		return clean_string.to_int()
	elif clean_string.is_valid_float():
		return clean_string.to_float()
	elif clean_string == "true":
		return true
	elif clean_string == "false":
		return false
	else:
		return string


## Takes param value and returns a string of the same value but with commas[br]
## Example: 123456789 -> "123,456,789"
static func beautify_int(value: int) -> String:
	var formatted_number: String = str(value)
	var is_negative: bool = value < 0
	
	if is_negative:
		formatted_number = formatted_number.substr(1)
	
	var count: int = 0
	var result: String = ""
	
	for char_idx in range(len(formatted_number) - 1, -1, -1): # Iterate backwards through the string
		result = formatted_number[char_idx] + result
		count += 1
		if count % 3 == 0 and char_idx != 0:
			result = "," + result # Add a comma every three digits
	
	if is_negative:
		result = "-" + result
	
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
		var type: int = typeof(item)
		if (type != TYPE_STRING and type != TYPE_STRING_NAME) or item.is_empty():
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
	
	var match_result:RegExMatch = regex.search(clean_text)
	
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


## Takes [param locale_string] and santizes and standarizes the output.[br]
## If [param strict] is [code]false[/code], it'll construct a valid locale
## with what it can.
## Otherwise all the parts of the code must be valid or it'll return an empty
## string.
## [codeblock]
## print(NFStringUtils.sanitize_locale("En_Invl-XX", false)) # Will print "en"
## print(NFStringUtils.sanitize_locale("En-Invl-US", false)) # Will print "en_US"
## print(NFStringUtils.sanitize_locale("en-Invl_US")) # Will print ""
## [/codeblock]
static func sanitize_locale(locale_string: String, strict: bool = true) -> String:
	if _LANG_CODES.is_empty():
		_populate_locale_dicts()
	
	var clean_string: String = locale_string.strip_edges()
	if clean_string.is_empty():
		return ""
	var normalized: String = clean_string.replace("-", "_")
	var parts: PackedStringArray = normalized.split("_")
	var part_size: int = parts.size()
	
	var lang: String = ""
	var scr: String = ""
	var cnt: String = ""
	
	if 0 < part_size:
		lang = parts[0].to_lower()
	if 1 < part_size:
		var code_slice: String = parts[1]
		if code_slice.length() == 4: # It could be a script tag.
			scr = capitalize(code_slice)
		else:
			cnt = code_slice.to_upper()
	if 2 < part_size:
		cnt = parts[2].to_upper()
	
	
	if lang.is_empty():
		return ""
	else:
		var lang_index: int = _LANG_CODES.bsearch(lang)
		if _LANG_CODES.size() <= lang_index or _LANG_CODES[lang_index] != lang:
			return ""
	
	var structured_code: String = lang
	
	if not scr.is_empty():
		var scr_index: int = _SCRIPT_CODES.bsearch(scr)
		if scr_index < _SCRIPT_CODES.size() and _SCRIPT_CODES[scr_index] == scr:
			structured_code += "_" + scr
		elif strict:
			return ""
	
	if not cnt.is_empty():
		var cnt_index: int = _COUNTRY_CODES.bsearch(cnt)
		if cnt_index < _COUNTRY_CODES.size() and _COUNTRY_CODES[cnt_index] == cnt:
			structured_code += "_" + cnt
		elif strict:
			return ""
	
	return TranslationServer.standardize_locale(structured_code)


static func get_locale_language(code: String) -> String:
	code = sanitize_locale(code, false)
	if code.is_empty():
		return ""
	return code.get_slice("_", 0).to_lower()


static func get_locale_country(code: String) -> String:
	code = sanitize_locale(code, false)
	var slice_count: int = code.get_slice_count("_")
	if slice_count < 2:
		return ""
	
	var candidate: String = code.get_slice("_", 1)
	if candidate.length() == 4:
		if 1 < slice_count:
			candidate = code.get_slice("_", 2)
		else:
			candidate = ""
	return candidate.to_upper()
