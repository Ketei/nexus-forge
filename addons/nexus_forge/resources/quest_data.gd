class_name QuestData
extends RefCounted
## An object containing the data and stages of a given quest.

# Must always contain one item.
# Changing this will update NexusForge Quests' types
enum QuestType {
	NO_TYPE
}

## ID of the quest.
var id: StringName = &""
## Title of the quest
var title: String = ""
## Type of the quest
var type: QuestType
## Description of the quest
var description: String = ""
## Data for the quest
var data: Dictionary[String, Variant] = {}
## Array containing all the stages in order.
var stages: Array[QuestStage] = []


## Returns all the stages IDs in the quest
func get_stages() -> Array[StringName]:
	var stages_id: Array[StringName] = []
	for stage in stages:
		stages_id.append(stage.id)
	return stages_id


## Returns the first stage of a quest.
func get_first_stage() -> QuestStage:
	return null if stages.is_empty() else stages[0]


## Returns a QuestStage object matching [param stage_id]. If it isn't found
## it returns [code]null[/code].
func get_stage(stage_id: StringName) -> QuestStage:
	for stage in stages:
		if stage.id == stage_id:
			return stage
	return null


## Gets the next stage from [param stage_id]. If [param stage_id] is the last
## stage it returns [code]null[/code].
func get_next_stage(stage_id: StringName) -> QuestStage:
	var idx: int = -1
	for stage in stages:
		if stage.id == stage_id:
			if idx + 1 < stages.size():
				return stages[idx + 1]
			else:
				return null
	return null
