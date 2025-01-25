@tool
extends Control


const LineEditConfirmationDialog = preload("res://addons/nexus_forge/classes/line_edit_confirmation_dialog.gd")

var characters_resource: NFCharacterDBRes = null
var races_resource: NFRacesRes = null:
	set(new_races):
		#if races_resource != null:
			#races_resource.changed.disconnect(on_races_changed)
		races_resource = new_races
		#races_resource.changed.connect(on_races_changed)
var _factions_resource: NFFactionRes = null:
	set(new_factions):
		#if _factions_resource != null:
			#_factions_resource.changed.disconnect(on_factions_changed)
		_factions_resource = new_factions
		#_factions_resource.changed.connect(on_factions_changed)
var talents_resource: NFTalentsRes = null:
	set(new_talents):
		#if talents_resource != null:
			#talents_resource.changed.disconnect(on_talents_changed)
			#talents_resource.perk_renamed.disconnect(on_perk_renamed)
		talents_resource = new_talents
		#talents_resource.perk_renamed.connect(on_perk_renamed)
		#talents_resource.changed.connect(on_talents_changed)

var current_character: int = -1
var current_variant: int = -1
var no_db_container: PanelContainer = null

@onready var skills_tree: Tree = $DataPanel/MainDataContainer/FactionsContainer/SkillsTree
@onready var variants_opt_btn: OptionButton = $DataPanel/MainDataContainer/ExtraContainer/VariantsContainer/TitleContainer/VariantsOptBtn
@onready var add_variant_button: Button = $DataPanel/MainDataContainer/ExtraContainer/VariantsContainer/TitleContainer/AddVariantButton
@onready var delete_variant_button: Button = $DataPanel/MainDataContainer/ExtraContainer/VariantsContainer/TitleContainer/DeleteVariantButton
@onready var add_var_int_button: Button = $DataPanel/MainDataContainer/ExtraContainer/VariantsContainer/VariantDataContainer/CDHeaderContainer/AddButtonsContainer/AddVarIntButton
@onready var add_var_float_button: Button = $DataPanel/MainDataContainer/ExtraContainer/VariantsContainer/VariantDataContainer/CDHeaderContainer/AddButtonsContainer/AddVarFloatButton
@onready var add_var_bool_button: Button = $DataPanel/MainDataContainer/ExtraContainer/VariantsContainer/VariantDataContainer/CDHeaderContainer/AddButtonsContainer/AddVarBoolButton
@onready var add_var_string_button: Button = $DataPanel/MainDataContainer/ExtraContainer/VariantsContainer/VariantDataContainer/CDHeaderContainer/AddButtonsContainer/AddVarStringButton
@onready var custom_data_search_line: LineEdit = $DataPanel/MainDataContainer/ExtraContainer/VariantsContainer/VariantDataContainer/CustomDataSearchLine
@onready var variant_data_tree: Tree = $DataPanel/MainDataContainer/ExtraContainer/VariantsContainer/VariantDataContainer/VariantDataTree
@onready var character_option_button: OptionButton = $DataPanel/MainDataContainer/GeneralContainer/ButtonContainer/CharacterOptBtn
@onready var new_character: Button = $DataPanel/MainDataContainer/GeneralContainer/ButtonContainer/NewCharacter
@onready var char_name_line: LineEdit = $DataPanel/MainDataContainer/GeneralContainer/CharNameContainer/CharNameLine
@onready var char_name_color: ColorPickerButton = $DataPanel/MainDataContainer/GeneralContainer/CharNameContainer/CharNameColor
@onready var species_option_button: OptionButton = $DataPanel/MainDataContainer/GeneralContainer/SpeciesContainer/SpeciesOptionButton
@onready var race_option_button: OptionButton = $DataPanel/MainDataContainer/GeneralContainer/RaceContainer/RaceOptionButton
@onready var gender_option_button: OptionButton = $DataPanel/MainDataContainer/GeneralContainer/GenderContainer/GenderOptionButton
@onready var character_data_tree: Tree = $DataPanel/MainDataContainer/GeneralContainer/CustomDataContainer/CharacterDataTree
@onready var faction_search_line: LineEdit = $DataPanel/MainDataContainer/FactionsContainer/FactionSearchLine
@onready var factions_tree: Tree = $DataPanel/MainDataContainer/FactionsContainer/FactionsTree
@onready var add_chr_int_button: Button = $DataPanel/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddIntButton
@onready var add_chr_float_button: Button = $DataPanel/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddFloatButton
@onready var add_chr_bool_button: Button = $DataPanel/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddBoolButton
@onready var add_chr_string_button: Button = $DataPanel/MainDataContainer/GeneralContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddStringButton
@onready var delete_character_btn: Button = $DataPanel/MainDataContainer/GeneralContainer/ButtonContainer/DeleteCharBtn

@onready var data_panel: PanelContainer = $DataPanel


func _ready() -> void:
	if load_resources():
		load_races()
		load_skills()
		load_factions()
		load_characters()
		data_panel.visible = true
	else:
		data_panel.visible = false
		no_db_container = preload("res://addons/nexus_forge/tools/characters/kinds_no_db.tscn").instantiate()
		add_child(no_db_container)
		no_db_container.check_res_pressed.connect(on_check_resources_pressed)
		no_db_container.load_db_pressed.connect(on_open_char_resource)
		no_db_container.create_db_pressed.connect(on_create_new_resource)
		no_db_container.set_tal_success(talents_resource != null)
		no_db_container.set_facc_success(_factions_resource != null)
		no_db_container.set_race_success(races_resource != null)
		no_db_container.set_char_success(characters_resource != null)
	
	new_character.pressed.connect(on_create_new_character)
	
	add_var_int_button.pressed.connect(_on_add_variant_data_pressed.bind("new_int", 0))
	add_var_float_button.pressed.connect(_on_add_variant_data_pressed.bind("new_float", 0.0))
	add_var_bool_button.pressed.connect(_on_add_variant_data_pressed.bind("new_bool", false))
	add_var_string_button.pressed.connect(_on_add_variant_data_pressed.bind("new_string", ""))
	
	add_chr_int_button.pressed.connect(_on_add_character_data_pressed.bind("new_int", 0))
	add_chr_float_button.pressed.connect(_on_add_character_data_pressed.bind("new_float", 0.0))
	add_chr_bool_button.pressed.connect(_on_add_character_data_pressed.bind("new_bool", false))
	add_chr_string_button.pressed.connect(_on_add_character_data_pressed.bind("new_string", ""))
	
	species_option_button.item_selected.connect(on_species_selected)
	character_option_button.item_selected.connect(on_character_selected, CONNECT_DEFERRED)
	variants_opt_btn.item_selected.connect(_on_variant_selected, CONNECT_DEFERRED)
	add_variant_button.pressed.connect(_on_create_variant_pressed)
	delete_variant_button.pressed.connect(_on_delete_variant_pressed)


func on_talents_changed() -> void:
	var skill_config: Dictionary = skills_tree.get_skill_data()

	load_skills()
	
	for skill in talents_resource.get_skills():
		if skill_config.has(skill):
			skills_tree.set_skill(
					skill,
					skill_config[skill]["level"])


func load_factions() -> void:
	factions_tree.clear_factions()
	for faction in _factions_resource.get_factions():
		factions_tree.add_faction(faction, _factions_resource.get_faction_rank_count(faction))


func on_factions_changed() -> void:
	var current_factions: Dictionary = factions_tree.get_factions()
	load_factions()
	for faction in _factions_resource.get_factions():
		if current_factions.has(faction):
			factions_tree.set_faction(faction, true, current_factions[faction]["rank"])


func on_races_changed() -> void:
	var current_species: String = ""
	var current_race: String = ""
	var gender_selected: bool = false
	
	if species_option_button.selected != -1:
		current_species = species_option_button.get_item_text(species_option_button.selected)
	if race_option_button.selected != -1:
		current_race = race_option_button.get_item_text(race_option_button.selected)
	
	load_races()
	
	if not current_species.is_empty() and races_resource.has_species(current_species):
		for item_idx in range(species_option_button.item_count):
			if species_option_button.get_item_text(item_idx) == current_species:
				species_option_button.select(item_idx)
				on_species_selected(item_idx)
				break
		
	if not current_race.is_empty() and races_resource.has_race(current_species, current_race):
		for race_idx in range(race_option_button.item_count):
			if race_option_button.get_item_text(race_idx) == current_race:
				race_option_button.select(race_idx)
				break


func load_skills() -> void:
	skills_tree.clear_skills()
	
	for skill in talents_resource.get_skills():
		skills_tree.add_skill(
				skill,
				talents_resource.get_skill_limit(skill))


func on_species_selected(index_selected: int) -> void:
	var species_id: String = species_option_button.get_item_text(index_selected)
	race_option_button.clear()
	
	for race in races_resource.get_races(species_id):
		race_option_button.add_item(race)
	
	if 0 < race_option_button.item_count:
		race_option_button.select(0)


func on_character_selected(character_id: int):
	if current_character != -1:
		save_current_character()
	
	current_character = character_id
	load_character(character_id)


func load_character(character_idx: int) -> void:
	character_data_tree.clear_data()
	factions_tree.reset_factions()
	variant_data_tree.clear_data()
	skills_tree.reset_skills()
	variants_opt_btn.clear()
	
	delete_character_btn.disabled = character_idx == -1
	add_chr_int_button.disabled = character_idx == -1
	add_chr_float_button.disabled = character_idx == -1
	add_chr_bool_button.disabled = character_idx == -1
	add_chr_string_button.disabled = character_idx == -1
	
	add_var_int_button.disabled = character_idx == -1
	add_var_float_button.disabled = character_idx == -1
	add_var_bool_button.disabled = character_idx == -1
	add_var_string_button.disabled = character_idx == -1
	add_variant_button.disabled = character_idx == -1
	
	if character_idx == -1:
		char_name_line.clear()
		char_name_color.color = Color.WHITE
		if 0 < species_option_button.item_count:
			select_species(species_option_button.get_item_text(0))
		else:
			species_option_button.select(-1)
		
		if 0 < race_option_button.item_count:
			select_race(race_option_button.get_item_text(0))
		else:
			race_option_button.select(-1)
		
		if 0 < gender_option_button.item_count:
			gender_option_button.select(0)
		else:
			gender_option_button.select(-1)
		delete_variant_button.disabled = true
		load_variant(-1)
		return
	
	var character_id: String = character_option_button.get_item_text(character_idx)
	
	char_name_line.text = characters_resource.get_character_name(character_id)
	char_name_color.color = characters_resource.get_character_color(character_id)
	
	select_species(characters_resource.get_character_species(character_id))
	select_race(characters_resource.get_character_race(character_id))
	select_gender(characters_resource.get_character_gender(character_id))
	
	if characters_resource.has_character_data(character_id, "gender"):
		gender_option_button.select(characters_resource.get_character_data(character_id, "gender"))
	
	for data_key in characters_resource.get_character_data_keys(character_id):
		character_data_tree.add_data(
				data_key,
				characters_resource.get_character_data(character_id, data_key))
	
	for faction in characters_resource.get_character_factions(character_id):
		factions_tree.set_faction(
				faction,
				true,
				characters_resource.get_character_faction_rank(character_id, faction))
	
	for skill in characters_resource.get_character_skills(character_id):
		skills_tree.set_skill(
				skill,
				characters_resource.get_character_skill_level(character_id, skill))
	
	for variant_key in characters_resource.get_character_variants(character_id):
		variants_opt_btn.add_item(variant_key)
	
	if 0 < variants_opt_btn.item_count:
		delete_variant_button.disabled = false
		variants_opt_btn.select(0)
		load_variant(0)
	else:
		delete_variant_button.disabled = true
		load_variant(-1)
	
	current_character = character_idx


func load_resources() -> bool:
	var character_path: String = ProjectSettings.get_setting(NFCharacterDBRes.SETTINGS_PATH, "")
	var race_path: String = ProjectSettings.get_setting(NFRacesRes.SETTINGS_PATH, "")
	var factions_path: String = ProjectSettings.get_setting(NFFactionRes.SETTINGS_PATH, "")
	var talents_path: String = ProjectSettings.get_setting(NFTalentsRes.SETTINGS_PATH, "")
	
	if not character_path.is_empty() and ResourceLoader.exists(character_path):
		var char_preload: Resource = load(character_path)
		if char_preload is NFCharacterDBRes:
			characters_resource = char_preload
	
	if not race_path.is_empty() and ResourceLoader.exists(race_path):
		var race_preload: Resource = load(race_path)
		if race_preload is NFRacesRes:
			races_resource = race_preload
	
	if not factions_path.is_empty() and ResourceLoader.exists(factions_path):
		var faction_preload: Resource = load(factions_path)
		if faction_preload is NFFactionRes:
			_factions_resource = faction_preload
	
	if not talents_path.is_empty() and ResourceLoader.exists(talents_path):
		var talent_preload: Resource = load(talents_path)
		if talent_preload is NFTalentsRes:
			talents_resource = talent_preload
	
	if no_db_container != null:
		no_db_container.set_tal_success(talents_resource != null)
		no_db_container.set_facc_success(_factions_resource != null)
		no_db_container.set_race_success(races_resource != null)
		no_db_container.set_char_success(characters_resource != null)
	
	return characters_resource != null and races_resource != null and _factions_resource != null and talents_resource != null


func on_check_resources_pressed() -> void:
	if load_resources():
		load_races()
		load_skills()
		load_factions()
		load_characters()
		data_panel.visible = true
		no_db_container.visible = false
		no_db_container.queue_free()


func select_species(species_id: String) -> void:
	for species_idx in range(species_option_button.item_count):
		if species_option_button.get_item_text(species_idx) == species_id:
			species_option_button.select(species_idx)
			on_species_selected(species_idx)
			break


func select_race(race_id: String) -> void:
	for race_idx in range(race_option_button.item_count):
		if race_option_button.get_item_text(race_idx) == race_id:
			race_option_button.select(race_idx)
			on_species_selected(race_idx)
			break


func select_gender(gender_id: String) -> void:
	for g_idx in range(gender_option_button.item_count):
		if gender_option_button.get_item_metadata(g_idx) == gender_id:
			gender_option_button.select(g_idx)
			break


func on_create_new_character() -> void:
	var char_id := LineEditConfirmationDialog.new()
	char_id.accept_empty = false
	char_id.clean_string = true
	char_id.invalid_strings = characters_resource.get_characters()
	add_child(char_id)
	char_id.show()
	char_id.focus_line_edit()
	
	var result = await char_id.dialog_confirmed
	
	if result[0]:
		character_option_button.add_item(result[1])
		characters_resource.create_character(result[1])
		if current_character != -1:
			save_current_character()
		character_option_button.select(character_option_button.item_count - 1)
		load_character(character_option_button.item_count - 1)
	char_id.queue_free()


func on_create_new_resource() -> void:
	var resource_loader := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").new()
	resource_loader.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	resource_loader.title = "Save Characters..."
	resource_loader.ok_button_text = "Save"
	add_child(resource_loader)
	resource_loader.show()
	
	var result = await resource_loader.dialog_finished
	
	if result[0]:
		characters_resource = NFCharacterDBRes.new()
		ResourceSaver.save(characters_resource, result[1])
		ProjectSettings.set_setting(NFCharacterDBRes.SETTINGS_PATH, result[1])
		ProjectSettings.save()
		
		if load_resources():
			load_races()
			load_skills()
			load_factions()
			load_characters()
			no_db_container.visible = false
			no_db_container.queue_free()
			data_panel.visible = true
	
	resource_loader.queue_free()


func _on_character_removed_pressed() -> void:
	var new_id: int = clampi(current_character, -1, character_option_button.item_count - 2)
	characters_resource.erase_character(character_option_button.get_item_text(current_character))
	character_option_button.remove_item(current_character)
	character_option_button.select(new_id)
	load_character(new_id)


func _on_create_variant_pressed() -> void:
	var ln_var := LineEditConfirmationDialog.new()
	add_child(ln_var)
	ln_var.show()
	ln_var.focus_line_edit()
	
	var result = await ln_var.dialog_confirmed
	
	if result[0]:
		characters_resource.create_character_variant(character_option_button.get_item_text(current_character), result[1])
		variants_opt_btn.add_item(result[1])
		if current_variant != -1:
			save_current_variant()
		variants_opt_btn.select(variants_opt_btn.item_count - 1)
		load_variant(variants_opt_btn.item_count - 1)


func _on_variant_selected(variant_idx: int) -> void:
	if current_variant != -1:
		save_current_variant()
	load_variant(variant_idx)


func _on_delete_variant_pressed() -> void:
	var new_v: int = clampi(current_variant, -1, variants_opt_btn.item_count - 2)
	characters_resource.erase_character_variant(
			character_option_button.get_item_text(current_character),
			variants_opt_btn.get_item_text(current_variant))
	variants_opt_btn.remove_item(current_variant)
	variants_opt_btn.select(new_v)
	load_variant(new_v)


func load_variant(variant_idx: int) -> void:
	variant_data_tree.clear_data()
	
	if variant_idx == -1:
		delete_variant_button.disabled = true
		add_var_int_button.disabled = true
		add_var_float_button.disabled = true
		add_var_bool_button.disabled = true
		add_var_string_button.disabled = true
		current_variant = -1
		return
	else:
		delete_variant_button.disabled = false
		add_var_int_button.disabled = false
		add_var_float_button.disabled = false
		add_var_bool_button.disabled = false
		add_var_string_button.disabled = false
	
	var c_id: String = character_option_button.get_item_text(current_character)
	var v_id: String = variants_opt_btn.get_item_text(variant_idx)
	
	
	for data_key in characters_resource.get_character_variant_data_keys(c_id, v_id):
		variant_data_tree.add_data(
				data_key,
				characters_resource.get_character_variant_data(c_id, v_id, data_key))
	 
	current_variant = variant_idx


func on_open_char_resource() -> void:
	var resource_loader := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").new()
	resource_loader.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	resource_loader.title = "Open Characters..."
	resource_loader.ok_button_text = "Select"
	add_child(resource_loader)
	
	var result = await resource_loader.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is NFCharacterDBRes:
			characters_resource = res_pre
			ProjectSettings.set_setting(NFCharacterDBRes.SETTINGS_PATH, result[1])
			ProjectSettings.save()
			
			
			if load_resources():
				load_races()
				load_skills()
				load_factions()
				load_characters()
				no_db_container.visible = false
				no_db_container.queue_free()
				data_panel.visible = true
	resource_loader.queue_free()


func load_races() -> void:
	species_option_button.clear()
	race_option_button.clear()
	
	for species in races_resource.get_species():
		species_option_button.add_item(species)
	
	if 0 < species_option_button.item_count:
		species_option_button.select(0)
		for race in races_resource.get_races(species_option_button.get_item_text(0)):
			race_option_button.add_item(race)
		if 0 < race_option_button.item_count:
			race_option_button.select(0)


func clear_all() -> void:
	char_name_line.clear()
	char_name_color.color = Color.WHITE
	species_option_button.select(-1 if species_option_button.item_count == 0 else 0)
	race_option_button.select(-1 if race_option_button.item_count == 0 else 0)
	gender_option_button.select(0)
	custom_data_search_line.clear()
	character_data_tree.clear_data()
	faction_search_line.clear()
	factions_tree.reset_factions()
	#skill_search_line.clear()
	skills_tree.reset_skills()
	variants_opt_btn.clear()
	add_variant_button.disabled = true
	delete_variant_button.disabled = true
	add_var_int_button.disabled = true
	add_var_float_button.disabled = true
	add_var_bool_button.disabled = true
	add_var_string_button.disabled = true
	custom_data_search_line.clear()
	variant_data_tree.clear_data()


func _on_add_character_data_pressed(data_name: String, data: Variant) -> void:
	character_data_tree.add_data(data_name, data)


func _on_add_variant_data_pressed(data_name: String, data: Variant) -> void:
	variant_data_tree.add_data(data_name, data)


func load_characters() -> void:
	character_option_button.clear()
	gender_option_button.clear()
	
	var g_idx: int = -1
	for gender in characters_resource.get_genders():
		g_idx += 1
		gender_option_button.add_item(
				characters_resource.get_gender_name(gender))
		gender_option_button.set_item_metadata(g_idx, gender)
	
	if g_idx != -1:
		gender_option_button.select(0)
	
	for character in characters_resource.get_characters():
		character_option_button.add_item(character)
	if 0 < character_option_button.item_count:
		character_option_button.select(0)
		load_character(0)


func save_current_variant() -> void:
	var char_id: String = character_option_button.get_item_text(current_character)
	var var_id: String = variants_opt_btn.get_item_text(current_variant)
	characters_resource._characters[char_id]["variants"][var_id] = variant_data_tree.get_data()


func save_current_character() -> void:
	if current_variant != -1:
		save_current_variant()
	
	var char_id: String = character_option_button.get_item_text(current_character)
	characters_resource.set_character_name(char_id, char_name_line.text.strip_edges())
	characters_resource.set_character_color(char_id, char_name_color.color)
	characters_resource.set_character_species(char_id, get_selected_species_id())
	characters_resource.set_character_race(char_id, get_selected_race_id())
	characters_resource.set_character_gender(char_id, get_selected_gender_id())
	characters_resource._characters[char_id]["data"] = character_data_tree.get_data()
	characters_resource._characters[char_id]["factions"] = factions_tree.get_factions()
	characters_resource._characters[char_id]["skills"] = skills_tree.get_skill_data()


func get_selected_species_id() -> String:
	return species_option_button.get_item_text(species_option_button.selected) if 0 <= species_option_button.selected else ""


func get_selected_race_id() -> String:
	return race_option_button.get_item_text(race_option_button.selected) if 0 <= race_option_button.selected else ""


func get_selected_gender_id() -> String:
	return gender_option_button.get_item_metadata(gender_option_button.selected) if 0 <= gender_option_button.selected else ""


func save() -> void:
	if current_character != -1:
		save_current_character()
	
	characters_resource.save()
