@tool
@icon("res://addons/nexus_forge/icons/brackets_speech.svg")
class_name PhraseMap
extends Resource
## A resource to hold localized argument-based strings.
##
## An argument based string is a string that will change its content based
## on existing data. It can be provided through methods in the [PhraseAPI] class
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
		_value_keys[dialog_id] = DictUtils.create_typed(TYPE_STRING, TYPE_CALLABLE)
	
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
	var return_result: Dictionary[String, String] = {
		"case": case,
		"value": DictUtils.get_nested_value(
				_phrases,
				[phrase, "formats", format, "cases", case],
				DictUtils.get_nested_value(
						_phrases,
						[phrase, "formats", format, "default"],
						""))}
	
	return return_result


func _find_case_callable(phrase: StringName, on_argument: String, method: Callable) -> Dictionary[String, String]:
	var case: String = str(method.call())
	var return_result: Dictionary[String, String] = {
		"case": case,
		"value": DictUtils.get_nested_value(
				_phrases,
				[phrase, "formats", on_argument, "cases", case],
				DictUtils.get_nested_value(
						_phrases,
						[phrase, "formats", on_argument, "default"],
						""))}
	return return_result


## Returns an array containing all the registered phrase keys.
func entries() -> Array[StringName]:
	var arr: Array[StringName] = []
	arr.assign(_phrases.keys())
	return arr


## Sets the phrase's [param key] text to [param text].
func set_entry(key: StringName, text: String) -> void:
	var formats: Dictionary = {}
	for format in get_valid_formats(text):
		formats[format] = {
			"default": DictUtils.get_nested_value(_phrases, [key, "text"], ""),
			"cases": DictUtils.get_nested_value(_phrases, [key, "cases"], {})}
	
	_phrases[key] = {
		"text": text,
		"formats": formats}


## Returns the text that the phrase [param key] is set to or an empty
## string if the phrase doesn't exist.
func get_entry(key: StringName) -> String:
	return DictUtils.get_nested_value(
			_phrases,
			[key, "text"],
			"")


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
	return DictUtils.has_nested_path(
			_phrases,
			[key, "formats", format])


## Sets the phrase [param phrase_key] default case for argument [param on_argument]
## to [param default_value].
func set_format_default(key: StringName, format: String,  default: String) -> void:
	if not DictUtils.set_nested_value(
			_phrases,
			[key, "formats", format, "default"],
			default,
			false):
		_phrases[key]["formats"][format] = {
			"default": default,
			"cases": {}}


## Returns the phrase [param phrase_key] default case for argument [param on_argument]
## or an empty string if the argument doesn't exist.
func get_case_default(key: StringName, format: String) -> String:
	return DictUtils.get_nested_value(
			_phrases,
			[key, "formats", format, "default"],
			"")


## Sets the case on the phrase [param key] of the argument [param on_argument]
## to [param value].
func set_case(key: StringName, format: String, case: String, value: String) -> void:
	if not _phrases.has(key):
		return
	
	DictUtils.set_nested_value(
			_phrases,
			[key, "formats", format, "cases", case],
			value)


## Clears the custom cases of the [param format] from the phrase
## with [param key].
func clear_cases(key: StringName, format: String) -> void:
	if not DictUtils.has_nested_path(_phrases, [key, "formats", format, "cases"]):
		return
	_phrases[key]["formats"][format]["cases"].clear()


## Returns the case from the phrase [param key] of the [param format]
## or an empty string if the case doesn't exist.
func get_case(key: StringName, format: String, case: String) -> String:
	return DictUtils.get_nested_value(
			_phrases,
			[key, "formats", format, "cases", case],
			"")


## Returns true if the [param case] exists on the [param format] in
## the phrase [param key].
func has_case(key: StringName, format: String, case: String) -> bool:
	return DictUtils.has_nested_path(_phrases, [key, "formats", format, "cases", case])


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
	
	for format_key in _phrases[phrase_key]["formats"].keys():
		# format_key = $inventory/is_full
		
		var case_result: Dictionary[String, String] = {}
		
		if override_values.has(format_key):
			case_result.assign(
					_find_case(
							phrase_key,
							format_key,
							override_values[format_key]))
		elif DictUtils.has_nested_path(_value_keys, [phrase_key, format_key]):
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
	
	for format in formats.keys():
		format_dict[format] = formats[format].format(values)
		# format_dict["$inventory/is_full"] = "Inventory 13 / 50"
		# format_dict["$inventory/count"] = ""
	
	
	 #return "Let's see: {$inventory/is_full}{$inventory/count}".format({
		#"$inventory/is_full": "Inventory 13 / 50",
		#"$inventory/count": ""})
	# Turns into
	# return "Let's see: Inventory 13 / 50"
	return _phrases[phrase_key]["text"].format(format_dict)
