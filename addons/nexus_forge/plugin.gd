@tool
extends EditorPlugin


const MAIN_SCENE = preload("res://addons/nexus_forge/NexusForgeMainScene.tscn")
const PLUGIN_NAME: String = "NexusForge"
const PLUGIN_ICON_PATH: String = "res://addons/nexus_forge/icons/nexus_forge_small.svg"
const HANDLED_CLASSES: Array[StringName] = [&"EditorDiscourseDialog", &"NFCharacterSheet", &"NFPhraseMap", &"NFQuest"]
const TOOL_NAME: String = "Nexus Forge Character Lookup"

var editor_view: Control = null
var export_plugin: EditorExportPlugin = null
var tracked_characters: Array[Dictionary] = []
var tracker_edited: bool = false
var class_timestamps: RefCounted = null


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
	
	var script_editor: ScriptEditor = EditorInterface.get_script_editor()
	
	for path in SCRIPT_DOC:
		var script_file: Script = load(path)
		script_editor.update_docs_from_script(script_file) # Could this work better?


func _enter_tree() -> void:
	export_plugin = load("res://addons/nexus_forge/export_plugin.gd").new()
	add_export_plugin(export_plugin)
	verify_project_settings()
	if ProjectSettings.has_setting("autoload/NexusForge") and ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("recompile_documentation"), false):
		recompile_script_docs.call_deferred()
	if not DirAccess.dir_exists_absolute("user://nexus_forge/"):
		DirAccess.make_dir_recursive_absolute("user://nexus_forge/")
	editor_view = MAIN_SCENE.instantiate()
	editor_view.visible = false
	EditorInterface.get_editor_main_screen().add_child(editor_view)
	if not editor_view.is_node_ready():
		await editor_view.ready
	
	var script: Script = get_script()
	var version: String = ""
	if script != null:
		var dir: String = script.resource_path.get_base_dir()
		var config_path: String = dir.path_join("plugin.cfg")
		var cfg: ConfigFile = ConfigFile.new()
		if cfg.load(config_path) == OK:
			version = cfg.get_value("plugin", "version", "")
	
	if version.is_empty():
		editor_view.set_version("unknown version")
	else:
		editor_view.set_version(version)
	
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
	
	class_timestamps = load("res://addons/nexus_forge/script_path_store.gd").new()
	
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
			discourse_base_lang,
			class_timestamps)
	
	# Resotring previous session character data.
	if FileAccess.file_exists("user://nexus_forge/persona_settings.cfg"):
		var cfg: ConfigFile = ConfigFile.new()
		if cfg.load("user://nexus_forge/persona_settings.cfg") == OK:
			var data = cfg.get_value("RUNTIME", "CharacterMap")
			if typeof(data) == TYPE_ARRAY:
				for entry in data:
					if typeof(entry) != TYPE_DICTIONARY or not entry.has_all(["path", "character_id", "timestamp"]):
						continue
					var id_type: int = typeof(entry["character_id"])
					if typeof(entry["path"]) != TYPE_STRING:
						continue
					elif id_type != TYPE_STRING_NAME and id_type != TYPE_STRING:
						continue
					elif typeof(entry["timestamp"]) != TYPE_INT:
						continue
					if FileAccess.file_exists(entry["path"]):
						set_character_entry(
								entry["path"],
								entry["character_id"],
								entry["timestamp"])
	tracker_edited = false
	
	if use_discourse:
		editor_view.discourse.character_browser_requested.connect(_on_character_browser_requested)
	
	if use_characters:
		editor_view.characters.character_created.connect(_on_character_created)
		editor_view.characters.character_saved.connect(_on_character_saved)
		editor_view.characters.character_opened.connect(_on_character_opened)
	
	add_tool_menu_item(TOOL_NAME, _on_scan_folder_selected)
	
	resource_saved.connect(_on_resource_saved, CONNECT_DEFERRED)
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	fs.filesystem_changed.connect(_on_filesystem_changed)
	
	EditorInterface.get_file_system_dock().resource_removed.connect(_on_resource_removed)
	EditorInterface.get_file_system_dock().files_moved.connect(_on_files_moved, CONNECT_DEFERRED)


func _build() -> bool:
	var path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse"), "res://localization/").strip_edges()
	
	var valid_path: bool = path != "" and path.is_absolute_path() and path.begins_with("res://") and path.get_extension() == ""
	
	if not valid_path:
		NFPluginGameHandler._log_msg(
				"plugin",
				"Invalid localization path '%s'" % path,
				NFPluginGameHandler._LogLevel.ERROR)
	
	if ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("character_register_ids"), true):
		save_character_paths()
	
	return true


func _save_external_data() -> void:
	if _editor_ready():
		editor_view.save_resources()
	
	if tracker_edited:
		var character_cfg: ConfigFile = ConfigFile.new()
		character_cfg.set_value("RUNTIME", "CharacterMap", tracked_characters.duplicate(true))
		if character_cfg.save("user://nexus_forge/persona_settings.cfg") == OK:
			tracker_edited = false
		else:
			NFPluginGameHandler._log_msg(
					"plugin",
					"Failed saving character config to user://nexus_forge/persona_settings.cfg",
					NFPluginGameHandler._LogLevel.ERROR)


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
	var discourse_recent_files: Array[String] = editor_view.discourse.get_recenlty_opened_files() if editor_view.discourse != null else NFArrayUtils.create_typed(TYPE_STRING)
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


func _on_character_browser_requested(node_uuid: StringName, target: LineEdit) -> void:
	var data_to_populate: Dictionary[String, StringName] = {}
	
	for entry in tracked_characters:
		data_to_populate[entry["path"]] = entry["character_id"]
	
	var browser: Window = load("res://addons/nexus_forge/discourse/character_browser.tscn").instantiate()
	var initial_text: String = target.text
	EditorInterface.popup_dialog_centered(browser)
	browser.populate_characters(data_to_populate)
	browser.grab_search_focus()
	
	var result: Array = await browser.window_finished
	browser.queue_free()
	
	if not result[0] or result[1] == initial_text:
		return
	
	target.text = result[1]
	target.set_meta(&"old_value", result[1])
	editor_view.discourse._on_dialog_node_character_id_changed(node_uuid, initial_text, result[1])
	editor_view.discourse._on_conversation_changed()


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
				"discourse - editor",
				"Localization preview scene '%s' was not found" % path,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	var scene = load(path)
	if scene == null or not scene is PackedScene or not scene.can_instantiate():
		if print_errors:
			NFPluginGameHandler._log_msg(
					"discourse - editor",
					"Error during instantiation of scene '%s'" % path,
					NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	var instance: Node = scene.instantiate()
	var scene_script: Script = instance.get_script()
	if scene_script == null:
		if print_errors:
			NFPluginGameHandler._log_msg(
					"discourse - editor",
					"Scene '%s' has no script attatched" % path,
					NFPluginGameHandler._LogLevel.ERROR)
		instance.free()
		return false
	
	var errors: Array[String] = []
	var static_methods: Array[Dictionary] = scene_script.get_script_method_list()
	var static_signals: Array[Dictionary] = scene_script.get_script_signal_list()
	var has_c_updt: bool = false
	var has_set_d: bool = false
	var has_set_c: bool = false
	var has_p_txt: bool = false
	var has_p_ch: bool = false
	
	for method in static_methods:
		if method["name"] == "set_choices":
			if method["args"].is_empty():
				continue
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
			if method["args"].is_empty():
				continue
			var arg: Dictionary = method["args"][0]
			var extra_valid: bool = true
			
			if 1 < method["args"].size():
				var default_size: int = method["default_args"].size()
				extra_valid = method["args"].size() - 1 <= default_size
			
			has_set_d = extra_valid and ( arg["type"] == TYPE_NIL or arg["type"] == TYPE_STRING )
		elif method["name"] == "update_choice":
			if method["args"].size() < 2:
				continue
			var idx_arg: Dictionary = method["args"][0]
			var txt_arg: Dictionary = method["args"][1]
			var extra_valid: bool = true
			
			if 1 < method["args"].size():
				var default_size: int = method["default_args"].size()
				extra_valid = method["args"].size() - 2 <= default_size
			
			if (idx_arg["type"] == TYPE_INT or idx_arg["type"] == TYPE_NIL or idx_arg["type"] == TYPE_FLOAT) and (txt_arg["type"] == TYPE_STRING or txt_arg["type"] == TYPE_NIL):
				has_c_updt = extra_valid
		elif method["name"] == "play_dialog":
			if method["args"].is_empty():
				continue
			var arg: Dictionary = method["args"][0]
			var extra_valid: bool = true
			
			if 1 < method["args"].size():
				var default_size: int = method["default_args"].size()
				extra_valid = method["args"].size() - 1 <= default_size
			
			has_p_txt = extra_valid and ( arg["type"] == TYPE_STRING or arg["type"] == TYPE_NIL )
		elif method["name"] == "play_choices":
			if method["args"].is_empty():
				continue
			var arg: Dictionary = method["args"][0]
			var extra_valid: bool = true
			
			if 1 < method["args"].size():
				var default_size: int = method["default_args"].size()
				extra_valid = method["args"].size() - 1 <= default_size
			
			if arg["type"] == TYPE_NIL:
				has_p_ch = extra_valid
			elif arg["type"] == TYPE_ARRAY:
				has_p_ch = extra_valid and ( arg["hint_string"].is_empty() or arg["hint_string"] == "String" )
		
		if has_set_c and has_set_d and has_c_updt and has_p_txt and has_p_ch:
			break
	
	if not has_c_updt:
		errors.append("Scene has no valid 'update_choice'\"' method.")
	if not has_set_d:
		errors.append("Scene has no valid 'set_dialog' method.")
	if not has_set_c:
		errors.append("Scene has no valid 'set_choices' method.")
	if not has_p_txt:
		errors.append("Scene has no valid 'play_dialog' method.")
	if not has_p_ch:
		errors.append("Scene has no valid 'play_choices' method.")
	
	if not errors.is_empty() and print_errors:
		NFPluginGameHandler._log_msg(
				"discourse - editor",
				"Scene '%s' errored: %s" % [path, ", ".join(errors)],
				NFPluginGameHandler._LogLevel.ERROR)
	
	instance.free()
	return has_c_updt and has_set_c and has_set_d and has_p_txt and has_p_ch


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
				var locales: PackedStringArray = NFStringUtils.split_and_strip(set_setting, ",", false)
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
				NFPluginGameHandler._log_msg(
						"plugin",
						"Custom debug scene was not found at '%s'" % path,
						NFPluginGameHandler._LogLevel.ERROR)
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
		&"NFCharacterSheet":
			set_character_entry(object.resource_path, object.id)
			tool_available = editor_view.characters != null
		&"NFPhraseMap":
			tool_available = editor_view.phrase_maps != null
		&"NFQuest":
			tool_available = editor_view.quests != null
	
	return HANDLED_CLASSES.has(script_global_name) and tool_available


func _edit(object: Object) -> void:
	if _editor_ready() and object != null:
		EditorInterface.set_main_screen_editor(PLUGIN_NAME)
		editor_view.handle_resource(object)


func _on_character_created(path: String) -> void:
	# ID is still not assigned, only the resource was created
	set_character_entry(path)


func _editor_ready() -> bool:
	return editor_view != null and editor_view.is_node_ready()


func _on_character_saved(path: String, id: StringName) -> void:
	set_character_entry(path, id, FileAccess.get_modified_time(path))


func _on_character_opened(path: String, id: StringName) -> void:
	set_character_entry(path, id)


func _on_resource_saved(resource: Resource) -> void:
	if resource is NFCharacterSheet:
		if not resource.resource_path.is_empty() and resource.resource_path.get_extension() == "tres":
			set_character_entry(resource.resource_path, resource.id, FileAccess.get_modified_time(resource.resource_path))
		return
	elif resource is not Script:
		return
	
	var script_class: StringName = resource.get_global_name()
	
	if script_class.is_empty():
		return
	class_timestamps.validate_update(String(script_class), resource.resource_path)


func _on_filesystem_changed():
	class_timestamps.check_for_updates()
	scan_for_character_changes()


func _on_files_moved(old_file: String, new_file: String) -> void:
	if old_file.get_extension() != "tres":
		return
	
	change_character_path(old_file, new_file)
	
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
	
	if file is NFQuest:
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
	elif object is NFCharacterSheet:
		remove_character(object.resource_path)
		editor_view.characters.filesystem_resource_removed(object)
	elif object is NFPhraseMap:
		editor_view.phrase_maps.filesystem_resource_removed(object)
	elif object is NFQuest:
		editor_view.quests.filesystem_resource_removed(object)
	elif object is NFBlackboardData:
		if editor_view.variables._variables_resource == object:
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("variables"),
					"")
			ProjectSettings.save()
			editor_view.variables.reload_resource()
	elif object is NFSpeciesCatalog:
		if editor_view.species._species_resource == object:
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("species"),
					"")
			ProjectSettings.save()
			editor_view.species.reload_resource()
	elif object is NFSkillCatalog:
		if editor_view.talents._skills_resource == object:
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("skills"),
					"")
			ProjectSettings.save()
			editor_view.talents.reload_skill_resource()
	elif object is NFTraitCatalog:
		if editor_view.talents._traits_resource == object:
			ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("traits"),
				"")
			ProjectSettings.save()
			editor_view.talents.reload_trait_resource()
	elif object is NFItemCatalog:
		if editor_view.recipes_link.items == object:
			ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("items"),
				"")
			ProjectSettings.save()
			editor_view.items.items_container.reload_item_resource()
			editor_view.recipes.reload_items(null)
	elif object is NFCurrencyCatalog:
		if editor_view.items.items_container.currency_resource == object:
			ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("currency"),
				"")
			ProjectSettings.save()
			editor_view.items.items_container.reload_currency_resource()
	elif object is NFRecipeCatalog:
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
	dialog.queue_free()
	dir_access.queue_free()
	
	if not result[0] or not DirAccess.dir_exists_absolute(result[1]):
		return
	
	var log_msg: String = ""
	var found_files: Dictionary[String, StringName] = discover_character_sheets(result[1])
	
	if found_files.is_empty():
		log_msg = "Scan finished. No character files found."
	else:
		for path in found_files:
			set_character_entry(path, found_files[path], FileAccess.get_modified_time(path))
		log_msg = "Scan Finished. %s character file(s) found." % found_files.size()
		
	NFPluginGameHandler._log_msg(
			"plugin",
			log_msg)


func _on_scan_canceled(dialog: ConfirmationDialog) -> void:
	dialog.queue_free()


func save_character_paths() -> void:
	if tracked_characters.is_empty():
		return
	
	var new_entries: Array[Dictionary] = []
	var performed_changes: bool = false
	
	for entry in tracked_characters:
		if not ResourceLoader.exists(entry["path"]):
			performed_changes = true
			continue
		
		var file_timestamp: int = FileAccess.get_modified_time(entry["path"])
		if file_timestamp == entry["timestamp"]:
			new_entries.append(entry)
			continue
		else:
			var data: Dictionary = parse_character_file(entry["path"])
			if data["is_character"]:
				var new_entry: Dictionary[String, Variant] = {
					"path": entry["path"],
					"character_id": data["id"],
					"timestamp": file_timestamp}
				new_entries.append(new_entry)
			performed_changes = true
	
	if not performed_changes:
		return
	
	tracked_characters.assign(new_entries)
	
	var character_cfg: ConfigFile = ConfigFile.new()
	character_cfg.set_value("RUNTIME", "CharacterMap", new_entries)
	if character_cfg.save("user://nexus_forge/persona_settings.cfg") == OK:
		tracker_edited = false
	else:
		NFPluginGameHandler._log_msg(
				"plugin",
				"Failed saving character config to user://nexus_forge/persona_settings.cfg",
				NFPluginGameHandler._LogLevel.WARNING)
	


func discover_character_sheets(on_path: String = "") -> Dictionary[String, StringName]:
	var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	var sys_directory: EditorFileSystemDirectory = efs.get_filesystem() if on_path.is_empty() else efs.get_filesystem_path(on_path)
	var character_sheets: Dictionary[String, StringName] = {}
	
	if sys_directory != null:
		_traverse_for_character_resources(sys_directory, character_sheets)
	
	return character_sheets


func _traverse_for_character_resources(dir: EditorFileSystemDirectory, results: Dictionary[String, StringName]) -> void:
	for index in range(dir.get_file_count()):
		var path: String = dir.get_file_path(index)
		if path.get_extension() == "tres":
			var res_data: Dictionary = parse_character_file(path)
			if res_data["is_character"]:
				results[path] = res_data["id"]
		
		for sub_index in range(dir.get_subdir_count()):
			_traverse_for_character_resources(dir.get_subdir(sub_index), results)


func parse_character_file(file_path: String, id_property: String = "id") -> Dictionary:
	var data: Dictionary = {"is_character": false, "id": &""}
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		return data

	var is_valid_class: bool = false
	var in_main_resource: bool = false
	
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		
		if line.is_empty():
			continue
			
		if not is_valid_class:
			if line.begins_with("[gd_resource"):
				if "script_class=\"NFCharacterSheet\"" in line:
					data["is_character"] = true
					is_valid_class = true
					continue
				else:
					return data 
			continue 
		
		if not in_main_resource:
			if line == "[resource]":
				in_main_resource = true
			continue
		
		if in_main_resource:
			if line.begins_with("["):
				return data 
			
			if line.begins_with(id_property + " =") or line.begins_with(id_property + "="):
				var parts: PackedStringArray = line.split("=", true, 1)
				if parts.size() == 2:
					var id_value: String = parts[1].strip_edges()
					data["id"] = id_value.trim_prefix("&\"").trim_suffix("\"")
					return data
	
	return data


func scan_for_character_changes() -> void:
	for idx in range(tracked_characters.size() - 1, -1, -1):
		if FileAccess.file_exists(tracked_characters[idx]["path"]):
			var dict: Dictionary = tracked_characters[idx]
			var timestamp: int = FileAccess.get_modified_time(dict["path"])
			if timestamp != dict["timestamp"]:
				var char_data = parse_character_file(dict["path"])
				if char_data["is_character"]:
					dict["timestamp"] = timestamp
					dict["character_id"] = char_data["id"]
				else:
					tracked_characters.remove_at(idx)
				tracker_edited = true
		else:
			tracked_characters.remove_at(idx)
			tracker_edited = true


func set_character_entry(path: String, character_id: StringName = &"", timestamp: int = -1) -> void:
	if not ResourceLoader.exists(path):
		return
	
	for item in tracked_characters:
		if item["path"] == path:
			if item["character_id"] != character_id:
				item["character_id"] = character_id
				tracker_edited = true
			
			if 0 < timestamp:
				if item["timestamp"] != timestamp:
					tracker_edited = true
					item["timestamp"] = timestamp
			
			return
	
	var new_entry: Dictionary[String, Variant] = {
		"path": path,
		"character_id": character_id,
		"timestamp": FileAccess.get_modified_time(path) if timestamp < 0 else timestamp}
	tracked_characters.append(new_entry)
	tracker_edited = true


func change_character_path(old_path: String, new_path: String) -> void:
	for item in tracked_characters:
		if item["path"] == old_path:
			item["path"] = new_path
			tracker_edited = true
			return


func remove_character(path: String) -> void:
	for idx in range(tracked_characters.size()):
		if tracked_characters[idx]["path"] == path:
			tracked_characters.remove_at(idx)
			tracker_edited = true
			return
