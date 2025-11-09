class_name ReleaseDiscourseDialog
extends DiscourseDialog


#const NodeTypes := DialogParserRelease.NodeTypes

#var parsed_dialog_cache: Cache
#var entry_id: StringName = &""
#var base_language: String = ""

# Used for localization.
# When generating release files, if this field is empty I assign it a new one
# and continue. If it has a custom id (EditorDiscouseDialog.locale_group) I
# generate a new UUID and map it {"my_custom_id": { "uuid": (UUID), "resource": pointer }}
# Then I simply merge the localization and the format_strings from the _dialog_locale
# into one file.
@export_storage var localization_uuid: StringName = &""
var _dialog_locale: DiscourseDialogLocale = null

# Map of custom IDs for the conversation {"EntryNode": (UUID)}
@export_storage var id_map: Dictionary[String, StringName] = {}

# Example of how data will be structured.
#var store = {
		#NodeTypes.ENTRY: {
			#"next_node": &""},
		#NodeTypes.DIALOG: {
			#"node_type": NodeTypes.DIALOG,
			#"character_id": &"",
			#"persist": true,
			#"character_settings": &"",
			#"dialog_settings": {},
			#"text_source": &"", # External key source for dialog
			#"next_node": &""},
		#NodeTypes.OPTIONS: {
			#"node_type": null,
			#"options": [{"text": "", "next_node": "", "settings": &""}, {}]},
		#NodeTypes.BRANCH: {
			#"node_type": null,
			#"result": &"", # What node provides the result
			#"case_true": &"",
			#"case_false": &""},
		#NodeTypes.CONDITION_SELECT: {
			#"node_type": null,
			#"result": &"", # What node provides the result
			#"true_value": &"",
			#"false_value": &""},
		#NodeTypes.COMPARATION: {
			#"node_type": null,
			#"operator": OP_EQUAL,
			#"value_a": &"",
			#"value_b": &""},
		#NodeTypes.EVENT: {
			#"variable_path": &"",
			#"variable": &"",
			#"value": &"",
			#"callable": &"",
			#"signal": &"",
			#"next_node": &""},
		#NodeTypes.MATCH: {
			#"case_default": &"",
			#"match_value": &"",
			#"cases": [
				#{"value": 0, "next_node": &""},
				#{"value": "X3", "next_node": &""}]},
		#NodeTypes.PAUSE: {
			#"next_node": &""},
		#NodeTypes.RANDOM: {
			#"default_override": &"",
			#"options": [
				#{"target": &"", "weight": &""}]},
		#NodeTypes.TYPE_GUARD: {
			#"type": TYPE_INT,
			#"value": &"",
			#"fallback": 100},
		#NodeTypes.VALUE: {
			#"value": 50},
		#NodeTypes.SIGNAL: {
			#"signal": &"",
			#"arguments": [&"", &""]}, # Sources for the arguments
		#NodeTypes.CALLABLE: {
			#"method": &"",
			#"arguments": [&""]},
		#NodeTypes.CALLABLE_RETURN: {
			#"method": &"",
			#"arguments": [&"", &""]},
		#NodeTypes.VARIABLE_GET: {
			#"path": &"",
			#"variable": &""},
		#NodeTypes.RANDOM_VALUE: {
			#"random_type": TYPE_BOOL,
			#"min_value": 0.0,
			#"max_value": 100.0,
			#"min_source": &"",
			#"max_source": &""},
		#NodeTypes.RESOURCE: {
			#"uuid": ""},
		#NodeTypes.DATA_EVENT: {
			#"variable_path": &"",
			#"variable": &"",
			#"value": &"",
			#"callable": &"",
			#"signal": &"",
			#"data_source": &""}} # Where is the data to get.
#var data: Dictionary = {
	#&"UUID_A": {"type": DataTypes.DATA, "data": "Hello World"},
	#&"UUID_B": {
		#"type": DataTypes.CALLABLE,
		#"method": &"method_name",
		#"arguments": [&"UUID_A", &"UUID_C"]},
	#&"UUID_P": {"type": DataTypes.DATA, "data": "wulfre"}} # This allows for multiple steps
#
#
#var dialog_steps: Dictionary = {
	#&"UUID": {
		#"step_type": NodeTypes.DIALOG,
		#"character_id": "ketei",
		#"persist": true,
		#"dialog_settings": {"font": "", "scene": "", "speed": 0.1},
		#"character_settings": {"display_name": "", "portrait_id": ""},
		#"text_source": &"UUID_A", # points to _data
		#"next_node": &"UUID2"}, # points to _dialog_steps
	#&"UUID2": {
		#"step_type": NodeTypes.CALLABLE_RETURN,
		#"method": &"get_random_text",
		#"arguments": [&"UUID_P"]}} # All arguments are stored in _data


#func get_dialog_data(uuid: StringName) -> Dictionary:
	#var data: Dictionary = {}
	#match dialog_nodes[uuid]["step_type"]:
		#NodeTypes.DIALOG:
			#var base: Dictionary = dialog_nodes[uuid]
			#data["character_id"] = base["character_id"]
			#data["persist"] = base["persist"]
			#data["dialog_settings"] = base["dialog_settings"].duplicate(true)
			#data["character_settings"] = base["character_settings"].duplicate(true)
			#var dialog_text: String = ""
			#if data["text_source"].is_empty():
				#dialog_text = _dialog_locale.get_text(uuid)
			#else:
				#var data_result: Variant = get_data(data["text_source"])
				##if typeof(data_result)
				##dialog_text = 
			## 3 options:
				## If text_source == &"" then get the string from _dialog_locale
				## if text_source != &"" then process the steps to get the text
			#data["dialog_text"] = dialog_text
	#
	#return data


#func get_node_data(uuid: StringName, language: String, region: String = "base") -> Dictionary:
	#if not dialog_nodes.has(uuid):
		#return {}
	#var data: Dictionary = dialog_nodes[uuid].duplicate(true)
	##var fixed_region: String = "common" if region.is_empty() else region
	#if language.is_empty():
		#language = "common"
	#if region.is_empty():
		#region = "base"
	#
	#match data["node_type"] as NodeTypes:
		#NodeTypes.DIALOG:
			#if language == "common" or not data["has_localization"]:
				#data["dialog_text"] = node_localization[uuid]["common"]["dialog"]
			#else:
				#data["dialog_text"] = node_localization[uuid][language][region]["dialog"]
		#NodeTypes.OPTIONS:
			#var options_translated: Array[String] = []
			#if language == "common" or not data["has_localization"]:
				#options_translated.assign(node_localization[uuid]["common"]["options"])
			#var idx: int = -1
			#for option:Dictionary in data["options"]:
				#idx += 1
				#option["option_text"] = options_translated[idx]
		#NodeTypes.LOCALIZED_TEXT:
			#if language == "common":
				#data["text"] = node_localization[uuid]["common"]["text"]
			#else:
				#data["text"] = node_localization[uuid][language][region]["text"]
	#
	#return data
	#match dialog_nodes[uuid]["node_type"]:
		#NodeTypes.CALLABLE_RETURN:
			#var method: Callable = Callable(NexusForge.Discourse.API, dialog_nodes[uuid]["method"])
			#var args: Array = []
			#for arg:StringName in dialog_nodes[uuid]["arguments"]:
				#args.append(get_data(arg))
			#return method.callv(args)
		#NodeTypes.CONDITION_SELECT:
			#var condition: bool = get_data(dialog_nodes[uuid]["result"])
			#if condition:
				#return get_data(dialog_nodes[uuid]["true_value"])
			#else:
				#return get_data(dialog_nodes[uuid]["false_value"])
		#NodeTypes.COMPARATION:
			#var a = get_data(dialog_nodes[uuid]["value_a"])
			#var b = get_data(dialog_nodes[uuid]["value_b"])
			#match dialog_nodes[uuid]["operator"]:
				#OP_EQUAL:
					#return a == b
				#OP_NOT_EQUAL:
					#return a != b
				#OP_LESS:
					#return a < b
				#OP_LESS_EQUAL:
					#return a <= b
				#OP_GREATER:
					#return a > b
				#OP_GREATER_EQUAL:
					#return a >= b
				#_:
					#return false
		#NodeTypes.TYPE_GUARD:
			#var pointed_value = get_data(dialog_nodes[uuid]["value"])
			#if typeof(pointed_value) == dialog_nodes[uuid]["type"]:
				#return pointed_value
			#else:
				#return dialog_nodes[uuid]["fallback"]
		#NodeTypes.VALUE:
			#return dialog_nodes[uuid]["value"]
		#NodeTypes.VARIABLE_GET:
			#return NexusForge.Variables.variables[dialog_nodes[uuid]["path"]][dialog_nodes[uuid]["variable"]]
		#NodeTypes.RANDOM_VALUE:
			#pass
	#return null



func get_uuid_from_id(id: String) -> StringName:
	if id_map.has(id):
		return id_map[id]
	return &""


func is_id_mapped(id: String) -> bool:
	return id_map.has(id)


func map_id_to(id: String, uuid: StringName) -> bool:
	if dialog_nodes.has(uuid):
		id_map[id] = uuid
		return true
	return false


func get_format_string_text(conversation: StringName, key: StringName) -> String:
	if _dialog_locale.has_format_string(conversation, key):
		return _dialog_locale.get_format_string_text(conversation, key)
	return ""


func get_format_string_arguments(conversation: StringName, key: StringName) -> Dictionary[String, Dictionary]:
	if _dialog_locale.has_format_string(conversation, key):
		return _dialog_locale.get_format_string_args(conversation, key)
	return Dictionary({}, TYPE_STRING, &"", null, TYPE_DICTIONARY, &"", null)
