@icon("res://addons/nexus_forge/icons/dialog_full.svg")
class_name ReleaseDiscourseDialog
extends DiscourseDialog
## A resource that contains a dialog's logic data.
##
## This resource only contains the logic of a dialog, not the diplay text of it.
## This file along with the localized file are generated on project export and
## it replaces [EditorDiscourseDialog] files.[br]
## The generated files are [b]NOT[/b] saved on the project's directory and are only
## stored on the exported project pck.[br]
## Localization files are contained within the given directory set on the
## Nexus Forge project setting [code]Localization Directory[/code].

# Used for localization.
# When generating release files, if this field is empty I assign it a new one
# and continue. If it has a custom id (EditorDiscouseDialog.locale_group) I
# generate a new UUID and map it {"my_custom_id": { "uuid": (UUID), "resource": pointer }}
# Then I simply merge the localization and the format_strings from the _dialog_locale
# into one file.
## The UUID from the file that contains this dialog's localized data.
@export_storage var localization_uuid: StringName = &""

# Map of custom IDs for the conversation {"EntryNode": (UUID)}
## A dictionary that maps user-given IDs to the node's UUIDs.
#@export_storage var id_map: Dictionary[String, StringName] = {}
var _dialog_locale: DiscourseDialogLocale = null

# Example of how data will be structured on dialog_nodes.
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


## Returns the dialog UUID assiged to the custom [param id].
func get_uuid_from_id(id: String) -> StringName:
	if id_map.has(id):
		return id_map[id]
	return &""


## Returns true if [param id] is mapped to a dialog UUID.
func is_id_mapped(id: String) -> bool:
	return id_map.has(id)


## Assigns the [param id] to the dialog's [param uuid]. Returns [code]true[/code]
## if the assignment was successful. If the UUID doesn't exist it'll return
## [code]false[/code].
func map_id_to(id: String, uuid: StringName) -> bool:
	#if dialog_nodes.has(uuid):
		#id_map[id] = uuid
		#return true
	return false


## Returns the unformatted text on the [param conversation] with the assigned [param key].
func get_format_string_text(conversation: StringName, key: StringName) -> String:
	if _dialog_locale.has_format_string(conversation, key):
		return _dialog_locale.get_format_string_text(conversation, key)
	return ""


## Returns a dictionary containing all the format arguments, their default and
## custom cases.
func get_format_string_arguments(conversation: StringName, key: StringName) -> Dictionary[String, Dictionary]:
	if _dialog_locale.has_format_string(conversation, key):
		return _dialog_locale.get_format_string_args(conversation, key)
	return Dictionary({}, TYPE_STRING, &"", null, TYPE_DICTIONARY, &"", null)
