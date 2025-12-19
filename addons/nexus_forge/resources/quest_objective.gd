@tool
@icon("res://addons/nexus_forge/icons/target_icon.svg")
class_name QuestObjective
extends Resource


enum ObjectiveType {}

## The ID of the objective.
@export var id: StringName = &""
## The title of the objective.
@export var title: String = ""
## The description of the objective.
@export var description: String = ""
## The objective type.
@export var type: ObjectiveType
## Custom data assigned to this objective.
@export var custom_data: Dictionary[String, Variant] = {}

## Events emmited by the quest manager when the objective is successfully
## completed.
@export var on_success_events: Dictionary[String, Variant] = {}
## Events emmited by the quest manager when the objective is failed.
@export var on_failure_events: Dictionary[String, Variant] = {}

@export var _requirements: Dictionary[String, Dictionary] = {}

var _progress: Dictionary[String, Variant] = {}


func _get_default_value_of_type(type_id: int) -> Variant:
	match type_id:
		TYPE_BOOL:
			return false
		TYPE_INT:
			return 0
		TYPE_FLOAT:
			return 0.0
		TYPE_STRING:
			return ""
		TYPE_VECTOR2:
			return Vector2.ZERO
		TYPE_VECTOR2I:
			return Vector2i.ZERO
		TYPE_RECT2:
			return Rect2()
		TYPE_RECT2I:
			return Rect2i()
		TYPE_VECTOR3:
			return Vector3.ZERO
		TYPE_VECTOR3I:
			return Vector3i.ZERO
		TYPE_TRANSFORM2D:
			return Transform2D()
		TYPE_VECTOR4:
			return Vector4.ZERO
		TYPE_VECTOR4I:
			return Vector4i.ZERO
		TYPE_PLANE:
			return Plane()
		TYPE_QUATERNION:
			return Quaternion()
		TYPE_AABB:
			return AABB()
		TYPE_BASIS:
			return Basis()
		TYPE_TRANSFORM3D:
			return Transform3D()
		TYPE_PROJECTION:
			return Projection()
		TYPE_COLOR:
			return Color()
		TYPE_STRING_NAME:
			return &""
		TYPE_DICTIONARY:
			return {}
		TYPE_ARRAY:
			return []
		TYPE_PACKED_BYTE_ARRAY:
			return PackedByteArray()
		TYPE_PACKED_INT32_ARRAY:
			return PackedInt32Array()
		TYPE_PACKED_INT64_ARRAY:
			return PackedInt64Array()
		TYPE_PACKED_FLOAT32_ARRAY:
			return PackedFloat32Array()
		TYPE_PACKED_FLOAT64_ARRAY:
			return PackedFloat64Array()
		TYPE_PACKED_STRING_ARRAY:
			return PackedStringArray()
		TYPE_PACKED_VECTOR2_ARRAY:
			return PackedVector2Array()
		TYPE_PACKED_VECTOR3_ARRAY:
			return PackedVector3Array()
		TYPE_PACKED_COLOR_ARRAY:
			return PackedColorArray()
		TYPE_PACKED_VECTOR4_ARRAY:
			return PackedVector4Array()
		_:
			return null


## Returns an array containing all the IDs of the requirements.
func requirements() -> Array[String]:
	var rq: Array[String] = []
	rq.assign(_requirements.keys())
	return rq


## Returns the data type of the [param requirement_id]. Returns [code]TYPE_NIL[/code]
## if [param requirement_id] isn't registered.
func get_requirement_type(requirement_id) -> int:
	if not _requirements.has(requirement_id):
		return TYPE_NIL
	return typeof(_requirements[requirement_id]["value"])


## Returns the value of [param requirement_id] or [code]null[/code] if the requirement
## doesn't exist.
func get_requirement_value(requirement_id: String) -> Variant:
	if _requirements.has(requirement_id):
		return _requirements[requirement_id]["value"]
	return null


## Returns the operator used when [param requirement_id] is checked for completion.
func get_requirement_mode(requirement_id: String) -> int:
	if _requirements.has(requirement_id):
		return _requirements[requirement_id]["operator"]
	return OP_MAX


## Sets a requirement to complete this objective with [param requirement_id].[br]
## If any progress has been set but the type of [param completion_value] is
## different to the one being tracked then the progress will be reset.
func set_requirement(requirement_id: String, completion_operator: int, completion_value) -> void:
	_requirements[requirement_id] = {
		"operator": completion_operator,
		"value": completion_value}
	if _progress.has(requirement_id) and typeof(_progress[requirement_id]) != get_requirement_type(requirement_id):
		_progress.erase(requirement_id)


## Sets the progress of [param requirement_id] to [param progress_value].[br]
## [b]Important:[/b] The type of [param progress_value] must match the type of the
## requirement otherwise the progress won't be set.
func set_progress(requirement_id: String, progress_value) -> void:
	if not _requirements.has(requirement_id) or typeof(_requirements[requirement_id]["value"]) != typeof(progress_value):
		return
	_progress[requirement_id] = progress_value


## Returns a dicitionary with the progress for all requirements and their current mode.
func get_objective_progress() -> Dictionary:
	var progress: Dictionary = {}
	
	for req in _requirements.keys():
		var current = null
		if _progress.has(req):
			current = _progress[req]
		else:
			current = _get_default_value_of_type(typeof(_requirements[req]["value"]))
			
		progress[req] = {
				"mode": _requirements[req]["operator"],
				"current": current,
				"target": _requirements[req]["value"]}
	
	return progress


## Returns the progress for the specific [param requirement]. Returns an empty
## dictionary if [param requirement] isn't registered.
func get_requirement_progress(requirement: String) -> Dictionary:
	var progress: Dictionary = {}
	if _requirements.has(requirement):
		var current = null
		if _progress.has(requirement):
			current = _progress[requirement]
		else:
			current = _get_default_value_of_type(typeof(_requirements[requirement]["value"]))
		progress["mode"] = _requirements[requirement]["operator"]
		progress["current"] = current
		progress["target"] = _requirements[requirement]["value"]
	return progress


## Returns [code]true[/code] if all the requirements in the objective have been met.
func is_objective_complete() -> bool:
	for requirement_id in _requirements.keys():
		if not _progress.has(requirement_id):
			return false
		match _requirements[requirement_id]["operator"]:
			OP_EQUAL:
				if _progress[requirement_id] != _requirements[requirement_id]["value"]:
					return false
			OP_NOT_EQUAL:
				if _progress[requirement_id] == _requirements[requirement_id]["value"]:
					return false
			OP_LESS:
				if _requirements[requirement_id]["value"] <= _progress[requirement_id]:
					return false
			OP_LESS_EQUAL:
				if _requirements[requirement_id]["value"] < _progress[requirement_id]:
					return false
			OP_GREATER:
				if _progress[requirement_id] <= _requirements[requirement_id]["value"]:
					return false
			OP_GREATER_EQUAL:
				if _progress[requirement_id] < _requirements[requirement_id]["value"]:
					return false
	
	return true


## Returns if the objective has the requirement with [param requirement_id].
func has_requirement(requirement_id: String) -> bool:
	return _requirements.has(requirement_id)


## Clears all requirements from the objective.
func clear_requirements() -> void:
	_requirements.clear()
	_progress.clear()
