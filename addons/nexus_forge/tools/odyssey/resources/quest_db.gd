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
							"custom_data": {} # Extra checks we want to make.
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
							"id": &"trigger_id",
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
		"max_completions": 1,
		"stages": [
			{ # Will grab 1 to 5 objectives randomly for a quest.
				"min": 1,
				"max": 5,
				"stage_pool":[
					{
						"title": "",
						"description": "",
						"requirements": {
							"items": [
								{
									"item_id": "",
									"amount": 10,
									"operator": OP_GREATER_EQUAL,
									"custom_data": {},
								}],
							"variables": [
								{
									"path": "stats/stamina",
									"value": 10,
									"operator": OP_GREATER_EQUAL
								}],
							"triggers": [
								{
									"id": &"trigger_id",
									"count": 0,
									"operator": OP_EQUAL}]}}
				]
			},
			{# Will grab 1 random objective from objectives
				"min": 1,
				"max": 1,
				"stage_pool": [
					{
						"title": "",
						"description": "",
						"items": [],
						"variables": [],
						"triggers": []
					},
					{
						"title": "",
						"description": "",
						"items": [],
						"variables": [],
						"triggers": []
					},
				]
			}
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
		"stages": [[0,3,5],[1,8],[0]],
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
	"trigger_id": 16
}
## Has all the active quests.
var active_main_quests: Array[Dictionary] = []
var active_boiler_quests: Array[Dictionary] = []

# Used so that we arent counting the array every time.
var _main_tracker: int = 0 # How many active main quests there are.
var _boiler_tracker: int = 0 # How many active bolier quests there are



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


func get_boiler_quest_stage_min(quest_key: String, stage_idx: int) -> int:
	return quests_boiler[quest_key]["stages"][stage_idx]["min"]


func get_boiler_quest_stage_max(quest_key: String, stage_idx: int) -> int:
	return quests_boiler[quest_key]["stages"][stage_idx]["max"]


func get_main_stage_title(quest_key: String, objective_idx: int) -> String:
	return quests_main[quest_key]["stages"][objective_idx]["title"]


func get_main_stage_desc(quest_key: String, objective_idx: String) -> String:
	return quests_main[quest_key]["stages"][objective_idx]["description"]


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
	active_main_quests.append(
		{
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
	active_boiler_quests.append(boiler_data)
	_boiler_tracker += 1
	return _boiler_tracker - 1


## This will generate a boiler quest with randomly selected objectives and
## return a dictionary with it which you can use on start_quest_boiler
func build_quest_boiler_data(boiler_key: String, unique_id: String) -> Dictionary:
	var objectives: Array[Array] = []
	
	for obj_pool in quests_boiler[boiler_key]["stages"]:
		var possible_idx: Array = range(obj_pool["stage_pool"].size())
		var new_obj: Array[int] = []
		for _count in range(randi_range(obj_pool["min"], obj_pool["max"])):
			if possible_idx.is_empty():
				break
			new_obj.append(Arrays.pop_random(possible_idx))
		objectives.append(new_obj)
	
	return {
		"title": quests_boiler[boiler_key]["title"],
		"description": quests_boiler[boiler_key]["description"],
		"key": unique_id,
		"boiler": boiler_key,
		"stage": 0,
		"stages": objectives,
		"active": false}


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


func set_trigger(trigger_id: StringName, set_count: int = 0) -> void:
	trigger_tracker[trigger_id] = maxi(0, set_count)


func get_trigger_count(trigger_id: StringName) -> int:
	if trigger_tracker.has(trigger_id):
		return trigger_tracker[trigger_id]
	return 0


func remove_trigger(trigger_id: StringName) -> void:
	trigger_tracker.erase(trigger_id)


func has_trigger(trigger_id: StringName) -> bool:
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
		"stages": Array([], TYPE_DICTIONARY, &"", null)}


func create_boiler_quest(quest_key: String, max_completions: int = 1, title: String = "", desc: String = "") -> void:
	quests_boiler[quest_key] = {
		"title": title,
		"description": desc,
		"max_completions": maxi(1, max_completions),
		"stages": Array([], TYPE_DICTIONARY, &"", null)}


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


func set_main_quest_stage_desc(quest_key: String, quest_stage: String, desc: String) -> void:
	quests_main[quest_key]["stages"][quest_stage]["description"] = desc


func set_boiler_quest_stage_desc(boiler_key: String, quest_stage: String, objective_id: int, desc: String) -> void:
	quests_boiler[boiler_key]["stages"][quest_stage]["stage_pool"][objective_id]["description"] = desc


func set_main_quest_stage_title(quest_key: String, stage_id: int, title: String) -> void:
	quests_main[quest_key]["stages"][stage_id]["title"] = title


func set_boiler_quest_stage_title(quest_key: String, stage_id: int, objective_id: int, title: String) -> void:
	quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][objective_id]["title"] = title


func add_main_quest_stage_item(quest_key: String, stage_id: int, item_id: String, amount: int, eval: int = OP_EQUAL, custom_data: Dictionary = {}) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"]["items"].append(
			{
				"id": item_id,
				"amount": maxi(0, amount),
				"operator": eval,
				"custom_data": custom_data})


func add_boiler_quest_stage_item(boiler_key: String, stage_id: int, objective_id: int, item_id: String, amount: int, eval: int = OP_EQUAL, custom_data: Dictionary = {}) -> void:
	quests_boiler[boiler_key]["stages"][stage_id]["stage_pool"][objective_id]["requirements"]["items"].append(
			{
				"id": item_id,
				"amount": maxi(0, amount),
				"operator": eval,
				"custom_data": custom_data})
	

func add_main_quest_stage_variable(quest_key: String, stage_id: int, variable_path: String, value: Variant, operator: int = OP_EQUAL) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"]["variables"].append({"path": variable_path, "value": value, "operator": operator})


func add_boiler_quest_stage_variable(quest_key: String, stage_id: int, pool_id: int, variable_path: String, value: Variant, operator: int = OP_EQUAL) -> void:
	quests_boiler[quest_key]["stages"][stage_id]["stage_pool"][pool_id]["requirements"]["variables"].append({"path": variable_path, "value": value, "operator": operator})


func add_main_quest_stage_trigger(quest_key: String, stage_id: int, trigger_id: StringName, count: int, operator: int = OP_EQUAL) -> void:
	quests_main[quest_key]["stages"][stage_id]["requirements"]["triggers"].append({"id": trigger_id, "count": count, "operator": operator})


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
					"requirements": {
						"items": Array([], TYPE_DICTIONARY, &"", null),
						"variables": Array([], TYPE_DICTIONARY, &"", null),
						"triggers": Array([], TYPE_DICTIONARY, &"", null)
					}
				})


func create_boiler_quest_stage_pool(quest_key: String, pool_min: int, pool_max: int, stage_id: int = -1) -> void:
	if 0 <= stage_id:
		quests_boiler[quest_key]["stages"].insert(
				stage_id,
				{
					"min": maxi(1, pool_min),
					"max": maxi(pool_min, pool_max),
					"stage_pool": Array([], TYPE_DICTIONARY, &"", null)
				})
	else:
		quests_boiler[quest_key]["stages"].append(
				{
					"min": maxi(1, pool_min),
					"max": maxi(pool_min, pool_max),
					"stage_pool": Array([], TYPE_DICTIONARY, &"", null)
				})


func add_boiler_quest_stage(quest_key: String, stage_id: int, stage_title: String = "", stage_desc: String = "", pool_id: int = -1) -> void:
	if 0 <= pool_id:
		quests_boiler[quest_key]["stages"][stage_id].insert(
				pool_id,
				{
					"title": stage_title,
					"description": stage_desc,
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
