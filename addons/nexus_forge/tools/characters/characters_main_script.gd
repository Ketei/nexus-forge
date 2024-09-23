extends Control


const RES_PATH_SETTING: String = "nexus_forge/characters/resource_path"

var _characters_resource: NexusForgeCharacterDatabase
var _character_selected: TreeItem:
	set(new_character):
		_character_selected = new_character
		data_container.visible = new_character != null
		no_char_center.visible = new_character == null
var _block_switch: bool = false

#@onready var main_menu: MenuButton = $MainContainer/MenusContainer/MainMenu

@onready var new_character: Button = $MainContainer/DataSplitContainer/CharacterSelectorContainer/ButtonContainer/NewCharacter
@onready var import_character_button: Button = $MainContainer/DataSplitContainer/CharacterSelectorContainer/ButtonContainer/ImportCharacterButton
@onready var add_int_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/VBoxContainer4/HBoxContainer/AddButtonsContainer/AddIntButton
@onready var add_float_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/VBoxContainer4/HBoxContainer/AddButtonsContainer/AddFloatButton
@onready var add_bool_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/VBoxContainer4/HBoxContainer/AddButtonsContainer/AddBoolButton
@onready var add_string_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/VBoxContainer4/HBoxContainer/AddButtonsContainer/AddStringButton
@onready var refresh_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/ImageContainer/PortraitsContainer/PortraitDataContainer/SpriteFrameContainer/Header/RefreshButton
@onready var select_sound_path_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/ImageContainer/PortraitsContainer/PortraitDataContainer/SoundsContainer/DataContainer/PanelContainer/HBoxContainer/SelectSoundPathButton
@onready var play_sound_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/ImageContainer/PortraitsContainer/PortraitDataContainer/SoundsContainer/DataContainer/PlaySoundButton
@onready var select_sprites_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/ImageContainer/PortraitsContainer/PortraitDataContainer/SpriteFrameContainer/LinePanel/LineContainer/SelectSpritesButton
@onready var add_variant_button: Button = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/VariantsContainer/TitleContainer/AddVariantButton
@onready var create_db_button: Button = $NoDBContainer/CenterContainer/InfoContainer/ButtonsContainer/CreateDBButton
@onready var load_db_button: Button = $NoDBContainer/CenterContainer/InfoContainer/ButtonsContainer/LoadDBButton

@onready var search_character_line: LineEdit = $MainContainer/DataSplitContainer/CharacterSelectorContainer/ButtonContainer/SearchCharacterLine
#@onready var character_id_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/IDContainer/CharacterIDLine
@onready var char_name_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CharNameContainer/CharNameLine
@onready var custom_data_search_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/VBoxContainer4/CustomDataSearchLine
@onready var flag_search_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/FlagsContainer/FlagSearchLine
@onready var faction_search_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/FactionsContainer/FactionSearchLine
@onready var sound_path_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/ImageContainer/PortraitsContainer/PortraitDataContainer/SoundsContainer/DataContainer/PanelContainer/HBoxContainer/SoundPathLine
@onready var sprite_frame_line: LineEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/ImageContainer/PortraitsContainer/PortraitDataContainer/SpriteFrameContainer/LinePanel/LineContainer/SpriteFrameLine

@onready var species_option_button: OptionButton = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/SpeciesContainer/SpeciesOptionButton
@onready var race_option_button: OptionButton = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/RaceContainer/RaceOptionButton
@onready var gender_option_button: OptionButton = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/GenderContainer/GenderOptionButton
@onready var anim_select_button: OptionButton = $MainContainer/DataSplitContainer/DataPanel/DataContainer/ImageContainer/PortraitsContainer/PortraitDataContainer/VBoxContainer/PortraitsAnimContainer/AnimSelectButton

@onready var characters_tree: Tree = $MainContainer/DataSplitContainer/CharacterSelectorContainer/CharactersTree
@onready var custom_data_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/VBoxContainer4/CustomDataTree
@onready var flags_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/FlagsContainer/FlagsTree
@onready var factions_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/FactionsContainer/FactionsTree
@onready var sprite_sheets_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/ImageContainer/SheetsContainer/SpriteSheetsTree
@onready var stats_container: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/StatsContainer
@onready var skills_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/SkillsContainer/SkillsTree
@onready var perks_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/PerksContainer/PerksTree
@onready var variants_tree: Tree = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/VariantsContainer/VariantsTree

@onready var skills_desc: TextEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/SkillsContainer/SkillsDesc
@onready var perks_desc: TextEdit = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs/PerksContainer/PerksDesc

@onready var data_set_tabs: TabContainer = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/DataSetTabs

@onready var char_name_color: ColorPickerButton = $MainContainer/DataSplitContainer/DataPanel/DataContainer/MainDataContainer/GeneralContainer/CharNameContainer/CharNameColor
@onready var play_check_button: CheckButton = $MainContainer/DataSplitContainer/DataPanel/DataContainer/ImageContainer/PortraitsContainer/PortraitDataContainer/VBoxContainer/PortraitsAnimContainer/PlayCheckButton
@onready var portrait_texture_rect: PortraitTextureRect = $MainContainer/DataSplitContainer/DataPanel/DataContainer/ImageContainer/PortraitsContainer/PortraitContainer/PortraitTextureRect

@onready var no_db_container: PanelContainer = $NoDBContainer

@onready var no_char_center: CenterContainer = $MainContainer/DataSplitContainer/DataPanel/NoCharCenter
@onready var data_container: VBoxContainer = $MainContainer/DataSplitContainer/DataPanel/DataContainer

@onready var main_container: VBoxContainer = $MainContainer

@onready var data_select_dialog: FileDialog = $ComponentNode/DataSelectDialog
@onready var id_select_panel: PanelContainer = $IDSelectPanel


func _ready() -> void:
	var res_path: String = ProjectSettings.get_setting(RES_PATH_SETTING, "")
	var tabs := data_set_tabs.get_tab_bar()
	tabs.set_tab_title(0, "Stats")
	tabs.set_tab_title(1, "Skills")
	tabs.set_tab_title(2, "Perks")
	tabs.set_tab_title(3, "Variants")
	
	if _character_selected == null:
		data_container.visible = false
		no_char_center.visible = true
	else:
		data_container.visible = true
		no_char_center.visible = false
	
	if res_path.is_empty() or not ResourceLoader.exists(res_path):
		no_db_container.visible = true
		main_container.visible = false
	else:
		var res_load: Resource = load(res_path)
		if res_load is NexusForgeCharacterDatabase:
			_characters_resource = res_load
			_load_characters()
			no_db_container.visible = false
			main_container.visible = true
		else:
			no_db_container.visible = true
			main_container.visible = false
	
	var gender_names = NexusForgeRaces.Genders.keys()
	
	for gender in NexusForgeRaces.Genders.values():
		if NexusForgeRaces.GENDER_DATA[gender]["icon"].is_empty():
			gender_option_button.add_item(
					Strings.capitalize(gender_names[gender]))
		else:
			gender_option_button.add_icon_item(
					load(NexusForgeRaces.GENDER_DATA[gender]["icon"]),
					Strings.capitalize(gender_names[gender]))
	
	data_select_dialog.file_selected.connect(on_dialog_ok)
	create_db_button.pressed.connect(on_create_new_resource)
	load_db_button.pressed.connect(on_open_char_resource)
	id_select_panel.id_changed.connect(on_id_selector_id_changed)
	id_select_panel.id_submitted.connect(on_id_submitted)
	new_character.pressed.connect(on_create_new_character)
	import_character_button.pressed.connect(on_import_character)


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
			var new_chara_db := NexusForgeCharacterDatabase.new()
			ResourceSaver.save(
					new_chara_db,
					resource_path)
			_characters_resource = new_chara_db
		else:
			if not ResourceLoader.exists(resource_path):
				return
		
			var preload_resource: Resource = load(resource_path)
		
			if preload_resource is not NexusForgeCharacterDatabase:
				return
			_characters_resource = preload_resource
			_characters_resource.validate_characters()
		
		if _characters_resource != null:
			# TODO Uncomment this once plugin is ready
			#ProjectSettings.set_setting(RES_PATH_SETTING, resource_path)
			_load_characters()
			no_db_container.visible = false
			main_container.visible = true


func clear_character() -> void:
	#character_id_line.clear()
	char_name_line.clear()
	char_name_color.color = Color.WHITE
	species_option_button.select(-1)
	race_option_button.select(-1)
	gender_option_button.select(-1)
	custom_data_search_line.clear()
	sprite_frame_line.clear()
	anim_select_button.select(-1)
	sound_path_line.clear()
	portrait_texture_rect.portrait_frames = null
	portrait_texture_rect.playing = false


func _load_characters() -> void:
	for character in _characters_resource._characters:
		characters_tree.add_character(character, _characters_resource._characters[character])
