@tool
@icon("res://addons/nexus_forge/icons/dialog_full.svg")
class_name EditorDiscourseDialog
extends DiscourseDialog
## A resource containing a dialog ONLY to be used in the Godot editor.
##
## Editor only files. On export, all EditorDiscourseDialog are converted to
## [ReleaseDiscourseDialog] and the original files are NOT included.


## Offset for the [GraphEdit] in Discourse.
var scroll_offset: Vector2 = Vector2.ZERO:
	set(new_scroll):
		scroll_offset = new_scroll.snappedf(0.001)
## Zoom for the [GraphEdit] in Discourse.
var zoom: float = 1.0:
	set(new_zoom):
		zoom = snappedf(new_zoom, 0.001)

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
		return ArrayUtils.create_array_typed(TYPE_STRING, format_strings[key][lang_code]["format"].keys())
	else:
		return ArrayUtils.create_array_typed(TYPE_STRING)


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
	
	var text_set: bool = DictUtils.set_nested_value(format_strings, [key, locale, "base_string"], text, false)
	
	if not text_set:
		DictUtils.set_nested_value(
					format_strings,
					[key, locale],
					{"base_string": text, "format": {}})


func set_format_string_case(key: String, locale: String, format: String, case: String, value: String) -> void:
	locale = TranslationServer.standardize_locale(locale)
	if not DictUtils.has_nested_path(format_strings, [key, locale]):
		return
	
	if not format_strings[key][locale]["format"].has(format):
		format_strings[key][locale]["format"][format] = {
			"default": "",
			"cases": {}}
	
	DictUtils.set_nested_value(
			format_strings,
			[key, locale, "format", format, "cases", case],
			value,
			false)


func get_format_string_case(key: String, locale: String, format: String, case: String) -> String:
	return DictUtils.get_nested_value(
			format_strings,
			[key, locale, "format", format, "cases", case],
			"",
			true)


## Sets the default case from a localized string with the given key.
func set_format_string_default_case(key: String, locale: String, format: String, default_text: String) -> void:
	locale = TranslationServer.standardize_locale(locale)
	if not DictUtils.has_nested_path(format_strings, [key, locale]):
		return
	
	if not format_strings[key][locale]["format"].has(format):
		format_strings[key][locale]["format"][format] = {
			"default": "",
			"cases": {}}
	
	DictUtils.set_nested_value(
			format_strings,
			[key, locale, "format", format, "default"],
			default_text,
			false)


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
func get_text_entry(node_uuid: StringName, locale: String = "", fallback: String = "[ENTRY NOT FOUND]") -> String:
	locale = TranslationServer.standardize_locale(locale)
	var localization_data = localization.get(node_uuid)
	
	if localization_data == null or localization_data["type"] != LocalizationType.TEXT:
		return fallback
	
	if not DictUtils.has_nested_path(localization_data, ["locales", locale]):
		return DictUtils.get_nested_value(localization_data, ["unlocalized"], fallback)
	else:
		return DictUtils.get_nested_value(
				localization_data,
				["locales", locale],
				fallback)


## Gets the array of choices of a node with [param node_uuid] of a specific [param locale].
## If the node isn't of a type that supports choices or it is not found it'll
## return [param fallback].
func get_choices_entry(node_uuid: StringName, locale: String = "", fallback: Array = ["[ENTRY NOT FOUND]"]) -> Array:
	locale = TranslationServer.standardize_locale(locale)
	var return_array: Array[String] = []
	
	if not localization.has(node_uuid) or localization[node_uuid]["type"] != LocalizationType.CHOICES:
		return_array.assign(fallback)
		return fallback
	
	var localization_data: Dictionary = localization[node_uuid]
	
	if localization_data["unlocalized"].is_empty():
		return_array.assign(
				DictUtils.get_nested_value(
						localization_data,
						["locales", locale],
						[]))
	else:
		return_array.assign(localization_data["unlocalized"])
	
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
		NodeType.OPTIONS:
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
func set_text_entry(uuid: StringName, text: String, locale: String = "") -> void:
	locale = TranslationServer.standardize_locale(locale)
	var localization_level: Dictionary = localization.get_or_add(uuid, {"type": LocalizationType.TEXT, "unlocalized": "", "locales": {}})
	
	if localization_level["type"] != LocalizationType.TEXT:
		return
	
	if locale.is_empty():
		localization_level["unlocalized"] = text
		localization_level["locales"].clear()
		return
	else:
		localization_level["unlocalized"] = ""
	
	
	localization_level["locales"][locale] = text


## Sets ALL the choices for an option node. Passing an empty string on [param locale]
## will set the options as unlocalized.[br]
## Note: Switching from a localized to an unlocalized node will clear the localization
## data completely and viceversa.
func set_choices_entry(uuid: StringName, options: Array, locale: String = "") -> void:
	# --- Data validation ---
	locale = TranslationServer.standardize_locale(locale)
	for option in options:
		if typeof(option) != TYPE_STRING:
			return
	# -----------------------
	
	var localization_level: Dictionary = localization.get_or_add(uuid, {"type": LocalizationType.CHOICES, "unlocalized": [], "locales": {}})
	
	if localization_level["type"] != LocalizationType.CHOICES:
		return
	
	if locale.is_empty():
		localization_level["unlocalized"] = options.duplicate(true)
		localization_level["locales"].clear()
		return
	else:
		localization_level["unlocalized"].clear()
	
	DictUtils.set_nested_value(
			localization_level,
			["locales", locale],
			options.duplicate(true))


## Sets a single choice for an option node. Specifically the choice with index
## [param option_index]. To set an unlocalized choice pass [code]common[/code]
## as the language argument. No region is needed when doing an unlocalized
## option.
func update_choice_entry(uuid: StringName, option_index: int, text: String, locale: String = "") -> void:
	if not localization.has(uuid) or localization[uuid]["type"] != LocalizationType.CHOICES:
		return
	
	var base_level: Dictionary = localization[uuid]
	
	if locale.is_empty():
		if base_level["unlocalized"].size() < option_index + 1:
			return
		base_level["unlocalized"][option_index] = text
	else:
		locale = TranslationServer.standardize_locale(locale)
		
		var locale_array = DictUtils.get_nested_value(
				base_level,
				["locales", locale])
		if typeof(locale_array) != TYPE_ARRAY or locale_array.size() + 1 < option_index:
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
	elif node.node_type == NodeType.OPTIONS:
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


## Builds and returns the custom ID static UUID relationship between nodes.[br]
## The returned key is the custom ID, while the values are the unique UUIDs.
func get_id_map() -> Dictionary[StringName, StringName]:
	var map: Dictionary[StringName, StringName] = {}
	for node_uuid in node_data.keys():
		map[node_data[node_uuid]["name"]] = node_uuid
	return map


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
func convert_for_release() -> DiscourseDialog:
	var available_methods: Dictionary = preload("res://addons/nexus_forge/discourse/nodes/method_call_node.gd").get_user_methods()
	var available_signals: Dictionary = preload("res://addons/nexus_forge/discourse/nodes/signal_node.gd").get_user_signals()
	
	var release_dialog: DiscourseDialog = DiscourseDialog.new()
	var api: DiscourseAPI = DiscourseAPI.new()
	var api_methods: Dictionary[StringName, Dictionary] = {} 
	
	for method in api.get_method_list():
		api_methods[StringName(method["name"])] = method
	
	release_dialog.entry_node = entry_node
	
	var new_id_map: Dictionary[StringName, StringName] = {}
	
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
		if node_data[node_uuid]["type"] == NodeType.ANCHOR_POINTER:
			var target_node: StringName = &""
			if not metadata["anchor_target"].is_empty():
				target_node = node_data[metadata["anchor_target"]]["output_connections"]["next_node"]
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
	
	var add_id: bool = true
	
	for node_id in node_uuids:
		var data: Dictionary[String, Variant] = {
			"type": node_data[node_id]["type"]}
		var metadata: Dictionary = node_data[node_id]["metadata"]
		match node_data[node_id]["type"]:
			NodeType.ENTRY:
				data["next_node"] = target_finder.get_target(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"]) #get_target_lambda.call(node_id)
			NodeType.DIALOG:
				var character_settings: Dictionary = {
					"display_name": &"",
					"portrait_id": &""}
				
				var dialog_settings: Dictionary = {
					"font_resource": &"",
					"dialog_scene": &"",
					"dialog_speed": &"",
					"metadata": {}}
				
				if not node_data[node_id]["input_connections"]["dialog_settings"]["target_node_uuid"].is_empty():
					var character_settings_data: Dictionary = node_data[node_data[node_id]["input_connections"]["dialog_settings"]["target_node_uuid"]]
					
					if not character_settings_data["input_connections"]["display_name"]["target_node_uuid"].is_empty():
						character_settings["display_name"] = StringName(character_settings_data["input_connections"]["display_name"]["target_node_uuid"])
					
					if not character_settings_data["input_connections"]["portrait_id"]["target_node_uuid"].is_empty():
						character_settings["portrait_id_node"] = StringName(character_settings_data["input_connections"]["display_name"]["target_node_uuid"])
				
				if not node_data[node_id]["input_connections"]["character_settings"]["target_node_uuid"].is_empty():
					var dialog_settings_data: Dictionary = node_data[node_data[node_id]["input_connections"]["character_settings"]["target_node_uuid"]]
					
					if not dialog_settings_data["input_connections"]["font_resource"]["target_node_uuid"].is_empty():
						dialog_settings["font_resource"] = StringName(dialog_settings_data["input_connections"]["font_resource"]["target_node_uuid"])
					
					if not dialog_settings_data["input_connections"]["dialog_scene"]["target_node_uuid"].is_empty():
						dialog_settings["dialog_scene"] = StringName(dialog_settings_data["input_connections"]["dialog_scene"]["target_node_uuid"])
					
					if not dialog_settings_data["input_connections"]["dialog_speed"]["target_node_uuid"].is_empty():
						dialog_settings["dialog_speed"] = StringName(dialog_settings_data["input_connections"]["dialog_speed"]["target_node_uuid"])
				
				if not node_data[node_id]["input_connections"]["metadata"]["target_node_uuid"].is_empty():
					var dialog_metadata_node: Dictionary = node_data[node_data[node_id]["input_connections"]["metadata"]["target_node_uuid"]]
					var dialog_metadata: Dictionary = dialog_metadata_node["metadata"]
					for meta_field in dialog_metadata:
						if not dialog_metadata_node["input_connections"].has(meta_field["id"]):
							push_error(
								"[DISCOURSE] Metadata node ", dialog_metadata_node["name"], " on file ", resource_path, " registered metadata with ID ", meta_field["id"], " on port ", meta_field["port"], " but the port isn't available. Setting to null.")
							dialog_metadata["metadata"][meta_field["id"]] = null
						else:
							dialog_settings["metadata"][meta_field["id"]] = dialog_metadata_node["input_connections"][meta_field["id"]]["target_node_uuid"]
				
				data["character_id"] = metadata["character_id"]
				data["persist"] = metadata["persist"]
				data["character_settings"] = character_settings
				data["dialog_settings"] = dialog_settings
				data["text_source"] = StringName(node_data[node_id]["input_connections"]["dialog_text_source"]["target_node_uuid"])
				data["next_node"] = target_finder.get_target(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"]) #get_target_lambda.call(dialog_nodes[node_id]["output_connections"]["next_node"]["target_node_uuid"])
			NodeType.OPTIONS:
				var options: Array[Dictionary] = []
				for option:Dictionary in metadata["options"]:
					var new_option: Dictionary[String, Variant] = {
						"next_node": target_finder.get_target(StringName(option["output_connections"]["next_node"]["target_node_uuid"])), #get_target_lambda.call(StringName(option["output_connections"]["next_node"]["target_node_uuid"])),
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
					
					if not node_data[node_id]["input_connections"]["metadata"]["target_node_uuid"].is_empty():
						var dialog_metadata_node: Dictionary = node_data[node_data[node_id]["input_connections"]["metadata"]["target_node_uuid"]]
						var dialog_metadata: Dictionary = dialog_metadata_node["metadata"]
						for meta_field in dialog_metadata:
							if not dialog_metadata_node["input_connections"].has(meta_field["id"]):
								push_error(
									"[DISCOURSE] Metadata node ", dialog_metadata_node["name"], " on file ", resource_path, " registered metadata with ID ", meta_field["id"], " on port ", meta_field["port"], " but the port isn't available. Setting to null.")
								new_option["metadata"][meta_field["id"]] = null
							else:
								new_option["metadata"][meta_field["id"]] = dialog_metadata_node["input_connections"][meta_field["id"]]["target_node_uuid"]
					
					options.append(new_option)
				data["options"] = options
			NodeType.BRANCH:
				data["result"] = StringName(node_data[node_id]["input_connections"]["path_direction"]["target_node_uuid"])
				data["case_true"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node_true"]["target_node_uuid"]))
				data["case_false"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node_false"]["target_node_uuid"]))
			NodeType.CONDITION_SELECT:
				data["result"] = StringName(node_data[node_id]["input_connections"]["result"]["target_node_uuid"])
				data["true_value"] = target_finder.get_target(StringName(node_data[node_id]["input_connections"]["true_value"]["target_node_uuid"]))
				data["false_value"] = target_finder.get_target(StringName(node_data[node_id]["input_connections"]["false_value"]["target_node_uuid"]))
			NodeType.COMPARATION:
				data["operator"] = metadata["operator"]
				data["value_a"] = StringName(node_data[node_id]["input_connections"]["node_a"]["target_node_uuid"])
				data["value_b"] = StringName(node_data[node_id]["input_connections"]["node_b"]["target_node_uuid"])
			NodeType.EVENT:
				var var_val: StringName = StringName(node_data[node_id]["input_connections"]["variable_value"]["target_node_uuid"])
				data["value"] = var_val
				
				if not node_data[node_id]["input_connections"]["callable"]["target_node_uuid"].is_empty():
					var callable_uuid: StringName = node_data[node_id]["input_connections"]["callable"]["target_node_uuid"]
					if available_methods.has(node_data[callable_uuid]["metadata"]["method"]):
						data["callable"] = StringName(node_data[node_id]["input_connections"]["callable"]["target_node_uuid"])
					else:
						data["callable"] = &""
						printerr("[Discourse] Warning: Issue when exporting ", resource_path, ". Event ", node_data[node_id]["name"], " calls an inexistent method.")
				else:
					data["callable"] = &""
				
				if not node_data[node_id]["input_connections"]["signal"]["target_node_uuid"].is_empty():
					var signal_uuid: StringName = node_data[node_id]["input_connections"]["signal"]["target_node_uuid"]
					if available_signals.has(node_data[signal_uuid]["metadata"]["signal"]):
						data["signal"] = StringName(node_data[node_id]["input_connections"]["signal"]["target_node_uuid"])
					else:
						data["signal"] = &""
						printerr("[Discourse] Warning: Issue when exporting ", resource_path, ". Event ", node_data[node_id]["name"], " emits an inexistent signal.")
				else:
					data["signal"] = &""
				data["next_node"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"]))
				
				if var_val.is_empty():
					data["variable_path"] = ""
				else:
					var clean_path: String = metadata["variable_path"].strip_edged().simplify_path()
					data["variable_path"] = clean_path
			NodeType.MATCH:
				var cases: Array[Dictionary] = []
				
				for case:Dictionary in metadata["cases"]:
					var new_case: Dictionary[String, Variant] = {}
					new_case["value"] = case["value"]
					new_case["next_node"] = target_finder.get_target(StringName(case["output_connections"]["next_node"]["target_node_uuid"]))
				
				data["case_default"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["default"]["target_node_uuid"]))
				data["match_value"] = StringName(node_data[node_id]["input_connections"]["match_value_source"]["target_node_uuid"])
				data["cases"] = cases
			NodeType.PAUSE:
				data["next_node"] = target_finder.get_target(StringName(node_data[node_id]["output_connections"]["next_node"]["target_node_uuid"]))
			NodeType.RANDOM:
				var options: Array[Dictionary] = []
				
				for option:Dictionary in metadata["options"]:
					var new_option: Dictionary[String, StringName] = {}
					new_option["target"] = target_finder.get_target(StringName(option["output_connections"]["next_node"]["target_node_uuid"]))
					new_option["weight_override"] = StringName(option["input_connections"]["weight"]["target_node_uuid"])
					options.append(new_option)
				
				data["default_override"] = StringName(node_data[node_id]["input_connections"]["default_weight"]["target_node_uuid"])
				data["options"] = options
			NodeType.TYPE_GUARD:
				data["type"] = typeof(metadata["fallback_value"])
				data["value"] = StringName(node_data[node_id]["input_connections"]["value"]["target_node_uuid"])
				data["fallback"] = metadata["fallback_value"]
			NodeType.SIGNAL:
				var arguments: Array[StringName] = []
				for argument:Dictionary in metadata["arguments"]:
					arguments.append(StringName(argument["target_node_uuid"]))
				data["signal"] = StringName(metadata["signal"])
				data["arguments"] = arguments
			NodeType.CALLABLE:
				var method_id: StringName = StringName(metadata["method"])
				var default_args_size: int = 0
				
				if not api_methods.has(method_id):
					push_error(
							"[DISCOURSE] Callable node ", data["name"], " on file ", resource_path, " calls for inexisting method: ", method_id)
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
								"[DISCOURSE] Callable node ", data["name"], " on file ", resource_path, " passed an argument on index ", arg_idx, " but a previous index doesn't have a value.")
					else:
						skipped_previous = true
						if default_args_size <= arg_idx:
							push_error(
								"[DISCOURSE] Callable node ", data["name"], " on file ", resource_path, " is missing a required argument value on index ", arg_idx)
				data["method"] = method_id
				data["arguments"] = arguments
			NodeType.CALLABLE_RETURN:
				var method_id: StringName = StringName(metadata["method"])
				var default_args_size: int = 0
				
				if not api_methods.has(method_id):
					push_error(
							"[DISCOURSE] Callable node ", data["name"], " on file ", resource_path, " calls for inexisting method: ", method_id)
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
								"[DISCOURSE] Callable node ", data["name"], " on file ", resource_path, " passed an argument on index ", arg_idx, " but a previous index doesn't have a value.")
					else:
						skipped_previous = true
						if default_args_size <= arg_idx:
							push_error(
								"[DISCOURSE] Callable node ", data["name"], " on file ", resource_path, " is missing a required argument value on index ", arg_idx)
				data["method"] = method_id
				data["arguments"] = arguments
			NodeType.VARIABLE_GET:
				var meta_path: String = ""
				if metadata.has("variable_path"):
					meta_path = metadata["variable_path"].strip_edges().simplify_path()
				else:
					push_warning("[DISCOURSE] Node ", data["name"], " has missing Blackboard data path. Using empty path instead")
				
				data["path"] = meta_path
			NodeType.RANDOM_VALUE:
				data["random_type"] = metadata["mode"]
				data["min_value"] = metadata["values"]["base"]
				data["max_value"] = metadata["values"]["max"]
				data["min_override"] = StringName(node_data[node_id]["input_connections"]["base_value"]["target_node_uuid"])
				data["max_override"] = StringName(node_data[node_id]["input_connections"]["max_value"]["target_node_uuid"])
			NodeType.RESOURCE:
				data["path"] = metadata["resource_path"]
			NodeType.DATA_EVENT:
				var var_val: StringName = StringName(node_data[node_id]["input_connections"]["variable_value"]["target_node_uuid"])
				data["value"] = var_val
				
				if not node_data[node_id]["input_connections"]["callable"]["target_node_uuid"].is_empty():
					var callable_uuid: StringName = node_data[node_id]["input_connections"]["callable"]["target_node_uuid"]
					if available_methods.has(node_data[callable_uuid]["metadata"]["method"]):
						data["callable"] = StringName(node_data[node_id]["input_connections"]["callable"]["target_node_uuid"])
					else:
						data["callable"] = &""
						printerr("[Discourse] Warning: Issue when exporting ", resource_path, ". Data event ", node_data[node_id]["name"], " calls an inexistent method.")
				else:
					data["callable"] = &""
				
				if not node_data[node_id]["input_connections"]["signal"]["target_node_uuid"].is_empty():
					var signal_uuid: StringName = node_data[node_id]["input_connections"]["signal"]["target_node_uuid"]
					if available_signals.has(node_data[signal_uuid]["metadata"]["signal"]):
						data["signal"] = StringName(node_data[node_id]["input_connections"]["signal"]["target_node_uuid"])
					else:
						data["signal"] = &""
						printerr("[Discourse] Warning: Issue when exporting ", resource_path, ". Data event ", node_data[node_id]["name"], " emits an inexistent signal.")
				else:
					data["signal"] = &""
				
				data["data_source"] = StringName(node_data[node_id]["input_connections"]["data_input"]["target_node_uuid"])
				if var_val.is_empty():
					data["variable_path"] = ""
				else:
					var meta_path: String = ""
					if metadata.has("variable_path"):
						meta_path = metadata["variable_path"].strip_edges().simplify_path()
					
					data["variable_path"] = meta_path
			NodeType.LOCALIZED_TEXT:
				pass
			NodeType.VALUE:
				add_id = false
				data["value"] = metadata["value"]
			_:
				add_id = false
		
		if add_id:
			data["id"] = node_data[node_id]["name"]
			new_id_map[StringName(node_data[node_id]["name"])] = node_id
		release_dialog.node_logic[node_id] = data
		add_id = true
	
	release_dialog.id_map = new_id_map
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
	var used_locales: Dictionary = {}
	
	# Given how Discourse works, there is ALWAYS a base language.
	for language in locale_map.keys():
		var lang_key: String = TranslationServer.standardize_locale(language)
		var lang_path: String = StringUtils.make_path(
				[base_path,
				lang_key,
				md5_fragment,
				filename])
		
		var lang_file: DiscourseDialogLocale = null
		
		if locale_group.is_empty():
			lang_file = DiscourseDialogLocale.new()
			lang_file.locale = lang_key
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
		
		for region_code in locale_map.keys():
			var locale_key: String = TranslationServer.standardize_locale(lang_key + "_" + region_code)
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
			push_warning(
				"[DISCOUSE] File contains more localization data than is being exported: " + resource_path + "\n. Verify locale map.")
		extra_data_warned = true
		break
	
	if extra_data_warned:
		return new_files
	
	for string_key in format_strings.keys():
		var used_string_locales = format_strings[string_key].keys()
		if not used_locales.has_all(used_string_locales):
			push_warning(
				"[DISCOUSE] File contains more localization data than is being exported: " + resource_path + "\n. Verify locale map.")
			break
	
	return new_files


func _add_locale_data(file: DiscourseDialogLocale, localization_id: String, locale: String) -> void:
	for node_id in localization.keys():
		var data = localization[node_id]
		
		if not data.has_all(["type", "unlocalized", "locales"]) or typeof("unlocalized") != TYPE_STRING or typeof(data["type"]) != TYPE_INT or typeof(data["locales"]) != TYPE_DICTIONARY:
			push_error(
					"[DISCOURSE] Incomplete or corrupt data for node with UID \"" + node_id + "\" - type/unlocalized/locales check.")
		var localized: bool = data["unlocalized"].is_empty()
		
		if data["type"] == LocalizationType.TEXT:
			var warn: bool = typeof(DictUtils.get_nested_value(data, ["locales", locale])) != TYPE_STRING if localized else false
			DictUtils.set_nested_value(
					file.localization,
					[localization_id, node_id, "dialog"],
					DictUtils.get_nested_value(
							data,
							["locales", locale],
							"") if localized else data["unlocalized"])
			if warn:
				if localized:
					push_warning("[DISCOURSE] Unlocalized data for node UID \"" + node_id + "\" is missing.")
				else:
					push_warning("[DISCOURSE] Localization data for node UID \"" + node_id + "\" for locale \"" + locale + "\" is missing.")
		
		elif data["type"] == LocalizationType.CHOICES:
			var warn: bool = typeof(DictUtils.get_nested_value(data, ["locales", locale])) != TYPE_ARRAY if data["unlocalized"].is_empty() else typeof(data["unlocalized"]) != TYPE_ARRAY
			
			if warn:
				if localized:
					push_warning("[DISCOURSE] Localization data for node UID \"" + node_id + "\" for locale \"" + locale + "\" is missing.")
				else:
					push_warning("[DISCOURSE] Unlocalized data for node UID \"" + node_id + "\" is missing.")
			
			var choices: Array[String] = []
			
			var idx: int = -1
			
			if localized:
				for data_entry in data["unlocalized"]:
					idx += 1
					if typeof(data_entry) == TYPE_STRING:
						choices.append(data_entry)
					else:
						choices.append("")
						push_error("[DISCORUSE] Unlocalized choice with index " + str(idx) + " isn't a string.")
			else:
				var choice_entry = DictUtils.get_nested_value(
						data, ["locales", locale])
				if typeof(choice_entry) == TYPE_ARRAY:
					for data_entry in choice_entry:
						idx += 1
						if typeof(data_entry) == TYPE_STRING:
							choices.append(data_entry)
						else:
							choices.append("")
							push_warning("[DISCORUSE] Choice with index " + str(idx) + " on locale " + locale + " isn't a string.")
			
			var choice_size: int = choices.size()
			var target_size: int = 0
			
			var choice_data = DictUtils.get_nested_value(node_data, [node_id, "metadata", "choices"])
			if typeof(choice_data) == TYPE_ARRAY:
				target_size = choice_data.size()
			else:
				push_warning(
						"[DISCOURSE] Localization for node UID " + node_id + " included, but node data is missing or corrupt.")
				target_size = choice_size
			
			if choice_size != target_size:
				push_warning(
						"[DISCOURSE] Localized choice count for dialog \" " + resource_path + "\" is different from the registered data. Localized Choices: " + str(choice_size) + ", Data target: " + str(target_size) + ". Exported localization will be resized to respect data.")
				choices.resize(target_size)
			
			file.set_choices(
					localization_id,
					node_id,
					choices)
		else:
			push_warning(
					"[DISCOURSE] Localization export for node with UID \"" + node_id + "\" couldn't define type.")
			var nameless_id = DictUtils.get_nested_value(node_data, [node_id, "name"])
			if typeof(nameless_id) == TYPE_STRING_NAME:
				push_warning("[DISCOURSE - INFO] ID for typeless node found: \"" + String(nameless_id) + "\"")
	
	for format_key in format_strings.keys():
		if not format_strings[format_key].has(locale) or typeof(format_strings[format_key][locale]) != TYPE_DICTIONARY:
			push_warning("[DISCOURSE] Format string with key " + format_key + " doesn't have valid localization data for language: " + locale + ". Skipping")
			continue
		
		var data: Dictionary = format_strings[format_key][locale]
		
		if not data.has_all(["base_string", "format"]) or typeof(data["base_string"]) != TYPE_STRING or typeof(data["format"]) != TYPE_DICTIONARY:
			push_error("[DISCOURSE] Format string with key " + format_key + " doesn't have valid localization data for language: " + locale + ". Skipping")
			continue
		
		var valid_formats: Dictionary = {}
		
		for format_slice in data["format"].keys():
			var valid_cases: Dictionary = {}
			
			if typeof(data["format"][format_slice]) != TYPE_DICTIONARY or not data["format"][format_slice].has_all(["default", "cases"]) or typeof(data["format"][format_slice]["default"]) != TYPE_STRING or typeof(data["format"][format_slice]["cases"]) != TYPE_DICTIONARY:
				push_error("[DISCOURSE] Format string with key " + format_key + " format " + format_slice + " has missing or corrupt data. Skipping")
				continue
			
			var formats: Dictionary = data["format"][format_slice]
			
			for case in formats["cases"].keys():
				if typeof(case) != TYPE_STRING or typeof(case) != TYPE_STRING_NAME:
					push_error("[DISCOURSE] Case is not of type string. Exception on: " + "/".join([format_key, locale, format_slice]))
					continue
				
				if typeof(formats["cases"][case]) != TYPE_STRING:
					push_error("[DISCOURSE] Case of format string with key " + format_key + " format " + format_slice + " case " + case + " is not of type string. Patching with warning string.")
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


## Returns an array with a split path used for variable access on the Blackboard.
func split_path_variable(path: String) -> Array[StringName]:
	var split: PackedStringArray = path.rsplit("/", false, 1)
	var path_array: Array[StringName] = []
	for path_component in split:
		path_array.append(StringName(path_component))
	if split.size() != 2:
		path_array.resize(2)
	return path_array


## Returns an array with all the format arguments of the prase [param phrase_text].[br]
## It'll only look for format arguments that start with $ or !.
static func get_phrase_arguments(phrase_text: String, trim_brackets: bool = false) -> Array[String]:
	var all_arguments: Array[String] = []
	
	var regex_search: RegEx = RegEx.new()
	
	regex_search.compile("\\{[\\$\\!][^\\s\\}]+\\}")
	
	if trim_brackets:
		for regex_match in regex_search.search_all(phrase_text): # $variable
			all_arguments.append(regex_match.get_string().trim_prefix("{").trim_suffix("}"))
	else:
		for regex_match in regex_search.search_all(phrase_text): # $variable
			all_arguments.append(regex_match.get_string())
	
	return all_arguments


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


func get_id_target(id: StringName) -> StringName:
	for entry in node_data.keys():
		if entry["name"] == id:
			return entry
	return &""


func has_id(id: String) -> bool:
	for entry in node_data.keys():
		if entry["name"] == id:
			return true
	return false


func link_id(id: String, uuid: StringName) -> bool:
	return false
