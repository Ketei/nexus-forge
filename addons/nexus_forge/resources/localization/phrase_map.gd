@tool
@icon("res://addons/nexus_forge/icons/brackets_speech.svg")
class_name NFPhraseMap
extends Resource
## A resource to hold localized argument-based strings.
##
## An argument based string is a string that will change its content based
## on existing data. It can be provided through methods in the [NFPhraseAPI] class
## by using prefix [code]![/code]; Or by pointing to a [Blackboard] variable
## with prefix [code]$[/code]. Non-access arguments can also be defined by not 
## using [code]$[/code] or [code]![/code] inside the brackets.[br][br]
## Text example: [code]"Here is a {!method} as argument. And here is one that accesses
## the variable {$folder/variable} in the blackboard. And {this} needs to be
## passed as override through get_text."[/code]

## The locale code this map is in.
@export var locale: String = ""

@export_storage var _phrases: Dictionary[StringName, Dictionary] = {}

# Not exported as these are generated on-demand. Stored in case of being
# needed again.
var _value_keys: Dictionary[StringName, Dictionary] = {}


## Returns an array containing all the formattable strings that are contained
## between curly braces. Curly braces are removed.
static func get_valid_formats(phrase_text: String) -> Array[String]:
	var all_args: Array[String] = []
	
	var regex_search: RegEx = RegEx.new()
	
	regex_search.compile("\\{[^\\s\\}]+\\}")
	
	for regex_match in regex_search.search_all(phrase_text): # $variable
		var text: String = regex_match.get_string().trim_prefix("{").trim_suffix("}")
		if all_args.has(text):
			continue
		all_args.append(text)
	
	return all_args


func _build_callable_for_variable(text: String) -> Callable:
	var clean_text: String = text.trim_prefix("$")
	var callable: Callable = Callable(
			NexusForge.Blackboard.get_variable.bind(
					clean_text, ""))
	
	return callable


func _build_callable_for_method(text: String) -> Callable:
	var parts: PackedStringArray = text.split("|", false, 1)
	var method: StringName = StringName(parts[0].trim_prefix("!"))
	var arguments: PackedStringArray = []
	if 1 < parts.size():
		arguments = parts[1].split(",")
	
	var final_arguments: Array = []
	
	for argument in arguments:
		if argument.begins_with("$"):
			final_arguments.append(_build_callable_for_variable(argument.trim_prefix("$")))
		elif argument.begins_with("!"):
			final_arguments.append(_build_callable_for_method(argument.trim_prefix("!")))
		else:
			final_arguments.append(argument)
	
	var callable: Callable = Callable(NexusForge.Discourse.API, method)
	
	if not final_arguments.is_empty():
		return _build_lazy_wrapper.bind(callable, final_arguments)
	
	return callable


func _build_lazy_wrapper(target_method: Callable, args: Array) -> Variant:
	var resolved_args: Array = []
	for arg in args:
		if arg is Callable:
			resolved_args.append(arg.call())
		else:
			resolved_args.append(arg)
	return target_method.callv(resolved_args)



func _generate_callables(dialog_id: StringName) -> void:
	var dialog: String = _phrases[dialog_id]["text"]
	
	if not _value_keys.has(dialog_id):
		_value_keys[dialog_id] = NFDictUtils.create_typed(TYPE_STRING, TYPE_CALLABLE)
	
	if dialog.is_empty():
		return
	
	var tokens_processed: Dictionary[String, Variant] = {}
	
	var phrase_regex: RegEx = RegEx.new()
	phrase_regex.compile("\\{([\\!\\$][^\\s\\}]+)\\}")
	
	for rgx_result in phrase_regex.search_all(dialog):
		var format: String = rgx_result.get_string(1)
		var token: String = format.substr(0, 1)
		
		if token == "!":
			if tokens_processed.has(rgx_result.get_string()):
				continue
			
			tokens_processed[rgx_result.get_string()] = null
			
			if not _value_keys.has(format):
				_value_keys[format] = {}
			
			_value_keys[dialog_id][format] = _build_callable_for_method(
					format.substr(1))
		elif token == "$":
			
			_value_keys[dialog_id][format] = _build_callable_for_variable(
					format.substr(1))


func _find_case(phrase: StringName, format: String, case: String) -> Dictionary[String, String]:
	var result: Dictionary[String, String] = {
		"case": case,
		"value": ""}
	
	var phrase_dict: Variant = _phrases.get(phrase)
	if typeof(phrase_dict) != TYPE_DICTIONARY:
		return result
	
	var formats_dict: Variant = phrase_dict.get("formats")
	if typeof(formats_dict) != TYPE_DICTIONARY:
		return result
	
	var p_format_dict: Variant = formats_dict.get(format)
	if typeof(p_format_dict) != TYPE_DICTIONARY:
		return result
	
	var cases_dict: Variant = p_format_dict.get("cases")
	if typeof(cases_dict) == TYPE_DICTIONARY:
		var case_result: Variant = cases_dict.get(case)
		if typeof(case_result) == TYPE_STRING:
			result["value"] = case_result
			return result
	
	var def_val: Variant = p_format_dict.get("default")
	if typeof(def_val) == TYPE_STRING:
		result["value"] = def_val
	
	return result


func _find_case_callable(phrase: StringName, on_argument: String, method: Callable) -> Dictionary[String, String]:
	var case: String = str(method.call())
	var result: Dictionary[String, String] = {
		"case": case,
		"value": ""}
	
	var phrase_dict: Variant = _phrases.get(phrase)
	if typeof(phrase_dict) != TYPE_DICTIONARY:
		return result
	
	var formats_dict: Variant = phrase_dict.get("formats")
	if typeof(formats_dict) != TYPE_DICTIONARY:
		return result
	
	var argument_dict: Variant = formats_dict.get(on_argument)
	if typeof(argument_dict) != TYPE_DICTIONARY:
		return result
	
	var cases_dict: Variant = argument_dict.get("cases")
	if typeof(cases_dict) == TYPE_DICTIONARY:
		var case_val: Variant = cases_dict.get(case)
		if typeof(case_val) == TYPE_STRING:
			result["value"] = case_val
			return result
		
	var default_val: Variant = argument_dict.get("default")
	if typeof(default_val) == TYPE_STRING:
		result["value"] = default_val
		
	return result


## Returns an array containing all the registered phrase keys.
func entries() -> Array[StringName]:
	var arr: Array[StringName] = []
	arr.assign(_phrases.keys())
	return arr


## Sets the phrase's [param key] text to [param text].
func set_entry(key: StringName, text: String) -> void:
	var formats: Dictionary[String, Dictionary] = {}
	
	var existing_formats: Dictionary = {}
	var phrase_dict: Variant = _phrases.get(key)
	if typeof(phrase_dict) == TYPE_DICTIONARY:
		var formats_dict: Variant = phrase_dict.get("formats")
		if typeof(formats_dict) == TYPE_DICTIONARY:
			existing_formats = formats_dict
	
	for format in get_valid_formats(text):
		var default: String = ""
		var cases: Dictionary[String, String] = {}
		
		var existing_format_data: Variant = existing_formats.get(format)
		if typeof(existing_format_data) == TYPE_DICTIONARY:
			var old_default: Variant = existing_format_data.get("default")
			if typeof(old_default) == TYPE_STRING:
				default = old_default
				
			var old_cases: Variant = existing_format_data.get("cases")
			if typeof(old_cases) == TYPE_DICTIONARY:
				cases.assign(old_cases)
		
		var format_entry: Dictionary[String, Variant] = {
			"default": default,
			"cases": cases}
		formats[format] = format_entry
	
	var phrase_entry: Dictionary[String, Variant] = {
		"text": text,
		"formats": formats}
	_phrases[key] = phrase_entry


## Returns the text that the phrase [param key] is set to or an empty
## string if the phrase doesn't exist.
func get_entry(key: StringName) -> String:
	var key_phrase: Dictionary = _phrases.get(key, {})
	return key_phrase.get("text", "")


## Returns an array of al the formattable arguments from the passed
## [param key].
func get_formats(key: StringName) -> Array[String]:
	var formats: Array[String] = []
	if _phrases.has(key):
		formats.assign(_phrases[key]["formats"].keys())
	return formats


## Returns true if [param phrase_key] exists in this map.
func has_entry(key: StringName):
	return _phrases.has(key)


## Erases the formattable phrase with the given [param phrase_key].
func erase_entry(key: StringName) -> void:
	if _phrases.erase(key):
		_value_keys.erase(key)


## Returns true if [param key] has a format [param format].
func has_format(key: StringName, format: String) -> bool:
	if not _phrases.has(key):
		return false
	
	return _phrases[key]["formats"].has(format)


## Returns the phrase [param phrase_key] default case for argument [param on_argument]
## or an empty string if the argument doesn't exist.
func get_case_default(key: StringName, format: String) -> String:
	var key_dict: Variant = _phrases.get(key)
	if key_dict == null:
		return ""
	
	var entry_format: Variant = key_dict["formats"].get(format)
	if typeof(entry_format) != TYPE_DICTIONARY:
		return ""
	
	return entry_format.get("default", "")


## Sets the case on the phrase [param key] of the argument [param on_argument]
## to [param value].
func set_case(key: StringName, format: String, case: String, value: String) -> void:
	if not _phrases.has(key):
		return
	
	var formats_dict: Dictionary = _phrases[key]["formats"]
	var cases_dict: Dictionary[String, String] = {}
	
	if formats_dict.has(format):
		var case_entry: Variant = formats_dict.get("cases")
		if typeof(case_entry) != TYPE_DICTIONARY:
			var new_cases: Dictionary[String, String] = {}
			formats_dict["cases"] = new_cases
			cases_dict = new_cases
		else:
			cases_dict = case_entry
	else:
		var new_cases: Dictionary[String, String] = {}
		var new_format: Dictionary[String, Variant] = {
			"default": "",
			"cases": new_cases}
		formats_dict[format] = new_format
		cases_dict = new_cases
	
	cases_dict[case] = value


## Removes the [param case] from the [param format] of the phrase with the
## given [param key].
func remove_case(key: StringName, format: String, case: String) -> void:
	if not _phrases.has(key):
		return
	
	var formats_dict: Dictionary = _phrases[key]["formats"]
	
	var format_entry: Variant = formats_dict.get(format)
	if typeof(format_entry) != TYPE_DICTIONARY:
		return
	format_entry["cases"].erase(case)


## Sets the default case on the phrase [param key] of the argument
## [param on_argument] to [param default].
func set_case_default(key: StringName, format: String, default: String) -> void:
	if not _phrases.has(key):
		return
	
	var formats_dict: Dictionary = _phrases[key]["formats"]
	var target_dict: Dictionary = {}
	if formats_dict.has(format):
		target_dict = formats_dict[format]
	else:
		var new_format_entry: Dictionary[String, Variant] = {
			"default": "",
			"cases": NFDictUtils.create_typed(TYPE_STRING, TYPE_STRING)}
		
		formats_dict[format] = new_format_entry
		target_dict = new_format_entry
	
	target_dict["default"] = default


## Clears the custom cases of the [param format] from the phrase
## with [param key].
func clear_cases(key: StringName, format: String) -> void:
	if not _phrases.has(key):
		return
	
	var formats_dict: Dictionary = _phrases[key]["formats"]
	var entry_dict: Variant = formats_dict.get(format)
	if typeof(entry_dict) == TYPE_DICTIONARY:
		entry_dict["cases"].clear()


## Returns the case from the phrase [param key] of the [param format]
## or an empty string if the case doesn't exist.
func get_case(key: StringName, format: String, case: String) -> String:
	if not _phrases.has(key):
		return ""
	
	var formats_dict: Dictionary = _phrases[key]["formats"]
	var format_entry: Variant = formats_dict.get(format)
	if typeof(format_entry) == TYPE_DICTIONARY:
		return format_entry["cases"].get(case, "")
	else:
		return ""


## Returns true if the [param case] exists on the [param format] in
## the phrase [param key].
func has_case(key: StringName, format: String, case: String) -> bool:
	if not _phrases.has(key):
		return false
	
	var phrase_formats: Dictionary = _phrases[key]["formats"]
	var format_entry: Variant = phrase_formats.get(format)
	if typeof(format_entry) == TYPE_DICTIONARY:
		return format_entry["cases"].has(case)
	return false


## Returns the formatted text of phrase [param phrase_key]. Optionally you can pass
## [param override_values] that will be used instead of Blackboard or callable
## data (if applicable) to get the appropiate case for formatting the phrase's text.
func get_text(phrase_key: StringName, override_values: Dictionary[String, String] = {}) -> String:
	if not _phrases.has(phrase_key):
		return ""
	
	# Will be working with text "Let's see: {$inventory/is_full}{$inventory/count}"
	var format_dict: Dictionary[String, String] = {}
	
	if not _value_keys.has(phrase_key):
		_generate_callables(phrase_key)
	
	var formats: Dictionary[String, String] = {}
	var values: Dictionary[String, String] = {}
	
	for format_key in _phrases[phrase_key]["formats"]:
		# format_key = $inventory/is_full
		
		var case_result: Dictionary[String, String] = {}
		
		if override_values.has(format_key):
			case_result.assign(
					_find_case(
							phrase_key,
							format_key,
							override_values[format_key]))
		elif _value_keys.has(phrase_key) and _value_keys[phrase_key].has(format_key):
			case_result.assign(
					_find_case_callable(
							phrase_key,
							format_key,
							_value_keys[phrase_key][format_key]))
		else:
			case_result["case"] = ""
			case_result["value"] = _phrases[phrase_key]["formats"][format_key]["default"]

		# case_result = { "case": "false", "value": "Inventory {$inventory/count} / 50" }
		
		formats[format_key] = case_result["value"]
		# formats["$inventory/is_full"] = "Inventory {$inventory/count} / 50"
		# formats["$inventory/count"] = ""
		values[format_key] = case_result["case"]
		# values["$inventory/is_full"] = "false"
		# values["$inventory/count"] = "13"
	
	for format in formats:
		format_dict[format] = formats[format].format(values)
		# format_dict["$inventory/is_full"] = "Inventory 13 / 50"
		# format_dict["$inventory/count"] = ""
	
	 #return "Let's see: {$inventory/is_full}{$inventory/count}".format({
		#"$inventory/is_full": "Inventory 13 / 50",
		#"$inventory/count": ""})
	# Turns into
	# return "Let's see: Inventory 13 / 50"
	return _phrases[phrase_key]["text"].format(format_dict)
