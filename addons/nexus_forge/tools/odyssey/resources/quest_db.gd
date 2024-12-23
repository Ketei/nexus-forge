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
				"items": [], # Array[Dict]
				"currency": [], # Array[Dict]
				"variables": [], # Array[Dict]
			},
			"quest_finished": {
				"items": [], # Array[Dict]
				"currency": [], # Array[Dict]
				"variables": [], # Array[Dict]
			},
			"quest_started": {
				"items": [], # Array[Dict]
				"currency": [], # Array[Dict]
				"variables": [], # Array[Dict]
			},
			"quest_ended": {
				"items": [], # Array[Dict]
				"currency": [], # Array[Dict]
				"variables": [], # Array[Dict]
			},
			"quest_progressed": {
				"items": [], # Array[Dict]
				"currency": [], # Array[Dict]
				"variables": [], # Array[Dict]
			},
		},
		"stages": [
			{
				"title": "",
				"description": "",
				"requirements": {
					"items": [
						{
							"item": 0,#"item_id",
							"amount": 10,
							"operator": OP_EQUAL,
							"custom_data": [{}] # Extra checks we want to make.
							}
					],
					"variables": [
						{
							"path": "stats/stamina",
							"value": 10,
							"operator": OP_GREATER_EQUAL
						}
					],
					"triggers": [
						{
							"trigger": "trigger_id",
							"count": 2,
							"operator": OP_LESS_EQUAL
						}
					],
				}
			}
		]
	}
}


var boiler_ex = { # Example, not required
	"boiler_a": {
		"title": "",
		"description": "",
		"completion_limit": 1,
		"events": {},
		"stages": [
			[
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
								"operator": OP_EQUAL}]}
				}
			]
		],
	}
}

var quest_main_tracker_example: Array[Dictionary] = [{
		"key": "kobold_egg",
		"stage": 0, # Current stage the quest is at.
		"active": false, # For quest markers, etc.
	}]

var quest_boiler_tracker_ex: Array[Dictionary] = [
	{
		"key": "given_id", # The id given to this quest by the creator
		"boiler": "boiler_a", # The key given in the dictionary
		"title": "",
		"description": "",
		"stage": 0,
		# The index references the stage the quest is at, the second is the
		# index of the item in the pool array of the boiler quests.
		# quests_boiler["stages"][this.stage][this.stages[this.stage]]
		"stages": [3,8,0],
		"active": false
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


func _add_trigger_quest_tracker(trigger_id: String, quest_id: String, is_main: bool) -> void:
	var type_key: String = "main" if is_main else "boiler"
	if not trigger_tracker[trigger_id]["referenced"][type_key].has(quest_id):
		trigger_tracker[trigger_id]["referenced"][type_key].append(quest_id)


func get_main_quest_keys() -> Array[String]:
	return Array(quests_main.keys(), TYPE_STRING, &"", null)


func get_boiler_quest_keys() -> Array[String]:
	return Array(quests_boiler.keys(), TYPE_STRING, &"", null)


func get_main_quest_stage_count(quest_key: String) -> int:
	return quests_main[quest_key]["stages"].count()


func get_main_quest_stage_data(quest_key: String, stage_idx: int) -> Dictionary:
	return quests_main[quest_key]["stages"][stage_idx]


func get_boiler_quest_stage_count(quest_key: String) -> int:
	return quests_boiler[quest_key]["stages"].count()


func get_boiler_quest_stage_pool_count(quest_key: String, stage_idx: int) -> int:
	return quests_boiler[quest_key]["stages"][stage_idx]["stage_pool"].count()


func get_boiler_quest_stage_pool_data(quest_key: String, stage_idx: int, pool_idx: int) -> Dictionary:
	return quests_main[quest_key]["stages"][stage_idx]


func get_boiler_quest_completion_limit(quest_key: String) -> int:
	return quests_boiler[quest_key]["completion_limit"]


func set_boiler_quest_completion_limit(quest_key: String, new_limit: int) -> void:
	quests_boiler[quest_key]["completion_limit"] = maxi(0, new_limit)


func get_main_stage_title(quest_key: String, objective_idx: int) -> String:
	return quests_main[quest_key]["stages"][objective_idx]["title"]


func get_boiler_stage_title(quest_key: String, stage_idx: int, pool_idx: int) -> String:
	return quests_boiler[quest_key]["stages"][stage_idx][pool_idx]["title"]


func get_main_stage_desc(quest_key: String, stage_id: int) -> String:
	return quests_main[quest_key]["stages"][stage_id]["description"]


func get_boiler_stage_desc(quest_key: String, stage_id: int, pool_idx: int) -> String:
	return quests_boiler[quest_key]["stages"][stage_id][pool_idx]["description"]


func get_main_quest_title(quest_key: String) -> String:
	return quests_main[quest_key]["title"]


func get_boiler_quest_title(quest_key: String) -> String:
	return quests_boiler[quest_key]["title"]


func get_main_quest_desc(quest_key: String) -> String:
	return quests_main[quest_key]["description"]


func get_boiler_quest_desc(quest_key: String) -> String:
	return quests_boiler[quest_key]["description"]


func finish_main_quest(quest_idx: int) -> void:
	var quest_key: int = active_main_quests[quest_idx]["key"]
	var finished_idx: int = Arrays.binary_search(finished_unique, quest_key)
	Arrays.remove_unsorted_at(active_main_quests, quest_idx)
	
	if finished_idx == -1: # If it isn't finished, add it to the finished list.
		Arrays.insert_sorted_asc(finished_unique, quest_key)
	_main_tracker -= 1


## Finishes a boiler quest with its' unique_id. If the quest was successful
## it'll increase the count that the quest has been finished.
func finish_boiler_quest(quest_idx: int, successful: bool) -> void:
	if successful:
		var boiler_key: String = active_boiler_quests[quest_idx]["boiler"]
		if not finished_boiler.has(boiler_key):
			finished_boiler[boiler_key] = 0
		finished_boiler[boiler_key] += 1
	Arrays.remove_unsorted_at(active_boiler_quests, quest_idx)
	_boiler_tracker -= 1


func get_boiler_quest_completed_count(boiler_key: String) -> int:
	if finished_boiler.has(boiler_key):
		return finished_boiler[boiler_key]
	return 0


func is_main_quest_started(quest_key: String) -> bool:
	#var quest_id: int = get_main_quest_id(quest_key)
	for quest in active_main_quests:
		if quest["quest_key"] == quest_key:
			return true
	return false


func start_quest_main(quest_key: String, stage: int = 0, set_active: bool = false) -> int:
	var required_triggers: Array[String] = []
	
	for stage_dict in quests_main[quest_key]["stages"]:
		for requirement in stage_dict["requirements"]["triggers"]:
			required_triggers.append(requirement["trigger"])
	
	for trigger in required_triggers:
		if not has_trigger(trigger):
			create_trigger(trigger)
		_add_trigger_quest_tracker(trigger, quest_key, true)
	
	active_main_quests.append({
			"key": quest_key,
			"stage": stage,
			"active": set_active
		}
	)
	_main_tracker += 1
	return _main_tracker - 1


## Starts a boiler-quest. Requires an unique_id to be differentiated from the
## rest of the quests. Check with [method is_boiler_id_free] to check if the id
## is available.
func start_quest_boiler(boiler_data: Dictionary) -> int:
	var required_triggers: Array[String] = []
	
	var current_stage: int = -1
	for pool_item in boiler_data["stages"]:
		current_stage += 1
		for requirement in quests_boiler[boiler_data["boiler"]]["stages"][current_stage][pool_item]["requirements"]["triggers"]:
			required_triggers.append(requirement["trigger"])
	
	for trigger in required_triggers:
		if not has_trigger(trigger):
			create_trigger(trigger)
		_add_trigger_quest_tracker(trigger, boiler_data["boiler"], false)
	
	active_boiler_quests.append(boiler_data)
	_boiler_tracker += 1
	return _boiler_tracker - 1


## This will generate a boiler quest with randomly selected objectives and
## return a dictionary with it which you can use on start_quest_boiler
func build_quest_boiler_data(boiler_key: String, unique_id: String) -> Dictionary:
	var objectives: Array[int] = []
	
	for obj_pool in quests_boiler[boiler_key]["stages"]:
		objectives.append(
				randi_range(
						0,
						obj_pool["stage_pool"].size() - 1))
	
	return {
		"title": quests_boiler[boiler_key]["title"],
		"description": quests_boiler[boiler_key]["description"],
		"key": unique_id,
		"boiler": boiler_key,
		"stage": 0,
		"stages": objectives,
		"active": false
		}


func set_quest_stage_main(quest_idx: int, quest_stage: int) -> void:
	var quest_key: String = active_main_quests[quest_idx]["key"]
	for quest in active_main_quests:
		if quest["key"] == quest_key:
			quest["stage"] = clampi(
					quest_stage,
					0,
					quests_main[quest_key]["stages"].size())
			break


func get_quest_stage_main(quest_idx: int) -> int:
	return active_main_quests[quest_idx]["stage"]


func get_quest_stage_boiler(quest_idx: int) -> int:
	return active_boiler_quests[quest_idx]["stage"]


func is_boiler_quest_exhausted(quest_key: String) -> bool:
	return quests_boiler[quest_key] <= get_boiler_quest_completed_count(quest_key)


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


func get_tracked_triggers() -> Array[String]:
	return Array(trigger_tracker.keys(), TYPE_STRING, &"", null)


#func set_quest_progress_item_unique(quest_id: String, item: String, value: int) -> void:
	#active["unique"][quest_id]["progress"]["items"][item] = value
#
#
#func set_quest_progress_item_boiler(quest_id: String, unique_id: String, item: String, value: int) -> void:
	#active["boiler"][quest_id][unique_id]["progress"]["items"][item] = value
#
#
#func set_quest_progress_trigger_unique(quest_id: String, trigger: String, value: int) -> void:
	#active["unique"][quest_id]["progress"]["triggers"][trigger] = value
#
#
#func set_quest_progress_trigger_boiler(quest_id: String, unique_id: String, trigger: String, value: int) -> void:
	#active["boiler"][quest_id][unique_id]["progress"]["triggers"][trigger] = value
#
#
#func get_quest_progress_item_unique(quest_id: String, item: String) -> int:
	#return active["unique"][quest_id]["progress"]["items"][item]
#
#
#func get_quest_progress_item_boiler(quest_id: String, unique_id: String, item: String) -> int:
	#return active["boiler"][quest_id][unique_id]["progress"]["items"][item]
#
#
#func get_quest_progress_trigger_unique(quest_id: String, trigger: String) -> int:
	#return active["unique"][quest_id]["progress"]["triggers"][trigger]
#
#
#func get_quest_progress_trigger_boiler(quest_id: String, unique_id: String, trigger: String) -> int:
	#return active["boiler"][quest_id][unique_id]["progress"]["triggers"][trigger]


#func sum_quest_progress_item_unique(quest_id: String, item: String, value: int) -> void:
	#var sum: int = get_quest_progress_item_unique(quest_id, item) + value
	#active["unique"][quest_id]["progress"]["items"][item] = maxi(0, sum)
#
#
#func sum_quest_progress_item_boiler(quest_id: String, unique_id: String, item: String, value: int) -> void:
	#var sum: int = get_quest_progress_item_boiler(quest_id, unique_id, item) + value
	#active["boiler"][quest_id][unique_id]["progress"]["items"][item] = maxi(0, sum)
#
#
#func sum_quest_progress_trigger_unique(quest_id: String, trigger: String, value: int) -> void:
	#var sum: int = get_quest_progress_trigger_unique(quest_id, trigger) + value
	#active["unique"][quest_id]["progress"]["triggers"][trigger] = maxi(0, sum)
#
#
#func sum_quest_progress_trigger_boiler(quest_id: String, unique_id: String, trigger: String, value: int) -> void:
	#var sum: int = get_quest_progress_trigger_boiler(quest_id, unique_id, trigger) + value
	#active["boiler"][quest_id][unique_id]["progress"]["triggers"][trigger] = maxi(0, sum)


func main_quest_stage_achieved(quest_key: String, quest_stage: int, quest_data: Dictionary = {}) -> bool:
	if not quests_main.has(quest_key):
		return false
	
	for req_item in quests_main[quest_key]["stages"][quest_stage]["requirements"]["items"]:
		for item in quest_data["items"]:
			if item["id"] != req_item["id"]:
				continue
			# We have an array full of dictionaries {id: string, op: int, value: var}
			# We need to 
			match req_item["operator"]:
				OP_EQUAL:
					if req_item["amount"] != item["amount"]:
						return false
				OP_NOT_EQUAL:
					if req_item["amount"] == item["amount"]:
						return false
				OP_LESS:
					if req_item["amount"] <= item["amount"]:
						return false
				OP_LESS_EQUAL:
					if req_item["amount"] < item["amount"]:
						return false
				OP_GREATER:
					if req_item["amount"] >= item["amount"]:
						return false
				OP_GREATER_EQUAL:
					if req_item["amount"] > item["amount"]:
						return false
				_:
					return false
			break
	
	for req_val in quests_main[quest_key]["stages"][quest_stage]["requirements"]["variables"]:
		for given_val in quest_data["variables"]:
			if req_val["path"] != given_val["path"]:
				continue
			var current_var = NexusForge.Variables.get_variable(req_val["path"])
			match req_val["operator"]:
				OP_EQUAL:
					if req_val["value"] != current_var:
						return false
				OP_NOT_EQUAL:
					if req_val["value"] == current_var:
						return false
				OP_LESS:
					if req_val["value"] <= current_var:
						return false
				OP_LESS_EQUAL:
					if req_val["value"] < current_var:
						return false
				OP_GREATER:
					if req_val["value"] >= current_var:
						return false
				OP_GREATER_EQUAL:
					if req_val["value"] > current_var:
						return false
				_:
					return false
			break
	
	for req_trigg in quests_main[quest_key]["stages"][quest_stage]["requirements"]["triggers"]:
		for given_trigger in quest_data["triggers"]:
			if req_trigg["id"] != given_trigger["id"]:
				continue
			match req_trigg["operator"]:
				OP_EQUAL:
					if req_trigg["count"] != given_trigger["count"]:
						return false
				OP_NOT_EQUAL:
					if req_trigg["count"] == given_trigger["count"]:
						return false
				OP_LESS:
					if req_trigg["count"] <= given_trigger["count"]:
						return false
				OP_LESS_EQUAL:
					if req_trigg["count"] < given_trigger["count"]:
						return false
				OP_GREATER:
					if req_trigg["count"] >= given_trigger["count"]:
						return false
				OP_GREATER_EQUAL:
					if req_trigg["count"] > given_trigger["count"]:
						return false
				_:
					return false
			break
	return true


func boiler_quest_stage_achieved(quest_key: String, quest_stage: int, objective_id: int, quest_data: Dictionary = {}) -> bool:
	if quests_boiler.has(quest_key):
		for req_item in quests_boiler[quest_key]["stages"][quest_stage]["stage_pool"][objective_id]["requirements"]["items"]:
			for item in quest_data["items"]:
				if item["id"] != req_item["id"]:
					continue
				if req_item["custom_data"] != item["custom_data"]:
					return false
				match req_item["operator"]:
					OP_EQUAL:
						if req_item["amount"] != item["amount"]:
							return false
					OP_NOT_EQUAL:
						if req_item["amount"] == item["amount"]:
							return false
					OP_LESS:
						if req_item["amount"] <= item["amount"]:
							return false
					OP_LESS_EQUAL:
						if req_item["amount"] < item["amount"]:
							return false
					OP_GREATER:
						if req_item["amount"] >= item["amount"]:
							return false
					OP_GREATER_EQUAL:
						if req_item["amount"] > item["amount"]:
							return false
					_:
						return false
				break
		for req_val in quests_boiler[quest_key]["stages"][quest_stage]["stage_pool"][objective_id]["requirements"]["variables"]:
			for given_val in quest_data["variables"]:
				if req_val["path"] != given_val["path"]:
					continue
				var current_var = NexusForge.Variables.get_variable(req_val["path"])
				match req_val["operator"]:
					OP_EQUAL:
						if req_val["value"] != current_var:
							return false
					OP_NOT_EQUAL:
						if req_val["value"] == current_var:
							return false
					OP_LESS:
						if req_val["value"] <= current_var:
							return false
					OP_LESS_EQUAL:
						if req_val["value"] < current_var:
							return false
					OP_GREATER:
						if req_val["value"] >= current_var:
							return false
					OP_GREATER_EQUAL:
						if req_val["value"] > current_var:
							return false
					_:
						return false
				break
		for req_trigg in quests_boiler[quest_key]["stages"][quest_stage]["stage_pool"][objective_id]["requirements"]["triggers"]:
			for given_trigger in quest_data["triggers"]:
				if req_trigg["id"] != given_trigger["id"]:
					continue
				match req_trigg["operator"]:
					OP_EQUAL:
						if req_trigg["count"] != given_trigger["count"]:
							return false
					OP_NOT_EQUAL:
						if req_trigg["count"] == given_trigger["count"]:
							return false
					OP_LESS:
						if req_trigg["count"] <= given_trigger["count"]:
							return false
					OP_LESS_EQUAL:
						if req_trigg["count"] < given_trigger["count"]:
							return false
					OP_GREATER:
						if req_trigg["count"] >= given_trigger["count"]:
							return false
					OP_GREATER_EQUAL:
						if req_trigg["count"] > given_trigger["count"]:
							return false
					_:
						return false
		return true
	return false


# Returns an array of items to input into *_quest_stage_achieved. Ex:
# [{"item": "peach", "amount": 12, "with_data": ["quality", "material", "juicy"]}]
# Then you need to build an array[Dict] with similar structure BUT it has
# to retain the same order as given. EX:
# [{"item": "peach", "amount": 7, "custom_data": [{"id": "quality", "value": 3}, {"id": "material", "value": "soft", "juicy": true}]}]

func get_main_quest_required_item_data(quest_id: String, stage_id: int) -> Array[Dictionary]:
	var required_items: Array[Dictionary] = []
	
	for required_item in quests_main[quest_id]["stages"][stage_id]["requirements"]["items"]:
		var custom_data_keys: Array[String] = []
		
		for custom_key in required_item["custom_data"]:
			custom_data_keys.append(custom_key["id"])
		
		required_items.append({
			"item": required_item["item"],
			"amount": required_item["amount"],
			"custom_data": custom_data_keys})
	
	return required_items


func get_boiler_quest_required_item_data(quest_id: String, stage_id: int, pool_idx: int) -> Array[Dictionary]:
	var required_items: Array[Dictionary] = []
	
	for required_item in quests_boiler[quest_id]["stages"][stage_id][pool_idx]["requirements"]["items"]:
		var custom_data_keys: Array[String] = []
		
		for custom_key in required_item["custom_data"]:
			custom_data_keys.append(custom_key["id"])
		
		required_items.append({
			"item": required_item["item"],
			"amount": required_item["amount"],
			"custom_data": custom_data_keys})
	
	return required_items

# --------------------------------------------------------------

func main_quest_next_stage(quest_idx: int) -> void:
	active_main_quests[quest_idx]["stage"] = mini(
			active_main_quests[quest_idx]["stage"] + 1,
			active_main_quests[quest_idx]["stages"].size() - 1)


func boiler_quest_next_stage(quest_idx: int) -> void:
	active_boiler_quests[quest_idx]["stage"] = mini(
			active_boiler_quests[quest_idx]["stage"] + 1,
			active_boiler_quests[quest_idx]["stage_pool"].size() - 1)


### Returns a dictionary with 3 keys: "items", "triggers" and "variables".
### This one is used for unique quests only.[br]
### Each one has a dictionary with 3 keys: "current", "required" and "operator"[br]
### Ex: {"items": {"apple": {"current": 1, "required": 3, "operator": "EQUAL_OR_MORE"}}}
#func get_quest_progress_serialized_unique(quest_id: String) -> Dictionary:
	#var serialized: Dictionary = {
		#"items": [],
		#"triggers": [],
		#"variables": []
	#}
	
	#for item in active["unique"][quest_id]["progress"]["items"]:
		#serialized["items"][item] = {
			#"exact": quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["items"][item]["exact"],
			#"current": get_quest_progress_item_unique(quest_id, item),
			#"required": quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["items"][item]["amount"],
			#"operator": operator_to_string(quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["items"][item]["match"])}
	#for trigger in active["unique"][quest_id]["progress"]["triggers"]:
		#serialized["triggers"][trigger] = {
			#"current": get_quest_progress_trigger_unique(quest_id, trigger),
			#"required": quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["triggers"][trigger]["amount"],
			#"operator": operator_to_string(quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["triggers"][trigger]["match"])}
	#for variable in quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["variables"]:
		#serialized["variables"][variable] = {
			#"current": NexusForge.Variables.get_variable(variable),
			#"required": quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["variables"][variable]["value"],
			#"operator": operator_to_string(quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["variables"][variable]["match"])}

	#return serialized


func create_main_quest(quest_key: String, title: String = "", desc: String = "") -> void:
	quests_main[quest_key] = {
		"title": title,
		"description": desc,
		"events": {},
		"stages": Array([], TYPE_DICTIONARY, &"", null)}


func create_boiler_quest(quest_key: String, completion_limit: int = 1, title: String = "", desc: String = "") -> void:
	quests_boiler[quest_key] = {
		"title": title,
		"description": desc,
		"completion_limit": maxi(0, completion_limit),
		"events": {},
		"stages": Array([], TYPE_ARRAY, &"", null)}


func get_main_quest_events(quest_key: String, event_key: String) -> Dictionary:
	if quests_main[quest_key]["events"].has(event_key):
		return quests_main[quest_key]["events"][event_key]
	return {}


func register_main_quest_event(quest_key: String, event_key: String, event_data: Dictionary) -> void:
	quests_main[quest_key]["events"][event_key] = event_data


func has_main_quest_event(quest_key: String, event_key: String) -> bool:
	return quests_main[quest_key]["events"].has(event_key)


func remove_main_quest_event(quest_key: String, event_key: String) -> void:
	quests_main[quest_key]["events"].erase(event_key)


func get_boiler_quest_events(quest_key: String, event_key: String) -> Array[Dictionary]:
	if quests_boiler[quest_key]["events"].has(event_key):
		return quests_main[quest_key]["events"][event_key]
	return Array([], TYPE_DICTIONARY, &"", null)


func has_boiler_quest_event(quest_key: String, event_key: String) -> bool:
	return quests_boiler[quest_key]["events"].has(event_key)


func register_boiler_quest_event(quest_key: String, event_key: String, event_data: Dictionary) -> void:
	quests_boiler[quest_key]["events"][event_key] = event_data


func remove_boiler_quest_event(quest_key: String, event_key: String) -> void:
	quests_boiler[quest_key]["events"].erase(event_key)


func has_main_quest(quest_key: String) -> bool:
	return quests_main.has(quest_key)


func has_boiler_quest(quest_key: String) -> bool:
	return quests_boiler.has(quest_key)


func erase_main_quest(quest_key: String) -> void:
	quests_main.erase(quest_key)


func erase_boiler_quest(quest_key: String) -> void:
	quests_boiler.erase(quest_key)


func erase_main_quest_stage(quest_key: String, stage_id: int) -> void:
	quests_main[quest_key]["stages"].remove_at(stage_id)


func erase_boiler_quest_stage(quest_key: String, stage_id: int) -> void:
	quests_boiler[quest_key]["stages"].remove_at(stage_id)


func erase_boiler_quest_pool(quest_key: String, stage_id: int, pool_id: int) -> void:
	quests_boiler[quest_key]["stages"][stage_id]["stage_pool"].remove_at(stage_id)


func set_boiler_quest_pool_min(quest_key: String, stage_id: int, pool_id: int, pool_min: int) -> void:
	quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][pool_id]["min"] = maxi(1, pool_min)
	quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][pool_id]["max"] = maxi(
			pool_min,
			quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][pool_id]["max"])


func set_boiler_quest_pool_max(quest_key: String, stage_id: int, pool_id: int, pool_max: int) -> void:
	quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][pool_id]["max"] = maxi(
		quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][pool_id]["min"],
		pool_max)


func clear_main_quest_stage_requirements(quest_key: String, stage_id: int, requirement_key: String) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"][requirement_key].clear()


func clear_main_quest_stage_requirement(quest_key: String, stage_id: int, requirement_key: String, requirement_idx: int) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"][requirement_key].remove_at(requirement_idx)


func set_main_quest_title(quest_key: String, title: String) -> void:
	quests_main[quest_key]["title"] = title


func set_boiler_quest_title(quest_key: String, title: String) -> void:
	quests_boiler[quest_key]["title"] = title


func set_main_quest_desc(quest_key: String, desc: String) -> void:
	quests_main[quest_key]["description"] = desc


func set_boiler_quest_desc(boiler_key: String, desc: String) -> void:
	quests_boiler[boiler_key]["description"] = desc


func set_main_quest_stage_desc(quest_key: String, stage_id: int, desc: String) -> void:
	quests_main[quest_key]["stages"][stage_id]["description"] = desc


func set_boiler_quest_stage_desc(boiler_key: String, stage_id: int, pool_idx: int, desc: String) -> void:
	quests_boiler[boiler_key]["stages"][stage_id][pool_idx]["description"] = desc


func set_main_quest_stage_title(quest_key: String, stage_id: int, title: String) -> void:
	quests_main[quest_key]["stages"][stage_id]["title"] = title


func set_boiler_quest_stage_title(quest_key: String, stage_id: int, pool_idx: int, title: String) -> void:
	quests_boiler[quest_key]["stages"][stage_id][pool_idx]["title"] = title


func add_main_quest_stage_item(quest_key: String, stage_id: int, item_id: String, amount: int, eval: int = OP_EQUAL, custom_data: Array[Dictionary] = []) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"]["items"].append(
			{
				"item": item_id,
				"amount": maxi(0, amount),
				"operator": eval,
				"custom_data": custom_data})


func add_boiler_quest_stage_item(boiler_key: String, stage_id: int, objective_id: int, item_id: String, amount: int, eval: int = OP_EQUAL, custom_data: Array[Dictionary] = []) -> void:
	quests_boiler[boiler_key]["stages"][stage_id]["stage_pool"][objective_id]["requirements"]["items"].append(
			{
				"item": item_id,
				"amount": maxi(0, amount),
				"operator": eval,
				"custom_data": custom_data})
	

func add_main_quest_stage_variable(quest_key: String, stage_id: int, variable_path: String, value: Variant, operator: int = OP_EQUAL) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"]["variables"].append({"path": variable_path, "value": value, "operator": operator})


func add_boiler_quest_stage_variable(quest_key: String, stage_id: int, pool_id: int, variable_path: String, value: Variant, operator: int = OP_EQUAL) -> void:
	quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][pool_id]["requirements"]["variables"].append({"path": variable_path, "value": value, "operator": operator})


func add_main_quest_stage_trigger(quest_key: String, stage_id: int, trigger_id: StringName, count: int, operator: int = OP_EQUAL) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"]["triggers"].append({"trigger": trigger_id, "count": count, "operator": operator})


func remove_main_quest_stage_item(quest_key: String, stage_id: int, item_idx: String) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"]["items"].remove_at(item_idx)


func remove_boiler_quest_stage_item(quest_key: String, stage_id: int, pool_id: int, item_idx: String) -> void:
	quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][pool_id]["requirements"]["items"].remove_at(item_idx)


func remove_main_quest_stage_variable(quest_key: String, stage_id: int, variable_idx: int) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"]["variables"].remove_at(variable_idx)


func remove_boiler_quest_stage_variable(quest_key: String, stage_id: int, stage_pool: int, variable_idx: int) -> void:
	quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][stage_id]["requirements"]["variables"].remove_at(variable_idx)


func remove_main_quest_stage_trigger(quest_key: String, stage_id: int, trigger_idx: int) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"]["triggers"].remove_at(trigger_idx)


func remove_boiler_quest_stage_trigger(quest_key: String, stage_id: int, pool_id: int, trigger_idx: int) -> void:
	quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][pool_id]["requirements"]["triggers"].remove_at(trigger_idx)


func get_main_quest_stage_requirements(quest_key: String, stage_id: int) -> Dictionary:
	return quests_main[quest_key]["stages"][stage_id]["requirements"]


func get_boiler_quest_stage_requirements(quest_key: String, stage_id: int, pool_id: int) -> Dictionary:
	return quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][pool_id]["requirements"]


func create_main_quest_stage(quest_key: String, stage_title: String = "", stage_desc: String = "", stage_id: int = -1) -> void:
	if 0 <= stage_id:
		quests_main[quest_key]["stages"].insert(
				stage_id,
				{
					"title": stage_title,
					"description": stage_desc,
					"events": {},
					"requirements": {
						"items": Array([], TYPE_DICTIONARY, &"", null),
						"variables": Array([], TYPE_DICTIONARY, &"", null),
						"triggers": Array([], TYPE_DICTIONARY, &"", null)
					}
				})
	else:
		quests_main[quest_key]["stages"].append(
				{
					"title": stage_title,
					"description": stage_desc,
					"events": {},
					"requirements": {
						"items": Array([], TYPE_DICTIONARY, &"", null),
						"variables": Array([], TYPE_DICTIONARY, &"", null),
						"triggers": Array([], TYPE_DICTIONARY, &"", null)
					}
				})


func create_boiler_quest_stage_pool(quest_key: String, stage_id: int = -1) -> void:
	if 0 <= stage_id:
		quests_boiler[quest_key]["stages"].insert(
				stage_id,
				Array([], TYPE_DICTIONARY, &"", null)
				)
	else:
		quests_boiler[quest_key]["stages"].append(
				Array([], TYPE_DICTIONARY, &"", null)
				)


func create_boiler_quest_pool_stage(quest_key: String, stage_id: int, stage_title: String = "", stage_desc: String = "", pool_id: int = -1) -> void:
	if 0 <= pool_id:
		quests_boiler[quest_key]["stages"][stage_id].insert(
				pool_id,
				{
					"title": stage_title,
					"description": stage_desc,
					"events": {},
					"requirements": {
						"items": Array([], TYPE_DICTIONARY, &"", null),
						"variables": Array([], TYPE_DICTIONARY, &"", null),
						"triggers": Array([], TYPE_DICTIONARY, &"", null)
					}
				})
	else:
		quests_boiler[quest_key]["stages"][stage_id].append(
				{
					"title": stage_title,
					"description": stage_desc,
					"events": {},
					"requirements": {
						"items": Array([], TYPE_DICTIONARY, &"", null),
						"variables": Array([], TYPE_DICTIONARY, &"", null),
						"triggers": Array([], TYPE_DICTIONARY, &"", null)
					}
				})


func save() -> void:
	ResourceSaver.save(
			self,
			ProjectSettings.get_setting(SETTINGS_PATH, "res://quests_resource.tres")
			)
