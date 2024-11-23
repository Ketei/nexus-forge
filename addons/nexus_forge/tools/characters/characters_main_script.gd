@tool
extends Control


var _characters_resource: NFCharacterDBRes = null
var _races_resource: NFRacesRes = null:
	set(new_races):
		if _races_resource != null:
			_races_resource.changed.disconnect(on_races_changed)
		_races_resource = new_races
		_races_resource.changed.connect(on_races_changed)
var _factions_resource: NFFactionRes = null:
	set(new_factions):
		if _factions_resource != null:
			_factions_resource.changed.disconnect(on_factions_changed)
		_factions_resource = new_factions
		_factions_resource.changed.connect(on_factions_changed)
var _talents_resource: NFTalentsRes = null:
	set(new_talents):
		if _talents_resource != null:
			_talents_resource.changed.disconnect(on_talents_changed)
		_talents_resource = new_talents
		_talents_resource.changed.connect(on_talents_changed)

var _character_selected: String = ""
var _block_switch: bool = false
var _character_memory: Dictionary = {}
var no_db_container: PanelContainer = null

@onready var sprite_frame_line: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SpriteFrameContainer/LinePanel/LineContainer/SpriteFrameLine
@onready var select_sprites_button: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SpriteFrameContainer/LinePanel/LineContainer/SelectSpritesButton
@onready var sound_path_line: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SoundsContainer/DataContainer/PanelContainer/HBoxContainer/SoundPathLine
@onready var select_sound_path_button: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SoundsContainer/DataContainer/PanelContainer/HBoxContainer/SelectSoundPathButton
@onready var play_sound_button: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SoundsContainer/DataContainer/PlaySoundButton


@onready var data_set_tabs: TabContainer = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs

@onready var no_char_center: CenterContainer = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/NoCharCenter

@onready var chara_id_label: Label = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/HBoxContainer/CharaIDLabel

@onready var copy_id_btn: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/HBoxContainer/CopyIDBtn
@onready var add_sprite_button: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/SheetsContainer/HeaderContainer/AddSpriteButton
@onready var add_int_button: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddIntButton
@onready var add_float_button: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddFloatButton
@onready var add_bool_button: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddBoolButton
@onready var add_string_button: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddStringButton
@onready var new_character: Button = $MainContainer/DataSplitContainer/CharacterSelectorContainer/ButtonContainer/NewCharacter
@onready var import_character_button: Button = $MainContainer/DataSplitContainer/CharacterSelectorContainer/ButtonContainer/ImportCharacterButton
@onready var add_stat_btn: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs/StatsContainer/HeaderContainer/AddStatBtn
@onready var add_variant_button: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs/VariantsContainer/TitleContainer/AddVariantButton
#@onready var refresh_button: Button = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/PortraitContainer/SpriteFrameContainer/Header/RefreshButton

#@onready var animated_chk_btn: CheckButton = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/PortraitContainer/HBoxContainer/InfoContainer/AnimationContainer/AnimatedChkBtn

@onready var search_character_line: LineEdit = $MainContainer/DataSplitContainer/CharacterSelectorContainer/ButtonContainer/SearchCharacterLine
@onready var custom_data_search_line: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CustomDataSearchLine
@onready var flag_search_line: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/VBoxContainer/FlagsContainer/FlagSearchLine
@onready var faction_search_line: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/VBoxContainer/FactionsContainer/FactionSearchLine
@onready var char_name_line: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CharNameContainer/CharNameLine
@onready var line_edit: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs/StatsContainer/HeaderContainer/LineEdit
@onready var skill_search_line: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs/SkillsContainer/SkillSearchLine
@onready var search_perk_ln_edt: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs/PerksContainer/SearchPerkLnEdt
@onready var search_variant_ln_edt: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs/VariantsContainer/TitleContainer/SearchVariantLnEdt
#@onready var sprite_frame_line: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/PortraitContainer/SpriteFrameContainer/LinePanel/LineContainer/SpriteFrameLine
#@onready var sound_path_line: LineEdit = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/PortraitContainer/HBoxContainer/InfoContainer/SoundsContainer/DataContainer/PanelContainer/HBoxContainer/SoundPathLine

@onready var characters_tree: Tree = $MainContainer/DataSplitContainer/CharacterSelectorContainer/CharactersTree
@onready var factions_tree: Tree = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/VBoxContainer/FactionsContainer/FactionsTree
@onready var sprite_sheets_tree: Tree = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/SheetsContainer/SpriteSheetsTree
@onready var custom_data_tree: Tree = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CustomDataTree
@onready var flags_tree: Tree = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/VBoxContainer/FlagsContainer/FlagsTree
@onready var stats_tree: Tree = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs/StatsContainer/StatsTree
@onready var skills_tree: Tree = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs/SkillsContainer/SkillsTree
@onready var perks_tree: Tree = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs/PerksContainer/PerksTree
@onready var variants_tree: Tree = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/DataSetTabs/VariantsContainer/VariantsTree

@onready var char_name_color: ColorPickerButton = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CharNameContainer/CharNameColor
@onready var species_option_button: OptionButton = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/SpeciesContainer/SpeciesOptionButton
@onready var race_option_button: OptionButton = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/RaceContainer/RaceOptionButton
@onready var gender_option_button: OptionButton = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/GenderContainer/GenderOptionButton
#@onready var anim_opt_btn: OptionButton = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/PortraitContainer/HBoxContainer/InfoContainer/AnimationContainer/AnimOptBtn

#@onready var fps_spn_bx: SpinBox = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/PortraitContainer/HBoxContainer/InfoContainer/FPSContainer/FPSSpnBx

#@onready var no_db_container: PanelContainer = $NoDBContainer

@onready var main_container: VBoxContainer = $MainContainer

@onready var data_select_dialog: FileDialog = $ComponentNode/DataSelectDialog
#@onready var id_select_panel: PanelContainer = $IDSelectPanel

#@onready var races_missing_container: HBoxContainer = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer
#@onready var char_db_container: HBoxContainer = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/CharDBContainer
#@onready var race_res_container: HBoxContainer = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/RaceResContainer

#@onready var success_char_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/CharDBContainer/SuccessCharTexture
#@onready var failure_char_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/CharDBContainer/FailureCharTexture
#@onready var success_races_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/RaceResContainer/SuccessRacesTexture
#@onready var failure_races_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/RaceResContainer/FailureRacesTexture
#
#@onready var success_facc_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/FaccResContainer/SuccessFaccTexture
#@onready var failure_facc_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/FaccResContainer/FailureFaccTexture

#@onready var chara_button_container: VBoxContainer = $NoDBContainer/CenterContainer/InfoContainer/ButtonsContainer/CharaButtonContainer
@onready var data_container: VBoxContainer = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer

#@onready var success_talent_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/TalentsResContainer/SuccessFaccTexture
#@onready var failure_talent_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/TalentsResContainer/FailureFaccTexture

@onready var main_menu: MenuButton = $MainContainer/DataSplitContainer/CharacterSelectorContainer/HBoxContainer/MenusContainer/MainMenu
@onready var type_stream_player: AudioStreamPlayer = $ComponentNode/TypeStreamPlayer

#@onready var portrait_texture: PortraitTextureRect = $MainContainer/DataSplitContainer/VBoxContainer/DataPanel/DataContainer/MainDataContainer/ExtraContainer/PortraitContainer/HBoxContainer/PortraitTexture


func _ready() -> void:
	#var res_path: String = ProjectSettings.get_setting(NFCharacterDBRes.SETTINGS_PATH, "")
	#var races_path: String = ProjectSettings.get_setting(NFRacesRes.SETTINGS_PATH, "")
	#var factions_path: String = ProjectSettings.get_setting(NFFactionRes.SETTINGS_PATH, "")
	#var talents_path: String = ProjectSettings.get_setting(NFTalentsRes.SETTINGS_PATH, "")
	
	var tabs := data_set_tabs.get_tab_bar()
	tabs.set_tab_title(0, "Stats")
	tabs.set_tab_title(1, "Skills")
	tabs.set_tab_title(2, "Perks")
	tabs.set_tab_title(3, "Variants")
	
	if check_for_resources():
		load_characters()
		load_races()
		load_skills()
		load_factions()
		main_container.visible = true
	else:
		main_container.visible = false
		no_db_container = preload("res://addons/nexus_forge/tools/characters/kinds_no_db.tscn").instantiate()
		add_child(no_db_container)
		no_db_container.check_res_pressed.connect(on_check_resources_pressed)
		no_db_container.load_db_pressed.connect(on_open_char_resource)
		no_db_container.create_db_pressed.connect(on_create_new_resource)
		no_db_container.visible = true
		no_db_container.set_tal_success(_talents_resource != null)
		no_db_container.set_facc_success(_factions_resource != null)
		no_db_container.set_race_success(_races_resource != null)
		no_db_container.set_char_success(_characters_resource != null)
	
	main_menu.get_popup().id_pressed.connect(on_menu_pressed)
	data_select_dialog.file_selected.connect(on_dialog_ok)
	#create_db_button.pressed.connect(on_create_new_resource)
	#load_db_button.pressed.connect(on_open_char_resource)
	#id_select_panel.id_changed.connect(on_id_selector_id_changed)
	#id_select_panel.id_submitted.connect(on_id_submitted)
	new_character.pressed.connect(on_create_new_character)
	import_character_button.pressed.connect(on_import_character)
	copy_id_btn.pressed.connect(on_copy_id_btn_pressed)
	
	add_int_button.pressed.connect(create_custom_data.bind(TYPE_INT))
	add_float_button.pressed.connect(create_custom_data.bind(TYPE_FLOAT))
	add_bool_button.pressed.connect(create_custom_data.bind(TYPE_BOOL))
	add_string_button.pressed.connect(create_custom_data.bind(TYPE_STRING))
	
	characters_tree.character_selected.connect(on_character_selected)
	
	species_option_button.item_selected.connect(on_species_selected)
	race_option_button.item_selected.connect(on_race_selected)
	
	sprite_sheets_tree.sheets_updated.connect(on_sheets_updated)
	sprite_sheets_tree.id_edited.connect(on_ref_id_edited)
	
	select_sprites_button.pressed.connect(on_load_portrait_pressed)
	select_sound_path_button.pressed.connect(on_load_sound_pressed)
	play_sound_button.pressed.connect(on_play_sound_pressed)
	sound_path_line.text_changed.connect(on_sound_path_set)
	
	stats_tree.stat_edited.connect(on_stat_id_edited)


func on_play_sound_pressed() -> void:
	if sprite_frame_line.text.is_empty():
		return
	
	if type_stream_player.stream == null:
		type_stream_player.stream = load(sprite_frame_line.text)
	
	type_stream_player.play()


func on_sound_path_set(path: String) -> void:
	play_sound_button.disabled = path.is_empty()


func on_menu_pressed(id: int) -> void:
	match id:
		0:
			on_create_new_character()
		1:
			save_characters()
		2:
			on_import_character()


func on_talents_changed() -> void:
	var skill_config: Dictionary = skills_tree.get_skill_data()
	var perk_config: Dictionary = perks_tree.get_selected_perks()

	load_skills()
	load_perks()
	
	for skill in _talents_resource.get_skills():
		if skill_config.has(skill):
			skills_tree.set_skill(
					skill,
					skill_config[skill]["level"])

	for perk in _talents_resource.get_perks():
		if perk_config.has(perk):
			perks_tree.set_perk(perk, true, perk_config[perk]["level"])


func load_factions() -> void:
	factions_tree.clear_factions()
	for faction in _factions_resource.get_factions():
		factions_tree.add_faction(faction, _factions_resource.get_faction_name(faction))


func on_factions_changed() -> void:
	var current_factions: Dictionary = factions_tree.get_factions()
	load_factions()
	for faction in _factions_resource.get_factions():
		if current_factions.has(faction):
			factions_tree.set_faction(faction, true, current_factions[faction]["rank"])


func on_races_changed() -> void:
	var current_species: String = ""
	var current_race: String = ""
	var current_gender: int = -1
	var gender_selected: bool = false
	
	if species_option_button.selected != -1:
		current_species = species_option_button.get_item_metadata(species_option_button.selected)
	if race_option_button.selected != -1:
		current_race = race_option_button.get_item_metadata(race_option_button.selected)
	if gender_option_button.selected != -1:
		current_gender = gender_option_button.get_item_metadata(gender_option_button.selected)
		gender_selected = true
	
	load_races()
	
	if not current_species.is_empty():
		for option_idx in range(species_option_button.item_count):
			if species_option_button.get_item_metadata(option_idx) == current_species:
				species_option_button.select(option_idx)
				on_species_selected(option_idx)
				break
	if not current_race.is_empty():
		for race_idx in range(race_option_button.item_count):
			if race_option_button.get_item_metadata(race_idx) == current_race:
				race_option_button.select(race_idx)
				on_race_selected(race_idx)
				break
	if gender_selected:
		for gender_idx in range(gender_option_button.item_count):
			if gender_option_button.get_item_metadata(gender_idx) == current_gender:
				gender_option_button.select(gender_idx)
				break


func load_perks() -> void:
	perks_tree.clear_perks()
	for perk in _talents_resource.get_perks():
		perks_tree.add_perk(perk, _talents_resource.get_perk_level(perk))


func load_skills() -> void:
	skills_tree.clear_skills()
	for skill in _talents_resource.get_skills():
		skills_tree.add_skill(
				skill,
				_talents_resource.get_skill_name(skill),
				_talents_resource.get_skill_limit(skill))


func on_species_selected(index_selected: int) -> void:
	var species: String = species_option_button.get_item_metadata(index_selected)
	var race_id: int = 0
	race_option_button.clear()
	for race in _races_resource.get_races(species):
		race_option_button.add_item(
				Strings.capitalize(_races_resource.get_race_name(species, race)),
				race_id)
		race_option_button.set_item_metadata(
				race_option_button.get_item_index(race_id),
				race)
		race_id += 1
	if race_id != 0:
		race_option_button.select(0)
		on_race_selected(0)


func on_race_selected(index_selected: int) -> void:
	var species: String = species_option_button.get_item_metadata(species_option_button.selected)
	var race: String = race_option_button.get_item_metadata(race_option_button.selected)
	var gender_id: int = 0
	
	gender_option_button.clear()
	
	for gender in _races_resource.get_race_genders(species, race):
		gender_option_button.add_item(Strings.capitalize(NFRacesRes.get_gender_name(gender)), gender_id)
		gender_option_button.set_item_metadata(
			gender_option_button.get_item_index(gender_id),
			gender)
		gender_id += 1


func on_character_selected(character_id: String):
	if _block_switch:
		return
	_block_switch = true
	_character_selected = character_id
	characters_tree.ensure_selected(character_id)
	_block_switch = false


func on_copy_id_btn_pressed() -> void:
	DisplayServer.clipboard_set(chara_id_label.text)


func _set_character_selected(character_id: String) -> void:
	_character_selected = character_id
	
	sprite_sheets_tree.clear_sprite_sheets()
	custom_data_tree.clear_custom_data()
	factions_tree.clear_checks()
	stats_tree.clear_stats()
	perks_tree.clear_checks()
	variants_tree.clear_variants()
	type_stream_player.stream = null
	
	if _character_memory.has(character_id):
		var character_data: Dictionary = _character_memory[character_id]
		chara_id_label.text = character_id
		char_name_line.text = character_data["character_name"]
		char_name_color.color = character_data["color"]
		sprite_frame_line.text = character_data["sprite_frames_path"]
		sound_path_line.text = character_data["typing_sound_path"]
		select_species(character_data["character_species"])
		select_race(character_data["character_race"])
		select_gender(character_data["character_gender"])
		flags_tree.set_flags(character_data["flags"])
		
		for sheet in character_data["sprite_sheets"]:
			sprite_sheets_tree.create_sheet_path(
					sheet,
					character_data["sprite_sheets"][sheet])
		
		for data in character_data["custom_data"]:
			custom_data_tree.create_custom_value(
				character_data["custom_data"][data],
				data)
		for faction in character_data["factions"]:
			factions_tree.set_faction(
					faction,
					true,
					character_data["factions"][faction]["rank"])
		for stat in character_data["stats"]:
			stats_tree.create_stat(
					stat,
					character_data["stats"][stat]["min"],
					character_data["stats"][stat]["max"])
		for perk in character_data["perks"]:
			perks_tree.set_perk(
					perk,
					true,
					character_data["perks"][perk]["level"])
		for skill in character_data["skills"]:
			skills_tree.set_skill(
					skill,
					character_data["skills"][skill]["level"])
		for variant in character_data["variants"]:
			variants_tree.create_variant(
					variant,
					character_data["variants"][variant]["sheet"],
					character_data["variants"][variant]["stats"])
	else:
		var character_data: CharacterDefinition = characters_tree.get_character_data(character_id)
		
		if character_data == null:
			printerr("[CHARACTERS] Something went wrong while opening data from: " + character_id)
			return
		
		chara_id_label.text = character_data.character_id
		char_name_line.text = character_data.character_name
		char_name_color.color = character_data.character_name_color
		sprite_frame_line.text = character_data.sprite_frames_path
		sound_path_line.text = character_data.typing_sound_path
		select_species(character_data.character_species)
		select_race(character_data.character_race)
		select_gender(character_data.character_gender)
		flags_tree.set_flags(character_data.flags)
		
		for sheet in character_data.get_sprite_sheet_ids():
			sprite_sheets_tree.create_sheet_path(
					sheet,
					character_data.get_sprite_sheet_path(sheet))
		for data in character_data.get_custom_data_ids():
			custom_data_tree.create_custom_value(
				character_data.get_custom_data(data),
				data)
		for faction in character_data.get_characer_factions():
			factions_tree.set_faction(
					faction,
					true,
					character_data.get_faction_rank(faction))
		for stat in character_data.get_stat_ids():
			var stat_range
			stats_tree.create_stat(
					stat,
					character_data.get_stat_min(stat),
					character_data.get_stat_max(stat))
		for perk in character_data.get_perk_ids():
			perks_tree.set_perk(
					perk,
					true,
					character_data.get_perk_level(perk))
		for skill in character_data.get_skill_ids():
			skills_tree.set_skill(
					skill,
					character_data.get_skill_level(skill))
		for variant in character_data.get_variants():
			variants_tree.create_variant(
					variant,
					character_data.get_variant_sprite_sheet(variant),
					character_data.get_variant_mods(variant))


func check_for_resources() -> bool:
	var character_path: String = ProjectSettings.get_setting(NFCharacterDBRes.SETTINGS_PATH, "")
	var race_path: String = ProjectSettings.get_setting(NFRacesRes.SETTINGS_PATH, "")
	var factions_path: String = ProjectSettings.get_setting(NFFactionRes.SETTINGS_PATH, "")
	var talents_path: String = ProjectSettings.get_setting(NFTalentsRes.SETTINGS_PATH, "")
	
	if not character_path.is_empty() and ResourceLoader.exists(character_path):
		var char_preload: Resource = load(character_path)
		if char_preload is NFCharacterDBRes:
			_characters_resource = char_preload
	
	if not race_path.is_empty() and ResourceLoader.exists(race_path):
		var race_preload: Resource = load(race_path)
		if race_preload is NFRacesRes:
			_races_resource = race_preload
	
	if not factions_path.is_empty() and ResourceLoader.exists(factions_path):
		var faction_preload: Resource = load(factions_path)
		if faction_preload is NFFactionRes:
			_factions_resource = faction_preload
	
	if not talents_path.is_empty() and ResourceLoader.exists(talents_path):
		var talent_preload: Resource = load(talents_path)
		if talent_preload is NFTalentsRes:
			_talents_resource = talent_preload
	
	if _characters_resource == null or _races_resource == null or _factions_resource == null or _talents_resource == null:
		if no_db_container != null:
			no_db_container.set_tal_success(_talents_resource != null)
			no_db_container.set_facc_success(_factions_resource != null)
			no_db_container.set_race_success(_races_resource != null)
			no_db_container.set_char_success(_characters_resource != null)
		return false
	else:
		return true


func on_check_resources_pressed() -> void:
	if check_for_resources():
		load_characters()
		load_races()
		load_skills()
		load_factions()
		main_container.visible = true
		no_db_container.visible = false
	else:
		main_container.visible = false
		no_db_container.visible = true


func create_sheet(sprite_id: String, sprite_path: String) -> void:
	sprite_sheets_tree.create_sheet_path(sprite_id, sprite_path)
	variants_tree.update_refs(sprite_sheets_tree.get_variant_ids())


func on_ref_id_edited(from: String, to: String) -> void:
	variants_tree.update_ref_id(from, to)


func on_stat_id_edited(from: String, to: String) -> void:
	variants_tree.update_stat_id(from, to)


func on_sheets_updated() -> void:
	variants_tree.update_refs(sprite_sheets_tree.get_variant_ids())


func select_species(species_id: String) -> void:
	var found: bool = false
	for species_idx in range(species_option_button.item_count):
		if species_option_button.get_item_text(species_idx) == species_id:
			species_option_button.select(species_idx)
			on_species_selected(species_idx)
			found = true
			break
	if not found:
		printerr(str("[CHARACTERS] Species ", species_id, " not found."))


func select_race(race_id: String) -> void:
	var found: bool = false
	for race_idx in range(race_option_button.item_count):
		if race_option_button.get_item_text(race_idx) == race_id:
			race_option_button.select(race_idx)
			on_species_selected(race_idx)
			found = true
			break
	if not found:
		printerr(str("[CHARACTERS] Species ", race_id, " not found."))


func select_gender(gender: int) -> void:
	var found: bool = false
	for gender_idx in range(gender_option_button.item_count):
		if gender_option_button.get_item_metadata(gender_idx) == gender:
			gender_option_button.select(gender_idx)
			found = true
			break
	if not found:
		printerr(str("[CHARACTERS] Gender ", gender, " not found."))



func on_load_sound_pressed() -> void:
	data_select_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	data_select_dialog.clear_filters()
	data_select_dialog.add_filter("*.ogg,*.mp3,*.wav", "Audio Files")
	data_select_dialog.dialog_mode = 2
	data_select_dialog.show()


func on_load_portrait_pressed() -> void:
	data_select_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	data_select_dialog.clear_filters()
	data_select_dialog.add_filter("*.tres,*.res", "Resources")
	data_select_dialog.dialog_mode = 3
	data_select_dialog.show()


func on_create_new_character() -> void:
	data_select_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	data_select_dialog.clear_filters()
	data_select_dialog.add_filter("*.tres", "Resources")
	data_select_dialog.dialog_mode = 1
	data_select_dialog.show()


func on_import_character() -> void:
	data_select_dialog.dialog_mode = 1
	data_select_dialog.clear_filters()
	data_select_dialog.add_filter("*.tres", "Resources")
	data_select_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	data_select_dialog.show()


func on_create_new_resource() -> void:
	data_select_dialog.dialog_mode = 0
	data_select_dialog.clear_filters()
	data_select_dialog.add_filter("*.tres", "Resources")
	data_select_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	data_select_dialog.show()


func on_open_char_resource() -> void:
	data_select_dialog.dialog_mode = 0
	data_select_dialog.clear_filters()
	data_select_dialog.add_filter("*.tres", "Resources")
	data_select_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	data_select_dialog.show()


func on_dialog_ok(resource_path: String) -> void:
	match data_select_dialog.dialog_mode:
		0: # Resource
			if data_select_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
				var new_chara_db := NFCharacterDBRes.new()
				ResourceSaver.save(
						new_chara_db,
						resource_path)
				_characters_resource = new_chara_db
			else:
				if not ResourceLoader.exists(resource_path):
					return
			
				var preload_resource: Resource = load(resource_path)
			
				if preload_resource is NFCharacterDBRes:
					_characters_resource = preload_resource
					_characters_resource.validate_characters()
			
			if _characters_resource != null:
				ProjectSettings.set_setting(NFCharacterDBRes.SETTINGS_PATH, resource_path)
				ProjectSettings.save()
				load_characters()
				
				if check_for_resources():
					no_db_container.visible = false
					if no_db_container != null:
						no_db_container.queue_free()
					main_container.visible = true
		1: # Character
			if data_select_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
				var new_char := CharacterDefinition.new()
				#new_char.character_id = data_select_dialog.character_id
				if ResourceSaver.save(new_char, resource_path) == OK:
					if not _characters_resource.has_character(data_select_dialog.character_id):
						characters_tree.add_character(resource_path)
					_characters_resource.set_character(data_select_dialog.character_id, resource_path)
					_characters_resource.save()
			else:
				if not ResourceLoader.exists(resource_path):
					return
				
				var res_pre: Resource = load(resource_path)
				
				if res_pre is not CharacterDefinition:
					return
				
				if _characters_resource.has_character(res_pre.character_id):
					printerr(str("[CHARACTERS] A character with ID \"", res_pre.character_id, "\" already exists. ID will be changed."))
				
				_characters_resource.set_character(characters_tree.add_character(resource_path), resource_path)
				_characters_resource.save()
		2: # Sound
			sound_path_line.text = resource_path
		3: # Sprite
			var frames_preload: Resource = load(resource_path)
			if frames_preload is SpriteFrames:
				sprite_frame_line.text = resource_path
			else:
				printerr("[KINDS] Selected resource isn't SpriteFrames")
		


func _has_all_required_resources() -> bool:
	return _characters_resource != null and _races_resource != null and _factions_resource != null and _talents_resource != null


func load_races() -> void:
	gender_option_button.clear()
	species_option_button.clear()
	
	var gender_names = NFRacesRes.Genders.keys()
	var gender_idx: int = 0
		
	for gender in NFRacesRes.Genders.values():
		if NFRacesRes.GENDER_DATA[gender]["icon"].is_empty():
			gender_option_button.add_item(
					Strings.capitalize(gender_names[gender]))
		else:
			gender_option_button.add_icon_item(
					load(NFRacesRes.GENDER_DATA[gender]["icon"]),
					Strings.capitalize(gender_names[gender]))
		gender_option_button.set_item_metadata(gender_idx, gender)
		gender_idx += 1
	
	var species_id: int = 0
	
	for species in _races_resource.get_species():
		species_option_button.add_item(Strings.capitalize(_races_resource.get_species_name(species)), species_id)
		species_option_button.set_item_metadata(species_option_button.get_item_index(species_id), species)
		species_id += 1
	
	if species_id != 0:
		species_option_button.select(0)
		on_species_selected(0)


func clear_character() -> void:
	char_name_line.clear()
	char_name_color.color = Color.WHITE
	species_option_button.select(-1)
	race_option_button.select(-1)
	gender_option_button.select(-1)
	custom_data_search_line.clear()
	sprite_frame_line.clear()
	sound_path_line.clear()


func create_custom_data(data_type: int) -> void:
	custom_data_tree.create_custom_value(data_type)


func load_characters() -> void:
	for character in _characters_resource._characters:
		characters_tree.add_character(_characters_resource._characters[character])


func store_current() -> void:
	if _character_selected.is_empty():
		return
	_character_memory[_character_selected] = {
		"character_name": char_name_line.text.strip_edges(),
		"color": char_name_color.color,
		"sprite_frames_path": sprite_frame_line.text,
		"typing_sound_path": sound_path_line.text,
		"character_species": species_option_button.get_item_text(species_option_button.selected),
		"character_race": race_option_button.get_item_text(race_option_button.selected),
		"character_gender": gender_option_button.get_item_metadata(gender_option_button.selected),
		"flags": flags_tree.get_flags(),
		"sprite_sheets": sprite_sheets_tree.get_sprites_data(),
		"custom_data": custom_data_tree.get_custom_data(),
		"factions": factions_tree.get_factions(),
		"stats": stats_tree.get_stats(),
		"perks": perks_tree.get_selected_perks(),
		"skills": skills_tree.get_skill_data(),
		"variants": variants_tree.get_stat_variant_data()
	}


func save_characters() -> void:
	store_current()
	for character in _character_memory:
		var char_path: Dictionary = characters_tree.get_serialized_data(character)
		var character_res: CharacterDefinition = CharacterDefinition.new()
		var ch: Dictionary = _character_memory[character]
		character_res.character_id = chara_id_label.text
		character_res.character_name = ch["character_name"]
		character_res.character_name_color = ch["color"]
		character_res.sprite_frames_path = ch["sprite_frames_path"]
		character_res.typing_sound_path = ch["typing_sound_path"]
		character_res.character_species = ch["character_species"]
		character_res.character_race = ch["character_race"]
		character_res.character_gender = ch["character_gender"]
		character_res.flags = ch["flags"]
		for sprite_sheet in ch["sprite_sheets"]:
			character_res.add_sprite_sheet(sprite_sheet, ch["sprite_sheets"][sprite_sheet])
		for c_data in ch["custom_data"]:
			character_res.set_custom_data(c_data, ch["custom_data"][c_data])
		for faction in ch["factions"]:
			character_res.add_to_faction(faction, ch["factions"][faction]["rank"])
		for stat in ch["stats"]:
			character_res.add_stat(stat, ch["stat"][stat]["min"], ch["stat"][stat]["max"])
		for perk in ch["perks"]:
			character_res.set_perk(perk, ch["perks"][perk]["level"])
		for skill in ch["skills"]:
			character_res.set_skill(skill, ch["skills"][skill]["level"])
		for variant in ch["variants"]:
			character_res.create_variant(variant)
			character_res.set_variant_sprite_sheet(
					variant,
					ch["variants"][variant]["sheet"])
			for stat_variant in ch["variants"][variant]["stats"]:
				character_res.set_variant_stat_mod(
						variant,
						stat_variant,
						ch["variants"][variant]["stats"][stat_variant])
		ResourceSaver.save(character_res, char_path["path"])
		characters_tree.set_character_data(
				chara_id_label.text,
				character_res)
	_character_memory.clear()
