@tool
class_name NFQuestRes
extends Resource


signal unique_quest_finished(quest_id: String)
signal boiler_quest_finished(quest_id: String, unique_id: String)

const SETTINGS_PATH: String = "nexus_forge/quests_resource"

# Holds the boiler quests.
#@export var quests_boiler: Dictionary = {}

var quest_ex = {
	"kobold_egg": {
		"title": "",
		"description": "",
		"events": {
			"quest_successful": {
				"items": {"item_id": {"count": 0, "operator": OP_ADD}},
				"currency": {"currency_id": {"count": 0, "operator": OP_ADD}},
				"variables": [{"path": "", "value": null, "operator": OP_EQUAL}],
				"data": {"data_id": null},
			}
		},
		"stages": [
			{
				"title": "",
				"description": "",
				"requirements": {
					"items": {
						"item_id": {
							"amount": 10,
							"operator": OP_EQUAL,
							"custom_data": {
								"data_key": {"operator": OP_EQUAL, "value": 0}
							}}},
					"variables": [
						{
							"path": "stats/stamina",
							"value": 10,
							"operator": OP_GREATER_EQUAL
						}
					],
					"triggers": {
						"trigger_id": {
							"count": 2,
							"operator": OP_LESS_EQUAL}},
					"data": {
						"data_id": null
					} # This contains custom data for the dev to parse
				}
			}
		]
	}
}

var stages = [{"pool_name": "Stage Pool", "pool_items": []}]

var boiler_ex = { # Example, not required
	"boiler_a": {
		"title": "",
		"description": "",
		"completion_limit": 1,
		"events": {},
		"stages": [
			{
				"pool_name": "",
				"pool_items": [
					{
						"title": "",
						"description": "",
						"requirements": {
							"items": [
								{
									"item": "",
									"amount": 10,
									"operator": OP_GREATER_EQUAL,
									"custom_data": [{}],
								}],
							"variables": [
								{
									"path": "stats/stamina",
									"value": 10,
									"operator": OP_GREATER_EQUAL
								}],
							"triggers": [
								{
									"trigger": &"trigger_id",
									"count": 0,
									"operator": OP_EQUAL}],
							"data": {}}
							
					}
				]
			}
		],
	}
}

var quest_main_tracker_example: Array[Dictionary] = [{
	"id": "kobold_egg",
	"stage": 0, # Current stage the quest is at.
}]

var quest_boiler_tracker_ex: Array[Dictionary] = [
	{
		"id": "given_id", # The id given to this quest by the creator
		"boiler": "boiler_a", # The key given in the dictionary
		"title": "",
		"description": "",
		"stage": 0,
		# The index references the stage the quest is at, the second is the
		# index of the item in the pool array of the boiler quests.
		# quests_boiler["stages"][this.stage][this.stages[this.stage]]
		"stages": [3,8,0]
	}
]

## Holds all unique quests.
@export var quests_main: Dictionary = {}
@export var quests_boiler: Dictionary = {}
#@export var _main_id_counter: int = -1
#@export var _boiler_id_counter: int = -1
## Has all the finished quests
var finished_unique: Array[String] = []
var finished_boiler: Dictionary = {"boiler_a": 3}
var trigger_tracker: Dictionary = {
	"trigger_id": {"count": 16, "referenced": {"main": ["string"], "boiler": ["asd"], "custom": ["asd"]}}
}
## Has all the active quests.
var active_main_quests: Array[Dictionary] = []
var active_boiler_quests: Array[Dictionary] = []

# Used so that we arent counting the array every time.
var _main_tracker: int = 0 # How many active main quests there are.
var _boiler_tracker: int = 0 # How many active bolier quests there are


func _can_trigger_be_freed(trigger_id: String) -> bool:
	return trigger_tracker[trigger_id]["referenced"]["main"].is_empty() and\
		trigger_tracker[trigger_id]["referenced"]["boiler"].is_empty() and\
		trigger_tracker[trigger_id]["referenced"]["custom"].is_empty()


func _get_main_quest_triggers(quest_id: String) -> Array[String]:
	var triggers: Array[String] = []
	
	for stage_dict:Dictionary in quests_main[quest_id]["stages"]:
		if not stage_dict["requirements"].has("stages"):
			continue
		
		for requirement in stage_dict["requirements"]["triggers"]:
			triggers.append(requirement["trigger"])
	
	return triggers


func _get_boiler_quest_triggers(quest_id: String, stage: int, pool_indexes: Array[int]) -> Array[String]:
	var triggers: Array[String] = []
	
	for pool_idx in pool_indexes:
		if quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"].has("triggers"):
			
			for trigger in quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["triggers"]:
				triggers.append(trigger["trigger"])
		
	return triggers


func _add_trigger_quest_tracker(trigger_id: String, quest_id: String, is_main: bool) -> void:
	var type_key: String = "main" if is_main else "boiler"
	if not trigger_tracker[trigger_id]["referenced"][type_key].has(quest_id):
		trigger_tracker[trigger_id]["referenced"][type_key].append(quest_id)


func _remove_trigger_quest_tracker(trigger_id: String, quest_id: String, is_main: bool) -> void:
	var type_key: String = "main" if is_main else "boiler"
	trigger_tracker[trigger_id]["referenced"][type_key].erase(quest_id)

# --- Main ---

func start_quest_main(quest_id: String, stage: int = 0) -> int:
	for trigger in _get_main_quest_triggers(quest_id):
		if not has_trigger(trigger):
			create_trigger(trigger)
		
		_add_trigger_quest_tracker(trigger, quest_id, true)
	
	active_main_quests.append({
		"id": quest_id,
		"stage": stage})
	
	_main_tracker += 1
	return _main_tracker - 1


func is_main_quest_started(quest_key: String) -> bool:
	for quest in active_main_quests:
		if quest["id"] == quest_key:
			return true
	return false


func finish_main_quest(quest_idx: int) -> void:
	var quest_id: String = active_main_quests[quest_idx]["id"]
	
	Arrays.remove_unsorted_at(active_main_quests, quest_idx)
	
	if Arrays.binary_search(finished_unique, quest_id) == -1: # If it isn't finished, add it to the finished list.
		Arrays.insert_sorted_asc(finished_unique, quest_id)
	
	for trigger in _get_main_quest_triggers(quest_id):
		_remove_trigger_quest_tracker(trigger, quest_id, true)
		if _can_trigger_be_freed(trigger):
			remove_trigger(trigger)
	
	_main_tracker -= 1


func main_quest_next_stage(quest_idx: int) -> void:
	active_main_quests[quest_idx]["stage"] = mini(
		active_main_quests[quest_idx]["stage"] + 1,
		quests_main[active_main_quests[quest_idx]["id"]]["stages"].size() - 1)


func set_main_quest_stage(quest_idx: int, quest_stage: int) -> void:
	var quest_key: String = active_main_quests[quest_idx]["id"]
	
	var clamped_stage: int = clampi(
		quest_stage,
		0,
		quests_main[quest_key]["stages"].size() - 1)
	
	active_main_quests[quest_idx]["stage"] = clamped_stage


func get_main_quest_stage(quest_idx: int) -> int:
	return active_main_quests[quest_idx]["stage"]


# --- Boiler ---

## Starts a boiler-quest. Requires an unique_id to be differentiated from the
## rest of the quests. Check with [method is_boiler_id_free] to check if the id
## is available.
func start_quest_boiler(boiler_data: Dictionary) -> int:
	var required_triggers: Array[String] = []
	
	for stage in range(get_boiler_quest_stage_count(boiler_data["id"])):
		Arrays.append_uniques(
			required_triggers,
			_get_boiler_quest_triggers(
				boiler_data["boiler"],
				stage,
				boiler_data["stages"]))
	
	for trigger in required_triggers:
		if not has_trigger(trigger):
			create_trigger(trigger)
		_add_trigger_quest_tracker(trigger, boiler_data["id"], false)
	
	active_boiler_quests.append(boiler_data)
	_boiler_tracker += 1
	return _boiler_tracker - 1


func is_boiler_id_free(id: String) -> bool:
	for quest in active_boiler_quests:
		if quest["id"] == id:
			return true
	return false


func boiler_quest_next_stage(quest_idx: int) -> void:
	active_boiler_quests[quest_idx]["stage"] = mini(
		active_boiler_quests[quest_idx]["stage"] + 1,
		quests_boiler[active_boiler_quests[quest_idx]["id"]]["stages"].size() - 1)


func set_boiler_quest_stage(quest_idx: int, quest_stage: int) -> void:
	var quest_key: String = active_boiler_quests[quest_idx]["id"]
	
	var clamped_stage: int = clampi(
		quest_stage,
		0,
		quests_boiler[quest_key]["stages"].size() - 1)
	
	active_boiler_quests[quest_idx]["stage"] = clamped_stage


func get_boiler_quest_stage(quest_idx: int) -> int:
	return active_boiler_quests[quest_idx]["stage"]


## Finishes a boiler quest with its' unique_id. If the quest was successful
## it'll increase the count that the quest has been finished.
func finish_boiler_quest(quest_idx: int, successful: bool) -> void:
	if successful:
		var boiler_key: String = active_boiler_quests[quest_idx]["boiler"]
		if not finished_boiler.has(boiler_key):
			finished_boiler[boiler_key] = 0
		finished_boiler[boiler_key] += 1
	
	var triggers: Array[String] = []
	
	for stage in range(get_boiler_quest_stage_count(active_boiler_quests[quest_idx]["boiler"])):
		Arrays.append_uniques(
			triggers,
			_get_boiler_quest_triggers(
				active_boiler_quests[quest_idx]["boiler"],
				stage,
				active_boiler_quests[quest_idx]["stages"]))
	
	for trigger in triggers:
		_remove_trigger_quest_tracker(
			trigger,
			active_boiler_quests[quest_idx]["id"],
			false)
		
		if _can_trigger_be_freed(trigger):
			remove_trigger(trigger)
	
	Arrays.remove_unsorted_at(active_boiler_quests, quest_idx)
	_boiler_tracker -= 1


func get_boiler_quest_completed_count(boiler_key: String) -> int:
	if finished_boiler.has(boiler_key):
		return finished_boiler[boiler_key]
	return 0


## This will generate a boiler quest with randomly selected objectives and
## return a dictionary with it which you can use on [method start_quest_boiler]
func build_quest_boiler_data(boiler_key: String, unique_id: String) -> Dictionary:
	var objectives: Array[int] = []
	
	for obj_pool in quests_boiler[boiler_key]["stages"]:
		objectives.append(
			randi_range(
				0,
				obj_pool["stage_pool"].size() - 1))
	
	return {
		"id": unique_id,
		"boiler": boiler_key,
		"title": quests_boiler[boiler_key]["title"],
		"description": quests_boiler[boiler_key]["description"],
		"stage": 0,
		"stages": objectives
		}


func is_boiler_quest_exhausted(quest_key: String) -> bool:
	return quests_boiler[quest_key] <= get_boiler_quest_completed_count(quest_key)

# --- Triggers ---

func create_trigger(trigger_id: String, set_count: int = 0) -> void:
	trigger_tracker[trigger_id] = {
		"count": maxi(0, set_count),
		"referenced": {
			"main": Array([], TYPE_STRING, &"", null), # Use exclusive by quests
			"boiler": Array([], TYPE_STRING, &"", null), # Use exclusive by quests
			"custom": Array([], TYPE_STRING, &"", null)}} # Reserved for users


func set_trigger_count(trigger_id: String, trigger_count: int) -> void:
	trigger_tracker[trigger_id]["count"] = trigger_count


## Adds a custom reference to a trigger preventing the quests module from
## removing the trigger once it's no longer used by any quest.
func add_trigger_reference(trigger_id: String, custom_reference: String) -> void:
	if not trigger_tracker[trigger_id]["referenced"]["custom"].has(custom_reference):
		trigger_tracker[trigger_id]["referenced"]["custom"].append(custom_reference)


func has_trigger_reference(trigger_id: String, custom_reference: String) -> bool:
	return trigger_tracker[trigger_id]["referenced"]["custom"].has(custom_reference)


## Removes a custom reference from a trigger. If it's no longer referenced by
## any other custom reference or by any quest the trigger will be freed from
## memory.
func remove_trigger_reference(trigger_id: String, custom_reference: String) -> void:
	var target_idx: int = trigger_tracker[trigger_id]["referenced"]["custom"].find(custom_reference)
	if target_idx != -1:
		Arrays.remove_unsorted_at(
			trigger_tracker[trigger_id]["referenced"]["custom"],
			target_idx)
		if _can_trigger_be_freed(trigger_id):
			remove_trigger(trigger_id)


func get_trigger_count(trigger_id: String) -> int:
	if trigger_tracker.has(trigger_id):
		return trigger_tracker[trigger_id]["count"]
	return 0


func remove_trigger(trigger_id: String) -> void:
	trigger_tracker.erase(trigger_id)


func has_trigger(trigger_id: String) -> bool:
	return trigger_tracker.has(trigger_id)


func get_tracked_triggers() -> PackedStringArray:
	return PackedStringArray(trigger_tracker.keys())

# --- Data Handling ---

#region Main Quests

func get_main_quests() -> PackedStringArray:
	return PackedStringArray(quests_main.keys())


func has_main_quest(quest_id: String) -> bool:
	return quests_main.has(quest_id)


func create_main_quest(quest_id: String) -> void:
	if not quests_main.has(quest_id):
		quests_main[quest_id] = {
			"title": "",
			"description": "",
			"events": {},
			"stages": Array([], TYPE_DICTIONARY, &"", null)}


func erase_main_quest(quest_id: String) -> void:
	if quests_main.has(quest_id):
		quests_main.erase(quest_id)


func get_main_quest_title(quest_id: String) -> String:
	if quests_main.has(quest_id) and quests_main[quest_id].has("title"):
		return quests_main[quest_id]["title"]
	return ""


func set_main_quest_title(quest_id: String, title: String) -> void:
	if quests_main.has(quest_id):
		quests_main[quest_id]["title"] = title


func get_main_quest_description(quest_id: String) -> String:
	if quests_main.has(quest_id) and quests_main[quest_id].has("description"):
		return quests_main[quest_id]["description"]
	return ""


func set_main_quest_description(quest_id: String, description: String) -> void:
	if quests_main.has(quest_id):
		quests_main[quest_id]["description"] = description


#region Events

func create_main_quest_event(quest_id: String, event_id: String) -> void:
	quests_main[quest_id]["events"][event_id] = {
		"items": {},
		"currency": {},
		"variables": Array([], TYPE_DICTIONARY, &"", null),
		"data": {}}


func has_main_quest_event(quest_id: String, event_id: String) -> bool:
	return quests_main[quest_id]["events"].has(event_id)


func erase_main_quest_event(quest_id: String, event_id: String) -> void:
	quests_main[quest_id]["events"].erase(event_id)


func get_main_quest_events(quest_id: String) -> PackedStringArray:
	return PackedStringArray(quests_main[quest_id]["events"].keys())


func set_main_quest_event_item(quest_id: String, event_id: String, item_id: StringName, count: int, operator: int) -> void:
	quests_main[quest_id]["events"][event_id]["items"][item_id] = {
		"count": count,
		"operator": operator}


func has_main_quest_event_item(quest_id: String, event_id: String, item_id: StringName) -> bool:
	return quests_main[quest_id]["events"][event_id]["items"].has(item_id)


func get_main_quest_event_items(quest_id: String, event_id: String) -> PackedStringArray:
	return PackedStringArray(quests_main[quest_id]["events"][event_id]["items"].keys())


func get_main_quest_event_item_count(quest_id: String, event_id: String, item_id: StringName) -> int:
	return quests_main[quest_id]["events"][event_id]["items"][item_id]["count"]


func get_main_quest_event_item_operator(quest_id: String, event_id: String, item_id: StringName) -> int:
	return quests_main[quest_id]["events"][event_id]["items"][item_id]["operator"]


func erase_main_quest_event_item(quest_id: String, event_id: String, item_id: StringName) -> void:
	return quests_main[quest_id]["events"][event_id]["items"].erase(item_id)


func set_main_quest_event_currency(quest_id: String, event_id: String, currency_id: StringName, count: int, operator: int) -> void:
	quests_main[quest_id]["events"][event_id]["currency"][currency_id] = {
		"count": count,
		"operator": operator}


func has_main_quest_event_currency(quest_id: String, event_id: String, currency_id: StringName) -> bool:
	return quests_main[quest_id]["events"][event_id]["currency"].has(currency_id)


func get_main_quest_event_currencies(quest_id: String, event_id: String) -> PackedStringArray:
	return PackedStringArray(quests_main[quest_id]["events"][event_id]["currency"].keys())


func get_main_quest_event_currency_count(quest_id: String, event_id: String, currency_id: StringName) -> int:
	return quests_main[quest_id]["events"][event_id]["currency"][currency_id]["count"]


func get_main_quest_event_currency_operator(quest_id: String, event_id: String, currency_id: StringName) -> int:
	return quests_main[quest_id]["events"][event_id]["currency"][currency_id]["operator"]


func erase_main_quest_event_currency(quest_id: String, event_id: String, currency_id: StringName) -> void:
	return quests_main[quest_id]["events"][event_id]["currency"].erase(currency_id)


func set_main_quest_event_variable(quest_id: String, event_id: String, variable_path: String, value: Variant, operator: int) -> void:
	var var_idx: int = get_main_quest_event_variable_index(quest_id, event_id, variable_path)
	
	if var_idx == -1:
		quests_main[quest_id]["events"][event_id]["variables"].append({
			"path": variable_path,
			"value": value,
			"operator": operator})
	else:
		quests_main[quest_id]["events"][event_id]["variables"][var_idx]["value"] = value
		quests_main[quest_id]["events"][event_id]["variables"][var_idx]["operator"] = operator


func get_main_quest_event_variable_index(quest_id: String, event_id: String, variable_path: String) -> int:
	var idx: int = -1
	
	for variable in quests_main[quest_id]["events"][event_id]["variables"]:
		idx += 1
		if variable["path"] == variable_path:
			return idx
	
	return -1


func get_main_quest_event_variables(quest_id: String, event_id: String) -> PackedStringArray:
	var paths := PackedStringArray()
	
	for variable in quests_main[quest_id]["events"][event_id]["variables"]:
		paths.append(variable["path"])
	
	return paths


func get_main_quest_event_variable_value(quest_id: String, event_id: String, variable_path: String) -> Variant:
	var idx: int = get_main_quest_event_variable_index(quest_id, event_id, variable_path)
	return quests_main[quest_id]["events"][event_id]["variables"][idx]["value"]


func get_main_quest_event_variable_operator(quest_id: String, event_id: String, variable_path: String) -> int:
	var idx: int = get_main_quest_event_variable_index(quest_id, event_id, variable_path)
	return quests_main[quest_id]["events"][event_id]["variables"][idx]["operator"]


func erase_main_quest_event_variable(quest_id: String, event_id: String, variable_path: StringName) -> void:
	return quests_main[quest_id]["events"][event_id]["variables"].erase(
		get_main_quest_event_variable_index(quest_id, event_id, variable_path))


func set_main_quest_event_data(quest_id: String, event_id: String, data_key: String, data: Variant) -> void:
	quests_main[quest_id]["events"][event_id]["data"][data_key] = data


func has_main_quest_event_data(quest_id: String, event_id: String, data_key: String) -> bool:
	return quests_main[quest_id]["events"][event_id]["data"].has(data_key)


func get_main_quest_event_data_keys(quest_id: String, event_id: String) -> PackedStringArray:
	return PackedStringArray(quests_main[quest_id]["events"][event_id]["data"].keys())


func get_main_quest_event_data(quest_id: String, event_id: String, data_key: String) -> Variant:
	return quests_main[quest_id]["events"][event_id]["data"][data_key]


func erase_main_quest_event_data(quest_id: String, event_id: String, data_key: String) -> void:
	quests_main[quest_id]["events"][event_id]["data"].erase(data_key)

#endregion

#region Stages

func get_main_quest_stage_count(quest_id: String) -> int:
	return quests_main[quest_id]["stages"].size()


func create_main_quest_stage(quest_id: String, stage_idx: int = -1) -> int:
	var size: int = quests_main[quest_id]["stages"].size()
	if stage_idx < 0:
		quests_main[quest_id]["stages"].append(
			{
				"title":"",
				"description": "",
				"requirements": {
					"items": {},
					"variables": Array([], TYPE_DICTIONARY, &"", null),
					"triggers": {},
					"data": {}}})
		return size
	else:
		var clamped_idx: int = Arrays.clamp_index(
			quests_main[quest_id]["stages"],
			stage_idx)
		quests_main[quest_id]["stages"].insert(clamped_idx)
		return clamped_idx


func erase_main_quest_stage(quest_id: String, stage_idx: int = -1) -> void:
	quests_main[quest_id]["stages"].remove_at(stage_idx)


func set_main_quest_stage_title(quest_id: String, stage: int, title: String) -> void:
	quests_main[quest_id]["stages"][stage]["title"] = title


func get_main_quest_stage_title(quest_id: String, stage: int) -> String:
	return quests_main[quest_id]["stages"][stage]["title"]


func set_main_quest_stage_description(quest_id: String, stage: int, description: String) -> void:
	quests_main[quest_id]["stages"][stage]["description"] = description


func get_main_quest_stage_description(quest_id: String, stage: int) -> String:
	return quests_main[quest_id]["stages"][stage]["description"]


#region Requirements

#region Items

func set_main_quest_item_requirement(quest_id: String, stage_idx: int, item_id: StringName, amount: int, operator: int) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id] = {
		"amount": amount,
		"operator": operator,
		"custom_data": {}}


func has_main_quest_item_requirement(quest_id: String, stage_idx: int, item_id: String) -> bool:
	if not quests_main.has(quest_id):
		return false

	if stage_idx < 0 or quests_main[quest_id]["stages"].size() <= stage_idx:
		return false

	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"].has(item_id)


func erase_main_quest_item_requirement(quest_id: String, stage_idx: int, item_id: String) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"].erase(item_id)


func set_main_quest_item_amount(quest_id: String, stage_idx: int, item_id: String, amount: int) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["amount"] = amount


func get_main_quest_item_amount(quest_id: String, stage_idx: int, item_id: String) -> int:
	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["amount"]


func set_main_quest_item_operator(quest_id: String, stage_idx: int, item_id: String, operator: int) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["operator"] = operator


func get_main_quest_item_operator(quest_id: String, stage_idx: int, item_id: String) -> int:
	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["operator"]

#region Custom Data

func create_main_quest_stage_item_custom_data(quest_id: String, stage_idx: int, item_id: String, data_key: String, data: Variant, operator: int) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"][data_key] = {"value": data, "operator": operator}


func set_main_quest_stage_item_custom_data(quest_id: String, stage_idx: int, item_id: String, data_key: String, data: Variant) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"][data_key]["data"] = data


func set_main_quest_stage_item_custom_data_operator(quest_id: String, stage_idx: int, item_id: String, data_key: String, operator: int) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"][data_key]["operator"] = operator


func get_main_quest_stage_item_custom_data(quest_id: String, stage_idx: int, item_id: String, data_key: String) -> Variant:
	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"][data_key]["data"]


func get_main_quest_stage_item_custom_data_operator(quest_id: String, stage_idx: int, item_id: String, data_key: String) -> Variant:
	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"][data_key]["operator"]


func has_main_quest_stage_item_custom_data(quest_id: String, stage_idx: int, item_id: String, data_key: String) -> bool:
	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"].has(data_key)


func erase_main_quest_stage_item_custom_data(quest_id: String, stage_idx: int, item_id: String, data_key: String) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"].erase(data_key)


func get_main_quest_stage_item_custom_data_keys(quest_id: String, stage_idx: int, item_id: String) -> PackedStringArray:
	return PackedStringArray(quests_main[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"].keys())

#endregion
#endregion

#region Variables

func set_main_quest_stage_variable_requirement(quest_id: String, stage_id: String, variable_path: String, value: Variant, operator: int) -> void:
	var var_idx: int = get_main_quest_stage_variable_index(quest_id, stage_id, variable_path)
	
	if var_idx == -1:
		quests_main[quest_id]["stages"][stage_id]["variables"].append({
			"path": variable_path,
			"value": value,
			"operator": operator})
	else:
		quests_main[quest_id]["events"][stage_id]["variables"][var_idx]["value"] = value
		quests_main[quest_id]["events"][stage_id]["variables"][var_idx]["operator"] = operator


func get_main_quest_stage_variable_index(quest_id: String, stage_id: String, variable_path: String) -> int:
	var idx: int = -1
	
	for variable in quests_main[quest_id]["stages"][stage_id]["variables"]:
		idx += 1
		if variable["path"] == variable_path:
			return idx
	
	return -1


func get_main_quest_stage_variable_requirements(quest_id: String, stage_id: String) -> PackedStringArray:
	var paths := PackedStringArray()
	
	for variable in quests_main[quest_id]["stages"][stage_id]["variables"]:
		paths.append(variable["path"])
	
	return paths


func get_main_quest_stage_variable_requirement_value(quest_id: String, stage_id: String, variable_path: String) -> Variant:
	var idx: int = get_main_quest_stage_variable_index(quest_id, stage_id, variable_path)
	return quests_main[quest_id]["stages"][stage_id]["variables"][idx]["value"]


func get_main_quest_stage_variable_requirement_operator(quest_id: String, stage_id: String, variable_path: String) -> int:
	var idx: int = get_main_quest_stage_variable_index(quest_id, stage_id, variable_path)
	return quests_main[quest_id]["stages"][stage_id]["variables"][idx]["operator"]


func erase_main_quest_stage_variable_requirement(quest_id: String, stage_id: String, variable_path: StringName) -> void:
	return quests_main[quest_id]["events"][stage_id]["variables"].erase(
		get_main_quest_stage_variable_index(quest_id, stage_id, variable_path))

#endregion

#region Triggers

func add_main_quest_stage_trigger_requirement(quest_id: String, stage_idx: int, trigger_id: StringName, count: int, operator: int) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["triggers"][trigger_id] = {
		"count": count,
		"operator": operator}


func has_main_quest_stage_trigger_requirement(quest_id: String, stage_idx: int, trigger_id: StringName) -> bool:
	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["triggers"].has(trigger_id)


func get_main_quest_stage_trigger_requirements(quest_id: String, stage_idx: int) -> Array[StringName]:
	return Array(
		quests_main[quest_id]["stages"][stage_idx]["requirements"]["triggers"].keys(),
		TYPE_STRING_NAME,
		&"",
		null)


func erase_main_quest_stage_trigger_requirement(quest_id: String, stage_idx: int, trigger_id: StringName) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["triggers"].erase(trigger_id)


func get_main_quest_stage_trigger_count_requirement(quest_id: String, stage_idx: int, trigger_id: StringName) -> int:
	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["triggers"][trigger_id]["count"]


func set_main_quest_stage_trigger_count_requirement(quest_id: String, stage_idx: int, trigger_id: StringName, count: int) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["triggers"][trigger_id]["count"] = count


func set_main_quest_stage_trigger_operator_requirement(quest_id: String, stage_idx: int, trigger_id: StringName, operator: int) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["triggers"][trigger_id]["operator"] = operator


func get_main_quest_stage_trigger_operator_requirement(quest_id: String, stage_idx: int, trigger_id: StringName) -> int:
	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["triggers"][trigger_id]["operator"]

#endregion

#region Custom Data

func set_main_quest_stage_data_requirement(quest_id: String, stage_idx: int, data_key: String, data: Variant) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["data"][data_key] = data


func has_main_quest_stage_data_requirement(quest_id: String, stage_idx: int, data_key: String) -> bool:
	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["data"].has(data_key)


func get_main_quest_stage_data_requirement_keys(quest_id: String, stage_idx: int, data_key: String) -> PackedStringArray:
	return PackedStringArray(quests_main[quest_id]["stages"][stage_idx]["requirements"]["data"].keys())


func get_main_quest_stage_data_requirement(quest_id: String, stage_idx: int, data_key: String) -> Variant:
	return quests_main[quest_id]["stages"][stage_idx]["requirements"]["data"][data_key]


func erase_main_quest_stage_data_requirement(quest_id: String, stage_idx: int, data_key: String) -> void:
	quests_main[quest_id]["stages"][stage_idx]["requirements"]["data"].erase(data_key)

#endregion
#endregion
#endregion
#endregion


#region Boiler Quests

func create_boiler_quest(boiler_id: String) -> void:
	quests_boiler[boiler_id] = {
		"title": "",
		"description": "",
		"completion_limit": 1,
		"events": {},
		"stages": Array([], TYPE_DICTIONARY, &"", null)}


func has_boiler_quest(boiler_id: String) -> void:
	return quests_boiler.has(boiler_id)


func get_boiler_quests() -> PackedStringArray:
	return PackedStringArray(quests_boiler.keys())


func erase_boiler_quest(boiler_id: String) -> void:
	quests_boiler.erase(boiler_id)


func set_boiler_quest_title(boiler_id: String, title: String) -> void:
	quests_boiler[boiler_id]["title"] = title


func get_boiler_quest_title(boiler_id: String) -> String:
	return quests_boiler[boiler_id]["title"]


func set_boiler_quest_description(boiler_id: String, description: String) -> void:
	quests_boiler[boiler_id]["description"] = description


func get_boiler_quest_description(boiler_id: String) -> String:
	return quests_boiler[boiler_id]["description"]


func set_boiler_quest_completion_limit(boiler_id: String, completion_limit: int) -> void:
	quests_boiler[boiler_id]["completion_limit"] = maxi(0, completion_limit)


func get_boiler_quest_completion_limit(boiler_id: String) -> int:
	return quests_boiler[boiler_id]["completion_limit"]

#region Events

func create_boiler_quest_event(quest_id: String, event_id: String) -> void:
	quests_boiler[quest_id]["events"][event_id] = {
		"items": {},
		"currency": {},
		"variables": Array([], TYPE_DICTIONARY, &"", null),
		"data": {}}


func has_boiler_quest_event(quest_id: String, event_id: String) -> bool:
	return quests_boiler[quest_id]["events"].has(event_id)


func erase_boiler_quest_event(quest_id: String, event_id: String) -> void:
	quests_boiler[quest_id]["events"].erase(event_id)


func get_boiler_quest_events(quest_id: String) -> PackedStringArray:
	return PackedStringArray(quests_boiler[quest_id]["events"].keys())


func set_boiler_quest_event_item(quest_id: String, event_id: String, item_id: StringName, count: int, operator: int) -> void:
	quests_boiler[quest_id]["events"][event_id]["items"][item_id] = {
		"count": count,
		"operator": operator}


func has_boiler_quest_event_item(quest_id: String, event_id: String, item_id: StringName) -> bool:
	return quests_boiler[quest_id]["events"][event_id]["items"].has(item_id)


func get_boiler_quest_event_items(quest_id: String, event_id: String) -> PackedStringArray:
	return PackedStringArray(quests_boiler[quest_id]["events"][event_id]["items"].keys())


func get_boiler_quest_event_item_count(quest_id: String, event_id: String, item_id: StringName) -> int:
	return quests_boiler[quest_id]["events"][event_id]["items"][item_id]["count"]


func get_boiler_quest_event_item_operator(quest_id: String, event_id: String, item_id: StringName) -> int:
	return quests_boiler[quest_id]["events"][event_id]["items"][item_id]["operator"]


func erase_boiler_quest_event_item(quest_id: String, event_id: String, item_id: StringName) -> void:
	return quests_boiler[quest_id]["events"][event_id]["items"].erase(item_id)


func set_boiler_quest_event_currency(quest_id: String, event_id: String, currency_id: StringName, count: int, operator: int) -> void:
	quests_boiler[quest_id]["events"][event_id]["currency"][currency_id] = {
		"count": count,
		"operator": operator}


func has_boiler_quest_event_currency(quest_id: String, event_id: String, currency_id: StringName) -> bool:
	return quests_boiler[quest_id]["events"][event_id]["currency"].has(currency_id)


func get_boiler_quest_event_currencies(quest_id: String, event_id: String) -> PackedStringArray:
	return PackedStringArray(quests_boiler[quest_id]["events"][event_id]["currency"].keys())


func get_boiler_quest_event_currency_count(quest_id: String, event_id: String, currency_id: StringName) -> int:
	return quests_boiler[quest_id]["events"][event_id]["currency"][currency_id]["count"]


func get_boiler_quest_event_currency_operator(quest_id: String, event_id: String, currency_id: StringName) -> int:
	return quests_boiler[quest_id]["events"][event_id]["currency"][currency_id]["operator"]


func erase_boiler_quest_event_currency(quest_id: String, event_id: String, currency_id: StringName) -> void:
	return quests_boiler[quest_id]["events"][event_id]["currency"].erase(currency_id)


func set_boiler_quest_event_variable(quest_id: String, event_id: String, variable_path: String, value: Variant, operator: int) -> void:
	var var_idx: int = get_boiler_quest_event_variable_index(quest_id, event_id, variable_path)
	
	if var_idx == -1:
		quests_boiler[quest_id]["events"][event_id]["variables"].append({
			"path": variable_path,
			"value": value,
			"operator": operator})
	else:
		quests_boiler[quest_id]["events"][event_id]["variables"][var_idx]["value"] = value
		quests_boiler[quest_id]["events"][event_id]["variables"][var_idx]["operator"] = operator


func get_boiler_quest_event_variable_index(quest_id: String, event_id: String, variable_path: String) -> int:
	var idx: int = -1
	
	for variable in quests_boiler[quest_id]["events"][event_id]["variables"]:
		idx += 1
		if variable["path"] == variable_path:
			return idx
	
	return -1


func get_boiler_quest_event_variables(quest_id: String, event_id: String) -> PackedStringArray:
	var paths := PackedStringArray()
	
	for variable in quests_boiler[quest_id]["events"][event_id]["variables"]:
		paths.append(variable["path"])
	
	return paths


func get_boiler_quest_event_variable_value(quest_id: String, event_id: String, variable_path: String) -> Variant:
	var idx: int = get_boiler_quest_event_variable_index(quest_id, event_id, variable_path)
	return quests_boiler[quest_id]["events"][event_id]["variables"][idx]["value"]


func get_boiler_quest_event_variable_operator(quest_id: String, event_id: String, variable_path: String) -> int:
	var idx: int = get_boiler_quest_event_variable_index(quest_id, event_id, variable_path)
	return quests_boiler[quest_id]["events"][event_id]["variables"][idx]["operator"]


func erase_boiler_quest_event_variable(quest_id: String, event_id: String, variable_path: StringName) -> void:
	return quests_boiler[quest_id]["events"][event_id]["variables"].erase(
		get_boiler_quest_event_variable_index(quest_id, event_id, variable_path))


func set_boiler_quest_event_data(quest_id: String, event_id: String, data_key: String, data: Variant) -> void:
	quests_boiler[quest_id]["events"][event_id]["data"][data_key] = data


func has_boiler_quest_event_data(quest_id: String, event_id: String, data_key: String) -> bool:
	return quests_boiler[quest_id]["events"][event_id]["data"].has(data_key)


func get_boiler_quest_event_data_keys(quest_id: String, event_id: String) -> PackedStringArray:
	return PackedStringArray(quests_boiler[quest_id]["events"][event_id]["data"].keys())


func get_boiler_quest_event_data(quest_id: String, event_id: String, data_key: String) -> Variant:
	return quests_boiler[quest_id]["events"][event_id]["data"][data_key]


func erase_boiler_quest_event_data(quest_id: String, event_id: String, data_key: String) -> void:
	quests_boiler[quest_id]["events"][event_id]["data"].erase(data_key)

#endregion

#region Stages

func get_boiler_quest_stage_count(quest_id: String) -> int:
	return quests_boiler[quest_id]["stages"].size()


func set_boiler_quest_stage_pool_name(quest_id: String, stage: int, new_name: String) -> void:
	quests_boiler[quest_id]["stages"][stage]["pool_name"] = new_name


func get_boiler_quest_stage_pool_name(quest_id: String, stage: int) -> String:
	return quests_boiler[quest_id]["stages"][stage]["pool_name"]


func create_boiler_quest_stage(quest_id: String, stage_idx: int = -1) -> int:
	var size: int = quests_boiler[quest_id]["stages"].size()
	
	if stage_idx < 0:
		quests_boiler[quest_id]["stages"].append(
			{
				"pool_name": "",
				"pool_items": Array([], TYPE_DICTIONARY, &"", null)
			})
		return size
	else:
		var clamped_idx: int = Arrays.clamp_index(
			quests_boiler[quest_id]["stages"],
			stage_idx)
		quests_boiler[quest_id]["stages"].insert(
			{
				"pool_name": "",
				"pool_items": Array([], TYPE_DICTIONARY, &"", null)
			},
			clamped_idx)
		return clamped_idx


func erase_boiler_quest_stage(quest_key: String, stage_id: int) -> void:
	quests_boiler[quest_key]["stages"].remove_at(stage_id)


func create_boiler_quest_stage_pool_item(quest_id: String, stage_idx: int) -> void:
	quests_boiler[quest_id]["stages"][stage_idx]["pool_items"].append(
		{
			"title":"",
			"description": "",
			"requirements": {
				"items": {},
				"variables": Array([], TYPE_DICTIONARY, &"", null),
				"triggers": {},
				"data": {}}})


func get_boiler_quest_stage_pool_size(boiler_id: String, stage: int) -> int:
	return quests_boiler[boiler_id]["stages"][stage]["pool_items"].size()


func remove_boiler_quest_stage_pool_item(boiler_id: String, stage: int, item_idx: int) -> int:
	return quests_boiler[boiler_id]["stages"][stage]["pool_items"].remove_at(item_idx)


func set_boiler_quest_pool_item_title(quest_id: String, stage: int, pool_idx: int, title: String) -> void:
	quests_boiler[quest_id]["stages"][stage]["pool_items"][pool_idx]["title"] = title


func get_boiler_quest_pool_item_title(quest_id: String, stage: int, pool_idx: int) -> String:
	return quests_boiler[quest_id]["stages"][stage]["pool_items"][pool_idx]["title"]


func set_boiler_quest_pool_item_description(quest_id: String, stage: int, pool_idx: int, description: String) -> void:
	quests_boiler[quest_id]["stages"][stage]["pool_items"][pool_idx]["description"] = description


func get_boiler_quest_pool_item_description(quest_id: String, stage: int, pool_idx: int) -> String:
	return quests_boiler[quest_id]["stages"][stage]["pool_items"][pool_idx]["description"]


#region Requirements

#region Items

func set_boiler_quest_pool_item_requirement(quest_id: String, stage_idx: int, item_id: StringName, amount: int, operator: int) -> void:
	quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id] = {
		"amount": amount,
		"operator": operator,
		"custom_data": {}}


func has_boiler_quest_pool_item_requirement(quest_id: String, stage_idx: int, item_id: String) -> bool:
	if not quests_boiler.has(quest_id):
		return false

	if stage_idx < 0 or quests_boiler[quest_id]["stages"].size() <= stage_idx:
		return false

	return quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"].has(item_id)


func erase_boiler_quest_pool_item_requirement(quest_id: String, stage_idx: int, item_id: String) -> void:
	quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"].erase(item_id)


func set_boiler_quest_pool_item_amount(quest_id: String, stage_idx: int, item_id: String, amount: int) -> void:
	quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["amount"] = amount


func get_boiler_quest_pool_item_amount(quest_id: String, stage_idx: int, item_id: String) -> int:
	return quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["amount"]


func set_boiler_quest_pool_item_operator(quest_id: String, stage_idx: int, item_id: String, operator: int) -> void:
	quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["operator"] = operator


func get_boiler_quest_pool_item_operator(quest_id: String, stage_idx: int, item_id: String) -> int:
	return quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["operator"]

#region Custom Data

func add_boiler_quest_stage_item_custom_data(quest_id: String, stage_idx: int, item_id: String, data_key: String, data: Variant, operator: int) -> void:
	quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"][data_key] = {"value": data, "operator": operator}


func set_boiler_quest_stage_item_custom_data(quest_id: String, stage_idx: int, item_id: String, data_key: String, data: Variant) -> void:
	quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"][data_key]["value"] = data


func set_boiler_quest_stage_item_custom_operator(quest_id: String, stage_idx: int, item_id: String, data_key: String, operator: int) -> void:
	quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"][data_key]["operator"] = operator


func get_boiler_quest_stage_item_custom_data(quest_id: String, stage_idx: int, item_id: String, data_key: String) -> Variant:
	return quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"][data_key]["value"]


func get_boiler_quest_stage_item_custom_operator(quest_id: String, stage_idx: int, item_id: String, data_key: String) -> int:
	return quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"][data_key]["operator"]


func has_boiler_quest_stage_item_custom_data(quest_id: String, stage_idx: int, item_id: String, data_key: String) -> bool:
	return quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"].has(data_key)


func erase_boiler_quest_stage_item_custom_data(quest_id: String, stage_idx: int, item_id: String, data_key: String) -> void:
	quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"].erase(data_key)


func get_boiler_quest_stage_item_custom_data_keys(quest_id: String, stage_idx: int, item_id: String) -> PackedStringArray:
	return PackedStringArray(quests_boiler[quest_id]["stages"][stage_idx]["requirements"]["items"][item_id]["custom_data"].keys())

#endregion
#endregion

#region Variables

func set_boiler_quest_stage_variable_requirement(quest_id: String, stage: int, pool_idx: int, variable_path: String, value: Variant, operator: int) -> void:
	var var_idx: int = get_boiler_quest_stage_variable_index(quest_id, stage, pool_idx, variable_path)
	
	if var_idx == -1:
		quests_boiler[quest_id]["stages"][stage][pool_idx]["variables"].append({
			"path": variable_path,
			"value": value,
			"operator": operator})
	else:
		quests_boiler[quest_id]["stages"][stage][pool_idx]["variables"][var_idx]["value"] = value
		quests_boiler[quest_id]["stages"][stage][pool_idx]["variables"][var_idx]["operator"] = operator


func get_boiler_quest_stage_variable_index(quest_id: String, stage: int, pool_idx: int, variable_path: String) -> int:
	var idx: int = -1
	
	for variable in quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["variables"]:
		idx += 1
		if variable["path"] == variable_path:
			return idx
	
	return -1


func get_boiler_quest_stage_required_variables(quest_id: String, stage: int, pool_idx: int) -> PackedStringArray:
	var paths := PackedStringArray()
	
	for variable in quests_boiler[quest_id]["stages"][stage][pool_idx]["variables"]:
		paths.append(variable["path"])
	
	return paths


func set_boiler_quest_stage_variable_requirement_value(quest_id: String, stage: int, pool_idx: int, variable_path: String, value: Variant) -> void:
	var idx: int = get_boiler_quest_stage_variable_index(quest_id, stage, pool_idx, variable_path)
	quests_boiler[quest_id]["stages"][stage][pool_idx]["variables"][idx]["value"] = value


func get_boiler_quest_stage_variable_requirement_value(quest_id: String, stage: int, pool_idx: int, variable_path: String) -> Variant:
	var idx: int = get_boiler_quest_stage_variable_index(quest_id, stage, pool_idx, variable_path)
	return quests_boiler[quest_id]["stages"][stage][pool_idx]["variables"][idx]["value"]


func set_boiler_quest_stage_variable_requirement_operator(quest_id: String, stage: int, pool_idx: int, variable_path: String, opertor: int) -> void:
	var idx: int = get_boiler_quest_stage_variable_index(quest_id, stage, pool_idx, variable_path)
	quests_boiler[quest_id]["stages"][stage][pool_idx]["variables"][idx]["operator"] = opertor


func get_boiler_quest_stage_variable_requirement_operator(quest_id: String, stage: int, pool_idx: int, variable_path: String) -> int:
	var idx: int = get_boiler_quest_stage_variable_index(quest_id, stage, pool_idx, variable_path)
	return quests_boiler[quest_id]["stages"][stage][pool_idx]["variables"][idx]["operator"]


func erase_boiler_quest_stage_variable_requirement(quest_id: String, stage: int, pool_idx: int, variable_path: String) -> void:
	return quests_boiler[quest_id]["stages"][stage][pool_idx]["variables"].erase(
		get_boiler_quest_stage_variable_index(quest_id, stage, pool_idx, variable_path))

#endregion

#region Triggers

func add_boiler_quest_stage_trigger_requirement(quest_id: String, stage: int, pool_idx: int, trigger_id: StringName, count: int, operator: int) -> void:
	quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["triggers"][trigger_id] = {
		"count": count,
		"operator": operator}


func has_boiler_quest_stage_trigger_requirement(quest_id: String, stage: int, pool_idx: int, trigger_id: StringName) -> bool:
	return quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["triggers"].has(trigger_id)


func get_boiler_quest_stage_trigger_requirements(quest_id: String, stage: int, pool_idx: int) -> Array[StringName]:
	return Array(
		quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["triggers"].keys(),
		TYPE_STRING_NAME,
		&"",
		null)


func erase_boiler_quest_stage_trigger_requirement(quest_id: String, stage: int, pool_idx: int, trigger_id: StringName) -> void:
	quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["triggers"].erase(trigger_id)


func get_boiler_quest_stage_trigger_count_requirement(quest_id: String, stage: int, pool_idx: int, trigger_id: StringName) -> int:
	return quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["triggers"][trigger_id]["count"]


func set_boiler_quest_stage_trigger_count_requirement(quest_id: String, stage: int, pool_idx: int, trigger_id: StringName, count: int) -> void:
	quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["triggers"][trigger_id]["count"] = count


func set_boiler_quest_stage_trigger_operator_requirement(quest_id: String, stage: int, pool_idx: int, trigger_id: StringName, operator: int) -> void:
	quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["triggers"][trigger_id]["operator"] = operator


func get_boiler_quest_stage_trigger_operator_requirement(quest_id: String, stage: int, pool_idx: int, trigger_id: StringName) -> int:
	return quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["triggers"][trigger_id]["operator"]

#endregion

#region Custom Data

func set_boiler_quest_stage_data_requirement(quest_id: String, stage: int, pool_idx: int, data_key: String, data: Variant) -> void:
	quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["data"][data_key] = data


func has_boiler_quest_stage_data_requirement(quest_id: String, stage: int, pool_idx: int, data_key: String) -> bool:
	return quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["data"].has(data_key)


func get_boiler_quest_stage_data_requirement_keys(quest_id: String, stage: int, pool_idx: int, data_key: String) -> PackedStringArray:
	return PackedStringArray(quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["data"].keys())


func get_boiler_quest_stage_data_requirement(quest_id: String, stage: int, pool_idx: int, data_key: String) -> Variant:
	return quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["data"][data_key]


func erase_boiler_quest_stage_data_requirement(quest_id: String, stage: int, pool_idx: int, data_key: String) -> void:
	quests_boiler[quest_id]["stages"][stage][pool_idx]["requirements"]["data"].erase(data_key)

#endregion
#endregion
#endregion

#endregion

# ---------------------

func save() -> void:
	ResourceSaver.save(
		self,
		ProjectSettings.get_setting(SETTINGS_PATH, "res://quests_resource.tres"))
