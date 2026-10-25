@tool
@icon("res://addons/nexus_forge/icons/dialog_full.svg")
class_name EditorDiscourseDialog
extends DiscourseDialog
## A resource containing a dialog ONLY to be used in the Godot editor.
##
## Editor only files. On export, all EditorDiscourseDialog are converted to
## [ReleaseDiscourseDialog] and the original files are NOT included.


static var _regex_search: RegEx

## Offset for the [GraphEdit] in Discourse.
var scroll_offset: Vector2 = Vector2.ZERO:
	set(new_scroll):
		scroll_offset = new_scroll.snappedf(0.001)
## Zoom for the [GraphEdit] in Discourse.
var zoom: float = 1.0:
	set(new_zoom):
		zoom = snappedf(new_zoom, 0.001)
## A dictionary containing the collapsed status of folders.
var collapsed_state: Dictionary[String, bool] = {}

## A map of all languages that will be exported and used. If
## localization data is set but the locale isn't registered in here
## then the export plugin will ignore that data.
@export_storage var locale_map: Dictionary[String, Dictionary] = {
	#"en": {"US": null, "GB": null}
}

## The user-assigned ID of this dialogue. Will be used during the
## game's export process.
@export var dialog_id: String = ""

## The user-assigned locale group ID.
## [br][br]
## Localizations with the same id will be merged toguether on the
## release file.
## If empty then each conversation will have it's own unique locale
## json file.
@export_storage var locale_group: String = ""

## Individual frame data.
@export_storage var node_frames: Dictionary[String, Dictionary] = {
	#"e2f420f0-1e9b-4672-bdaf-e926b59945d2": {
		#"title": "Random Frame",
		#"position": Vector2(100, 100),
		#"size": Vector2(200, 200),
		#"tint_color": Color(0.0, 0.0, 0.0, 0.55),
		#"nodes": ["629de91c-d6c1-4f67-a287-b6899695b0a6"], # Nodes linked to it.
	#}
}

## Individual node data.
@export_storage var node_data: Dictionary[StringName, Dictionary] = {
	#&"9156f183-6761-4259-9dde-1a81d12fb047": {
		#"name": &"Greeting",
		#"output_connections": {},
		#"input_connections": {},
		#"metadata": {
			#"character_id": "ABC",
			#"persist": true,
			#"size": Vector2.ZERO,
			#"position": Vector2.ZERO
			#"localized": true
		#}
	#}
}

## The localization data of this dialogue.
@export_storage var localization: Dictionary[StringName, Dictionary] = {
	#&"9156f183-6761-4259-9dde-1a81d12fb047": {
		#"type": LocalizationType.DIALOG,
		#"unlocalized": "",
		#"locales": {
			#"en": "Hello!",
			#"es": "Hola",
			#"en-US": "Howdy!"
		#}
	#},
	#&"8baeaa95-264b-44e7-b483-4076635f6216" : {
		#"type": LocalizationType.CHOICES,
		#"unlocalized": [],
		#"locales": {
			#"en": ["option one", "option two", "option three"],
			#"es-MX": ["opcion uno", "opcion dos", "option tres"],
			#"fr-CA": ["option une", "option deux", "option trois"]
		#}
	#}
}

## The format string data and localization of this dialogue.
@export_storage var format_strings: Dictionary[String, Dictionary] = {
	#"GREETINGS": {
		#"en": {
			#"base_string": "Hemlo!",
			#"format": {
				#"player": {
					#"default": "",
					#"cases": {
						#"ketei": "Doggie",
						#"wulfre": "variables/player/name",
					#}
				#}
			#}
		#}
	#}
}


# Node folder structure
# {"is_node": true, "uuid": ""}
# {"is_node": false, "name": "", "items": {}}
## The folder structure of this dialogue file.
@export_storage var node_structure: Array[Dictionary] = []

# Local ID map that builds as calls are made for optimization.
var _id_map: Dictionary[StringName, StringName] = {}


static func _static_init() -> void:
	_regex_search = RegEx.new()
	_regex_search.compile("\\{[\\$\\!][^\\s\\}]+\\}")


## Returns an array with all the format arguments of the prase [param phrase_text].[br]
## It'll only look for format arguments that start with $ or !.
static func get_phrase_arguments(phrase_text: String, trim_brackets: bool = false) -> Array[String]:
	var all_arguments: Array[String] = []
	
	if trim_brackets:
		for regex_match in _regex_search.search_all(phrase_text): # $variable
			all_arguments.append(regex_match.get_string().trim_prefix("{").trim_suffix("}"))
	else:
		for regex_match in _regex_search.search_all(phrase_text): # $variable
			all_arguments.append(regex_match.get_string())
	
	return all_arguments


func _get_text_data_localized(node_uuid: StringName, for_locale: String) -> Dictionary:
	for_locale = NFStringUtils.sanitize_locale(for_locale)
	
	var data: Dictionary[String, Variant] = {
		"is_override": false,
		"text": "[MISSING LOCALIZATION DATA]"}
	
	if for_locale.is_empty() or not node_data.has(node_uuid):
		return data
	
	var node_id: StringName = node_data[node_uuid].get("name", &"")
	var localized: bool = node_data[node_uuid]["metadata"]["localized"]
	
	if _dialog_overrides != null and _dialog_overrides.has_override(node_id, for_locale, TYPE_STRING):
		data["is_override"] = true
		data["text"] = _dialog_overrides.get_override(node_id, for_locale)
		return data
	
	if not localization.has(node_uuid):
		return data
	
	var e: Dictionary = NFDictUtils.EMPTY_DICT
	var localization_dict: Dictionary = localization.get(node_uuid, e)
	var locales_dict: Dictionary = localization_dict.get("locales", e)
	
	if localized:
		var localized_data: Variant = locales_dict.get(for_locale)
		if typeof(localized_data) == TYPE_STRING and not localized_data.is_empty():
			data["text"] = localized_data
			return data
	else:
		var unlocalized_data: Variant = localization_dict.get("unlocalized")
		if typeof(unlocalized_data) == TYPE_STRING:
			data["text"] = localization[node_uuid]["unlocalized"]
			return data
	
	# 0 = No Fallback
	# 1 = Direct Fallback: Merge fallback_object with loaded objects
	# 2 = Cascade fallback
	var fallback_mode: int = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse_fallback_mode"),
			2)
	
	if fallback_mode == 0:
		return data
	
	var lang_fallback: String = ProjectSettings.get_setting(
			"internationalization/locale/fallback")
	
	if fallback_mode == 2 and for_locale.contains("_"):
		var base_lang: String = for_locale.get_slice("_", 0)
		if base_lang != lang_fallback:
			if locales_dict.has(base_lang):
				var locale_data: Variant = locales_dict.get(base_lang)
				if typeof(locale_data) == TYPE_STRING and not locale_data.is_empty():
					data["text"] = locale_data
					return data
	
	if locales_dict.has(lang_fallback):
		var locale_data: Variant = locales_dict.get(lang_fallback)
		if typeof(locale_data) == TYPE_STRING and not locale_data.is_empty():
			data["text"] = locale_data
	
	return data


func _get_array_data_localized(node_uuid: StringName, for_locale: String) -> Dictionary:
	for_locale = NFStringUtils.sanitize_locale(for_locale)
	
	var choices: PackedStringArray = []
	var build_array: Array = []
	var data: Dictionary[String, Variant] = {
		"is_override": false,
		"choices": choices}
	
	var node_size: int = 0
	if node_data.has(node_uuid):
		node_size = node_data[node_uuid]["metadata"]["choices"].size()
	
	if node_size == 0:
		return data
	else:
		choices.resize(node_size)
		build_array.resize(node_size)
	
	if not localization.has(node_uuid) or for_locale.is_empty():
		choices.fill("[MISSING LOCALIZATION DATA]")
		return data
	
	var node_id: StringName = node_data[node_uuid].get("name", &"")
	var localized: bool = node_data[node_uuid]["metadata"]["localized"]
	
	if localized:
		if localization[node_uuid]["locales"].has(for_locale):
			if typeof(localization[node_uuid]["locales"][for_locale]) == TYPE_PACKED_STRING_ARRAY:
				var source: PackedStringArray = localization[node_uuid]["locales"][for_locale]
				for idx in range(mini(source.size(), node_size)):
					var choice_item: String = source[idx].strip_edges()
					if  not choice_item.is_empty():
						build_array[idx] = choice_item
	else:
		if typeof(localization[node_uuid]["unlocalized"]) == TYPE_PACKED_STRING_ARRAY:
			var source: PackedStringArray = localization[node_uuid]["unlocalized"]
			for idx in range(mini(source.size(), node_size)):
				var choice_item: String = source[idx].strip_edges()
				if not choice_item.is_empty():
					build_array[idx] = choice_item
	
	# 0 = No Fallback
	# 1 = Direct Fallback: Merge fallback_object with loaded objects
	# 2 = Cascade fallback
	var fallback_mode: int = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse_fallback_mode"),
			2)
	var lang_fallback: String = ProjectSettings.get_setting(
			"internationalization/locale/fallback")
	var req_is_not_fallback: bool = for_locale != lang_fallback
	
	for idx in range(build_array.size()):
		var val: Variant = build_array[idx]
		if val != null:
			choices[idx] = val
	
	if fallback_mode == 2 and req_is_not_fallback and for_locale.contains("_"):
		var base_lang: String = for_locale.get_slice("_", 0)
		if base_lang != lang_fallback:
			if localization[node_uuid]["locales"].has(base_lang):
				if typeof(localization[node_uuid]["locales"][base_lang]) == TYPE_PACKED_STRING_ARRAY:
					var source: PackedStringArray = localization[node_uuid]["locales"][base_lang]
					var it: int = mini(source.size(), node_size)
					for idx in range(it):
						var choice_item: String = source[idx].strip_edges()
						if choices[idx].is_empty() and not choice_item.is_empty():
							choices[idx] = choice_item
	
	if fallback_mode != 0 and req_is_not_fallback and localization[node_uuid]["locales"].has(lang_fallback):
		if typeof(localization[node_uuid]["locales"][lang_fallback]) == TYPE_PACKED_STRING_ARRAY:
			var source: PackedStringArray = localization[node_uuid]["locales"][lang_fallback]
			var it: int = mini(source.size(), node_size)
			for idx in range(it):
				var choice_item: String = source[idx].strip_edges()
				if choices[idx].is_empty() and not choice_item.is_empty():
					choices[idx] = choice_item
	
	var empty: int = choices.find("")
	while -1 < empty:
		choices[empty] = "[MISSING LOCALIZATION DATA]"
		empty = choices.find("", empty + 1)
	
	if _dialog_overrides != null:
		var override: Variant = _dialog_overrides.get_override(node_id, for_locale)
		if typeof(override) == TYPE_ARRAY:
			var it: int = mini(override.size(), node_size)
			for override_index in range(it):
				var item: Variant = override[override_index]
				if item != null:
					choices[override_index] = item
			data["is_override"] = true
	
	return data


## Returns the text of a localized string.
func get_format_string(key: String, locale: String) -> String:
	locale = NFStringUtils.sanitize_locale(locale)
	var e: Dictionary = NFDictUtils.EMPTY_DICT
	return format_strings.get(key, e).get(locale, e).get("base_string", "")


## Returns whether a format string with [param key] exists. If
## [param locale] isn't empty it'll validate that locale too.
func has_format_string(key: String, locale: String = "") -> bool:
	locale = NFStringUtils.sanitize_locale(locale)
	return format_strings.get(key, NFDictUtils.EMPTY_DICT).has(locale)


## Returns all format keys that the localized string has.
func get_format_string_formats(key: String, locale_code: String) -> Array[String]:
	var lang_code: String = NFStringUtils.sanitize_locale(locale_code)
	var e: Dictionary = NFDictUtils.EMPTY_DICT
	var format_dict: Dictionary = format_strings.get(key, e).get(lang_code, e).get("format", e)
	var formats: Array[String] = []
	if not format_dict.is_empty():
		formats.assign(format_dict.keys())
	return formats


## Returns the format keys and the possible formats of a given key.
func get_format_string_arguments(key: String, locale_code: String) -> Dictionary[String, Dictionary]:
	var lang_code: String = NFStringUtils.sanitize_locale(locale_code)
	var e: Dictionary = NFDictUtils.EMPTY_DICT
	var format_dict: Variant = format_strings.get(key, e).get(lang_code, e).get("format")
	var return_dict: Dictionary[String, Dictionary] = {}
	
	if typeof(format_dict) == TYPE_DICTIONARY:
		return_dict.assign(format_dict.duplicate(true))
	return return_dict


## Returns strings formatted for NexusForge plugin use.
func get_editor_localized_strings(locale_code: String) -> Dictionary[String, Dictionary]:
	var lang_code: String = NFStringUtils.sanitize_locale(locale_code)
	var data: Dictionary[String, Dictionary] = {}
	
	for key in format_strings:
		if format_strings[key].has(lang_code):
			data[key] = format_strings[key][lang_code].duplicate(true)
	return data


## Sets or creates a localized string with the given key.
func set_format_string(key: String, text: String, locale: String) -> void:
	locale = NFStringUtils.sanitize_locale(locale)
	
	if locale.is_empty():
		return
	
	if not format_strings.has(key):
		format_strings[key] = NFDictUtils.create_typed(TYPE_STRING, TYPE_DICTIONARY)
	var key_dict: Dictionary = format_strings[key]
	
	if not key_dict.has(locale):
		var new_locale: Dictionary[String, Variant] = {
			"base_string": "",
			"format": NFDictUtils.create_typed(TYPE_STRING, TYPE_DICTIONARY)}
		key_dict[locale] = new_locale
	var locale_dict: Dictionary = key_dict[locale]
	locale_dict["base_string"] = text


## Checks if the format key exists in the given key and locale. If it doesn't it'll
## create it. Returns true if the entry was created or already existed.
func validate_format_string_format(key: String, locale: String, format: String) -> bool:
	locale = NFStringUtils.sanitize_locale(locale)
	
	if not NFDictUtils.has_nested_path(format_strings, [key, locale, "format"]):
		return false
	
	if not format_strings[key][locale]["format"].has(format):
		format_strings[key][locale]["format"][format] = {
			"cases": NFDictUtils.create_typed(TYPE_STRING, TYPE_STRING),
			"default": ""}
	else:
		if not format_strings[key][locale]["format"][format].has("cases"):
			format_strings[key][locale]["format"][format]["cases"] = NFDictUtils.create_typed(TYPE_STRING, TYPE_STRING)
		if not format_strings[key][locale]["format"][format].has("default"):
			format_strings[key][locale]["format"][format]["default"] = ""
	
	return true


## Sets the [param case] for the [param locale] on the [param format] in the
## specified [param key] to [param value].
func set_format_string_case(key: String, locale: String, format: String, case: String, value: String) -> void:
	locale = NFStringUtils.sanitize_locale(locale)
	
	if locale.is_empty() or not format_strings.has(key):
		return
	
	if not format_strings[key].has(locale):
		format_strings[key][locale] = {
			"base_string": "",
			"format": NFDictUtils.create_typed(TYPE_STRING, TYPE_DICTIONARY)}
	
	if not format_strings[key][locale]["format"].has(format):
		format_strings[key][locale]["format"][format] = {
			"default": "",
			"cases": NFDictUtils.create_typed(TYPE_STRING, TYPE_STRING)}
	
	NFDictUtils.set_nested_value(
			format_strings,
			[key, locale, "format", format, "cases", case],
			value)


## Gets the [param case] in the [param locale] on the [param format]
## in the specified [param key].[br]
## Returns an empty string if not found.
func get_format_string_case(key: String, locale: String, format: String, case: String) -> String:
	locale = NFStringUtils.sanitize_locale(locale)
	return NFDictUtils.get_nested_value(
			format_strings,
			[key, locale, "format", format, "cases", case],
			"",
			true)


## Returns an array containing all the cases (not their results) of a specified
## [param format] of the [param locale] from the specified [param key].
func get_format_string_cases(key: String, locale: String, format: String) -> Array[String]:
	locale = NFStringUtils.sanitize_locale(locale)
	var cases: Array[String] = []
	
	if NFDictUtils.has_nested_path(format_strings, [key, locale, "format", format, "cases"]):
		cases.assign(format_strings[key][locale]["format"][format]["cases"].keys())
	return cases


## Sets the default case from a localized string with the given key.
func set_format_string_default_case(key: String, locale: String, format: String, default_text: String) -> void:
	locale = NFStringUtils.sanitize_locale(locale)
	
	if locale.is_empty() or not format_strings.has(key):
		return
	
	if not format_strings[key].has(locale):
		format_strings[key][locale] = {
			"base_string": "",
			"format": NFDictUtils.create_typed(TYPE_STRING, TYPE_DICTIONARY)}
	
	if not format_strings[key][locale]["format"].has(format):
		format_strings[key][locale]["format"][format] = {
			"default": "",
			"cases": NFDictUtils.create_typed(TYPE_STRING, TYPE_STRING)}
	
	NFDictUtils.set_nested_value(
			format_strings,
			[key, locale, "format", format, "default"],
			default_text)


## Returns the default case from a localized string with the given key.
func get_format_string_default_case(key: String, locale: String, argument: String) -> String:
	locale = NFStringUtils.sanitize_locale(locale)
	return NFDictUtils.get_nested_value(
			format_strings,
			[key, locale, "format", argument, "default"],
			"")


## Erases a [param format_key] and all its cases on the given [param key]
## from the given [param locale].
func erase_format_string_format(key: String, locale: String, format_key: String) -> void:
	locale = NFStringUtils.sanitize_locale(locale)
	if NFDictUtils.has_nested_path(format_strings, [key, locale, "format"]):
		format_strings[key][locale]["format"].erase(format_key)


## Erases the specific [param case] of the [param format_key] of the specified
## [param locale] in the [param key].
func erase_format_string_case(key: String, locale: String, format_key: String, case: String) -> bool:
	locale = NFStringUtils.sanitize_locale(locale)
	if NFDictUtils.has_nested_path(format_strings, [key, locale, "format", format_key, "cases"]):
		return format_strings[key][locale]["format"][format_key]["cases"].erase(case)
	return false


## Clears the list of custom cases from the given key.
func clear_format_string_cases(key: String, locale: String, format: String) -> void:
	locale = NFStringUtils.sanitize_locale(locale)
	var cases = NFDictUtils.get_nested_value(
			format_strings,
			[key, locale, "format", format, "cases"])
	
	if typeof(cases) == TYPE_DICTIONARY:
		cases.clear()


## Returns all the registered node uuids.
func get_node_uuids() -> Array:
	return node_data.keys()


## Returns all the registered frames uuids.
func get_frames_uuids() -> Array:
	return node_frames.keys()


## Gets the node data. If it contains localized data then [param locale]
## will be used to integrate the localization data. Mainly used by the
## graph editor to set node's data.
func get_node_data(node_uuid: StringName, locale: String = "") -> Dictionary:
	if not node_data.has(node_uuid):
		return {}
	
	var base_data: Dictionary = node_data[node_uuid].duplicate(true)
	var metadata_merge: Dictionary = {}
	
	match base_data["type"]:
		NodeType.DIALOG:
			metadata_merge = {
				"dialog_text": get_text_entry(node_uuid, locale)}
		NodeType.CHOICES:
			var options_translated: Array[String] = []
			options_translated.assign(get_choices_entry(node_uuid, locale))
			var target_size: int = base_data["metadata"]["choices"].size()
	
			if options_translated.size() != target_size:
				NFPluginGameHandler._log_msg(
						"discourse - editor",
						"Choice data size of node '%s' is different from the localization data of locale '%s'. Data size: %d, locale size: %d" % [base_data["name"], locale, target_size, options_translated.size()],
						NFPluginGameHandler._LogLevel.WARNING)
				
				options_translated.resize(target_size)
	
			var idx: int = -1
			for option_translated in options_translated:
				idx += 1
				base_data["metadata"]["choices"][idx]["text"] = option_translated
		NodeType.LOCALIZED_TEXT:
			metadata_merge = {
				"text": get_text_entry(node_uuid, locale)}
	
	if not metadata_merge.is_empty():
		base_data["metadata"].merge(metadata_merge, true)
	
	return base_data


## Gets the text of a node with [param node_uuid] of a specific [param locale].
## If the node isn't of a type that supports text or it is not found it'll
## return [param fallback].
func get_text_entry(node_uuid: StringName, locale: String, fallback: String = "[ENTRY NOT FOUND]") -> String:
	locale = NFStringUtils.sanitize_locale(locale)
	
	if not localization.has(node_uuid) or localization[node_uuid]["type"] != LocalizationType.TEXT:
		return fallback
	
	var e: Dictionary = NFDictUtils.EMPTY_DICT
	var source_dict: Dictionary = localization[node_uuid]
	
	var localized: bool = node_data.get(node_uuid, e).get("metadata", e).get("localized", true)
	
	if localized:
		var data_source: Dictionary = source_dict.get("locales", e)
		var data: String = data_source.get(locale, fallback)
		return data
	else:
		var data: String = source_dict.get("unlocalized", fallback)
		return data


## Gets the array of choices of a node with [param node_uuid] of a specific [param locale].
## If the node isn't of a type that supports choices or it is not found it'll
## return [param fallback].
func get_choices_entry(node_uuid: StringName, locale: String = "", fallback: Array = ["[ENTRY NOT FOUND]"]) -> Array[String]:
	var e: Dictionary = NFDictUtils.EMPTY_DICT
	
	locale = NFStringUtils.sanitize_locale(locale)
	var return_array: Array[String] = []
	
	if not localization.has(node_uuid) or localization[node_uuid]["type"] != LocalizationType.CHOICES:
		return_array.assign(fallback)
		return return_array
	
	var localized: bool = node_data.get(
			node_uuid, e).get("metadata", e).get("localized", true)
	
	var base_array: Array[String] = []
	
	if localized:
		if localization.get(node_uuid, e).get("locales", e).has(locale):
			var data: Variant = localization[node_uuid]["locales"][locale]
			if typeof(data) == TYPE_PACKED_STRING_ARRAY:
				base_array.assign(data)
	else:
		if localization.get(node_uuid, NFDictUtils.EMPTY_DICT).has("unlocalized"):
			var data: Variant = localization[node_uuid]["unlocalized"]
			if typeof(data) == TYPE_PACKED_STRING_ARRAY:
				base_array.assign(data)
	
	return base_array


## Sets the locale for text (Dialogs & localized text nodes). Passing [code]""[/code]
## on [param locale] will set the text as unlocalized, meaning that the text will
## be the same on all localizations.[br]
## Note: Switching from a localized to an unlocalized node will clear the localization
## data completely and viceversa.
func set_dialog_text(uuid: StringName, text: String, locale: String = "") -> void:
	locale = NFStringUtils.sanitize_locale(locale)
	var localization_level: Dictionary = localization.get_or_add(uuid, {"type": LocalizationType.TEXT, "unlocalized": "", "locales": {}})
	
	if localization_level["type"] != LocalizationType.TEXT:
		return
	
	if locale.is_empty():
		localization_level["unlocalized"] = text
		localization_level["locales"].clear()
	else:
		localization_level["unlocalized"] = ""
		localization_level["locales"][locale] = text


## Sets ALL the choices for an option node. Passing an empty string on [param locale]
## will set the options as unlocalized.[br]
## Note: Switching from a localized to an unlocalized node will clear the localization
## data completely and viceversa.
func set_choices_array(uuid: StringName, options: Array, locale: String = "") -> void:
	# --- Data validation ---
	locale = NFStringUtils.sanitize_locale(locale)
	var valid_options: PackedStringArray
	for option in options:
		var opt_type: int = typeof(option)
		if opt_type == TYPE_STRING:
			valid_options.append(option)
		else:
			NFPluginGameHandler._log_msg(
				"discourse",
				"Incorrect type for choice assing. Provided type: " + type_string(opt_type),
				NFPluginGameHandler._LogLevel.ERROR)
			valid_options.append("[INVALID FORMAT]")
	# -----------------------
	
	if not localization.has(uuid):
		var new_entry: Dictionary[String, Variant] = {
			"type": LocalizationType.CHOICES,
			"unlocalized": PackedStringArray(),
			"locales": NFDictUtils.create_typed(TYPE_STRING, TYPE_PACKED_STRING_ARRAY)}
		localization[uuid] = new_entry
	
	var localization_level: Dictionary = localization[uuid]
	
	if localization_level["type"] != LocalizationType.CHOICES:
		return
	
	if locale.is_empty():
		localization_level["unlocalized"] = valid_options
		localization_level["locales"].clear()
	else:
		localization_level["unlocalized"].clear()
		localization_level["locales"][locale] = valid_options


## Sets a single choice for an option node. Specifically the choice with index
## [param option_index]. To set an unlocalized choice pass [code]common[/code]
## as the language argument. No region is needed when doing an unlocalized
## option.
func set_choice_text(uuid: StringName, option_index: int, text: String, locale: String = "") -> void:
	if not localization.has(uuid) or localization[uuid]["type"] != LocalizationType.CHOICES:
		return
	
	var base_level: Dictionary = localization[uuid]
	
	if locale.is_empty():
		if not base_level.has("unlocalized") or typeof(base_level["unlocalized"]) != TYPE_PACKED_STRING_ARRAY:
			return
		
		var items: PackedStringArray = base_level["unlocalized"]
		var arr_size: int = items.size()
		if arr_size == 0:
			return
		var max_index: int = arr_size - 1
		if not NFMath.is_between(option_index, -arr_size, max_index):
			return
		
		items[option_index] = text
	else:
		locale = NFStringUtils.sanitize_locale(locale)
		if not base_level["locales"].has(locale) or typeof(base_level["locales"][locale]) != TYPE_PACKED_STRING_ARRAY:
			return
		
		var locale_array: PackedStringArray = base_level["locales"][locale]
		var arr_size: int = locale_array.size()
		if arr_size == 0:
			return
		
		var max_index: int = arr_size - 1
		if not NFMath.is_between(option_index, -arr_size, max_index):
			return
		
		locale_array[option_index] = text


## Registers a frame.[br]
## [b]Note:[/b] Always register frames before registering nodes.
func register_frame(uuid: String, title: String, position: Vector2, size: Vector2, tint: Color) -> void:
	node_frames[uuid] = {
		"title": title,
		"position": position,
		"size": size,
		"tint_color": tint,
		"nodes": Array([], TYPE_STRING, &"", null)}


## Returns the registered frame data.
func get_frame_data(uuid: String) -> Dictionary:
	if node_frames.has(uuid):
		return node_frames[uuid]
	return {
		"title": "",
		"position": Vector2.ZERO,
		"size": Vector2(200.0, 200.0),
		"tint_color": Color(0.0, 0.0, 0.0, 0.588),
		"nodes": Array([], TYPE_STRING, &"", null)}


## Registers a node with an uuid and the data.[br]
## Registering a node will NOT include localizable data like dialog text or options.
## Use [method set_localization_text], [method set_unlocalized_text],
## [method set_localization_choices], [method set_unlocalized_choices] and
## [method update_localization_choice] to save localizable data.
func register_node(node: DiscourseGraphNode, parent_frame: String = "") -> void:
	var uuid: StringName = node.get_node_uuid()
	var data: Dictionary = node._get_node_data()
	
	if node.node_type == NodeType.DIALOG:
		data["metadata"].erase("dialog_text")
	elif node.node_type == NodeType.CHOICES:
		for choice in data["metadata"]["choices"]:
			choice.erase("text")
	elif node.node_type == NodeType.LOCALIZED_TEXT:
		data["metadata"].erase("text")
	elif node.node_type == NodeType.ENTRY:
		entry_node = uuid
	
	node_data[uuid] = data
	
	if not parent_frame.is_empty() and node_frames.has(parent_frame) and not node_frames[parent_frame]["nodes"].has(uuid):
		node_frames[parent_frame]["nodes"].append(uuid)


## Removes the [param node_uuid]'s node and localization data.
func remove_node(node_uuid: StringName) -> void:
	node_data.erase(node_uuid)
	localization.erase(node_uuid)


## Removes the frame [param frame_uuid] data.
func remove_frame(frame_uuid: StringName) -> void:
	node_frames.erase(frame_uuid)


## Clears the resource.
func clear() -> void:
	scroll_offset = Vector2.ZERO
	zoom = 1.0
	localization.clear()
	node_frames.clear()
	node_data.clear()
	format_strings.clear()


## Grabs all data, strips it of the editor information and returns its
## [DiscourseDialog] version for release. Intended ONLY to be used by the 
## NexusForge export plugin.
func convert_for_release(api_methods: Dictionary[StringName, Dictionary]) -> DiscourseDialog:
	var available_methods: Dictionary = preload("res://addons/nexus_forge/discourse/nodes/method_call_node.gd").get_user_methods()
	var available_signals: Dictionary = preload("res://addons/nexus_forge/discourse/nodes/signal_node.gd").get_user_signals()
	
	var release_dialog: DiscourseDialog = DiscourseDialog.new()
	var uuid_translator: Dictionary[StringName, StringName] = {}
	
	release_dialog.entry_node = node_data[entry_node]["name"] if node_data.has(entry_node) else &""
	
	# UUID(Anchor pointer): UUID(Anchor Target)
	# Example "123"(anchor pointer uuid) -> "456"(Anchor) -> "789"(Anchor connection)
	# anchor_nodes["123"] = "789"
	# This is to skip the anchor nodes as they are only a visual helper for the editor
	# on the release files, anchor nodes have no use.
	var anchor_nodes: Dictionary[StringName, StringName] = {}
	
	# NFUUID(merger_id): NFUUID(merger_next_node)
	var dialog_mergers: Dictionary[StringName, StringName] = {}
	
	var target_finder: RefCounted = preload("res://addons/nexus_forge/discourse/exporter_target.gd").new()
	
	var node_uuids: Array[StringName] = []
	node_uuids.assign(node_data.keys())
	
	for node_uuid in node_uuids:
		var metadata: Dictionary = node_data[node_uuid]["metadata"]
		uuid_translator[node_uuid] = node_data[node_uuid]["name"]
		if node_data[node_uuid]["type"] == NodeType.SHORTCUT_IN:
			var target_node: StringName = &""
			if not metadata["anchor_target"].is_empty():
				target_node = node_data[metadata["anchor_target"]]["output_connections"]["next_node"]["target_node_uuid"]
			anchor_nodes[node_uuid] = target_node
		elif node_data[node_uuid]["type"] == NodeType.DIALOG_MERGE:
			var target_node: StringName = &""
			if not node_data[node_uuid]["output_connections"]["next_node"]["target_node_uuid"].is_empty():
				target_node = StringName(node_data[node_uuid]["output_connections"]["next_node"]["target_node_uuid"])
			dialog_mergers[node_uuid] = target_node
		else:
			continue
	
	target_finder.anchor_nodes.assign(anchor_nodes)
	target_finder.dialog_mergers.assign(dialog_mergers)
	target_finder.uuid_to_id_conversions.assign(uuid_translator)
	
	for node_id in node_uuids:
		var export_data: Dictionary[String, Variant] = {
			"node_type": node_data[node_id]["type"]}
		var metadata: Dictionary = node_data[node_id]["metadata"]
		
		match node_data[node_id]["type"]:
			NodeType.ENTRY:
				export_data["next_node"] = target_finder.get_target(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"])
			NodeType.DIALOG:
				var character_settings: Dictionary = {
					"display_name": &"",
					"portrait_id": &""}
				
				var dialog_settings: Dictionary = {
					"font_resource": &"",
					"dialog_scene": &"",
					"dialog_speed": &"",
					"metadata": {}}
				
				if not node_data[node_id]["input_connections"]["character_settings"]["target_node_uuid"].is_empty():
					var character_settings_data: Dictionary = node_data[node_data[node_id]["input_connections"]["character_settings"]["target_node_uuid"]]
					
					if not character_settings_data["input_connections"]["display_name"]["target_node_uuid"].is_empty():
						character_settings["display_name"] = target_finder.get_target(character_settings_data["input_connections"]["display_name"]["target_node_uuid"])
					
					if not character_settings_data["input_connections"]["portrait_id"]["target_node_uuid"].is_empty():
						character_settings["portrait_id"] = target_finder.get_target(character_settings_data["input_connections"]["portrait_id"]["target_node_uuid"])
				
				if not node_data[node_id]["input_connections"]["dialog_settings"]["target_node_uuid"].is_empty():
					var dialog_settings_data: Dictionary = node_data[node_data[node_id]["input_connections"]["dialog_settings"]["target_node_uuid"]]
					
					if not dialog_settings_data["input_connections"]["font_resource"]["target_node_uuid"].is_empty():
						dialog_settings["font_resource"] = target_finder.get_target(dialog_settings_data["input_connections"]["font_resource"]["target_node_uuid"])
					
					if not dialog_settings_data["input_connections"]["dialog_scene"]["target_node_uuid"].is_empty():
						dialog_settings["dialog_scene"] = target_finder.get_target(dialog_settings_data["input_connections"]["dialog_scene"]["target_node_uuid"])
					
					if not dialog_settings_data["input_connections"]["dialog_speed"]["target_node_uuid"].is_empty():
						dialog_settings["dialog_speed"] = target_finder.get_target(dialog_settings_data["input_connections"]["dialog_speed"]["target_node_uuid"])
				
					if not dialog_settings_data["input_connections"]["metadata"]["target_node_uuid"].is_empty():
						var dialog_metadata_node: Dictionary = node_data[dialog_settings_data["input_connections"]["metadata"]["target_node_uuid"]]
						var dialog_metadata: Dictionary = dialog_metadata_node["metadata"]
						for meta_field in dialog_metadata["metadata_connections"]:
							if not dialog_metadata_node["input_connections"].has(meta_field["id"]):
								NFPluginGameHandler._log_msg(
										"export - dialog",
										"Metadata node '%s' on file '%s' registered metadata with ID '%s' on port %d but the port isn't available. Setting to null." % [dialog_metadata_node["name"], resource_path, meta_field["id"], meta_field["port"]],
										NFPluginGameHandler._LogLevel.ERROR)
								dialog_settings["metadata"][meta_field["id"]] = null
							else:
								dialog_settings["metadata"][meta_field["id"]] = target_finder.get_target(dialog_metadata_node["input_connections"][meta_field["id"]]["target_node_uuid"])
				
				export_data["character_id"] = metadata["character_id"]
				export_data["persist"] = metadata["persist"]
				export_data["character_settings"] = character_settings
				export_data["dialog_settings"] = dialog_settings
				export_data["text_source"] = target_finder.get_target(node_data[node_id]["input_connections"]["dialog_text_source"]["target_node_uuid"])
				export_data["next_node"] = target_finder.get_target(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"])
			NodeType.CHOICES:
				var options: Array[Dictionary] = []
				for option:Dictionary in metadata["choices"]:
					var new_option: Dictionary[String, Variant] = {
						"next_node": target_finder.get_target(StringName(option["output_connections"]["next_node"]["target_node_uuid"])),
						"settings": {
							"available": &"",
							"unlocked": &"",
							"lock_hint": &"",
							"metadata": {}}}
					
					if not option["input_connections"]["settings"]["target_node_uuid"].is_empty():
						var option_settings: Dictionary = node_data[option["input_connections"]["settings"]["target_node_uuid"]]
						if not option_settings["input_connections"]["option_available"]["target_node_uuid"].is_empty():
							new_option["settings"]["available"] = target_finder.get_target(option_settings["input_connections"]["option_available"]["target_node_uuid"])
						
						if not option_settings["input_connections"]["option_unlocked"]["target_node_uuid"].is_empty():
							new_option["settings"]["unlocked"] = target_finder.get_target(option_settings["input_connections"]["option_unlocked"]["target_node_uuid"])
		
						if not option_settings["input_connections"]["locked_hint"]["target_node_uuid"].is_empty():
							new_option["settings"]["lock_hint"] = target_finder.get_target(option_settings["input_connections"]["locked_hint"]["target_node_uuid"])
					
						if not option_settings["input_connections"]["metadata"]["target_node_uuid"].is_empty():
							var dialog_metadata_node: Dictionary = node_data[option_settings["input_connections"]["metadata"]["target_node_uuid"]]
							var dialog_metadata: Dictionary = dialog_metadata_node["metadata"]
							for meta_field in dialog_metadata["metadata_connections"]: 
								if not dialog_metadata_node["input_connections"].has(meta_field["id"]):
									NFPluginGameHandler._log_msg(
											"export - dialog",
											"Metadata node '%s' on file '%s' registered metadata with ID '%s' on port %d but the port isn't available. Setting to null." % [dialog_metadata_node["name"], resource_path, meta_field["id"], meta_field["port"]],
											NFPluginGameHandler._LogLevel.ERROR)
									new_option["settings"]["metadata"][meta_field["id"]] = null 
								else:
									new_option["settings"]["metadata"][meta_field["id"]] = target_finder.get_target(dialog_metadata_node["input_connections"][meta_field["id"]]["target_node_uuid"])
					
					options.append(new_option)
				export_data["choices"] = options
			NodeType.BRANCH:
				export_data["result"] = target_finder.get_target(node_data[node_id]["input_connections"]["path_direction"]["target_node_uuid"])
				export_data["case_true"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node_true"]["target_node_uuid"]))
				export_data["case_false"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node_false"]["target_node_uuid"]))
			NodeType.CONDITION_SELECT:
				export_data["result"] = target_finder.get_target(node_data[node_id]["input_connections"]["result"]["target_node_uuid"])
				export_data["true_value"] = target_finder.get_target(StringName(node_data[node_id]["input_connections"]["true_value"]["target_node_uuid"]))
				export_data["false_value"] = target_finder.get_target(StringName(node_data[node_id]["input_connections"]["false_value"]["target_node_uuid"]))
			NodeType.COMPARATION:
				export_data["operator"] = metadata["operator"]
				export_data["value_a"] = target_finder.get_target(node_data[node_id]["input_connections"]["node_a"]["target_node_uuid"])
				export_data["value_b"] = target_finder.get_target(node_data[node_id]["input_connections"]["node_b"]["target_node_uuid"])
			NodeType.EVENT:
				var var_val: StringName = StringName(node_data[node_id]["input_connections"]["variable_value"]["target_node_uuid"])
				export_data["value"] = target_finder.get_target(var_val)
				
				if not node_data[node_id]["input_connections"]["callable"]["target_node_uuid"].is_empty():
					var callable_uuid: StringName = node_data[node_id]["input_connections"]["callable"]["target_node_uuid"]
					if available_methods.has(node_data[callable_uuid]["metadata"]["method"]):
						export_data["callable"] = target_finder.get_target(node_data[node_id]["input_connections"]["callable"]["target_node_uuid"])
					else:
						export_data["callable"] = &""
						NFPluginGameHandler._log_msg(
								"export - dialog",
								"[DISCOURSE] Warning: Issue when exporting %s. Event %s calls an inexistent method." % [
									resource_path,
									node_data[node_id]["name"]],
								NFPluginGameHandler._LogLevel.ERROR)
				else:
					export_data["callable"] = &""
				
				if not node_data[node_id]["input_connections"]["signal"]["target_node_uuid"].is_empty():
					var signal_uuid: StringName = node_data[node_id]["input_connections"]["signal"]["target_node_uuid"]
					if available_signals.has(node_data[signal_uuid]["metadata"]["signal"]):
						export_data["signal"] = target_finder.get_target(signal_uuid)
					else:
						export_data["signal"] = &""
						NFPluginGameHandler._log_msg(
								"export - dialog",
								"[DISCOURSE] Warning: Issue when exporting %s. Event %s emits an inexistent signal." % [
									resource_path,
									node_data[node_id]["name"]],
								NFPluginGameHandler._LogLevel.ERROR)
				else:
					export_data["signal"] = &""
				
				export_data["next_node"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"]))
				
				if var_val.is_empty():
					export_data["variable_path"] = ""
				else:
					var clean_path: String = metadata["variable_path"].strip_edges().simplify_path()
					export_data["variable_path"] = clean_path
			NodeType.MATCH:
				var cases: Array[Dictionary] = []
				
				for case:Dictionary in metadata["cases"]:
					var new_case: Dictionary[String, Variant] = {}
					new_case["value"] = case["value"]
					new_case["next_node"] = target_finder.get_target(StringName(case["output_connections"]["next_node"]["target_node_uuid"]))
					cases.append(new_case)
				
				export_data["case_default"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["default"]["target_node_uuid"]))
				export_data["match_value"] = target_finder.get_target(node_data[node_id]["input_connections"]["match_value_source"]["target_node_uuid"])
				export_data["cases"] = cases
			NodeType.PAUSE:
				export_data["next_node"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"]))
			NodeType.RANDOM:
				var options: Array[Dictionary] = []
				
				for option:Dictionary in metadata["options"]:
					var new_option: Dictionary[String, StringName] = {}
					new_option["target"] = target_finder.get_target(StringName(option["output_connections"]["next_node"]["target_node_uuid"]))
					new_option["weight_override"] = target_finder.get_target(option["input_connections"]["weight"]["target_node_uuid"])
					options.append(new_option)
				
				export_data["weight_override"] = target_finder.get_target(node_data[node_id]["input_connections"]["default_weight"]["target_node_uuid"])
				export_data["choices"] = options
			NodeType.TYPE_GUARD:
				export_data["value"] = target_finder.get_target(node_data[node_id]["input_connections"]["value"]["target_node_uuid"])
				export_data["fallback"] = metadata["fallback_value"]
			NodeType.SIGNAL:
				var arguments: Array[StringName] = []
				for argument:Dictionary in metadata["arguments"]:
					var target_uuid: StringName = StringName(argument["target_node_uuid"])
					if not target_uuid.is_empty():
						arguments.append(target_finder.get_target(target_uuid))
					else:
						arguments.append(&"")
				export_data["signal"] = StringName(metadata["signal"])
				export_data["arguments"] = arguments
			NodeType.CALLABLE:
				var method_id: StringName = StringName(metadata["method"])
				
				if not method_id.is_empty():
					var default_args_size: int = 0
					
					if not api_methods.has(method_id):
						NFPluginGameHandler._log_msg(
								"export - dialog",
								"Callable node '%s' on file '%s' calls for an inexisting method '%s'" % [node_data[node_id]["name"], resource_path, method_id],
								NFPluginGameHandler._LogLevel.ERROR)
					else:
						default_args_size = api_methods[method_id]["default_args"].size()
					
					var arguments: Array[StringName] = []
					var arg_idx: int = -1
					var skipped_previous: bool = false
					for argument:Dictionary in metadata["arguments"]:
						arg_idx += 1
						var t_uuid: StringName = StringName(argument["target_node_uuid"])
						
						if not t_uuid.is_empty():
							arguments.append(target_finder.get_target(t_uuid))
							if skipped_previous:
								NFPluginGameHandler._log_msg(
										"export - dialog",
										"Callable node '%s' on file '%s' passed an argument on index %d but a previous index doesn't have a value." % [node_data[node_id]["name"], resource_path, arg_idx],
										NFPluginGameHandler._LogLevel.ERROR)
						else:
							arguments.append(&"")
							skipped_previous = true
							if default_args_size <= arg_idx:
								NFPluginGameHandler._log_msg(
										"export - dialog",
										"Callable node '%s' on file '%s' is missing a required argument value on index %d" % [node_data[node_id]["name"], resource_path, arg_idx],
										NFPluginGameHandler._LogLevel.ERROR)
					export_data["method"] = method_id
					export_data["arguments"] = arguments
				else:
					export_data["method"] = &""
					export_data["arguments"] = NFArrayUtils.create_typed(TYPE_STRING_NAME)
			NodeType.CALLABLE_RETURN:
				var method_id: StringName = StringName(metadata["method"])
				if not method_id.is_empty():
					var default_args_size: int = 0
					
					if not api_methods.has(method_id):
						NFPluginGameHandler._log_msg(
								"export - dialog",
								"[DISCOURSE] Callable node '%s' on file '%s' calls for inexisting method '%s'" % [
									node_data[node_id]["name"],
									resource_path,
									method_id],
								NFPluginGameHandler._LogLevel.ERROR)
					else:
						default_args_size = api_methods[method_id]["default_args"].size()
					
					var arguments: Array[StringName] = []
					var arg_idx: int = -1
					var skipped_previous: bool = false
					for argument:Dictionary in metadata["arguments"]:
						arg_idx += 1
						var t_uuid: StringName = StringName(argument["target_node_uuid"])
						if not argument["target_node_uuid"].is_empty():
							arguments.append(target_finder.get_target(t_uuid))
							if skipped_previous:
								NFPluginGameHandler._log_msg(
										"export - dialog",
										"[DISCOURSE] Callable node '%s' on file '%s' passed an argument on index %d but a previous index doesn't have a value." % [
											node_data[node_id]["name"],
											resource_path,
											arg_idx],
										NFPluginGameHandler._LogLevel.ERROR)
						else:
							arguments.append(&"")
							skipped_previous = true
							if default_args_size <= arg_idx:
								NFPluginGameHandler._log_msg(
										"export - dialog",
										"[DISCOURSE] Callable node '%s' on file '%s' is missing a required argument value on index %d" % [
											node_data[node_id]["name"],
											resource_path,
											arg_idx],
										NFPluginGameHandler._LogLevel.ERROR)
					export_data["method"] = method_id
					export_data["arguments"] = arguments
				else:
					export_data["method"] = &""
					export_data["arguments"] = NFArrayUtils.create_typed(TYPE_STRING_NAME)
			NodeType.VARIABLE_GET:
				var meta_path: String = ""
				if metadata.has("variable_path"):
					meta_path = metadata["variable_path"].strip_edges().simplify_path()
				else:
					NFPluginGameHandler._log_msg(
							"export - dialog",
							"[DISCOURSE] Node %s has missing Blackboard data path. Using empty path instead" % node_data[node_id]["name"],
							NFPluginGameHandler._LogLevel.WARNING)
				
				export_data["path"] = meta_path
			NodeType.RANDOM_VALUE:
				export_data["random_type"] = metadata["mode"]
				export_data["min_value"] = metadata["values"]["base"]
				export_data["max_value"] = metadata["values"]["max"]
				export_data["min_override"] = target_finder.get_target(node_data[node_id]["input_connections"]["base_value"]["target_node_uuid"])
				export_data["max_override"] = target_finder.get_target(node_data[node_id]["input_connections"]["max_value"]["target_node_uuid"])
			NodeType.RESOURCE:
				export_data["resource_path"] = metadata["resource_path"]
			NodeType.DATA_EVENT:
				var var_val: StringName = StringName(node_data[node_id]["input_connections"]["variable_value"]["target_node_uuid"])
				export_data["value"] = target_finder.get_target(var_val)
				
				if not node_data[node_id]["input_connections"]["callable"]["target_node_uuid"].is_empty():
					var callable_uuid: StringName = node_data[node_id]["input_connections"]["callable"]["target_node_uuid"]
					if available_methods.has(node_data[callable_uuid]["metadata"]["method"]):
						export_data["callable"] = target_finder.get_target(callable_uuid)
					else:
						export_data["callable"] = &""
						NFPluginGameHandler._log_msg(
								"export - dialog",
								"[DISCOURSE] Warning: Issue when exporting %s. Data event %s calls an inexistent method." % [
									resource_path,
									node_data[node_id]["name"]],
								NFPluginGameHandler._LogLevel.ERROR)
				else:
					export_data["callable"] = &""
				
				if not node_data[node_id]["input_connections"]["signal"]["target_node_uuid"].is_empty():
					var signal_uuid: StringName = node_data[node_id]["input_connections"]["signal"]["target_node_uuid"]
					if available_signals.has(node_data[signal_uuid]["metadata"]["signal"]):
						export_data["signal"] = target_finder.get_target(signal_uuid)
					else:
						export_data["signal"] = &""
						NFPluginGameHandler._log_msg(
								"export - dialog",
								"[DISCOURSE] Warning: Issue when exporting %s. Data event %s emits an inexistent signal." % [
									resource_path,
									node_data[node_id]["name"]],
								NFPluginGameHandler._LogLevel.ERROR)
				else:
					export_data["signal"] = &""
				
				export_data["data_source"] = target_finder.get_target(node_data[node_id]["input_connections"]["data_input"]["target_node_uuid"])
				if var_val.is_empty():
					export_data["variable_path"] = ""
				else:
					var meta_path: String = ""
					if metadata.has("variable_path"):
						meta_path = metadata["variable_path"].strip_edges().simplify_path()
					
					export_data["variable_path"] = meta_path
			NodeType.LOCALIZED_TEXT:
				pass
			NodeType.VALUE:
				export_data["value"] = metadata["value"]
			NodeType.TRAVEL_TO:
				export_data["travel_target"] = target_finder.get_target(StringName(metadata["travel_target"]))
				export_data["next_node"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"]))
			NodeType.TRAVEL_TARGET:
				export_data["next_node"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"]))
			_:
				pass
		
		release_dialog.node_logic[uuid_translator[node_id]] = export_data
	return release_dialog


## Generates and returns all NEW locale files. Inteded ONLY to be used by the 
## NexusForge export plugin.
func generate_localization_files(localization_id: String, base_path: String, filename: String, localization_groups: Dictionary = {}) -> Array[Dictionary]:
	# Should never be the case, but just in case
	if resource_path.is_empty():
		NFPluginGameHandler._log_msg(
				"export - dialog",
				"Tried to generate localization of a file with no path.",
				NFPluginGameHandler._LogLevel.WARNING)
		return []
	
	var new_files: Array[Dictionary] = []
	#var md5_hash: String = resource_path.to_lower().md5_text().substr(0, 12)
	var md5_fragment: String = filename.substr(0, 2)
	var used_locales: Dictionary[String, Variant] = {}
	
	# Given how Discourse works, there is ALWAYS a base language.
	for language in locale_map.keys():
		var lang_key: String = TranslationServer.standardize_locale(language.to_lower())
		if lang_key.is_empty():
			continue
		var lang_path: String = NFStringUtils.make_path(
				[base_path,
				lang_key,
				md5_fragment,
				filename])
		
		var lang_file: DiscourseDialogLocale = null
		
		if locale_group.is_empty():
			lang_file = DiscourseDialogLocale.new()
			lang_file.locale = lang_key
			
			new_files.append({
				"file": lang_file,
				"path": lang_path})
		elif NFDictUtils.has_nested_path(localization_groups, [locale_group, lang_key]):
			lang_file = localization_groups[locale_group][lang_key]
		else:
			lang_file = DiscourseDialogLocale.new()
			lang_file.locale = lang_key
			NFDictUtils.set_nested_value(
						localization_groups,
						[locale_group, lang_key],
						lang_file)
			
			new_files.append({
				"file": lang_file,
				"path": lang_path})
		
		_add_locale_data(lang_file, localization_id, lang_key)
		used_locales[lang_key] = null
		
		for region_code in locale_map[lang_key].keys():
			var locale_key: String = TranslationServer.standardize_locale(lang_key + "_" + region_code.to_upper())
			if locale_key.is_empty():
				continue
			
			var lang_locale_file: DiscourseDialogLocale = null
			var locale_path: String = NFStringUtils.make_path([
				base_path, locale_key, md5_fragment, filename])
			
			if not locale_group.is_empty() and NFDictUtils.has_nested_path(localization_groups, [locale_group, locale_key]):
				lang_locale_file = localization_groups[locale_group][locale_key]
			else:
				lang_locale_file = DiscourseDialogLocale.new()
				lang_locale_file.locale = locale_key
				NFDictUtils.set_nested_value(
						localization_groups,
						[locale_group, locale_key],
						lang_locale_file)
				
				new_files.append({
					"file": lang_locale_file,
					"path": locale_path})
			
			_add_locale_data(lang_locale_file, localization_id, locale_key)
			used_locales[locale_key] = null
	
	# Check to warn in case that file has more localization data than map.
	
	var extra_data_warned: bool = false
	
	for localization_key in localization.keys():
		if not node_data.has(localization_key) or not NFDictUtils.get_nested_value(node_data[localization_key], ["metadata", "localized"], false, true):
			continue
		
		var localization_locales = NFDictUtils.get_nested_value(localization, [localization_key, "locales"], {})
		if typeof(localization_locales) != TYPE_DICTIONARY:
			continue
		var localization_keys = localization_locales.keys()
		
		if not used_locales.has_all(localization_keys):
			NFPluginGameHandler._log_msg(
					"export - dialog",
					"Localization data of file '%s' contains more localization data than the resource is set for.\nUsed locales: %s\nExisting locales: %s" % [resource_path, used_locales.keys(), localization_keys],
					NFPluginGameHandler._LogLevel.WARNING)
			extra_data_warned = true
			break
	
	if extra_data_warned:
		return new_files
	
	for string_key in format_strings:
		var used_string_locales = format_strings[string_key].keys()
		if not used_locales.has_all(used_string_locales):
			NFPluginGameHandler._log_msg(
					"export - dialog",
					"Localization data of file '%s' contains more localization data than the resource is set for.\nUsed locales: %s\nExisting locales: %s" % [resource_path, used_locales.keys(), used_string_locales],
					NFPluginGameHandler._LogLevel.WARNING)
			break
	
	return new_files


func _add_locale_data(file: DiscourseDialogLocale, localization_id: StringName, locale: String) -> void:
	var missing_text: String = "" # Leaving empty is good. As data invalidation is performed at runtime.
	var e: Dictionary = NFDictUtils.EMPTY_DICT
	
	for node_uuid in localization.keys():
		if not node_data.has(node_uuid):
			NFPluginGameHandler._log_msg(
					"export - dialog",
					"Orphaned localization with ID '%s'. Skipping." % node_uuid,
					NFPluginGameHandler._LogLevel.WARNING)
			continue
		
		var nodeid: StringName = node_data[node_uuid]["name"]
		var data = localization[node_uuid]
		var localized: bool = NFDictUtils.get_nested_value(
				node_data,
				[node_uuid, "metadata", "localized"],
				false,
				true)
		
		var type_mismatch: bool = _localization_type_mismatch(node_uuid)
		var data_complete: bool = _is_localization_data_complete(data, localized)
		
		if type_mismatch or not data_complete:
			var type: int = node_data[node_uuid]["type"]
			if not data_complete:
				NFPluginGameHandler._log_msg(
						"export - dialog",
						"Incomplete or corrupt data for node with UID '%s' " % node_uuid,
						NFPluginGameHandler._LogLevel.ERROR)
			if type_mismatch:
				NFPluginGameHandler._log_msg(
						"export - dialog",
						"Type mismatch for node & localization with UID '%s' of file %s" % [node_uuid, resource_path],
						NFPluginGameHandler._LogLevel.ERROR)
			
			NFPluginGameHandler._log_msg(
					"export - dialog",
					"Patching data with placeholder entries.",
					NFPluginGameHandler._LogLevel.WARNING)
			
			if type == NodeType.DIALOG or type == NodeType.LOCALIZED_TEXT:
				if not file.localization.has(localization_id):
					file.localization[localization_id] = NFDictUtils.create_typed(TYPE_STRING_NAME, TYPE_DICTIONARY)
				var loc_dict: Dictionary = file.localization[localization_id]
				
				if not loc_dict.has(nodeid):
					loc_dict[nodeid] = NFDictUtils.create_typed(TYPE_STRING, TYPE_STRING)
				var dialog_dict: Dictionary = loc_dict[nodeid]
				
				dialog_dict["dialog"] = missing_text
			elif type == NodeType.CHOICES:
				var choice_size: int = node_data[node_uuid]["metadata"]["choices"].size()
				var choices: PackedStringArray = []
				choices.resize(choice_size)
				for idx in range(choice_size):
					choices[idx] = missing_text
				
				if not file.localization.has(localization_id):
					file.localization[localization_id] = NFDictUtils.create_typed(TYPE_STRING_NAME, TYPE_DICTIONARY)
				var loc_dict: Dictionary = file.localization[localization_id]
				
				if not loc_dict.has(nodeid):
					loc_dict[nodeid] = NFDictUtils.create_typed(TYPE_STRING, TYPE_PACKED_STRING_ARRAY)
				
				var choices_dict: Dictionary = loc_dict[nodeid]
				choices_dict["choices"] = choices
		
		if data["type"] == LocalizationType.TEXT:
			var warn: bool = false
			var text_data: Variant = null
			if localized:
				text_data = data.get("locales", e).get(locale)
			else:
				text_data = data.get("unlocalized")
			warn = typeof(text_data) != TYPE_STRING
			
			if not file.localization.has(localization_id):
				file.localization[localization_id] = NFDictUtils.create_typed(TYPE_STRING_NAME, TYPE_DICTIONARY)
			var locale_dict: Dictionary = file.localization[localization_id]
			
			if not locale_dict.has(nodeid):
				locale_dict[nodeid] = NFDictUtils.create_typed(TYPE_STRING, TYPE_STRING)
			var node_dict: Dictionary = locale_dict[nodeid]
			
			var text_set: String = ""
			
			if localized:
				text_set = data.get("locales", e).get(locale, missing_text)
			else:
				text_set = data.get("unlocalized", missing_text)
			
			if warn:
				if localized:
					NFPluginGameHandler._log_msg(
							"export - dialog",
							"Localization data for node UID '%s' for locale '%s' is missing." % [node_uuid, locale],
							NFPluginGameHandler._LogLevel.WARNING)
				else:
					NFPluginGameHandler._log_msg(
							"export - dialog",
							"Unlocalized data for node UID '%s' is missing." % node_uuid,
							NFPluginGameHandler._LogLevel.WARNING)
		
		elif data["type"] == LocalizationType.CHOICES:
			var data_exists: bool = false
			var choice_size: int = node_data[node_uuid]["metadata"]["choices"].size()
			var base: Array[String] = []
			
			if localized:
				data_exists = data["locales"].has(locale) and typeof(data["locales"][locale]) == TYPE_PACKED_STRING_ARRAY
				if data_exists:
					for idx in range(data["locales"][locale].size()):
						if typeof(data["locales"][locale][idx]) == TYPE_STRING:
							base.append(data["locales"][locale][idx])
						else:
							NFPluginGameHandler._log_msg(
									"export - dialog",
									"Choice with index %d on locale '%s' isn't a string." % [idx, locale],
									NFPluginGameHandler._LogLevel.WARNING)
							base.append("[INVALID STRING]")
				else:
					base.resize(choice_size)
			else:
				data_exists = typeof(data["unlocalized"]) == TYPE_PACKED_STRING_ARRAY
				if data_exists:
					for idx in range(data["unlocalized"].size()):
						if typeof(data["unlocalized"][idx]) == TYPE_STRING:
							base.append(data["unlocalized"][idx])
						else:
							NFPluginGameHandler._log_msg(
									"export - dialog",
									"Choice with index %d on locale '%s' isn't a string." % [idx, locale],
									NFPluginGameHandler._LogLevel.WARNING)
							base.append("[INVALID STRING]")
				else:
					base.resize(choice_size)
			
			if not data_exists:
				if localized:
					NFPluginGameHandler._log_msg(
							"export - dialog",
							"Localization data for node UID '%s' for locale '%s' is missing." % [node_uuid, locale],
							NFPluginGameHandler._LogLevel.WARNING)
				else:
					NFPluginGameHandler._log_msg(
							"export - dialog",
							"Unlocalized data for node UID '%s' is missing." % node_uuid,
							NFPluginGameHandler._LogLevel.WARNING)
				var err_string: String = missing_text
				base.resize(choice_size)
				for idx in range(choice_size):
					base[idx] = err_string
			
			if not file.localization.has(localization_id):
				file.localization[localization_id] = NFDictUtils.create_typed(TYPE_STRING_NAME, TYPE_DICTIONARY)
			var locale_id_dict: Dictionary = file.localization[localization_id]
			
			if not locale_id_dict.has(nodeid):
				locale_id_dict[nodeid] = NFDictUtils.create_typed(TYPE_STRING, TYPE_PACKED_STRING_ARRAY)
			var choices_dict: Dictionary = locale_id_dict[nodeid]
			
			var current_size: int = base.size()
			if choice_size != current_size:
				NFPluginGameHandler._log_msg(
						"export - dialog",
						"Localization choice count on node UID %s differs from data choice count: %d vs %d. Patching to match data size." % [
							node_uuid,
							current_size,
							choice_size],
						NFPluginGameHandler._LogLevel.WARNING)
				base.resize(choice_size)
				if current_size < choice_size:
					NFPluginGameHandler._log_msg(
							"export - dialog",
							"Localization count is smaller. Applying placeholders.",
							NFPluginGameHandler._LogLevel.WARNING)
					for missing_idx in range(current_size, choice_size):
						base[missing_idx] = missing_text
			
			choices_dict["choices"] = PackedStringArray(base)
		
		else:
			NFPluginGameHandler._log_msg(
					"export - dialog",
					"Localization export for node with UID '%s' couldn't define type." % node_uuid,
					NFPluginGameHandler._LogLevel.WARNING)
			var nameless_id = NFDictUtils.get_nested_value(node_data, [node_uuid, "name"])
			if typeof(nameless_id) == TYPE_STRING_NAME:
				NFPluginGameHandler._log_msg(
						"export - dialog",
						"ID for typeless node found: '%s'\"" % str(nameless_id),
						NFPluginGameHandler._LogLevel.WARNING)
	
	for format_key in format_strings.keys():
		if not format_strings[format_key].has(locale) or typeof(format_strings[format_key][locale]) != TYPE_DICTIONARY:
			NFPluginGameHandler._log_msg(
					"export - dialog",
					"Format string of file '%s' with key '%s' doesn't have valid localization data for locale '%s'. Skipping" % [
						resource_path,
						format_key,
						locale],
					NFPluginGameHandler._LogLevel.WARNING)
			continue
		
		var data: Dictionary = format_strings[format_key][locale]
		
		if not data.has_all(["base_string", "format"]) or typeof(data["base_string"]) != TYPE_STRING or typeof(data["format"]) != TYPE_DICTIONARY:
			NFPluginGameHandler._log_msg(
					"export - dialog",
					"Format string of file '%s' with key '%s' doesn't have valid localization data for locale '%s'. Skipping" % [
						resource_path,
						format_key,
						locale],
					NFPluginGameHandler._LogLevel.ERROR)
			continue
		
		var valid_formats: Dictionary[String, Dictionary] = {}
		var format_tags: Array[String] = get_phrase_arguments(data["base_string"])
		
		for format_slice in data["format"]:
			if typeof(format_slice) != TYPE_STRING and typeof(format_slice) != TYPE_STRING_NAME:
				continue
			elif typeof(data["format"][format_slice]) != TYPE_DICTIONARY or not data["format"][format_slice].has_all(["default", "cases"]) or typeof(data["format"][format_slice]["default"]) != TYPE_STRING or typeof(data["format"][format_slice]["cases"]) != TYPE_DICTIONARY:
				NFPluginGameHandler._log_msg(
						"export - dialog",
						"Format string of file '%s' with key '%s' format '%s' has missing or corrupt data. Skipping" % [
							resource_path,
							format_key,
							format_slice],
						NFPluginGameHandler._LogLevel.ERROR)
				continue
			elif not format_tags.has(format_slice):
				continue
				
			var valid_cases: Dictionary[String, String] = {}
			
			var formats: Dictionary = data["format"][format_slice]
			
			for case in formats["cases"]:
				if typeof(case) != TYPE_STRING and typeof(case) != TYPE_STRING_NAME:
					NFPluginGameHandler._log_msg(
							"export - dialog",
							"Case on resource '%s' is not of type string. Exception on: '%s'" % [
								resource_path,
								"/".join([format_key, locale, format_slice])],
							NFPluginGameHandler._LogLevel.ERROR)
					continue
				
				var format_type: int = typeof(formats["cases"][case])
				
				if format_type != TYPE_STRING and format_type != TYPE_STRING_NAME:
					NFPluginGameHandler._log_msg(
							"dialog export",
							"Case on file '%s', format string with key '%s' format '%s' case '%s' is not of type string. Patching with warning string." % [resource_path, format_key, format_slice, case],
							NFPluginGameHandler._LogLevel.WARNING)
					valid_cases[case] = "[CASE NOT IMPLEMENTED]"
				else:
					valid_cases[case] = formats["cases"][case]
			
			var format_data: Dictionary[String, Variant] = {
				"default": data["format"][format_slice]["default"] if typeof(data["format"][format_slice]["default"]) == TYPE_STRING else "",
				"cases": valid_cases}
			valid_formats[format_slice] = format_data
		
		var full_data: Dictionary[String, Variant] = {
			"base_string": data["base_string"],
			"format": valid_formats}
		
		if not file.format_strings.has(localization_id):
			file.format_strings[localization_id] = NFDictUtils.create_typed(TYPE_STRING, TYPE_DICTIONARY)
		var format_dict: Dictionary = file.format_strings[localization_id]
		
		format_dict[format_key] = full_data


func _is_localization_data_complete(data: Dictionary, localized: bool) -> bool:
	if data.is_empty():
		return false
	
	var keys: Array = ["type"]
	if localized:
		keys.append("locales")
	else:
		keys.append("unlocalized")
	
	if not data.has_all(keys):
		NFPluginGameHandler._log_msg(
				"export - dialog",
				"Localization data missing.",
				NFPluginGameHandler._LogLevel.WARNING)
		return false
	
	if typeof(data["type"]) != TYPE_INT:
		NFPluginGameHandler._log_msg(
				"export - dialog",
				"Localization data type missing.",
				NFPluginGameHandler._LogLevel.WARNING)
		return false
	
	if localized and typeof(data["locales"]) != TYPE_DICTIONARY:
		NFPluginGameHandler._log_msg(
				"export - dialog",
				"Localization text data mismatch.",
				NFPluginGameHandler._LogLevel.WARNING)
		return false
	
	return true


func _localization_type_mismatch(uuid: StringName) -> bool:
	if not node_data.has(uuid) or not localization.has(uuid):
		return false
	
	var node_type: NodeType = node_data[uuid]["type"]
	var locale_type: LocalizationType = localization[uuid]["type"]
	
	if locale_type == LocalizationType.TEXT:
		return node_type != NodeType.DIALOG and node_type != NodeType.LOCALIZED_TEXT
	else:
		return node_type != NodeType.CHOICES


## Returns an array with a split path used for variable access on the Blackboard.
func split_path_variable(path: String) -> Array[StringName]:
	var split: PackedStringArray = path.rsplit("/", false, 1)
	var path_array: Array[StringName] = []
	for path_component in split:
		path_array.append(StringName(path_component))
	if split.size() != 2:
		path_array.resize(2)
	return path_array


## Adds a locale to the locale map. The locale map is used to track which
## languages/regions are valid and will be exported/used.[br]
## If text is missing the localization it'll throw an error on export.[br]
## If there is localization data of locales not registered through here it'll
## warn that the data isn't going to be used during runtime.
func add_locale(locale: String) -> void:
	locale = NFStringUtils.sanitize_locale(locale)
	if locale.is_empty():
		return
	
	var language: String = NFStringUtils.get_locale_language(locale)
	var region: String = NFStringUtils.get_locale_country(locale)
	
	if not locale_map.has(language):
		locale_map[language] = {}
		if not region.is_empty():
			locale_map[language][region] = null
	else:
		if not region.is_empty() and not locale_map[language].has(region):
			locale_map[language][region] = null


## Returns whether [param locale_code] is a valid locale registered
## in this resource locale map.
func has_locale(locale_code: String) -> bool:
	var standard_code: String = NFStringUtils.sanitize_locale(locale_code)
	if standard_code.is_empty():
		return false
	
	var lang: String = NFStringUtils.get_locale_language(locale_code)
	var reg: String = NFStringUtils.get_locale_country(locale_code)
	
	if reg.is_empty():
		return locale_map.has(lang)
	else:
		if locale_map.has(lang):
			return locale_map[lang].has(reg)
		return false


## Removes a locale from the locale map.
func remove_locale(locale: String) -> void:
	locale = NFStringUtils.sanitize_locale(locale)
	
	if locale.is_empty():
		return
	
	var language: String = NFStringUtils.get_locale_language(locale)
	var region: String = NFStringUtils.get_locale_country(locale)
	
	if not locale_map.has(language):
		return
	
	var locales_to_remove: Array[String] = [locale]
	if region.is_empty():
		for region_code in locale_map[language]:
			locales_to_remove.append(language + "_" + region_code)
		locale_map.erase(language)
	else:
		locale_map[language].erase(region)
	
	for locale_code in locales_to_remove:
		for format_key in format_strings:
			format_strings[format_key].erase(locale_code)
		for node_uuid in localization:
			localization[node_uuid]["locales"].erase(locale_code)


## Gets all the localization data of [param locale] contained
## in this resource for display purposes.
func get_display_localization_data(locale: String) -> Dictionary:
	var data: Dictionary = {}
	
	for code in localization.keys():
		if localization[code]["locales"].has(locale):
			if localization[code]["type"] == LocalizationType.TEXT:
				data[code] = localization[code]["locales"][locale]
			else:
				data[code] = localization[code]["locales"][locale].duplicate()
	return data


## Returns a dictionary containing the UUID of a node based on its
## [param id].
## [br][br]
## Dictionary contains 2 keys: 
## [code]"found"[/code](bool) and [code]"uuid"[/code](StringName)
func find_uuid_from_id(id: StringName) -> Dictionary:
	var dict: Dictionary = {"found": false, "uuid": &""}
	
	_buid_id_map()
	
	if not _id_map.has(id):
		return dict
	
	dict["found"] = true
	dict["uuid"] = _id_map[id]
	
	return dict


## Returns whether [param id_or_uuid] exists in this file.
func has_dialog_entry(id_or_uuid: StringName) -> bool:
	_buid_id_map()
	return node_data.has(id_or_uuid) or _id_map.has(id_or_uuid)


func _phrases_to_json_string() -> String:
	var data: Dictionary = {}
	
	var valid_locales: Dictionary[String, Variant] = {}
	
	for lang_code in locale_map: # Using currently registered locales
		valid_locales[lang_code] = null
		for reg_code in locale_map[lang_code]:
			var locale: String = lang_code + "_" + reg_code
			valid_locales[locale] = null
	
	for key in format_strings:
		var locale_data: Dictionary = {}
		for locale_code in valid_locales:
			if not format_strings[key].has(locale_code):
				locale_data[locale_code] = {
					"base_string": "",
					"format": {}}
				continue
		
			var base_string: String = format_strings[key][locale_code].get("base_string", "")
			var phrase_data: Dictionary = {
				"base_string": base_string,
				"format": {}}
			# We won't trust that the dictionary is completely and correctly
			# populated, so we populate the correct formats outselves.
			var args: Array[String] = get_phrase_arguments(base_string, true)
			
			for form in args:
				var format_data: Dictionary = {
					"default": "",
					"cases": {}}
				if format_strings[key][locale_code]["format"].has(form):
					format_data["default"] = NFDictUtils.get_nested_value(format_strings, [key, locale_code, "format", form, "default"], "")
					format_data["cases"] = NFDictUtils.get_nested_value(format_strings, [key, locale_code, "format", form, "cases"], {})
				phrase_data["format"][form] = format_data
			locale_data[locale_code] = phrase_data
		data[key] = locale_data
	
	return JSON.stringify(data, "\t")


func _import_phrase_data(data: Dictionary) -> void:
	var new_structure: Dictionary[String, Dictionary] = {}
	
	for imported_key in data:
		if typeof(imported_key) != TYPE_STRING or typeof(data[imported_key]) != TYPE_DICTIONARY:
			continue
		var entry_data: Dictionary = data[imported_key]
		var locale_entries: Dictionary = {}
		for prob_loc in entry_data:
			if typeof(prob_loc) != TYPE_STRING or typeof(entry_data[prob_loc]) != TYPE_DICTIONARY:
				continue
			
			var standard_locale: String = NFStringUtils.sanitize_locale(prob_loc)
			if standard_locale.is_empty():
				continue
			var localization_data: Dictionary = entry_data[prob_loc]
			if not localization_data.has("base_string") or typeof(localization_data["base_string"]) != TYPE_STRING:
				continue
			
			var formats: Dictionary = {}
			var locale_data: Dictionary = {
				"base_string": localization_data["base_string"],
				"format": formats}
			
			if localization_data.has("format"):
				for format_key in localization_data["format"]:
					if typeof(format_key) != TYPE_STRING or typeof(localization_data["format"][format_key]) != TYPE_DICTIONARY:
						continue
					var format_data: Dictionary = localization_data["format"][format_key]
					if not format_data.has("default") or typeof(format_data["default"]) != TYPE_STRING:
						continue
					var cases: Dictionary = {}
					var format_entry: Dictionary = {
						"default": format_data["default"],
						"cases": cases}
					if format_data.has("cases") and typeof(format_data["cases"]) == TYPE_DICTIONARY:
						for case_key in format_data["cases"]:
							if typeof(case_key) != TYPE_STRING:
								continue
							elif typeof(format_data["cases"][case_key]) != TYPE_STRING:
								continue
							else:
								cases[case_key] = format_data["cases"][case_key]
					formats[format_key] = format_entry
			
			locale_entries[standard_locale] = locale_data
		new_structure[imported_key] = locale_entries
	
	# - Merging of deep entries -
	for import_key in new_structure:
		if not format_strings.has(import_key):
			NFPluginGameHandler._log_msg(
				"discourse - editor",
				"Import data contains key '%s' but internal structure doesnt. Skipping" % import_key,
				NFPluginGameHandler._LogLevel.WARNING)
			continue
		
		var locale_level: Dictionary = format_strings[import_key]
		for imported_locale in new_structure[import_key]:
			if not locale_level.has(imported_locale):
				if has_locale(imported_locale): # File has locale registered, but dictionary hasn't for some reason.
					locale_level[imported_locale] = new_structure[import_key][imported_locale].duplicate(true)
				else:
					NFPluginGameHandler._log_msg(
							"discourse - editor",
							"Import data contains locale '%s' but internal structure doesnt. Skipping" % imported_locale,
							NFPluginGameHandler._LogLevel.WARNING)
				continue
			
			var local_locale_data: Dictionary = locale_level[imported_locale]
			var imported_locale_data: Dictionary = new_structure[import_key][imported_locale]
			var existing_formats: Array[String] = get_phrase_arguments(imported_locale_data["base_string"], true)
			local_locale_data["base_string"] = imported_locale_data["base_string"]
			
			for format_key in imported_locale_data["format"]:
				if not local_locale_data["format"].has(format_key):
					if existing_formats.has(format_key):
						local_locale_data["format"][format_key] =\
								imported_locale_data["format"][format_key].duplicate(true)
					continue
				
				var local_format: Dictionary = local_locale_data["format"][format_key]
				var imported_format: Dictionary = imported_locale_data["format"][format_key]
				local_format["default"] = imported_format["default"]
				for case in local_format["cases"]:
					if imported_format["cases"].has(case):
						local_format["cases"][case] = imported_format["cases"][case]


## Returns an array of all the registered locale codes in this
## resoruce.
func get_used_locales() -> Array[String]:
	var used_locales: Array[String] = []
	
	for lang_code in locale_map:
		used_locales.append(lang_code)
		for reg_code in locale_map[lang_code]:
			var locale_code: String = lang_code + "_" + reg_code
			used_locales.append(locale_code)
	return used_locales


func _get_data_for_csv() -> Dictionary:
	var csv_data: Dictionary = {}
	
	var possible_locales: Array[String] = get_used_locales()
	
	for node_uuid in node_data:
		if not node_data[node_uuid].has("metadata") or not node_data[node_uuid]["metadata"].get("localized", false):
			continue
		
		var node_id: String = String(node_data[node_uuid]["name"])
		if node_data[node_uuid]["type"] == NodeType.DIALOG or node_data[node_uuid]["type"] == NodeType.LOCALIZED_TEXT:
			var row_data: Dictionary = {}
			if localization.has(node_uuid):
				for locale_code in possible_locales:
					if localization[node_uuid]["locales"].has(locale_code):
						var data_type: int = typeof(localization[node_uuid]["locales"][locale_code])
						if data_type == TYPE_STRING:
							row_data[locale_code] = localization[node_uuid]["locales"][locale_code]
						else:
							row_data[locale_code] = ""
			else:
				for locale_code in possible_locales:
					row_data[locale_code] = ""
			csv_data[node_id] = row_data
		elif node_data[node_uuid]["type"] == NodeType.CHOICES:
			var target_size: int = node_data[node_uuid]["metadata"]["choices"].size()
			var arr_range: Array = range(target_size)
			if localization.has(node_uuid):
				for locale_code in possible_locales:
					var assigned_choices: Array[String] = []
					assigned_choices.assign(NFDictUtils.get_nested_value(
							localization,
							[node_uuid, "locales", locale_code],
							[],
							true))
					if assigned_choices.size() < target_size:
						assigned_choices.resize(target_size)
					
					for idx in arr_range:
						var id: String = node_id + ":" + str(idx)
						if not csv_data.has(id):
							csv_data[id] = {}
						csv_data[id][locale_code] = assigned_choices[idx]
			else:
				for locale_code in possible_locales:
					for idx in arr_range:
						var id: String = node_id + ":" + str(idx)
						if not csv_data.has(id):
							csv_data[id] = {}
						csv_data[id][locale_code] = ""
	
	return csv_data


func _set_csv_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	var id_to_uuid: Dictionary[String, StringName] = {}
	for node_uuid in node_data:
		id_to_uuid[String(node_data[node_uuid]["name"])] = node_uuid
	
	for import_id in data:
		var id_type: int = typeof(import_id)
		if id_type != TYPE_STRING and id_type != TYPE_STRING_NAME:
			continue
		var data_type: int = typeof(data[import_id])
		if data_type != TYPE_DICTIONARY:
			continue
		
		var node_id: String = import_id.strip_edges()
		var choice_idx: int = -1
		
		if 2 <= node_id.length() and node_id.contains(":"):
			var trailing_data: Dictionary = NFStringUtils.get_trailing_integer(node_id)
			if trailing_data["has_integer"]:
				choice_idx = trailing_data["integer"]
			node_id = node_id.trim_suffix(":" + str(choice_idx))
		
		if not id_to_uuid.has(node_id):
			continue
		
		var uuid: StringName = id_to_uuid[node_id]
		
		if not node_data[uuid]["metadata"]["localized"]:
			continue
		
		var type: NFDialogParser.NodeTypes = node_data[uuid]["type"]
		
		if type == NFDialogParser.NodeTypes.DIALOG or type == NFDialogParser.NodeTypes.LOCALIZED_TEXT:
			if -1 < choice_idx:
				continue
			for import_locale in data[import_id]:
				var locale_type: int = typeof(import_locale)
				if locale_type != TYPE_STRING:
					continue
				var locale_code: String = NFStringUtils.sanitize_locale(String(import_locale))
				if locale_code.is_empty():
					continue
				var localization_type: int = typeof(data[import_id][import_locale])
				if localization_type != TYPE_STRING:
					continue
				if not localization.has(uuid):
					localization[uuid] = {
						"type": LocalizationType.TEXT,
						"unlocalized": "",
						"locales": {}}
				localization[uuid]["locales"][locale_code] = data[import_id][import_locale]
		elif type == NFDialogParser.NodeTypes.CHOICES:
			if choice_idx < 0:
				continue
			var choice_size: int = node_data[uuid]["metadata"]["choices"].size()
			if choice_size - 1 < choice_idx:
				continue
			for import_locale in data[import_id]:
				var locale_type: int = typeof(import_locale)
				if locale_type != TYPE_STRING:
					continue
				var locale_code: String = NFStringUtils.sanitize_locale(String(import_locale))
				if locale_code.is_empty():
					continue
				var localization_type: int = typeof(data[import_id][import_locale])
				if localization_type != TYPE_STRING:
					continue
				
				if not localization.has(uuid):
					var entry: Dictionary[String, Variant] = {
						"type": LocalizationType.CHOICES,
						"unlocalized": PackedStringArray(),
						"locales": NFDictUtils.create_typed(TYPE_STRING, TYPE_PACKED_STRING_ARRAY)}
					localization[uuid] = entry
				
				var locale_data: Dictionary = localization[uuid]["locales"]
				if not locale_data.has(locale_code):
					locale_data[locale_code] = PackedStringArray()
				var target_array: PackedStringArray = locale_data[locale_code]
				
				if target_array.size() != choice_size:
					target_array.resize(choice_size)
				target_array[choice_idx] = data[import_id][import_locale]


func _buid_id_map() -> void:
	if _id_map.is_empty() and not node_data.is_empty():
		for node_uuid in node_data:
			_id_map[StringName(node_data[node_uuid]["name"])] = node_uuid


func _get_format_string_localized(key: String, for_locale: String) -> String:
	for_locale = NFStringUtils.sanitize_locale(for_locale)
	
	if _phrase_overrides != null:
		var possible_override: Variant = _phrase_overrides.get_base_string_override(
				dialog_id,
				for_locale,
				key)
		if possible_override != null:
			return possible_override
	
	var default_fallback: String = "[MISSING LOCALIZATION DATA]"
	
	var key_dict: Variant = format_strings.get(key)
	if key_dict == null:
		return default_fallback
	
	# 2. Direct Match
	if key_dict.has(for_locale):
		var base_str: String = key_dict[for_locale]["base_string"]
		if not base_str.is_empty():
			return base_str
	
	var fallback_mode: int = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse_fallback_mode"),
			2)
			
	if fallback_mode == 0:
		return default_fallback
		
	var lang_fallback: String = ProjectSettings.get_setting(
			"internationalization/locale/fallback")
			
	# 3. Cascade Fallback (e.g., es_AR -> es)
	if fallback_mode == 2 and for_locale.contains("_"):
		var base_lang: String = for_locale.get_slice("_", 0)
		if base_lang != lang_fallback:
			if key_dict.has(base_lang):
				var cas_str: String = key_dict[base_lang]["base_string"]
				if not cas_str.is_empty():
					return cas_str
	
	# 4. Project Default Fallback
	if key_dict.has(lang_fallback):
		var fall_str: String = key_dict[lang_fallback]["base_string"]
		if not fall_str.is_empty():
			return fall_str
	
	return default_fallback


func _get_format_string_args_localized(key: String, for_locale: String) -> Dictionary[String, Dictionary]:
	for_locale = NFStringUtils.sanitize_locale(for_locale)
	
	var e: Dictionary = NFDictUtils.EMPTY_DICT
	var base: Dictionary[String, Dictionary] = {}
	
	if format_strings.has(key):
		var key_dict: Dictionary = format_strings[key]
		var target_locale_to_use: String = ""
		
		if key_dict.has(for_locale) and not key_dict[for_locale].get("base_string", "").strip_edges().is_empty():
			target_locale_to_use = for_locale
		else:
			var fallback_mode: int = ProjectSettings.get_setting(
					NFPluginGameHandler.get_setting_path("discourse_fallback_mode"),
					2)
			
			if 0 < fallback_mode:
				var lang_fallback: String = ProjectSettings.get_setting("internationalization/locale/fallback")
				
				if fallback_mode == 2 and for_locale.contains("_"):
					var base_lang: String = NFStringUtils.get_locale_language(for_locale)
					if base_lang != lang_fallback and not key_dict.get(base_lang, e).get("base_string", "").strip_edges().is_empty():
						target_locale_to_use = base_lang
				
				if target_locale_to_use.is_empty() and key_dict.has(lang_fallback) and not key_dict.get(lang_fallback, e).get("base_string", "").strip_edges().is_empty():
					target_locale_to_use = lang_fallback
		
		if not target_locale_to_use.is_empty():
			var current: Dictionary = key_dict[target_locale_to_use]["format"].duplicate(true)
			base.assign(current)
	
	# 2. Deep-merge the specific locale's overrides on top of the resolved base
	if _phrase_overrides != null:
		var possible_override: Dictionary[String, Dictionary] = _phrase_overrides.get_formats_override(
				dialog_id,
				for_locale,
				key)
		
		for format_key in possible_override:
			var default_overrides: Array[String] = _phrase_overrides.get_format_case_default_overriden(
					dialog_id,
					key,
					format_key,
					for_locale)
			
			if not base.has(format_key):
				base[format_key] = possible_override[format_key]
			else:
				var base_format: Dictionary = base[format_key]
				var over_format: Dictionary = possible_override[format_key]
				
				if over_format.has("default"):
					base_format["default"] = over_format["default"]
				
				if over_format.has("cases"):
					if not base_format.has("cases"):
						base_format["cases"] = over_format["cases"]
					else:
						var case_dict: Dictionary = base_format["cases"]
						for def_case in default_overrides:
							case_dict.erase(def_case)
						case_dict.merge(over_format["cases"], true)
	return base
