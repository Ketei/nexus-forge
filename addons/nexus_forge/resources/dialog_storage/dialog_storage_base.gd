@icon("res://addons/nexus_forge/icons/dialog_full.svg")
class_name DiscourseDialog
extends Resource
## A resource containing a conversation.
##
## This resource only contains the "logic" part of a conversation to be parsed
## by Discourse on project export. Usually generated from [EditorDiscourseDialog]
## files.


enum LocalizationFormat {
	STRING = 0,
	VAR_ACCESS = 1,
	METHOD_CALL = 2,
}

enum LocalizationType {
	TEXT = 0,
	CHOICES = 1,
}

## The types of nodes.
const NodeType := DialogParser.NodeTypes
const LOCALE_STORE_MAX: int = 3

## The UUID of the entry node.
@export_storage var entry_node: StringName = ""

# Generated on export
@export_storage var node_logic: Dictionary[StringName, Dictionary] = {
	#&"9156f183-6761-4259-9dde-1a81d12fb047": {
		#"type": NodeType.DIALOG, # On save
		#"character_id": "ABC", # On save
		#"persist": true, # On save
		#"character_settings": {}, # On export. In memory on debug.
		#"dialog_settings": {}, # On export. In memory on debug.
		#"text_source": &"", # On export. In memory on debug.
		#"next_node": &"" # On export. In memory on debug.
	#},
	#&"9156f183-6761-4259-9dde-1a81d12fb048": {
		#"type": NodeType.OPTIONS,
		#"choices": [{
			#"next_node": &"",
			#"settings": {
				#"available": true, # On export.
				#"unlocked": true, # On export.
			#}
		#}]
	#}
}

# Generated on export.
@export_storage var id_map: Dictionary[StringName, StringName] = {
	#&"Greeting": &"9156f183-6761-4259-9dde-1a81d12fb047"
}

var _uid_to_id: Dictionary[StringName, StringName] = {
	#&"9156f183-6761-4259-9dde-1a81d12fb047": &"Greeting"
}

var parsed_dialog_cache: Cache
var _loaded_locales: Cache


func _init() -> void:
	parsed_dialog_cache = Cache.new()
	_loaded_locales = Cache.new()
	_loaded_locales.max_size = LOCALE_STORE_MAX


func _store_locale(locale_code: String, new_locale: DiscourseDialogLocale) -> void:
	_loaded_locales.cache_data(locale_code, new_locale)


func _get_locale(locale_code: String) -> DiscourseDialogLocale:
	if _loaded_locales.is_in_cache(locale_code):
		return _loaded_locales.get_cache(locale_code)
	return null


func _has_locale(locale_code: String) -> bool:
	return _loaded_locales.is_in_cache(locale_code)


func _get_id_from_uid(uid: StringName) -> String:
	if _uid_to_id.has(uid):
		return _uid_to_id[uid]
	
	for id in id_map.keys():
		if id_map[id] == uid:
			_uid_to_id[uid] = id
			return id
	return ""


## Returns the dialog UUID assiged to the custom [param id].
func get_id_target(id: StringName) -> StringName:
	if id_map.has(id):
		return id_map[id]
	return &""


## Returns true if [param id] is mapped to a dialog UUID.
func has_id(id: String) -> bool:
	return id_map.has(id)


## Assigns the [param id] to the dialog's [param uuid]. Returns [code]true[/code]
## if the assignment was successful. If the UUID doesn't exist it'll return
## [code]false[/code].
func link_id(id: String, uuid: StringName) -> bool:
	if node_logic.has(uuid):
		id_map[id] = uuid
		return true
	return false
