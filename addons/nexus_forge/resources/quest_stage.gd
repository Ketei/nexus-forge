@tool
@icon("res://addons/nexus_forge/icons/sign_icon.svg")
class_name QuestStage
extends Resource


enum StageType {}

## The ID of the stage.
@export var id: StringName = &""
## The title of the stage.
@export var title: String = "": set = _set_stage_title
## The description of the stage.
@export var description: String = "": set = _set_stage_description
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

var _title_builder: Callable = Callable()
var _description_builder: Callable = Callable()


func _set_stage_title(new_title: String) -> void:
	if new_title == title:
			return
	title = new_title
	if _title_builder.is_valid():
		_title_builder = Callable()


func _set_stage_description(new_desc: String) -> void:
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


## Returns the quest [member QuestStage.title]. Formats it if [code]Format Quest Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_stage_title() -> String:
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


## Returns the quest [member QuestStage.description]. Formats it if [code]Format Quest Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_stage_description() -> String:
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
