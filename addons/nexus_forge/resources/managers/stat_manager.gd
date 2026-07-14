class_name NFStatManager
extends RefCounted
## An object to keep track of stat's info and custom stats.
##
## This object can keep track of data of base and custom stats. Data
## can be accessed directly by using the ID of the stat eg. [code]Stats.my_stat[/code].
## If the stat isn't registered a fallback object will be returned. You can
## call is_valid() to verify a stat validity as well as is_custom() to
## see if the stat is custom.

## Emmited when a stat is created.
signal stat_created(stat_id: StringName)
## Emmited when a stat is erased.
signal stat_erased(stat_id: StringName)
## Emits when allow_greater or allow_lesser on a stat is toggled.
signal stat_clamping_toggled(for_stat: StringName)
## Emits when max_value and min_value on a stat change and it's respective
## allow_* is enabled.
signal stat_clamping_changed(for_stat: StringName)


# Custom stats where the value is an integer array holding 2 values [min, max]
# &"health": {"name": "Health", "description": "Life!", "allow_*": true, "*_value": 0, "data": {}}
var _stat_entries: Dictionary[StringName, NFCatalogEntryStat] = {}
var _stat_ranges: Dictionary[StringName, Dictionary] = {}
var _base_stats: Dictionary[StringName, int] = {}


func _init() -> void:
	_base_stats.assign(StatBlock.stats())
	
	for stat in _base_stats.keys():
		var entry: NFCatalogEntryStat = NFCatalogEntryStat.new()
		entry.name = String(stat).capitalize()
		entry._flags = NFCatalogEntry._get_flags(true, false, true)
		_stat_entries[stat] = entry
	
	_base_stats.make_read_only()


func _get(property: StringName) -> Variant:
	if _stat_entries.has(property):
		return _stat_entries[property]
	var invalid: NFCatalogEntryStat = NFCatalogEntryStat.new()
	invalid._flags = NFCatalogEntry._get_flags(false, false, true)
	return invalid


## Loads a stat [param catalog] into this object. If [param clear_stats]
## is [code]true[/code] then previous stat data will be cleared.
func load_catalog(catalog: StatCatalog, clear_stats: bool = true) -> void:
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
		new_data.type = catalog.stat_type(stat_id)
		new_data._flags = NFCatalogEntry._get_flags(true, not _base_stats.has(stat_id), true)
		_stat_entries[stat_id] = new_data


## Returns an array containing all registered stats.
func stats() -> Array[StringName]:
	return ArrayUtils.create_typed(TYPE_STRING_NAME, _stat_entries.keys())


## Returns ture if a stat [param stat_id] is registered.
func has_stat(stat_id: StringName) -> bool:
	return _stat_entries.has(stat_id)


## Returns [code]true[/code] if the stat belongs to declared stats on the
## [StatBlock].
func is_base_stat(stat_id: StringName) -> bool:
	return _base_stats.has(stat_id)


## Registers a custom stat with [param stat_id] of type [param type] unless
## it already exists. After creation you can access the stat directly by doing
## [code]Stats.my_custom_stat[/code]. Access will return a [NFCatalogEntryStat] object.[br]
## Registering a new stat will also add them to all existing [StatBlock]s and
## include them on newly instantiated ones.
func create_stat(stat_id: StringName, type: int) -> void:
	if _stat_entries.has(stat_id):
		return
	
	var new_entry: NFCatalogEntryStat = NFCatalogEntryStat.new()
	
	new_entry.name = String(stat_id).capitalize()
	new_entry.type = type
	new_entry._valid = true
	new_entry._custom = true
	
	_stat_entries[stat_id] = new_entry
	
	stat_created.emit(stat_id)


## Returns the built-in type of a stat. Either [code]TYPE_INT[/code] or
## [code]TYPE_FLOAT[/code].[br]
## Returns [code]TYPE_NIL[/code] if the stat doesn't exist.
func stat_type(stat_id: StringName) -> int:
	if not _stat_entries.has(stat_id):
		return _stat_entries[stat_id].type
	return TYPE_NIL


## Sets a the stat [param stat_id] name to [param new_name].
func set_stat_name(stat_id: StringName, new_name: String) -> void:
	if not _stat_entries.has(stat_id):
		return
	
	_stat_entries[stat_id].name = new_name


## Sets a the stat [param stat_id] description to [param description].
func set_stat_description(stat_id: StringName, description: String) -> void:
	if not _stat_entries.has(stat_id):
		return
	
	_stat_entries[stat_id].description = description


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
func set_stat_data(stat_id: StringName, data_key: String, data) -> void:
	if not _stat_entries.has(stat_id):
		return
	
	if data == null:
		_stat_entries[stat_id].custom_data.erase(data_key)
	else:
		_stat_entries[stat_id].custom_data[data_key] = data


## Gets the stat [param stat_id] custom data [param data_key] or [code]null[/code]
## if not found.
func get_stat_data(stat_id: StringName, data_key: String) -> Variant:
	if _stat_entries.has(stat_id) and _stat_entries[stat_id].custom_data.has(data_key):
		return _stat_entries[stat_id].custom_data[data_key]
	return null


## Clears a stat custom data.
func clear_data(stat_id: StringName) -> void:
	if _stat_entries.has(stat_id):
		_stat_entries[stat_id].custom_data.clear()


## Sets a new minimum value of a stat [param stat_id] to [param new_min].[br][br]
## [b]Note:[/b] If the maximum value is less than the new minimum assigned, the max
## value will be increased to match the minimum value.
func set_stat_min(stat_id: StringName, new_min: float) -> void:
	if not _stat_entries.has(stat_id):
		return
	
	if not _stat_ranges.has(stat_id):
		var entry: Dictionary[String, Variant] = {
			"min_value": 0.0,
			"max_value": 0.0,
			"allow_greater": true,
			"allow_lesser": true}
		_stat_ranges[stat_id] = entry
	
	if _stat_ranges[stat_id]["min_value"] == new_min:
		return
	
	_stat_ranges[stat_id]["min_value"] = new_min
	if _stat_ranges[stat_id]["max_value"] < new_min:
		_stat_ranges[stat_id]["max_value"] = new_min
	
	if not _stat_ranges[stat_id]["allow_lesser"]:
		stat_clamping_changed.emit(stat_id)


## Sets a new maximum value of a stat [param stat_id] to [param new_max].[br][br]
## [b]Note:[/b] The maximum value can't be less than the assigned minimum value.
func set_stat_max(stat_id: StringName, new_max: float) -> void:
	if not _stat_ranges.has(stat_id):
		var entry: Dictionary[String, Variant] = {
			"min_value": 0.0,
			"max_value": 0.0,
			"allow_greater": true,
			"allow_lesser": true}
		_stat_ranges[stat_id] = entry
	
	var true_max: float = maxf(_stat_ranges[stat_id]["min_value"], new_max)
	
	if _stat_ranges[stat_id]["max_value"] == true_max:
		return
	
	_stat_ranges[stat_id]["max_value"] = true_max
	
	if not _stat_ranges[stat_id]["allow_greater"]:
		stat_clamping_changed.emit(stat_id)


## Sets a range of a stat.
func set_stat_range(stat_id: StringName, min_range: float, max_range: float) -> void:
	if not _stat_ranges.has(stat_id):
		var entry: Dictionary[String, Variant] = {
			"min_value": 0.0,
			"max_value": 0.0,
			"allow_greater": true,
			"allow_lesser": true}
		_stat_ranges[stat_id] = entry
	
	var update: bool = false
	var true_min: float = 0.0
	var true_max: float = 0.0
	
	if min_range < max_range:
		true_min = min_range
		true_max = max_range
	else:
		true_min = max_range
		true_max = min_range
	
	if _stat_ranges[stat_id]["min_value"] != true_min:
		_stat_ranges[stat_id]["min_value"] = true_min
		update = not _stat_ranges[stat_id]["allow_lesser"]
	
	if _stat_ranges[stat_id]["max_value"] != true_max:
		_stat_ranges[stat_id]["max_value"] = true_max
		if not update:
			update = not _stat_ranges[stat_id]["allow_greater"]
	
	if update:
		stat_clamping_changed.emit(stat_id)


## Returns true if the custom stat [param stat_id] allows for lesser values or
## the stat doesn't exists.
func allows_lesser(stat_id: StringName) -> bool:
	if _stat_ranges.has(stat_id):
		return _stat_ranges[stat_id]["allow_lesser"]
	return true


## Returns true if the custom stat [param stat_id] allows for greater values or
## the stat doesn't exists.
func allows_greater(stat_id: StringName) -> bool:
	if _stat_ranges.has(stat_id):
		return _stat_ranges[stat_id]["allow_greater"]
	return true


## Sets if a stat should [param allow] lesser values than the minimum set.
func set_allow_lesser(for_stat: StringName, allow: bool) -> void:
	if not _stat_entries.has(for_stat):
		return
	
	if not _stat_ranges.has(for_stat):
		var entry: Dictionary[String, Variant] = {
			"min_value": 0.0,
			"max_value": 0.0,
			"allow_greater": true,
			"allow_lesser": true}
		_stat_ranges[for_stat] = entry
	
	if _stat_ranges[for_stat]["allow_lesser"] == allow:
		return
	
	_stat_ranges[for_stat]["allow_lesser"] = allow
	stat_clamping_toggled.emit(for_stat)


## Sets if a stat should [param allow] greater values than the maximum set.
func set_allow_greater(for_stat: StringName, allow: bool) -> void:
	if not _stat_entries.has(for_stat):
		return
	
	if not _stat_ranges.has(for_stat):
		var entry: Dictionary[String, Variant] = {
			"min_value": 0.0,
			"max_value": 0.0,
			"allow_greater": true,
			"allow_lesser": true}
		_stat_ranges[for_stat] = entry
	
	if _stat_ranges[for_stat]["allow_greater"] == allow:
		return
	
	_stat_ranges[for_stat]["allow_greater"] = allow
	stat_clamping_toggled.emit(for_stat)


## Sets if a stat should use a min/max range.
func set_use_range(stat_id: StringName, allow_lesser: bool, allow_greater: bool) -> void:
	if not _stat_entries.has(stat_id):
		return
	
	if not _stat_ranges.has(stat_id):
		var entry: Dictionary[String, Variant] = {
			"min_value": 0.0,
			"max_value": 0.0,
			"allow_greater": true,
			"allow_lesser": true}
		_stat_ranges[stat_id] = entry
	
	var update: bool = false
	
	if _stat_ranges[stat_id]["allow_lesser"] != allow_lesser:
		_stat_ranges[stat_id]["allow_lesser"] = allow_lesser
		update = true
		
	if _stat_ranges[stat_id]["allow_greater"] != allow_greater:
		_stat_ranges[stat_id]["allow_greater"] = allow_greater
		update = true
	
	if update:
		stat_clamping_toggled.emit(stat_id)


## Returns the minumum value of [param stat_id] or 0.0 if it doesn't exist.
func get_range_min(stat_id: StringName) -> float:
	if not _stat_ranges.has(stat_id):
		return 0.0
	
	var value: float = _stat_ranges[stat_id]["min_value"]
	if _stat_entries[stat_id].type == TYPE_INT:
		return snappedf(value, 1.0)
	return value


## Returns the maximum value of [param stat_id] or 0.0 if it doesn't exist.
func get_range_max(stat_id: StringName) -> float:
	if not _stat_ranges.has(stat_id):
		return 0.0
	
	var value: float = _stat_ranges[stat_id]["max_value"]
	if _stat_entries[stat_id].type == TYPE_INT:
		return snappedf(value, 1.0)
	return value


## Erases the custom stat [param stat_id] if it exists.[br]
## Erasing a stat WON'T erase it from existing [StatBlock]s, but will prevent
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
