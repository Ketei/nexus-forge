@tool
@icon("res://addons/nexus_forge/icons/sword_icon.svg")
class_name ItemSheet
extends Resource

enum ItemFlag {
	SELLABLE,
	GIFTABLE,
	}

enum Rarity {
	BASIC,
	COMMON,
	UNCOMMON,
	RARE,
	}

var item_id: StringName = &""
var name: String = "": set = _set_item_name
var category: StringName = &""
var rarity: Rarity = Rarity.COMMON
var value: int = 0
var description: String = "": set = _set_item_description
var flags: Array[ItemFlag] = []
var custom_data: Dictionary[StringName, Variant] = {}

var _name_builder: Callable = Callable()
var _description_builder: Callable = Callable()

func _get(property: StringName) -> Variant:
	if custom_data.has(property):
		return custom_data[property]
	return null

## Returns the item [member ItemSheet.name]. Formats it if [code]Format Item Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_item_name() -> String:
	if not ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("items_format_strings"), false):
		return name
	
	if _name_builder.is_valid():
		return _name_builder.call()
	
	var _regex_formatter: RegEx
	
	_regex_formatter = RegEx.new()
	_regex_formatter.compile("\\{\\$[^\\s\\}]+\\}")
	
	var title_formats: Dictionary[String, Callable] = {}
	
	for format_title in _regex_formatter.search_all(name):
		var string_path: String = format_title.get_string().trim_prefix("{$").trim_suffix("}")
		var path_simplified: String = string_path.simplify_path()
		#var var_parts: PackedStringArray = string_path.rsplit("/", false, 1)
		
		var black_callable: Callable = NexusForge.Blackboard.get_variable.bind(path_simplified, path_simplified)
		
		title_formats["$" + string_path] = black_callable
	
	_name_builder = _build_format.bind(name, title_formats)
	
	return _build_format(name, title_formats)


## Returns the item [member ItemSheet.description]. Formats it if [code]Format Item Strings with Blackboard[/code]
## is [code]On[/code] on [code]Project Settings[/code].
func get_item_description() -> String:
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


func _set_item_name(new_name: String) -> void:
	if new_name == name:
			return
	name = new_name
	if _name_builder.is_valid():
		_name_builder = Callable()


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
