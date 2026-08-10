@tool
@icon("res://addons/nexus_forge/icons/scroll_full.svg")
class_name Quest
extends Resource


enum QuestType {
	MAIN_QUEST = 0,
	SIDE_QUEST = 1,
}

static var _regex_formatter: RegEx

## ID of the quest.
@export var id: StringName = &""
## Type of the quest.
@export var type: QuestType
## The title of the quest.
@export var title: String = "":
	set(new_title):
		if new_title == title:
			return
		title = new_title
		if _title_builder.is_valid():
			_title_builder = Callable()
## The description of the quest.
@export var description: String = "":
	set(new_desc):
		if new_desc == description:
			return
		description = new_desc
		if _description_builder.is_valid():
			_description_builder = Callable()
## Custom data assigned to the quest.
@export var custom_data: Dictionary[String, Variant] = {}

## The initial stage of the quest.
@export var entry_stage: StringName = &""

## Events to be signaled by the [QuestManager] if the quest is completed
## successfully.

## Dictionary containing the events signaled by the quest manager when the quest
## completes. Currently only Succed and Failed are supported.
@export var events: Dictionary[StringName, Dictionary] = {}

@export var _stages: Dictionary[StringName, QuestStage] = {}

var _title_builder: Callable = Callable()
var _description_builder: Callable = Callable()
var _mods_applied: bool = false:
	set(a):
		if _mods_applied:
			return
		_mods_applied = a


static func _static_init() -> void:
	_regex_formatter = RegEx.new()
	_regex_formatter.compile("\\{\\$[^\\}]+\\}")


## Returns the quest [member Quest.title]. Formats it if [code]Format Quest Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_quest_title() -> String:
	if not ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("items_format_strings"), false):
		return title
	
	if _title_builder.is_valid():
		return _title_builder.call()
	
	var title_formats: Dictionary[String, Callable] = {}
	
	for format_title in _regex_formatter.search_all(title):
		var string_path: String = format_title.get_string().trim_prefix("{$").trim_suffix("}")
		var path_simplified: String = string_path.simplify_path()
		
		var variable: Callable = NexusForge.Blackboard.get_variable.bind(path_simplified, path_simplified)
		
		title_formats["$" + string_path] = variable
	
	_title_builder = _build_format.bind(title, title_formats)
	
	return _build_format(title, title_formats)


## Returns the item [member Quest.description]. Formats it if [code]Format Quest Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_quest_description() -> String:
	if not ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("items_format_strings"), false):
		return description
	
	if _description_builder.is_valid():
		return _description_builder.call()
	
	var desc_formats: Dictionary = {}
	
	for description_item in _regex_formatter.search_all(description):
		var string_path: String = description_item.get_string().trim_prefix("{$").trim_suffix("}")
		var path_simplified: String = string_path.simplify_path()
		
		var variable: Callable = NexusForge.Blackboard.get_variable.bind(path_simplified, path_simplified)
		
		desc_formats["$" + string_path] = variable
	
	_description_builder = _build_format.bind(description, desc_formats)
	
	return _build_format(description, desc_formats)


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


func _build_format(string: String, call_formats: Dictionary[String, Callable]) -> String:
	var new_format: Dictionary[String, String] = {}
	
	for key in call_formats:
		new_format[key] = call_formats[key].call()
	
	return string.format(new_format)
