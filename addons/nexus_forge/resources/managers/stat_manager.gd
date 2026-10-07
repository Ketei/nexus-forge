class_name NFStatManager
extends RefCounted
## An object to keep track of stat's info and custom stats.
##
## This object can keep track of data of base and custom stats.

## Emitted when a stat is created.
signal stat_created(stat_id: StringName)
## Emitted when a stat is erased.
signal stat_erased(stat_id: StringName)
## Emits when allow_greater or allow_lesser on a stat is toggled.
signal stat_clamping_toggled(for_stat: StringName)
## Emits when max_value and min_value on a stat change and it's respective
## allow_* is disabled.
signal stat_clamping_changed(for_stat: StringName)
## Emitted when a stat name or descriptions are updated
signal stat_info_changed(stat_id: StringName)
## Emitted when a stat custom data changes.
signal stat_data_changed(stat_id: StringName)


# Custom stats where the value is an integer array holding 2 values [min, max]
# &"health": {"name": "Health", "description": "Life!", "allow_*": true, "*_value": 0, "data": {}}
var _stat_entries: Dictionary[StringName, NFCatalogEntryStat] = {}
#var _stat_ranges: Dictionary[StringName, Dictionary] = {}
var _base_stats: Dictionary[StringName, int] = {}


func _init() -> void:
	_base_stats.assign(NFStatBlock.stats())
	
	for stat in _base_stats:
		var entry: NFCatalogEntryStat = NFCatalogEntryStat.new()
		entry.name = String(stat).capitalize()
		entry.is_float = _base_stats[stat] == TYPE_FLOAT
		entry._flags = NFCatalogEntry._get_flags(false, true)
		_stat_entries[stat] = entry
	
	_base_stats.make_read_only()


## Loads a stat [param catalog] into this object. If [param clear_stats]
## is [code]true[/code] then previous stat data will be cleared.
func load_catalog(catalog: NFStatCatalog, clear_stats: bool = true) -> void:
	if clear_stats:
		for entry in _stat_entries.keys():
				if _base_stats.has(entry):
					continue
				_stat_entries.erase(entry)
	
	for stat_id in catalog.stats():
		var new_data: NFCatalogEntryStat = NFCatalogEntryStat.new()
		new_data.name = catalog.get_stat_name(stat_id)
		new_data.description = catalog.get_stat_description(stat_id)
		new_data.custom_data.assign(catalog.stat_data(stat_id))
		new_data.is_float = catalog.stat_type(stat_id) != TYPE_INT
		new_data.min_value = catalog.get_min_value(stat_id)
		new_data.max_value = catalog.get_max_value(stat_id)
		new_data.allow_lesser = catalog.allows_lesser(stat_id)
		new_data.allow_greater = catalog.allows_greater(stat_id)
		
		new_data._flags = NFCatalogEntry._get_flags(not _base_stats.has(stat_id), true)
		_stat_entries[stat_id] = new_data


## Returns an array containing all registered stats.
func stats() -> Array[StringName]:
	return NFArrayUtils.create_typed(TYPE_STRING_NAME, _stat_entries.keys())


## Returns ture if a stat [param stat_id] is registered.
func has_stat(stat_id: StringName) -> bool:
	return _stat_entries.has(stat_id)


## Returns [code]true[/code] if the stat belongs to declared stats on the
## [NFStatBlock].
func is_base_stat(stat_id: StringName) -> bool:
	return _base_stats.has(stat_id)


## Registers a custom stat with [param stat_id]. If [param as_float] is
## [code]true[/code] it'll be registered as a float, otherwise it'll be an int.
## [br][br]
## [b]Note:[/b] Registering a new stat will also add them to all existing
## [NFStatBlock]s and include them on newly instantiated ones.
func create_stat(stat_id: StringName, as_float: bool) -> void:
	if _stat_entries.has(stat_id):
		return
	
	var new_entry: NFCatalogEntryStat = NFCatalogEntryStat.new()
	
	new_entry.name = String(stat_id).capitalize()
	new_entry.is_float = as_float
	new_entry._flags = NFCatalogEntry._get_flags(true, true)
	
	_stat_entries[stat_id] = new_entry
	
	stat_created.emit(stat_id)


## Sets a the stat [param stat_id] name to [param new_name].
func set_stat_name(stat_id: StringName, new_name: String) -> void:
	if not _stat_entries.has(stat_id) or _stat_entries[stat_id].name == new_name:
		return
	
	_stat_entries[stat_id].name = new_name
	stat_info_changed.emit(stat_id)


## Sets a the stat [param stat_id] description to [param description].
func set_stat_description(stat_id: StringName, description: String) -> void:
	if not _stat_entries.has(stat_id) or _stat_entries[stat_id].description == description:
		return
	
	_stat_entries[stat_id].description = description
	stat_info_changed.emit(stat_id)


## Returns the [param stat_id] name or an empty string if not found.
func get_stat_name(stat_id: StringName) -> String:
	if _stat_entries.has(stat_id):
		return _stat_entries[stat_id].name
	return ""


## Returns the [param stat_id] description or an empty string if not found.
func get_stat_description(stat_id: StringName) -> String:
	if _stat_entries.has(stat_id):
		return _stat_entries[stat_id].description
	return ""


## Sets the stat [param stat_id] custom data [param data_key] to [param data].
## If [param data] is [code]null[/code] then the entry is removed.
func set_stat_data(stat_id: StringName, data_key: StringName, data) -> void:
	if not _stat_entries.has(stat_id):
		return
	
	if data == null:
		_stat_entries[stat_id].custom_data.erase(data_key)
	else:
		_stat_entries[stat_id].custom_data[data_key] = data
	
	stat_data_changed.emit(stat_id)


## Gets the stat [param stat_id] custom data [param data_key] or [code]null[/code]
## if not found.
func get_stat_data(stat_id: StringName, data_key: String) -> Variant:
	if _stat_entries.has(stat_id):
		return _stat_entries[stat_id].custom_data.get(data_key)
	return null


## Clears a stat custom data.
func clear_data(stat_id: StringName) -> void:
	if _stat_entries.has(stat_id):
		_stat_entries[stat_id].custom_data.clear()
		stat_data_changed.emit(stat_id)


## Sets a new minimum value of a stat [param stat_id] to [param new_min].[br][br]
## [b]Note:[/b] If the maximum value is less than the new minimum assigned, the max
## value will be increased to match the minimum value.
func set_stat_min(stat_id: StringName, new_min: float) -> void:
	var obj: NFCatalogEntryStat = _stat_entries.get(stat_id)
	
	if obj == null or obj.min_value == new_min:
		return
	
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, false)
	var greater_push: bool = not obj.allow_greater and obj.max_value < new_min
	obj.min_value = new_min
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, true)
	if not obj.allow_lesser or greater_push:
		stat_clamping_changed.emit(stat_id)


## Sets a new maximum value of a stat [param stat_id] to [param new_max].[br][br]
## [b]Note:[/b] The maximum value can't be less than the assigned minimum value.
func set_stat_max(stat_id: StringName, new_max: float) -> void:
	var obj: NFCatalogEntryStat = _stat_entries.get(stat_id)
	
	if obj == null:
		return
	
	var actual_new_max: float = maxf(new_max, obj.min_value)
	if obj.max_value == actual_new_max:
		return
	
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, false)
	obj.max_value = new_max
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, true)
	if not obj.allow_greater:
		stat_clamping_changed.emit(stat_id)


## Sets a range of a stat.
func set_stat_range(stat_id: StringName, min_range: float, max_range: float) -> void:
	var obj: NFCatalogEntryStat = _stat_entries.get(stat_id)
	
	if obj == null:
		return
	
	var push_max: float = maxf(min_range, max_range)
	var same_min: bool = obj.min_value == min_range
	var same_max: bool = obj.max_value == push_max
	
	if same_min and same_max:
		return
	
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, false)
	obj.min_value = min_range
	obj.max_value = push_max
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, true)
	
	var min_affects_clamp: bool = not same_min and not obj.allow_lesser
	var max_affects_clamp: bool = not same_max and not obj.allow_greater
	
	if min_affects_clamp or max_affects_clamp:
		stat_clamping_changed.emit(stat_id)


## Returns true if the custom stat [param stat_id] allows for lesser values or
## the stat doesn't exists.
func allows_lesser(stat_id: StringName) -> bool:
	var obj: NFCatalogEntryStat = _stat_entries.get(stat_id)
	if obj == null:
		return true
	return obj.allow_lesser


## Returns true if the custom stat [param stat_id] allows for greater values or
## the stat doesn't exists.
func allows_greater(stat_id: StringName) -> bool:
	var obj: NFCatalogEntryStat = _stat_entries.get(stat_id)
	if obj == null:
		return true
	return obj.allow_greater


## Sets if a stat should [param allow] lesser values than the minimum set.
func set_allow_lesser(for_stat: StringName, allow: bool) -> void:
	var obj: NFCatalogEntryStat = _stat_entries.get(for_stat)
	
	if obj == null or obj.allow_lesser == allow:
		return
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, false)
	obj.allow_lesser = allow
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, true)
	stat_clamping_toggled.emit(for_stat)


## Sets if a stat should [param allow] greater values than the maximum set.
func set_allow_greater(for_stat: StringName, allow: bool) -> void:
	var obj: NFCatalogEntryStat = _stat_entries.get(for_stat)
	
	if obj == null or obj.allow_greater == allow:
		return
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, false)
	obj.allow_greater = allow
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, true)
	
	stat_clamping_toggled.emit(for_stat)


## Sets if a stat should use a min/max range.
func set_use_range(stat_id: StringName, allow_lesser: bool, allow_greater: bool) -> void:
	var obj: NFCatalogEntryStat = _stat_entries.get(stat_id)
	
	if obj == null:
		return
	
	var greater_changed: bool = obj.allow_greater != allow_greater
	var lesser_changed: bool = obj.allow_lesser != allow_lesser
	
	if not greater_changed and not lesser_changed:
		return
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, false)
	obj.allow_lesser = allow_lesser
	obj.allow_greater = allow_greater
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, true)
	
	if lesser_changed or greater_changed:
		stat_clamping_toggled.emit(stat_id)


## Sets the ranges of a stat and if they should be clamped. Emits relevant signals
## after setting.
func set_stat_clamping(stat_id: StringName, allow_lesser: bool, min_val: float, allow_greater: bool, max_val: float) -> void:
	var obj: NFCatalogEntryStat = _stat_entries.get(stat_id)
	
	if obj == null:
		return
	
	var pushed_max: float = maxf(min_val, max_val)
	
	var allow_min_changed: bool = obj.allow_lesser != allow_lesser
	var allow_max_changed: bool = obj.allow_greater != allow_greater
	var min_val_changed: bool = obj.min_value != min_val
	var max_val_changed: bool = obj.max_value != pushed_max
	
	if not allow_min_changed and not allow_max_changed and not min_val_changed and not max_val_changed:
		return
	
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, false)
	
	if allow_min_changed or allow_max_changed:
		obj.allow_lesser = allow_lesser
		obj.allow_greater = allow_greater
	
	if min_val_changed or max_val_changed:
		obj.min_value = min_val
		obj.max_value = pushed_max
	
	obj._flags = NFBitUtils.set_bit_index(obj._flags, 63, true)
	
	if allow_min_changed or allow_max_changed:
		stat_clamping_toggled.emit(stat_id)
	
	if min_val_changed or max_val_changed:
		var min_affects_clamp: bool = min_val_changed and not obj.allow_lesser
		var max_affects_clamp: bool = max_val_changed and not obj.allow_greater
	
		if min_affects_clamp or max_affects_clamp:
			stat_clamping_changed.emit(stat_id)


## Returns the minumum value of [param stat_id] or 0.0 if it doesn't exist.
func get_range_min(stat_id: StringName) -> float:
	var obj: NFCatalogEntryStat = _stat_entries.get(stat_id)
	
	if obj == null:
		return 0.0
	return obj.min_value


## Returns the maximum value of [param stat_id] or 0.0 if it doesn't exist.
func get_range_max(stat_id: StringName) -> float:
	var obj: NFCatalogEntryStat = _stat_entries.get(stat_id)
	
	if obj == null:
		return 0.0
	return obj.max_value


## Erases the custom stat [param stat_id] if it exists.[br]
## Erasing a stat WON'T erase it from existing [NFStatBlock]s, but will prevent
## new ones from having the custom stat in them.
func erase_stat(stat_id: StringName) -> void:
	if not _stat_entries.has(stat_id):
		return
	
	if _base_stats.has(stat_id):
		NFPluginGameHandler._log_msg(
				"stats",
				"Erasing built-in stats is disallowed.",
				NFPluginGameHandler._LogLevel.WARNING)
		return
	
	if _stat_entries.erase(stat_id):
		stat_erased.emit(stat_id)
