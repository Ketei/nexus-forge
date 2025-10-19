extends EditorExportPlugin


var localization_files: Array[DiscourseDialogLocale] = []
var localization_map: Dictionary[String, Dictionary] = {}
var locale_group_uuids: Dictionary[String, String] = {}


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
	if resource is not EditorDiscourseDialog:
		return null # We don't intend to modify other resources 
	
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
