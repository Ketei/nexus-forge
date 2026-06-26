@tool
extends EditorPlugin


const MAIN_SCENE = preload("res://addons/nexus_forge/NexusForgeMainScene.tscn")
const PLUGIN_NAME: String = "NexusForge"
const PLUGIN_ICON_PATH: String = "res://addons/nexus_forge/icons/nexus_forge_small.svg"
const HANDLED_CLASSES: Array[StringName] = [&"EditorDiscourseDialog", &"CharacterSheet", &"PhraseMap", &"Quest"]
const TOOL_NAME: String = "Nexus Forge Character Lookup"

var editor_view: Control = null
var export_plugin: EditorExportPlugin = null
var character_map: Dictionary[String, Variant] = {}


# Earlier versions of godot had an issue where documentation wouldn't show
# unless recompiled. This forces a recompilation. Adds to load time.
func recompile_script_docs() -> void:
	const SCRIPT_DOC: Array[String] = [
		"res://addons/nexus_forge/classes/autoload/nexus_forge_singleton.gd",
		"res://addons/nexus_forge/resources/cache/cache_system.gd",
		"res://addons/nexus_forge/resources/cache/resource_cache.gd",
		"res://addons/nexus_forge/resources/bit_flags.gd",
		"res://addons/nexus_forge/resources/value_range.gd",
		"res://addons/nexus_forge/resources/range_float.gd",
		"res://addons/nexus_forge/resources/range_integer.gd",
		"res://addons/nexus_forge/classes/utils/array_utils.gd",
		"res://addons/nexus_forge/classes/utils/bit_utils.gd",
		"res://addons/nexus_forge/classes/utils/dict_utils.gd",
		"res://addons/nexus_forge/classes/utils/math.gd",
		"res://addons/nexus_forge/classes/utils/random_weight_pool.gd",
		"res://addons/nexus_forge/classes/utils/ranges.gd",
		"res://addons/nexus_forge/classes/utils/strings.gd",
		"res://addons/nexus_forge/classes/utils/uuid.gd",
		"res://addons/nexus_forge/resources/skill_set.gd",
		"res://addons/nexus_forge/resources/stat_block.gd",
		"res://addons/nexus_forge/resources/trait_block.gd",
		"res://addons/nexus_forge/resources/dialog_storage/dialog_locale.gd",
		"res://addons/nexus_forge/resources/dialog_storage/parsed_dialog.gd",
		"res://addons/nexus_forge/resources/localization/phrase_map.gd",
		"res://addons/nexus_forge/resources/parser/discouse_parser_base.gd",
		"res://addons/nexus_forge/resources/character_sheet.gd",
		"res://addons/nexus_forge/resources/item_sheet.gd",
		"res://addons/nexus_forge/resources/quest_objective.gd",
		"res://addons/nexus_forge/resources/quest_stage.gd",
		"res://addons/nexus_forge/resources/quest_resource.gd",
		"res://addons/nexus_forge/resources/quest_manager.gd",
		"res://addons/nexus_forge/resources/recipe_item.gd",
		"res://addons/nexus_forge/resources/recipe_sheet.gd",
		"res://addons/nexus_forge/resources/species.gd",
		"res://addons/nexus_forge/resources/currency_catalog.gd",
		"res://addons/nexus_forge/resources/item_catalog.gd",
		"res://addons/nexus_forge/resources/recipe_catalog.gd",
		"res://addons/nexus_forge/resources/skill_catalog.gd",
		"res://addons/nexus_forge/resources/species_catalog.gd",
		"res://addons/nexus_forge/resources/stat_catalog.gd",
		"res://addons/nexus_forge/resources/trait_catalog.gd",
		"res://addons/nexus_forge/resources/var_db_script.gd"]
	
	for file in SCRIPT_DOC:
		ResourceSaver.save(load(file))


func _enter_tree() -> void:
	export_plugin = preload("res://addons/nexus_forge/export_plugin.gd").new()
	add_export_plugin(export_plugin)
	verify_project_settings()
	if ProjectSettings.has_setting("autoload/NexusForge") and ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("recompile_documentation"), false):
		recompile_script_docs.call_deferred()
	editor_view = MAIN_SCENE.instantiate()
	editor_view.visible = false
	EditorInterface.get_editor_main_screen().add_child(editor_view)
	if not editor_view.is_node_ready():
		await editor_view.ready
	var use_discourse: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("discourse_enabled"), true)
	var use_characters: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("characters_enabled"), true)
	var use_species: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("species_enabled"), true)
	var use_stats: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("stats_enabled"), true)
	var use_skills: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("skills_enabled"), true)
	var use_traits: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("traits_enabled"), true)
	var use_items: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("items_enabled"), true)
	var use_currencies: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("currencies_enabled"), true)
	var use_recipes: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("recipes_enabled"), true)
	var use_quests: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("quests_enabled"), true)
	var use_phrases: bool = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("phrases_enabled"), true)
	var discourse_base_lang: String = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("discourse_base_language"), OS.get_locale_language())
	
	editor_view.ready_plugin(
			use_discourse,
			use_characters,
			use_species,
			use_stats,
			use_skills,
			use_traits,
			use_items,
			use_currencies,
			use_recipes,
			use_quests,
			use_phrases,
			discourse_base_lang)
	
	if FileAccess.file_exists("user://nexus_forge/persona_settings.cfg"):
		var cfg: ConfigFile = ConfigFile.new()
		if cfg.load("user://nexus_forge/persona_settings.cfg") == OK:
			var data = cfg.get_value("RUNTIME", "CharacterMap")
			for key in data.keys():
				if FileAccess.file_exists(key):
					character_map[key] = data[key]
	
	if use_characters:
		editor_view.characters.character_loaded.connect(_on_character_loaded)
	
	add_tool_menu_item(TOOL_NAME, _on_scan_folder_selected)
	
	resource_saved.connect(_on_resource_saved, CONNECT_DEFERRED)
	EditorInterface.get_file_system_dock().resource_removed.connect(_on_resource_removed)
	EditorInterface.get_file_system_dock().files_moved.connect(_on_files_moved, CONNECT_DEFERRED)


func _build() -> bool:
	var path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse"), "res://localization/").strip_edges()
	
	var valid_path: bool = path != "" and path.is_absolute_path() and path.begins_with("res://") and path.get_extension() == ""
	
	if not valid_path:
		printerr("[ERROR] NexusForge: Discourse needs a valid folder path for localization files on project settings.")
	
	if ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("character_register_ids"), true):
		save_character_paths()
	
	return true


func _save_external_data() -> void:
	if _editor_ready():
		editor_view.save_resources()
	
	var character_cfg: ConfigFile = ConfigFile.new()
	
	character_cfg.set_value("RUNTIME", "CharacterMap", character_map)
	
	if character_cfg.save("user://nexus_forge/persona_settings.cfg") != OK:
		print("Failed saving character config")


func _has_main_screen() -> bool:
	return true


func _get_unsaved_status(for_scene: String) -> String:
	if for_scene.is_empty() and editor_view.has_unsaved_changes():
		return "Save changes in NexusForge before closing?"
	return ""


func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	remove_tool_menu_item(TOOL_NAME)
	if editor_view:
		editor_view.queue_free()
	resource_saved.disconnect(_on_resource_saved)


func _get_plugin_icon() -> Texture2D:
	return load(PLUGIN_ICON_PATH)


func _get_plugin_name() -> String:
	return PLUGIN_NAME


func _make_visible(visible):
	if editor_view != null:
		editor_view.visible = visible


func _enable_plugin() -> void:
	add_autoload_singleton(
			"NexusForge",
			"res://addons/nexus_forge/classes/autoload/nexus_forge_singleton.gd")
	if ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("recompile_documentation"), false):
		recompile_script_docs.call_deferred()


func _get_window_layout(configuration: ConfigFile) -> void:
	var discourse_id_visible: bool = editor_view.discourse.display_dialog_id_checked() if editor_view.discourse != null else false
	var discourse_open_files: Array[String] = editor_view.discourse.get_open_files() if editor_view.discourse != null else Array([], TYPE_STRING, &"", null)
	var discourse_recent_files: Array[String] = editor_view.discourse.get_recenlty_opened_files() if editor_view.discourse != null else ArrayUtils.create_typed(TYPE_STRING)
	var open_characters: Array[String] = editor_view.characters.get_open_characters() if editor_view.characters != null else Array([], TYPE_STRING, &"", null)
	var open_maps: Array[String] = editor_view.phrase_maps.get_open_maps() if editor_view.phrase_maps != null else Array([], TYPE_STRING, &"", null)
	var open_quests: Array[String] = editor_view.quests.get_open_files() if editor_view.quests != null else Array([], TYPE_STRING, &"", null)
	
	editor_view.save_layouts()
	
	configuration.set_value("NexusForge", "discourse_show_id", discourse_id_visible)
	configuration.set_value("NexusForge", "open_dialogs", discourse_open_files)
	configuration.set_value("NexusForge", "recent_dialogs", discourse_recent_files)
	configuration.set_value("NexusForge", "open_characters", open_characters)
	configuration.set_value("NexusForge", "open_phrase_maps", open_maps)
	configuration.set_value("NexusForge", "open_quests", open_quests)
	configuration.set_value("NexusForge", "active_tab", editor_view.current_tab)
	
	configuration.set_value("NexusForge", "blackboard_folder_layout", editor_view.variables.get_folder_layout())
	configuration.set_value("NexusForge", "blackboard_sort_column", editor_view.variables.get_sorting_column())


func _set_window_layout(configuration: ConfigFile) -> void:
	const empty: Array[String] = []
	var maps: Array[String] = configuration.get_value("NexusForge", "open_phrase_maps", empty)
	var characters: Array[String] = configuration.get_value("NexusForge", "open_characters", empty)
	var dialogs: Array[String] = configuration.get_value("NexusForge", "open_dialogs", empty)
	var recent_dialogs: Array[String] = configuration.get_value("NexusForge", "recent_dialogs", empty)
	var folder_layout: Dictionary = configuration.get_value("NexusForge", "blackboard_folder_layout", {})
	var black_sorting_column: int = configuration.get_value("NexusForge", "blackboard_sort_column", 0)
	var open_quests: Array[String] = configuration.get_value("NexusForge", "open_quests", empty)
	var discourse_display_id: bool = configuration.get_value("NexusForge", "discourse_show_id", false)
	var tab: int = configuration.get_value("NexusForge", "active_tab", 0)
	
	editor_view.go_to_tab(tab)
	editor_view.variables.set_folder_layout(folder_layout)
	editor_view.variables.set_sorting_column(black_sorting_column)
	editor_view.variables.restore_layout()
	
	if editor_view.discourse != null:
		editor_view.discourse.load_dialog_files(dialogs)
		editor_view.discourse.set_recently_opened_files(recent_dialogs)
		editor_view.discourse.set_display_dialog_id_checked(discourse_display_id)
	if editor_view.characters != null:
		editor_view.characters.load_character_files(characters)
	if editor_view.phrase_maps != null:
		editor_view.phrase_maps.open_map_files(maps)
	if editor_view.quests != null:
		editor_view.quests.open_files(open_quests)


func _sort_custom_settings(a: String, b: String) -> bool:
	var a_string: String = NFPluginGameHandler._SETTINGS_PATHS[a]["sort_string"] if NFPluginGameHandler._SETTINGS_PATHS[a].has("sort_string") else NFPluginGameHandler._SETTINGS_PATHS[a]["setting_path"]
	var b_string: String = NFPluginGameHandler._SETTINGS_PATHS[b]["sort_string"] if NFPluginGameHandler._SETTINGS_PATHS[b].has("sort_string") else NFPluginGameHandler._SETTINGS_PATHS[b]["setting_path"]
	return a_string < b_string


func is_preview_scene_valid(print_errors: bool = true) -> bool:
	var path: String = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("discourse_localization_preview_scene"), "")
	
	if path.is_empty():
		return false
	
	if not FileAccess.file_exists(path):
		if print_errors:
			NFPluginGameHandler._log_msg(
				"settings",
				"Localization preview scene '%s' was not found" % path,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	var scene = load(path)
	if scene == null or not scene is PackedScene or not scene.can_instantiate():
		if print_errors:
			NFPluginGameHandler._log_msg(
					"settings",
					"Error during instantiation of scene '%s'" % path,
					NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	var instance: Node = scene.instantiate()
	var scene_script: Script = instance.get_script()
	if scene_script == null:
		if print_errors:
			NFPluginGameHandler._log_msg(
					"settings",
					"Scene '%s' has no script attatched" % path,
					NFPluginGameHandler._LogLevel.ERROR)
		instance.free()
		return false
	
	var errors: Array[String] = []
	var static_methods: Array[Dictionary] = scene_script.get_script_method_list()
	var static_signals: Array[Dictionary] = scene_script.get_script_signal_list()
	var has_d_txt: bool = false
	var has_c_txt: bool = false
	var has_set_d: bool = false
	var has_set_c: bool = false
	
	for item_signal in static_signals:
		if item_signal["name"] == "dialog_text_changed":
			if item_signal["args"].size() == 1:
				var arg: Dictionary = item_signal["args"][0]
				has_d_txt = arg["type"] == TYPE_NIL or arg["type"] == TYPE_STRING
		elif item_signal["name"] == "choice_text_changed":
			if item_signal["args"].size() == 2:
				var arg_1: Dictionary = item_signal["args"][0]
				var arg_2: Dictionary = item_signal["args"][1]
				
				var arg_1_valid: bool = arg_1["type"] == TYPE_NIL or arg_1["type"] == TYPE_STRING
				var arg_2_valid: bool = arg_2["type"] == TYPE_NIL or arg_2["type"] == TYPE_INT
				
				has_c_txt = arg_1_valid and arg_2_valid
		
		if has_d_txt and has_c_txt:
			break
	
	for method in static_methods:
		if method["name"] == "set_choices":
			if not method["args"].is_empty():
				var arg: Dictionary = method["args"][0]
				var extra_valid: bool = true
				
				if 1 < method["args"].size():
					var default_size: int = method["default_args"].size()
					extra_valid = method["args"].size() - 1 <= default_size
				
				if arg["type"] == TYPE_NIL:
					has_set_c = extra_valid
				elif arg["type"] == TYPE_ARRAY:
					has_set_c = extra_valid and ( arg["hint_string"].is_empty() or arg["hint_string"] == "String" )
		elif method["name"] == "set_dialog":
			if not method["args"].is_empty():
				var arg: Dictionary = method["args"][0]
				var extra_valid: bool = true
				
				if 1 < method["args"].size():
					var default_size: int = method["default_args"].size()
					extra_valid = method["args"].size() - 1 <= default_size
				
				has_set_d = extra_valid and ( arg["type"] == TYPE_NIL or arg["type"] == TYPE_STRING )
		
		if has_set_c and has_set_d:
			break
	
	if not has_d_txt:
		errors.append("Scene has no valid \"dialog_text_changed\" signal")
	if not has_c_txt:
		errors.append("Scene has no valid \"choice_text_changed\" signal")
	if not has_set_d:
		errors.append("Scene has no valid \"set_dialog\" method")
	if not has_set_c:
		errors.append("Scene has no valid \"set_choices\" method")
	
	if not errors.is_empty() and print_errors:
		NFPluginGameHandler._log_msg(
				"settings",
				"Scene '%s' errored: %s" % [path, ", ".join(errors)],
				NFPluginGameHandler._LogLevel.ERROR)
	
	instance.free()
	return has_d_txt and has_c_txt and has_set_c and has_set_d


func verify_project_settings() -> void:
	var setting_order: Array[String] = []
	setting_order.assign(NFPluginGameHandler._SETTINGS_PATHS.keys())
	setting_order.sort_custom(_sort_custom_settings)
	
	for tool_id in setting_order:
		if not ProjectSettings.has_setting(NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"]):
			ProjectSettings.set_setting(
				NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"],
				NFPluginGameHandler._SETTINGS_PATHS[tool_id]["default_value"] if tool_id != "discourse_base_language" else OS.get_locale_language())
		
		if tool_id == "discourse_base_language":
			var set_setting: String = TranslationServer.standardize_locale(ProjectSettings.get_setting(NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"], ""))
			if not set_setting.is_empty():
				var parts: PackedStringArray = set_setting.split("_", false)
				var language: String = parts[0]
				
				if language != set_setting:
					ProjectSettings.set_setting(
					NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"],
					language)
			else:
				ProjectSettings.set_setting(
					NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"],
					OS.get_locale_language())
		elif tool_id == "discourse_use_languages":
			var set_setting: String = ProjectSettings.get_setting(NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"], "")
			if not set_setting.is_empty():
				var locales: PackedStringArray = StringUtils.split_and_strip(set_setting, ",", false)
				var valid_locales: Dictionary[String, Variant] = {}
				
				for locale in locales:
					var valid_code: String = TranslationServer.standardize_locale(locale)
					if valid_code.is_empty():
						continue
					
					var parts: PackedStringArray = valid_code.split("_", false)
					var lang: String = parts[0]
					var region: String = ""
					for idx in range(1, parts.size()):
						if parts[idx].length() == 2:
							region = parts[idx]
							break
					
					var locale_code: String = lang if region.is_empty() else lang + "_" + region
					
					if not valid_locales.has(locale_code):
						valid_locales[locale_code] = null
				
				ProjectSettings.set_setting(
						NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"],
						", ".join(PackedStringArray(valid_locales.keys())))
		elif tool_id == "discourse_custom_dialog_debug_scene":
			var path: String = ProjectSettings.get_setting(NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"], "")
			if not path.is_empty() and not FileAccess.file_exists(path):
				push_error(
						"[NEXUS FORGE] Custom debug scene \"" + path + "\" was not found.")
		elif tool_id == "discourse_localization_preview_scene":
			is_preview_scene_valid()
			
		
		ProjectSettings.set_initial_value(
				NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"],
				NFPluginGameHandler._SETTINGS_PATHS[tool_id]["default_value"] if tool_id != "discourse_base_language" else OS.get_locale_language())
		
		ProjectSettings.set_restart_if_changed(
				NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"],
				NFPluginGameHandler._SETTINGS_PATHS[tool_id]["restart_required"] if NFPluginGameHandler._SETTINGS_PATHS[tool_id].has("restart_required") else true)
		
		var property_info = {
			"name": NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"],
			"type": NFPluginGameHandler._SETTINGS_PATHS[tool_id]["type"],
			"hint": NFPluginGameHandler._SETTINGS_PATHS[tool_id]["hint"] if NFPluginGameHandler._SETTINGS_PATHS[tool_id].has("hint") else PROPERTY_HINT_NONE,
			"hint_string": NFPluginGameHandler._SETTINGS_PATHS[tool_id]["hint_string"] if NFPluginGameHandler._SETTINGS_PATHS[tool_id].has("hint_string") else ""}

		ProjectSettings.add_property_info(property_info)
		ProjectSettings.set_as_basic(
				NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"],
				NFPluginGameHandler._SETTINGS_PATHS[tool_id]["is_basic"] if NFPluginGameHandler._SETTINGS_PATHS[tool_id].has("is_basic") else true)
	
	var idx: int = -1
	for setting in setting_order:
		idx += 1
		ProjectSettings.set_order(NFPluginGameHandler._SETTINGS_PATHS[setting]["setting_path"], idx)
		
	ProjectSettings.save()


func _disable_plugin() -> void:
	remove_autoload_singleton("NexusForge")
	
	for tool_id in NFPluginGameHandler._SETTINGS_PATHS.keys():
		if ProjectSettings.has_setting(NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"]):
			ProjectSettings.set_setting(
					NFPluginGameHandler._SETTINGS_PATHS[tool_id]["setting_path"],
					null)
	
	ProjectSettings.save()


func _handles(object: Object) -> bool:
	if object is not Resource or object == null:
		return false
	
	var script: Script = object.get_script()
	if script == null:
		return false
		
	var script_global_name: StringName = script.get_global_name()
	var tool_available: bool = false
	
	match script_global_name:
		&"EditorDiscourseDialog":
			tool_available = editor_view.discourse != null
		&"CharacterSheet":
			if not character_map.has(object.resource_path):
				character_map[object.resource_path] = null
			tool_available = editor_view.characters != null
		&"PhraseMap":
			tool_available = editor_view.phrase_maps != null
		&"Quest":
			tool_available = editor_view.quests != null
	
	return HANDLED_CLASSES.has(script_global_name) and tool_available


func _edit(object: Object) -> void:
	if _editor_ready() and object != null:
		_make_visible(true)
		editor_view.handle_resource(object)


func _on_character_loaded(path: String) -> void:
	if not character_map.has(path):
		character_map[path] = null


func _editor_ready() -> bool:
	return editor_view != null and editor_view.is_node_ready()


func _on_resource_saved(resource: Resource) -> void:
	if resource is CharacterSheet:
		if not resource.resource_path.is_empty() and not character_map.has(resource.resource_path):
			character_map[resource.resource_path] = null
		return
	elif resource is not Script:
		return
	
	var script_class: StringName = resource.get_global_name()
	
	if script_class.is_empty():
		return
	elif script_class == &"StatBlock":
		editor_view.reload_stats()
	elif script_class == &"SkillSet":
		editor_view.reload_skills()
	elif script_class == &"TraitBlock":
		editor_view.reload_traits()
	elif script_class == &"CharacterSheet":
		editor_view.reload_character_sheet()
	elif script_class == &"ItemSheet":
		editor_view.reload_items()
	elif script_class == &"Quest":
		editor_view.reload_quest_data_types()
	elif script_class == &"QuestStage":
		editor_view.reload_quest_stage_types()
	elif script_class == &"QuestObjective":
		editor_view.reload_quest_objective_types()
	elif script_class == &"DiscourseAPI":
		editor_view.reload_discourse_api()


func _on_files_moved(old_file: String, new_file: String) -> void:
	if old_file.get_extension() != "tres":
		return
	
	if character_map.has(old_file):
		character_map[new_file] = null
		character_map.erase(old_file)
	
	if ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse"), "") == old_file:
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("discourse"), new_file)
		ProjectSettings.save()
		return
	elif ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("variables"), "") == old_file:
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("variables"), new_file)
		ProjectSettings.save()
		return
	elif ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("traits"), "") == old_file:
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("traits"), new_file)
		ProjectSettings.save()
		return
	elif ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("skills"), "") == old_file:
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("skills"), new_file)
		ProjectSettings.save()
		return
	elif ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("species"), "") == old_file:
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("species"), new_file)
		ProjectSettings.save()
		return
	elif ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("items"), "") == old_file:
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("items"), new_file)
		ProjectSettings.save()
		return
	elif ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("currency"), "") == old_file:
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("currency"), new_file)
		ProjectSettings.save()
		return
	elif ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("recipes"), "") == old_file:
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("recipes"), new_file)
		ProjectSettings.save()
		return
	
	var file = load(new_file)
	var mode: String = ""
	
	if file is Quest:
		mode = "-treestate-"
	elif file is EditorDiscourseDialog:
		mode = "-graphstate-"
	else:
		return
	
	var md5: String = old_file.md5_text()
	var config_file: String = old_file.get_file() + mode + md5 + ".cfg"
	var path: String = "res://.godot/editor/".path_join(config_file)
	if FileAccess.file_exists(path):
		var new_md5: String = new_file.md5_text()
		var new_path: String = "res://.godot/editor/".path_join(new_file.get_file() + mode + new_md5 + ".cfg")
		DirAccess.rename_absolute(old_file, new_path)


func _on_resource_removed(object: Resource) -> void:
	if object == null:
		return
	if object is EditorDiscourseDialog:
		editor_view.discourse.filesystem_resource_removed(object)
	elif object is CharacterSheet:
		character_map.erase(object.resource_path)
		editor_view.characters.filesystem_resource_removed(object)
	elif object is PhraseMap:
		editor_view.phrase_maps.filesystem_resource_removed(object)
	elif object is Quest:
		editor_view.quests.filesystem_resource_removed(object)
	elif object is BlackboardData:
		if editor_view.variables._variables_resource == object:
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("variables"),
					"")
			ProjectSettings.save()
			editor_view.variables.reload_resource()
	elif object is SpeciesCatalog:
		if editor_view.species._species_resource == object:
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("species"),
					"")
			ProjectSettings.save()
			editor_view.species.reload_resource()
	elif object is SkillCatalog:
		if editor_view.talents._skills_resource == object:
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("skills"),
					"")
			ProjectSettings.save()
			editor_view.talents.reload_skill_resource()
	elif object is TraitCatalog:
		if editor_view.talents._traits_resource == object:
			ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("traits"),
				"")
			ProjectSettings.save()
			editor_view.talents.reload_trait_resource()
	elif object is ItemCatalog:
		if editor_view.recipes_link.items == object:
			ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("items"),
				"")
			ProjectSettings.save()
			editor_view.items.items_container.reload_item_resource()
			editor_view.recipes.reload_items(null)
	elif object is CurrencyCatalog:
		if editor_view.items.items_container.currency_resource == object:
			ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("currency"),
				"")
			ProjectSettings.save()
			editor_view.items.items_container.reload_currency_resource()
	elif object is RecipeCatalog:
		if editor_view.recipes_link.recipes == object:
			ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("recipes"),
				"")
			ProjectSettings.save()
			editor_view.recipes.reload_recipe_resource()


func _on_scan_folder_selected() -> void:
	var confirmation: ConfirmationDialog = load("res://addons/nexus_forge/characters/characer_scanner_window.tscn").instantiate()
	confirmation.confirmed.connect(_on_scan_confirmed.bind(confirmation))
	confirmation.canceled.connect(_on_scan_canceled.bind(confirmation))
	EditorInterface.popup_dialog_centered(confirmation)


func _on_scan_confirmed(dialog: ConfirmationDialog) -> void:
	var dir_access: EditorFileDialog = load("res://addons/nexus_forge/classes/dir_file_dialog_editor.gd").new()
	EditorInterface.popup_dialog_centered(dir_access)
	
	var result: Array = await dir_access.dialog_finished
	
	if result[0] and DirAccess.dir_exists_absolute(result[1]):
		var log_msg: String = ""
		var found_files: Dictionary[String, StringName] = {}
		_scan_add_directory_for_characters(result[1], found_files)
		if found_files.is_empty():
			log_msg = "Scan finished. No character files found."
		else:
			character_map.merge(found_files, true)
			log_msg = "Scan Finished. %s character file(s) found." % found_files.size()
			
		NFPluginGameHandler._log_msg(
				"plugin",
				log_msg)
	
	dialog.queue_free()
	dir_access.queue_free()


func _scan_add_directory_for_characters(directory: String, _on: Dictionary[String, StringName]) -> void:
	for file in DirAccess.get_files_at(directory):
		if file.get_extension() != "tres":
			continue
		var path: String = directory.path_join(file)
		var res_load = load(path)
		if res_load != null and res_load is CharacterSheet:
			_on[path] = res_load.id
	
	for subdirectory in DirAccess.get_directories_at(directory):
		_scan_add_directory_for_characters(directory.path_join(subdirectory), _on)


func _on_scan_canceled(dialog: ConfirmationDialog) -> void:
	dialog.queue_free()


func save_character_paths() -> void:
	var valid_characters: Dictionary[String, Variant] = {}
	
	for res_path in character_map.keys():
		if not ResourceLoader.exists(res_path):
			character_map.erase(res_path)
			continue
		var char = load(res_path)
		if char == null or char is not CharacterSheet:
			continue
		valid_characters[res_path] = char.id
	
	if valid_characters != character_map:
		character_map.assign(valid_characters)
	
	var character_cfg: ConfigFile = ConfigFile.new()
	character_cfg.set_value("RUNTIME", "CharacterMap", valid_characters)
	
	if character_cfg.save("user://nexus_forge/persona_settings.cfg") != OK:
		print("Failed saving cfg")
