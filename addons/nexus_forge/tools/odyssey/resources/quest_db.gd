@tool
class_name NFQuestRes
extends Resource


signal unique_quest_finished(quest_id: String)
signal boiler_quest_finished(quest_id: String, unique_id: String)

enum OperatorFlags {
	EQUAL = 1,
	NOT = 2,
	LESS_THAN = 4,
	MORE_THAN = 8,
	EQUAL_OR_LESS = 5,
	EQUAL_OR_MORE = 9,
	}

const SETTINGS_PATH: String = "nexus_forge/quests_resource"

## Holds the boiler quests.
@export var quests_boiler: Dictionary = {}

var boiler_ex = {
	"quest_id": {
		"title": "",
		"desc": "",
		"order": ["0", "1"],
		"objectives":{
			"0": {
				"title": "",
				"desc": "",
				"items": {
					"crystal": {
						# If exact, it assumes item id, else item flag.
						"exact": false,
						"amount": 5,
						"match": OperatorFlags.EQUAL_OR_MORE
						}
				}
			}
		}
	}
}



## Holds all unique quests.
@export var quests_unique: Dictionary = {
	#"kobold_egg": {
		#"title": "Some large eggs",
		#"desc": "Why not get some eggies?",
		#"order": ["impreg", "lay", "incubate"],
		#"objectives":{ 
			#"impreg": {
				#"title": "atitle",
				#"desc": "Impregnate a kobold.",
				#"items": {"cum": {"exact": true, "amount": 10, "match": OperatorFlags.EQUAL_OR_MORE}},
				#"variables": {"owned": {"value": 1, "match": OperatorFlags.EQUAL_OR_MORE}},
				#"triggers": {"slept": {"amount": 5, "match": OperatorFlags.EQUAL}}
			#}
		#}
	#}
}
## Has all the finished quests
var finished_unique: Array = []
var finished_boiler: Dictionary = {}
## Has all the active quests.
var active: Dictionary = {
	"unique": {},
	"boiler": {}
}


func get_quests(get_main: bool) -> Array:
	if get_main:
		return quests_unique.keys()
	else:
		return quests_boiler.keys()


func _get_boiler_quest_dict(id: String, stage: int = 0) -> Dictionary:
	var quest_data: Dictionary = {
		"stage": stage,
		"stage_id": quests_boiler[id]["order"][stage]
	}
	#quest_data["id"] = id
	return quest_data


func get_objective_title(quest: String, objective: String) -> String:
	return quests_unique[quest]["objectives"][objective]["title"]


func get_objective_desc(quest: String, objective: String) -> String:
	return quests_unique[quest]["objectives"][objective]["desc"]


func get_quest_title(quest_id: String, on_unique: bool) -> String:
	if on_unique:
		return quests_unique[quest_id]["title"]
	else:
		return quests_boiler[quest_id]["title"]


func get_quest_desc(quest_id: String, on_unique: bool) -> String:
	if on_unique:
		return quests_unique[quest_id]["desc"]
	else:
		return quests_boiler[quest_id]["desc"]


func _build_progress_dict(quest: String, objective: String, is_boiler: bool = false) -> Dictionary:
	var progress_dict: Dictionary = {
		"items": {},
		"triggers": {}}
	
	var target: Dictionary = quests_boiler[quest][objective] if is_boiler else quests_unique[quest][objective]

	for item in target["items"]:
		progress_dict["items"][item] = 0
	for trigger in target["triggers"]:
		progress_dict["triggers"][trigger] = 0

	return progress_dict


func operator_to_string(operator_enum: OperatorFlags) -> String:
	return OperatorFlags.keys()[operator_enum]


func finish_unique_quest(quest_id: String) -> void:
	if active["unique"].has(quest_id): # If the quest is in active, remove it
		active["unique"].erase(quest_id)
	# Search if the quest is finished
	var finished_idx: int = Arrays.binary_search(finished_unique, quest_id)
	if finished_idx == -1: # If it isn't finished, add it to the finished list.
		Arrays.insert_sorted_asc(finished_unique, quest_id)
		#finished.append(quest_id)
		#finished.sort()


## Finishes a boiler quest with its' unique_id. If the quest was successful
## it'll increase the count that the quest has been finished.
func finish_boiler_quest(quest: String, unique_id: String, successful: bool) -> void:
	if active["boiler"][quest].has(unique_id): # If the quest is in active, remove it
		active["boiler"][quest].erase(unique_id)
		if successful:
			if not finished_boiler.has(quest):
				finished_boiler[quest] = {}
			if not finished_boiler[quest].has(unique_id):
				finished_boiler[quest][unique_id] = 0
			finished_boiler[quest][unique_id] += 1


func get_boiler_quest_completed_amount(quest: String, unique_id: String) -> int:
	if finished_boiler.has(quest) and finished_boiler[quest].has(unique_id):
		return finished_boiler[quest][unique_id]
	return 0


func get_objective_id(quest: String, objective_idx: int, unique: bool) -> String:
	var target_dict: Dictionary = quests_unique if unique else quests_boiler 
	if target_dict.has(quest):
		if maxi(0, objective_idx) <= target_dict[quest]["order"].size() - 1:
			return target_dict[quest]["order"][objective_idx]
	return ""


func start_quest_unique(quest_id: String) -> void:
	if active.has(quest_id):
		return
	var finished_idx: int = Arrays.binary_search(finished_unique, quest_id)
	if finished_idx != -1:
		finished_unique.remove_at(finished_idx)
	active["unique"][quest_id] = {
		"stage_id": get_objective_id(quest_id, 0, true),
		"stage": 0,
		"progress": _build_progress_dict(quest_id, get_objective_id(quest_id, 0, true))}


## Starts a boiler-quest. Requires an unique_id to be differentiated from the
## rest of the quests. Check with [method is_boiler_id_free] to check if the id
## is available.
func start_quest_boiler(boiler_id: String, unique_id: String) -> void:
	if not active["boiler"].has(boiler_id):
		active["boiler"][boiler_id] = {}
	active["boiler"][boiler_id][unique_id] = {
		"stage_id": get_objective_id(boiler_id, 0, false),
		"stage": 0,
		"progress": _build_progress_dict(
				boiler_id,
				get_objective_id(boiler_id, 0, false),
				true)}


func is_boiler_id_free(boiler_id: String, id_to_check: String) -> bool:
	if active["boiler"].has(boiler_id):
		return !active["boiler"][boiler_id].has(id_to_check)
	return true


func set_active_stage(quest_id: String, quest_stage: int, unique: bool) -> void:
	var quest_size: int = quests_unique[quest_id]["order"].size() if unique else quests_boiler[quest_id]["order"].size()
	quest_size -= 1
	var valid_progress: int = clampi(quest_stage, -1, quest_size)
	var active_key: String = "unique" if unique else "boiler"
	
	if valid_progress < 0:
		return
	
	active[active_key][quest_id] = {
		"stage_id": get_objective_id(quest_id, valid_progress, unique),
		"stage": valid_progress,
		"progress": _build_progress_dict(quest_id, get_objective_id(quest_id, valid_progress, unique))}


func get_active_stage(quest_id: String) -> int:
	return active["unique"][quest_id]["stage"]


func get_active_stage_boiler(quest_id: String, unique_id: String) -> int:
	return active["boiler"][quest_id][unique_id]["stage"]


func set_quest_progress_item_unique(quest_id: String, item: String, value: int) -> void:
	active["unique"][quest_id]["progress"]["items"][item] = value


func set_quest_progress_item_boiler(quest_id: String, unique_id: String, item: String, value: int) -> void:
	active["boiler"][quest_id][unique_id]["progress"]["items"][item] = value


func set_quest_progress_trigger_unique(quest_id: String, trigger: String, value: int) -> void:
	active["unique"][quest_id]["progress"]["triggers"][trigger] = value


func set_quest_progress_trigger_boiler(quest_id: String, unique_id: String, trigger: String, value: int) -> void:
	active["boiler"][quest_id][unique_id]["progress"]["triggers"][trigger] = value


func get_quest_progress_item_unique(quest_id: String, item: String) -> int:
	return active["unique"][quest_id]["progress"]["items"][item]


func get_quest_progress_item_boiler(quest_id: String, unique_id: String, item: String) -> int:
	return active["boiler"][quest_id][unique_id]["progress"]["items"][item]


func get_quest_progress_trigger_unique(quest_id: String, trigger: String) -> int:
	return active["unique"][quest_id]["progress"]["triggers"][trigger]


func get_quest_progress_trigger_boiler(quest_id: String, unique_id: String, trigger: String) -> int:
	return active["boiler"][quest_id][unique_id]["progress"]["triggers"][trigger]


func sum_quest_progress_item_unique(quest_id: String, item: String, value: int) -> void:
	var sum: int = get_quest_progress_item_unique(quest_id, item) + value
	active["unique"][quest_id]["progress"]["items"][item] = maxi(0, sum)


func sum_quest_progress_item_boiler(quest_id: String, unique_id: String, item: String, value: int) -> void:
	var sum: int = get_quest_progress_item_boiler(quest_id, unique_id, item) + value
	active["boiler"][quest_id][unique_id]["progress"]["items"][item] = maxi(0, sum)


func sum_quest_progress_trigger_unique(quest_id: String, trigger: String, value: int) -> void:
	var sum: int = get_quest_progress_trigger_unique(quest_id, trigger) + value
	active["unique"][quest_id]["progress"]["triggers"][trigger] = maxi(0, sum)


func sum_quest_progress_trigger_boiler(quest_id: String, unique_id: String, trigger: String, value: int) -> void:
	var sum: int = get_quest_progress_trigger_boiler(quest_id, unique_id, trigger) + value
	active["boiler"][quest_id][unique_id]["progress"]["triggers"][trigger] = maxi(0, sum)


## Will return true if the quest tracker has all the items, triggers and variables
## required to a valid value. Returns false if not.
func is_objective_fullfilled_unique(quest: String) -> bool:
	for item in active[quest]["items"]:
		match quests_unique[quest][active[quest]["stage_id"]]["items"][item]["match"]:
			OperatorFlags.EQUAL:
				if get_quest_progress_item_unique(quest, item) != quests_unique[quest][active[quest]["stage_id"]]["items"][item]["amount"]:
					return false
			OperatorFlags.NOT:
				if get_quest_progress_item_unique(quest, item) == quests_unique[quest][active[quest]["stage_id"]]["items"][item]["amount"]:
					return false
			OperatorFlags.LESS_THAN:
				if get_quest_progress_item_unique(quest, item) >= quests_unique[quest][active[quest]["stage_id"]]["items"][item]["amount"]:
					return false
			OperatorFlags.MORE_THAN:
				if get_quest_progress_item_unique(quest, item) <= quests_unique[quest][active[quest]["stage_id"]]["items"][item]["amount"]:
					return false
			OperatorFlags.EQUAL_OR_LESS:
				if get_quest_progress_item_unique(quest, item) > quests_unique[quest][active[quest]["stage_id"]]["items"][item]["amount"]:
					return false
			OperatorFlags.EQUAL_OR_MORE:
				if get_quest_progress_item_unique(quest, item) < quests_unique[quest][active[quest]["stage_id"]]["items"][item]["amount"]:
					return false
	for trigger in active[quest]["triggers"]:
		match quests_unique[quest][active[quest]["stage_id"]]["triggers"][trigger]["match"]:
			OperatorFlags.EQUAL:
				if get_quest_progress_trigger_unique(quest, trigger) != quests_unique[quest][active[quest]["stage_id"]]["triggers"][trigger]["amount"]:
					return false
			OperatorFlags.NOT:
				if get_quest_progress_trigger_unique(quest, trigger) == quests_unique[quest][active[quest]["stage_id"]]["triggers"][trigger]["amount"]:
					return false
			OperatorFlags.LESS_THAN:
				if get_quest_progress_trigger_unique(quest, trigger) >= quests_unique[quest][active[quest]["stage_id"]]["triggers"][trigger]["amount"]:
					return false
			OperatorFlags.MORE_THAN:
				if get_quest_progress_trigger_unique(quest, trigger) <= quests_unique[quest][active[quest]["stage_id"]]["triggers"][trigger]["amount"]:
					return false
			OperatorFlags.EQUAL_OR_LESS:
				if get_quest_progress_trigger_unique(quest, trigger) > quests_unique[quest][active[quest]["stage_id"]]["triggers"][trigger]["amount"]:
					return false
			OperatorFlags.EQUAL_OR_MORE:
				if get_quest_progress_trigger_unique(quest, trigger) < quests_unique[quest][active[quest]["stage_id"]]["triggers"][trigger]["amount"]:
					return false
	for variable in quests_unique[quest][active[quest]["stage_id"]]["variables"]:
		match quests_unique[quest][active[quest]["stage_id"]]["variables"][variable]["match"]:
			OperatorFlags.EQUAL:
				if NexusForge.Variables.get_variable(variable) != quests_unique[quest][active[quest]["stage_id"]]["variables"][variable]["value"]:
					return false
			OperatorFlags.NOT:
				if NexusForge.Variables.get_variable(variable) == quests_unique[quest][active[quest]["stage_id"]]["variables"][variable]["value"]:
					return false
			OperatorFlags.LESS_THAN:
				if NexusForge.Variables.get_variable(variable) >= quests_unique[quest][active[quest]["stage_id"]]["variables"][variable]["value"]:
					return false
			OperatorFlags.MORE_THAN:
				if NexusForge.Variables.get_variable(variable) <= quests_unique[quest][active[quest]["stage_id"]]["variables"][variable]["value"]:
					return false
			OperatorFlags.EQUAL_OR_LESS:
				if NexusForge.Variables.get_variable(variable) > quests_unique[quest][active[quest]["stage_id"]]["variables"][variable]["value"]:
					return false
			OperatorFlags.EQUAL_OR_MORE:
				if NexusForge.Variables.get_variable(variable) < quests_unique[quest][active[quest]["stage_id"]]["variables"][variable]["value"]:
					return false
	return true


func is_quest_active(quest: String) -> bool:
	return active.has(quest)


func progress_quest_unique(quest: String) -> void:
	if active["unique"][quest]["stage"] + 1 < quests_unique[quest]["order"].size():
		active["unique"][quest]["stage"] += 1
		active["unique"][quest]["stage_id"] = get_objective_id(quest, active[quest]["stage"], true)
	else:
		unique_quest_finished.emit(quest)


func progress_quest_boiler(quest: String, unique_id: String) -> void:
	if active["boiler"][quest][unique_id]["stage"] + 1 < quests_unique[quest]["order"].size():
		active["boiler"][quest][unique_id]["stage"] += 1
		active["boiler"][quest][unique_id]["stage_id"] = get_objective_id(quest, active[quest]["stage"], false)
	else:
		boiler_quest_finished.emit(quest, unique_id)


## Returns a dictionary with 3 keys: "items", "triggers" and "variables".
## This one is used for unique quests only.[br]
## Each one has a dictionary with 3 keys: "current", "required" and "operator"[br]
## Ex: {"items": {"apple": {"current": 1, "required": 3, "operator": "EQUAL_OR_MORE"}}}
func get_quest_progress_serialized_unique(quest_id: String) -> Dictionary:
	var serialized: Dictionary = {
		"items": {},
		"triggers": {},
		"variables": {}
	}
	
	for item in active["unique"][quest_id]["progress"]["items"]:
		serialized["items"][item] = {
			"exact": quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["items"][item]["exact"],
			"current": get_quest_progress_item_unique(quest_id, item),
			"required": quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["items"][item]["amount"],
			"operator": operator_to_string(quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["items"][item]["match"])}
	for trigger in active["unique"][quest_id]["progress"]["triggers"]:
		serialized["triggers"][trigger] = {
			"current": get_quest_progress_trigger_unique(quest_id, trigger),
			"required": quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["triggers"][trigger]["amount"],
			"operator": operator_to_string(quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["triggers"][trigger]["match"])}
	for variable in quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["variables"]:
		serialized["variables"][variable] = {
			"current": NexusForge.Variables.get_variable(variable),
			"required": quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["variables"][variable]["value"],
			"operator": operator_to_string(quests_unique[quest_id][active["unique"][quest_id]["stage_id"]]["variables"][variable]["match"])}

	return serialized


## Returns a dictionary with 3 keys: "items", "triggers" and "variables".
## This one is used for unique quests only.[br]
## Each one has a dictionary with 3 keys: "current", "required" and "operator"[br]
## Ex: {"items": {"apple": {"current": 1, "required": 3, "operator": "EQUAL_OR_MORE"}}}
func get_quest_progress_serialized_boiler(quest_id: String, unique_id: String) -> Dictionary:
	var serialized: Dictionary = {
		"items": {},
		"triggers": {},
		"variables": {}
	}
	
	for item in active["boiler"][quest_id][unique_id]["progress"]["items"]:
		serialized["items"][item] = {
			"exact": quests_unique[quest_id][active["boiler"][quest_id][unique_id]["stage_id"]]["items"][item]["exact"],
			"current": get_quest_progress_item_boiler(quest_id, unique_id, item),
			"required": quests_unique[quest_id][active["boiler"][quest_id][unique_id]["stage_id"]]["items"][item]["amount"],
			"operator": operator_to_string(quests_unique[quest_id][active["boiler"][quest_id][unique_id]["stage_id"]]["items"][item]["match"])}
	for trigger in active["boiler"][quest_id][unique_id]["progress"]["triggers"]:
		serialized["triggers"][trigger] = {
			"current": get_quest_progress_trigger_boiler(quest_id, unique_id, trigger),
			"required": quests_unique[quest_id][active["boiler"][quest_id][unique_id]["stage_id"]]["triggers"][trigger]["amount"],
			"operator": operator_to_string(quests_unique[quest_id][active["boiler"][quest_id][unique_id]["stage_id"]]["triggers"][trigger]["match"])}
	for variable in quests_unique[quest_id][active["boiler"][quest_id][unique_id]["stage_id"]]["variables"]:
		serialized["variables"][variable] = {
			"current": NexusForge.Variables.get_variable(variable),
			"required": quests_unique[quest_id][active["boiler"][quest_id][unique_id]["stage_id"]]["variables"][variable]["value"],
			"operator": operator_to_string(quests_unique[quest_id][active["boiler"][quest_id][unique_id]["stage_id"]]["variables"][variable]["match"])}

	return serialized


func create_quest(quest_id: String, is_unique: bool, title: String = "", desc: String = "") -> void:
	if is_unique:	
		quests_unique[quest_id] = {
			"title": title,
			"desc": desc,
			"order": [],
			"objectives": {}}
	else:
		quests_boiler[quest_id] = {
			"title": title,
			"desc": desc,
			"order": [],
			"objectives": {}}


func get_quest_objectives(quest_id: String, is_unique: bool) -> Array:
	if is_unique:
		return quests_unique[quest_id]["order"].duplicate()
	else:
		return quests_boiler[quest_id]["order"].duplicate()


func has_quest(quest_id: String, unique: bool) -> bool:
	if unique:
		return quests_unique.has(quest_id)
	else:
		return quests_boiler.has(quest_id)


func has_quest_objective(quest_id: String, objective: String, on_unique: bool) -> bool:
	if on_unique:
		return quests_unique.has(quest_id) and quests_unique[quest_id]["objectives"].has(objective)
	else:
		return quests_boiler.has(quest_id) and quests_boiler[quest_id]["objectives"].has(objective)


func erase_quest(quest_id: String, is_unique: bool) -> void:
	if is_unique:
		quests_unique.erase(quest_id)
	else:
		quests_boiler.erase(quest_id)


func erase_objective(quest_id: String, objective: String, on_unique: bool) -> void:
	if on_unique:
		if quests_unique[quest_id]["objectives"].erase(objective):
			quests_unique[quest_id]["order"].erase(objective)
	else:
		if quests_boiler[quest_id]["objectives"].erase(objective):
			quests_boiler[quest_id]["order"].erase(objective)


func clear_all_quests() -> void:
	clear_unique_quests()
	clear_boiler_quests()


func clear_unique_quests() -> void:
	quests_unique.clear()


func clear_boiler_quests() -> void:
	quests_boiler.clear()


func clear_quest_objectives(quest_id: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest_id]["order"].clear()
		quests_unique[quest_id]["objectives"].clear()
	else:
		quests_boiler[quest_id]["order"].clear()
		quests_boiler[quest_id]["objectives"].clear()


func clear_objective_items(quest: String, objective: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["items"].clear()
	else:
		quests_boiler[quest]["objectives"][objective]["items"].clear()


func clear_objective_variables(quest: String, objective: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["variables"].clear()
	else:
		quests_boiler[quest]["objectives"][objective]["variables"].clear()


func clear_objective_triggers(quest: String, objective: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["triggers"].clear()
	else:
		quests_boiler[quest]["objectives"][objective]["triggers"].clear()


func clear_objective_requirements(quest: String, objective: String, on_unique: bool) -> void:
	clear_objective_items(quest, objective, on_unique)
	clear_objective_variables(quest, objective, on_unique)
	clear_objective_triggers(quest, objective, on_unique)


func set_quest_title(quest_id: String, title: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest_id]["title"] = title
	else:
		quests_boiler[quest_id]["title"] = title


func set_quest_desc(quest_id: String, desc: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest_id]["desc"] = desc
	else:
		quests_boiler[quest_id]["desc"] = desc


func set_quest_objective_desc(quest: String, objective: String, desc: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["desc"] = desc
	else:
		quests_boiler[quest]["objectives"][objective]["desc"] = desc


func set_quest_objective_title(quest: String, objective: String, title: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["title"] = title
	else:
		quests_boiler[quest]["objectives"][objective]["title"] = title


func add_objective_item(quest: String, objective: String, on_unique: bool, item: String, exact: bool, amount: int, eval := OperatorFlags.EQUAL) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["items"][item] = {"exact": exact, "amount": maxi(0, amount), "match": eval}
	else:
		quests_boiler[quest]["objectives"][objective]["items"][item] = {"exact": exact, "amount": maxi(0, amount), "match": eval}


func add_objective_variable(quest: String, objective: String, on_unique: bool, variable: String, value: Variant, eval := OperatorFlags.EQUAL) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["variables"][variable] = {"value": value, "match": eval}
	else:
		quests_boiler[quest]["objectives"][objective]["variables"][variable] = {"value": value, "match": eval}


func add_objective_trigger(quest: String, objective: String, on_unique: bool, trigger: String, amount: int, eval := OperatorFlags.EQUAL) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["triggers"][trigger] = {"amount": maxi(0, amount), "match": eval}
	else:
		quests_boiler[quest]["objectives"][objective]["triggers"][trigger] = {"amount": maxi(0, amount), "match": eval}


func remove_objective_item(quest: String, objective: String, item: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["items"].erase(item)
	else:
		quests_boiler[quest]["objectives"][objective]["items"].erase(item)


func remove_objective_variable(quest: String, objective: String, variable: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["variables"].erase(objective)
	else:
		quests_boiler[quest]["objectives"][objective]["variables"].erase(objective)

# Rework for boilers
func remove_objective_trigger(quest: String, objective: String, trigger: String, on_unique: bool) -> void:
	if on_unique:
		quests_unique[quest]["objectives"][objective]["triggers"].erase(trigger)
	else:
		quests_boiler[quest]["objectives"][objective]["triggers"].erase(trigger)


func has_objective_item(quest: String, objective: String, item: String, on_unique: bool) -> bool:
	if on_unique:
		return quests_unique[quest]["objectives"][objective]["items"].has(item)
	return quests_boiler[quest]["objectives"][objective]["items"].has(item)


func has_objective_variable(quest: String, objective: String, variable: String, on_unique: bool) -> bool:
	if on_unique:
		return quests_unique[quest]["objectives"][objective]["variables"].has(objective)
	return quests_boiler[quest]["objectives"][objective]["variables"].has(objective)


func has_objective_trigger(quest: String, objective: String, trigger: String, on_unique: bool) -> bool:
	if on_unique:
		return quests_unique[quest]["objectives"][objective]["triggers"].has(trigger)
	return quests_boiler[quest]["objectives"][objective]["triggers"].has(trigger)


func get_objective_conditions(quest: String, objective: String, on_unique: bool) -> Dictionary:
	if on_unique:
		return {
			"items": quests_unique[quest]["objectives"][objective]["items"].duplicate(),
			"variables": quests_unique[quest]["objectives"][objective]["variables"].duplicate(),
			"triggers": quests_unique[quest]["objectives"][objective]["triggers"].duplicate()}
	return {
			"items": quests_boiler[quest]["objectives"][objective]["items"].duplicate(),
			"variables": quests_boiler[quest]["objectives"][objective]["variables"].duplicate(),
			"triggers": quests_boiler[quest]["objectives"][objective]["triggers"].duplicate()}


func create_objective(quest_id: String, objective_position: int, objective_id: String, on_unique: bool, title: String = "", objective_desc: String = "") -> void:
	var target_dict: Dictionary = quests_unique if on_unique else quests_boiler
	
	if objective_position < 0:
		target_dict[quest_id]["order"].append(objective_id)
	else:
		target_dict[quest_id]["order"].insert(
				clampi(
						objective_position,
						0,
						target_dict[quest_id]["order"].size()),
				objective_id)
	
	target_dict[quest_id]["objectives"][objective_id] = {
		"title": title,
		"desc": objective_desc,
		"items": {},
		"variables": {},
		"triggers": {},
	}


func save() -> void:
	ResourceSaver.save(
			self,
			ProjectSettings.get_setting(SETTINGS_PATH, "res://quests_resource.tres")
	)
