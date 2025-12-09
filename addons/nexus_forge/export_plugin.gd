extends EditorExportPlugin


var localization_paths: Array[Dictionary] = []
var localization_map: Dictionary[String, Dictionary] = {}


var locale_group_uuids: Dictionary[String, String] = {}
var localization_files: Dictionary[String, DiscourseDialogLocale] = {}
var release_files: Dictionary[String, ReleaseDiscourseDialog] = {}

var dialog_path: String = ""
var export_temp_dir: DirAccess = null


func _get_name() -> String:
	return "NexusForgeExporter"


func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	export_temp_dir = DirAccess.create_temp("godot_nf_plugin")
	var file_base_path: String = ProjectSettings.get_setting(
			EditorNFPlugin.get_project_settings_path("discourse")).strip_edges()
	
	localization_paths.clear()
	localization_map.clear()
	locale_group_uuids.clear()
	localization_files.clear()
	release_files.clear()
	
	if not file_base_path.ends_with("/"):
		file_base_path += "/"
	
	dialog_path = file_base_path


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if path.get_extension() == "tres":
		var file: Resource = load(path)
		if file is EditorDiscourseDialog:
			release_files[path] = process_editor_discourse_dialog(file)


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


func _customize_resource(resource: Resource, _path: String) -> Resource:
	if resource is EditorDiscourseDialog:# == &"EditorDiscourseDialog":
		if release_files.has(resource.resource_path):
			#print("Returned a previously generated resource")
			if localization_files.has(release_files[resource.resource_path].localization_uuid):
				#print("Localization file exists!")
				var locale_file: DiscourseDialogLocale = localization_files[release_files[resource.resource_path].localization_uuid]
				var virtual_path: String = locale_file.resource_path.get_basename() + ".json"
				var file_path: String = export_temp_dir.get_current_dir() + "/" + locale_file.resource_path.get_file().get_basename() + ".json"
				var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE_READ)
				file.store_string(locale_file.as_json())
				file.close()
				
				if file != null:
					add_file(
							virtual_path,
							FileAccess.get_file_as_bytes(file_path),
							false)
					localization_files.erase(release_files[resource.resource_path].localization_uuid)
			return release_files[resource.resource_path]
		else:
			return null
	elif resource is SkillCatalog:
		return customize_skill_catalog(resource)
	elif resource is TraitCatalog:
		return customize_trait_catalog(resource)
	elif resource is SpeciesCatalog:
		return customize_species(resource)
	return null


func process_editor_discourse_dialog(dialog_resource: EditorDiscourseDialog) -> ReleaseDiscourseDialog:
	# Assigning an UUID if the group already exists, if not remains empty so
	# EditorDiscourseDialog.convert_for_release() generates an unique one.
	var locale_uuid: String = locale_group_uuids[dialog_resource.locale_group] if locale_group_uuids.has(dialog_resource.locale_group) else ""
	var release_resource: ReleaseDiscourseDialog = dialog_resource.convert_for_release(locale_uuid)
	release_files[dialog_resource.resource_path] = release_resource
	# If there is a locale_group but it is not mapped yet, then map it.
	if not dialog_resource.locale_group.is_empty() and not locale_group_uuids.has(dialog_resource.locale_group):
		locale_group_uuids[dialog_resource.locale_group] = release_resource.localization_uuid
	
	var localization_group: Dictionary[String, DiscourseDialogLocale] = {}
	var uses_locale_group: bool = not dialog_resource.locale_group.is_empty()
	
	 # For the purposes of updating.
	if localization_map.has(dialog_resource.locale_group):
		localization_group = localization_map[dialog_resource.locale_group]
	
	 # dialog_resource.generate_localization_files return array will ONLY contain
	 # newly created files, the ones updated through localization_group won't be
	 # returned.
	var new_localization: Array[DiscourseDialogLocale] = dialog_resource.generate_localization_files(
			release_resource.localization_uuid,
			dialog_path,
			localization_group)
	
	if uses_locale_group:
		if not localization_map.has(dialog_resource.locale_group):
			var new_map: Dictionary[String, DiscourseDialogLocale] = {}
			localization_map[dialog_resource.locale_group] = new_map
		for locale in new_localization:
			localization_map[dialog_resource.locale_group][locale.language + "-" + locale.region] = locale
	
	for locale_file in new_localization:
		localization_files[release_resource.localization_uuid] = locale_file
	
	return release_resource


func customize_species(resource: SpeciesCatalog) -> SpeciesCatalog:
	var stats: Array[StringName] = []
	stats.assign(StatBlock.stats().keys())
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
	
	for saved_trait in catalog._traits.keys():
		if traits.has(saved_trait):
			continue
		catalog._traits.erase(saved_trait)
	
	return catalog


func customize_skill_catalog(catalog: SkillCatalog) -> SkillCatalog:
	var skills: Array[StringName] = SkillSet.skills()
	
	for saved_skill in catalog._skills.keys():
		if skills.has(saved_skill):
			continue
		catalog._skills.erase(saved_skill)
	
	return catalog


func customize_discourse_dialog(resource: EditorDiscourseDialog) -> ReleaseDiscourseDialog:
	# Establishing the class for auto-complete
	var dialog_resource: EditorDiscourseDialog = resource
	
	# Assigning an UUID if the group already exists, if not remains empty so
	# EditorDiscourseDialog.convert_for_release() generates an unique one.
	var locale_uuid: String = locale_group_uuids[dialog_resource.locale_group] if locale_group_uuids.has(dialog_resource.locale_group) else ""
	var release_resource: ReleaseDiscourseDialog = dialog_resource.convert_for_release(locale_uuid)
	# If there is a locale_group but it is not mapped yet, then map it.
	if not dialog_resource.locale_group.is_empty() and not locale_group_uuids.has(dialog_resource.locale_group):
		locale_group_uuids[dialog_resource.locale_group] = release_resource.localization_uuid
	
	var localization_group: Dictionary[String, DiscourseDialogLocale] = {}
	var uses_locale_group: bool = not dialog_resource.locale_group.is_empty()
	
	 # For the purposes of updating.
	if localization_map.has(dialog_resource.locale_group):
		localization_group = localization_map[dialog_resource.locale_group]
	
	 # dialog_resource.generate_localization_files return array will ONLY contain
	 # newly created files, the ones updated through localization_group won't be
	 # returned.
	var new_localization: Array[DiscourseDialogLocale] = dialog_resource.generate_localization_files(
			release_resource.localization_uuid,
			dialog_path,
			localization_group)
	
	if uses_locale_group:
		if not localization_map.has(dialog_resource.locale_group):
			var new_map: Dictionary[String, DiscourseDialogLocale] = {}
			localization_map[dialog_resource.locale_group] = new_map
		for locale in new_localization:
			localization_map[dialog_resource.locale_group][locale.language + "-" + locale.region] = locale
	
	#localization_files.append_array(new_localization)
	for file in new_localization:
		localization_paths.append({
			"path": file.resource_path,
			"file": file})
		file.resource_path = ""
	
	return release_resource


func _export_end() -> void:
	export_temp_dir = null
	localization_paths.clear()
	localization_map.clear()
	locale_group_uuids.clear()
	localization_files.clear()
	release_files.clear()
