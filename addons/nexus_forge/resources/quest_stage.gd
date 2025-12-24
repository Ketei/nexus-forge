@tool
@icon("res://addons/nexus_forge/icons/sign_icon.svg")
class_name QuestStage
extends Resource


enum StageType {}

## The ID of the stage.
@export var id: StringName = &""
## The title of the stage.
@export var title: String = ""
## The description of the stage.
@export var description: String = ""
## The type of the stage.
@export var type: StageType
## CUstom data assigned to the stage.
@export var custom_data: Dictionary[String, Variant] = {}

## The ID of the next stage should this complete successfully. An empty value
## signifies the end of the quest this is in.
@export var success_stage_id: StringName = &""
## The ID of the next stage should this be failed. An empty value
## signifies the end of the quest this is in.
@export var failure_stage_id: StringName = &""

## Events to be signaled by the [QuestManager] if the stage is completed
## successfully.
@export var on_success_events: Dictionary[String, Variant] = {}
## Events to be signaled by the [QuestManager] if the stage is failed
@export var on_failure_events: Dictionary[String, Variant] = {}

@export var _objectives: Dictionary[StringName, Dictionary] = {}



## Returns an array with all the IDs of registered objectives.
func objectives() -> Array[StringName]:
	var obj: Array[StringName] = []
	obj.assign(_objectives.keys())
	return obj


## Creates a new objective for this stage. If an objective with id
## [method QuestObjective.id] already exists it won't be added.[br]
## [param required] will define if this objective is required to complete
## the stage.
func add_objective(objective: QuestObjective, required: bool) -> void:
	if _objectives.has(objective.id):
		return
	_objectives[objective.id] = {
		"objective": objective,
		"required": required}


## Removes the objective with id [param objective_id].
func remove_objective(objective_id: StringName) -> void:
	_objectives.erase(objective_id)


## Returns true if [param objective_id] is registered in this stage.
func has_objective(objective_id: StringName) -> bool:
	return _objectives.has(objective_id)


## Sets the existing [param objective_id] to be [param required] or not.
func set_objective_required(objective_id: StringName, required: bool) -> void:
	if _objectives.has(objective_id):
		_objectives[objective_id]["required"] = required


## Returns [code]true[/code] if [param objective_id] exists and is required to
## complete the stage.
func is_objective_required(objective_id: StringName) -> bool:
	if _objectives.has(objective_id):
		return _objectives[objective_id]["required"]
	return false


## Returns [code]true[/code] if all the required objectives have been completed.
func can_complete_stage() -> bool:
	for objective_id in _objectives:
		var a: QuestObjective
		if _objectives[objective_id]["required"] and not _objectives[objective_id]["objective"].is_objective_complete():
			return false
	return true


## Returns the objective object assigned to [param objective_id]. Returns
## [code]null[/code] if the objective isn't registered.
func get_objective(objective_id: StringName) -> QuestObjective:
	if _objectives.has(objective_id):
		return _objectives[objective_id]["objective"]
	return null
