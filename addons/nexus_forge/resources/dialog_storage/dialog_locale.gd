class_name DiscourseDialogLocale
extends Resource


## The locale code this dialog is in.
@export var locale: String = "en"

# The dictionary containing the UUIDs of the conversations, nodes and localized
# data.
@export_storage var localization: Dictionary[StringName, Dictionary] = {
	#&"resourceUID": {
		#&"NodeUUID": {"text": "Hello world"},
		#&"UUID2": {"choices": ["a", "b", "c"]}}
	#&"resourceUID2": {
		#...
	#}
	}
# The format strings from conversations and all their formats.
@export_storage var format_strings: Dictionary[String, Dictionary] = {
	#"resourceUID": {
		#"HELLO_WORLD": {
			#"base_string": "Hello {-player}",
			#"format": {
				#"player": {
					#"default": ":3",
					#"cases": {
						#"wulfre": "bear",
						#"other": "{player}"}
				#}
			#}
		#},
		#&"EGGD": {
			#"base_string": "",
			#"formats": {}
		#}
	#}
}


static func new_from_json(json_string: String) -> DiscourseDialogLocale:
	var data = JSON.parse_string(json_string)
	
	if data == null or typeof(data) != TYPE_DICTIONARY or not data.has_all(["localization", "format_strings"]) or typeof(data["localization"]) != TYPE_DICTIONARY or typeof(data["format_strings"]) != TYPE_DICTIONARY:
		return null
	
	var new_locale: DiscourseDialogLocale = DiscourseDialogLocale.new()
	
	for localization_key:String in data["localization"].keys():
		#if typeof(data["localization"][localization_key]) != TYPE_DICTIONARY:
			#continue
		var locale_data: Dictionary[StringName, Dictionary] = {}
		for node_uuid in data["localization"][localization_key].keys():
			#if typeof(data["localization"][localization_key][node_uuid]) != TYPE_DICTIONARY:
				#continue
			if data["localization"][localization_key][node_uuid].has("text") and typeof(data["localization"][localization_key][node_uuid]["text"]) == TYPE_STRING:
				locale_data[StringName(node_uuid)] = {"text": data["localization"][localization_key][node_uuid]["text"]}
			elif data["localization"][localization_key][node_uuid].has("choices") and typeof(data["localization"][localization_key][node_uuid]["choices"]) == TYPE_ARRAY:
				#var choices: PackedStringArray = []
				#for choice in data["localization"][localization_key][node_uuid]["choices"]:
					#if typeof(choice) == TYPE_STRING:
						#choices.append(choice)
				locale_data[StringName(node_uuid)] = {"choices": PackedStringArray(data["localization"][localization_key][node_uuid]["choices"])}
		
		new_locale.localization[StringName(localization_key)] = locale_data
	
	for conversation_uuid in data["format_strings"].keys():
		var conversation_data: Dictionary[String, Dictionary] = {}
		for format_id in data["format_strings"][conversation_uuid].keys():
			var formats: Dictionary[String, Dictionary] = {}
			
			for format_key in data["format_strings"][conversation_uuid][format_id]["format"].keys():
				var custom_cases: Dictionary[String, String] = {}
				for custom_case in data["format_strings"][conversation_uuid][format_id]["format"][format_key]["cases"].keys():
					custom_cases[custom_case] = data["format_strings"][conversation_uuid][format_id]["format"][format_key]["cases"][custom_case]
			
				formats[format_key] = {
					"cases": custom_cases,
					"default": data["format_strings"][conversation_uuid][format_id]["format"][format_key]["default"]}
			conversation_data[format_id] = {
				"format": formats,
				"base_string": data["format_strings"][conversation_uuid][format_id]["base_string"]}
		new_locale.format_strings[conversation_uuid] = conversation_data
	return new_locale


## Sets the dialog text from the [param conversation]'s [param uuid] to [param text].
func set_text(conversation: StringName, uuid: StringName, text: String) -> void:
	DictUtils.set_nested_value(
			localization,
			[conversation, uuid, "dialog"],
			text,
			false)


## Sets the dialog options from the [param conversation]'s [param uuid] to be
## [param options].
func set_choices(conversation: StringName, uuid: StringName, choices: PackedStringArray) -> void:
	DictUtils.set_nested_value(
			localization,
			[conversation, uuid, "choices"],
			choices.duplicate(),
			false)


func as_json() -> String:
	var data: Dictionary = {
		"localization": localization,
		"format_strings": format_strings}
	return JSON.stringify(data, "\t")


## Returns the options of the given [param uuid] from the [param conversation] .
func get_choices(conversation: StringName, node: StringName) -> PackedStringArray:
	return DictUtils.get_nested_value(
			localization,
			[conversation, node, "choices"],
			PackedStringArray()).duplicate()


## Returns the dialog text from the given [param uuid] from the [param conversation]
func get_text(conversation: StringName, node: StringName) -> String:
	return DictUtils.get_nested_value(
			localization,
			[conversation, node, "text"],
			"")


## Returns if the [param conversation] has data for the given [param uuid]
func has_data(conversation: StringName, node: StringName) -> bool:
	return DictUtils.has_nested_path(localization, [conversation, node])


## Returns the unformatted string from the [param conversation] assiged to [param key].
func get_format_string_text(conversation: StringName, key: StringName) -> String:
	return DictUtils.get_nested_value(
			format_strings,
			[conversation, key, "text"],
			"")


## Returns the dictionary containing the format arguments along with the data of
## their [code]default[/code] value and [code]custom[/code] cases.
func get_format_string_args(conversation: StringName, key: StringName) -> Dictionary[String, Dictionary]:
	return DictUtils.get_nested_value(
			format_strings,
			[conversation, key, "arguments"],
			Dictionary({}, TYPE_STRING, &"", null, TYPE_DICTIONARY, &"", null)).duplicate(true)


## Returns true if the given [param conversation] has a format string with the given [param key].
func has_format_string(conversation: StringName, key: StringName) -> bool:
	return DictUtils.has_nested_path(
			format_strings,
			[conversation, key])


## Sets the format string from the [param conversation] with the assigned
## [param key] to be [param text] and the given format [param arguments].
func set_format_string(conversation: StringName, key: String, text: String, arguments: Dictionary[String, Dictionary]) -> void:
	var target: Dictionary = DictUtils.get_nested_value(
			format_strings,
			[conversation, key],
			{})
	
	if not target.is_empty():
		target["text"] = text
		target["arguments"] = arguments.duplicate(true)
