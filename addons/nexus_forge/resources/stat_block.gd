@tool
@icon("res://addons/nexus_forge/icons/stats.svg")
class_name StatBlock
extends Resource
## A resource that defines stats for characters.
##
## A statsheet that will hold ranges for characters. Has a custom _init
## function that will initialize all null/unassigned RangeFloat and RangeInt
## variables.

enum StatType {
	INTEGER,
	FLOAT}


@export var level: RangeInt
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
	NexusForge.Stats.stat_erased.connect(stat_block._on_custom_stat_erased)
	
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
# is initialized it'll proceed to assign the variables to the file's valies,
# overwriting the newly initialized values.
func _init() -> void:
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
	
	new_range.min_value = NexusForge.Stats.get_custom_min_value(stat_id)
	new_range.max_value = NexusForge.Stats.get_custom_max_value(stat_id)
	
	_custom_stats[stat_id] = new_range


func _on_custom_stat_erased(stat_id: StringName) -> void:
	if _custom_stats.has(stat_id):
		_custom_stats.erase(stat_id)


## Returns all stats used in the statblock
func custom_stats() -> Array[StringName]:
	var all_stats: Array[StringName] = []
	all_stats.assign(_custom_stats.keys())
	return all_stats


## Adds a custom [param stat] to the stat block. [param type] must
func create_custom(stat_id: StringName, type: StatType) -> void:
	if _custom_stats.has(stat_id):
		return
	_custom_stats[stat_id] = RangeInt.new() if type == StatType.INTEGER else RangeFloat.new()


## Gets the range of the custom [param stat_id]. Returns [RangeInt] or [RangeFloat]
## depending on the stat type.[br]
## Returns [code]null[/code] if the stat doesn't exist.
func get_custom(stat_id: StringName) -> ValueRange:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id]
	return null


## Returns true if the custom stat [param stat_id] exists.
func has_custom(stat_id: StringName) -> bool:
	return _custom_stats.has(stat_id)


## Returns the stat type that [param stat_id] is.[br]
## Returns [code]TYPE_NIL[/code] if the stat doesn't exist.
func custom_type(stat_id: StringName) -> int:
	if _custom_stats.has(stat_id):
		return _custom_stats[stat_id].range_type()
	return TYPE_NIL
