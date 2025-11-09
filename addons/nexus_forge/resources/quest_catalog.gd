@tool
@icon("res://addons/nexus_forge/icons/scroll_full.svg")
class_name QuestCatalog
extends Resource
## Resource containing all data related to quests.

const QuestType := QuestData.QuestType
const StageType := QuestStage.StageType
const StageFlag := QuestStage.StageFlag

const StepFlag := QuestStep.StepFlag
const StepType := QuestStep.StepType

## Default data assigned to a quest when [method create_quest] is called.
const DEFAULT_QUEST_DATA: Dictionary[String, Variant] = {}

## Default data assigned to a stage when [method create_stage] is called.
const DEFAULT_STAGE_DATA: Dictionary[String, Variant] = {}

## Default data assigned to a step when [method create_step] is called.
const DEFAULT_STEP_DATA: Dictionary[String, Variant] = {}

@export_storage var _quests: Dictionary[StringName, Dictionary] = {
	#&"first_quest": {
		#"title": "My first quest",
		#"description": "A quest description",
		#"data": {},
		#"first_stage": &"",
		#"stages": {}}
		}


## Returns an array containing all available quests.
func quests() -> Array[StringName]:
	var all_quests: Array[StringName] = []
	all_quests.assign(_quests.keys())
	return all_quests


## Returns an array containing all stages from the quest [param from_quest].
func stages(from_quest: StringName) -> Array[StringName]:
	var all_stages: Array[StringName] = []
	if has_quest(from_quest):
		all_stages.assign(_quests[from_quest]["stages"].keys())
	return all_stages


## Returns an array containing all steps from the stage [param from_stage] in
## the quest [param from_quest].
func steps(from_quest: StringName, from_stage: StringName) -> Array[StringName]:
	var all_steps: Array[StringName] = []
	if has_stage(from_quest, from_stage):
		all_steps.assign(_quests[from_quest]["stages"][from_stage]["steps"].keys())
	return all_steps


## Returns a [QuestData] object containing all stages and steps from the quest 
## [param quest_id].
func get_quest(quest_id: StringName) -> QuestData:
	if not has_quest(quest_id):
		return null
	
	var new_quest: QuestData = QuestData.new()
	var quest_data: Dictionary[String, Variant] = _quests[quest_id]
	
	new_quest.id = quest_id
	new_quest.title = quest_data["title"]
	new_quest.description = quest_data["description"]
	new_quest.data = quest_data["data"].duplicate(true)

	var stage_limit: int = _quests[quest_id]["stages"].size()
	var stage_iteration: int = 0
	var current_stage: StringName = quest_data["first_stage"]
	while current_stage != &"":
		if stage_limit <= stage_iteration:
			printerr("ERROR: Infinite loop/cycle detected in stage flow on quest ", quest_id)
			break
		
		var stage: QuestStage = get_quest_stage(quest_id, current_stage)
		
		if stage == null:
			printerr("ERROR: Stage {0} links to inexistent stage. Stopping stage flow for quest {1}".format([current_stage, quest_id]))
			break
		else:
			new_quest.stages.append(
					stage)
		
		current_stage = quest_data["stages"][current_stage]["next_stage"]
	
	return new_quest


## Returns a [QuestStage] object containing all steps from the stage [param stage_id]
## of the quest [param from_quest].
func get_quest_stage(from_quest: StringName, stage_id: StringName) -> QuestStage:
	if not has_stage(from_quest, stage_id):
		return null
	var new_stage: QuestStage = QuestStage.new() 
	var stage_data: Dictionary[String, Variant] = _quests[from_quest]["stages"][stage_id]
	
	new_stage.id = stage_id
	new_stage.title = stage_data["title"]
	new_stage.type = stage_data["type"]
	new_stage.flags.assign(stage_data["flags"])
	new_stage.data = stage_data["data"].duplicate(true)
	
	var step_limit: int = stage_data["steps"].size()
	var step_iteration: int = 0
	var current_step: StringName = stage_data["first_step"]
	
	while current_step != &"":
		if step_limit <= step_iteration:
			printerr("ERROR: Infinite loop/cycle detected in step flow for steps on stage ", stage_id)
			break
		
		var step: QuestStep = get_quest_step(from_quest, stage_id, current_step)
		
		if step == null:
			printerr("ERROR: Step {0} links to inexistent step. Stopping step flow for stage {1}.".format([current_step, stage_id]))
			break
		else:
			new_stage.steps.append(
					step)
		
		current_step = stage_data["steps"][current_step]["next_step"]
	
	return new_stage


## Returns a [QuestStep] from the stage [param from_stage] of the quest [param from_quest].
func get_quest_step(from_quest: StringName, from_stage: StringName, step_id: StringName) -> QuestStep:
	if not has_step(from_quest, from_stage, step_id):
		return null
	
	var step_data: Dictionary[String, Variant] = _quests[from_quest]["stages"][from_stage]["steps"][step_id]
	var new_step: QuestStep = QuestStep.new()
	new_step.id = step_id
	new_step.title = step_data["title"]
	new_step.type = step_data["type"]
	new_step.flags.assign(step_data["flags"])
	new_step.data = step_data["data"].duplicate(true)

	return new_step


## Creates a quest with ID [param quest_id] if the quest doesn't exist.
func create_quest(quest_id: StringName) -> void:
	if _quests.has(quest_id):
		return
	
	var data: Dictionary[String, Variant] = {}
	data.assign(DEFAULT_QUEST_DATA)
	var new_quest: Dictionary[String, Variant] = {
		"title": "",
		"type": QuestType.NO_TYPE,
		"description": "",
		"data": data,
		"stages": Dictionary({}, TYPE_STRING_NAME, &"", null, TYPE_DICTIONARY, &"", null)}
	
	_quests[quest_id] = new_quest


## Returns true if a quest exists with ID [param quest_id].
func has_quest(quest_id: StringName) -> bool:
	return _quests.has(quest_id)


## Returns the type of quest [param quest_id].
func get_quest_type(quest_id: StringName) -> QuestType:
	if has_quest(quest_id):
		return _quests[quest_id]["type"]
	return QuestType.NO_TYPE


## Sets the entry stage for the quest [param from_quest] to [param stage_id].
func set_quest_first_stage(from_quest: StringName, stage_id: StringName) -> void:
	if has_stage(from_quest, stage_id):
		_quests[from_quest]["first_stage"] = stage_id


## Sets the quest type for the quest [param quest_id] to [param type].
func set_quest_type(quest_id: StringName, type: QuestType) -> void:
	if has_quest(quest_id):
		_quests[quest_id]["type"] = type


## Sets the quest title for the quest [param quest_id] to [param title].
func set_quest_title(quest_id: StringName, title: String) -> void:
	if not has_quest(quest_id):
		return
	_quests[quest_id]["title"] = title


## Returns the quest title for the quest [param quest_id].
func get_quest_title(quest_id: StringName) -> String:
	if not has_quest(quest_id):
		return ""
	return _quests[quest_id]["title"]


## Sets the quest description for the quest [param quest_id] to [param description].
func set_quest_description(quest_id: StringName, description: String) -> void:
	if not has_quest(quest_id):
		return
	_quests[quest_id]["description"] = description


## Returns the quest description for the quest [param quest_id].
func get_quest_description(quest_id: StringName) -> String:
	if not has_quest(quest_id):
		return ""
	return _quests[quest_id]["description"]


## Sets the quest data with key [param data_key] for the quest [param quest_id]
## to [param data].[br]
## If [param data] is [code]null[/code] the data will be erased.
func set_quest_data(on_quest: StringName, data_key: String, data: Variant) -> void:
	if not has_quest(on_quest):
		return
	
	if data == null:
		if _quests[on_quest]["data"].has(data_key):
			_quests[on_quest]["data"].erase(data_key)
	else:
		_quests[on_quest]["data"][data_key] = data


## Returns true if the quest [param on_quest] has the data key [param data_key].
func has_quest_data(on_quest: StringName, data_key: String) -> bool:
	if not has_quest(on_quest):
		return false
	return _quests[on_quest]["data"].has(data_key)


## Returns an array with all data keys on quest with ID [param on_quest].
func quest_data_keys(on_quest: StringName) -> Array[String]:
	var keys: Array[String] = []
	if has_quest(on_quest):
		keys.assign(_quests[on_quest]["data"].keys())
	return keys


## Returns the data with key [param data_key] from quest with ID [param on_quest].[br]
## Returns null if the key doesn't exist.
func get_quest_data(on_quest: StringName, data_key: String) -> Variant:
	if not has_quest(on_quest) or not _quests[on_quest]["data"].has(data_key):
		return null
	return _quests[on_quest]["data"][data_key]


## Clears the data from the quest [param on_quest].
func clear_quest_data(on_quest: StringName) -> void:
	if has_quest(on_quest):
		_quests[on_quest]["data"].clear()


## Erases a quest with ID [param quest_id].
func erase_quest(quest_id: StringName) -> void:
	if has_quest(quest_id):
		_quests.erase(quest_id)


## Creates a stage with ID [param stage_id] on quest with ID [param on_quest].[br]
## If [param on_quest] doesn't exist the stage isn't created.
func create_stage(on_quest: StringName, stage_id: StringName) -> void:
	if not _quests.has(on_quest) or has_stage(on_quest, stage_id):
		return
	
	var flags: Array[StageFlag] = []
	var data: Dictionary[String, Variant] = {}
	data.assign(DEFAULT_STAGE_DATA)
	
	var new_stage: Dictionary[String, Variant] = {
		"next_stage": &"",
		"title": "",
		"type": StageType.NO_TYPE,
		"flags": flags,
		"data": data,
		"steps": Dictionary({}, TYPE_STRING_NAME, &"", null, TYPE_DICTIONARY, &"", null)}
	
	_quests[on_quest]["stages"][stage_id] = new_stage


## Sets a stage first step to the step with ID [param step_id] on the stage
## [param from_stage] on the quest with ID [param from_quest]. If the quest or stage
## don't exist, the stage isn't set.
func set_stage_first_step(from_quest: StringName, from_stage: StringName, step_id: StringName) -> void:
	if has_step(from_quest, from_stage, step_id):
		_quests[from_quest]["stages"][from_stage]["first_step"] = step_id


## Returns true if a stage with ID [param stage_id] exists on stage with ID
## [param on_quest].
func has_stage(on_quest: StringName, stage_id: String) -> bool:
	return _quests.has(on_quest) and _quests[on_quest]["stages"].has(stage_id)


## Links or sets the following stage from [param from_stage] to be [param to_stage]
## on the quest with ID [param of_quest]. The quest, and both stages need to exist
## for the stages to be linked.
func set_stage_link(of_quest: StringName, from_stage: StringName, to_stage: StringName) -> void:
	if has_stage(of_quest, from_stage) and ( to_stage.is_empty() or has_stage(of_quest, to_stage) ):
		_quests[of_quest]["stages"][from_stage]["next_stage"] = to_stage


## Sets the title from the stage [param stage] on the quest [param from_quest] to
## [param title].
func set_stage_title(from_quest: StringName, stage: StringName, title: String) -> void:
	if has_stage(from_quest, stage):
		_quests[from_quest]["stages"][stage]["title"] = title


## Returns the title from the stage with ID [param stage] on the quest [param from_quest].
func get_stage_title(from_quest: StringName, stage: StringName) -> String:
	if has_stage(from_quest, stage):
		return _quests[from_quest]["stages"][stage]["title"]
	return ""


## Sets the stage type for the stage with ID [param stage] on the quest
## [param quest_id] to [param type].
func set_stage_type(from_quest: StringName, stage: StringName, type: StageType) -> void:
	if has_stage(from_quest, stage):
		_quests[from_quest]["stages"][stage]["type"] = type


## Returns the stage type from the stage with ID [param stage] on the quest with
## ID [param from_quest].
func get_stage_type(from_quest: StringName, stage: StringName) -> StageType:
	if has_stage(from_quest, stage):
		return _quests[from_quest]["stages"][stage]["type"]
	return StageType.NO_TYPE


## Sets the [param flag] on the [param stage] from the quest [param from_quest].[br]
## If [param enabled] is [code]true[/code] the flag is added, otherwise it is removed.
func set_stage_flag(from_quest: StringName, stage: StringName, flag: StageFlag, enabled: bool) -> void:
	if has_stage(from_quest, stage):
		if enabled:
			if not _quests[from_quest]["stages"][stage]["flags"].has(flag):
				_quests[from_quest]["stages"][stage]["flags"].append(flag)
		else:
			if _quests[from_quest]["stages"][stage]["flags"].has(flag):
				_quests[from_quest]["stages"][stage]["flags"].erase(flag)


## Returns true if the [param stage] from the [quest] has the specified [param flag]
func has_stage_flag(quest: StringName, stage: StringName, flag: StepFlag) -> bool:
	if has_stage(quest, stage):
		return _quests[quest]["stages"][stage]["flags"].has(flag)
	return false


## Sets the stage data of stage [param stage_id] with key [param data_key] for
## the quest [param quest_id] to [param data].[br]
## If [param data] is [code]null[/code] the data key will be erased.
func set_stage_data(quest_id: StringName, stage_id: StringName, data_key: String, data: Variant) -> void:
	if not has_stage(quest_id, stage_id):
		return
	
	if data == null:
		if _quests[quest_id]["stages"][stage_id]["data"].has(data_key):
			_quests[quest_id]["stages"][stage_id]["data"].erase(data_key)
	else:
		_quests[quest_id]["stages"][stage_id]["data"][data_key] = data


## Returns true if the stage [param on_stage] from the quest [param on_quest]
## contains the data with key [param data_key].
func has_stage_data(on_quest: StringName, on_stage: StringName, data_key: String) -> bool:
	if not has_stage(on_quest, on_stage):
		return false
	return _quests[on_quest]["stages"][on_stage]["data"].has(data_key)


## Returns an array containing all the data keys on the stage [param on_stage]
## from the quest [param on_quest].
func stage_data_keys(on_quest: StringName, on_stage: StringName) -> Array[String]:
	var keys: Array[String] = []
	if has_stage(on_quest, on_stage):
		keys.assign(_quests[on_quest]["stages"][on_stage]["data"].keys())
	return keys


## Returns the data with key [param data_key] on the stage [param on_stage]
## from the quest [param on_quest].
func get_stage_data(on_quest: StringName, on_stage: StringName, data_key: String) -> Variant:
	if not has_stage(on_quest, on_stage) or not _quests[on_quest]["stages"][on_stage]["data"].has(data_key):
		return null
	return _quests[on_quest]["stages"][on_stage]["data"][data_key]


## Clears the data from the stage [param on_step] on the quest [param on_quest].
func clear_stage_data(on_quest: StringName, on_stage: StringName) -> void:
	if has_stage(on_quest, on_stage):
		_quests[on_quest]["stages"][on_stage]["data"].clear()


## Erases the stage with ID [param stage_id] from the quest with ID [param on_quest].
func erase_stage(on_quest: StringName, stage_id: String) -> void:
	if has_stage(on_quest, stage_id):
		_quests[on_quest]["stages"].erase(stage_id)


## Creates a step with ID [param step_id] on the stage [param on_stage] from
## the quest [param on_quest].
func create_step(on_quest: StringName, on_stage: StringName, step_id: StringName) -> void:
	if not has_stage(on_quest, on_stage) or has_step(on_quest, on_stage, step_id):
		return
	
	var flags: Array[StepFlag] = []
	var data: Dictionary[String, Variant] = {}
	data.assign(DEFAULT_STEP_DATA)
	var next_step: Dictionary[String, Variant] = {
		"next_step": &"",
		"title": "",
		"type": StepType.NO_TYPE,
		"flags": flags,
		"data": data}
	
	_quests[on_quest]["stages"][on_stage]["steps"][step_id] = next_step


## Returns true if a step with ID [param step_id] exists on the stage [param on_stage]
## from the quest [param on_quest].
func has_step(on_quest: StringName, on_stage: StringName, step_id: StringName) -> bool:
	return _quests.has(on_quest) and\
			_quests[on_quest]["stages"].has(on_stage) and\
			_quests[on_quest]["stages"][on_stage]["steps"].has(step_id)


## Links or sets the following step from [param from_step] to be [param to_step]
## from the stage [param stage_id] on the quest with ID [param quest_id].[br]
## The quest, and both stages need to exist for the stages to be linked.
func set_step_link(quest_id: StringName, stage_id: StringName, from_step: StringName, to_step: StringName) -> void:
	if has_step(quest_id, stage_id, from_step) and has_step(quest_id, stage_id, to_step):
		_quests[quest_id]["stages"][stage_id]["steps"]["step_id"]["next_step"] = to_step


## Sets the title of the step [param step_id] on the stage [param on_stage] from
## the quest [param on_quest] to [param title].
func set_step_title(on_quest: StringName, on_stage: StringName, step_id: StringName, title: String) -> void:
	if not has_step(on_quest, on_stage, step_id):
		return
	_quests[on_quest]["stages"][on_stage]["steps"][step_id]["title"] = title


## Returns the title of the step [param step_id] on the stage [param on_stage] from
## the quest [param on_quest].
func get_step_title(on_quest: StringName, on_stage: StringName, step_id: StringName) -> String:
	if not has_step(on_quest, on_stage, step_id):
		return ""
	return _quests[on_quest]["stages"][on_stage]["steps"][step_id]["title"]


## Sets the step type for the step with ID [param step_id] from the stage [param on_stage]
## on the quest [param quest_id] to [param type].
func set_step_type(on_quest: StringName, on_stage: StringName, step_id: StringName, type: StepType) -> void:
	if not has_step(on_quest, on_stage, step_id):
		return
	_quests[on_quest]["stages"][on_stage]["steps"][step_id]["type"] = type


## Returns the step type for the step with ID [param step_id] from the stage [param on_stage]
## on the quest [param quest_id].
func get_step_type(on_quest: StringName, on_stage: StringName, step_id: StringName) -> StepType:
	if not has_step(on_quest, on_stage, step_id):
		return StepType.NO_TYPE
	return _quests[on_quest]["stages"][on_stage]["steps"][step_id]["type"]


## Sets the [param flag] for the step [param step_id] on the [param stage] from
## the quest [param from_quest].[br]
## If [param enabled] is [code]true[/code] the flag is added, otherwise it is removed.
func set_step_flag(on_quest: StringName, on_stage: StringName, step_id: StringName, flag: StepFlag, enabled: bool) -> void:
	if not has_step(on_quest, on_stage, step_id):
		return
	if enabled:
		if not _quests[on_quest]["stages"][on_stage]["steps"][step_id]["flags"].has(flag):
			_quests[on_quest]["stages"][on_stage]["steps"][step_id]["flags"].append(flag)
	else:
		if _quests[on_quest]["stages"][on_stage]["steps"][step_id]["flags"].has(flag):
			_quests[on_quest]["stages"][on_stage]["steps"][step_id]["flags"].erase(flag)


## Returns true if the step [param step_id] on the stage [param on_stage] from
## the quest [param on_quest] has the specified [param flag].
func has_step_flag(on_quest: StringName, on_stage: StringName, step_id: StringName, flag: StepFlag) -> bool:
	if not has_step(on_quest, on_stage, step_id):
		return false
	return _quests[on_quest]["stages"][on_stage]["steps"][step_id]["flags"].has(flag)


## Sets the step data of steo [param on_step] with key [param data_key] on the
## stage [param on_stage] of the quest [param quest_id] to [param data].[br]
## If [param data] is [code]null[/code] the data key will be erased.
func set_step_data(on_quest: StringName, on_stage: StringName, on_step: StringName, data_key: String, data: Variant) -> void:
	if not has_step(on_quest, on_stage, on_step):
		return
	
	if data == null:
		if _quests[on_quest]["stages"][on_stage]["steps"][on_step]["data"].has(data_key):
			_quests[on_quest]["stages"][on_stage]["steps"][on_step]["data"].erase(data_key)
	else:
		_quests[on_quest]["stages"][on_stage]["steps"][on_step]["data"][data_key] = data


## Returns the data with key [param data_key] on the step [param on_step]
## from the stage [param on_stage] of the quest [param on_quest].
func get_step_data(on_quest: StringName, on_stage: StringName, on_step: StringName, data_key: String) -> Variant:
	if not has_step(on_quest, on_stage, on_step) or not _quests[on_quest]["stages"][on_stage]["steps"][on_step]["data"].has(data_key):
		return null
	return _quests[on_quest]["stages"][on_stage]["steps"][on_step]["data"][data_key]


## Returns true if the step [param on_step] from the stage [param on_stage] of
## the quest [param on_quest] contains the data with key [param data_key].
func has_step_data(on_quest: StringName, on_stage: StringName, on_step: StringName, data_key: String) -> bool:
	if not has_step(on_quest, on_stage, on_step):
		return false
	return _quests[on_quest]["stages"][on_stage]["steps"][on_step]["data"].has(data_key)


## Returns an array containing all the data keys on the step [param on_step]
## from the stage [param on_stage] of the quest [param on_quest].
func step_data_keys(on_quest: StringName, on_stage: StringName, on_step: StringName) -> Array[String]:
	var keys: Array[String] = []
	if has_step(on_quest, on_stage, on_step):
		keys.assign(_quests[on_quest]["stages"][on_stage]["steps"][on_step]["data"].keys())
	return keys


## Clears the data from the step [param on_step] on the stage [param on_stage]
## of the quest [param on_quest].
func clear_step_data(on_quest: StringName, on_stage: StringName, on_step: StringName) -> void:
	if has_step(on_quest, on_stage, on_step):
		_quests[on_quest]["stages"][on_stage]["steps"][on_step]["data"].clear()


## Erases the step with ID [param step_id] on the stage [param stage_id] from the
## quest with ID [param on_quest].
func erase_step(on_quest: StringName, on_stage: StringName, step_id: StringName) -> void:
	if has_step(on_quest, on_stage, step_id):
		_quests[on_quest]["stages"][on_stage]["steps"].erase(step_id)
