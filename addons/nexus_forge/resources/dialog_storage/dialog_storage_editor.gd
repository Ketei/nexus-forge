@tool
@icon("res://addons/nexus_forge/icons/dialog_full.svg")
class_name EditorDiscourseDialog
extends DiscourseDialog
## A resource containing a dialog ONLY to be used in the Godot editor.
##
## Editor only files. On export, all EditorDiscourseDialog are converted to
## [ReleaseDiscourseDialog] and the original files are NOT included.


static var regex_search: RegEx

## Offset for the [GraphEdit] in Discourse.
var scroll_offset: Vector2 = Vector2.ZERO:
	set(new_scroll):
		scroll_offset = new_scroll.snappedf(0.001)
## Zoom for the [GraphEdit] in Discourse.
var zoom: float = 1.0:
	set(new_zoom):
		zoom = snappedf(new_zoom, 0.001)
var collapsed_state: Dictionary[String, bool] = {}

# A map of all languages that will be exported and used. If localization data
# is set but the locale isn't registered in here then the export plugin
# will ignore that data.
@export_storage var locale_map: Dictionary[String, Dictionary] = {
	#"en": {"US": null, "GB": null}
}

@export var dialog_id: String = ""

# Localizations with the same id will be merged toguether on the release file.
# If empty then each conversation will have it's own unique locale file.
@export_storage var locale_group: String = ""

@export_storage var node_frames: Dictionary[String, Dictionary] = {
	#"e2f420f0-1e9b-4672-bdaf-e926b59945d2": {
		#"title": "Random Frame",
		#"position": Vector2(100, 100),
		#"size": Vector2(200, 200),
		#"tint_color": Color(0.0, 0.0, 0.0, 0.55),
		#"nodes": ["629de91c-d6c1-4f67-a287-b6899695b0a6"], # Nodes linked to it.
	#}
}

# Generated on export
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
				#},
				#"daytime": {
					#"default": "",
					#"cases": {
						#"type": LocalizationFormat.METHOD_CALL,
						#"value": "get_time_string"}},
				#"fruit": {
					#"type": LocalizationFormat.STRING,
					#"value": "Banana"
				#}
			#}
		#}
	#}
}


# Node folder structure
# {"is_node": true, "uuid": ""}
# {"is_node": false, "name": "", "items": {}}
@export_storage var node_structure: Array[Dictionary] = []

# Local ID map that builds as calls are made for optimization.
var _id_map: Dictionary[StringName, StringName] = {}


static func _static_init() -> void:
	regex_search = RegEx.new()
	regex_search.compile("\\{[\\$\\!][^\\s\\}]+\\}")


## Returns an array with all the format arguments of the prase [param phrase_text].[br]
## It'll only look for format arguments that start with $ or !.
static func get_phrase_arguments(phrase_text: String, trim_brackets: bool = false) -> Array[String]:
	var all_arguments: Array[String] = []
	
	if trim_brackets:
		for regex_match in regex_search.search_all(phrase_text): # $variable
			all_arguments.append(regex_match.get_string().trim_prefix("{").trim_suffix("}"))
	else:
		for regex_match in regex_search.search_all(phrase_text): # $variable
			all_arguments.append(regex_match.get_string())
	
	return all_arguments


## Returns the text of a localized string.
func get_format_string(key: String, locale: String) -> String:
	locale = TranslationServer.standardize_locale(locale)
	return DictUtils.get_nested_value(
			format_strings,
			[key, locale, "base_string"],
			"")


func has_format_string(key: String, locale: String = "") -> bool:
	if locale.is_empty():
		return format_strings.has(key)
	else:
		return format_strings.has(key) and format_strings[key].has(locale)


## Returns all format keys that the localized string has.
func get_format_string_formats(key: String, locale_code: String) -> Array[String]:
	var lang_code: String = TranslationServer.standardize_locale(locale_code)
	if DictUtils.has_nested_path(format_strings, [key, lang_code, "format"]):
		return ArrayUtils.create_typed(TYPE_STRING, format_strings[key][lang_code]["format"].keys())
	else:
		return ArrayUtils.create_typed(TYPE_STRING)


## Returns the format keys and the possible formats of a given key.
func get_format_string_arguments(key: String, locale_code: String) -> Dictionary[String, Dictionary]:
	var lang_code: String = TranslationServer.standardize_locale(locale_code)
	var formats = DictUtils.get_nested_value(
			format_strings,
			[key, lang_code, "format"])
	
	if typeof(formats) == TYPE_DICTIONARY:
		return Dictionary(formats.duplicate(true), TYPE_STRING, &"", null, TYPE_DICTIONARY, &"", null)
	else:
		return Dictionary({}, TYPE_STRING, &"", null, TYPE_DICTIONARY, &"", null)


## Returns strings formatted for NexusForge plugin use.
func get_editor_localized_strings(locale_code: String) -> Dictionary[String, Dictionary]:
	var lang_code: String = TranslationServer.standardize_locale(locale_code)
	var data: Dictionary[String, Dictionary] = {}
	
	for key in format_strings.keys():
		data[key] = format_strings[key][lang_code].duplicate(true)
	return data


## Sets or creates a localized string with the given key.
func set_format_string(key: String, text: String, locale: String) -> void:
	locale = TranslationServer.standardize_locale(locale)
	
	if not format_strings.has(key) or locale.is_empty():
		return
	
	if not format_strings[key].has(locale):
		format_strings[key][locale] = {
			"base_string": "",
			"format": {}}
	
	format_strings[key][locale]["base_string"] = text


## Checks if the format key exists in the given key and locale. If it doesn't it'll
## create it. Returns true if the entry was created or already existed.
func validate_format_string_format(key: String, locale: String, format: String) -> bool:
	if not DictUtils.has_nested_path(format_strings, [key, locale, "format"]):
		return false
	
	if not format_strings[key][locale]["format"].has(format):
		format_strings[key][locale]["format"][format] = {
			"cases": {},
			"default": ""}
	else:
		if not format_strings[key][locale]["format"][format].has("cases"):
			format_strings[key][locale]["format"][format]["cases"] = {}
		if not format_strings[key][locale]["format"][format].has("default"):
			format_strings[key][locale]["format"][format]["default"] = ""
	
	return true


func set_format_string_case(key: String, locale: String, format: String, case: String, value: String) -> void:
	locale = TranslationServer.standardize_locale(locale)
	
	if locale.is_empty() or not format_strings.has(key):
		return
	
	if not format_strings[key].has(locale):
		format_strings[key][locale] = {
			"base_string": "",
			"format": {}}
	
	if not format_strings[key][locale]["format"].has(format):
		format_strings[key][locale]["format"][format] = {
			"default": "",
			"cases": {}}
	
	DictUtils.set_nested_value(
			format_strings,
			[key, locale, "format", format, "cases", case],
			value)


func get_format_string_case(key: String, locale: String, format: String, case: String) -> String:
	return DictUtils.get_nested_value(
			format_strings,
			[key, locale, "format", format, "cases", case],
			"",
			true)


func get_format_string_cases(key: String, locale: String, format: String) -> Array[String]:
	var cases: Array[String] = []
	
	if DictUtils.has_nested_path(format_strings, [key, locale, "format", format, "cases"]):
		cases.assign(format_strings[key][locale]["format"][format]["cases"].keys())
	return cases


## Sets the default case from a localized string with the given key.
func set_format_string_default_case(key: String, locale: String, format: String, default_text: String) -> void:
	locale = TranslationServer.standardize_locale(locale)
	
	if locale.is_empty() or not format_strings.has(key):
		return
	
	if not format_strings[key].has(locale):
		format_strings[key][locale] = {
			"base_string": "",
			"format": {}}
	
	if not format_strings[key][locale]["format"].has(format):
		format_strings[key][locale]["format"][format] = {
			"default": "",
			"cases": {}}
	
	DictUtils.set_nested_value(
			format_strings,
			[key, locale, "format", format, "default"],
			default_text)


## Returns the default case from a localized string with the given key.
func get_format_string_default_case(key: String, locale: String, argument: String) -> String:
	locale = TranslationServer.standardize_locale(locale)
	return DictUtils.get_nested_value(
			format_strings,
			[key, locale, "format", argument, "default"],
			"")


## Erases a [param format_key] and all its cases on the given [param key]
## from the given [param locale].
func erase_format_string_format(key: String, locale: String, format_key: String) -> void:
	if DictUtils.has_nested_path(format_strings, [key, locale, "format"]):
		format_strings[key][locale]["format"].erase(format_key)


func erase_format_string_case(key: String, locale: String, format_key: String, case: String) -> bool:
	if DictUtils.has_nested_path(format_strings, [key, locale, "format", format_key, "cases"]):
		return format_strings[key][locale]["format"][format_key]["cases"].erase(case)
	return false


## Clears the list of custom cases from the given key.
func clear_format_string_cases(key: String, locale: String, format: String) -> void:
	locale = TranslationServer.standardize_locale(locale)
	var cases = DictUtils.get_nested_value(
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


## Gets the text of a node with [param node_uuid] of a specific [param locale].
## If the node isn't of a type that supports text or it is not found it'll
## return [param fallback].
func get_text_entry(node_uuid: StringName, locale: String, fallback: String = "[ENTRY NOT FOUND]") -> String:
	locale = TranslationServer.standardize_locale(locale)
	
	if not localization.has(node_uuid) or localization[node_uuid]["type"] != LocalizationType.TEXT:
		return fallback
	
	var has_id: bool = DictUtils.has_nested_path(node_data, [node_uuid, "name"])
	var node_id: StringName = DictUtils.get_nested_value(node_data, [node_uuid, "name"], &"", true)
	var localized: bool = DictUtils.get_nested_value(
			node_data,
			[node_uuid, "metadata", "localized"],
			true,
			true)
	
	if _dialog_overrides != null and has_id and _dialog_overrides.has_override(node_id, locale):
		return _dialog_overrides.get_override(node_id, locale)
	elif not localized:
		return DictUtils.get_nested_value(localization, [node_uuid, "unlocalized"], fallback, true)
	else:
		return DictUtils.get_nested_value(
				localization,
				[node_uuid, "locales", locale],
				fallback,
				true)


## Gets the array of choices of a node with [param node_uuid] of a specific [param locale].
## If the node isn't of a type that supports choices or it is not found it'll
## return [param fallback].
func get_choices_entry(node_uuid: StringName, locale: String = "", fallback: Array = ["[ENTRY NOT FOUND]"]) -> Array[String]:
	locale = TranslationServer.standardize_locale(locale)
	var return_array: Array[String] = []
	
	if not localization.has(node_uuid) or localization[node_uuid]["type"] != LocalizationType.CHOICES:
		return_array.assign(fallback)
		return fallback
	
	#var localization_data: Dictionary = localization[node_uuid]
	var has_id: bool = DictUtils.has_nested_path(node_data, [node_uuid, "name"])
	var node_id: StringName = DictUtils.get_nested_value(
			node_data,
			[node_uuid, "name"],
			&"",
			true) if has_id else &""
	var localized: bool = DictUtils.get_nested_value(
			node_data,
			[node_uuid, "metadata", "localized"],
			true,
			true)
	
	if _dialog_overrides != null and has_id and _dialog_overrides.has_override(node_id, locale):
		var override = _dialog_overrides.get_override(node_id, locale)
		var override_type: int = typeof(override)
		if override_type == TYPE_PACKED_STRING_ARRAY:
			return_array.assign(override)
	elif localized:
		return_array.assign(
				DictUtils.get_nested_value(
						localization,
						[node_uuid, "locales", locale],
						[],
						true))
	else:
		return_array.assign(
				DictUtils.get_nested_value(
						localization,
						[node_uuid, "unlocalized"],
						[],
						true))
	
	return return_array


## Returns the node data from a the node with the given [param uuid] in a specific locale.
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
				push_warning("[DISCOURSE] Choice data of node {node_id} size is different from the {locale_code} localization data. Data size: {data_size}, locale size: {locale_size}".format({"data_size": target_size, "locale_size": options_translated.size(), "locale_code": locale, "node_id": base_data["name"]}) )
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


## Sets the locale for text (Dialogs & localized text nodes). Passing [code]""[/code]
## on [param locale] will set the text as unlocalized, meaning that the text will
## be the same on all localizations.[br]
## Note: Switching from a localized to an unlocalized node will clear the localization
## data completely and viceversa.
func set_dialog_text(uuid: StringName, text: String, locale: String = "") -> void:
	locale = TranslationServer.standardize_locale(locale)
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
	locale = TranslationServer.standardize_locale(locale)
	var valid_options: Array[String]
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
	
	var localization_level: Dictionary = localization.get_or_add(uuid, {"type": LocalizationType.CHOICES, "unlocalized": [], "locales": {}})
	
	if localization_level["type"] != LocalizationType.CHOICES:
		return
	
	if locale.is_empty():
		localization_level["unlocalized"] = valid_options
		localization_level["locales"].clear()
	else:
		localization_level["unlocalized"].clear()
		DictUtils.set_nested_value(
				localization_level,
				["locales", locale],
				valid_options)


## Sets a single choice for an option node. Specifically the choice with index
## [param option_index]. To set an unlocalized choice pass [code]common[/code]
## as the language argument. No region is needed when doing an unlocalized
## option.
func set_choice_text(uuid: StringName, option_index: int, text: String, locale: String = "") -> void:
	if not localization.has(uuid) or localization[uuid]["type"] != LocalizationType.CHOICES:
		return
	
	var base_level: Dictionary = localization[uuid]
	
	if locale.is_empty():
		if not base_level.has("unlocalized") or typeof(base_level["unlocalized"]) != TYPE_ARRAY:
			return
		
		var arr_size: int = base_level["unlocalized"].size()
		if arr_size == 0:
			return
		var max_index: int = arr_size - 1
		if not RangeUtils.is_between(option_index, -arr_size, max_index):
			return
		
		base_level["unlocalized"][option_index] = text
	else:
		locale = TranslationServer.standardize_locale(locale)
		if not DictUtils.has_nested_path(base_level, ["locales", locale]) or typeof(base_level["locales"][locale]) != TYPE_ARRAY:
			return
		var locale_array: Array = base_level["locales"][locale]
		
		var arr_size: int = locale_array.size()
		if arr_size == 0:
			return
		var max_index: int = arr_size - 1
		if not RangeUtils.is_between(option_index, -arr_size, max_index):
			return
		
		locale_array[option_index] = text


## Registers a frame.[br]
## Note: Always register frames before registering nodes.
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


func remove_node(node_uuid: StringName) -> void:
	node_data.erase(node_uuid)
	localization.erase(node_uuid)


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
## [DiscourseDialog] version for release. Inteded ONLY to be used by the 
## NexusForge export plugin.
func convert_for_release(api_methods: Dictionary[StringName, Dictionary]) -> DiscourseDialog:
	var available_methods: Dictionary = preload("res://addons/nexus_forge/discourse/nodes/method_call_node.gd").get_user_methods()
	var available_signals: Dictionary = preload("res://addons/nexus_forge/discourse/nodes/signal_node.gd").get_user_signals()
	
	var release_dialog: DiscourseDialog = DiscourseDialog.new()
	var uuid_translator: Dictionary[StringName, StringName] = {}
	
	release_dialog.entry_node = node_data[entry_node]["name"] if node_data.has(entry_node) else &""
	
	#var new_id_map: Dictionary[StringName, StringName] = {}
	
	# UUID(Anchor pointer): UUID(Anchor Target)
	# Example "123"(anchor pointer uuid) -> "456"(Anchor) -> "789"(Anchor connection)
	# anchor_nodes["123"] = "789"
	# This is to skip the anchor nodes as they are only a visual helper for the editor
	# on the release files, anchor nodes have no use.
	var anchor_nodes: Dictionary[StringName, StringName] = {}
	
	# UUID(merger_id): UUID(merger_next_node)
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
		var node_name: StringName = node_data[node_id]["name"]
		
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
						character_settings["display_name"] = StringName(character_settings_data["input_connections"]["display_name"]["target_node_uuid"])
					
					if not character_settings_data["input_connections"]["portrait_id"]["target_node_uuid"].is_empty():
						character_settings["portrait_id_node"] = StringName(character_settings_data["input_connections"]["display_name"]["target_node_uuid"])
				
				if not node_data[node_id]["input_connections"]["dialog_settings"]["target_node_uuid"].is_empty():
					var dialog_settings_data: Dictionary = node_data[node_data[node_id]["input_connections"]["dialog_settings"]["target_node_uuid"]]
					
					if not dialog_settings_data["input_connections"]["font_resource"]["target_node_uuid"].is_empty():
						dialog_settings["font_resource"] = StringName(dialog_settings_data["input_connections"]["font_resource"]["target_node_uuid"])
					
					if not dialog_settings_data["input_connections"]["dialog_scene"]["target_node_uuid"].is_empty():
						dialog_settings["dialog_scene"] = StringName(dialog_settings_data["input_connections"]["dialog_scene"]["target_node_uuid"])
					
					if not dialog_settings_data["input_connections"]["dialog_speed"]["target_node_uuid"].is_empty():
						dialog_settings["dialog_speed"] = StringName(dialog_settings_data["input_connections"]["dialog_speed"]["target_node_uuid"])
				
					if not dialog_settings_data["input_connections"]["metadata"]["target_node_uuid"].is_empty():
						var dialog_metadata_node: Dictionary = node_data[dialog_settings_data["input_connections"]["metadata"]["target_node_uuid"]]
						var dialog_metadata: Dictionary = dialog_metadata_node["metadata"]
						for meta_field in dialog_metadata["metadata_connections"]:
							if not dialog_metadata_node["input_connections"].has(meta_field["id"]):
								push_error(
									"[DISCOURSE] Metadata node ", dialog_metadata_node["name"], " on file ", resource_path, " registered metadata with ID ", meta_field["id"], " on port ", meta_field["port"], " but the port isn't available. Setting to null.")
								dialog_metadata["metadata"][meta_field["id"]] = null
							else:
								dialog_settings["metadata"][meta_field["id"]] = dialog_metadata_node["input_connections"][meta_field["id"]]["target_node_uuid"]
				
				export_data["character_id"] = metadata["character_id"]
				export_data["persist"] = metadata["persist"]
				export_data["character_settings"] = character_settings
				export_data["dialog_settings"] = dialog_settings
				export_data["text_source"] = StringName(node_data[node_id]["input_connections"]["dialog_text_source"]["target_node_uuid"])
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
							new_option["settings"]["available"] = StringName(option_settings["input_connections"]["option_available"]["target_node_uuid"])
						
						if not option_settings["input_connections"]["option_unlocked"]["target_node_uuid"].is_empty():
							new_option["settings"]["unlocked"] = StringName(option_settings["input_connections"]["option_unlocked"]["target_node_uuid"])
		
						if not option_settings["input_connections"]["locked_hint"]["target_node_uuid"].is_empty():
							new_option["settings"]["lock_hint"] = StringName(option_settings["input_connections"]["locked_hint"]["target_node_uuid"])
					
						if not option_settings["input_connections"]["metadata"]["target_node_uuid"].is_empty():
							var dialog_metadata_node: Dictionary = node_data[option_settings["input_connections"]["metadata"]["target_node_uuid"]]
							var dialog_metadata: Dictionary = dialog_metadata_node["metadata"]
							for meta_field in dialog_metadata:
								if not dialog_metadata_node["input_connections"].has(meta_field["id"]):
									push_error(
										"[DISCOURSE] Metadata node ", dialog_metadata_node["name"], " on file ", resource_path, " registered metadata with ID ", meta_field["id"], " on port ", meta_field["port"], " but the port isn't available. Setting to null.")
									new_option["metadata"][meta_field["id"]] = null
								else:
									new_option["metadata"][meta_field["id"]] = dialog_metadata_node["input_connections"][meta_field["id"]]["target_node_uuid"]
					
					options.append(new_option)
				export_data["choices"] = options
			NodeType.BRANCH:
				export_data["result"] = StringName(node_data[node_id]["input_connections"]["path_direction"]["target_node_uuid"])
				export_data["case_true"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node_true"]["target_node_uuid"]))
				export_data["case_false"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node_false"]["target_node_uuid"]))
			NodeType.CONDITION_SELECT:
				export_data["result"] = StringName(node_data[node_id]["input_connections"]["result"]["target_node_uuid"])
				export_data["true_value"] = target_finder.get_target(StringName(node_data[node_id]["input_connections"]["true_value"]["target_node_uuid"]))
				export_data["false_value"] = target_finder.get_target(StringName(node_data[node_id]["input_connections"]["false_value"]["target_node_uuid"]))
			NodeType.COMPARATION:
				export_data["operator"] = metadata["operator"]
				export_data["value_a"] = StringName(node_data[node_id]["input_connections"]["node_a"]["target_node_uuid"])
				export_data["value_b"] = StringName(node_data[node_id]["input_connections"]["node_b"]["target_node_uuid"])
			NodeType.EVENT:
				var var_val: StringName = StringName(node_data[node_id]["input_connections"]["variable_value"]["target_node_uuid"])
				export_data["value"] = var_val
				
				if not node_data[node_id]["input_connections"]["callable"]["target_node_uuid"].is_empty():
					var callable_uuid: StringName = node_data[node_id]["input_connections"]["callable"]["target_node_uuid"]
					if available_methods.has(node_data[callable_uuid]["metadata"]["method"]):
						export_data["callable"] = StringName(node_data[node_id]["input_connections"]["callable"]["target_node_uuid"])
					else:
						export_data["callable"] = &""
						printerr("[DISCOURSE] Warning: Issue when exporting ", resource_path, ". Event ", node_data[node_id]["name"], " calls an inexistent method.")
				else:
					export_data["callable"] = &""
				
				if not node_data[node_id]["input_connections"]["signal"]["target_node_uuid"].is_empty():
					var signal_uuid: StringName = node_data[node_id]["input_connections"]["signal"]["target_node_uuid"]
					if available_signals.has(node_data[signal_uuid]["metadata"]["signal"]):
						export_data["signal"] = StringName(node_data[node_id]["input_connections"]["signal"]["target_node_uuid"])
					else:
						export_data["signal"] = &""
						printerr("[DISCOURSE] Warning: Issue when exporting ", resource_path, ". Event ", node_data[node_id]["name"], " emits an inexistent signal.")
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
				
				export_data["case_default"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["default"]["target_node_uuid"]))
				export_data["match_value"] = StringName(node_data[node_id]["input_connections"]["match_value_source"]["target_node_uuid"])
				export_data["cases"] = cases
			NodeType.PAUSE:
				export_data["next_node"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"]))
			NodeType.RANDOM:
				var options: Array[Dictionary] = []
				
				for option:Dictionary in metadata["options"]:
					var new_option: Dictionary[String, StringName] = {}
					new_option["target"] = target_finder.get_target(StringName(option["output_connections"]["next_node"]["target_node_uuid"]))
					new_option["weight_override"] = StringName(option["input_connections"]["weight"]["target_node_uuid"])
					options.append(new_option)
				
				export_data["weight_override"] = StringName(node_data[node_id]["input_connections"]["default_weight"]["target_node_uuid"])
				export_data["choices"] = options
			NodeType.TYPE_GUARD:
				export_data["value"] = StringName(node_data[node_id]["input_connections"]["value"]["target_node_uuid"])
				export_data["fallback"] = metadata["fallback_value"]
			NodeType.SIGNAL:
				var arguments: Array[StringName] = []
				for argument:Dictionary in metadata["arguments"]:
					arguments.append(StringName(argument["target_node_uuid"]))
				export_data["signal"] = StringName(metadata["signal"])
				export_data["arguments"] = arguments
			NodeType.CALLABLE:
				var method_id: StringName = StringName(metadata["method"])
				
				if not method_id.is_empty():
					var default_args_size: int = 0
					
					if not api_methods.has(method_id):
						push_error(
								"[DISCOURSE] Callable node ", node_data[node_id]["name"], " on file ", resource_path, " calls for inexisting method: ", method_id)
					else:
						default_args_size = api_methods[method_id]["default_args"].size()
					
					var arguments: Array[StringName] = []
					var arg_idx: int = -1
					var skipped_previous: bool = false
					for argument:Dictionary in metadata["arguments"]:
						arg_idx += 1
						arguments.append(StringName(argument["target_node_uuid"]))
						if not argument["target_node_uuid"].is_empty():
							if skipped_previous:
								push_error(
									"[DISCOURSE] Callable node ", node_data[node_id]["name"], " on file ", resource_path, " passed an argument on index ", arg_idx, " but a previous index doesn't have a value.")
						else:
							skipped_previous = true
							if default_args_size <= arg_idx:
								push_error(
									"[DISCOURSE] Callable node ", node_data[node_id]["name"], " on file ", resource_path, " is missing a required argument value on index ", arg_idx)
					export_data["method"] = method_id
					export_data["arguments"] = arguments
				else:
					export_data["method"] = &""
					export_data["arguments"] = ArrayUtils.create_typed(TYPE_STRING_NAME)
			NodeType.CALLABLE_RETURN:
				var method_id: StringName = StringName(metadata["method"])
				if not method_id.is_empty():
					var default_args_size: int = 0
					
					if not api_methods.has(method_id):
						push_error(
								"[DISCOURSE] Callable node ", node_data[node_id]["name"], " on file ", resource_path, " calls for inexisting method: ", method_id)
					else:
						default_args_size = api_methods[method_id]["default_args"].size()
					
					var arguments: Array[StringName] = []
					var arg_idx: int = -1
					var skipped_previous: bool = false
					for argument:Dictionary in metadata["arguments"]:
						arg_idx += 1
						arguments.append(StringName(argument["target_node_uuid"]))
						if not argument["target_node_uuid"].is_empty():
							if skipped_previous:
								push_error(
									"[DISCOURSE] Callable node ", node_data[node_id]["name"], " on file ", resource_path, " passed an argument on index ", arg_idx, " but a previous index doesn't have a value.")
						else:
							skipped_previous = true
							if default_args_size <= arg_idx:
								push_error(
									"[DISCOURSE] Callable node ", node_data[node_id]["name"], " on file ", resource_path, " is missing a required argument value on index ", arg_idx)
					export_data["method"] = method_id
					export_data["arguments"] = arguments
				else:
					export_data["method"] = &""
					export_data["arguments"] = ArrayUtils.create_typed(TYPE_STRING_NAME)
			NodeType.VARIABLE_GET:
				var meta_path: String = ""
				if metadata.has("variable_path"):
					meta_path = metadata["variable_path"].strip_edges().simplify_path()
				else:
					push_warning("[DISCOURSE] Node ", node_data[node_id]["name"], " has missing Blackboard data path. Using empty path instead")
				
				export_data["path"] = meta_path
			NodeType.RANDOM_VALUE:
				export_data["random_type"] = metadata["mode"]
				export_data["min_value"] = metadata["values"]["base"]
				export_data["max_value"] = metadata["values"]["max"]
				export_data["min_override"] = StringName(node_data[node_id]["input_connections"]["base_value"]["target_node_uuid"])
				export_data["max_override"] = StringName(node_data[node_id]["input_connections"]["max_value"]["target_node_uuid"])
			NodeType.RESOURCE:
				export_data["path"] = metadata["resource_path"]
			NodeType.DATA_EVENT:
				var var_val: StringName = StringName(node_data[node_id]["input_connections"]["variable_value"]["target_node_uuid"])
				export_data["value"] = var_val
				
				if not node_data[node_id]["input_connections"]["callable"]["target_node_uuid"].is_empty():
					var callable_uuid: StringName = node_data[node_id]["input_connections"]["callable"]["target_node_uuid"]
					if available_methods.has(node_data[callable_uuid]["metadata"]["method"]):
						export_data["callable"] = StringName(node_data[node_id]["input_connections"]["callable"]["target_node_uuid"])
					else:
						export_data["callable"] = &""
						printerr("[DISCOURSE] Warning: Issue when exporting ", resource_path, ". Data event ", node_data[node_id]["name"], " calls an inexistent method.")
				else:
					export_data["callable"] = &""
				
				if not node_data[node_id]["input_connections"]["signal"]["target_node_uuid"].is_empty():
					var signal_uuid: StringName = node_data[node_id]["input_connections"]["signal"]["target_node_uuid"]
					if available_signals.has(node_data[signal_uuid]["metadata"]["signal"]):
						export_data["signal"] = StringName(node_data[node_id]["input_connections"]["signal"]["target_node_uuid"])
					else:
						export_data["signal"] = &""
						printerr("[DISCOURSE] Warning: Issue when exporting ", resource_path, ". Data event ", node_data[node_id]["name"], " emits an inexistent signal.")
				else:
					export_data["signal"] = &""
				
				export_data["data_source"] = StringName(node_data[node_id]["input_connections"]["data_input"]["target_node_uuid"])
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
	
	return release_dialog


## Generates and returns all NEW locale files. Inteded ONLY to be used by the 
## NexusForge export plugin.
func generate_localization_files(localization_id: String, base_path: String, filename: String, localization_groups: Dictionary = {}) -> Array[Dictionary]:
	# Should never be the case, but just in case
	if resource_path.is_empty():
		push_error("[DISCOURSE - EXPORT ERROR] Tried to generate localization of a file with no path.")
		return []
	
	var new_files: Array[Dictionary] = []
	#var md5_hash: String = resource_path.to_lower().md5_text().substr(0, 12)
	var md5_fragment: String = filename.substr(0, 2)
	var used_locales: Dictionary[String, Variant] = {}
	
	# Given how Discourse works, there is ALWAYS a base language.
	for language in locale_map.keys():
		var lang_key: String = TranslationServer.standardize_locale(language)
		if lang_key.is_empty():
			continue
		var lang_path: String = StringUtils.make_path(
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
		elif DictUtils.has_nested_path(localization_groups, [locale_group, lang_key]):
			lang_file = localization_groups[locale_group][lang_key]
		else:
			lang_file = DiscourseDialogLocale.new()
			lang_file.locale = lang_key
			DictUtils.set_nested_value(
						localization_groups,
						[locale_group, lang_key],
						lang_file)
			
			new_files.append({
				"file": lang_file,
				"path": lang_path})
		
		_add_locale_data(lang_file, localization_id, lang_key)
		used_locales[lang_key] = null
		
		for region_code in locale_map[lang_key].keys():
			var locale_key: String = TranslationServer.standardize_locale(lang_key + "_" + region_code)
			if locale_key.is_empty():
				continue
			
			var lang_locale_file: DiscourseDialogLocale = null
			var locale_path: String = StringUtils.make_path([
				base_path, locale_key, md5_fragment, filename])
			
			if DictUtils.has_nested_path(localization_groups, [locale_group, locale_key]):
				lang_locale_file = localization_groups[locale_group][locale_key]
			else:
				lang_locale_file = DiscourseDialogLocale.new()
				lang_locale_file.locale = locale_key
				DictUtils.set_nested_value(
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
		var localization_locales = DictUtils.get_nested_value(localization, [localization_key, "locales"], {})
		if typeof(localization_locales) != TYPE_DICTIONARY:
			continue
		var localization_keys = localization_locales.keys()
		
		if not used_locales.has_all(localization_keys):
			push_warning("Used locales: %s, existing locales: %s" % [used_locales.keys(), localization_keys] )
			#push_warning(
				#"[DISCOUSE] File contains more localization data than is being exported: " + resource_path + "\n. Verify locale map.")
			extra_data_warned = true
			break
	
	if extra_data_warned:
		return new_files
	
	for string_key in format_strings.keys():
		var used_string_locales = format_strings[string_key].keys()
		if not used_locales.has_all(used_string_locales):
			push_warning("Used locales: %s, existing locales: %s" % [used_locales.keys(), used_string_locales] )
			#push_warning(
				#"[DISCOUSE] File contains more localization data than is being exported: " + resource_path + "\n. Verify locale map.")
			break
	
	return new_files


func _add_locale_data(file: DiscourseDialogLocale, localization_id: String, locale: String) -> void:
	for node_uuid in localization.keys():
		if not node_data.has(node_uuid):
			push_warning("[DISCOURSE] Orphaned localization with ID '%s'. Skipping." % node_uuid)
			continue
		
		var nodeid: StringName = node_data[node_uuid]["name"]
		var data = localization[node_uuid]
		var localized: bool = DictUtils.get_nested_value(
				node_data,
				[node_uuid, "metadata", "localized"],
				false,
				true)
		
		var type_mismatch: bool = _localization_type_mismatch(node_uuid)
		var data_complete: bool = _is_localization_data_complete(data, localized)
		
		if type_mismatch or not data_complete:
			var type: int = node_data[node_uuid]["type"]
			if not data_complete:
				push_error(
						"[DISCOURSE] Incomplete or corrupt data for node with UID '%s' " % node_uuid)
			if type_mismatch:
				push_error(
						"[DISCOURSE] Type mismatch for node & localization with UID '%s' of file %s" % [node_uuid, resource_path])
			
			push_warning("[DISCOURSE] Patching data with placeholder entries.")
			
			if type == NodeType.DIALOG or type == NodeType.LOCALIZED_TEXT:
				DictUtils.set_nested_value(
					file.localization,
					[localization_id, nodeid, "dialog"],
					"",
					true)
			elif type == NodeType.CHOICES:
				var choice_size: int = node_data[node_uuid]["metadata"]["choices"].size()
				var choices: PackedStringArray = []
				choices.resize(choice_size)
				for idx in range(choice_size):
					choices[idx] = "[MISSING LOCALIZATION DATA]"
				DictUtils.set_nested_value(
						file.localization,
						[localization_id, nodeid, "choices"],
						choices,
						true)
		
		if data["type"] == LocalizationType.TEXT:
			var warn: bool = typeof(DictUtils.get_nested_value(data, ["locales", locale])) != TYPE_STRING if localized else typeof(data["unlocalized"]) != TYPE_STRING
			DictUtils.set_nested_value(
					file.localization,
					[localization_id, nodeid, "dialog"],
					DictUtils.get_nested_value(
							data,
							["locales", locale],
							"[MISSING LOCALIZATION DATA]",
							true) if localized else DictUtils.get_nested_value(data, ["unlocalized"], "[MISSING LOCALIZATION DATA]", true))
			if warn:
				if localized:
					push_warning("[DISCOURSE] Unlocalized data for node UID \"" + node_uuid + "\" is missing.")
				else:
					push_warning("[DISCOURSE] Localization data for node UID \"" + node_uuid + "\" for locale \"" + locale + "\" is missing.")
		
		elif data["type"] == LocalizationType.CHOICES:
			var data_exists: bool = false
			var choice_size: int = node_data[node_uuid]["metadata"]["choices"].size()
			var base: Array[String] = []
			
			if localized:
				data_exists = data["locales"].has(locale) and typeof(data["locales"][locale]) == TYPE_ARRAY
				if data_exists:
					for idx in range(data["locales"][locale].size()):
						if typeof(data["locales"][locale][idx]) == TYPE_STRING:
							base.append(data["locales"][locale][idx])
						else:
							push_warning("[DISCORUSE] Choice with index " + str(idx) + " on locale " + locale + " isn't a string.")
							base.append("[INVALID TEXT]")
				else:
					base.resize(choice_size)
			else:
				data_exists = typeof(data["unlocalized"]) == TYPE_ARRAY
				if data_exists:
					for idx in range(data["unlocalized"].size()):
						if typeof(data["unlocalized"][idx]) == TYPE_STRING:
							base.append(data["unlocalized"][idx])
						else:
							push_warning("[DISCORUSE] Choice with index %s on locale '%s' isn't a string." % [idx, locale])
							base.append("[INVALID TEXT]")
				else:
					base.resize(choice_size)
			
			if not data_exists:
				if localized:
					push_warning("[DISCOURSE] Localization data for node UID '%s' for locale '%s' is missing." % [node_uuid, locale])
				else:
					push_warning("[DISCOURSE] Unlocalized data for node UID '%s' is missing." % node_uuid)
				var err_string: String = "[MISSING LOCALIZATION DATA]"
				base.resize(choice_size)
				for idx in range(choice_size):
					base[idx] = err_string
			
			DictUtils.set_nested_value(
					file.localization,
					[localization_id, nodeid, "choices"],
					PackedStringArray(base),
					true)
			
			var current_size: int = base.size()
			if choice_size != current_size:
				push_warning(
					"[DISCOURSE] Localization choice count on node UID %s differs from data choice count: %s vs %s. Patching to match data size." % [node_uuid, current_size, choice_size])
				base.resize(choice_size)
				if current_size < choice_size:
					push_warning("[DISCOURSE] Localization count is smaller. Applying placeholders.")
					for missing_idx in range(current_size, choice_size):
						base[missing_idx] = "[MISSING LOCALIZATION DATA]"
		else:
			push_warning(
					"[DISCOURSE] Localization export for node with UID '%s' couldn't define type." % node_uuid)
			var nameless_id = DictUtils.get_nested_value(node_data, [node_uuid, "name"])
			if typeof(nameless_id) == TYPE_STRING_NAME:
				push_warning("[DISCOURSE - INFO] ID for typeless node found: %s\"" % String(nameless_id))
	
	for format_key in format_strings.keys():
		if not format_strings[format_key].has(locale) or typeof(format_strings[format_key][locale]) != TYPE_DICTIONARY:
			push_warning("[DISCOURSE] Format string of file '%s' with key '%s' doesn't have valid localization data for locale '%s'. Skipping" % [resource_path, format_key, locale])
			continue
		
		var data: Dictionary = format_strings[format_key][locale]
		
		if not data.has_all(["base_string", "format"]) or typeof(data["base_string"]) != TYPE_STRING or typeof(data["format"]) != TYPE_DICTIONARY:
			push_error("[DISCOURSE] Format string of file '%s' with key '%s' doesn't have valid localization data for locale '%s'. Skipping" % [resource_path, format_key, locale])
			continue
		
		var valid_formats: Dictionary = {}
		
		for format_slice in data["format"].keys():
			var valid_cases: Dictionary = {}
			
			if typeof(data["format"][format_slice]) != TYPE_DICTIONARY or not data["format"][format_slice].has_all(["default", "cases"]) or typeof(data["format"][format_slice]["default"]) != TYPE_STRING or typeof(data["format"][format_slice]["cases"]) != TYPE_DICTIONARY:
				push_error("[DISCOURSE] Format string of file '%s' with key '%s' format '%s' has missing or corrupt data. Skipping" % [resource_path, format_key, format_slice])
				continue
			
			var formats: Dictionary = data["format"][format_slice]
			
			for case in formats["cases"].keys():
				if typeof(case) != TYPE_STRING and typeof(case) != TYPE_STRING_NAME:
					push_error("[DISCOURSE] Case on resource %s is not of type string. Exception on: %s " % [resource_path, "/".join([format_key, locale, format_slice])])
					continue
				
				var format_type: int = typeof(formats["cases"][case])
				
				if format_type != TYPE_STRING and format_type != TYPE_STRING_NAME:
					NFPluginGameHandler._log_msg(
							"dialog export",
							"[DISCOURSE] Case on file '%s', format string with key '%s' format '%s' case '%s' is not of type string. Patching with warning string." % [resource_path, format_key, format_slice, case],
							NFPluginGameHandler._LogLevel.WARNING)
					valid_cases[case] = "[CASE NOT IMPLEMENTED]"
				else:
					valid_cases[case] = formats["cases"][case]
			
			valid_formats[format_slice] = {
				"default": data["format"][format_slice]["default"] if typeof(data["format"][format_slice]["default"]) == TYPE_STRING else "",
				"cases": valid_cases}
		
		var full_data: Dictionary = {
			"base_string": data["base_string"],
			"format": valid_formats}
		
		DictUtils.set_nested_value(
				file.format_strings,
				[localization_id, format_key],
				full_data)


func _is_localization_data_complete(data: Dictionary, localized: bool) -> bool:
	if data.is_empty():
		return false
	
	var keys: Array = ["type"]
	if localized:
		keys.append("locales")
	else:
		keys.append("unlocalized")
	
	if not data.has_all(keys):
		push_warning("[DISCOURSE] Localization data missing.")
		return false
	
	if typeof(data["type"]) != TYPE_INT:
		push_warning("[DISCOURSE] Localization data type missing.")
		return false
	
	if localized and typeof(data["locales"]) != TYPE_DICTIONARY:
		push_warning("[DISCOURSE] Localization text data mismatch.")
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
	locale = TranslationServer.standardize_locale(locale)
	if locale.is_empty():
		return
	
	var locale_parts: PackedStringArray = locale.split("_", false, 1)
	var language: String = locale_parts[0]
	var region: String = locale_parts[1] if locale_parts.size() == 2 else ""
	
	if not locale_map.has(language):
		locale_map[language] = {}
		if not region.is_empty():
			locale_map[language][region] = null
	else:
		if not region.is_empty() and not locale_map[language].has(region):
			locale_map[language][region] = null


func has_locale(locale_code: String) -> bool:
	var standard_code: String = TranslationServer.standardize_locale(locale_code)
	if standard_code.is_empty():
		return false
	
	var parts: PackedStringArray = standard_code.split("_", false, 2)
	var lang: String = parts[0]
	var reg: String = parts[1] if 1 < parts.size() else ""
	
	if reg.is_empty():
		return locale_map.has(lang)
	else:
		if locale_map.has(lang):
			return locale_map[lang].has(reg)
		return false


## Removes a locale from the locale map.
func remove_locale(locale: String) -> void:
	locale = TranslationServer.standardize_locale(locale)
	if locale.is_empty():
		return
	var locale_parts: PackedStringArray = locale.split("_", false, 1)
	var language: String = locale_parts[0]
	var region: String = locale_parts[1] if locale_parts.size() == 2 else ""
	
	if not locale_map.has(language):
		return
	
	var locale_code: String = language if region.is_empty() else language + "_" + region
	
	if region.is_empty():
		locale_map.erase(language)
	else:
		locale_map[language].erase(region)
	
	for format_key in format_strings.keys():
		format_strings[format_key].erase(locale_code)
	for node_uuid in localization.keys():
		localization[node_uuid]["locales"].erase(locale_code)


func get_display_localization_data(locale: String) -> Dictionary:
	var data: Dictionary = {}
	
	for code in localization.keys():
		if localization[code]["locales"].has(locale):
			if localization[code]["type"] == LocalizationType.TEXT:
				data[code] = localization[code]["locales"][locale]
			else:
				data[code] = localization[code]["locales"][locale].duplicate()
	return data


func find_uuid_from_id(id: StringName) -> Dictionary:
	var dict: Dictionary = {"found": false, "id": &""}
	
	_buid_id_map()
	
	if not _id_map.has(id):
		return dict
	
	dict["found"] = true
	dict["uuid"] = _id_map[id]
	
	return dict


func get_id_target(id: StringName) -> StringName:
	for entry in node_data.keys():
		if node_data[entry]["name"] == id:
			return entry
	return &""


func has_dialog_entry(id_or_uuid: String) -> bool:
	_buid_id_map()
	return node_data.has(id_or_uuid) or _id_map.has(id_or_uuid)


func phrases_to_json_string() -> String:
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
			var args: Array[String] = get_phrase_arguments(base_string)
			for form in args:
				var format_data: Dictionary = {
					"default": "",
					"cases": {}}
				if format_strings[key][locale_code]["format"].has(form):
					format_data["default"] = DictUtils.get_nested_value(format_strings, [key, locale_code, "format", form, "default"], "")
					format_data["cases"] = DictUtils.get_nested_value(format_strings, [key, locale_code, "format", form, "cases"], {})
				phrase_data["format"][form] = format_data
			locale_data[locale_code] = phrase_data
		data[key] = locale_data
	
	return JSON.stringify(data, "\t")


func import_phrase_data(data: Dictionary) -> void:
	var new_structure: Dictionary[String, Dictionary] = {}
	
	for imported_key in data:
		if typeof(imported_key) != TYPE_STRING or typeof(data[imported_key]) != TYPE_DICTIONARY:
			continue
		var entry_data: Dictionary = data[imported_key]
		var locale_entries: Dictionary = {}
		for prob_loc in entry_data:
			if typeof(prob_loc) != TYPE_STRING or typeof(entry_data[prob_loc]) != TYPE_DICTIONARY:
				continue
			
			var standard_locale: String = TranslationServer.standardize_locale(prob_loc)
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
			var existing_formats: Array[String] = get_phrase_arguments(imported_locale_data["base_string"])
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
					assigned_choices.assign(DictUtils.get_nested_value(
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
			var trailing_data: Dictionary = StringUtils.get_trailing_integer(node_id)
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
				var locale_code: String = TranslationServer.standardize_locale(String(import_locale))
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
				var locale_code: String = TranslationServer.standardize_locale(String(import_locale))
				if locale_code.is_empty():
					continue
				var localization_type: int = typeof(data[import_id][import_locale])
				if localization_type != TYPE_STRING:
					continue
				
				if not localization.has(uuid):
					localization[uuid] = {
						"type": LocalizationType.CHOICES,
						"unlocalized": ArrayUtils.create_typed(TYPE_STRING),
						"locales": {}}
				
				var localized_choices: Array[String] = localization[uuid]["locales"].get_or_add(locale_code, ArrayUtils.create_typed(TYPE_STRING))
				if localized_choices.size() != choice_size:
					localized_choices.resize(choice_size)
				localized_choices[choice_idx] = data[import_id][import_locale]


func _buid_id_map() -> void:
	if _id_map.is_empty() and not node_data.is_empty():
		for node_uuid in node_data:
			_id_map[StringName(node_data[node_uuid]["name"])] = node_uuid
