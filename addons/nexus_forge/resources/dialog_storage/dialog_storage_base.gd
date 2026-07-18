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
@export_storage var entry_node: StringName = &""

# Generated on export
@export_storage var node_logic: Dictionary[StringName, Dictionary] = {
	#&"9156f183-6761-4259-9dde-1a81d12fb047": {
		#"id": "This is the ID",
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

var _uid_to_id: Dictionary[StringName, StringName] = {
	#&"9156f183-6761-4259-9dde-1a81d12fb047": &"Greeting"
}

var _dialog_overrides: NFDialogEntryOverride = null:
	set(o):
		if _dialog_overrides != null:
			_dialog_overrides.override_changed.disconnect(_on_override_updated)
			for node_id in _dialog_overrides._overrides.keys():
				for locale_id in _dialog_overrides._overrides[node_id].keys():
					if not o.has_override(node_id, locale_id):
						var duuid: String = String(node_id) + "/" + locale_id
						parsed_dialog_cache.remove_data(duuid)
					else:
						var o_override = o.get_override(node_id, locale_id)
						var c_override = _dialog_overrides.get_override(node_id, locale_id)
						if typeof(o_override) == typeof(c_override) and o_override == c_override:
							continue
						else:
							var duuid: String = String(node_id) + "/" + locale_id
							parsed_dialog_cache.remove_data(duuid)
			_dialog_overrides.clear()
		
		_dialog_overrides = o
		_dialog_overrides.override_changed.connect(_on_override_updated)

var parsed_dialog_cache: Cache
var _loaded_locales: Cache
var _active_locale: DiscourseDialogLocale = null
var _active_locale_code: String = ""


func _init() -> void:
	parsed_dialog_cache = Cache.new()
	_loaded_locales = Cache.new()
	_loaded_locales.max_size = LOCALE_STORE_MAX


func _store_locale(locale_code: String, new_locale: DiscourseDialogLocale) -> void:
	_loaded_locales.cache_data(locale_code, new_locale)
	if locale_code == _active_locale_code:
		_active_locale = new_locale


func _get_locale(locale_code: String) -> DiscourseDialogLocale:
	if _loaded_locales.is_in_cache(locale_code):
		return _loaded_locales.get_cache(locale_code)
	return null


func _set_locale(locale_code: String) -> void:
	_active_locale = _get_locale(locale_code)
	_active_locale_code = locale_code


func _has_locale(locale_code: String) -> bool:
	return _loaded_locales.is_in_cache(locale_code)


func _get_text(dialog_id: String, uuid: String) -> String:
	if _active_locale == null:
		return "[MISSING LOCALIZATION DATA]"
	
	var locale: String = _active_locale.locale
	
	if _dialog_overrides != null and _dialog_overrides.has_override(node_logic[uuid]["id"], locale):
		var override = _dialog_overrides.get_override(node_logic[uuid]["id"], locale)
		if typeof(override) == TYPE_STRING:
			return override
		else:
			return "[OVERRIDE TYPE ERROR]"
	else:
		return _active_locale.get_text(dialog_id, uuid)


func _get_choices(dialog_id: String, uuid: String) -> PackedStringArray:
	if _active_locale == null:
		return PackedStringArray()
	
	var locale: String = _active_locale.locale
	
	if _dialog_overrides != null and _dialog_overrides.has_override(node_logic[uuid]["id"], locale):
		var override = _dialog_overrides.get_override(node_logic[uuid]["id"], locale)
		if typeof(override) == TYPE_PACKED_STRING_ARRAY:
			return override.duplicate()
		else:
			return PackedStringArray(["[OVERRIDE TYPE ERROR]"])
	else:
		return _active_locale.get_choices(dialog_id, uuid)


func _on_override_updated(node_id: StringName, locale: String) -> void:
	if not node_logic.has(node_id):
		return
	
	var duuid: String = String(node_id) + "/" + locale
	parsed_dialog_cache.remove_data(duuid)


class NFDialogEntryOverride extends RefCounted:
	signal override_changed(node_id: String, locale: String)
	# node id: {locale: etry}
	var _overrides: Dictionary[String, Dictionary] = {}
	
	
	func clear() -> void:
		_overrides.clear()
	
	
	func has_override(node_id: StringName, locale: String) -> bool:
		return DictUtils.has_nested_path(
				_overrides,
				[node_id, locale])
	
	
	func get_override(node_id: StringName, locale: String) -> Variant:
		return DictUtils.get_nested_value(
				_overrides,
				[node_id, locale])
	
	
	func set_override(node_id: StringName, locale: String, override) -> void:
		var override_type: int = typeof(override)
		
		if override_type == TYPE_NIL:
			if _overrides.has(node_id) and _overrides[node_id].erase(locale):
				override_changed.emit(node_id, locale)
		else:
			if DictUtils.has_nested_path(_overrides, [node_id, locale]):
				if typeof(_overrides[node_id][locale]) == override_type:
					if _overrides[node_id][locale] == override:
						return
			if not _overrides.has(node_id):
				_overrides[node_id] = DictUtils.create_typed(TYPE_STRING, TYPE_NIL)
			_overrides[node_id][locale] = override
			override_changed.emit(node_id, locale)
