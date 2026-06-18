@tool
@icon("res://addons/nexus_forge/icons/target_icon.svg")
class_name QuestObjective
extends Resource


enum ObjectiveType {}

## The ID of the objective.
@export var id: StringName = &""
## The title of the objective.
@export var title: String = "": set = _set_objective_title
## The description of the objective.
@export var description: String = "": set = _set_objective_description
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
var _completed: bool = false
var _title_builder: Callable = Callable()
var _description_builder: Callable = Callable()


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


func _set_objective_title(new_title: String) -> void:
	if new_title == title:
			return
	title = new_title
	if _title_builder.is_valid():
		_title_builder = Callable()


func _set_objective_description(new_desc: String) -> void:
	if new_desc == description:
		return
	description = new_desc
	if _description_builder.is_valid():
		_description_builder = Callable()


func _build_format(string: String, call_formats: Dictionary[String, Callable]) -> String:
	var new_format: Dictionary[String, String] = {}
	
	for key in call_formats.keys():
		new_format[key] = call_formats[key].call()
	
	return string.format(new_format)


## Returns the quest [member QuestObjective.title]. Formats it if [code]Format Quest Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_objective_title() -> String:
	if not ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("quests_format_strings"), false):
		return title
	
	if _title_builder.is_valid():
		return _title_builder.call()
	
	var _regex_formatter: RegEx
	
	_regex_formatter = RegEx.new()
	_regex_formatter.compile("\\{\\$[^\\s\\}]+\\}")
	
	var title_formats: Dictionary[String, Callable] = {}
	
	for format_title in _regex_formatter.search_all(title):
		var string_path: String = format_title.get_string().trim_prefix("{$").trim_suffix("}")
		var path_simplified: String = string_path.simplify_path()
		#var var_parts: PackedStringArray = string_path.rsplit("/", false, 1)
		
		var black_callable: Callable = NexusForge.Blackboard.get_variable.bind(path_simplified, path_simplified)
		
		title_formats["$" + string_path] = black_callable
	
	_title_builder = _build_format.bind(title, title_formats)
	
	return _build_format(title, title_formats)


## Returns the quest [member QuestObjective.description]. Formats it if [code]Format Quest Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_objective_description() -> String:
	if not ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("items_format_strings"), false):
		return description
	
	if _description_builder.is_valid():
		return _description_builder.call()
	
	var _regex_formatter: RegEx
	
	_regex_formatter = RegEx.new()
	_regex_formatter.compile("\\{\\$[^\\s\\}]+\\}")
	
	var desc_formats: Dictionary[String, Callable] = {}
	
	for description_item in _regex_formatter.search_all(description):
		var string_path: String = description_item.get_string().trim_prefix("{$").trim_suffix("}")
		var var_parts: PackedStringArray = string_path.rsplit("/", false, 1)
		if var_parts.size() != 2:
			continue
		
		var variable: Callable = NexusForge.Blackboard.get_variable.bind(var_parts[0], var_parts[1], string_path)
		
		desc_formats["$" + string_path] = variable
	
	_description_builder = _build_format.bind(description, desc_formats)
	
	return _build_format(description, desc_formats)


## Returns an array containing all the paths of the requirements.
func requirements() -> Array[String]:
	var rq: Array[String] = []
	rq.assign(_requirements.keys())
	return rq


## Returns the data type of the [param requirement_path]. Returns [code]TYPE_NIL[/code]
## if [param requirement_path] isn't registered.
func get_requirement_type(requirement_path: String) -> int:
	if not _requirements.has(requirement_path):
		return TYPE_NIL
	return typeof(_requirements[requirement_path]["value"])


## Returns the value of [param requirement_path] or [code]null[/code] if the requirement
## doesn't exist.
func get_requirement_value(requirement_path: String) -> Variant:
	if _requirements.has(requirement_path):
		return _requirements[requirement_path]["value"]
	return null


## Returns the operator used when [param requirement_path] is checked for completion.
func get_requirement_mode(requirement_path: String) -> int:
	if _requirements.has(requirement_path):
		return _requirements[requirement_path]["operator"]
	return OP_MAX


## Sets a requirement to complete this objective with [param requirement_path].[br]
## If any progress has been set but the type of [param completion_value] is
## different to the one being tracked then the progress will be reset.
func set_requirement(requirement_path: String, completion_operator: int, completion_value) -> void:
	_requirements[requirement_path] = {
		"operator": completion_operator,
		"value": completion_value}
	if _progress.has(requirement_path) and typeof(_progress[requirement_path]) != get_requirement_type(requirement_path):
		_progress.erase(requirement_path)


## Sets the progress of [param requirement_path] to [param progress_value].[br]
## [b]Important:[/b] The type of [param progress_value] must match the type of the
## requirement otherwise the progress won't be set.
func set_progress(requirement_path: String, progress_value) -> void:
	if not _requirements.has(requirement_path) or typeof(_requirements[requirement_path]["value"]) != typeof(progress_value):
		return
	_progress[requirement_path] = progress_value


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


## Returns [code]true[/code] if all the requirements in the objective have been met
## or if [method set_completed] was called with [code]true[/code].
func is_objective_complete() -> bool:
	if _completed:
		return true
	
	for requirement_path in _requirements.keys():
		if not _progress.has(requirement_path):
			return false
		match _requirements[requirement_path]["operator"]:
			OP_EQUAL:
				if _progress[requirement_path] != _requirements[requirement_path]["value"]:
					return false
			OP_NOT_EQUAL:
				if _progress[requirement_path] == _requirements[requirement_path]["value"]:
					return false
			OP_LESS:
				if _requirements[requirement_path]["value"] <= _progress[requirement_path]:
					return false
			OP_LESS_EQUAL:
				if _requirements[requirement_path]["value"] < _progress[requirement_path]:
					return false
			OP_GREATER:
				if _progress[requirement_path] <= _requirements[requirement_path]["value"]:
					return false
			OP_GREATER_EQUAL:
				if _progress[requirement_path] < _requirements[requirement_path]["value"]:
					return false
	
	return true


## Returns if the objective has the requirement with [param requirement_path].
func has_requirement(requirement_path: String) -> bool:
	return _requirements.has(requirement_path)


## Clears all requirements from the objective.
func clear_requirements() -> void:
	_requirements.clear()
	_progress.clear()


## Forces the status of completed on the objective, even if the requirements
## haven't been met.
func set_completed(is_completed: bool) -> void:
	_completed = is_completed
