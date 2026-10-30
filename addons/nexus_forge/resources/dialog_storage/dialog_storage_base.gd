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

## Enables/Disables mutex locking to prevent race conditions
## if doing multi-threaded access. Only use if you know what you're doing.[br]
## This flag also toggles the [code]thread_safe[/code] flag of the internal
## caches.
## [br][br]
## [b]Tip:[/b] Leave as [code]false[/code] if only using the main thread
## to avoid unnecessary locking overhead.
## [br][br]
## [b]Note:[/b] Enabling this option instantiates a [Mutex] for this object,
## setting it to [code]false[/code] drops the mutex's reference.
var thread_safe: bool = false:
	set(t):
		if thread_safe and not t:
			_mutex = null
		thread_safe = t
		parsed_dialog_cache.thread_safe = t
		_loaded_locales.thread_safe = t
		if t and _mutex == null:
			_mutex = Mutex.new()
var _mutex: Mutex = null

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

var _dialog_overrides: NFDialogEntryOverride = null:
	set(o):
		if o == _dialog_overrides:
			return
		
		if thread_safe:
			_mutex.lock()
		
		if _dialog_overrides != null:
			_clear_override_keys()
			_dialog_overrides.override_changed.disconnect(_on_dialog_override_updated)
			
		_dialog_overrides = o
		
		if _dialog_overrides != null:
			_dialog_overrides.override_changed.connect(_on_dialog_override_updated)
		
		if thread_safe:
			_mutex.unlock()

var _phrase_overrides: NFPhraseEntryOverride = null:
	set(o):
		if o == _phrase_overrides:
			return
		
		if thread_safe:
			_mutex.lock()
		
		if _phrase_overrides != null:
			_phrase_overrides.phrases_changed.disconnect(_on_phrases_changed)
		_phrase_overrides = o
		if o != null:
			o.phrases_changed.connect(_on_phrases_changed)
		
		parsed_dialog_cache.clear()
		
		if thread_safe:
			_mutex.unlock()

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
	if thread_safe:
		_mutex.lock()
	_loaded_locales.cache_data(locale_code, new_locale)
	if locale_code == _active_locale_code:
		_active_locale = new_locale
	if thread_safe:
		_mutex.unlock()


func _get_locale(locale_code: String) -> DiscourseDialogLocale:
	var value: DiscourseDialogLocale = null
	if thread_safe:
		_mutex.lock()
	
	if _loaded_locales.is_in_cache(locale_code):
		value = _loaded_locales.get_cache(locale_code)
	
	if thread_safe:
		_mutex.unlock()
	
	return value


func _set_locale(locale_code: String) -> void:
	if thread_safe:
		_mutex.lock()
	if _loaded_locales.is_in_cache(locale_code):
		_active_locale = _loaded_locales.get_cache(locale_code)
	else:
		_active_locale = null
	
	_active_locale_code = locale_code
	if thread_safe:
		_mutex.unlock()


func _has_locale(locale_code: String) -> bool:
	var in_cache: bool = false
	if thread_safe:
		_mutex.lock()
	in_cache = _loaded_locales.is_in_cache(locale_code)
	if thread_safe:
		_mutex.unlock()
	return in_cache


func _get_text_data(dialog_id: StringName, node_id: StringName) -> Dictionary:
	var data: Dictionary[String, Variant] = {
		"is_override": false,
		"text": "[MISSING LOCALIZATION DATA]"}
	
	if thread_safe:
		_mutex.lock()
	
	var locale: String = _active_locale_code
	var base_string: String = "[MISSING LOCALIZATION DATA]"
	
	if _active_locale != null:
		var loc_str: String = _active_locale.get_text(dialog_id, node_id).strip_edges()
		if not loc_str.is_empty():
			base_string = loc_str
	
	if _dialog_overrides != null:
		var override: Variant = _dialog_overrides.get_override(node_id, locale)
		if typeof(override) == TYPE_STRING:
			data["is_override"] = true
			base_string = override
	
	data["text"] = base_string
	
	if thread_safe:
		_mutex.unlock()
	
	return data


func _get_choices(dialog_id: StringName, id: StringName) -> PackedStringArray:
	var locale: String = _active_locale_code
	var origin_choices: PackedStringArray = ["[MISSING LOCALIZATION DATA]"]
	
	if thread_safe:
		_mutex.lock()
	
	var dirty: bool = true
	if _active_locale != null:
		origin_choices = _active_locale.get_choices(dialog_id, id)
		dirty = false
	
	if _dialog_overrides != null:
		var override: Variant = _dialog_overrides.get_override(id, locale)
		if typeof(override) == TYPE_ARRAY:
			var ovr_size: int = override.size()
			if dirty:
				origin_choices.resize(ovr_size)
				origin_choices.fill("[MISSING LOCALIZATION DATA]")
			
			if origin_choices.size() < ovr_size:
				origin_choices.resize(ovr_size)
			
			for idx in range(ovr_size):
				var override_item: Variant = override[idx]
				if override_item != null:
					origin_choices[idx] = override_item
	
	if thread_safe:
		_mutex.unlock()
	
	return origin_choices


func _on_dialog_override_updated(node_id: StringName, locale: String, indexes: Array[int]) -> void:
	if not node_logic.has(node_id):
		return
	
	if indexes.is_empty():
		# The base dialog text was changed or removed.
		var duuid: String = String(node_id) + "/" + locale + "/override"
		parsed_dialog_cache.remove_data(duuid)
	else:
		# One or more specific choices were changed or removed.
		for idx in indexes:
			var unlocked_duuid: String = String(node_id) + "_" + str(idx) + "_unlocked/" + locale + "/override"
			var locked_duuid: String = String(node_id) + "_" + str(idx) + "_locked/" + locale + "/override"
			
			parsed_dialog_cache.remove_data(unlocked_duuid)
			parsed_dialog_cache.remove_data(locked_duuid)


func _on_phrases_changed() -> void:
	parsed_dialog_cache.clear()


func _clear_override_keys() -> void:
	var keys_to_erase: Array[String] = []
	for key in parsed_dialog_cache.keys():
		if key.ends_with("/override"):
			keys_to_erase.append(key)
	
	parsed_dialog_cache.remove_keys(keys_to_erase)


func _get_format_string(conversation: StringName, key: String) -> String:
	var final_string: String = "[MISSING LOCALIZATION DATA]"
	if thread_safe:
		_mutex.lock()
	
	if _active_locale == null:
		if thread_safe:
			_mutex.unlock()
		return final_string
	
	var string_set: bool = false
	if _phrase_overrides != null:
		var possible_override: Variant = _phrase_overrides.get_base_string_override(
				conversation,
				_active_locale_code,
				key)
		if possible_override != null:
			final_string = possible_override
			string_set = true

	if not string_set:
		var loc_text: String = _active_locale.get_format_string_text(conversation, key)
		if not loc_text.is_empty():
			final_string = loc_text
	
	if thread_safe:
		_mutex.unlock()
	
	return final_string


func _get_format_string_args(conversation: StringName, key: String) -> Dictionary[String, Dictionary]:
	var final_args: Dictionary[String, Dictionary] = {}
	
	if thread_safe:
		_mutex.lock()
	
	if _active_locale == null:
		if thread_safe:
			_mutex.unlock()
		return final_args
	
	var base: Dictionary[String, Dictionary] = _active_locale.get_format_string_args(conversation, key)
	
	if _phrase_overrides != null:
		var possible_override: Dictionary[String, Dictionary] = _phrase_overrides.get_formats_override(
				conversation,
				_active_locale_code,
				key)
		
		for format_key in possible_override:
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
						case_dict.merge(over_format["cases"], true)
		
		for format_key in base:
			var default_overrides: Array[String] = _phrase_overrides.get_format_case_default_overriden(
					conversation,
					key,
					format_key,
					_active_locale_code)
			
			if not default_overrides.is_empty() and base[format_key].has("cases"):
				var case_dict: Dictionary = base[format_key]["cases"]
				for def_case in default_overrides:
					case_dict.erase(def_case)
	
	if thread_safe:
		_mutex.unlock()
	return base


## An override used by [DiscourseDialog] to replace text dynamically
## on a dialogue.
class NFDialogEntryOverride extends RefCounted:
	## Emits when an override was changed
	signal override_changed(node_id: StringName, locale: String, indexes: Array[int])
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
		return _overrides.get(node_id, NFDictUtils.EMPTY_DICT).get(locale)
	
	
	## Registers a text [param override] for [param node_id] on the
	## specified [param locale]. If [param force] is true, and another override
	## that is not a dialogue override exists, it'll be overwriten with a
	## dialogue override instead. Otherwise, it'll
	## stop the assign.[br]
	func set_dialog_override(node_id: StringName, locale: String, override: String, force: bool = false) -> bool:
		if not _overrides.has(node_id):
			_overrides[node_id] = NFDictUtils.create_typed(TYPE_STRING_NAME, TYPE_NIL)
		var target: Dictionary = _overrides[node_id]
		var current: Variant = target.get(locale)
		var type: int = typeof(current)
		if type != TYPE_NIL and type != TYPE_STRING and not force:
			return false
		_overrides[node_id][locale] = override
		var e: Array[int] = []
		override_changed.emit(node_id, locale, e)
		return true
	
	
	## Clears the dialogue override of [param node_id] for the [param locale]
	func remove_dialog_override(node_id: StringName, locale: String) -> void:
		if _overrides.has(node_id):
			var target: Dictionary = _overrides[node_id]
			var override: Variant = target.get(locale)
			if typeof(override) == TYPE_STRING:
				target.erase(locale)
				if target.is_empty():
					_overrides.erase(node_id)
				var e: Array[int] = []
				override_changed.emit(node_id, locale, e)
	
	
	## Sets a choice override for a specific [param node_id].If [param force]
	## is true, and another override that is not a choices override exists,
	## it'll be overwriten with a choices override instead. Otherwise, it'll
	## stop the assign.[br]
	## [b]Note:[/b] This override is NOT destructive. Meaning that if a previous
	## choice override exists and is not being overwritten by [param choices]
	## it'll remain in the overrides.
	func set_choices_override(node_id: StringName, locale: String, choices: Array, force: bool = false) -> bool:
		if not _overrides.has(node_id):
			_overrides[node_id] = NFDictUtils.create_typed(TYPE_STRING_NAME, TYPE_NIL)
		var target: Dictionary = _overrides[node_id]
		var current: Variant = target.get(locale)
		var type: int = typeof(current)
		if type != TYPE_NIL and type != TYPE_ARRAY and not force:
			return false
		
		var valid_array: Array = []
		var total_size: int = choices.size()
		valid_array.resize(total_size)
		
		for idx in range(total_size):
			if typeof(choices[idx]) == TYPE_STRING:
				valid_array[idx] = choices[idx]
		
		while not valid_array.is_empty() and valid_array[-1] == null:
			valid_array.remove_at(-1)
		
		if valid_array.is_empty():
			return true
		
		if type == TYPE_ARRAY:
			var curr_size: int = current.size()
			var valid_size: int = valid_array.size()
			if curr_size < valid_size:
				curr_size = valid_size
				current.resize(valid_size)
			var updated_indexes: Array[int] = []
			for idx in range(valid_size): # Valid size is always the same or smalelr
				if valid_array[idx] != null:
					current[idx] = valid_array[idx]
					updated_indexes.append(idx)
			if not updated_indexes.is_empty():
				override_changed.emit(node_id, locale, updated_indexes)
		else:
			var valid_idx: Array[int] = []
			for idx in range(valid_array.size()):
				if valid_array[idx] != null:
					valid_idx.append(idx)
			
			target[locale] = valid_array
			if not valid_idx.is_empty():
				override_changed.emit(node_id, locale, valid_idx)
		
		return true
	
	
	## Sets an override for a specific choice on index [param choice_idx] to be
	## [param override]. If [param force] is true, and another override
	## that is not a choice override exists, it'll be overwriten with a
	## choices override instead. Otherwise, it'll
	## stop the assign.[br]
	## [b]Note:[/b] This method does NOT work with negative indexes.[br]
	func set_choice_override(node_id: StringName, locale: String, choice_idx: int, override: String, force: bool = false) -> bool:
		if choice_idx < 0:
			return false
		if not _overrides.has(node_id):
			_overrides[node_id] = NFDictUtils.create_typed(TYPE_STRING_NAME, TYPE_NIL)
		var target: Dictionary = _overrides[node_id]
		var current: Variant = target.get(locale)
		var type: int = typeof(current)
		if type != TYPE_NIL and type != TYPE_ARRAY and not force:
			return false
		var override_arr: Array = current if type == TYPE_ARRAY else []
		var arr_size: int = override_arr.size()
		var target_size: int = choice_idx + 1
		
		if arr_size < target_size:
			override_arr.resize(target_size)
		override_arr[choice_idx] = override
		
		target[locale] = override_arr
		var i: Array[int] = [choice_idx]
		override_changed.emit(node_id, locale, i)
		return true
	
	
	## Removes all choice overrides for the [param node_id] of the specified
	## [param locale].[br]
	## [b]Note:[/b] This only works if the override exists and is of type choices.
	func clear_choice_overrides(node_id: StringName, locale: String) -> void:
		var value: Variant = _overrides.get(node_id, NFDictUtils.EMPTY_DICT).get(locale)
		if typeof(value) != TYPE_ARRAY:
			return
		
		var indexes: Array[int] = []
		for idx in range(value.size()):
			if value[idx] != null:
				indexes.append(idx)
		
		_overrides[node_id].erase(locale)
		if _overrides[node_id].is_empty():
			_overrides.erase(node_id)
		if not indexes.is_empty():
			override_changed.emit(node_id, locale, indexes)
	
	
	## Removes the choice override of index [param choice_idx].
	func remove_choice_override(node_id: StringName, locale: String, choice_idx: int) -> void:
		if not _overrides.has(node_id):
			return
		
		var target: Dictionary = _overrides[node_id]
		var override: Variant = target.get(locale)
		if typeof(override) != TYPE_ARRAY:
			return
		
		if not NFArrayUtils.is_index_valid(override, choice_idx): # Index out of bounds
			return
		
		var arr_size: int = override.size()
		var real_idx: int = wrapi(choice_idx, 0, arr_size)
		
		override[real_idx] = null
		var is_empty: bool = true
		for item in override:
			if item != null:
				is_empty = false
				break
		
		if is_empty:
			target.erase(locale)
			if _overrides[node_id].is_empty():
				_overrides.erase(node_id)
		var i: Array[int] = [real_idx]
		override_changed.emit(node_id, locale, i)


## An override used by [DiscourseDialog] to replace phrases text
## dynamically on dialogue.
class NFPhraseEntryOverride extends RefCounted:
	## Emitted when any of the internal data changes
	signal phrases_changed
	
	var _overrides: Dictionary[StringName, Dictionary] = {}
	var _default_cases: Dictionary[StringName, Dictionary] = {
		 #"DIALOG_ID": {
			#"PhraseKey": {
				#"format_text": {
					#"loc_CODE": ["default", "cases"]
				#}
			#}
		#}
	}
	
	## Overrides a format's case to use the default entry instead.
	## [br][br]
	##  [color=yellow]Warning:[/color] This will clear any data set with
	## [method DiscourseDialog.NFPhraseEntryOverride.set_format_case_override]
	func override_format_case_to_default(dialog: StringName, phrase: String, format: String, case: String, locale: String) -> void:
		if not _default_cases.has(dialog):
			var formats: Dictionary[String, Dictionary] = {}
			_default_cases[dialog] = formats
		
		var dialogue_data: Dictionary = _default_cases[dialog]
		
		if not dialogue_data.has(phrase):
			var new_phrase: Dictionary[String, Dictionary] = {}
			dialogue_data[phrase] = new_phrase
		
		var phrase_data: Dictionary = dialogue_data[phrase]
		
		if not phrase_data.has(format):
			var new_overrides: Dictionary[String, Array] = {}
			phrase_data[format] = new_overrides
		
		var formats_data: Variant = phrase_data[format]
		
		if not formats_data.has(locale):
			var case_arr: Array[String] = []
			formats_data[locale] = case_arr
		
		var overrides: Array[String] = formats_data[locale]
		var update: bool = false
		
		if not overrides.has(case):
			overrides.append(case)
			update = true
		
		var e: Dictionary = NFDictUtils.EMPTY_DICT
		var locales_dict: Dictionary = _overrides.get(dialog, e).get(locale, e).get(phrase, e).get("format", e).get(format, e).get("cases", e)
		if locales_dict.has(case):
			update = true
			locales_dict.erase(case)
		
		if update:
			phrases_changed.emit()
	
	
	## Clears the default override of a format's case, restoring its data.
	func clear_format_case_default(dialog: StringName, phrase: String, format: String, case: String, locale: String) -> void:
		if _erase_format_case_default(dialog, phrase, format, case, locale):
			phrases_changed.emit()
	
	
	## Returns an array of all the overriden cases that are defaulting.
	func get_format_case_default_overriden(dialog: StringName, phrase: String, format: String, locale: String) -> Array[String]:
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
	func get_base_string_override(dialog: StringName, locale: String, phrase: String) -> Variant:
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
	func get_formats_override(dialog: StringName, locale: String, phrase: String) -> Dictionary[String, Dictionary]:
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
			var entry: Dictionary[String, Variant] = {
				"cases": target["cases"].duplicate(true)}
			
			if target["default"] != null:
				entry["default"] = target["default"]
			override_dict[format_key] = entry
			
		return override_dict
	
	
	## Sets a format's default text to be [param default].[br]
	## If [param default] is [code]null[/code] the override is cleared.
	func set_format_default_override(dialog: StringName, locale: String, phrase: String, format: String, default: Variant) -> void:
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
	func set_format_case_override(dialog: StringName, locale: String, phrase: String, format: String, case: String, result: Variant) -> void:
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
	func set_base_string_override(dialog: StringName, locale: String, phrase: String, base: Variant) -> void:
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
	func has_override(dialog_id: StringName) -> bool:
		return _overrides.has(dialog_id) or _default_cases.has(dialog_id)
	
	
	func _erase_format_case_default(dialog: StringName, phrase: String, format: String, case: String, locale: String) -> bool:
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
