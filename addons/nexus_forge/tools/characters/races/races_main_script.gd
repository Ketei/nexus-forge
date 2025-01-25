@tool
extends Control


const LineEditConfirmationDialog = preload("res://addons/nexus_forge/classes/line_edit_confirmation_dialog.gd")
var race_resource: NFRacesRes = null
var no_race_panel: PanelContainer = null 


var current_species: int = -1:
	set(new_idx):
		current_species = new_idx
		var species_selected: bool = 0 <= new_idx
		species_name_l_edit.editable = species_selected
		create_race_btn.disabled = not species_selected
		delete_species_btn.disabled = not species_selected
		race_opt_btn.disabled = not species_selected
		species_int_btn.disabled = not species_selected
		species_flt_btn.disabled = not species_selected
		species_bool_btn.disabled = not species_selected
		species_str_btn.disabled = not species_selected
var current_race: int = -1:
	set(new_idx):
		current_race = new_idx
		var race_selected: bool = 0 <= new_idx 
		races_int_btn.disabled = not race_selected
		races_flt_btn.disabled = not race_selected
		races_bool_btn.disabled = not race_selected
		races_str_btn.disabled = not race_selected
		race_name_l_edit.editable = race_selected
		delete_race_btn.disabled = not race_selected



@onready var species_opt_btn: OptionButton = $MainContainer/SpcRcContainer/SpeciesContainer/SpeciesDataCotnainer/SpeciesOptBtn
@onready var create_species_btn: Button = $MainContainer/SpcRcContainer/SpeciesContainer/SpeciesDataCotnainer/CreateSpeciesBtn
@onready var delete_species_btn: Button = $MainContainer/SpcRcContainer/SpeciesContainer/SpeciesDataCotnainer/DeleteSpeciesBtn
@onready var species_name_l_edit: LineEdit = $MainContainer/SpcRcContainer/SpeciesContainer/SpeciesNameLEdit
@onready var species_int_btn: Button = $MainContainer/SpcRcContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/SpeciesIntBtn
@onready var species_flt_btn: Button = $MainContainer/SpcRcContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/SpeciesFltBtn
@onready var species_bool_btn: Button = $MainContainer/SpcRcContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/SpeciesBoolBtn
@onready var species_str_btn: Button = $MainContainer/SpcRcContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/SpeciesStrBtn
@onready var species_data_search_l_edit: LineEdit = $MainContainer/SpcRcContainer/CustomDataContainer/SpeciesDataSearchLEdit
@onready var species_data_tree: Tree = $MainContainer/SpcRcContainer/CustomDataContainer/SpeciesDataTree
@onready var race_opt_btn: OptionButton = $MainContainer/RaceContainer/RaceContainer/RaceDataContainer/RaceOptBtn
@onready var create_race_btn: Button = $MainContainer/RaceContainer/RaceContainer/RaceDataContainer/CreateRaceBtn
@onready var delete_race_btn: Button = $MainContainer/RaceContainer/RaceContainer/RaceDataContainer/DeleteRaceBtn
@onready var race_name_l_edit: LineEdit = $MainContainer/RaceContainer/RaceContainer/RaceNameLEdit
@onready var races_int_btn: Button = $MainContainer/RaceContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/RacesIntBtn
@onready var races_flt_btn: Button = $MainContainer/RaceContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/RacesFltBtn
@onready var races_bool_btn: Button = $MainContainer/RaceContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/RacesBoolBtn
@onready var races_str_btn: Button = $MainContainer/RaceContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/RacesStrBtn
@onready var races_data_search_l_edit: LineEdit = $MainContainer/RaceContainer/CustomDataContainer/RacesDataSearchLEdit
@onready var races_data_tree: Tree = $MainContainer/RaceContainer/CustomDataContainer/RacesDataTree


@onready var main_container: HBoxContainer = $MainContainer


func _ready() -> void:
	var races_path: String = ProjectSettings.get_setting(NFRacesRes.SETTINGS_PATH, "")
	
	if not races_path.is_empty() and ResourceLoader.exists(races_path):
		var preload_res: Resource = load(races_path)
		if preload_res is NFRacesRes:
			race_resource = preload_res
	
	main_container.visible = race_resource != null

	if race_resource != null:
		_load_species()
	else:
		no_race_panel = preload("res://addons/nexus_forge/scenes/no_db_container.tscn").instantiate()
		add_child(no_race_panel)
		no_race_panel.set_resource_type("NFRacesRes", "Races", "Race")
		no_race_panel.create_resource_pressed.connect(on_create_database_pressed)
		no_race_panel.load_resource_pressed.connect(on_load_database_pressed)
		no_race_panel.visible = true
	
	
	create_species_btn.pressed.connect(on_create_species)
	create_race_btn.pressed.connect(on_create_race)
	delete_race_btn.pressed.connect(on_delete_race_pressed)
	delete_species_btn.pressed.connect(on_delete_species_pressed)
	
	races_int_btn.pressed.connect(_on_create_race_data_pressed.bind("new_int", 0))
	races_flt_btn.pressed.connect(_on_create_race_data_pressed.bind("new_flt", 0.0))
	races_bool_btn.pressed.connect(_on_create_race_data_pressed.bind("new_bool", false))
	races_str_btn.pressed.connect(_on_create_race_data_pressed.bind("new_str", ""))
	
	species_int_btn.pressed.connect(_on_create_species_data_pressed.bind("new_int", 0))
	species_flt_btn.pressed.connect(_on_create_species_data_pressed.bind("new_flt", 0.0))
	species_bool_btn.pressed.connect(_on_create_species_data_pressed.bind("new_bool", false))
	species_str_btn.pressed.connect(_on_create_species_data_pressed.bind("new_str", ""))
	
	species_data_search_l_edit.text_changed.connect(_on_species_data_search_changed)
	races_data_search_l_edit.text_changed.connect(_on_race_data_search_changed)
	
	species_opt_btn.item_selected.connect(_on_species_selected)
	race_opt_btn.item_selected.connect(_on_race_selected)


func _load_species() -> void:
	species_opt_btn.clear()
	for species in race_resource.get_species():
		add_species(species)
	if species_opt_btn.item_count != 0:
		species_opt_btn.select(0)
		load_species(0)


func on_delete_species_pressed() -> void:
	# TODO Add confirmation before deleting
	delete_species()


func on_delete_race_pressed() -> void:
	# TODO Add confirmation before deleting
	delete_race()


func _on_species_selected(species_idx: int) -> void:
	if current_species != -1:
		save_current_species()
	load_species(species_idx)


func load_species(species_idx: int) -> void:
	species_data_tree.clear_data()
	race_opt_btn.clear()
	
	if species_idx == -1:
		species_name_l_edit.clear()
		current_species = -1
		load_race(-1)
		return

	var species_id: String = species_opt_btn.get_item_text(species_idx)
	species_name_l_edit.text = race_resource.get_species_name(species_id)
	
	for data_key in race_resource.get_species_data_keys(species_id):
		species_data_tree.add_data(
				data_key,
				race_resource.get_species_data(species_id, data_key))
	
	current_species = species_idx
	
	for race in race_resource.get_races(species_id):
		race_opt_btn.add_item(race)
	 
	if 0 < race_opt_btn.item_count:
		race_opt_btn.select(0)
		load_race(0)
	else:
		load_race(-1)


func _on_race_selected(race_idx: int) -> void:
	if current_race != -1:
		save_current_race()
	load_race(race_idx)


func load_race(race_idx: int) -> void:
	races_data_tree.clear_data()
	
	if race_idx == -1:
		race_name_l_edit.clear()
		current_race = -1
		return
	
	var species_id: String = species_opt_btn.get_item_text(current_species)
	var race_id: String = race_opt_btn.get_item_text(race_idx)
	
	race_name_l_edit.text = race_resource.get_race_name(species_id, race_id)
	
	for data_key in race_resource.get_race_data_keys(species_id, race_id):
		races_data_tree.add_data(
			data_key,
			race_resource.get_race_data(species_id, race_id, data_key))
	
	current_race = race_idx


func add_species(species_id: String) -> void:
	species_opt_btn.add_item(species_id)


func get_species_index(species_id: String) -> int:
	for species_idx in range(species_opt_btn.item_count):
		if species_opt_btn.get_item_metadata(species_idx) == species_id:
			return species_idx
	return -1


func delete_species() -> void:
	var new_species: int = clampi(current_species, -1, species_opt_btn.item_count - 2)
	race_resource.erase_species(species_opt_btn.get_item_text(current_species))
	species_opt_btn.remove_item(current_species)
	species_opt_btn.select(new_species)
	load_species(new_species)


func delete_race() -> void:
	var new_race: int = clampi(current_race, -1, race_opt_btn.item_count - 2)
	race_resource.erase_race(
			species_opt_btn.get_item_text(current_species),
			race_opt_btn.get_item_text(current_race))
	race_opt_btn.remove_item(current_race)
	race_opt_btn.select(new_race)
	load_race(new_race)


func on_create_database_pressed() -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").new()
	database_creator.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		race_resource = NFRacesRes.new()
		ResourceSaver.save(race_resource, result[1])
		ProjectSettings.set_setting(NFRacesRes.SETTINGS_PATH, result[1])
		ProjectSettings.save()
		_load_species()
		main_container.visible = true
		no_race_panel.visible = false
		no_race_panel.queue_free()
	
	database_creator.queue_free()


func on_load_database_pressed() -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").new()
	database_creator.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is NFRacesRes:
			race_resource = res_pre
			ProjectSettings.set_setting(NFRacesRes.SETTINGS_PATH, result[1])
			ProjectSettings.save()
			_load_species()
			main_container.visible = true
			no_race_panel.visible = false
			no_race_panel.queue_free()
	
	database_creator.queue_free()


func on_create_species() -> void:
	var new_species := LineEditConfirmationDialog.new()
	new_species.accept_empty = false
	new_species.clean_string = true
	new_species.invalid_strings = race_resource.get_species()
	add_child(new_species)
	new_species.show()
	new_species.focus_line_edit()
	
	var result = await new_species.dialog_confirmed
	
	if result[0]:
		race_resource.create_species(result[1])
		species_opt_btn.add_item(result[1])
		if current_species != -1:
			save_current_species()
		species_opt_btn.select(species_opt_btn.item_count - 1)
		load_species(species_opt_btn.item_count - 1)
	new_species.queue_free()


func on_create_race() -> void:
	var new_race := LineEditConfirmationDialog.new()
	new_race.accept_empty = false
	new_race.clean_string = true
	new_race.invalid_strings = race_resource.get_races(species_opt_btn.get_item_text(current_species))
	add_child(new_race)
	new_race.show()
	new_race.focus_line_edit()
	
	var result: Array = await new_race.dialog_confirmed
	
	if result[0]:
		race_resource.create_race(species_opt_btn.get_item_text(current_species), result[1])
		race_opt_btn.add_item(result[1])
		if current_race != -1:
			save_current_race()
		race_opt_btn.select(race_opt_btn.item_count - 1)
		load_race(race_opt_btn.item_count - 1)
	
	new_race.queue_free()


func _on_create_species_data_pressed(data_name: String, data: Variant) -> void:
	species_data_tree.add_data(data_name, data)


func _on_create_race_data_pressed(data_name: String, data: Variant) -> void:
	races_data_tree.add_data(data_name, data)


func _on_race_data_search_changed(search_text: String) -> void:
	races_data_tree.search_data(search_text.strip_edges())


func _on_species_data_search_changed(search_text: String) -> void:
	species_data_tree.search_data(search_text.strip_edges())


func save_current_race() -> void:
	var species_id: String = species_opt_btn.get_item_text(current_species)
	var race_id: String = race_opt_btn.get_item_text(current_race)
	
	race_resource.set_race_name(species_id, race_id, race_name_l_edit.text.strip_edges())
	race_resource.species[species_id]["races"][race_id]["data"] = races_data_tree.get_data()


func save_current_species() -> void:
	var species_id: String = species_opt_btn.get_item_text(current_species)
	race_resource.set_species_name(species_id, species_name_l_edit.text.strip_edges())
	race_resource.species[species_id]["data"] = species_data_tree.get_data()
	
	if current_race != -1:
		save_current_race()


func save() -> void:
	if current_species != -1:
		save_current_species()
	race_resource.save()
