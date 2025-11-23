extends EditorExportPlugin


const WHITELIST_FOLDERS: Array[String] = [
	"resources", # Contains all resource definitions
	"classes" # Contains all code for singletons and utilities
	]

const EXCLUDED_FILES: Array[String] = [
	"res://addons/nexus_forge/resources/parser/discourse_parser_editor.gd",
	"res://addons/nexus_forge/resources/dialog_storage/dialog_storage_editor.gd"
	]


var localization_files: Array[DiscourseDialogLocale] = []
var localization_map: Dictionary[String, Dictionary] = {}
var locale_group_uuids: Dictionary[String, String] = {}
var dialog_path: String = ""


func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	var file_base_path: String = ProjectSettings.get_setting(
			EditorNFPlugin.get_project_settings_path("discourse")).strip_edges()
	
	if not file_base_path.ends_with("/"):
		file_base_path += "/"
	
	dialog_path = file_base_path


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if not path.begins_with("res://addons/nexus_forge/"):
		return
	
	if WHITELIST_FOLDERS.has(path.get_slice("/", 4)) == false:
		skip()
	elif path in EXCLUDED_FILES:
		skip()


func _begin_customize_resources(_platform: EditorExportPlatform, _features: PackedStringArray) -> bool:
	localization_files.clear()
	localization_map.clear()
	locale_group_uuids.clear()
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
	var resource_class: StringName = resource.get_script().get_global_name()
	if resource_class == &"EditorDiscourseDialog":
		return customize_discourse_dialog(resource)
	elif resource_class == &"SkillCatalog":
		return customize_skill_catalog(resource)
	elif resource_class == &"TraitCatalog":
		return customize_trait_catalog(resource)
	elif resource_class == &"SpeciesCatalog":
		return customize_species(resource)
	return null


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
			release_resource.conversation_uuid,
			dialog_path,
			localization_group)
	
	if uses_locale_group:
		if not localization_map.has(dialog_resource.locale_group):
			var new_map: Dictionary[String, DiscourseDialogLocale] = {}
			localization_map[dialog_resource.locale_group] = new_map
		for locale in new_localization:
			localization_map[dialog_resource.locale_group][locale.language + "-" + locale.region] = locale
	
	localization_files.append_array(new_localization)
	
	return release_resource


func _end_customize_resources() -> void:
	for localization_file in localization_files:
		add_file(
				localization_file.resource_path,
				var_to_bytes_with_objects(localization_file),
				false)
