class_name QuestStep
extends RefCounted


enum StepFlag {
	OPTIONAL
}

# Must always contain NO_TYPE as an item.
enum StepType {
	NO_TYPE
}

## ID of the step.
var id: StringName = &""
## Title of the step.
var title: String = ""
## Type of step.
var type: StepType
## Flags of the step.
var flags: Array[StepFlag] = []
## Data for the step.
var data: Dictionary[String, Variant] = {}
