class_name DiscourseDialogLocale
extends Resource


@export var language: String = "en"
@export var region: String = "base"
@export var localization: Dictionary = {
	#&"MyConversationUUID": {
		#&"UUID": {"dialog": "Hello world"},
		#&"UUID2": {"options": PackedStringArray(["Hi", "Who?", "Where?"])}}
	}
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


func get_options(conversation: StringName, uuid: StringName) -> PackedStringArray:
	return localization[conversation][uuid]["options"].duplicate()


func get_text(conversation: StringName, uuid: StringName) -> String:
	return localization[conversation][uuid]["dialog"]


func has_text(conversation: StringName, uuid: StringName) -> bool:
	return localization[conversation].has(uuid)


func get_format_string_text(conversation: StringName, key: StringName) -> String:
	return format_strings[conversation][key]["text"]


func get_format_string_args(conversation: StringName, key: StringName) -> Dictionary[String, Dictionary]:
	return format_strings[conversation][key]["arguments"].duplicate(true)


func has_format_string(conversation: StringName, key: StringName) -> bool:
	return format_strings[conversation].has(key)


func set_text(conversation: StringName, uuid: StringName, text: String) -> void:
	if not localization.has(conversation):
		localization[conversation] = {}
	localization[conversation][uuid] = {"dialog": text}


func set_options(conversation: StringName, uuid: StringName, options: PackedStringArray) -> void:
	if not localization.has(conversation):
		localization[conversation] = {}
	localization[conversation][uuid] = {"options": options.duplicate()}


func set_format_string(conversation: StringName, key: String, text: String, arguments: Dictionary[String, Dictionary]) -> void:
	if not format_strings.has(conversation):
		format_strings[conversation] = {}
	format_strings[conversation][key] = {
		"text": text,
		"arguments": arguments.duplicate(true)}
