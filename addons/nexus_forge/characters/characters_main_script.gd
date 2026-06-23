@tool
extends PanelContainer


signal import_species_data_pressed
signal character_loaded(path: String)


const LineEditConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd")

var _unsaved: bool = false

var current_sheet: CharacterSheet = null
var ui_enabled: bool = false


@onready var char_menu_btn: MenuButton = $CharacterContainer/BasicDataSplit/CharacterTreeContainer/HBoxContainer/CharMenuBtn
@onready var search_char_ln_edt: LineEdit = $CharacterContainer/BasicDataSplit/CharacterTreeContainer/HBoxContainer/SearchCharLnEdt
@onready var char_id_line: LineEdit = $CharacterContainer/BasicDataSplit/GeneralContainer/CharIDContainer/CharIDLine
@onready var char_name_line: LineEdit = $CharacterContainer/BasicDataSplit/GeneralContainer/CharNameContainer/CharNameLine
@onready var species_option_button: OptionButton = $CharacterContainer/BasicDataSplit/GeneralContainer/SpeciesContainer/SpeciesOptionButton
@onready var gender_option_button: OptionButton = $CharacterContainer/BasicDataSplit/GeneralContainer/GenderContainer/GenderOptionButton
@onready var add_char_int_button: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddCharIntButton
@onready var add_char_float_button: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddCharFloatButton
@onready var add_char_bool_button: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddCharBoolButton
@onready var add_char_string_button: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddCharStringButton
@onready var add_dict_button: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddDictButton
@onready var character_custom_data_search_line: LineEdit = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CharacterCustomDataSearchLine
@onready var character_data_tree: Tree = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CharacterDataTree
@onready var load_species_data_btn: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/SpeciesContainer/LoadSpeciesDataBtn

@onready var char_stats_container: VBoxContainer = $CharacterContainer/ValuesSplit/ValuesVBox/StatVBox/StatScroll/CharStatsContainer
@onready var char_skill_container: VBoxContainer = $CharacterContainer/ValuesSplit/ValuesVBox/SkillVBox/SkillScroll/CharSkillContainer
@onready var char_tree: Tree = $CharacterContainer/BasicDataSplit/CharacterTreeContainer/CharTree
@onready var char_traits_container: VBoxContainer = $CharacterContainer/ValuesSplit/TraitsVbox/ScrollContainer/CharTraitsContainer

@onready var edit_stat_block_btn: Button = $CharacterContainer/ValuesSplit/ValuesVBox/StatVBox/StatLbl/EditStatBlockBtn
@onready var edit_skill_set_btn: Button = $CharacterContainer/ValuesSplit/ValuesVBox/SkillVBox/StatLbl/EditSkillSetBtn
@onready var edit_trait_block_btn: Button = $CharacterContainer/ValuesSplit/TraitsVbox/StatLbl/EditTraitBlockBtn
@onready var edit_genders_btn: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/GenderContainer/EditGendersBtn


func ready_plugin() -> void:
	char_tree.ready_plugin()
	character_data_tree.ready_plugin()
	
	search_char_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	character_custom_data_search_line.right_icon = get_theme_icon("Search", "EditorIcons")
	
	set_ui_enabled(false)
	update_genders()
	update_talent_nodes()
	update_species_data()
	
	add_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	char_menu_btn.icon = get_theme_icon("GuiTabMenuHl", "EditorIcons")
	edit_stat_block_btn.icon = get_theme_icon("Edit", "EditorIcons")
	edit_skill_set_btn.icon = get_theme_icon("Edit", "EditorIcons")
	edit_trait_block_btn.icon = get_theme_icon("Edit", "EditorIcons")
	edit_genders_btn.icon = get_theme_icon("Edit", "EditorIcons")
	
	character_custom_data_search_line.right_icon = get_theme_icon("Search", "EditorIcons")
	
	char_menu_btn.get_popup().id_pressed.connect(_on_character_menu_id_pressed)
	char_id_line.text_changed.connect(_something_changed)
	char_name_line.text_changed.connect(_something_changed)
	species_option_button.item_selected.connect(_something_changed)
	gender_option_button.item_selected.connect(_something_changed)
	add_char_int_button.pressed.connect(_on_add_data_pressed.bind("new_int", 0))
	add_char_float_button.pressed.connect(_on_add_data_pressed.bind("new_float", 0.0))
	add_char_bool_button.pressed.connect(_on_add_data_pressed.bind("new_bool", false))
	add_char_string_button.pressed.connect(_on_add_data_pressed.bind("new_string", ""))
	add_dict_button.pressed.connect(_on_add_data_pressed.bind("new_folder", {}))
	character_data_tree.data_changed.connect(_something_changed)
	char_tree.character_selected.connect(_on_character_selected, CONNECT_DEFERRED)
	load_species_data_btn.pressed.connect(_on_import_species_data_pressed)
	char_tree.character_closed.connect(_on_close_character_pressed, CONNECT_DEFERRED)
	
	edit_stat_block_btn.pressed.connect(_on_edit_statblock_pressed)
	edit_skill_set_btn.pressed.connect(_on_edit_skillset_pressed)
	edit_trait_block_btn.pressed.connect(_on_edit_traitblock_pressed)
	edit_genders_btn.pressed.connect(_on_edit_genders_pressed)


func _on_edit_genders_pressed() -> void:
	var sheet_script: Script = CharacterSheet.new().get_script()
	var source_code: String = sheet_script.source_code
	
	if source_code.is_empty():
		return
	
	var pattern: String = "enum\\s+Gender\\s*\\{[^}]*\\}"
	var regex: RegEx = RegEx.new()
	regex.compile(pattern)
	
	var regex_match: RegExMatch = regex.search(source_code)
	
	if regex_match == null:
		return
	
	var match_start: int = regex_match.get_start()
	var match_string: String = regex_match.get_string()
	var brace_open_idx: int = match_start + match_string.find("{")
	var brace_close_index: int = regex_match.get_end() - 1
	
	var inner_length: int = brace_close_index - brace_open_idx - 1
	var inner_text: String = source_code.substr(brace_open_idx + 1, inner_length)
	var stripped_text: String = inner_text.strip_edges(false)
	
	var target_idx: int = brace_open_idx + stripped_text.length() + 1
	var text_before_target: String = source_code.substr(0, target_idx)
	
	var line: int  = text_before_target.count("\n") + 1
	var last_newline_idx: int = text_before_target.rfind("\n")
	var column: int = text_before_target.length() - last_newline_idx
	EditorInterface.edit_script(sheet_script, line, column)
	
	if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
		EditorInterface.set_main_screen_editor("Script")


func _on_edit_statblock_pressed() -> void:
	EditorInterface.edit_script(StatBlock.new().get_script())
	if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
		EditorInterface.set_main_screen_editor("Script")


func _on_edit_skillset_pressed() -> void:
	EditorInterface.edit_script(SkillSet.new().get_script())
	if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
		EditorInterface.set_main_screen_editor("Script")


func _on_edit_traitblock_pressed() -> void:
	EditorInterface.edit_script(TraitBlock.new().get_script())
	if not EditorInterface.get_editor_settings().get_setting("text_editor/external/use_external_editor"):
		EditorInterface.set_main_screen_editor("Script")


func _on_close_character_pressed(resource: CharacterSheet, unsaved: bool) -> void:
	if unsaved:
		var unsaved_dialog := preload("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
		unsaved_dialog.title = "Save Character..."
		unsaved_dialog.dialog_text = "Character has unsaved changes.\nDo you want to save before closing?"
		add_child(unsaved_dialog)
		unsaved_dialog.show()
		
		var result: int = await unsaved_dialog.dialog_finished # 0 = save, 1 = don't save, 2 = cancel
		
		if result == 0:
			if resource == current_sheet:
				save_current_character()
			ResourceSaver.save(resource)
		elif result == 2:
			unsaved_dialog.queue_free()
			return
		unsaved_dialog.queue_free()
	
	if resource == current_sheet:
		current_sheet = null
		char_id_line.text = ""
		char_name_line.text = ""
		set_ui_enabled(false)
		character_data_tree.clear_data()
		reset_skills()
		reset_stats()
		reset_traits()
		_unsaved = false
	
	char_tree.remove_character(resource)


func _on_add_data_pressed(data_key: String, data: Variant) -> void:
	character_data_tree.add_data(data_key, data)
	_something_changed()


func _something_changed(_arg: Variant = null) -> void:
	if _unsaved:
		return
	
	_unsaved = true
	if current_sheet != null:
		char_tree.set_unsaved(current_sheet, true)


func get_open_characters() -> Array[String]:
	return char_tree.get_open_paths()


func load_character_files(files: Array[String]) -> void:
	for file in files:
		if not FileAccess.file_exists(file):
			continue
		var loaded: Resource = load(file)
		if loaded != null and loaded is CharacterSheet:
			if char_tree.has_character(loaded):
				continue
			
			if loaded.stats == null:
				loaded.stats = StatBlock.new()
			if loaded.skills == null:
				loaded.skills = SkillSet.new()
			if loaded.traits == null:
				loaded.traits = TraitBlock.new()
			
			char_tree.create_character(loaded, false)


func update_genders() -> void:
	gender_option_button.clear()
	var gender_obg: CharacterSheet = CharacterSheet.new()
	var map: Dictionary = gender_obg.get_script().get_script_constant_map()
	
	if not map.has(&"Gender"):
		gender_option_button.disabled = true
		return
	
	var genders: Dictionary = map[&"Gender"]
	
	for gender:String in genders.keys():
		gender_option_button.add_item(
				gender.capitalize())
		gender_option_button.set_item_metadata(
				-1,
				genders[gender])
	
	gender_option_button.disabled = gender_option_button.item_count == 0 or current_sheet == null


func update_species_data(species_catalog: SpeciesCatalog = null) -> void:
	var currently_selected: StringName = &"" if species_option_button.selected == -1 else species_option_button.get_item_metadata(species_option_button.selected)
	var new_index: int = -1
	
	species_option_button.clear()
	
	var species_path: String = ProjectSettings.get_setting(
			NFPluginGameHandler.get_setting_path("species"),
			"")
	
	if species_catalog == null:
		if species_path != "" and FileAccess.file_exists(species_path):
			var pre_res: Resource = load(species_path)
			if pre_res is SpeciesCatalog:
				var species:Array[StringName] = pre_res.species()
				species.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
				if not currently_selected.is_empty():
					new_index = species.find(currently_selected)
				for species_id in species:
					var text: String = String(species_id).capitalize()
					var parent: String = String(pre_res._species[species_id]["parent_dominant"])
					var recessive: String = String(pre_res._species[species_id]["parent_recessive"])
					if not parent.is_empty():
						text += " (" + parent
						if not recessive.is_empty():
							text += " / " + recessive
						text += ")"
					species_option_button.add_item(text)
					species_option_button.set_item_metadata(-1, species_id)
	else:
		var species:Array[StringName] = species_catalog.species()
		species.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
		if not currently_selected.is_empty():
			new_index = species.find(currently_selected)
		for species_id in species:
			var text: String = String(species_id).capitalize()
			var parent: String = String(species_catalog._species[species_id]["parent_dominant"])
			if parent != "":
				text += " (" + parent + ")"
			species_option_button.add_item(text)
			species_option_button.set_item_metadata(-1, species_id)
	
	species_option_button.disabled = not ui_enabled or species_option_button.item_count == 0
	load_species_data_btn.disabled = species_option_button.disabled
	
	if new_index == -1:
		if 0 < species_option_button.item_count:
			species_option_button.select(0)
	else:
		species_option_button.select(new_index)


func update_talent_nodes() -> void:
	var skill_set: SkillSet = SkillSet.new()

	var trait_block: TraitBlock = TraitBlock.new()
	
	var stat_block: StatBlock = StatBlock.new()
	
	var stats_data: Dictionary[StringName, int] = StatBlock.stats()
	
	var stats: Array[String] = []
	stats.assign(stats_data.keys())
	stats.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	var stat_map: Dictionary[StringName, Control] = {}
	for existing_stat in char_stats_container.get_children():
		char_stats_container.remove_child(existing_stat)
		if existing_stat.get_meta(&"stat_id") in stats:
			stat_map[existing_stat.get_meta(&"stat_id")] = existing_stat
		else:
			existing_stat.queue_free()
		
	for stat_id in stats:
		var stat_default: float = 0.0
		var stat_item: ValueRange = stat_block.get(stat_id)
		if stat_item != null:
			stat_default = stat_item.value
		
		if stat_map.has(stat_id):
			char_stats_container.add_child(stat_map[stat_id])
			stat_map[stat_id].set_meta(&"default_value", stat_default)
			if stats_data[stat_id] != stat_map[stat_id].get_meta(&"type"):
				var new_step: float = 1.0 if stats_data[stat_id] == TYPE_INT else 0.01
				stat_map[stat_id].get_meta(&"value").step = new_step
				stat_map[stat_id].get_meta(&"max").step = new_step
				stat_map[stat_id].get_meta(&"min").step = new_step
				stat_map[stat_id].set_meta(&"type", stats_data[stat_id])
			stat_map.erase(stat_id)
		else:
			var stat = create_stat_item(stat_id, stats_data[stat_id], stat_default)
			char_stats_container.add_child(stat)
	
	for remaining_stat in stat_map:
		stat_map[remaining_stat].queue_free()
	
	var skills: Array[StringName] = SkillSet.skills()
	skills.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	var skill_map: Dictionary[StringName, Control] = {}
	for existing_skill in char_skill_container.get_children():
		char_skill_container.remove_child(existing_skill)
		if skills.has(existing_skill.get_meta(&"skill_id")):
			skill_map[existing_skill.get_meta(&"skill_id")] = existing_skill
		else:
			existing_skill.queue_free()
	
	for skill_id in skills:
		if skill_map.has(skill_id):
			char_skill_container.add_child(skill_map[skill_id])
			skill_map[skill_id].set_meta(&"default_value", skill_set.get(skill_id))
			skill_map.erase(skill_id)
		else:
			var skill = create_skill_item(skill_id, skill_set.get(skill_id))
			char_skill_container.add_child(skill)
	
	for remaining_skill in skill_map.keys():
		skill_map[remaining_skill].queue_free()
	

	var traits: Array[StringName] = TraitBlock.traits()
	traits.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	var trait_map: Dictionary[StringName, Control] = {}
	for existing_trait in char_traits_container.get_children():
		char_traits_container.remove_child(existing_trait)
		if traits.has(existing_trait.get_meta(&"trait_id")):
			trait_map[existing_trait.get_meta(&"trait_id")] = existing_trait
		else:
			existing_trait.queue_free()
	
	for trait_id in traits:
		if trait_map.has(trait_id):
			char_traits_container.add_child(trait_map[trait_id])
			trait_map[trait_id].set_meta(&"default_value", trait_block.get(trait_id))
			trait_map.erase(trait_id)
		else:
			var new_trait: HBoxContainer = create_trait_item(trait_id, trait_block.get(trait_id))
			char_traits_container.add_child(new_trait)
	for remaining_trait in trait_map.keys():
		trait_map[remaining_trait].queue_free()
	
	char_tree.update_talent_objects()
	if current_sheet != null:
		_unsaved = char_tree.is_unsaved(current_sheet)


func _on_new_character_pressed() -> void:
	var resource_selector := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	resource_selector.file_mode = resource_selector.FILE_MODE_SAVE_FILE
	resource_selector.access = resource_selector.ACCESS_RESOURCES
	resource_selector.title = "Save Character..."
	add_child(resource_selector)
	resource_selector.show()
	
	var dialog_result: Array = await resource_selector.dialog_finished
	
	if dialog_result[0]:
		if current_sheet != null:
			save_current_character()
		var new_resource: CharacterSheet = CharacterSheet.new()
		new_resource.initialize_objects()
		if ResourceLoader.has_cached(dialog_result[1]):
			new_resource.take_over_path(dialog_result[1])
		new_resource.resource_path = dialog_result[1]
		
		for stat in StatBlock.stats():
			var stat_range: ValueRange = new_resource.stats.get(stat)
			stat_range.min_value = 0.0
			stat_range.max_value = 1.0
			stat_range.allow_greater = true
			stat_range.allow_lesser = true
		
		ResourceSaver.save(new_resource, dialog_result[1])
		char_tree.create_character(new_resource, true, false)
		load_character(new_resource)
		current_sheet = new_resource
		_unsaved = false
		set_ui_enabled(true)
		character_loaded.emit.call_deferred(dialog_result[1])
	
	resource_selector.queue_free()


func _on_open_character_pressed() -> void:
	var resource_selector := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	resource_selector.file_mode = resource_selector.FILE_MODE_OPEN_FILE
	resource_selector.access = resource_selector.ACCESS_RESOURCES
	resource_selector.title = "Open Character..."
	add_child(resource_selector)
	resource_selector.show()
	
	var dialog_result: Array = await resource_selector.dialog_finished
	
	if dialog_result[0] and FileAccess.file_exists(dialog_result[1]):
		var resource_preload: Resource = load(dialog_result[1])
		if resource_preload is CharacterSheet:
			if current_sheet != null:
				save_current_character()
			if resource_preload.stats == null:
				resource_preload.stats = StatBlock.new()
			if resource_preload.skills == null:
				resource_preload.skills = SkillSet.new()
			if resource_preload.traits == null:
				resource_preload.traits = TraitBlock.new()
			
			if char_tree.has_character(resource_preload):
				char_tree.select_character(resource_preload, false)
			else:
				char_tree.create_character(resource_preload, true, false)
			
			load_character(resource_preload)
			current_sheet = resource_preload
			set_ui_enabled(true)
			_unsaved = false
	
	resource_selector.queue_free()


func _on_character_selected(character_sheet: CharacterSheet, unsaved: bool) -> void:
	if current_sheet != null:
		save_current_character()
	load_character(character_sheet)
	current_sheet = character_sheet
	set_ui_enabled(true)
	_unsaved = unsaved


func _on_character_menu_id_pressed(id: int) -> void:
	match id:
		0: # New character
			_on_new_character_pressed()
		1: # Open Character
			_on_open_character_pressed()


func _on_import_species_data_pressed() -> void:
	import_species_data_pressed.emit()


func import_species_data(species_sheet: SpeciesCatalog, with_inheritance: bool) -> void:
	if species_option_button.selected == -1 or not species_sheet.has_species(species_option_button.get_selected_metadata()):
		return
	
	var species_selected: StringName = species_option_button.get_selected_metadata()
	
	var stats: Dictionary[StringName, float] = species_sheet._species_stat_data(species_selected, with_inheritance)
	var skills: Dictionary[StringName, int] = species_sheet._species_skill_data(species_selected, with_inheritance)
	var traits: Dictionary[StringName, int] = species_sheet._species_trait_data(species_selected, with_inheritance)
	
	for stat in char_stats_container.get_children():
		var target_stat: StringName = stat.get_meta(&"stat_id")
		if stats.has(target_stat):
			stat.get_meta(&"value").set_value_no_signal(
					stats[target_stat])
	
	for skill in char_skill_container.get_children():
		var target_skill: StringName = skill.get_meta(&"skill_id")
		if skills.has(target_skill):
			skill.get_child(1).set_value_no_signal(
				skills[target_skill])
	
	for child in char_traits_container.get_children():
		var target_trait: StringName = child.get_meta(&"trait_id")
		if traits.has(target_trait):
			child.get_child(1).set_value_no_signal(
					traits[target_trait])
	
	_something_changed()


func set_ui_enabled(enabled: bool) -> void:
	var disabled: bool = not enabled
	
	char_id_line.editable = enabled
	char_name_line.editable = enabled
	species_option_button.disabled = disabled or species_option_button.item_count == 0
	gender_option_button.disabled = disabled
	add_char_int_button.disabled = disabled
	add_char_float_button.disabled = disabled
	add_char_bool_button.disabled = disabled
	add_char_string_button.disabled = disabled
	add_dict_button.disabled = disabled
	load_species_data_btn.disabled = species_option_button.disabled
	character_data_tree.enabled = enabled
	
	for item in char_stats_container.get_children():
		item.get_meta(&"value").editable = enabled
		item.get_meta(&"use_max").disabled = disabled
		item.get_meta(&"use_min").disabled = disabled
		item.get_meta(&"max").editable = item.get_meta(&"use_max").button_pressed
		item.get_meta(&"min").editable = item.get_meta(&"use_min").button_pressed
	
	for item in char_skill_container.get_children():
		item.get_child(1).editable = enabled
	
	for item in char_traits_container.get_children():
		item.get_child(1).editable = enabled
	
	ui_enabled = enabled


func reset_stats() -> void:
	for item in char_stats_container.get_children():
		var max_spn: SpinBox = item.get_meta(&"max")
		var min_spn: SpinBox = item.get_meta(&"min")
		var btn: Button = item.get_meta(&"collapse")
		var flags: int = btn.get_meta(&"range_flags")
		item.get_meta(&"value").set_value_no_signal(item.get_meta(&"default_value", 0.0))
		item.get_meta(&"use_max").set_pressed_no_signal(false)
		item.get_meta(&"use_min").set_pressed_no_signal(false)
		if BitUtils.is_bit_index(flags, 2, true):
			btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_none.svg")
		else:
			btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_none.svg")
		
		flags = BitUtils.set_bits(flags, 3, false)
		btn.set_meta(&"range_flags", flags)
		
		max_spn.editable = false
		max_spn.set_value_no_signal(1.0)
		min_spn.editable = false
		min_spn.set_value_no_signal(0.0)


func reset_skills() -> void:
	for item in char_skill_container.get_children():
		item.get_child(1).set_value_no_signal(item.get_meta(&"default_value", 0.0))


func reset_traits() -> void:
	for item in char_traits_container.get_children():
		item.get_child(1).set_value_no_signal(item.get_meta(&"default_value", 0.0))


func save_current_character() -> void:
	current_sheet.id = StringName(char_id_line.text.strip_edges())
	current_sheet.name = char_name_line.text.strip_edges()
	current_sheet.species = &"" if species_option_button.selected == -1 else species_option_button.get_item_metadata(species_option_button.selected)
	if -1 < gender_option_button.selected:
		current_sheet.gender = gender_option_button.get_item_metadata(gender_option_button.selected)
	else:
		current_sheet.gender = 0
	current_sheet.custom_data.clear()
	current_sheet.custom_data.assign(character_data_tree.get_data())
	
	for stat in char_stats_container.get_children():
		var sheet_stat: ValueRange = current_sheet.stats.get(stat.get_meta(&"stat_id"))
		if sheet_stat == null:
			var new_sheet: ValueRange = RangeInt.new() if stat.get_meta(&"type") == TYPE_INT else RangeFloat.new()
			current_sheet.stats.set(stat.get_meta(&"stat_id"), new_sheet)
			sheet_stat = new_sheet
		
		sheet_stat.value = stat.get_meta(&"value").value
		sheet_stat.allow_greater = not stat.get_meta(&"use_max").button_pressed
		sheet_stat.allow_lesser = not stat.get_meta(&"use_min").button_pressed
		sheet_stat.min_value = stat.get_meta(&"min").value
		sheet_stat.max_value = stat.get_meta(&"max").value
	
	for skill in char_skill_container.get_children():
		current_sheet.skills.set(
				skill.get_meta(&"skill_id"),
				int(skill.get_child(1).value))
	
	for trait_item in char_traits_container.get_children():
		current_sheet.traits.set(
				trait_item.get_meta(&"trait_id"),
				int(trait_item.get_child(1).value))
	
	char_tree.update_sheet(current_sheet)
	char_tree.set_unsaved(current_sheet, _unsaved)


func has_unsaved_files() -> bool:
	return char_tree.is_any_unsaved()


func save() -> void:
	if current_sheet != null:
		save_current_character()
	var unsaved_characters: Array[CharacterSheet] = char_tree.get_unsaved()
	for item in unsaved_characters:
		ResourceSaver.save(item)
	char_tree.set_all_saved()
	_unsaved = false


func load_character(sheet: CharacterSheet) -> void:
	char_id_line.text = sheet.id
	char_name_line.text = sheet.name
	select_species(sheet.species)
	select_gender(sheet.gender)
	
	character_data_tree.clear_data()
	
	for key in sheet.custom_data.keys():
		character_data_tree.add_data(key, sheet.custom_data[key])
	
	for stat in char_stats_container.get_children():
		var stat_range: ValueRange = sheet.stats.get(stat.get_meta(&"stat_id"))
		if stat_range == null:
			var max_spn: SpinBox = stat.get_meta(&"max")
			var min_spn: SpinBox = stat.get_meta(&"min")
			var btn: Button = stat.get_meta(&"collapse")
			var flags: int = btn.get_meta(&"range_flags")
			stat.get_meta(&"value").set_value_no_signal(0.0)
			stat.get_meta(&"use_max").set_pressed_no_signal(false)
			stat.get_meta(&"use_min").set_pressed_no_signal(false)
			if BitUtils.is_bit_index(flags, 2, true):
				btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_none.svg")
			else:
				btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_none.svg")
			
			flags = BitUtils.set_bits(flags, 3, false)
			btn.set_meta(&"range_flags", flags)
			
			max_spn.editable = false
			max_spn.set_value_no_signal(1.0)
			min_spn.editable = false
			min_spn.set_value_no_signal(0.0)
			continue
		
		var collapse_btn: Button = stat.get_meta(&"collapse")
		var flags: int = collapse_btn.get_meta(&"range_flags")
		var value: SpinBox = stat.get_meta(&"value")
		var max_spinbox: SpinBox = stat.get_meta(&"max")
		
		flags = BitUtils.set_bit_index(flags, 0, not stat_range.allow_lesser)
		flags = BitUtils.set_bit_index(flags, 1, not stat_range.allow_greater)
		collapse_btn.set_meta(&"range_flags", flags)
		
		if BitUtils.is_bit_index(flags, 2, true): #Expanded
			match BitUtils.get_bits(flags, 3):
				0:
					collapse_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_none.svg")
				1:
					collapse_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_min.svg")
				2:
					collapse_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_max.svg")
				3:
					collapse_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_minmax.svg")
		else:
			match BitUtils.get_bits(flags, 3):
				0:
					collapse_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_none.svg")
				1:
					collapse_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_min.svg")
				2:
					collapse_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_max.svg")
				3:
					collapse_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_minmax.svg")
		
		value.allow_greater = stat_range.allow_greater
		value.allow_lesser = stat_range.allow_lesser
		stat.get_meta(&"use_max").set_pressed_no_signal(not stat_range.allow_greater)
		stat.get_meta(&"use_min").set_pressed_no_signal(not stat_range.allow_lesser)
		stat.get_meta(&"min").set_value_no_signal(stat_range.min_value)
		max_spinbox.set_value_no_signal(stat_range.max_value if stat_range.min_value <= stat_range.max_value else stat_range.min_value)
		stat.get_meta(&"max").editable = stat_range.allow_greater
		stat.get_meta(&"min").editable = stat_range.allow_lesser
		
		if not stat_range.allow_greater and stat_range.max_value < value.value:
			value.set_value_no_signal(stat_range.max_value)
		
		if not stat_range.allow_lesser and value.value < stat_range.min_value:
			value.set_value_no_signal(stat_range.min_value)
		
		value.set_value_no_signal(stat_range.value)
	
	for skill in char_skill_container.get_children():
		if skill is HBoxContainer:
			var skill_value = sheet.skills.get(skill.get_meta(&"skill_id"))
			if skill_value == null:
				skill.get_child(1).set_value_no_signal(skill.get_meta(&"default_value"))
			else:
				skill.get_child(1).set_value_no_signal(skill_value)
	
	for child in char_traits_container.get_children():
		if child is HBoxContainer:
			var trait_value = sheet.traits.get(child.get_meta(&"trait_id"))
			if trait_value == null:
				child.get_child(1).set_value_no_signal(child.get_meta(&"default_value"))
			else:
				child.get_child(1).set_value_no_signal(trait_value)


func select_species(type: StringName) -> void:
	for item_idx in range(species_option_button.item_count):
		if species_option_button.get_item_metadata(item_idx) == type:
			species_option_button.select(item_idx)
			break


func select_gender(gender: CharacterSheet.Gender) -> void:
	for item_idx in range(gender_option_button.item_count):
		if gender_option_button.get_item_metadata(item_idx) == gender:
			gender_option_button.select(item_idx)
			break

# default must be a numeric value (float/type
func create_stat_item(stat_id: StringName, type: int, default: float) -> VBoxContainer:
	var new_stat: VBoxContainer = VBoxContainer.new()
	var data_field: HBoxContainer = HBoxContainer.new()
	var limits_container: HBoxContainer = HBoxContainer.new()
	var min_container: HBoxContainer = HBoxContainer.new()
	var max_container: HBoxContainer = HBoxContainer.new()
	var stat_label: Label = Label.new()
	var new_value: SpinBox = SpinBox.new()
	var edit_limits_btn: Button = Button.new()
	
	var limit_max_spn: SpinBox = SpinBox.new()
	var limit_min_spn: SpinBox = SpinBox.new()
	var allow_greater: CheckBox = CheckBox.new()
	var allow_lesser: CheckBox = CheckBox.new()
	
	limits_container.visible = false
	
	allow_lesser.text = "Min"
	allow_lesser.custom_minimum_size = Vector2(62.0, 32.0)
	allow_lesser.tooltip_text = "Use minimum.\nLeaving unchecked will allow stat\nto go lower indefinitely."
	allow_lesser.disabled = current_sheet == null
	limit_min_spn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	limit_min_spn.allow_lesser = true
	limit_min_spn.allow_greater = true
	limit_min_spn.editable = not allow_lesser.disabled
	
	
	allow_greater.text = "Max"
	allow_greater.custom_minimum_size = Vector2(62.0, 32.0)
	allow_greater.tooltip_text = "Use maximum.\nLeaving unchecked will allow stat\nto go higher indefinitely."
	allow_greater.disabled = current_sheet == null
	limit_max_spn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	limit_max_spn.allow_lesser = true
	limit_max_spn.allow_greater = true
	limit_max_spn.editable = not allow_greater.disabled
	
	edit_limits_btn.custom_minimum_size = Vector2(32.0, 32.0)
	edit_limits_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_none.svg")
	edit_limits_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit_limits_btn.tooltip_text = "Show limits"
	edit_limits_btn.flat = true
	edit_limits_btn.focus_mode = Control.FOCUS_CLICK
	
	stat_label.text = String(stat_id).capitalize()
	stat_label.tooltip_text = stat_label.text
	stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_label.size_flags_stretch_ratio = 2.0
	stat_label.custom_minimum_size = Vector2(24.0, 32.0)
	stat_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stat_label.mouse_filter = Control.MOUSE_FILTER_STOP
	
	new_value.allow_greater = true
	new_value.allow_lesser = true
	new_value.update_on_text_changed = true
	new_value.custom_minimum_size.y = 32
	new_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_value.size_flags_stretch_ratio = 3.0
	new_value.value = default
	if type == TYPE_INT:
		new_value.step = 1.0
		limit_max_spn.step = 1.0
		limit_min_spn.step = 1.0
	else:
		new_value.step = 0.01
		limit_max_spn.step = 0.01
		limit_min_spn.step = 0.01
	
	new_value.value_changed.connect(_something_changed)
	new_value.editable = ui_enabled
	
	new_stat.set_meta(&"stat_id", stat_id)
	new_stat.set_meta(&"value", new_value)
	new_stat.set_meta(&"use_max", allow_greater)
	new_stat.set_meta(&"use_min", allow_lesser)
	new_stat.set_meta(&"max", limit_max_spn)
	new_stat.set_meta(&"min", limit_min_spn)
	new_stat.set_meta(&"type", type)
	new_stat.set_meta(&"collapse", edit_limits_btn)
	new_stat.set_meta(&"default_value", default)
	
	edit_limits_btn.set_meta(&"range_flags", 0)
	
	min_container.add_child(allow_lesser)
	min_container.add_child(limit_min_spn)
	
	max_container.add_child(allow_greater)
	max_container.add_child(limit_max_spn)
	
	data_field.add_child(edit_limits_btn)
	data_field.add_child(stat_label)
	data_field.add_child(new_value)
	
	limits_container.add_child(min_container)
	limits_container.add_child(max_container)
	
	new_stat.add_child(data_field)
	new_stat.add_child(limits_container)
	
	edit_limits_btn.pressed.connect(_toggle_limit_visibility_pressed.bind(edit_limits_btn, limits_container))
	limit_max_spn.value_changed.connect(_on_limit_max_changed.bind(new_value))
	limit_min_spn.value_changed.connect(_on_limit_min_changed.bind(new_value, limit_max_spn))
	# is_enabled: bool, stat: SpinBox, min_spin: SpinBox, max_spin: SpinBox, limit_btn: CheckBox
	allow_lesser.toggled.connect(_on_toggle_min_stat.bind(new_value, limit_min_spn, limit_max_spn, edit_limits_btn))
	allow_greater.toggled.connect(_on_toggle_max_stat.bind(new_value, limit_max_spn, edit_limits_btn))
	
	return new_stat


func _on_toggle_min_stat(is_enabled: bool, stat: SpinBox, min_spin: SpinBox, max_spin: SpinBox, limit_btn: Button) -> void:
	stat.allow_lesser = not is_enabled
	max_spin.allow_lesser = not is_enabled
	min_spin.editable = is_enabled
	
	if is_enabled and stat.value < min_spin.value:
		stat.set_value_no_signal(min_spin.value)
	
	var flags: int = limit_btn.get_meta(&"range_flags")
	flags = BitUtils.set_bit_index(flags, 0, is_enabled)
	
	if BitUtils.is_bit_index(flags, 2, true): # Uncollapsed
		match BitUtils.get_bits(flags, 3):
			0:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_none.svg")
			1:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_min.svg")
			2:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_max.svg")
			3:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_minmax.svg")
	else:
		match BitUtils.get_bits(flags, 3):
			0:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_none.svg")
			1:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_min.svg")
			2:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_max.svg")
			3:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_minmax.svg")
	
	limit_btn.set_meta(&"range_flags", flags)
	_something_changed()


func _on_toggle_max_stat(is_enabled: bool, stat: SpinBox, max_spin: SpinBox, limit_btn: Button) -> void:
	var flags: int = limit_btn.get_meta(&"range_flags")
	flags = BitUtils.set_bit_index(flags, 1, is_enabled)
	
	stat.allow_greater = not is_enabled
	max_spin.editable = is_enabled
	if is_enabled and max_spin.value < stat.value:
		stat.set_value_no_signal(max_spin.value)
	
	if BitUtils.is_bit_index(flags, 2, true): # Uncollapsed
		match BitUtils.get_bits(flags, 3):
			0:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_none.svg")
			1:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_min.svg")
			2:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_max.svg")
			3:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_minmax.svg")
	else:
		match BitUtils.get_bits(flags, 3):
			0:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_none.svg")
			1:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_min.svg")
			2:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_max.svg")
			3:
				limit_btn.icon = preload("res://addons/nexus_forge/icons/range_collapsed_minmax.svg")
	limit_btn.set_meta(&"range_flags", flags)
	_something_changed()


func _toggle_limit_visibility_pressed(toggle_button: Button, limit_container: HBoxContainer) -> void:
	var flags: int = toggle_button.get_meta(&"range_flags")
	limit_container.visible = not limit_container.visible
	flags = BitUtils.set_bit_index(flags, 2, limit_container.visible)
	
	var icon: Texture2D = null
	
	if BitUtils.is_bit_index(flags, 2, true): # Uncollapsed
		match BitUtils.get_bits(flags, 3):
			0:
				icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_none.svg")
			1:
				icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_min.svg")
			2:
				icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_max.svg")
			3:
				icon = preload("res://addons/nexus_forge/icons/range_uncollapsed_minmax.svg")
	else:
		match BitUtils.get_bits(flags, 3):
			0:
				icon = preload("res://addons/nexus_forge/icons/range_collapsed_none.svg")
			1:
				icon = preload("res://addons/nexus_forge/icons/range_collapsed_min.svg")
			2:
				icon = preload("res://addons/nexus_forge/icons/range_collapsed_max.svg")
			3:
				icon = preload("res://addons/nexus_forge/icons/range_collapsed_minmax.svg")
	
	toggle_button.icon = icon
	toggle_button.set_meta(&"range_flags", flags)


func _on_limit_max_changed(value: float, stat: SpinBox) -> void:
	stat.max_value = value
	if value < stat.value:
		stat.set_value_no_signal(value)
	
	_something_changed()


func _on_limit_min_changed(value: float, stat: SpinBox, max_spin: SpinBox) -> void:
	stat.min_value = value
	max_spin.min_value = value
	if stat.value < value:
		stat.set_value_no_signal(value)
	_something_changed()


func create_skill_item(skill_id: StringName, default_value: int) -> HBoxContainer:
	var new_skill: HBoxContainer = HBoxContainer.new()
	var skill_label: Label = Label.new()
	var new_value: SpinBox = SpinBox.new()
	
	skill_label.text = String(skill_id).capitalize()
	skill_label.tooltip_text = skill_label.text
	skill_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_label.size_flags_stretch_ratio = 2.0
	skill_label.custom_minimum_size.y = 32
	skill_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	skill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skill_label.mouse_filter = Control.MOUSE_FILTER_STOP
	
	new_value.allow_greater = true
	new_value.allow_lesser = true
	new_value.update_on_text_changed = true
	new_value.custom_minimum_size = Vector2(24.0, 32.0)
	new_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_value.size_flags_stretch_ratio = 3.0
	new_value.step = 1.0
	new_value.value = default_value
	new_value.editable = ui_enabled
	new_value.value_changed.connect(_something_changed)
	
	new_skill.set_meta(&"skill_id", skill_id)
	new_skill.set_meta(&"default_value", default_value)
	
	new_skill.add_child(skill_label)
	new_skill.add_child(new_value)
	
	return new_skill


func create_trait_item(trait_id: StringName, default_value: int) -> HBoxContainer:
	var new_trait: HBoxContainer = HBoxContainer.new()
	var trait_label: Label = Label.new()
	var new_value: SpinBox = SpinBox.new()
	
	trait_label.text = String(trait_id).capitalize()
	trait_label.tooltip_text = trait_label.text
	trait_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trait_label.size_flags_stretch_ratio = 2.0
	trait_label.custom_minimum_size = Vector2(24.0, 32.0)
	trait_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	trait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trait_label.mouse_filter = Control.MOUSE_FILTER_STOP
	
	new_value.allow_greater = true
	new_value.allow_lesser = true
	new_value.update_on_text_changed = true
	new_value.step = 1.0
	new_value.value = default_value
	#if type == TYPE_INT:
	#else:
		#new_value.step = 0.01
	new_value.custom_minimum_size.y = 32
	new_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_value.size_flags_stretch_ratio = 3.0
	new_value.editable = ui_enabled
	new_value.value_changed.connect(_something_changed)
	#new_value.set_meta(&"default_value", default)
	
	new_trait.set_meta(&"trait_id", trait_id)
	new_trait.set_meta(&"default_value", default_value)
	
	new_trait.add_child(trait_label)
	new_trait.add_child(new_value)
	
	return new_trait


func plugin_open_resource(resource: CharacterSheet) -> void:
	if current_sheet == resource:
		return
	
	if current_sheet != null:
		save_current_character()
	
	if char_tree.has_character(resource):
		char_tree.select_character(resource)
	else:
		if resource.stats == null:
			resource.stats = StatBlock.new()
		if resource.skills == null:
			resource.skills = SkillSet.new()
		if resource.traits == null:
			resource.traits = TraitBlock.new()
		char_tree.create_character(resource, true, false)
		load_character(resource)
		current_sheet = resource
		_unsaved = false
	
	set_ui_enabled(true)


func filesystem_resource_removed(res: Resource) -> void:
	if res == null:
		return
	
	char_tree.remove_character(res)
	if current_sheet == res:
		current_sheet = null
		char_id_line.text = ""
		char_name_line.text = ""
		set_ui_enabled(false)
		character_data_tree.clear_data()
		reset_skills()
		reset_stats()
		reset_traits()
		_unsaved = false


func close_active_character() -> void:
	if current_sheet == null:
		return
		
	if char_tree.is_unsaved(current_sheet):
		var unsaved_dialog := preload("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
		unsaved_dialog.title = "Save Character..."
		unsaved_dialog.dialog_text = "Character has unsaved changes.\nDo you want to save before closing?"
		add_child(unsaved_dialog)
		unsaved_dialog.show()
		
		var result: int = await unsaved_dialog.dialog_finished # 0 = save, 1 = don't save, 2 = cancel
		
		if result == 0:
			save_current_character()
			ResourceSaver.save(current_sheet)
		elif result == 2:
			unsaved_dialog.queue_free()
			return
		unsaved_dialog.queue_free()
	
	char_id_line.text = ""
	char_name_line.text = ""
	set_ui_enabled(false)
	character_data_tree.clear_data()
	reset_skills()
	reset_stats()
	reset_traits()
	_unsaved = false
	
	char_tree.remove_character(current_sheet)
	
	current_sheet = null
