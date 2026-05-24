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

enum StatType {
	NIL,
	INTEGER,
	FLOAT}


@export var health: RangeInt

var _custom_stats: Dictionary[StringName, ValueRange] = {}


## Builder that will create a new StatBlock with custom stats defined on
## [member NexusForge.Stats].
static func new_stat_block() -> StatBlock:
	var stat_block: StatBlock = StatBlock.new()
	
	for custom_stat in NexusForge.Stats.custom_stats():
		if stat_block._custom_stats.has(custom_stat):
			continue
		
		var new_range: ValueRange = RangeInt.new() if NexusForge.Stats.custom_stat_type(custom_stat) == StatCatalog.StatType.INTEGER else RangeFloat.new()
		
		new_range.min_value = NexusForge.Stats.get_custom_min_value(custom_stat)
		new_range.max_value = NexusForge.Stats.get_custom_max_value(custom_stat)
		
		stat_block._custom_stats[custom_stat] = NexusForge.Stats.get_custom_default_value(custom_stat)
	
	NexusForge.Stats.stat_created.connect(stat_block._on_custom_stat_created)
	NexusForge.Stats.stat_min_range_changed.connect(stat_block._on_stat_min_range_changed)
	NexusForge.Stats.stat_max_range_changed.connect(stat_block._on_stat_max_range_changed)
	
	return stat_block


## Returns all the stats in the statblock. This does NOT include custom stats.[br]
## The key represents the stat, and the value its type from [enum Variant.Type].
static func stats() -> Dictionary[StringName, int]:
	const MASK: int = PROPERTY_USAGE_SCRIPT_VARIABLE + PROPERTY_USAGE_STORAGE
	const VALID_CLASSES: Array[StringName] = [&"RangeInt", &"RangeFloat"]
	
	var block: StatBlock = StatBlock.new()
	var all_stats: Dictionary[StringName, int] = {}
	var data: Array[Dictionary] = block.get_script().get_script_property_list()
	
	for item in data:
		if not VALID_CLASSES.has(item["class_name"]) or not BitUtils.are_bits(item["usage"], MASK, true):
			continue
		all_stats[StringName(item["name"])] = TYPE_INT if item["class_name"] == &"RangeInt" else TYPE_FLOAT
	
	return all_stats


# This init will make sure all RangeInt and RangeFloat are not null.
# Note that initialization (_init) comes BEFORE loading, so once the file
# is initialized it'll proceed to assign the variables to the file's values,
# overwriting the newly initialized ones.
func _init(initialize_ranges: bool = false) -> void:
	if initialize_ranges == false:
		return
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


func _on_custom_stat_created(stat_id: StringName) -> void:
	if _custom_stats.has(stat_id):
		return
	
	var new_range: ValueRange = RangeInt.new() if NexusForge.Stats.custom_stat_type(stat_id) == StatCatalog.StatType.INTEGER else RangeFloat.new()
	
	new_range.allow_lesser = NexusForge.Stats.custom_allows_lesser(stat_id)
	new_range.allow_greater = NexusForge.Stats.custom_allows_greater(stat_id)
	new_range.min_value = NexusForge.Stats.get_custom_min_value(stat_id)
	new_range.max_value = NexusForge.Stats.get_custom_max_value(stat_id)
	
	_custom_stats[stat_id] = new_range


func _on_stat_min_range_changed(stat_id: StringName, new_min: float) -> void:
	if not _custom_stats.has(stat_id):
		return
	_custom_stats[stat_id].min_value = new_min


func _on_stat_max_range_changed(stat_id: StringName, new_max: float) -> void:
	if not _custom_stats.has(stat_id):
		return
	_custom_stats[stat_id].max_value = new_max


## Returns all stats used in the statblock
func custom_stats() -> Array[StringName]:
	var all_stats: Array[StringName] = []
	all_stats.assign(_custom_stats.keys())
	return all_stats


## Adds a custom [param type] [param stat] to the stat block and returns the
## created object.[br]
## If [param stat_id] already exists and the [param type] matches the stat
## type, it returns the object, otherwise returns [code]null[/code]
func create_custom(stat_id: StringName, type: StatType) -> ValueRange:
	if _custom_stats.has(stat_id):
		var class_type: int = TYPE_INT if type == StatType.INTEGER else TYPE_FLOAT
		if _custom_stats[stat_id].range_type() == class_type:
			return _custom_stats[stat_id]
		else:
			return null
	
	_custom_stats[stat_id] = RangeInt.new() if type == StatType.INTEGER else RangeFloat.new()
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
func has_custom(stat_id: StringName, type: StatType = StatType.NIL) -> bool:
	if not _custom_stats.has(stat_id):
		return false
	
	if type == StatType.NIL:
		return true
	else:
		var class_type = TYPE_INT if type == StatType.INTEGER else TYPE_FLOAT
		return _custom_stats[stat_id].range_type() == class_type


## Returns the stat type that [param stat_id] is.[br]
## Returns [code]TYPE_NIL[/code] if the stat doesn't exist.
func custom_type(stat_id: StringName) -> int:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id].range_type()
	return TYPE_NIL
