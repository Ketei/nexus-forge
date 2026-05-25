@tool
@icon("res://addons/nexus_forge/icons/scroll_full.svg")
class_name Quest
extends Resource


enum QuestType {
	MAIN_QUEST,
	SIDE_QUEST
}

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

var _title_builder: Callable = Callable()
var _description_builder: Callable = Callable()

## Returns the quest [member Quest.title]. Formats it if [code]Format Quest Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_quest_title() -> String:
	if not ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("items_format_strings"), false):
		return title
	
	if _title_builder.is_valid():
		return _title_builder.call()
	
	var _regex_formatter: RegEx
	
	_regex_formatter = RegEx.new()
	_regex_formatter.compile("\\{\\$[^\\s\\}]+\\}")
	
	var title_formats: Dictionary = {}
	
	for format_title in _regex_formatter.search_all(title):
		var string_path: String = format_title.get_string().trim_prefix("{$").trim_suffix("}")
		var var_parts: PackedStringArray = string_path.rsplit("/", false, 1)
		if var_parts.size() != 2:
			continue
		
		var variable: Callable = NexusForge.Blackboard.get_variable.bind(var_parts[0], var_parts[1], string_path)
		
		title_formats["$" + string_path] = variable
	
	_title_builder = _build_format.bind(title, title_formats)
	
	return _build_format(title, title_formats)


## Returns the item [member Quest.description]. Formats it if [code]Format Quest Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_quest_description() -> String:
	if not ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("items_format_strings"), false):
		return description
	
	if _description_builder.is_valid():
		return _description_builder.call()
	
	var _regex_formatter: RegEx
	
	_regex_formatter = RegEx.new()
	_regex_formatter.compile("\\{\\$[^\\s\\}]+\\}")
	
	var desc_formats: Dictionary = {}
	
	for description_item in _regex_formatter.search_all(description):
		var string_path: String = description_item.get_string().trim_prefix("{$").trim_suffix("}")
		var var_parts: PackedStringArray = string_path.rsplit("/", false, 1)
		if var_parts.size() != 2:
			continue
		
		var variable: Callable = NexusForge.Blackboard.get_variable.bind(var_parts[0], var_parts[1], string_path)
		
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


func _set_quest_title(new_title: String) -> void:
	if new_title == title:
			return
	title = new_title
	if _title_builder.is_valid():
		_title_builder = Callable()


func _set_item_description(new_desc: String) -> void:
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
