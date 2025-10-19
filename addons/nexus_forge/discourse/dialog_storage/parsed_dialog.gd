class_name ParsedDialog
extends RefCounted

var language: String = ""
var region: String = ""
var dialog: String = ""
var _format_args: Dictionary = {
	#"$player_name": NexusForge.Variables.get_variable.bindv(["player_name"]),
	#"!player_name": _find_case
}
var _phrases_format: Dictionary = {
	#"&EGG_TEST|eggs=10,gender=male" : {
		#"text": "You've laid {!eggs}, you are {!gender} {$butts}",
		#"arguments": {"!eggs": {"default": "{eggs} {gender} eggs", "custom": {"0": "none", "10": "Lots"}}},
		#"format": {"!eggs": _find_case, "!gender": "sissy", "$butts": print.bind(":3")}
	#}
}


func _find_case(on_format: String, on_argument: String, case: String) -> String:
	if _phrases_format[on_format]["arguments"][on_argument]["custom"].has(case):
		return _phrases_format[on_format]["arguments"][on_argument]["custom"][case]
	else:
		return _phrases_format[on_format]["arguments"][on_argument]["default"]


func _find_case_callable(on_format: String, on_argument: String, method: Callable) -> Dictionary[String, String]:
	var case: String = str(method.call())
	var return_result: Dictionary[String, String] = {"case": case, "value": ""}
	if _phrases_format[on_format]["arguments"][on_argument]["custom"].has(case):
		return_result["value"] = _phrases_format[on_format]["arguments"][on_argument]["custom"][case]
	else:
		return_result["value"] = _phrases_format[on_format]["arguments"][on_argument]["default"]
	
	return return_result


func create_format_phrase(key: String, text: String, arguments: Dictionary) -> void:
	_phrases_format[key] = {
		"text": text,
		"arguments": arguments.duplicate(true),
		"format": {}}


func set_format_phrase_string(format_key: String, argument: String, case: String) -> void:
	_phrases_format[format_key]["format"][argument] = _find_case.bind(format_key, argument, case)


## For [param argument] be sure to include the prefix.
func set_format_phrase_callable(format_key: String, argument: String, case: Callable) -> void:
	_phrases_format[format_key]["format"][argument] =  _find_case_callable.bind(format_key, argument, case)


func set_format_string(key: String, text: String) -> void:
	_format_args[key] = text


func set_format_callable(key: String, method: Callable, arguments: Array = []) -> void:
	_format_args[key] = method.bindv(arguments.duplicate(true))


func get_dialog() -> String:
	var format_dict: Dictionary[String, String] = {}
	
	for format_key in _phrases_format.keys():
		var formats: Dictionary = {}
		var values: Dictionary = {}
		var phrase_text: String = _phrases_format[format_key]["text"]
		for format_arg:String in _phrases_format[format_key]["format"].keys():
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
		
	for key in _format_args.keys():
		if typeof(_format_args[key]) == TYPE_CALLABLE:
			format_dict[key] = str(_format_args[key].call())
		else:
			format_dict[key] = key
	
	return dialog.format(format_dict)
