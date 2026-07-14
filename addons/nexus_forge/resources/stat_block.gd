@tool
@icon("res://addons/nexus_forge/icons/stats.svg")
class_name StatBlock
extends Resource
## A resource that defines stats for characters.
##
## To add new stats and make them appear on NexusForge you need to add
## a new variable with an export flag and type the stat as a [RangeInt] or
## [RangeFloat] depending on what numerical value you want the stat to be.
## Example: 
## [codeblock]
## @export var new_stat: RangeInt
## [/codeblock]

@export var health: RangeInt

@export_storage var _custom_stats: Dictionary[StringName, ValueRange] = {}

# Global toggle to sync ranges and toggles with the singleton
var _singleton_sync: bool = true
# Specific stats to NOT sync with the singleton
var _sync_blacklist: Dictionary[StringName, Variant] = {}

## Returns all the stats in the statblock. This does NOT include custom stats.[br]
## The key represents the stat, and the value its type from [enum Variant.Type].
static func stats() -> Dictionary[StringName, int]:
	const MASK: int = PROPERTY_USAGE_SCRIPT_VARIABLE + PROPERTY_USAGE_STORAGE
	const VALID_CLASSES: Array[StringName] = [&"RangeInt", &"RangeFloat"]
	
	var block: StatBlock = StatBlock.new(false)
	var all_stats: Dictionary[StringName, int] = {}
	var data: Array[Dictionary] = block.get_script().get_script_property_list()
	
	for item in data:
		if not VALID_CLASSES.has(item["class_name"]) or not BitUtils.are_bits(item["usage"], MASK, true):
			continue
		all_stats[StringName(item["name"])] = TYPE_INT if item["class_name"] == &"RangeInt" else TYPE_FLOAT
	
	return all_stats


func _init(use_nexus_forge: bool = true) -> void:
	if not use_nexus_forge or Engine.is_editor_hint():
		return
	
	for custom_stat in NexusForge.Stats.stats():
		if NexusForge.Stats.is_base_stat(custom_stat) or _custom_stats.has(custom_stat):
			continue
		
		var new_range: ValueRange = RangeInt.new() if NexusForge.Stats.stat_type(custom_stat) == TYPE_INT else RangeFloat.new()
		
		new_range.allow_lesser = NexusForge.Stats.custom_allows_lesser(custom_stat)
		new_range.allow_greater = NexusForge.Stats.custom_allows_greater(custom_stat)
		new_range.min_value = NexusForge.Stats.get_custom_min_value(custom_stat)
		new_range.max_value = NexusForge.Stats.get_custom_max_value(custom_stat)
		
		_custom_stats[custom_stat] = new_range
	
	NexusForge.Stats.stat_created.connect(_on_custom_stat_created)
	NexusForge.Stats.stat_clamping_changed.connect(_on_stat_clamping_changed)
	NexusForge.Stats.stat_clamping_toggled.connect(_on_stat_clamping_toggled)


func _set(property: StringName, value: Variant) -> bool:
	if _custom_stats.has(property) and typeof(value) == TYPE_OBJECT and (value is RangeInt or value is RangeFloat):
		_custom_stats[property] = value
		return true
	return false


func _get(property: StringName) -> Variant:
	if _custom_stats.has(property):
		return _custom_stats[property]
	return null


## This will make sure all stat variables of type RangeInt and
## RangeFloat have objects assigned to them.
func initialize_ranges() -> void:
	var variant: StringName = &""
	for item in get_script().get_script_property_list():
		if item["class_name"] == &"RangeInt":
			variant = StringName(item["name"])
			if get(variant) == null:
				set(variant, RangeInt.new())
		elif item["class_name"] == &"RangeFloat":
			variant = StringName(item["name"])
			if get(variant) == null:
				set(variant, RangeFloat.new())


## Assigns stats (built-in and custom) of another [param stat_block]
## into the [StatBlock].
func assign(stat_block: StatBlock) -> void:
	var properties: Dictionary[StringName, int] = stats()
	for property in properties.keys():
		set(property, stat_block.get(property))
	_custom_stats.assign(stat_block._custom_stats)


func _on_custom_stat_created(stat_id: StringName) -> void:
	if _custom_stats.has(stat_id):
		return
	
	var new_range: ValueRange = RangeInt.new() if NexusForge.Stats.stat_type(stat_id) == TYPE_INT else RangeFloat.new()
	var allows_lesser: bool = NexusForge.Stats.allows_lesser(stat_id) 
	var allows_greater: bool = NexusForge.Stats.allows_greater(stat_id)
	
	new_range.allow_lesser = allows_lesser
	new_range.allow_greater = allows_greater
	
	new_range.min_value = NexusForge.Stats.get_range_min(stat_id)
	new_range.max_value = NexusForge.Stats.get_range_max(stat_id)
	
	_custom_stats[stat_id] = new_range


func _on_stat_clamping_changed(stat_id: StringName) -> void:
	if not _singleton_sync or not _custom_stats.has(stat_id) or _sync_blacklist.has(stat_id):
		return
	
	_custom_stats[stat_id].max_value = NexusForge.Stats.get_range_max(stat_id)
	_custom_stats[stat_id].min_value = NexusForge.Stats.get_range_min(stat_id)


func _on_stat_clamping_toggled(stat_id: StringName) -> void:
	if not _singleton_sync or not _custom_stats.has(stat_id) or _sync_blacklist.has(stat_id):
		return
	
	var stat: ValueRange = _custom_stats[stat_id]
	var allow_greater: bool = NexusForge.Stats.allows_greater(stat_id)
	var allow_lesser: bool = NexusForge.Stats.allows_lesser(stat_id)
	
	stat.allow_greater = allow_greater
	stat.allow_lesser = allow_lesser
	
	stat.max_value = NexusForge.Stats.get_range_max(stat_id)
	stat.min_value = NexusForge.Stats.get_range_min(stat_id)


## Returns all stats used in the statblock
func custom_stats() -> Array[StringName]:
	var all_stats: Array[StringName] = []
	all_stats.assign(_custom_stats.keys())
	return all_stats


## Creates a custom stat of [param type] which can then be
## accessed and modified directly like
## [code]StatBlock.my_custom_trait[/code]. This method returns
## the created object.[br]
## If [param stat_id] already exists and the [param type] matches the stat
## type, it returns the object, otherwise returns [code]null[/code]
func create_custom(stat_id: StringName, type: int) -> ValueRange:
	if _custom_stats.has(stat_id):
		var class_type: int = TYPE_INT if type == TYPE_INT else TYPE_FLOAT
		if _custom_stats[stat_id].range_type() == class_type:
			return _custom_stats[stat_id]
		else:
			return null
	
	_custom_stats[stat_id] = RangeInt.new() if type == TYPE_INT else RangeFloat.new()
	return _custom_stats[stat_id]


## Gets the range of the custom [param stat_id]. Returns [RangeInt] or [RangeFloat]
## depending on the stat type.[br]
## Returns [code]null[/code] if the stat doesn't exist.
func get_custom(stat_id: StringName) -> ValueRange:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id]
	return null


## Returns true if the custom stat [param stat_id] exists. If [param type] is set
## to a type, it'll also check if the stat is of the stated type.
func has_custom(stat_id: StringName, type: int = TYPE_NIL) -> bool:
	if not _custom_stats.has(stat_id):
		return false
	
	if type == TYPE_NIL:
		return true
	else:
		var class_type = TYPE_INT if type == TYPE_INT else TYPE_FLOAT
		return _custom_stats[stat_id].range_type() == class_type


## Returns the stat type that [param stat_id] is.[br]
## Returns [code]TYPE_NIL[/code] if the stat doesn't exist.
func custom_type(stat_id: StringName) -> int:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id].range_type()
	return TYPE_NIL


## Sets whether this object's stats should update along with the singleton. If
## disabled, stats created via the singleton will still be added to the object,
## but their min & max ranges will be 0 and they will allow lesser and greater values.
func set_singleton_sync(enable: bool, sync_now: bool = true) -> void:
	var update: bool = _singleton_sync != enable
	_singleton_sync = enable
	
	if enable and update and sync_now: # Only sync if status changed to enabled
		sync_stats_with_singleton()


## Syncs all of this object's stats to match the data of the singleton, unless
## the stat's sync was disabled with [method StatBlock.set_stat_sync].
func sync_stats_with_singleton() -> void:
	var existing_stats: Dictionary[StringName, int] = stats()
	
	for stat_id in existing_stats.keys():
		if _sync_blacklist.has(stat_id):
			continue
		var stat_range: ValueRange = get(stat_id)
		if stat_range == null:
			stat_range = RangeInt.new() if existing_stats[stat_id] == TYPE_INT else RangeFloat.new()
			set(stat_id, stat_range)
		sync_stat_with_singleton(stat_id)
	
	for stat_id in _custom_stats.keys():
		if _sync_blacklist.has(stat_id):
			continue
		sync_stat_with_singleton(stat_id)


## Enables or disables the synchronization of a specific stat with the Nexus Forge singleton.[br]
## If a stat was disabled and gets re-enabled, using [param sync_now] will force
## the stat to match the current values of the singleton.
func set_stat_sync(stat_id: StringName, enable: bool, sync_now: bool = true) -> void:
	if not enable:
		_sync_blacklist[stat_id] = null
		return
	
	if _sync_blacklist.erase(stat_id) and sync_now:
		sync_stat_with_singleton(stat_id)


## Syncs a specific stat with the singleton values [b]REGARDLESS[/b] 
## of whether the sync was disabled with [method StatBlock.set_stat_sync].
func sync_stat_with_singleton(stat_id: StringName) -> void:
	var stat_range: ValueRange = get(stat_id)
	if stat_range == null:
		if _custom_stats.has(stat_id):
			stat_range = _custom_stats[stat_id]
		else:
			return
	
	stat_range.min_value = NexusForge.Stats.get_range_min(stat_id)
	stat_range.max_value = NexusForge.Stats.get_range_max(stat_id)
	stat_range.allow_lesser = NexusForge.Stats.allows_lesser(stat_id)
	stat_range.allow_greater = NexusForge.Stats.allows_greater(stat_id)
