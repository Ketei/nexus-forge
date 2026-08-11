@tool
@icon("res://addons/nexus_forge/icons/target_icon.svg")
class_name QuestObjective
extends Resource


enum ObjectiveType {
	TRAVEL = 0,
	COLLECT = 1,
}

static var _regex_formatter: RegEx

## The ID of the objective.
@export var id: StringName = &""
## The title of the objective.
@export var title: String = "":
	set(new_title):
		if new_title == title:
			return
		title = new_title
		if _title_builder.is_valid():
			_title_builder = Callable()
## The description of the objective.
@export var description: String = "":
	set(new_desc):
		if new_desc == description:
			return
		description = new_desc
		if _description_builder.is_valid():
			_description_builder = Callable()
## The objective type.
@export var type: ObjectiveType
## Custom data assigned to this objective.
@export var custom_data: Dictionary[String, Variant] = {}

## Dictionary containing the events signaled by the quest manager when the objective
## completes. Currently only success and failure are supported.
@export var events: Dictionary[StringName, Dictionary] = {}

@export var _requirements: Dictionary[String, Dictionary] = {}

var _title_builder: Callable = Callable()
var _description_builder: Callable = Callable()


static func _static_init() -> void:
	_regex_formatter = RegEx.new()
	_regex_formatter.compile("\\{\\$[^\\}]+\\}")


## Returns the quest [member QuestObjective.title]. Formats it if [code]Format Quest Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_objective_title() -> String:
	if not ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("quests_format_strings"), false):
		return title
	
	if _title_builder.is_valid():
		return _title_builder.call()
	
	var title_formats: Dictionary[String, Callable] = {}
	
	for format_title in _regex_formatter.search_all(title):
		var string_path: String = format_title.get_string().trim_prefix("{$").trim_suffix("}")
		var path_simplified: String = string_path.simplify_path()
		
		var black_callable: Callable = NexusForge.Blackboard.get_variable.bind(path_simplified, path_simplified)
		
		title_formats["$" + string_path] = black_callable
	
	_title_builder = _build_format.bind(title, title_formats)
	
	return _build_format(title, title_formats)


## Returns the quest [member QuestObjective.description]. Formats it if [code]Format Quest Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_objective_description() -> String:
	if not ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("quests_format_strings"), false):
		return description
	
	if _description_builder.is_valid():
		return _description_builder.call()
	
	var desc_formats: Dictionary[String, Callable] = {}
	
	for description_item in _regex_formatter.search_all(description):
		var string_path: String = description_item.get_string().trim_prefix("{$").trim_suffix("}")
		var path_simplified: String = string_path.simplify_path()
		
		var variable: Callable = NexusForge.Blackboard.get_variable.bind(path_simplified, path_simplified)
		
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


## Returns if the objective has the requirement with [param requirement_path].
func has_requirement(requirement_path: String) -> bool:
	return _requirements.has(requirement_path)


## Removes a specific requirement from the objective.
func remove_requirement(requirement_path: String) -> void:
	_requirements.erase(requirement_path)


## Clears all requirements from the objective.
func clear_requirements() -> void:
	_requirements.clear()


func _build_format(string: String, call_formats: Dictionary[String, Callable]) -> String:
	var new_format: Dictionary[String, String] = {}
	
	for key in call_formats:
		new_format[key] = call_formats[key].call()
	
	return string.format(new_format)
