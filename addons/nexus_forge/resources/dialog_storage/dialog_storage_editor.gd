@tool
@icon("res://addons/nexus_forge/icons/dialog_full.svg")
class_name EditorDiscourseDialog
extends DiscourseDialog
## A resource containing a dialog ONLY to be used in the Godot editor.
##
## Editor only files. On export, all EditorDiscourseDialog are converted to
## [ReleaseDiscourseDialog] and the original files are NOT included.


@export_storage var scroll_offset: Vector2 = Vector2.ZERO:
	set(new_scroll):
		scroll_offset = new_scroll.snappedf(0.001)
@export_storage var zoom: float = 1.0:
	set(new_zoom):
		zoom = snappedf(new_zoom, 0.001)

# This is the localization for nodes. Each UUID represents the node UUID. EAch value
# changes depending on the node type. THe type can be checked by looking at the
# nodes[uuid]["node_type"] value.
# To save storage, the nodes that don't need localization (For example, the ones that use only numbers)
# will be stored in the _global key. When loading the plugin, the resource will first
# check if the UUID exists on the node_localization["_global"] dictionary and if not
# THEN return the specific language localization.
@export_storage var locale_map: Dictionary[String, PackedStringArray] = {
	#"en": ["US", "GB"]
}

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


@export_storage var node_localization: Dictionary[StringName, Dictionary] = {
	#"a809f219-f5e1-4dc2-a041-4d200062dd53": {
		#"common": {"dialog": "10-5=5"}},
	#"629de91c-d6c1-4f67-a287-b6899695b0a6": {
		#"en": {
			#"base": {"dialog": "Common English"},
			#"US": {"dialog": "American English, bro!"},
			#"GB": {"dialog": "British English, sir."}},
		#"es": {
			#"base": {"dialog": "Ingles comun."}}},
	#"fccfaeaa-6014-4841-ab77-770775afd4e7": {
		#"en": {
			#"base": {"options": ["grey", "green"]},
			#"GB": {"options": ["gray", "green"]}}}
}

@export_storage var localized_strings: Dictionary[String, Dictionary] = {
	#"TITLE": {
		#"en": {
			#"base": {
				#"text": "Hello {-player}",
				#"arguments": {
					#"player": {
						#"default": ":3",
						#"custom": {
							#"wulfre": "bear",
							#"other": "{player}"}}}},
			#"US": "Hello burgor",
			#"GB": "Salutations tea tea"},
		#"es": {
			#"base": {
				#"text": ""
			#}
		#}
	#}
}

# Example of how data will be structured on dialog_nodes
#@export var dialog_nodes: Dictionary[String, Dictionary] = {
	#"629de91c-d6c1-4f67-a287-b6899695b0a6": {
		#"node_type": DiscourseGraphNode.DialogueNodeType.DIALOG,
		#"position": Vector2(0, 100),
		#"size": Vector2(200, 100),
		#"character_id": "Player",
		#"persist": true,
		#"output_connections": {
			#"next_node": {
				#"target_node_uuid": "fccfaeaa-6014-4841-ab77-770775afd4e7",
				#"target_port": 0
			#}
		#}
	#},
	#"629de91c-d6c1-4f67-a287-b6899695b0a7": {
		#"node_type": DiscourseGraphNode.DialogueNodeType.OPTIONS,
		#"position": Vector2(0, 100),
		#"options": [
			#{
				#"option_text": "Hello!",
				#"output_connections": {"next_node": {}},
				#"input_connections": {"settings": {}}}
		#],
	#}
#}


#@export var localized_strings: Dictionary[String, Dictionary] = {
	#"TITLE": {
		#"en": {
			#"base": {
				#"text": "Hello {-player}",
				#"arguments": {
					#"player": {
						#"default": ":3",
						#"custom": {
							#"wulfre": "bear",
							#"other": "{player}"}}}},
			#"US": "Hello burgor",
			#"GB": "Salutations tea tea"},
		#"es": {
			#"base": {
				#"text": ""
			#}
		#}
	#}
#}

@export_storage var node_structure: Array[Dictionary] = [
	#{"is_node": true, "uuid": "kasdjlaksd"},
	#{"is_node": false, "name": "Folder", "items": [{"is_node": true, "uuid": "kasjdlasjk"}]}
]


## Returns the text of a localized string.
func get_localized_string(key: String, language: String, region: String = "base") -> String:
	if localized_strings.has(key) and\
			localized_strings[key].has(language) and\
			localized_strings[key][language].has(region):
		return localized_strings[key][language][region]["text"]
	printerr("No string with key \"", key,"\" and locale ", language + "_" + region, " exists.")
	return ""


## Returns all format keys that the localized string has.
func get_localized_string_formats(key: String, language: String, region: String = "base") -> Array[String]:
	var keys: Array[String] = []
	if localized_strings.has(key) and localized_strings[key].has(language):
		keys.assign(
				localized_strings[key][language][region]["arguments"].keys())
	return keys


## Returns the format keys and the possible formats of a given key.
func get_localized_arguments(key: String, language: String, region: String = "base") -> Dictionary[String, Dictionary]:
	if localized_strings.has(key) and\
			localized_strings[key].has(language) and\
			localized_strings[key][language].has(region):
		return localized_strings[key][language][region]["arguments"].duplicate(true)
	printerr("No arguments with key \"", key,"\" and locale ", language + "_" + region, " exist.")
	return Dictionary({}, TYPE_STRING, &"", null, TYPE_DICTIONARY, &"", null)


## Returns strings formatted for NexusForge plugin use.
func get_editor_localized_strings(language: String, region: String = "base") -> Dictionary[String, Dictionary]:
	var data: Dictionary[String, Dictionary] = {}
	for key in localized_strings.keys():
		data[key] = localized_strings[key][language][region].duplicate(true)
	return data


## Creates a localized string with the given [param key] unless it already exists.
func create_localized_string(key: String, text: String) -> void:
	if localized_strings.has(key):
		return
	
	var data: Dictionary[String, Dictionary] = {}
	
	for language in locale_map.keys():
		set_localized_string(key, text, language)
		for region in locale_map[language]:
			set_localized_string(key, text, language, region)


## Sets or creates a localized string with the given key.
func set_localized_string(key: String, text: String, language: String, region: String = "base") -> void:
	if not localized_strings.has(key):
		localized_strings[key] = Dictionary({},
				TYPE_STRING, &"", null,
				TYPE_DICTIONARY, &"", null)
	if not localized_strings[key].has(language):
		localized_strings[key][language] = Dictionary({}, 
				TYPE_STRING, &"", null,
				TYPE_DICTIONARY, &"", null)
	
	if not localized_strings[key][language].has(region):
		var new_reg_dict: Dictionary[String, Variant] = {
			"text": "",
			"arguments": Dictionary({},
					TYPE_STRING, &"", null,
					TYPE_DICTIONARY, &"", null)}
		localized_strings[key][language][region] = new_reg_dict
	
	if localized_strings[key][language][region]["text"] == text:
		return
	
	localized_strings[key][language][region]["text"] = text

	var arg_data: Array[String] = get_phrase_arguments(text)
	
	for existing_key in localized_strings[key][language][region]["arguments"].keys():
		if not arg_data.has(existing_key):
			localized_strings[key][language][region]["arguments"].erase(existing_key)
	
	for new_key in arg_data:
		if not localized_strings[key][language][region]["arguments"].has(new_key):
			var new_key_data: Dictionary[String, Variant] = {
				"default": "",
				"custom": Dictionary({},
						TYPE_STRING, &"", null,
						TYPE_STRING, &"", null)}
			localized_strings[key][language][region]["arguments"][new_key] = new_key_data


## Sets the default case from a localized string with the given key.
func set_localized_string_argument_default_case(key: String, language: String, region: String, argument: String, default_text: String) -> void:
	if localized_strings.has(key) and localized_strings[key].has(language) and localized_strings[key][language].has(region) and localized_strings[key][language][region]["arguments"].has(argument):
		localized_strings[key][language][region]["arguments"][argument]["default"] = default_text


## Returns the default case from a localized string with the given key.
func get_localized_string_argument_default_case(key: String, language: String, region: String, argument: String) -> String:
	if localized_strings.has(key) and localized_strings[key].has(language) and localized_strings[key][language].has(region) and localized_strings[key][language][region]["arguments"].has(argument):
		return localized_strings[key][language][region]["arguments"][argument]["default"]
	return ""


## Sets the format case on the given key to [param text].
func set_localized_string_custom_case(key: String, language: String, region: String, argument: String, case: String, text: String) -> void:
	if localized_strings.has(key) and localized_strings[key].has(language) and localized_strings[key][language].has(region) and localized_strings[key][language][region]["arguments"].has(argument):
		localized_strings[key][language][region]["arguments"][argument]["custom"][case] = text


## Clears the list of custom cases from the given key.
func clear_localized_string_cases(key: String, language: String, region: String, argument: String) -> void:
	if localized_strings.has(key) and localized_strings[key].has(language) and localized_strings[key][language].has(region) and localized_strings[key][language][region]["arguments"].has(argument):
		localized_strings[key][language][region]["arguments"][argument]["custom"].clear()


## Returns all the registered node uuids.
func get_node_uuids() -> Array:
	return dialog_nodes.keys()


## Returns all the registered frames uuids.
func get_frames_uuids() -> Array:
	return node_frames.keys()


## Returns the node data from a the node with the given [param uuid] in a specific locale.
func get_node_data(node_uuid: StringName, language: String, region: String = "") -> Dictionary:
	if not dialog_nodes.has(node_uuid):
		return {}
	var data: Dictionary = dialog_nodes[node_uuid].duplicate(true)
	#var fixed_region: String = "common" if region.is_empty() else region
	if language.is_empty():
		language = "common"
	if region.is_empty():
		region = "base"
	
	match data["node_type"] as NodeTypes:
		NodeTypes.DIALOG:
			if language == "common" or not data["has_localization"]:
				data["dialog_text"] = node_localization[node_uuid]["common"]["dialog"]
			else:
				data["dialog_text"] = node_localization[node_uuid][language][region]["dialog"]
		NodeTypes.OPTIONS:
			var options_translated: Array[String] = []
			if language == "common" or not data["has_localization"]:
				options_translated.assign(node_localization[node_uuid]["common"]["options"])
			var idx: int = -1
			for option:Dictionary in data["options"]:
				idx += 1
				option["option_text"] = options_translated[idx]
		NodeTypes.LOCALIZED_TEXT:
			if language == "common":
				data["text"] = node_localization[node_uuid]["common"]["text"]
			else:
				data["text"] = node_localization[node_uuid][language][region]["text"]
	
	return data


## Sets the locale for text (Dialogs & localized text nodes). Passing [code]""[/code]
## on [param locale] will set the text as unlocalized, meaning that the text will
## be the same on all localizations.[br]
## Note: Switching from a localized to an unlocalized node will clear the localization
## data completely and viceversa.
func set_localization_text(uuid: StringName, text: String, language: String, region: String = "base") -> void:
	if not node_localization.has(uuid):
		node_localization[uuid] = {}
	var localization_level: Dictionary = node_localization[uuid]
	
	if not localization_level.has(language):
		localization_level[language] = {}
	localization_level = localization_level[language]
	
	if language != "common":
		if not localization_level.has(region):
			localization_level[region] = {}
		localization_level = localization_level[region]
	
	match dialog_nodes[uuid]["node_type"]:
		NodeTypes.DIALOG:
			localization_level["dialog"] = text
		NodeTypes.LOCALIZED_TEXT:
			localization_level["text"] = text
		_:
			printerr("Tried to set text of a non-compatible node.")
			return
	
	if language != "common" and region != "base":
		if not locale_map.has(language):
			locale_map[language] = PackedStringArray()
		locale_map[language].append(region)


func set_unlocalized_text(uuid: StringName, text: String) -> void:
	set_localization_text(uuid, text, "common", "base")

## Sets ALL the choices for an option node. Passing an empty string on [param locale]
## will set the options as unlocalized.[br]
## Note: Switching from a localized to an unlocalized node will clear the localization
## data completely and viceversa.
func set_localization_choices(uuid: StringName, options: Array[String], language: String, region: String = "base") -> void:
	if not node_localization.has(uuid):
		node_localization[uuid] = {}
	var exists: bool = true
	var localization_level: Dictionary = node_localization[uuid]
	
	if not localization_level.has(language):
		localization_level[language] = {}
		exists = false
	localization_level = localization_level[language]
	
	if language != "common":
		if not localization_level.has(region):
			localization_level[region] = {}
		localization_level = localization_level[region]
		exists = false
	
	var new_options: Array[String] = options.duplicate()
	var target_array: Array[String] = []
	
	if exists == false:
		var clean_options: Array[String] = []
		localization_level["options"] = clean_options
		target_array = clean_options
	elif language == "common":
		target_array = node_localization[uuid][language]["options"]
	else:
		target_array = node_localization[uuid][language][region]["options"]
	
	target_array.clear()
	target_array.assign(new_options)
	
	if language != "common" and region != "base":
		if not locale_map.has(language):
			locale_map[language] = PackedStringArray()
		locale_map[language].append(region)


## Sets choices unlocalized.
func set_unlocalized_choices(uuid: StringName, options: Array[String]) -> void:
	set_localization_choices(uuid, options, "common", "base")


## Sets a single choice for an option node. Specifically the choice with index
## [param option_index]. To set an unlocalized choice pass [code]common[/code]
## as the language argument. No region is needed when doing an unlocalized
## option.
func update_localization_choice(uuid: StringName, option_index: int, option_text: String, language: String, region: String = "base") -> void:
	if option_index < 0 or dialog_nodes[uuid]["options"].size() <= option_index:
		return
	
	var base_level: Dictionary = node_localization[uuid]
	
	if language == "common":
		base_level = base_level["common"]
	else:
		base_level = base_level[language][region]
	
	base_level["options"][option_index] = option_text


## Changes the amount of choices from the given choice node UUID to be [param new_count]
func set_localization_choice_count(uuid: StringName, new_count: int) -> void:
	if not dialog_nodes.has(uuid) or dialog_nodes[uuid]["node_type"] != NodeTypes.OPTIONS or new_count < 0:
		return
	
	dialog_nodes[uuid]["options"].resize(new_count)
	
	if not node_localization.has(uuid):
		return
	
	if node_localization[uuid].has("common"):
		node_localization[uuid]["common"]["options"].resize(new_count)
	else:
		for language_code in node_localization[uuid].keys():
			for country_code in node_localization[uuid][language_code].keys():
				node_localization[uuid][language_code][country_code]["options"].resize(new_count)


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
func register_node(uuid: StringName, data: Dictionary, parent_frame: String = "") -> void:
	dialog_nodes[uuid] = data.duplicate(true)
	match data["node_type"]:
		NodeTypes.DIALOG:
			dialog_nodes[uuid].erase("dialog_text")
		NodeTypes.OPTIONS:
			for option:Dictionary in dialog_nodes[uuid]["options"]:
				option.erase("option_text")
		NodeTypes.LOCALIZED_TEXT:
			dialog_nodes[uuid].erase("text")
		NodeTypes.ENTRY:
			entry_node = uuid
	if not parent_frame.is_empty() and node_frames.has(parent_frame) and not node_frames[parent_frame]["nodes"].has(uuid):
		node_frames[parent_frame]["nodes"].append(uuid)


## Builds and returns the custom ID static UUID relationship between nodes.[br]
## The returned key is the custom ID, while the values are the unique UUIDs.
func get_id_map() -> Dictionary[String, StringName]:
	var map: Dictionary[String, StringName] = {}
	for node_uuid in dialog_nodes.keys():
		map[dialog_nodes[node_uuid]["custom_id"]] = node_uuid
	return map


## Clears the resource.
func clear() -> void:
	scroll_offset = Vector2.ZERO
	zoom = 1.0
	node_localization.clear()
	node_frames.clear()
	dialog_nodes.clear()


## Converts this resource to a [ReleaseDiscourseDialog].
func convert_for_release(localization_uuid: String = "") -> ReleaseDiscourseDialog:
	var available_methods: Dictionary = preload("res://addons/nexus_forge/discourse/nodes/method_call_node.gd").get_user_methods()
	var available_signals: Dictionary = preload("res://addons/nexus_forge/discourse/nodes/signal_node.gd").get_user_signals()
	
	var release_dialog: ReleaseDiscourseDialog = ReleaseDiscourseDialog.new()
	var id_map: Dictionary[String, StringName] = {}
	
	if localization_uuid.is_empty():
		release_dialog.localization_uuid = StringName(UUID.generate_new())
	else:
		release_dialog.localization_uuid = StringName(localization_uuid)
	
	# UUID: Value of the node.
	# This dictionary will only hold data that is STATIC, such as the data
	# generated through the value node which is unchanging. This is to
	# skip one jump from a node to a data node and instead store the data
	# directly.
	var data_nodes: Dictionary[StringName, Variant] = {}
	
	# UUID(Anchor pointer): UUID(Anchor Target)
	# Example "123"(anchor pointer uuid) -> "456"(Anchor) -> "789"(Anchor connection)
	# anchor_nodes["123"] = "789"
	# This is to skip the anchor nodes as they are only a visual helper for the editor
	# on the release files, anchor nodes have no use.
	var anchor_nodes: Dictionary[StringName, StringName] = {}
	
	# UUID(merger_id): UUID(merger_next_node)
	var dialog_mergers: Dictionary[StringName, StringName] = {}
	
	# Declaration of the recursive lambda. Required as I can't call recursively
	# inside of the delcaration
	var get_target_lambda: Callable = Callable()
	# Recursive function to find the final target of an UUID. Basically unfucks
	# whatever spaghetti connections there might be between nodes, joiners and
	# anchors
	get_target_lambda = func(lambda_uuid: StringName, _origin: StringName = &"", _iteration: int = 0):
		if _origin == lambda_uuid or 100 <= _iteration:
			if 100 <= _iteration:
				printerr("Error: Over 99 anchor/joiner direct connections found. Breaking connection.\nAt this point, I'm pretty sure you're just drawing a picture of a worm. Please stop drawing worms.")
			return &""
		
		if _origin.is_empty():
			_origin = lambda_uuid
		
		if anchor_nodes.has(lambda_uuid):
			return get_target_lambda.call(anchor_nodes[lambda_uuid], _origin, _iteration + 1)
		elif dialog_mergers.has(lambda_uuid):
			return get_target_lambda.call(dialog_mergers[lambda_uuid], _origin, _iteration + 1)
		else:
			return lambda_uuid
	
	#var get_target_lambda: Callable = func (uuid: StringName) -> StringName:
		#return _get_target_uuid.call(uuid, _get_target_uuid)
	
	var node_uuids: Array[StringName] = []
	node_uuids.assign(dialog_nodes.keys())
	
	for node_uuid in node_uuids:
		if dialog_nodes[node_uuid]["node_type"] == NodeTypes.VALUE:
			data_nodes[node_uuid] = dialog_nodes[node_uuid]["value"]
		elif dialog_nodes[node_uuid]["node_type"] == NodeTypes.ANCHOR_POINTER:
			var target_node: StringName = &""
			if not dialog_nodes[node_uuid]["anchor_target"].is_empty():
				target_node = dialog_nodes[dialog_nodes[node_uuid]["anchor_target"]]["output_connections"]["next_node"]
			anchor_nodes[node_uuid] = target_node
		elif dialog_nodes[node_uuid]["node_type"] == NodeTypes.DIALOG_MERGE:
			var target_node: StringName = &""
			if not dialog_nodes[node_uuid]["output_connections"]["next_node"]["target_node_uuid"].is_empty():
				target_node = StringName(dialog_nodes[node_uuid]["output_connections"]["next_node"]["target_node_uuid"])
			dialog_mergers[node_uuid] = target_node
		else:
			continue
	
	var add_id: bool = false
	
	for node_id in node_uuids:
		var data: Dictionary[String, Variant] = {
			"node_type": dialog_nodes[node_id]["node_type"]}
		match dialog_nodes[node_id]["node_type"]:
			NodeTypes.ENTRY:
				add_id = true
				data["next_node"] = get_target_lambda.call(node_id)
			NodeTypes.DIALOG:
				add_id = true
				var character_settings: Dictionary = {
					"display_name": "",
					"portrait_id": "",
					"display_name_node": &"",
					"portrait_id_node": &""}
				
				var dialog_settings: Dictionary = {
					"font_resource": "",
					"dialog_scene": "",
					"dialog_speed": 0,
					"font_resource_node": &"",
					"dialog_scene_node": &"",
					"dialog_speed_node": &""}
				
				if not dialog_nodes[node_id]["input_connections"]["dialog_settings"]["target_node_uuid"].is_empty():
					var character_settings_data: Dictionary = dialog_nodes[dialog_nodes[node_id]["input_connections"]["dialog_settings"]["target_node_uuid"]]
					
					if not character_settings_data["input_connections"]["display_name"]["target_node_uuid"].is_empty():
						if data_nodes.has(character_settings_data["input_connections"]["display_name"]["target_node_uuid"]):
							character_settings["display_name"] = data_nodes[character_settings_data["input_connections"]["display_name"]["target_node_uuid"]]
						else:
							character_settings["display_name_node"] = StringName(character_settings_data["input_connections"]["display_name"]["target_node_uuid"])
					
					if not character_settings_data["input_connections"]["portrait_id"]["target_node_uuid"].is_empty():
						if data_nodes.has(character_settings_data["input_connections"]["portrait_id"]["target_node_uuid"]):
							character_settings["portrait_id"] = data_nodes[character_settings_data["input_connections"]["display_name"]["target_node_uuid"]]
						else:
							character_settings["portrait_id_node"] = StringName(character_settings_data["input_connections"]["display_name"]["target_node_uuid"])
				
				if not dialog_nodes[node_id]["input_connections"]["character_settings"]["target_node_uuid"].is_empty():
					var dialog_settings_data: Dictionary = dialog_nodes[dialog_nodes[node_id]["input_connections"]["character_settings"]["target_node_uuid"]]
					
					if not dialog_settings_data["input_connections"]["font_resource"]["target_node_uuid"].is_empty():
						if data_nodes.has(dialog_settings_data["input_connections"]["font_resource"]["target_node_uuid"]):
							dialog_settings["font_resource"] = data_nodes[dialog_settings_data["input_connections"]["font_resource"]["target_node_uuid"]]
						else:
							dialog_settings["font_resource_node"] = StringName(dialog_settings_data["input_connections"]["font_resource"]["target_node_uuid"])
					
					if not dialog_settings_data["input_connections"]["dialog_scene"]["target_node_uuid"].is_empty():
						if data_nodes.has(dialog_settings_data["input_connections"]["dialog_scene"]["target_node_uuid"]):
							dialog_settings["dialog_scene"] = data_nodes[dialog_settings_data["input_connections"]["dialog_scene"]["target_node_uuid"]]
						else:
							dialog_settings["dialog_scene_node"] = StringName(dialog_settings_data["input_connections"]["dialog_scene"]["target_node_uuid"])
					
					if not dialog_settings_data["input_connections"]["dialog_speed"]["target_node_uuid"].is_empty():
						if data_nodes.has(dialog_settings_data["input_connections"]["dialog_speed"]["target_node_uuid"]):
							dialog_settings["dialog_speed"] = data_nodes[dialog_settings_data["input_connections"]["dialog_speed"]["target_node_uuid"]]
						else:
							dialog_settings["dialog_speed_node"] = StringName(dialog_settings_data["input_connections"]["dialog_speed"]["target_node_uuid"])

				data["character_id"] = dialog_nodes[node_id]["character_id"]
				data["persist"] = dialog_nodes[node_id]["persist"]
				data["character_settings"] = character_settings
				data["dialog_settings"] = dialog_settings
				data["text_source"] = StringName(dialog_nodes[node_id]["input_connections"]["dialog_text_source"]["target_node_uuid"])
				data["next_node"] = get_target_lambda.call(dialog_nodes[node_id]["output_connections"]["next_node"]["target_node_uuid"])
			NodeTypes.OPTIONS:
				add_id = true
				var options: Array[Dictionary] = []
				for option:Dictionary in dialog_nodes[node_id]["options"]:
					var new_option: Dictionary[String, Variant] = {
						"next_node": get_target_lambda.call(StringName(option["output_connections"]["next_node"]["target_node_uuid"])),
						"settings": {
							"available": true,
							"locked": false,
							"lock_hint": "",
							"available_node": &"",
							"locked_node": &"",
							"lock_hint_node": &""}}
					
					if not option["input_connections"]["settings"]["target_node_uuid"].is_empty():
						var option_settings: Dictionary = dialog_nodes[option["input_connections"]["settings"]["target_node_uuid"]]
						if not option_settings["input_connections"]["option_available"]["target_node_uuid"].is_empty():
							if data_nodes.has(option_settings["input_connections"]["option_available"]["target_node_uuid"]):
								new_option["settings"]["available"] = data_nodes[option_settings["input_connections"]["option_available"]["target_node_uuid"]]
							else:
								new_option["settings"]["available_node"] = StringName(option_settings["input_connections"]["option_available"]["target_node_uuid"])
						
						if not option_settings["input_connections"]["option_locked"]["target_node_uuid"].is_empty():
							if data_nodes.has(option_settings["input_connections"]["option_locked"]["target_node_uuid"]):
								new_option["settings"]["locked"] = data_nodes[option_settings["input_connections"]["option_locked"]["target_node_uuid"]]
							else:
								new_option["settings"]["locked_node"] = StringName(option_settings["input_connections"]["option_locked"]["target_node_uuid"])
		
						if not option_settings["input_connections"]["locked_hint"]["target_node_uuid"].is_empty():
							if data_nodes.has(option_settings["input_connections"]["locked_hint"]["target_node_uuid"]):
								new_option["settings"]["lock_hint"] = data_nodes[option_settings["input_connections"]["locked_hint"]["target_node_uuid"]]
							else:
								new_option["settings"]["lock_hint_node"] = StringName(option_settings["input_connections"]["locked_hint"]["target_node_uuid"])
					options.append(new_option)
				data["options"] = options
			NodeTypes.BRANCH:
				add_id = true
				data["result"] = StringName(dialog_nodes[node_id]["input_connections"]["path_direction"]["target_node_uuid"])
				data["case_true"] = get_target_lambda.call(StringName(dialog_nodes[node_id]["output_connections"]["next_node_true"]["target_node_uuid"]))
				data["case_false"] = get_target_lambda.call(StringName(dialog_nodes[node_id]["output_connections"]["next_node_false"]["target_node_uuid"]))
			NodeTypes.CONDITION_SELECT:
				add_id = true
				data["result" ] = StringName(dialog_nodes[node_id]["input_connections"]["result"]["target_node_uuid"])
				data["true_value"] = get_target_lambda.call(StringName(dialog_nodes[node_id]["input_connections"]["true_value"]["target_node_uuid"]))
				data["false_value"] = get_target_lambda.call(StringName(dialog_nodes[node_id]["input_connections"]["false_value"]["target_node_uuid"]))
			NodeTypes.COMPARATION:
				add_id = true
				data["operator"] = dialog_nodes[node_id]["operator"]
				data["value_a"] = StringName(dialog_nodes[node_id]["input_connections"]["node_a"]["target_node_uuid"])
				data["value_b"] = StringName(dialog_nodes[node_id]["input_connections"]["node_b"]["target_node_uuid"])
			NodeTypes.EVENT:
				add_id = true
				var var_val: StringName = StringName(dialog_nodes[node_id]["input_connections"]["variable_value"]["target_node_uuid"])
				data["value"] = var_val
				
				if not dialog_nodes[node_id]["input_connections"]["callable"]["target_node_uuid"].is_empty():
					var callable_uuid: StringName = dialog_nodes[node_id]["input_connections"]["callable"]["target_node_uuid"]
					if available_methods.has(dialog_nodes[callable_uuid]["method"]):
						data["callable"] = StringName(dialog_nodes[node_id]["input_connections"]["callable"]["target_node_uuid"])
					else:
						data["callable"] = &""
						printerr("[Discourse] Warning: Issue when exporting ", resource_path, ". Event ", dialog_nodes[node_id]["name"], " calls an inexistent method.")
				else:
					data["callable"] = &""
				
				if not dialog_nodes[node_id]["input_connections"]["signal"]["target_node_uuid"].is_empty():
					var signal_uuid: StringName = dialog_nodes[node_id]["input_connections"]["signal"]["target_node_uuid"]
					if available_signals.has(dialog_nodes[signal_uuid]["signal"]):
						data["signal"] = StringName(dialog_nodes[node_id]["input_connections"]["signal"]["target_node_uuid"])
					else:
						data["signal"] = &""
						printerr("[Discourse] Warning: Issue when exporting ", resource_path, ". Event ", dialog_nodes[node_id]["name"], " emits an inexistent signal.")
				else:
					data["signal"] = &""
				data["next_node"] = get_target_lambda.call(StringName(dialog_nodes[node_id]["output_connections"]["next_node"]["target_node_uuid"]))
				if var_val.is_empty():
					data["variable_path"] = &""
					data["variable"] = &""
				else:
					var split_vars: Array[StringName] = split_path_variable(
							dialog_nodes[node_id]["variable_path"])
					if split_vars.size() < 2:
						data["variable_path"] = &""
						data["variable"] = &""
					else:
						data["variable_path"] = split_vars[0]
						data["variable"] = split_vars[1]
			NodeTypes.MATCH:
				add_id = true
				var cases: Array[Dictionary] = []
				
				for case:Dictionary in dialog_nodes[node_id]["cases"]:
					var new_case: Dictionary[String, Variant] = {}
					new_case["value"] = case["value"]
					new_case["next_node"] = get_target_lambda.call(StringName(case["output_connections"]["next_node"]["target_node_uuid"]))
				
				data["case_default"] = get_target_lambda.call(StringName(dialog_nodes[node_id]["output_connections"]["default"]["target_node_uuid"]))
				data["match_value"] = StringName(dialog_nodes[node_id]["input_connections"]["match_value_source"]["target_node_uuid"])
				data["cases"] = cases
			NodeTypes.PAUSE:
				add_id = true
				data["next_node"] = get_target_lambda.call(StringName(dialog_nodes[node_id]["output_connections"]["next_node"]["target_node_uuid"]))
			NodeTypes.RANDOM:
				add_id = true
				var options: Array[Dictionary] = []
				
				for option:Dictionary in dialog_nodes[node_id]["options"]:
					var new_option: Dictionary[String, StringName] = {}
					new_option["target"] = get_target_lambda.call(StringName(option["output_connections"]["next_node"]["target_node_uuid"]))
					new_option["weight_override"] = StringName(option["output_connections"]["weight"]["target_node_uuid"])
					options.append(new_option)
				
				data["default_override"] = StringName(dialog_nodes[node_id]["input_connections"]["default_weight"]["target_node_uuid"])
				data["options"] = options
			NodeTypes.TYPE_GUARD:
				add_id = true
				data["type"] = typeof(dialog_nodes[node_id]["fallback_value"])
				data["value"] = StringName(dialog_nodes[node_id]["input_connections"]["value"]["target_node_uuid"])
				data["fallback"] = dialog_nodes[node_id]["fallback_value"]
			NodeTypes.SIGNAL:
				add_id = true
				var arguments: Array[Dictionary] = []
				for argument:Dictionary in dialog_nodes[node_id]["arguments"]:
					var new_argument: Dictionary[String, Variant] = {
						"data": null,
						"override": &""}
					if not argument["target_node_uuid"].is_empty():
						if data_nodes.has(argument["target_node_uuid"]):
							new_argument["data"] = data_nodes[argument["target_node_uuid"]]
						else:
							new_argument["override"] = StringName(argument["target_node_uuid"])
					arguments.append(new_argument)
				data["signal"] = StringName(dialog_nodes[node_id]["signal"])
				data["arguments"] = arguments
			NodeTypes.CALLABLE:
				add_id = true
				var arguments: Array[Dictionary] = []
				for argument:Dictionary in dialog_nodes[node_id]["arguments"]:
					var new_argument: Dictionary[String, Variant] = {
						"data": null,
						"override": &""}
					if not argument["target_node_uuid"].is_empty():
						if data_nodes.has(argument["target_node_uuid"]):
							new_argument["data"] = data_nodes[argument["target_node_uuid"]]
						else:
							new_argument["override"] = StringName(argument["target_node_uuid"])
				data["method"] = StringName(dialog_nodes[node_id]["method"])
				data["arguments"] = arguments
			NodeTypes.CALLABLE_RETURN:
				add_id = true
				var arguments: Array[Dictionary] = []
				for argument:Dictionary in dialog_nodes[node_id]["arguments"]:
					var new_argument: Dictionary[String, Variant] = {
						"data": null,
						"override": &""}
					if not argument["target_node_uuid"].is_empty():
						if data_nodes.has(argument["target_node_uuid"]):
							new_argument["data"] = data_nodes[argument["target_node_uuid"]]
						else:
							new_argument["override"] = StringName(argument["target_node_uuid"])
				data["method"] = StringName(dialog_nodes[node_id]["method"])
				data["arguments"] = arguments
			NodeTypes.VARIABLE_GET:
				add_id = true
				var path: StringName = &""
				var variable: StringName = &""
				if not dialog_nodes[node_id]["variable_path"].is_empty():
					var var_paths: Array[StringName] = split_path_variable(dialog_nodes[node_id]["variable_path"])
					if var_paths.size() == 2:
						path = var_paths[0]
						variable = var_paths[1]
				data["path"] = path
				data["variable"] = variable
			NodeTypes.RANDOM_VALUE:
				add_id = true
				data["random_type"] = dialog_nodes[node_id]["mode"]
				data["min_value"] = dialog_nodes[node_id]["values"]["base"]
				data["max_value"] = dialog_nodes[node_id]["values"]["max"]
				data["min_override"] = StringName(dialog_nodes[node_id]["input_connections"]["base_value"]["target_node_uuid"])
				data["max_override"] = StringName(dialog_nodes[node_id]["input_connections"]["max_value"]["target_node_uuid"])
			NodeTypes.RESOURCE:
				add_id = true
				data["path"] = dialog_nodes[node_id]["resource_path"]
			NodeTypes.DATA_EVENT:
				add_id = true
				var var_val: StringName = StringName(dialog_nodes[node_id]["input_connections"]["variable_value"]["target_node_uuid"])
				data["value"] = var_val
				
				if not dialog_nodes[node_id]["input_connections"]["callable"]["target_node_uuid"].is_empty():
					var callable_uuid: StringName = dialog_nodes[node_id]["input_connections"]["callable"]["target_node_uuid"]
					if available_methods.has(dialog_nodes[callable_uuid]["method"]):
						data["callable"] = StringName(dialog_nodes[node_id]["input_connections"]["callable"]["target_node_uuid"])
					else:
						data["callable"] = &""
						printerr("[Discourse] Warning: Issue when exporting ", resource_path, ". Data event ", dialog_nodes[node_id]["name"], " calls an inexistent method.")
				else:
					data["callable"] = &""
				
				if not dialog_nodes[node_id]["input_connections"]["signal"]["target_node_uuid"].is_empty():
					var signal_uuid: StringName = dialog_nodes[node_id]["input_connections"]["signal"]["target_node_uuid"]
					if available_signals.has(dialog_nodes[signal_uuid]["signal"]):
						data["signal"] = StringName(dialog_nodes[node_id]["input_connections"]["signal"]["target_node_uuid"])
					else:
						data["signal"] = &""
						printerr("[Discourse] Warning: Issue when exporting ", resource_path, ". Data event ", dialog_nodes[node_id]["name"], " emits an inexistent signal.")
				else:
					data["signal"] = &""
				
				data["data_source"] = StringName(dialog_nodes[node_id]["input_connections"]["data_input"]["target_node_uuid"])
				if var_val.is_empty():
					data["variable_path"] = &""
					data["variable"] = &""
				else:
					var split_vars: Array[StringName] = split_path_variable(
							dialog_nodes[node_id]["variable_path"])
					if split_vars.size() < 2:
						data["variable_path"] = &""
						data["variable"] = &""
					else:
						data["variable_path"] = split_vars[0]
						data["variable"] = split_vars[1]
			NodeTypes.LOCALIZED_TEXT:
				add_id = true
				data["text"] = node_id
			_:
				add_id = false
		
		if add_id:
			id_map[String(dialog_nodes[node_id]["name"])] = node_id
		release_dialog.dialog_nodes[node_id] = data
	
	release_dialog.id_map = id_map
	
	return release_dialog


## Generates and returns all NEW locale files. All locale files updated
## via localization_map won't be returned in the array.
func generate_localization_files(conversation_id: StringName, base_path: String, localization_map: Dictionary[String, DiscourseDialogLocale] = {}) -> Array[DiscourseDialogLocale]:
	var locale_files: Array[DiscourseDialogLocale] = []
	
	for language in locale_map.keys():
		var new_base_locale: DiscourseDialogLocale = null
		var return_base: bool = true
		if localization_map.has(language + "-" + "base"):
			new_base_locale = localization_map[language + "-" + "base"]
			return_base = false
		else:
			new_base_locale = DiscourseDialogLocale.new()
			new_base_locale.language = language
			new_base_locale.region = "base"
			var base_locale_path: String = str(
					base_path,
					language,
					"-base/dialog/",
					conversation_id,
					".tres")
			new_base_locale.resource_path = base_locale_path
		
		var node_keys: Array = node_localization.keys()
		var format_string_keys: Array = localized_strings.keys()
		
		for node_uuid in node_keys:
			var target_data: Dictionary = {}
			if node_localization[node_uuid].has("common"):
				target_data = node_localization[node_uuid]["common"]
			else:
				target_data = node_localization[node_uuid][language]["base"]
			
			if target_data.has("dialog"):
				new_base_locale.set_text(conversation_id, node_uuid, target_data["dialog"])
			else:
				new_base_locale.set_options(conversation_id, node_uuid, PackedStringArray(target_data["options"]))
			
		for format_string_key in format_string_keys:
			new_base_locale.set_format_string(
					conversation_id,
					format_string_key,
					localized_strings[format_string_key][language]["base"]["text"],
					localized_strings[format_string_key][language]["base"]["arguments"])
		
		if return_base:
			locale_files.append(new_base_locale)
		
		for region in locale_map[language]:
			var new_locale: DiscourseDialogLocale = null
			var return_region: bool = true
			if localization_map.has(language + "-" + region):
				new_locale = localization_map[language + "-" + region]
				return_region = false
			else:
				new_locale = DiscourseDialogLocale.new()
				new_locale.language = language
				new_locale.region = region
				new_locale.resource_path = str(
					base_path,
					language,
					"-",
					region,
					"/dialog/",
					conversation_id,
					".tres")
			
			for locale_format_string_key in format_string_keys:
				new_locale.set_format_string(
						conversation_id,
						locale_format_string_key,
						localized_strings[locale_format_string_key][language][region]["text"],
						localized_strings[locale_format_string_key][language][region]["arguments"])
			
			for node_uuid in node_keys:
				var target_data: Dictionary = {}
				
				if node_localization[node_uuid].has("common"):
					target_data = node_localization[node_uuid]["common"]
				else:
					target_data = node_localization[node_uuid][language][region]
				
				if target_data.has("dialog"):
					new_locale.set_text(
							conversation_id,
							node_uuid,
							target_data["dialog"])
				else:
					new_locale.set_options(
							conversation_id,
							node_uuid,
							PackedStringArray(target_data["options"]))
			
			if return_region:
				locale_files.append(new_locale)
	
	return locale_files


# Only call if the resource file already exists in the project directory!
#func save() -> void:
	#ResourceSaver.save(self)


## Returns localization data of all registered and localized nodes.
func get_node_localization_data() -> Dictionary[StringName, Dictionary]:
	var data: Dictionary[StringName, Dictionary] = {}
	
	for uuid in node_localization.keys():
		if node_localization[uuid].has("common"):
			continue
		data[uuid] = {}
		for language in node_localization[uuid].keys():
			data[uuid][language] = {}
			for region in node_localization[uuid][language].keys():
				data[uuid][language][region] = node_localization[uuid][language][region].duplicate(true)
	
	return data


## Returns an array with a split path used for variable access on the Blackboard.
func split_path_variable(path: String) -> Array[StringName]:
	var split: PackedStringArray = path.rsplit("/", false, 1)
	var path_array: Array[StringName] = []
	var size: int = 0
	for path_component in split:
		path_array.append(StringName(path_component))
		size += 1
	if size != 2:
		path_array.resize(2)
	return path_array


## Returns an array with all the format arguments of the prase [param phrase_text].[br]
## It'll only look for format arguments that start with $ or !.
func get_phrase_arguments(phrase_text: String) -> Array[String]:
	var all_arguments: Array[String] = []
	#var variable_calls: Array[String] = []
	#var arguments_vals: Array[String] = []
	
	#var arguments: Dictionary[String, Array] = {
		#"functions": function_calls,
		#"variables": variable_calls}
	
	var regex_search: RegEx = RegEx.new()
	#regex_search.compile("\\{\\-([^\\s\\}]+)\\}")
	#
	#for regex_match in regex_search.search_all(phrase_text): # -Argument
		#arguments_vals.append(regex_match.get_string(1))
	
	regex_search.compile("\\{[\\$\\!][^\\s\\}]+\\}")
	
	for regex_match in regex_search.search_all(phrase_text): # $variable
		all_arguments.append(regex_match.get_string())
	
	#regex_search.compile("\\{\\!([^\\s\\}]+)\\}")
	#
	#for regex_match in regex_search.search_all(phrase_text): # !function
		#function_calls.append(regex_match.get_string(1))
	
	return all_arguments


## Adds a locale to the locale map. The locale map is used to track which
## languages/regions are saved in this plugin.
func add_locale(language: String, region: String = "base") -> void:
	var lang: StringName = StringName(language)
	
	if not locale_map.has(lang):
		locale_map[lang] = PackedStringArray()
		
		for localized_entry:String in localized_strings.keys():
			if not localized_strings[localized_entry].has(language):
				localized_strings[localized_entry][language] = Dictionary({},
						TYPE_STRING, &"", null,
						TYPE_DICTIONARY, &"", null)
			
			if not localized_strings[localized_entry][language].has("base"):
				localized_strings[localized_entry][language]["base"] = localized_strings[localized_entry][base_language]["base"].duplicate(true)
	
	if region == "base" or locale_map.has(region):
		return
	
	locale_map[lang].append(region)
	
	for localized_entry in localized_strings.keys():
		if localized_strings[localized_entry][language].has(region):
			continue
		localized_strings[localized_entry][language][region] = localized_strings[localized_entry][language]["base"].duplicate(true)


## Removes a locale from the locale map.
func remove_locale(language: String, region: String = "base") -> void:
	var lang_key: StringName = StringName(language)
	
	if not locale_map.has(lang_key):
		return
	
	if region == "base":
		locale_map.erase(lang_key)
		for locale_string in localized_strings.keys():
			localized_strings[locale_string].erase(language)
	else:
		for locale_string in localized_strings.keys():
			localized_strings[locale_string][language].erase(region)
