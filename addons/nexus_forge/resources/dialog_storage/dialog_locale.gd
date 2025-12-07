class_name DiscourseDialogLocale
extends Resource


## The language this dialog is in.
@export var language: String = "en"
## The region this dialog belongs to.
@export var region: String = "base"
## The dictionary containing the UUIDs of the conversations, nodes and localized
## data.[br]
@export var localization: Dictionary[StringName, Dictionary] = {
	#&"MyConversationUUID": {
		#&"UUID": {"dialog": "Hello world"},
		#&"UUID2": {"options": PackedStringArray(["Hi", "Who?", "Where?"])}}
	}
## The format strings from conversations and all their formats.
@export var format_strings: Dictionary[String, Dictionary] = {
	#"MyConversationUUID": {
		#"HELLO_WORLD": {
			#"text": "Hello {-player}",
			#"arguments": {
				#"player": {
					#"default": ":3",
					#"custom": {
						#"wulfre": "bear",
						#"other": "{player}"}
				#}
			#}
		#},
		#&"EGGD": {
			#"text": "",
			#"arguments": {}
		#}
	#}
}


static func new_from_json(json_string: String) -> DiscourseDialogLocale:
	var data = JSON.parse_string(json_string)
	
	if data == null or typeof(data) != TYPE_DICTIONARY or not data.has_all(["localization", "format_strings"]):
		return null
	
	var new_locale: DiscourseDialogLocale = DiscourseDialogLocale.new()
	
	for localization_key:String in data["localization"].keys():
		var locale_data: Dictionary[String, Dictionary] = {}
		
		for node_uuid in data["localization"][localization_key].keys():
			locale_data[node_uuid] = {}
			if data["localization"][localization_key][node_uuid].has("dialog"):
				locale_data[node_uuid]["dialog"] = data["localization"][localization_key][node_uuid]["dialog"]
			else:
				locale_data[node_uuid]["options"] = PackedStringArray(data["localization"][localization_key][node_uuid]["options"])
		
		new_locale.localization[StringName(localization_key)] = locale_data
	
	for conversation_uuid in data["format_strings"].keys():
		var conversation_data: Dictionary[String, Dictionary] = {}
		for format_key in data["format_strings"][conversation_uuid].keys():
			var arguments: Dictionary[String, Dictionary] = {}
			
			for argument_key in data["format_strings"][conversation_uuid][format_key]["arguments"].keys():
				var custom_args: Dictionary[String, String] = {}
				for custom_arg in data["format_strings"][conversation_uuid][format_key]["arguments"][argument_key]["custom"].keys():
					custom_args[custom_arg] = data["format_strings"][conversation_uuid][format_key]["arguments"][argument_key]["custom"][custom_arg]
			
				arguments[argument_key] = {
					"custom": custom_args,
					"default": data["format_strings"][conversation_uuid][format_key]["arguments"][argument_key]["default"]}
			conversation_data[format_key] = {
				"arguments": arguments,
				"text": data["format_strings"][conversation_uuid][format_key]["text"]}
		new_locale.format_strings[conversation_uuid] = conversation_data
	return new_locale


func as_json() -> String:
	var data: Dictionary = {
		"language": language,
		"region": region,
		"localization": localization,
		"format_strings": format_strings}
	return JSON.stringify(data)


## Returns the options of the given [param uuid] from the [param conversation] .
func get_options(conversation: StringName, uuid: StringName) -> PackedStringArray:
	if localization.has(conversation) and localization[conversation].has(uuid) and localization[conversation][uuid].has("options"):
		return localization[conversation][uuid]["options"].duplicate()
	return PackedStringArray()


## Returns the dialog text from the given [param uuid] from the [param conversation]
func get_text(conversation: StringName, uuid: StringName) -> String:
	if localization.has(conversation) and localization[conversation].has(uuid) and localization[conversation][uuid].has("dialog"):
		return localization[conversation][uuid]["dialog"]
	return ""


## Returns if the [param conversation] has data for the given [param uuid]
func has_data(conversation: StringName, uuid: StringName) -> bool:
	return localization.has(conversation) and localization[conversation].has(uuid)


## Returns the unformatted string from the [param conversation] assiged to [param key].
func get_format_string_text(conversation: StringName, key: StringName) -> String:
	if format_strings.has(conversation) and format_strings[conversation].has(key):
		return format_strings[conversation][key]["text"]
	return ""


## Returns the dictionary containing the format arguments along with the data of
## their [code]default[/code] value and [code]custom[/code] cases.
func get_format_string_args(conversation: StringName, key: StringName) -> Dictionary[String, Dictionary]:
	if format_strings.has(conversation) and format_strings[conversation].has(key):
		return format_strings[conversation][key]["arguments"].duplicate(true)
	return Dictionary({}, TYPE_STRING, &"", null, TYPE_DICTIONARY, &"", null)


## Returns true if the given [param conversation] has a format string with the given [param key].
func has_format_string(conversation: StringName, key: StringName) -> bool:
	return format_strings.has(conversation) and format_strings[conversation].has(key)


## Sets the dialog text from the [param conversation]'s [param uuid] to [param text].
func set_text(conversation: StringName, uuid: StringName, text: String) -> void:
	if localization.has(conversation) and localization[conversation].has(uuid) and localization[conversation][uuid].has("dialog"):
		localization[conversation][uuid]["dialog"] = text


## Sets the dialog options from the [param conversation]'s [param uuid] to be
## [param options].
func set_options(conversation: StringName, uuid: StringName, options: PackedStringArray) -> void:
	if localization.has(conversation) and localization[conversation].has(uuid) and localization[conversation][uuid].has("options"):
		localization[conversation][uuid]["options"] = options.duplicate()


## Sets the format string from the [param conversation] with the assigned
## [param key] to be [param text] and the given format [param arguments].
func set_format_string(conversation: StringName, key: String, text: String, arguments: Dictionary[String, Dictionary]) -> void:
	if format_strings.has(conversation) and format_strings[conversation].has(key):
		format_strings[conversation][key]["text"] = text
		format_strings[conversation][key]["arguments"] = arguments.duplicate(true)
