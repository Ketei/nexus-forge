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
	if json_string.is_empty():
		return null
	
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
						if string_data.has("cases") and typeof(string_data["cases"]) == TYPE_DICTIONARY:
							for custom_case in string_data["cases"].keys():
								if typeof(custom_case) != TYPE_STRING or typeof(string_data["cases"][custom_case]) != TYPE_STRING:
									continue
								custom_cases[custom_case] = string_data["cases"][custom_case]
						formats[format_key] = {
							"cases": custom_cases,
							"default": DictUtils.get_nested_value(format_data, ["format", format_key, "default"], "", true)}
				conversation_data[format_id] = {
					"format": formats,
					"base_string": DictUtils.get_nested_value(dialog_data, [format_id, "base_string"], "", true)}
			new_locale.format_strings[dialog_id] = conversation_data
	
	return new_locale


static func _overlay_dialog_array(target: PackedStringArray, source: PackedStringArray, max_size: int = -1) -> void:
	if source.is_empty():
		return
	
	var range_size: int = source.size() if max_size < 0 else mini(max_size, source.size())
	
	if target.size() < range_size:
		target.resize(range_size)
	
	for i in range(range_size):
		var text: String = target[i].strip_edges()
		if text.is_empty():
			target[i] = source[i]
	


## Merges the localization data of [param with] with the data of this
## object. If [param overwrite] is [code]true[/code] then existing data will be
## overwritten.
func merge_dialog(with: DiscourseDialogLocale) -> void:
	if with == null or with == self:
		return
	
	for dialog_id in with.localization:
		if not localization.has(dialog_id):
			localization[dialog_id] = with.localization[dialog_id].duplicate(true)
			continue
		
		var target_dialog: Dictionary = localization[dialog_id]
		var source_dialog: Dictionary = with.localization[dialog_id]
		
		for node_id in source_dialog:
			if not target_dialog.has(node_id):
				target_dialog[node_id] = source_dialog[node_id].duplicate(true)
				continue
			
			var target_node: Dictionary = target_dialog[node_id]
			var source_node: Dictionary = source_dialog[node_id]
			
			if target_node.has("text") and source_node.has("text"):
				if target_node["text"].is_empty():
					target_node["text"] = source_node["text"]
			elif target_node.has("choices") and source_node.has("choices"):
				_overlay_dialog_array(target_node["choices"], source_node["choices"])
	
	for dialog_id in with.format_strings:
		if not format_strings.has(dialog_id):
			format_strings[dialog_id] = with.format_strings[dialog_id].duplicate(true)
			continue
		
		var target_entry: Dictionary = format_strings[dialog_id]
		var source_entry: Dictionary = with.format_strings[dialog_id]
		
		for entry_id in source_entry:
			if not target_entry.has(entry_id):
				target_entry[entry_id] = source_entry[entry_id].duplicate(true)
				continue
			
			var target_data: Dictionary = target_entry[entry_id]
			var source_data: Dictionary = source_entry[entry_id]
			
			var target_base: String = ""
			
			if target_data.has("base_string"):
				target_base = target_data["base_string"].strip_edges()
			
			if target_base.is_empty():
				if source_data.has("base_string"):
					# We copy over everything, validation and healing is
					# performed by the object parsing the dialogs.
					target_data["base_string"] = source_data["base_string"]
					if source_data.has("format"):
						target_data["format"] = source_data["format"].duplicate(true)
				continue
			
			var entries: Array[String] = StringUtils.get_all_format_arguments(target_base, true)
			var source_formats: Dictionary = source_data["format"]
			var target_formats: Dictionary = target_data["format"]
			
			for existing_format in entries:
				if not source_formats.has(existing_format):
					continue
				
				if not target_formats.has(existing_format):
					target_formats[existing_format] = source_formats[existing_format].duplicate(true)
					continue
				
				var target_default: String = target_formats[existing_format]["default"].strip_edges()
				
				if target_default.is_empty():
					target_formats[existing_format]["default"] = source_formats[existing_format]["default"]
				
				var target_cases: Dictionary = target_formats[existing_format]["cases"]
				var source_cases: Dictionary = source_formats[existing_format]["cases"]
				
				for case in source_cases:
					if not target_cases.has(case):
						target_cases[case] = source_cases[case]
						continue
					
					var target_string: String = target_cases[case].strip_edges()
					if target_string.is_empty():
						target_cases[case] = source_cases[case]


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
