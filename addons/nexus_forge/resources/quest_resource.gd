@tool
@icon("res://addons/nexus_forge/icons/scroll_full.svg")
class_name Quest
extends Resource


enum QuestType {ONE}

## ID of the quest.
@export var id: StringName = &""
## Type of the quest.
@export var type: QuestType
## The title of the quest.
@export var title: String = ""
## The description of the quest.
@export var description: String = ""
## Custom data assigned to the quest.
@export var custom_data: Dictionary[String, Variant] = {}

## The initial stage of the quest.
@export var entry_stage: StringName = &""

## Events to be signaled by the [QuestManager] if the quest is completed
## successfully.
@export var on_success_events: Dictionary[String, Variant] = {}
## Events to be signaled by the [QuestManager] if the quest is failed.
@export var on_failure_events: Dictionary[String, Variant] = {}

@export var _stages: Dictionary[StringName, QuestStage] = {}


## Returns an array with all the IDs of the stages on this quest.
func stages() -> Array[StringName]:
	var st: Array[StringName] = []
	st.assign(_stages.keys())
	return st


## Adds a new stage to this quest.[br]
## [b]Note:[/b] Ensure that the [member QuestStage.id] from [param stage] is
## unique or it'll be overwriting an existing stage.
func add_stage(stage: QuestStage) -> void:
	_stages[stage.id] = stage


## Removes a stage with [param stage_id].
func remove_stage(stage_id: StringName) -> void:
	_stages.erase(stage_id)


## Returns if a stage with [param stage_id] is in this quest.
func has_stage(stage_id: StringName) -> bool:
	return _stages.has(stage_id)


## Returns the stage object from [param stage_id] or [code]null[/code] if the stage
## doesn't exist.
func get_stage(stage_id: StringName) -> QuestStage:
	if _stages.has(stage_id):
		return _stages[stage_id]
	return null
