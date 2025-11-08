@tool
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

## The language this map is in.
@export var language: String = ""
## The region for the language this map is in
@export var region: String = ""

@export_storage var _phrases: Dictionary[StringName, Dictionary] = {
	#&"InventoryStatus": {
		#"text": "Let's see...{$inventory/is_full}{$inventory/count}{passed_argument}",
		#"arguments": {
			#"$inventory/is_full": {
				#"default": "Inventory {$inventory/count} / 50",
				#"custom": {
					#"true": "Inventory is FULL!!!"},
			#"$inventory/count": {
				#"default": "",
				#"custom": {}}},
			#"passed_argument": {
				#"default": "",
				#"custom": {}
			#}
		#}
	#}
}

# Not exported as these are generated on-demand. Stored in case of being
# needed again.
var _value_keys: Dictionary[StringName, Dictionary] = {
	#&"InventoryStatus": {
		#"$inventory/is_full": Callable(), # Dynamically generated
		#"$inventory/count": Callable()
	#}
}


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


func _build_variable_callable(text: String) -> Callable:
	var var_callable: Callable = Callable(
			NexusForge.Blackboard.get_variable.bind(
						text.trim_prefix("$")))
	return var_callable


func _build_method_callable(function_string: String, arguments_string: String) -> Callable:
		var method: StringName = StringName(function_string)
		var arguments: PackedStringArray = arguments_string.split(",", false)
		
		var final_arguments: Array = []
		
		for argument in arguments:
			if argument.begins_with("$"):
				final_arguments.append(_build_variable_callable(argument))
			elif argument.begins_with("!"):
				var parts: PackedStringArray = argument.split("|", false, 1)
				var sub_arguments: String = "" if parts.size() <= 1 else parts[1]
				final_arguments.append(_build_method_callable(
						parts[1].trim_prefix("!"),
						sub_arguments))
			else:
				final_arguments.append(argument)
		
		return Callable(NexusForge._phrase_api, method).bind(final_arguments)


func _generate_callables(dialog_id: StringName) -> void:
	var dialog: String = _phrases[dialog_id]["text"]
	
	if dialog.is_empty():
		return
	
	var functions_processed: PackedStringArray = []
	var variables_processed: PackedStringArray = []
	var phrases_processed: PackedStringArray = []
	
	var function_regex: RegEx = RegEx.new()
	var variable_regex: RegEx = RegEx.new()
	function_regex.compile("\\{\\![^\\s\\}]+\\}")
	variable_regex.compile("\\{\\$[^\\s\\}]+\\}")
	
	# Searching for function calls.
	
	for rgx_func_result in function_regex.search_all(dialog):
		var value_key: String = rgx_func_result.get_string().trim_prefix("{").trim_suffix("}")
		if _value_keys[dialog_id].has(value_key) or functions_processed.has(rgx_func_result.get_string()):
			continue
		# Only split once from the left
		var parts: Array = value_key.split("|", false, 1)
		var argument_string: String = "" if parts.size() <= 1 else parts[1]
		functions_processed.append(rgx_func_result.get_string())
		
		#func set_format_callable(key: String, method: Callable, arguments: Array = []) -> void:
			#_format_args[key] = method.bindv(arguments.duplicate(true))
		_value_keys[dialog_id][value_key] = _build_method_callable(
				parts[0].trim_prefix("!"),
				argument_string)
	
	# Processing variables
	for rgx_var_result in variable_regex.search_all(dialog):
		var value_key: String = rgx_var_result.get_string().trim_prefix("{").trim_suffix("}")
		if _value_keys[dialog_id].has(value_key) or variables_processed.has(rgx_var_result.get_string()):
			continue
		
		variables_processed.append(rgx_var_result.get_string())
		
		_value_keys[dialog_id][value_key] = _build_variable_callable(value_key.trim_prefix("$"))


func _find_case(phrase: StringName, on_argument: String, case: String) -> Dictionary[String, String]:
	var return_result: Dictionary[String, String] = {"case": case, "value": ""}
	
	if _phrases[phrase]["arguments"][on_argument]["custom"].has(case):
		return_result["value"] = _phrases[phrase]["arguments"][on_argument]["custom"][case]
	else:
		return_result["value"] =  _phrases[phrase]["arguments"][on_argument]["default"]
	
	return return_result


func _find_case_callable(phrase: StringName, on_argument: String, method: Callable) -> Dictionary[String, String]:
	var case: String = str(method.call())
	var return_result: Dictionary[String, String] = {"case": case, "value": ""}
	if _phrases[phrase]["arguments"][on_argument]["custom"].has(case):
		return_result["value"] = _phrases[phrase]["arguments"][on_argument]["custom"][case]
	else:
		return_result["value"] = _phrases[phrase]["arguments"][on_argument]["default"]
	
	return return_result


func phrases() -> Array[StringName]:
	var arr: Array[StringName] = []
	arr.assign(_phrases.keys())
	return arr


## Creates a phrase and sets its text to [param text].
func create_phrase(phrase_key: StringName, text: String = "") -> void:
	if _phrases.has(phrase_key):
		return
	
	var arguments: Dictionary[String, Dictionary] = {}
	
	if not text.is_empty():
		var formats: Array[String] = get_valid_formats(text)
		
		for format in formats:
			var new_arg: Dictionary[String, Variant] = {
				"default": "",
				"custom": Dictionary({}, TYPE_STRING, &"", null, TYPE_STRING, &"", null)}
			arguments[format] = new_arg
	
	_phrases[phrase_key] = {
		"text": text,
		"arguments": arguments}


## Sets the phrase's [param phrase_key] text to [param text].
func set_phrase_text(phrase_key: StringName, text: String) -> void:
	if not _phrases.has(phrase_key):
		return
	
	_phrases[phrase_key]["text"] = text
	
	if text.is_empty():
		_phrases[phrase_key]["arguments"].clear()
	else:
		var formats: Array[String] = get_valid_formats(text)
		
		for existing_format in _phrases[phrase_key]["arguments"].keys():
			if not formats.has(existing_format):
				_phrases[phrase_key]["arguments"].erase(existing_format)
		
		for new_format in formats:
			if not _phrases[phrase_key]["arguments"].has(new_format):
				_phrases[phrase_key]["arguments"][new_format] = {
					"default": "",
					"custom": Dictionary({}, TYPE_STRING, &"", null, TYPE_STRING, &"", null)}


## Returns the text that the phrase [param phrase_key] is set to or an empty
## string if the phrase doesn't exist.
func get_phrase_text(phrase_key: StringName) -> String:
	if _phrases.has(phrase_key):
		return _phrases[phrase_key]["text"]
	return ""


func get_phrase_format_fields(phrase_key: StringName) -> Array[String]:
	var formats: Array[String] = []
	if _phrases.has(phrase_key):
		formats.assign(_phrases[phrase_key]["arguments"].keys())
	return formats


## Returns true if [param phrase_key] exists in this map.
func has_phrase(phrase_key: StringName):
	return _phrases.has(phrase_key)


func erase_phrase(phrase_key: StringName) -> void:
	if _phrases.erase(phrase_key):
		_value_keys.erase(phrase_key)


## Returns true if [param phrase_key] has an argument of [param argument].
func phrase_has_argument(phrase_key: StringName, argument: String) -> bool:
	return _phrases.has(phrase_key) and _phrases[phrase_key]["arguments"].has(argument)


## Sets the phrase [param phrase_key] default case for argument [param on_argument]
## to [param default_value].
func set_phrase_argument_default(phrase_key: StringName, on_argument: String,  default_value: String) -> void:
	if not _phrases.has(phrase_key):
		return
	
	if not _phrases[phrase_key]["arguments"].has(on_argument):
		var argument_data: Dictionary[String, Variant] = {
			"default": "",
			"custom": Dictionary({}, TYPE_STRING, &"", null, TYPE_STRING, &"", null)}
		_phrases[phrase_key]["arguments"][on_argument] = argument_data
	
	_phrases[phrase_key]["arguments"][on_argument]["default"] = default_value


## Returns the phrase [param phrase_key] default case for argument [param on_argument]
## or an empty string if the argument doesn't exist.
func get_phrase_argument_default(phrase_key: StringName, on_argument: String) -> String:
	if _phrases.has(phrase_key) and _phrases[phrase_key]["arguments"].has(on_argument):
		return _phrases[phrase_key]["arguments"][on_argument]["default"]
	return ""


## Sets the case on the phrase [param phrase_key] on the argument [param on_argument]
## to be [param value].
func set_phrase_argument_case(phrase_key: StringName, on_argument: String, case: String, value: String) -> void:
	if _phrases.has(phrase_key) == false:
		return
	
	if not _phrases[phrase_key]["arguments"].has(on_argument):
		var argument_data: Dictionary[String, Variant] = {
			"default": "",
			"custom": Dictionary({}, TYPE_STRING, &"", null, TYPE_STRING, &"", null)}
		_phrases[phrase_key]["arguments"][on_argument] = argument_data
	
	_phrases[phrase_key]["arguments"][on_argument]["custom"][case] = value


func clear_phrase_argument_cases(phrase_key: StringName, on_argument: String) -> void:
	if not _phrases.has(phrase_key) or not _phrases[phrase_key]["arguments"].has(on_argument):
		return
	_phrases[phrase_key]["arguments"][on_argument]["custom"].clear()


## Returns the case on the phrase [param phrase_key] on the argument [param on_argument]
## or an empty string if the case doesn't exist.
func get_phrase_argument_case(phrase_key: StringName, on_argument: String, case: String) -> String:
	if _phrases.has(phrase_key) and _phrases[phrase_key]["arguments"].has(on_argument) and _phrases[phrase_key]["arguments"][on_argument]["custom"].has(case):
		return _phrases[phrase_key]["arguments"][on_argument]["custom"][case]
	return ""


## Returns true if [param case] exists on the argument [param on_argument] from
## the phrase [param phrase_key].
func has_phrase_argument_case(phrase_key: StringName, on_argument: String, case: String) -> bool:
	return _phrases.has(phrase_key) and _phrases[phrase_key]["arguments"].has(on_argument) and _phrases[phrase_key]["arguments"][on_argument]["custom"].has(case)


## Returns the formatted text of phrase [param phrase_key]. Optionally you can pass
## [param override_values] that will be used instead of Blackboard or callable
## data (if applicable) to get the appropiate case for formatting the phrase's text.
func get_text(phrase_key: StringName, override_values: Dictionary[String, String] = {}) -> String:
	if _phrases.has(phrase_key) == false:
		return ""
	
	# Will be working with text "Let's see: {$inventory/is_full}{$inventory/count}"
	var format_dict: Dictionary[String, String] = {}
	
	if not _value_keys.has(phrase_key):
		_generate_callables(phrase_key)
	
	var formats: Dictionary[String, String] = {}
	var values: Dictionary[String, String] = {}
	
	for format_key in _phrases[phrase_key]["arguments"].keys():
		# format_key = $inventory/is_full
		
		var case_result: Dictionary[String, String] = {}
		
		if override_values.has(format_key):
			case_result.assign(
					_find_case(
							phrase_key,
							format_key,
							override_values[format_key]))
		elif _value_keys[phrase_key].has(format_key):
			case_result.assign(
					_find_case_callable(
							phrase_key,
							format_key,
							_value_keys[phrase_key][format_key]))
		else:
			case_result["case"] = ""
			case_result["value"] = _phrases[phrase_key]["arguments"][format_key]["default"]

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
