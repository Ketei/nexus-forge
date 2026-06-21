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

@export_storage var _custom_stats: Dictionary[StringName, ValueRange] = {}


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
	if not use_nexus_forge or not NexusForge.is_inside_tree():
		return
	
	for custom_stat in NexusForge.Stats.custom_stats():
		if _custom_stats.has(custom_stat):
			continue
		
		var new_range: ValueRange = RangeInt.new() if NexusForge.Stats.custom_stat_type(custom_stat) == StatCatalog.StatType.INTEGER else RangeFloat.new()
		
		new_range.allow_lesser = NexusForge.Stats.custom_allows_lesser(custom_stat)
		new_range.allow_greater = NexusForge.Stats.custom_allows_greater(custom_stat)
		new_range.min_value = NexusForge.Stats.get_custom_min_value(custom_stat)
		new_range.max_value = NexusForge.Stats.get_custom_max_value(custom_stat)
		
		_custom_stats[custom_stat] = new_range
	
	NexusForge.Stats.stat_created.connect(_on_custom_stat_created)
	NexusForge.Stats.stat_min_range_changed.connect(_on_stat_min_range_changed)
	NexusForge.Stats.stat_max_range_changed.connect(_on_stat_max_range_changed)


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


## Creates a custom stat of [param type] which can then be
## accessed and modified directly like
## [code]StatBlock.my_custom_trait[/code]. This method returns
## the created object.[br]
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
