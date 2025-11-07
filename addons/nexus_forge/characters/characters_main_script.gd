@tool
extends PanelContainer


const LineEditConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd")

var _unsaved: bool = false

var current_sheet: CharacterSheet = null
#var listen_selected: bool = true
var ui_enabled: bool = false


@onready var char_menu_btn: MenuButton = $CharacterContainer/BasicDataSplit/CharacterTreeContainer/HBoxContainer/CharMenuBtn
@onready var search_char_ln_edt: LineEdit = $CharacterContainer/BasicDataSplit/CharacterTreeContainer/HBoxContainer/SearchCharLnEdt
#@onready var new_character: Button = $CharacterContainer/BasicDataSplit/CharacterTreeContainer/HBoxContainer/NewCharacter
#@onready var open_character: Button = $CharacterContainer/BasicDataSplit/CharacterTreeContainer/HBoxContainer/OpenCharacter
@onready var char_id_line: LineEdit = $CharacterContainer/BasicDataSplit/GeneralContainer/CharIDContainer/CharIDLine
@onready var char_name_line: LineEdit = $CharacterContainer/BasicDataSplit/GeneralContainer/CharNameContainer/CharNameLine
@onready var species_option_button: OptionButton = $CharacterContainer/BasicDataSplit/GeneralContainer/SpeciesContainer/SpeciesOptionButton
@onready var gender_option_button: OptionButton = $CharacterContainer/BasicDataSplit/GeneralContainer/GenderContainer/GenderOptionButton
@onready var add_char_int_button: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddCharIntButton
@onready var add_char_float_button: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddCharFloatButton
@onready var add_char_bool_button: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddCharBoolButton
@onready var add_char_string_button: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddCharStringButton
@onready var character_custom_data_search_line: LineEdit = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CharacterCustomDataSearchLine
@onready var character_data_tree: Tree = $CharacterContainer/BasicDataSplit/GeneralContainer/CustomDataContainer/CharacterDataTree
@onready var load_species_data_btn: Button = $CharacterContainer/BasicDataSplit/GeneralContainer/SpeciesContainer/LoadSpeciesDataBtn

@onready var char_stats_container: VBoxContainer = $CharacterContainer/ValuesSplit/ValuesVBox/StatVBox/StatScroll/CharStatsContainer
@onready var char_skill_container: VBoxContainer = $CharacterContainer/ValuesSplit/ValuesVBox/SkillVBox/SkillScroll/CharSkillContainer
@onready var char_tree: Tree = $CharacterContainer/BasicDataSplit/CharacterTreeContainer/CharTree
@onready var char_traits_container: VBoxContainer = $CharacterContainer/ValuesSplit/TraitsVbox/ScrollContainer/CharTraitsContainer


func _ready() -> void:
	if Engine.is_editor_hint() and get_tree().edited_scene_root == self:
		return
	
	set_ui_enabled(false)
	update_genders()
	update_talent_nodes()
	update_species_data()
	
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
	character_data_tree.data_changed.connect(_something_changed)
	char_tree.character_selected.connect(_on_character_selected)


func _on_add_data_pressed(data_key: String, data: Variant) -> void:
	character_data_tree.add_data(data_key, data)
	_something_changed()


func _something_changed(_arg: Variant = null) -> void:
	if _unsaved:
		return
	_unsaved = true


func update_genders() -> void:
	gender_option_button.clear()
	var gender_obg: CharacterSheet = CharacterSheet.new()
	var map: Dictionary = gender_obg.get_script().get_script_constant_map()
	var genders: Dictionary = map[&"Gender"]
	
	for gender:String in genders.keys():
		gender_option_button.add_item(
				gender.capitalize())
		gender_option_button.set_item_metadata(
				-1,
				genders[gender])


func update_species_data(species_catalog: SpeciesCatalog = null) -> void:
	var currently_selected: StringName = &"" if species_option_button.selected == -1 else species_option_button.get_item_metadata(species_option_button.selected)
	var new_index: int = -1
	
	species_option_button.clear()
	
	var species_path: String = EditorNFPlugin.get_project_settings_path("species")
	
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
					var parent: String = String(pre_res.get_parent_species(species_id))
					if parent != "":
						text += " (" + parent + ")"
					species_option_button.add_item(text)
					species_option_button.set_item_metadata(-1, species_id)
	else:
		var species:Array[StringName] = species_catalog.species()
		species.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
		if not currently_selected.is_empty():
			new_index = species.find(currently_selected)
		for species_id in species:
			var text: String = String(species_id).capitalize()
			var parent: String = String(species_catalog.get_parent_species(species_id))
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
	#var stat_block: StatBlock = StatBlock.new()
	
	var skill_set: SkillSet = SkillSet.new()

	var trait_block: TraitBlock = TraitBlock.new()
	
	var stats_data: Dictionary[StringName, int] = StatBlock.stats()
	var stats: Array[String] = []
	stats.assign(stats_data.keys())
	stats.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	var stat_map: Dictionary[StringName, HBoxContainer] = {}
	for existing_stat in char_stats_container.get_children():
		char_stats_container.remove_child(existing_stat)
		if existing_stat.get_meta(&"stat_id") in stats:
			stat_map[existing_stat.get_meta(&"stat_id")] = existing_stat
		else:
			existing_stat.queue_free()
		
	for stat_id in stats:
		if stat_map.has(stat_id):
			char_stats_container.add_child(stat_map[stat_id])
			stat_map.erase(stat_id)
		else:
			var stat = create_stat_item(stat_id, stats_data[stat_id])
			char_stats_container.add_child(stat)
	
	for remaining_stat in stat_map:
		stat_map[remaining_stat].queue_free()
	
	var skills: Array[StringName] = SkillSet.skills()
	skills.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	var skill_map: Dictionary[StringName, HBoxContainer] = {}
	for existing_skill in char_skill_container.get_children():
		char_skill_container.remove_child(existing_skill)
		if skills.has(existing_skill.get_meta(&"skill_id")):
			skill_map[existing_skill.get_meta(&"skill_id")] = existing_skill
		else:
			existing_skill.queue_free()
	
	for skill_id in skills:
		if skill_map.has(skill_id):
			char_skill_container.add_child(skill_map[skill_id])
			skill_map.erase(skill_id)
		else:
			var skill = create_skill_item(skill_id, skill_set.get(skill_id))
			char_skill_container.add_child(skill)
	
	for remaining_skill in skill_map.keys():
		skill_map[remaining_skill].queue_free()
	

	var traits: Array[StringName] = TraitBlock.traits()
	traits.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	var trait_map: Dictionary[StringName, HBoxContainer] = {}
	for existing_trait in char_traits_container.get_children():
		char_traits_container.remove_child(existing_trait)
		if traits.has(existing_trait.get_meta(&"trait_id")):
			trait_map[existing_trait.get_meta(&"trait_id")] = existing_trait
		else:
			existing_trait.queue_free()
	
	for trait_id in traits:
		if trait_map.has(trait_id):
			char_traits_container.add_child(trait_map[trait_id])
			trait_map.erase(trait_id)
		else:
			var new_trait: HBoxContainer = create_trait_item(trait_id, trait_block.get(trait_id))
			char_traits_container.add_child(new_trait)
	for remaining_trait in trait_map.keys():
		trait_map[remaining_trait].queue_free()


func _on_new_character_pressed() -> void:
	# For testing
	#listen_selected = false
	#var test_resource: CharacterSheet = CharacterSheet.new()
	#test_resource.resource_path = "res://new_character.tres"
	#if test_resource.stats == null:
		#test_resource.stats = StatBlock.new()
	#if test_resource.skills == null:
		#test_resource.skills = SkillSet.new()
	#if test_resource.traits == null:
		#test_resource.traits = TraitBlock.new()
	#char_tree.create_character(test_resource, true)
	#load_character(test_resource)
	#current_sheet = test_resource
	#listen_selected = true
	#set_ui_enabled(true)
	#return
	# -----------
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
		new_resource.resource_path = dialog_result[1]
		if new_resource.stats == null:
			new_resource.stats = StatBlock.new()
		if new_resource.skills == null:
			new_resource.skills = SkillSet.new()
		if new_resource.traits == null:
			new_resource.traits = TraitBlock.new()
		ResourceSaver.save(new_resource, dialog_result[1])
		char_tree.create_character(new_resource, true, false)
		load_character(new_resource)
		current_sheet = new_resource
		_unsaved = false
		set_ui_enabled(true)
	
	resource_selector.queue_free()


func _on_open_character_pressed() -> void:
	#var id_creator := LineEditConfirmationDialog.new()
	#id_creator.line_placeholder_text = "Character ID"
	#id_creator.allow_empty = false
	#id_creator.use_blacklist = true
	#id_creator.character_blacklist.append(" ")
	#id_creator.text_blacklist.assign(_character_resource.characters())
	#id_creator.title = "Create Character"
	#id_creator.ok_button_text = "Create"
	#add_child(id_creator)
	#id_creator.show()
	#id_creator.grab_text_focus()
	#
	#var result: Array = await id_creator.dialog_finished
	#
	#if result[0]:
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
	if species_option_button.selected == -1:
		return
	
	var data: Dictionary[String, Dictionary] = NexusForge.Species._species_tree_data(species_option_button.get_item_metadata(species_option_button.selected))
	
	var stats: Dictionary[StringName, int] = data["stats"]
	var skills: Dictionary[StringName, int] = data["skills"]
	var traits: Dictionary[StringName, int] = data["traits"]
	
	for stat in char_stats_container.get_children():
		var target_stat: StringName = stat.get_meta(&"stat_id")
		if stats.has(target_stat):
			stat.get_child(1).set_value_no_signal(
					stats[target_stat])
	
	for skill in char_skill_container.get_children():
		var target_skill: StringName = skill.get_meta(&"skill_id")
		if stats.has(target_skill):
			skill.get_child(1).set_value_no_signal(
				skills[target_skill])
	
	for child in char_traits_container.get_children():
		var target_trait: StringName = child.get_meta(&"trait_id")
		if traits.has(target_trait):
			child.get_child(1).set_value_no_signal(
					traits[target_trait])


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
	load_species_data_btn.disabled = disabled
	
	for item in char_stats_container.get_children():
		item.get_child(1).editable = enabled
	
	for item in char_skill_container.get_children():
		item.get_child(1).editable = enabled
	
	for item in char_traits_container.get_children():
		item.get_child(1).editable = enabled
	
	ui_enabled = enabled


func reset_stats() -> void:
	for item in char_stats_container.get_children():
		if item is HBoxContainer:
			item.get_child(1).set_value_no_signal(0.0)


func reset_skills() -> void:
	for item in char_skill_container.get_children():
		if item is HBoxContainer:
			item.get_child(1).set_value_no_signal(item.get_meta(&"default_value", 0.0))


func reset_traits() -> void:
	for item in char_traits_container.get_children():
		if item is HBoxContainer:
			item.get_child(1).set_value_no_signal(item.get_meta(&"default_value", 0.0))


func save_current_character() -> void:
	current_sheet.id = StringName(char_id_line.text.strip_edges())
	current_sheet.name = char_name_line.text.strip_edges()
	current_sheet.species = &"" if species_option_button.selected == -1 else species_option_button.get_item_metadata(species_option_button.selected)
	current_sheet.gender = gender_option_button.get_item_metadata(gender_option_button.selected)
	current_sheet.custom_data.clear()
	current_sheet.custom_data.assign(
			character_data_tree.get_data())
	
	for stat in char_stats_container.get_children():
		current_sheet.stats.set(
				stat.get_meta(&"stat_id"), int(stat.get_child(1).value))
	
	for skill in char_skill_container.get_children():
		current_sheet.skills.set(
				skill.get_meta(&"skill_id"),
				int(skill.get_child(1).value))
	
	for trait_item in char_traits_container.get_children():
		current_sheet.traits.set(
				trait_item.get_meta(&"trait_id"),
				int(trait_item.get_child(1).value))
	
	char_tree.set_unsaved(current_sheet.id, _unsaved)


func has_unsaved_files() -> bool:
	return char_tree.is_any_unsaved()


func save() -> void:
	if current_sheet != null:
		save_current_character()
	var unsaved_characters: Array[CharacterSheet] = char_tree.get_unsaved()
	for item in unsaved_characters:
		ResourceSaver.save(current_sheet)
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
		if stat is HBoxContainer:
			var stat_range: ValueRange = sheet.stats.get(stat.get_meta(&"stat_id"))
			stat.get_child(1).set_value_no_signal(stat_range.value if stat_range != null else 1.0)
	
	for skill in char_skill_container.get_children():
		if skill is HBoxContainer:
			skill.get_child(1).set_value_no_signal(
					sheet.skills.get(skill.get_meta(&"skill_id")))
	
	for child in char_traits_container.get_children():
		if child is HBoxContainer:
			child.get_child(1).set_value_no_signal(
					sheet.traits.get(child.get_meta(&"trait_id")))


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
func create_stat_item(stat_id: StringName, type: int) -> HBoxContainer:
	var new_stat: HBoxContainer = HBoxContainer.new()
	var stat_label: Label = Label.new()
	var new_value: SpinBox = SpinBox.new()
	
	stat_label.text = String(stat_id).capitalize()
	stat_label.tooltip_text = stat_label.text
	stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_label.size_flags_stretch_ratio = 2.0
	stat_label.custom_minimum_size.y = 32
	stat_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stat_label.mouse_filter = Control.MOUSE_FILTER_STOP
	
	new_value.allow_greater = true
	new_value.allow_lesser = true
	new_value.custom_minimum_size.y = 32
	new_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_value.size_flags_stretch_ratio = 3.0
	new_value.value = 0
	if type == TYPE_INT:
		new_value.step = 1.0
	else:
		new_value.step = 0.01
	new_value.value_changed.connect(_something_changed)
	new_value.editable = ui_enabled
	
	new_stat.set_meta(&"stat_id", stat_id)
	
	new_stat.add_child(stat_label)
	new_stat.add_child(new_value)
	
	return new_stat


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
	new_value.custom_minimum_size.y = 32
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
	trait_label.custom_minimum_size.y = 32
	trait_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	trait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	trait_label.mouse_filter = Control.MOUSE_FILTER_STOP
	
	new_value.allow_greater = true
	new_value.allow_lesser = true
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
