extends EditorExportPlugin


# Generate the release files on export begin. These will be used later on _customize_resource
# The key is the path of the file, the value is the resource that will replace it.
var release_files: Dictionary[String, DiscourseDialog] = {}
var localization_groups: Dictionary = {}

# {"file_path": ["file": DiscourseDialogLocale, "path": res://i18n/en/aa/aaasdajlkd-my_file.json]}
var localization_files: Dictionary[String, Array] = {}

# Final map where the files are assigned to a non-conflicting ID.
var dialog_file_to_id: Dictionary[String, String] = {}
var id_to_dialog_file: Dictionary[String, String] = {}

# Final map where non-conflicting IDs are assigned to a localization file.
var id_to_localization: Dictionary[String, String] = {}


var dialog_path: String = ""
var export_temp_dir: DirAccess = null

var character_ids: Dictionary[StringName, String] = {}
var quest_ids: Dictionary[StringName, String] = {}
var export_characters: bool = true

var added_files: Dictionary[String, Variant] = {}
var discourse_api_methods: Dictionary[StringName, Dictionary] = {}


func _get_name() -> String:
	return "NexusForgeExporter"


func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	clear_memory()
	
	var discourse_api_found: bool = false
	var api_path: String = ""
	
	var all_classes: Array[Dictionary] = ProjectSettings.get_global_class_list()
	for class_entry in all_classes:
		if class_entry["class"] == "DiscourseAPI":
			api_path = class_entry["path"]
			break
	
	if not api_path.is_empty():
		var api_script: Script = load(api_path)
		if api_script != null:
			for method in api_script.get_script_method_list():
				discourse_api_methods[StringName(method["name"])] = method
			discourse_api_found = true
	
	if not discourse_api_found:
		NFPluginGameHandler._log_msg(
				"export",
				"Couldn't locate DiscourseAPI script file.",
				NFPluginGameHandler._LogLevel.ERROR)
	
	export_temp_dir = DirAccess.create_temp("godot_nf_plugin")
	var file_base_path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse")).strip_edges()
	
	export_characters = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("characters_id_to_files"),
			true)
	
	if not file_base_path.ends_with("/"):
		file_base_path += "/"
	
	dialog_path = file_base_path


func _get_new_dialog_id_for(path: String) -> String:
	var slug: String = path.get_basename().trim_prefix("res://").replace("/", ".").replace("\\", ".")
	
	return path.md5_text() if id_to_localization.has(slug) else slug


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if path.get_extension() != "tres":
		return
	
	if release_files.has(path):
		return
		
	var file: Resource = load(path)
	if file is not EditorDiscourseDialog:
		return
	
	var md5_hash: String = path.to_lower().md5_text().substr(0, 12)
	var localization_filename: String = md5_hash + "-" + path.get_file().get_basename() + ".json"
	var new_id: String = _get_valid_dialog_id(file.dialog_id, file.resource_path)
	
	dialog_file_to_id[path] = new_id
	id_to_dialog_file[new_id] = path
	id_to_localization[new_id] = localization_filename
	
	release_files[path] = process_editor_discourse_dialog(file, new_id, localization_filename)


func _get_valid_dialog_id(desired: String, path: String) -> String:
	var dialog_id: String = desired.strip_edges().replace(" ", "_")
	var new_id: String = ""
	
	if dialog_id.is_empty():
		var slug_id: String = _get_new_dialog_id_for(path)
		if id_to_localization.has(slug_id):
			new_id = path.md5_text()
		else:
			new_id = slug_id
	elif id_to_localization.has(dialog_id):
		var culprit: String = id_to_dialog_file.get(dialog_id, "Unknown")
		new_id = path.md5_text()
		NFPluginGameHandler._log_msg(
				"export",
				"Dialog ID '%s' already in use by '%s'. Changing ID of file '%s' to '%s'" % [dialog_id, culprit, path, new_id],
				NFPluginGameHandler._LogLevel.WARNING)
	else:
		new_id = dialog_id
	
	return new_id


func _begin_customize_resources(_platform: EditorExportPlatform, _features: PackedStringArray) -> bool:
	return true


func _get_customization_configuration_hash() -> int:
	# From my understanding, creating a hash would require scanning the whole
	# directory to find all dialog files,
	# hash the file and store it in a dictionary along with their
	# path {"res://dialog.tres": 123445} and then return the hash of that
	# dictionary. I think that this is maybe more intensive
	# than just regenerating all dialog resources.
	return randi()


func _customize_resource(resource: Resource, path: String) -> Resource:
	if resource is EditorDiscourseDialog:
		var res_key: String = resource.resource_path
		
		if resource.resource_path.is_empty():
			NFPluginGameHandler._log_msg(
					"export",
					"Embedded EditorDiscourseDialog found in scene '%s'. Embedded dialogs are not supported by the runtime API. Please save it as an external .tres file." % path,
					NFPluginGameHandler._LogLevel.ERROR)
			return null
		
		if not release_files.has(res_key):
			var dialog_id: String = _get_valid_dialog_id(resource.dialog_id, res_key)
			var md5_hash: String = dialog_id.md5_text().substr(0, 12)
			var loc_filename: String = md5_hash + "-" + res_key.get_file().get_basename() + ".json"
			
			release_files[res_key] = process_editor_discourse_dialog(resource, dialog_id, loc_filename)
		
		var loc_key: String = res_key
		
		if not localization_files.has(loc_key):
			return release_files[res_key]
		
		for locale_entry:Dictionary in localization_files[loc_key]:
			if locale_entry["path"].is_empty() or locale_entry["file"] == null:
				NFPluginGameHandler._log_msg(
						"export",
						"Failed to generate locale entry or path for '%s'." % path,
						NFPluginGameHandler._LogLevel.ERROR)
				continue
				
			var locale_file: DiscourseDialogLocale = locale_entry["file"]
			var virtual_path: String = locale_entry["path"]
			
			if added_files.has(virtual_path):
				NFPluginGameHandler._log_msg(
					"export",
					"Exporter tried to add a duplicate file '%s' when exporting. Skipping." % virtual_path,
					NFPluginGameHandler._LogLevel.WARNING)
				continue
			
			var file_path: String = export_temp_dir.get_current_dir().path_join(virtual_path.get_file())
			
			var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
			if file == null:
				NFPluginGameHandler._log_msg(
						"export",
						"Couldn't generate locale '%s' JSON for file '%s'. Error: %s" % [locale_file.locale, resource.resource_path, FileAccess.get_open_error()],
						NFPluginGameHandler._LogLevel.ERROR)
				continue
			
			if not file.store_string(locale_file.as_json()):
				NFPluginGameHandler._log_msg(
						"export",
						"Couldn't write data on file '%s'." % file_path,
						NFPluginGameHandler._LogLevel.ERROR)
			file.close()
			
			added_files[virtual_path] = null
			# Add file, for some reason, doesn't like it when you give it bynary
			# data that exists only in memory. And I kept finding that the export
			# files always were one behind when doing memory only.
			# e.g.
			# 	> Export A was supposed to export a.json, but exported nothing
			# 	> Change a.tres to b.tres
			# 	> Trigger export. PCK now contains a.json, should contain b.json instead
			# 	> Change b.tres to c.tres
			# 	> Exporter is now storing b.json instead of c.json
			# Only way I found to FORCE it to store the right files was using
			# FileAccess.get_file_as_bytes. If I'm doing something wrong
			# let me know.
			# Note: The files being added are being generated and stored in memory
			# when _export_file runs. They are being writen to disk and added to the
			# pck in here. When export is done, the files should NOT persist. This
			# means they need to be deleted somehow.
			add_file(
					virtual_path,
					FileAccess.get_file_as_bytes(file_path),
					false)
		return release_files[res_key]
	elif resource is NFSkillCatalog:
		return customize_skill_catalog(resource)
	elif resource is NFTraitCatalog:
		return customize_trait_catalog(resource)
	elif resource is NFSpeciesCatalog:
		return customize_species(resource)
	elif resource is NFStatCatalog:
		return customize_stat_catalog(resource)
	elif resource is NFCharacterSheet:
		if character_ids.has(resource.id):
			if export_characters:
				NFPluginGameHandler._log_msg(
						"export",
						"Resource '%s' has the same ID of registered resource '%s'. Skipping registration." % [path, character_ids[resource.id]],
						NFPluginGameHandler._LogLevel.WARNING)
			else:
				NFPluginGameHandler._log_msg(
						"export",
						"Resource '%s' has the same ID of resource '%s'." % [path, character_ids[resource.id]],
						NFPluginGameHandler._LogLevel.WARNING)
		else:
			character_ids[resource.id] = path
	elif resource is NFQuest:
		if quest_ids.has(resource.id):
			NFPluginGameHandler._log_msg(
						"export",
						"Quest resource '%s' has the same ID of '%s'" % [path, quest_ids[resource.id]],
						NFPluginGameHandler._LogLevel.WARNING)
		else:
			quest_ids[resource.id] = path
		
		if not resource.has_stage(resource.entry_stage):
			NFPluginGameHandler._log_msg(
						"export",
						"Quest resource '%s' entry stage '%s' isn't valid." % [path, resource.entry_stage],
						NFPluginGameHandler._LogLevel.WARNING)
	return null


func _end_customize_resources() -> void:
	var bridge_data: Dictionary = {
		"file_to_id": dialog_file_to_id,
		"id_to_locale_file": id_to_localization}
	
	var virtual_path: String = dialog_path.path_join("dialog_locale_map.json")
	var file_path: String = export_temp_dir.get_current_dir().path_join(virtual_path.get_file())
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		NFPluginGameHandler._log_msg(
				"export",
				"Error while generating dialog locale map. Error: %s" % FileAccess.get_open_error(),
				NFPluginGameHandler._LogLevel.ERROR)
	else:
		if file.store_string(JSON.stringify(bridge_data)):
			if added_files.has(virtual_path):
				NFPluginGameHandler._log_msg(
						"export",
						"Exporter tried to add a duplicate file '%s' when exporting. Skipping." % virtual_path,
						NFPluginGameHandler._LogLevel.WARNING)
			else:
				added_files[virtual_path] = null
				# Add file, for some reason, doesn't like it when you give it bynary
				# data that exists only in memory. And I kept finding that the export
				# files always were one behind when doing memory only.
				# e.g.
				# 	> Export A with data X. Was supposed to generate a.json, but exported nothing.
				# 	> Change data X to Y.
				# 	> Trigger export. PCK now contains a.json but with data X.
				# 	> Change data Y to Z.
				# 	> Exporter is now storing Y instead of Z.
				# Only way I found to FORCE it to store the right files was using
				# FileAccess.get_file_as_bytes. If I'm doing something wrong
				# let me know.
				add_file(
						virtual_path,
						FileAccess.get_file_as_bytes(file_path),
						false)
		else:
			NFPluginGameHandler._log_msg(
					"export",
					"Couldn't write dialog locale map to file '%s'" % file_path,
					NFPluginGameHandler._LogLevel.ERROR)
		file.close()
	
	if export_characters:
		var config_path: String = export_temp_dir.get_current_dir().path_join("settings.cfg")
		var cfg: ConfigFile = ConfigFile.new()
		cfg.set_value("PERSONA", "CharacterMap", character_ids)
		if cfg.save(config_path) == OK:
			if added_files.has("res://addons/nexus_forge/settings.cfg"):
				NFPluginGameHandler._log_msg(
						"export",
						"Exporter tried to add a duplicate file 'res://addons/nexus_forge/settings.cfg' when exporting. Skipping.",
						NFPluginGameHandler._LogLevel.WARNING)
			else:
				added_files["res://addons/nexus_forge/settings.cfg"] = null
				add_file(
						"res://addons/nexus_forge/settings.cfg",
						FileAccess.get_file_as_bytes(config_path),
						false)


func process_editor_discourse_dialog(dialog_resource: EditorDiscourseDialog, dialog_id: String, expected_name: String) -> DiscourseDialog:
	var release_resource: DiscourseDialog = dialog_resource.convert_for_release(discourse_api_methods)
	
	var localizations: Array[Dictionary] = dialog_resource.generate_localization_files(dialog_id, dialog_path, expected_name, localization_groups)
	
	if not localization_files.has(dialog_resource.resource_path):
		localization_files[dialog_resource.resource_path] = Array([], TYPE_DICTIONARY, &"", null)
	
	localization_files[dialog_resource.resource_path].append_array(localizations)
	
	return release_resource


func customize_species(resource: NFSpeciesCatalog) -> NFSpeciesCatalog:
	var stats: Dictionary[StringName, int] = NFStatBlock.stats()
	var skills: Array[StringName] = NFSkillSet.skills()
	var traits: Array[StringName] = NFTraitBlock.traits()
	
	for species in resource._species.keys():
		for stat in resource._species[species]["stats"].keys():
			if stats.has(stat):
				continue
			resource._species[species]["stats"].erase(stat)
		
		for skill in resource._species[species]["skills"].keys():
			if skills.has(skill):
				continue
			resource._species[species]["skills"].erase(skill)
		
		for trait_id in resource._species[species]["traits"].keys():
			if traits.has(trait_id):
				continue
			resource._species[species]["traits"].erase(trait_id)
	
	return resource


func customize_trait_catalog(catalog: NFTraitCatalog) -> NFTraitCatalog:
	var traits: Array[StringName] = NFTraitBlock.traits()
	
	for saved_trait in catalog._trait_data.keys():
		if traits.has(saved_trait):
			continue
		catalog._trait_data.erase(saved_trait)
	
	return catalog


func customize_stat_catalog(catalog: NFStatCatalog) -> NFStatCatalog:
	var stats_data: Dictionary[StringName, int] = NFStatBlock.stats()
	
	for saved_trait in catalog._stat_data.keys():
		if stats_data.has(saved_trait):
			continue
		catalog._stat_data.erase(saved_trait)
	
	return catalog


func customize_skill_catalog(catalog: NFSkillCatalog) -> NFSkillCatalog:
	var skills: Array[StringName] = NFSkillSet.skills()
	
	for saved_skill in catalog._skill_data.keys():
		if skills.has(saved_skill):
			continue
		catalog._skill_data.erase(saved_skill)
	
	return catalog


func _export_end() -> void:
	export_temp_dir = null
	clear_memory()


func clear_memory() -> void:
	release_files.clear()
	localization_groups.clear()
	localization_files.clear()
	dialog_file_to_id.clear()
	id_to_localization.clear()
	character_ids.clear()
	quest_ids.clear()
	added_files.clear()
	discourse_api_methods.clear()
	id_to_dialog_file.clear()
