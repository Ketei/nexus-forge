@icon("res://addons/nexus_forge/icons/dialog_full.svg")
class_name DiscourseDialog
extends Resource
## A resource containing a conversation.
##
## This resource only contains the "logic" part of a conversation to be parsed
## by Discourse on project export. Usually generated from [EditorDiscourseDialog]
## files.

	
## The type of localization.
enum LocalizationType {
	TEXT = 0, ## Represents a string entry.
	CHOICES = 1, ## Represents an array entry.
}

## The types of nodes.
const NodeType := NFDialogParser.NodeTypes
## The max amount of locales that will be stored per-dialogue.
const LOCALE_STORE_MAX: int = 3

## The ID of the entry node.
@export_storage var entry_node: StringName = &""

## The logic of all the nodes in a dialog. Does not contain localization
## data.
## [br][br]
## [b]Important:[/b] This data is only generated when the game is exported.
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
			_clear_override_keys()
			_dialog_overrides.override_changed.disconnect(_on_dialog_override_updated)
			
		_dialog_overrides = o
		
		if _dialog_overrides != null:
			_dialog_overrides.override_changed.connect(_on_dialog_override_updated)

var _phrase_overrides: NFPhraseEntryOverride = null:
	set(o):
		if _phrase_overrides != null:
			_clear_override_keys()
			_phrase_overrides.phrases_changed.disconnect(_on_phrases_changed)
		_phrase_overrides = o
		if o != null:
			o.phrases_changed.connect(_on_phrases_changed)

## Cache of parsed dialogues for quick loading.
var parsed_dialog_cache: NFLRUCache
var _loaded_locales: NFLRUCache
var _active_locale: DiscourseDialogLocale = null
var _active_locale_code: String = ""


func _init() -> void:
	parsed_dialog_cache = NFLRUCache.new()
	_loaded_locales = NFLRUCache.new()
	_phrase_overrides = NFPhraseEntryOverride.new()
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


func _get_text_data(dialog_id: String, node_id: String) -> Dictionary:
	var data: Dictionary[String, Variant] = {
		"is_override": false,
		"text": "[MISSING LOCALIZATION DATA]"}
	
	if _active_locale == null:
		return data
	
	var locale: String = _active_locale.locale
	
	if _dialog_overrides != null and _dialog_overrides.has_override(node_id, locale, TYPE_STRING):
		data["is_override"] = true
		data["text"] = _dialog_overrides.get_override(node_id, locale)
	else:
		data["text"] = _active_locale.get_text(dialog_id, node_id)
	
	return data


func _get_choices(dialog_id: String, id: String) -> PackedStringArray:
	if _active_locale == null:
		return ["[MISSING LOCALIZATION DATA]"]
	
	var locale: String = _active_locale.locale
	
	if _dialog_overrides != null and _dialog_overrides.has_override(id, locale):
		var override = _dialog_overrides.get_override(id, locale)
		if typeof(override) == TYPE_PACKED_STRING_ARRAY:
			return override.duplicate()
		else:
			return PackedStringArray(["[OVERRIDE TYPE ERROR]"])
	else:
		return _active_locale.get_choices(dialog_id, id)


func _on_dialog_override_updated(node_id: StringName, locale: String) -> void:
	if not node_logic.has(node_id):
		return
	
	var duuid: String = String(node_id) + "/" + locale + "/override"
	parsed_dialog_cache.remove_data(duuid)


func _on_phrases_changed() -> void:
	_clear_override_keys()


func _clear_override_keys() -> void:
	var keys_to_erase: Array[String] = []
	for key in parsed_dialog_cache.keys():
		if key.ends_with("/override"):
			keys_to_erase.append(key)
	
	parsed_dialog_cache.remove_keys(keys_to_erase)


func _get_format_string(conversation: String, key: String) -> String:
	if _active_locale == null:
		return "[MISSING LOCALIZATION DATA]"
	
	if _phrase_overrides != null:
		var possible_override: Variant = _phrase_overrides.get_base_string_override(
				conversation,
				_active_locale_code,
				key)
		if possible_override != null:
			return possible_override
	
	return _active_locale.get_format_string_text(conversation, key)


func _get_format_string_args(conversation: String, key: String) -> Dictionary[String, Dictionary]:
	if _active_locale == null:
		return {}
	
	var base: Dictionary[String, Dictionary] = _active_locale.get_format_string_args(conversation, key)
	
	if _phrase_overrides != null:
		var possible_override: Dictionary[String, Dictionary] = _phrase_overrides.get_formats_override(
				conversation,
				_active_locale_code,
				key)
		
		for format_key in possible_override:
			var default_overrides: Array[String] = _phrase_overrides.get_format_case_default_overriden(
					conversation,
					key,
					format_key,
					_active_locale_code)
			
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


## An override used by [DiscourseDialog] to replace text dynamically
## on a dialogue.
class NFDialogEntryOverride extends RefCounted:
	## Emits when an override was changed
	signal override_changed(node_id: String, locale: String)
	# node id: {locale: etry}
	var _overrides: Dictionary[String, Dictionary] = {}
	
	## Clears all overrides. Does not emit
	## [signal NFDialogEntryOverride.override_changed].
	func clear() -> void:
		_overrides.clear()
	
	
	## Returns if an override for the node [param node_id] on the
	## [param locale] exists.[br]
	## If [param type] is other than [code]TYPE_NIL[/code] it'll also condier
	## the type.
	func has_override(node_id: StringName, locale: String, type: int = TYPE_NIL) -> bool:
		var override_exist: bool = _overrides.has(node_id) and _overrides[node_id].has(locale)
		
		if type == TYPE_NIL or not override_exist:
			return override_exist
		else:
			return typeof(get_override(node_id, locale)) == type
	
	
	## Returns the registered override of [param node_id] for [param locale].[br]
	## Returns [code]null[/code] if no override existed.
	func get_override(node_id: StringName, locale: String) -> Variant:
		if _overrides.has(node_id):
			return _overrides[node_id].get(locale)
		return null
	
	
	## Registers an [param override] for [param node_id] in the specific
	## [param locale].
	func set_override(node_id: StringName, locale: String, override) -> void:
		var override_type: int = typeof(override)
		var node_dict: Variant = _overrides.get(node_id)
		
		if override_type == TYPE_NIL:
			if typeof(node_dict) == TYPE_DICTIONARY and node_dict.erase(locale):
				override_changed.emit(node_id, locale)
		else:
			if typeof(node_dict) == TYPE_DICTIONARY:
				var existing_val: Variant = node_dict.get(locale)
				if typeof(existing_val) == override_type and existing_val == override:
					return
				node_dict[locale] = override
			else:
				node_dict = NFDictUtils.create_typed(TYPE_STRING, TYPE_NIL)
				node_dict[locale] = override
				_overrides[node_id] = node_dict
			
			override_changed.emit(node_id, locale)


## An override used by [DiscourseDialog] to replace phrases text
## dynamically on dialogue.
class NFPhraseEntryOverride extends RefCounted:
	## Emitted when any of the internal data changes
	signal phrases_changed
	
	var _overrides: Dictionary[String, Dictionary] = {}
	var _default_cases: Dictionary[String, Dictionary] = {}
	
	## Overrides a format's case to use the default entry instead.
	## [br][br]
	##  [color=yellow]Warning:[/color] This will clear any data set with
	## [method DiscourseDialog.NFPhraseEntryOverride.set_format_case_override]
	func override_format_case_to_default(dialog: String, phrase: String, format: String, case: String, locale: String) -> void:
		var dialogue_data: Variant = _default_cases.get(dialog)
		if dialogue_data == null:
			var formats: Dictionary[String, Dictionary] = {}
			_default_cases[dialog] = formats
			dialogue_data = formats
		
		var phrase_data: Variant = dialogue_data.get(phrase)
		if phrase_data == null:
			var new_phrase: Dictionary[String, Dictionary] = {}
			dialogue_data[phrase] = new_phrase
			phrase_data = new_phrase
		
		var formats_data: Variant = phrase_data.get(format)
		if formats_data == null:
			var new_overrides: Dictionary[String, Array] = {}
			phrase_data[format] = new_overrides
			formats_data = new_overrides
		
		if not formats_data.has(locale):
			var case_arr: Array[String] = []
			formats_data[locale] = case_arr
		
		var overrides: Array[String] = formats_data[locale]
		var update: bool = false
		
		if not overrides.has(case):
			overrides.append(case)
			update = true
		
		var e: Dictionary = NFDictUtils.EMPTY_DICT
		var locales_dict: Dictionary = _overrides.get(dialog, e).get(locale, e).get(phrase, e).get(format, e).get("cases", e)
		if locales_dict.has(case):
			update = true
			locales_dict.erase(case)
		
		if update:
			phrases_changed.emit()
	
	
	## Clears the default override of a format's case, restoring its data.
	func clear_format_case_default(dialog: String, phrase: String, format: String, case: String, locale: String) -> void:
		if _erase_format_case_default(dialog, phrase, format, case, locale):
			phrases_changed.emit()
	
	
	## Returns an array of all the overriden cases that are defaulting.
	func get_format_case_default_overriden(dialog: String, phrase: String, format: String, locale: String) -> Array[String]:
		var d_data: Variant = _default_cases.get(dialog)
		if d_data == null:
			return []
		
		var p_data: Variant = d_data.get(phrase)
		if p_data == null:
			return []
		
		var f_data: Variant = p_data.get(format)
		if f_data == null:
			return []
		
		if f_data.has(locale):
			var arr: Array[String] = f_data[locale]
			return arr.duplicate()
		else:
			return []
	
	
	## Returns a phrase base string override or [code]null[/code] if not exists.
	func get_base_string_override(dialog: String, locale: String, phrase: String) -> Variant:
		var d_data: Variant = _overrides.get(dialog)
		if d_data == null:
			return null
		
		var loc_data: Variant = d_data.get(locale)
		if loc_data == null:
			return null
		
		var p_data: Variant = loc_data.get(phrase)
		if p_data == null:
			return null
		
		return p_data.get("base_string")
	
	
	## Returns a copy of the format overrides. Intended to be merged with
	## a complete copy.
	func get_formats_override(dialog: String, locale: String, phrase: String) -> Dictionary[String, Dictionary]:
		var conv: Variant = _overrides.get(dialog)
		if conv == null:
			return {}
		
		var loc: Variant = conv.get(locale)
		if loc == null:
			return {}
		
		var p_override: Variant = loc.get(phrase)
		if p_override == null:
			return {}
		
		var override_dict: Dictionary[String, Dictionary] = {}
		for format_key in p_override["format"]:
			var target: Dictionary = p_override["format"][format_key]
			var entry: Dictionary[String, Dictionary] = {
				"cases": target["cases"].duplicate(true)}
			
			if target["default"] != null:
				entry["default"] = target["default"]
			override_dict[format_key] = entry
			
		return override_dict
	
	
	## Sets a format's default text to be [param default].[br]
	## If [param default] is [code]null[/code] the override is cleared.
	func set_format_default_override(dialog: String, locale: String, phrase: String, format: String, default: Variant) -> void:
		var def_type: int = typeof(default)
		
		var d_override: Variant = _overrides.get(dialog)
		
		if def_type == TYPE_NIL:
			if d_override != null and d_override.has(locale) and d_override[locale].has(phrase) and d_override[locale][phrase]["format"].has(format):
				var target: Dictionary = d_override[locale][phrase]["format"][format]
				var change_made: bool = target["default"] != null
				target["default"] = null
				if target["cases"].is_empty():
					d_override[locale][phrase]["format"].erase(format)
					if d_override[locale][phrase]["format"].is_empty() and d_override[locale][phrase]["base_string"] == null:
						d_override[locale].erase(phrase)
						if d_override[locale].is_empty():
							d_override.erase(locale)
							if d_override.is_empty():
								_overrides.erase(dialog)
				if change_made:
					phrases_changed.emit()
			return
		elif def_type != TYPE_STRING:
			return
		
		if d_override == null:
			var new_dict: Dictionary[String, Dictionary] = {}
			_overrides[dialog] = new_dict
			d_override = new_dict
		
		var loc_data: Variant = d_override.get(locale)
		if loc_data == null:
			var new_loc: Dictionary[String, Dictionary] = {}
			d_override[locale] = new_loc
			loc_data = new_loc
		
		var phrase_o: Variant = loc_data.get(phrase)
		if phrase_o == null:
			var new_override: Dictionary[String, Variant] = {
				"base_string": null,
				"format": NFDictUtils.create_typed(
						TYPE_STRING, TYPE_DICTIONARY)}
			loc_data[phrase] = new_override # FIXED: Assigned to loc_data, not d_override
			phrase_o = new_override
		
		var format_o: Variant = phrase_o["format"].get(format)
		if format_o == null:
			var format_override: Dictionary[String, Variant] = {
				"default": null,
				"cases": NFDictUtils.create_typed(
						TYPE_STRING, TYPE_STRING)}
			phrase_o["format"][format] = format_override
			format_o = format_override
		
		var change_made: bool = format_o["default"] != default
		format_o["default"] = default
		if change_made:
			phrases_changed.emit()
	
	
	## Sets a format's case result to be [param result].[br]
	## If [param result] is [code]null[/code] the override is cleared.
	func set_format_case_override(dialog: String, locale: String, phrase: String, format: String, case: String, result: Variant) -> void:
		var res_type: int = typeof(result)
		
		var d_override: Variant = _overrides.get(dialog)
		
		if res_type == TYPE_NIL:
			if d_override != null and d_override.has(locale) and d_override[locale].has(phrase) and d_override[locale][phrase]["format"].has(format):
				var format_target: Dictionary = d_override[locale][phrase]["format"][format]
				if format_target["cases"].erase(case):
					if format_target["cases"].is_empty() and format_target["default"] == null:
						d_override[locale][phrase]["format"].erase(format)
						if d_override[locale][phrase]["format"].is_empty() and d_override[locale][phrase]["base_string"] == null:
							d_override[locale].erase(phrase)
							if d_override[locale].is_empty():
								d_override.erase(locale)
								if d_override.is_empty():
									_overrides.erase(dialog)
					phrases_changed.emit()
			return
		elif res_type != TYPE_STRING:
			return
		
		if d_override == null:
			var new_dict: Dictionary[String, Dictionary] = {}
			_overrides[dialog] = new_dict
			d_override = new_dict
		
		var loc_data: Variant = d_override.get(locale)
		if loc_data == null:
			var new_loc: Dictionary[String, Dictionary] = {}
			d_override[locale] = new_loc
			loc_data = new_loc
		
		var phrase_o: Variant = loc_data.get(phrase)
		if phrase_o == null:
			var new_override: Dictionary[String, Variant] = {
				"base_string": null,
				"format": NFDictUtils.create_typed(
						TYPE_STRING, TYPE_DICTIONARY)}
			loc_data[phrase] = new_override # FIXED: Assigned to loc_data, not d_override
			phrase_o = new_override
		
		var format_o: Variant = phrase_o["format"].get(format)
		if format_o == null:
			var format_override: Dictionary[String, Variant] = {
				"default": null,
				"cases": NFDictUtils.create_typed(
						TYPE_STRING, TYPE_STRING)}
			phrase_o["format"][format] = format_override
			format_o = format_override
		
		var change: bool = format_o["cases"].get(case) != result
		format_o["cases"][case] = result
		
		var erased: bool = _erase_format_case_default(dialog, phrase, format, case, locale)
		
		if change or erased:
			phrases_changed.emit()
	
	
	## Overrides the base string of a phrase used to apply formatting to [param base].[br]
	## If [param base] is [code]null[/code] the override is cleared.
	func set_base_string_override(dialog: String, locale: String, phrase: String, base: Variant) -> void:
		var base_type: int = typeof(base)
		
		var d_override: Variant = _overrides.get(dialog)
		
		if base_type == TYPE_NIL:
			if d_override != null and d_override.has(locale) and d_override[locale].has(phrase):
				var target: Dictionary = d_override[locale][phrase]
				var change: bool = target["base_string"] != null
				target["base_string"] = null
				if target["format"].is_empty():
					d_override[locale].erase(phrase)
					if d_override[locale].is_empty():
						d_override.erase(locale)
						if d_override.is_empty():
							_overrides.erase(dialog)
				if change:
					phrases_changed.emit()
			return
		elif base_type != TYPE_STRING:
			return
		
		if d_override == null:
			var new_dict: Dictionary[String, Dictionary] = {}
			_overrides[dialog] = new_dict
			d_override = new_dict
		
		var loc_data: Variant = d_override.get(locale)
		if loc_data == null:
			var new_loc: Dictionary[String, Dictionary] = {}
			d_override[locale] = new_loc
			loc_data = new_loc
		
		var phrase_o: Variant = loc_data.get(phrase)
		if phrase_o == null:
			var new_override: Dictionary[String, Variant] = {
				"base_string": null,
				"format": NFDictUtils.create_typed(
						TYPE_STRING, TYPE_DICTIONARY)}
			loc_data[phrase] = new_override # FIXED: Assigned to loc_data, not d_override
			phrase_o = new_override
		
		var change: bool = phrase_o["base_string"] != base
		phrase_o["base_string"] = base
		if change:
			phrases_changed.emit()
	
	
	## Returns if a phrase override exist for [param dialog_id].
	func has_override(dialog_id: String) -> bool:
		return _overrides.has(dialog_id) or _default_cases.has(dialog_id)
	
	
	func _erase_format_case_default(dialog: String, phrase: String, format: String, case: String, locale: String) -> bool:
		if not _default_cases.has(dialog):
			return false
		
		var dialogue_data: Dictionary = _default_cases[dialog]
		if not dialogue_data.has(phrase):
			return false
		
		var phrase_data: Dictionary = dialogue_data[phrase]
		if not phrase_data.has(format):
			return false
		
		var formats_data: Dictionary = phrase_data[format]
		if not formats_data.has(locale):
			return false
		
		var case_arr: Array[String] = formats_data[locale]
		var idx: int = case_arr.find(case)
		var change: bool = -1 < idx
		if change:
			case_arr.remove_at(idx)
		
		if case_arr.is_empty():
			formats_data.erase(locale)
		if formats_data.is_empty():
			phrase_data.erase(format)
		if phrase_data.is_empty():
			dialogue_data.erase(phrase)
		if dialogue_data.is_empty():
			_default_cases.erase(dialog)
		
		return change
