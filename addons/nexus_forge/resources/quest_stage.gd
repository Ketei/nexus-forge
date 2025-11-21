class_name QuestStage
extends RefCounted


# Must always contain NO_TYPE as an item.
enum StageType {
	NO_TYPE
}

enum StageFlag {
	HIDE_STEPS
}

## ID of the stage
var id: StringName = &""
## Title of the stage
var title: String = ""
## Type of the stage
var type: StageType
## Flags of the stage
var flags: Array[StageFlag] = []
## Data for the stage
var data: Dictionary[String, Variant] = {}
## An array containing the stage steps in order.
var steps: Array[QuestStep] = []


## Returns all the steps IDs in the stage.
func get_steps() -> Array[StringName]:
	var steps_id: Array[StringName] = []
	for step in steps:
		steps_id.append(step.id)
	return steps_id


## Returns the first stage of a quest.
func get_first_step() -> QuestStep:
	return null if steps.is_empty() else steps[0]


## Returns a QuestStage object matching [param stage_id]. If it isn't found
## it returns [code]null[/code].
func get_step(step_id: StringName) -> QuestStep:
	for step in steps:
		if step.id == step_id:
			return step
	return null


## Gets the next step from [param step_id]. If [param step_id] is the last
## step it returns [code]null[/code].
func get_next_step(step_id: StringName) -> QuestStep:
	var idx: int = -1
	for step in steps:
		if step.id == step_id:
			if idx + 1 < steps.size():
				return steps[idx + 1]
			else:
				return null
	return null
