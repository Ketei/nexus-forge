extends EditorExportPlugin


# Generate the release files on export begin. These will be used later on _customize_resource
# The key is the path of the file, the value is the resource that will replace it.
var release_files: Dictionary[String, DiscourseDialog] = {}
var localization_groups: Dictionary = {}

# {"file_path": ["file": DiscourseDialogLocale, "path": res://i18n/en/aa/aaasdajlkd-my_file.json]}
var localization_files: Dictionary[String, Array] = {}

# Final map where the files are assigned to a non-conflicting ID.
var dialog_file_to_id: Dictionary[String, String] = {}

# Final map where non-conflicting IDs are assigned to a localization file.
var id_to_localization: Dictionary[String, String] = {}


var dialog_path: String = ""
var export_temp_dir: DirAccess = null

var character_ids: Dictionary[StringName, String] = {}
var quest_ids: Dictionary[StringName, String] = {}
var export_characters: bool = true

var added_files: Dictionary[String, Variant] = {}


func _get_name() -> String:
	return "NexusForgeExporter"


func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	export_temp_dir = DirAccess.create_temp("godot_nf_plugin")
	var file_base_path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("discourse")).strip_edges()
	
	release_files.clear()
	localization_groups.clear()
	localization_files.clear()
	dialog_file_to_id.clear()
	id_to_localization.clear()
	character_ids.clear()
	quest_ids.clear()
	added_files.clear()
	
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
	
	var new_id: String = ""
	var md5_hash: String = path.to_lower().md5_text().substr(0, 12)
	var localization_filename: String = md5_hash + "-" + path.get_file().get_basename() + ".json"
	var dialog_id: String = file.dialog_id.strip_edges().replace(" ", "_")
	
	if dialog_id.is_empty():
		var slug_id: String = _get_new_dialog_id_for(path)
		if id_to_localization.has(slug_id):
			new_id = path.md5_text()
		else:
			new_id = slug_id
	elif id_to_localization.has(dialog_id):
		var culprit: String = ""
		for filepath in dialog_file_to_id.keys():
			if dialog_file_to_id[filepath] == dialog_id:
				culprit = filepath
				break
		new_id = path.md5_text()
		NFPluginGameHandler._log_msg(
				"export",
				"Dialog ID '%s' already in use by '%s'. Changing ID of file '%s' to '%s'" % [file.dialog_id, culprit, path, new_id],
				NFPluginGameHandler._LogLevel.WARNING)
	else:
		new_id = dialog_id
		
	dialog_file_to_id[path] = new_id
	id_to_localization[new_id] = localization_filename
	
	release_files[path] = process_editor_discourse_dialog(file, new_id, localization_filename)


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
		if not localization_files.has(path):
			return release_files[path]
		
		for locale_entry:Dictionary in localization_files[path]:
			if locale_entry["path"].is_empty() or locale_entry["file"] == null:
				NFPluginGameHandler._log_msg(
						"export",
						"Failed to generate locale entry or path for '%s'." % path,
						NFPluginGameHandler._LogLevel.ERROR)
				continue
				
			#if localization_files.has(release_files[resource.resource_path].localization_uuid):
			var locale_file: DiscourseDialogLocale = locale_entry["file"]
			var virtual_path: String = locale_entry["path"]
			var file_path: String = export_temp_dir.get_current_dir().path_join(virtual_path.get_file())
			
			var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE_READ)
			file.store_string(locale_file.as_json())
			file.close()
			
			
				
			
			if file != null:
				if added_files.has(virtual_path):
					NFPluginGameHandler._log_msg(
						"export",
						"Exporter tried to add a duplicate file '%s' when exporting. Skipping." % virtual_path,
						NFPluginGameHandler._LogLevel.WARNING)
				else:
					added_files[virtual_path] = null
					add_file(
							virtual_path,
							FileAccess.get_file_as_bytes(file_path),
							false)
			else:
				NFPluginGameHandler._log_msg(
						"export",
						"Couldn't generate locale '%s' JSON for file '%s'" % [locale_file.locale, resource.resource_path],
						NFPluginGameHandler._LogLevel.ERROR)
		if path == "res://tests/test_dialog_exported.tres":
			ResourceSaver.save(release_files[path], "res://tests/aaa_test_dialog_exported.tres")
		return release_files[path]
	elif resource is SkillCatalog:
		return customize_skill_catalog(resource)
	elif resource is TraitCatalog:
		return customize_trait_catalog(resource)
	elif resource is SpeciesCatalog:
		return customize_species(resource)
	elif resource is StatCatalog:
		return customize_stat_catalog(resource)
	elif resource is CharacterSheet:
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
	elif resource is Quest:
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
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE_READ)
	file.store_string(JSON.stringify(bridge_data))
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
	
	if file != null:
		if added_files.has(virtual_path):
			NFPluginGameHandler._log_msg(
						"export",
						"Exporter tried to add a duplicate file '%s' when exporting. Skipping." % virtual_path,
						NFPluginGameHandler._LogLevel.WARNING)
		else:
			added_files[virtual_path] = null
			add_file(
					virtual_path,
					FileAccess.get_file_as_bytes(file_path),
					false)
	else:
		NFPluginGameHandler._log_msg(
				"export",
				"Error while generating dialog locale map.",
				NFPluginGameHandler._LogLevel.ERROR)


func process_editor_discourse_dialog(dialog_resource: EditorDiscourseDialog, dialog_id: String, expected_name: String) -> DiscourseDialog:
	var release_resource: DiscourseDialog = dialog_resource.convert_for_release()
	
	var localizations: Array[Dictionary] = dialog_resource.generate_localization_files(dialog_id, dialog_path, expected_name, localization_groups)
	
	if not localization_files.has(dialog_resource.resource_path):
		localization_files[dialog_resource.resource_path] = Array([], TYPE_DICTIONARY, &"", null)
	
	localization_files[dialog_resource.resource_path].append_array(localizations)
	
	return release_resource


func customize_species(resource: SpeciesCatalog) -> SpeciesCatalog:
	var stats: Dictionary[StringName, int] = StatBlock.stats()
	var skills: Array[StringName] = SkillSet.skills()
	var traits: Array[StringName] = TraitBlock.traits()
	
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


func customize_trait_catalog(catalog: TraitCatalog) -> TraitCatalog:
	var traits: Array[StringName] = TraitBlock.traits()
	
	for saved_trait in catalog._trait_data.keys():
		if traits.has(saved_trait):
			continue
		catalog._trait_data.erase(saved_trait)
	
	return catalog


func customize_stat_catalog(catalog: StatCatalog) -> StatCatalog:
	var stats_data: Dictionary[StringName, int] = StatBlock.stats()
	
	for saved_trait in catalog._stat_data.keys():
		if stats_data.has(saved_trait):
			continue
		catalog._stat_data.erase(saved_trait)
	
	return catalog


func customize_skill_catalog(catalog: SkillCatalog) -> SkillCatalog:
	var skills: Array[StringName] = SkillSet.skills()
	
	for saved_skill in catalog._skill_data.keys():
		if skills.has(saved_skill):
			continue
		catalog._skill_data.erase(saved_skill)
	
	return catalog


func _export_end() -> void:
	export_temp_dir = null
	
	release_files.clear()
	localization_groups.clear()
	localization_files.clear()
	dialog_file_to_id.clear()
	id_to_localization.clear()
	character_ids.clear()
	quest_ids.clear()
	added_files.clear()
