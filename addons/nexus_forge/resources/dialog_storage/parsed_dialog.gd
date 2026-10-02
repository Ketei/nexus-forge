class_name NFParsedDialog
extends RefCounted
## Contains the parsed data of a [DiscourseDialog].
##
## This object will contain data to quickly re-format a [DiscourseDialog]
## dialog quicker by saving generated lambda functions to access variable data.

## The language this dialog is in.
var locale: String = ""
## The unformatted dialog this parser formats.
var dialog: String = ""
var _format_args: Dictionary[String, Variant] = {}
var _phrases_format: Dictionary[String, Dictionary] = {}


func _find_case(on_format: String, on_argument: String, case: String) -> String:
	var format_dict: Variant = _phrases_format.get(on_format)
	if typeof(format_dict) != TYPE_DICTIONARY:
		return ""
	
	var arguments_dict: Dictionary = format_dict[on_format]["arguments"]
	var argument_entry: Variant = arguments_dict.get(on_argument)
	
	if typeof(argument_entry) != TYPE_DICTIONARY:
		return ""
	
	var custom_cases: Dictionary = argument_entry["custom"]
	return custom_cases.get(case, argument_entry["default"])


func _find_case_callable(on_format: String, on_argument: String, method: Callable) -> Dictionary[String, String]:
	var case: String = str(method.call())
	var result: Dictionary[String, String] = {
		"case": case,
		"value": on_argument}
	
	var format_dict: Variant = _phrases_format.get(on_format)
	if typeof(format_dict) != TYPE_DICTIONARY:
		return result
	
	var argument_node: Variant = format_dict["arguments"].get(on_argument)
	if typeof(argument_node) != TYPE_DICTIONARY:
		return result
	
	var case_val: Variant = argument_node["cases"].get(case)
	if typeof(case_val) == TYPE_STRING:
		result["value"] = case_val
		return result
	
	result["value"] = argument_node.get("default", "")
	return result


## Registers a phrase to format [member dialog] with.
func create_format_phrase(key: String, text: String, arguments: Dictionary) -> void:
	var valid_arguments: Dictionary[String, Dictionary] = {}
	
	for arg_key in arguments:
		if typeof(arg_key) != TYPE_STRING or typeof(arguments[arg_key]) != TYPE_DICTIONARY:
			continue
		
		valid_arguments[arg_key] = arguments[arg_key].duplicate(true)
	
	var new_format_entry: Dictionary[String, Variant] = {
		"text": text,
		"arguments": valid_arguments,
		"format": NFDictUtils.create_typed(TYPE_STRING, TYPE_CALLABLE)}
	
	_phrases_format[key] = new_format_entry


## Sets the case of a format string from a phrase.
func set_format_phrase_string(format_key: String, argument: String, case: String) -> void:
	if not _phrases_format.has(format_key):
		return
	
	_phrases_format[format_key]["format"][argument] = _find_case.bind(format_key, argument, case)


## For [param argument] be sure to include the prefix.
func set_format_phrase_callable(format_key: String, argument: String, case: Callable) -> void:
	if not _phrases_format.has(format_key):
		return
	
	_phrases_format[format_key]["format"][argument] =  _find_case_callable.bind(format_key, argument, case)


## Sets a static string to be used to find the case when formatting [param key]
## on the [member dialog].
func set_format_string(key: String, text: String) -> void:
	_format_args[key] = text


## Sets the callable to be used when obtaining the case to format the [member dialog].
func set_format_callable(key: String, method: Callable) -> void:
	_format_args[key] = method


## Returns the formatted dialog.
func get_dialog() -> String:
	var format_dict: Dictionary[String, String] = {}
	for format_key in _phrases_format:
		var formats: Dictionary = {}
		var values: Dictionary = {}
		var phrase_text: String = _phrases_format[format_key]["text"]
		
		for format_arg:String in _phrases_format[format_key]["format"]:
		# !eggs, $gender, etc...
			var case_result: Dictionary[String, String] = _phrases_format[format_key]["format"][format_arg].call()
			# value = { "case": 10, "value": "{!eggs} eggs" }
			
			# formats["!eggs"] = "10 {!eggs}"
			formats[format_arg] = case_result["value"]
			
			# values["!eggs"] = "10"
			values[format_arg] = case_result["case"]
		
		#    Original     |    First format      |  Second format
		# I have {!eggs} -> I have {!eggs} eggs -> I have 10 eggs
		phrase_text = phrase_text.format(formats).format(values)
		
		# format_dict["&EGG"] = "I have 10 eggs"
		format_dict[format_key] = phrase_text
		
	for key in _format_args:
		if typeof(_format_args[key]) == TYPE_CALLABLE:
			format_dict[key] = str(_format_args[key].call())
		else:
			format_dict[key] = key
	
	return dialog.format(format_dict)
