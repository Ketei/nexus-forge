extends Control


const RES_PATH_SETTING: String = "nexus_forge/characters_resource"

var _characters_resource: NFCharacterDBRes
var _character_selected: TreeItem:
	set(new_character):
		_character_selected = new_character
		data_container.visible = new_character != null
		no_char_center.visible = new_character == null
var _block_switch: bool = false

#@onready var main_menu: MenuButton = $MainContainer/MenusContainer/MainMenu

@onready var new_character: Button = $MainContainer/DataSplitContainer/CharacterSelectorContainer/ButtonContainer/NewCharacter
@onready var import_character_button: Button = $MainContainer/DataSplitContainer/CharacterSelectorContainer/ButtonContainer/ImportCharacterButton
@onready var refresh_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SpriteFrameContainer/Header/RefreshButton
@onready var select_sound_path_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SoundsContainer/DataContainer/PanelContainer/HBoxContainer/SelectSoundPathButton
@onready var play_sound_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SoundsContainer/DataContainer/PlaySoundButton
@onready var select_sprites_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SpriteFrameContainer/LinePanel/LineContainer/SelectSpritesButton
@onready var add_variant_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/VariantsContainer/TitleContainer/AddVariantButton
@onready var create_db_button: Button = $NoDBContainer/CenterContainer/InfoContainer/ButtonsContainer/CharaButtonContainer/CreateDBButton
@onready var load_db_button: Button = $NoDBContainer/CenterContainer/InfoContainer/ButtonsContainer/CharaButtonContainer/LoadDBButton
@onready var add_int_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddIntButton
@onready var add_float_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddFloatButton
@onready var add_bool_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddBoolButton
@onready var add_string_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddStringButton


@onready var search_character_line: LineEdit = $MainContainer/DataSplitContainer/CharacterSelectorContainer/ButtonContainer/SearchCharacterLine
#@onready var character_id_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/IDContainer/CharacterIDLine
@onready var char_name_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CharNameContainer/CharNameLine
@onready var custom_data_search_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CustomDataSearchLine
@onready var flag_search_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/VBoxContainer/FlagsContainer/FlagSearchLine
@onready var faction_search_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/VBoxContainer/FactionsContainer/FactionSearchLine
@onready var sound_path_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SoundsContainer/DataContainer/PanelContainer/HBoxContainer/SoundPathLine
@onready var sprite_frame_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/PortraitDataContainer/SpriteFrameContainer/LinePanel/LineContainer/SpriteFrameLine

@onready var species_option_button: OptionButton = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/SpeciesContainer/SpeciesOptionButton
@onready var race_option_button: OptionButton = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/RaceContainer/RaceOptionButton
@onready var gender_option_button: OptionButton = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/GenderContainer/GenderOptionButton

@onready var characters_tree: Tree = $MainContainer/DataSplitContainer/CharacterSelectorContainer/CharactersTree
@onready var custom_data_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CustomDataContainer/CustomDataTree
@onready var flags_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/VBoxContainer/FlagsContainer/FlagsTree
@onready var factions_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/VBoxContainer/FactionsContainer/FactionsTree
@onready var sprite_sheets_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/SheetsContainer/SpriteSheetsTree
@onready var stats_container: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/StatsContainer
@onready var skills_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/SkillsContainer/SkillsTree
@onready var perks_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/PerksContainer/PerksTree
@onready var variants_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/VariantsContainer/VariantsTree

@onready var skills_desc: TextEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/SkillsContainer/SkillsDesc
@onready var perks_desc: TextEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/PerksContainer/PerksDesc

@onready var data_set_tabs: TabContainer = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs

@onready var char_name_color: ColorPickerButton = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CharNameContainer/CharNameColor

@onready var no_db_container: PanelContainer = $NoDBContainer

@onready var no_char_center: CenterContainer = $MainContainer/DataSplitContainer/DataPanel/NoCharCenter
@onready var data_container: VBoxContainer = $MainContainer/DataSplitContainer/DataPanel/DataContainer

@onready var main_container: VBoxContainer = $MainContainer

@onready var data_select_dialog: FileDialog = $ComponentNode/DataSelectDialog
@onready var id_select_panel: PanelContainer = $IDSelectPanel

@onready var races_missing_container: HBoxContainer = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer
@onready var char_db_container: HBoxContainer = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/CharDBContainer
@onready var race_res_container: HBoxContainer = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/RaceResContainer
#@onready var create_db_buttons_container: HBoxContainer = $NoDBContainer/CenterContainer/InfoContainer/ButtonsContainer

@onready var success_char_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/CharDBContainer/SuccessCharTexture
@onready var failure_char_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/CharDBContainer/FailureCharTexture
@onready var success_races_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/RaceResContainer/SuccessRacesTexture
@onready var failure_races_texture: TextureRect = $NoDBContainer/CenterContainer/InfoContainer/RacesMissingContainer/RaceResContainer/FailureRacesTexture

@onready var chara_button_container: VBoxContainer = $NoDBContainer/CenterContainer/InfoContainer/ButtonsContainer/CharaButtonContainer


func _ready() -> void:
	var res_path: String = ProjectSettings.get_setting(RES_PATH_SETTING, "")
	var tabs := data_set_tabs.get_tab_bar()
	tabs.set_tab_title(0, "Stats")
	tabs.set_tab_title(1, "Skills")
	tabs.set_tab_title(2, "Perks")
	tabs.set_tab_title(3, "Variants")
	
	if not res_path.is_empty() and ResourceLoader.exists(res_path):
		var res_load: Resource = load(res_path)
		if res_load is NFCharacterDBRes:
			_characters_resource = res_load
			_load_characters()
	
	if _characters_resource == null or NexusForge.Races == null:
		create_db_button.disabled = _characters_resource != null
		load_db_button.disabled = _characters_resource != null
		
		success_char_texture.visible = _characters_resource != null
		failure_char_texture.visible = _characters_resource == null
		
		success_races_texture.visible = NexusForge.Races != null
		failure_races_texture.visible = NexusForge.Races == null
		
		main_container.visible = false
		no_db_container.visible = true
	else:
		main_container.visible = true
		no_db_container.visible = false
	
	if NexusForge.Races != null:
		load_races()
	
	data_select_dialog.file_selected.connect(on_dialog_ok)
	create_db_button.pressed.connect(on_create_new_resource)
	load_db_button.pressed.connect(on_open_char_resource)
	id_select_panel.id_changed.connect(on_id_selector_id_changed)
	id_select_panel.id_submitted.connect(on_id_submitted)
	new_character.pressed.connect(on_create_new_character)
	import_character_button.pressed.connect(on_import_character)
	
	add_int_button.pressed.connect(create_custom_data.bind(TYPE_INT))
	add_float_button.pressed.connect(create_custom_data.bind(TYPE_FLOAT))
	add_bool_button.pressed.connect(create_custom_data.bind(TYPE_BOOL))
	add_string_button.pressed.connect(create_custom_data.bind(TYPE_STRING))
	
	characters_tree.item_selected.connect(on_character_tree_selected)
	
	species_option_button.item_selected.connect(on_species_selected)
	race_option_button.item_selected.connect(on_race_selected)


func on_species_selected(index_selected: int) -> void:
	var species: String = species_option_button.get_item_metadata(index_selected)
	var race_id: int = 0
	race_option_button.clear()
	for race in NexusForge.Races.species[species]["races"]:
		race_option_button.add_item(
				Strings.capitalize(NexusForge.Races.species[species]["races"][race]["name"]),
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
	
	for gender in NexusForge.Races.species[species]["races"][race]["genders"]:
		gender_option_button.add_item(Strings.capitalize(NFRacesRes.get_gender_name(gender)), gender_id)
		gender_option_button.set_item_metadata(
			gender_option_button.get_item_index(gender_id),
			gender)
		gender_id += 1


func on_character_tree_selected():
	if _block_switch:
		return
	_block_switch = true
	
	var target_character: TreeItem = characters_tree.get_selected()
	
	_character_selected = target_character
	if not target_character.is_selected(0):
		target_character.select(0)
	_block_switch = false


func on_id_selector_id_changed(new_id: String) -> void:
	id_select_panel.set_valid_id(not _characters_resource.has_character(new_id))


func on_id_submitted(new_id: String) -> void:
	id_select_panel.visible = false
	data_select_dialog.is_character = true
	data_select_dialog.character_id = new_id
	data_select_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	data_select_dialog.current_file = new_id
	data_select_dialog.show()


func on_create_new_character() -> void:
	id_select_panel.clear_id()
	id_select_panel.visible = true


func on_import_character() -> void:
	data_select_dialog.is_character = true
	data_select_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	data_select_dialog.show()


func on_create_new_resource() -> void:
	data_select_dialog.is_character = false
	data_select_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	data_select_dialog.show()


func on_open_char_resource() -> void:
	data_select_dialog.is_character = false
	data_select_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	data_select_dialog.show()


func on_dialog_ok(resource_path: String) -> void:
	if data_select_dialog.is_character:
		if data_select_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
			var new_char := CharacterDefinition.new()
			new_char.character_id = data_select_dialog.character_id
			if ResourceSaver.save(new_char, resource_path) == OK:
				if not _characters_resource.has_character(data_select_dialog.character_id):
					characters_tree.add_character(
							data_select_dialog.character_id,
							resource_path)
				_characters_resource.set_character(data_select_dialog.character_id, resource_path)
				_characters_resource.save()
		else:
			if not ResourceLoader.exists(resource_path):
				return
			var res_pre: Resource = load(resource_path)
			if res_pre is not CharacterDefinition:
				return
			if _characters_resource.has_character(res_pre.character_id):
				printerr(str("[CHARACTERS] A character with ID \"", res_pre.character_id, "\" already exists. Path will be replaced."))
			else:
				characters_tree.add_character(
							res_pre.character_id,
							resource_path)
			_characters_resource.set_character(res_pre.character_id, resource_path)
			_characters_resource.save()
	else:
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
		
			if preload_resource is not NFCharacterDBRes:
				return
			_characters_resource = preload_resource
			_characters_resource.validate_characters()
		
		if _characters_resource != null:
			# TODO Uncomment this once plugin is ready
			#ProjectSettings.set_setting(RES_PATH_SETTING, resource_path)
			_load_characters()
			if _has_all_required_resources():
				no_db_container.visible = false
				main_container.visible = true
			else:
				create_db_button.disabled = true
				load_db_button.disabled = true
				
				success_char_texture.visible = true
				failure_char_texture.visible = false
				
				failure_races_texture.visible = true
				success_races_texture.visible = false
				


func _has_all_required_resources() -> bool:
	return _characters_resource != null and NexusForge.Races != null


func load_races() -> void:
	gender_option_button.clear()
	species_option_button.clear()
	
	var gender_names = NFRacesRes.Genders.keys()
		
	for gender in NFRacesRes.Genders.values():
		if NFRacesRes.GENDER_DATA[gender]["icon"].is_empty():
			gender_option_button.add_item(
					Strings.capitalize(gender_names[gender]))
		else:
			gender_option_button.add_icon_item(
					load(NFRacesRes.GENDER_DATA[gender]["icon"]),
					Strings.capitalize(gender_names[gender]))

	var species_id: int = 0
	
	for species in NexusForge.Races.species:
		species_option_button.add_item(Strings.capitalize(NexusForge.Races.species[species]["name"]), species_id)
		species_option_button.set_item_metadata(species_option_button.get_item_index(species_id), species)
		species_id += 1
	
	if species_id != 0:
		species_option_button.select(0)
		on_species_selected(0)


func clear_character() -> void:
	#character_id_line.clear()
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


func _load_characters() -> void:
	for character in _characters_resource._characters:
		characters_tree.add_character(character, _characters_resource._characters[character])
