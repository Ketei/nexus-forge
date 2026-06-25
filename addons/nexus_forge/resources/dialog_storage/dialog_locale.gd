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

var json_file: String = ""


static func new_from_json(json_string: String) -> DiscourseDialogLocale:
	var data = JSON.parse_string(json_string)
	
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return null
	
	var new_locale: DiscourseDialogLocale = DiscourseDialogLocale.new()
	
	
	if data.has("localization") and typeof(data["localization"]) == TYPE_DICTIONARY:
		for localization_key in data["localization"].keys():
			if typeof(localization_key) != TYPE_STRING or typeof(data["localization"][localization_key]) != TYPE_DICTIONARY:
				continue
			var json_loc_data: Dictionary = data["localization"][localization_key]
			
			var locale_data: Dictionary[StringName, Dictionary] = {}
			for node_uuid in json_loc_data.keys():
				if typeof(node_uuid) != TYPE_STRING or typeof(data["localization"][localization_key][node_uuid]) != TYPE_DICTIONARY:
					continue
				var json_n_data: Dictionary = json_loc_data[node_uuid]
				if json_n_data.has("dialog"):
					if typeof(json_n_data["dialog"]) == TYPE_STRING:
						locale_data[StringName(node_uuid)] = {
							"text": json_n_data["dialog"]
						}
				elif json_n_data.has("choices"):
					if typeof(json_n_data["choices"]) == TYPE_ARRAY:
						var choice_array: PackedStringArray = []
						for choice in json_n_data["choices"]:
							if typeof(choice) == TYPE_STRING:
								choice_array.append(choice)
							else:
								choice_array.append("[JSON ERROR - Not a String]")
						locale_data[StringName(node_uuid)] = {
							"choices": choice_array}
			
			new_locale.localization[StringName(localization_key)] = locale_data
	
	if data.has("format_strings") and typeof(data["format_strings"]) == TYPE_DICTIONARY:
		var json_data: Dictionary = data["format_strings"]
		for dialog_id in json_data.keys():
			if typeof(dialog_id) != TYPE_STRING or typeof(json_data[dialog_id]) != TYPE_DICTIONARY:
				continue
			var dialog_data: Dictionary = json_data[dialog_id]
			var conversation_data: Dictionary[String, Dictionary] = {}
			for format_id in dialog_data.keys():
				if typeof(format_id) != TYPE_STRING or typeof(dialog_data[format_id]) != TYPE_DICTIONARY:
					continue
				
				var formats: Dictionary[String, Dictionary] = {}
				
				if dialog_data[format_id].has("format"):
					var format_data: Dictionary = dialog_data[format_id]
					for format_key in format_data["format"].keys():
						if typeof(format_key) != TYPE_STRING or typeof(format_data["format"][format_key]) != TYPE_DICTIONARY:
							continue
						var custom_cases: Dictionary[String, String] = {}
						var string_data: Dictionary = format_data["format"][format_key]
						for custom_case in string_data["cases"].keys():
							if typeof(custom_case) != TYPE_STRING or typeof(string_data["cases"][custom_case]) != TYPE_STRING:
								continue
							custom_cases[custom_case] = string_data["cases"][custom_case]
						#data["format_strings"][conversation_uuid][format_id]["format"][format_key]["default"]
						formats[format_key] = {
							"cases": custom_cases,
							"default": DictUtils.get_nested_value(format_data, ["format", format_key, "default"], "", true)}
				conversation_data[format_id] = {
					"format": formats,
					"base_string": DictUtils.get_nested_value(dialog_data, [format_id, "base_string"], "", true)}
			new_locale.format_strings[dialog_id] = conversation_data
	
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
	if DictUtils.has_nested_path(localization, [conversation, node, "choices"]):
		return localization[conversation][node]["choices"].duplicate()
	else:
		return PackedStringArray()


## Returns the dialog text from the given [param uuid] from the [param conversation]
func get_text(conversation: StringName, node: StringName) -> String:
	return DictUtils.get_nested_value(
			localization,
			[conversation, node, "text"],
			"",
			true)


## Returns if the [param conversation] has data for the given [param uuid]
func has_data(conversation: StringName, node: StringName) -> bool:
	return DictUtils.has_nested_path(localization, [conversation, node])


## Returns the unformatted string from the [param conversation] assiged to [param key].
func get_format_string_text(conversation: StringName, key: StringName) -> String:
	return DictUtils.get_nested_value(
			format_strings,
			[conversation, key, "base_string"],
			"",
			true)


## Returns the dictionary containing the format arguments along with the data of
## their [code]default[/code] value and custom [code]cases[/code].
func get_format_string_args(conversation: StringName, key: StringName) -> Dictionary[String, Dictionary]:
	var data: Dictionary[String, Dictionary] = {}
	var stored: Dictionary = DictUtils.get_nested_value(
			format_strings,
			[conversation, key, "format"],
			{},
			true)
	data.assign(stored.duplicate(true))
	return data


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
