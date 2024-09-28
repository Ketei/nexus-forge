extends Control


const RACE_RES_PATH: String = "nexus_forge/races_resource"

var _race_resource: NFRacesRes = null
var species_selected: bool = false:
	set(is_selected):
		if is_selected == species_selected:
			return
		species_selected = is_selected
		species_name_l_edit.editable = species_selected
		create_race_btn.disabled = not species_selected
		delete_species_btn.disabled = not species_selected
var race_selected: bool = false:
	set(is_selected):
		if is_selected == race_selected:
			return
		race_selected = is_selected
		custom_int_button.disabled = not race_selected
		custom_float_button.disabled = not race_selected
		custom_bool_button.disabled = not race_selected
		custom_string_button.disabled = not race_selected
		race_name_l_edit.editable = is_selected
		race_text_edit.editable = is_selected
		delete_race_btn.disabled = not race_selected
		stats_tree.set_editable(race_selected)
		genders_tree.set_editable(race_selected)

# On race/species switch, if this is true then save before switching.
var _saving_needed: bool = false 
var _ignore_changes: bool = false

@onready var create_species_btn: Button = $MainContainer/SpcRcContainer/SpeciesContainer/SpeciesDataCotnainer/CreateSpeciesBtn
@onready var delete_species_btn: Button = $MainContainer/SpcRcContainer/SpeciesContainer/SpeciesDataCotnainer/DeleteSpeciesBtn
@onready var create_race_btn: Button = $MainContainer/SpcRcContainer/RaceContainer/RaceDataContainer/CreateRaceBtn
@onready var delete_race_btn: Button = $MainContainer/SpcRcContainer/RaceContainer/RaceDataContainer/DeleteRaceBtn
@onready var custom_int_button: Button = $MainContainer/DataGenderContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/CustomIntButton
@onready var custom_float_button: Button = $MainContainer/DataGenderContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/CustomFloatButton
@onready var custom_bool_button: Button = $MainContainer/DataGenderContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/CustomBoolButton
@onready var custom_string_button: Button = $MainContainer/DataGenderContainer/CustomDataContainer/DataHeader/CustomDataButtonContainer/CustomStringButton
@onready var create_db_button: Button = $NoRacePanel/CenterContainer/InfoContainer/ButtonContainer2/CreateDBButton
@onready var load_db_button: Button = $NoRacePanel/CenterContainer/InfoContainer/ButtonContainer2/LoadDBButton

@onready var species_name_l_edit: LineEdit = $MainContainer/SpcRcContainer/SpeciesContainer/SpeciesNameLEdit
@onready var race_name_l_edit: LineEdit = $MainContainer/SpcRcContainer/RaceContainer/RaceNameLEdit
@onready var stat_search_l_edit: LineEdit = $MainContainer/StatsContainer/StatSearchLEdit
@onready var perk_search_l_edit: LineEdit = $MainContainer/PerksContainer/PerkSlectorContainer/PerkSearchLEdit
@onready var custom_data_search_l_edit: LineEdit = $MainContainer/DataGenderContainer/CustomDataContainer/CustomDataSearchLEdit

@onready var species_opt_btn: OptionButton = $MainContainer/SpcRcContainer/SpeciesContainer/SpeciesDataCotnainer/SpeciesOptBtn
@onready var race_opt_btn: OptionButton = $MainContainer/SpcRcContainer/RaceContainer/RaceDataContainer/RaceOptBtn

@onready var stats_tree: Tree = $MainContainer/StatsContainer/StatsTree
@onready var perks_tree: Tree = $MainContainer/PerksContainer/PerkSlectorContainer/PerksTree
@onready var custom_data_tree: Tree = $MainContainer/DataGenderContainer/CustomDataContainer/CustomDataTree
@onready var genders_tree: Tree = $MainContainer/DataGenderContainer/GenderContainer/GendersTree

@onready var race_text_edit: TextEdit = $MainContainer/SpcRcContainer/RaceTextEdit

@onready var rich_text_label: RichTextLabel = $MainContainer/PerksContainer/PerkDescContainer/RichTextLabel

@onready var main_container: HBoxContainer = $MainContainer
@onready var no_race_panel: PanelContainer = $NoRacePanel

@onready var species_id_select_panel: PanelContainer = $SpeciesIDSelectPanel
@onready var races_resource_dialog: FileDialog = $Elements/RacesResourceDialog


func _ready() -> void:
	var races_path: String = ProjectSettings.get_setting(RACE_RES_PATH, "")
	
	if not races_path.is_empty() and ResourceLoader.exists(races_path):
		var preload_res: Resource = load(races_path)
		if preload_res is NFRacesRes:
			_race_resource = preload_res
	
	main_container.visible = _race_resource != null
	no_race_panel.visible = _race_resource == null
	
	if _race_resource != null:
		_load_species()
	
	races_resource_dialog.file_selected.connect(on_file_path_selected)
	create_db_button.pressed.connect(on_create_database_pressed)
	load_db_button.pressed.connect(on_load_database_pressed)
	species_id_select_panel.create_species_pressed.connect(on_create_species)
	species_id_select_panel.create_race_pressed.connect(on_create_race)
	create_species_btn.pressed.connect(on_create_species_pressed)
	create_race_btn.pressed.connect(on_create_race_pressed)
	race_name_l_edit.text_changed.connect(on_line_changed)
	species_name_l_edit.text_changed.connect(on_line_changed)
	race_text_edit.text_changed.connect(on_something_changed)
	stats_tree.item_checked.connect(on_something_changed)
	custom_data_tree.data_changed.connect(on_something_changed)
	genders_tree.item_checked.connect(on_something_changed)
	delete_race_btn.pressed.connect(on_delete_race_pressed)
	delete_species_btn.pressed.connect(on_delete_species_pressed)
	custom_int_button.pressed.connect(on_create_custom_data_pressed.bind(0))
	custom_float_button.pressed.connect(on_create_custom_data_pressed.bind(0.0))
	custom_bool_button.pressed.connect(on_create_custom_data_pressed.bind(false))
	custom_string_button.pressed.connect(on_create_custom_data_pressed.bind(""))
	stat_search_l_edit.text_changed.connect(on_stat_search_changed)
	custom_data_search_l_edit.text_changed.connect(on_data_search_changed)


func _load_species() -> void:
	species_opt_btn.clear()
	for species in _race_resource.get_species():
		add_species(species)
	if species_opt_btn.item_count != 0:
		species_opt_btn.select(0)
		on_species_selected(0)


func on_delete_species_pressed() -> void:
	# TODO Add confirmation before deleting
	delete_species()


func on_delete_race_pressed() -> void:
	# TODO Add confirmation before deleting
	delete_race()


func on_species_selected(species_idx: int) -> void:
	if species_idx == -1:
		race_opt_btn.clear()
		on_race_selected(-1)
		species_name_l_edit.clear()
		species_selected = false
		return
	
	if _saving_needed:
		save_active_race()
	_ignore_changes = true
	var species_id: String = species_opt_btn.get_item_text(species_idx)
	species_name_l_edit.text = _race_resource.get_species_name(species_id)
	species_selected = true
	stat_search_l_edit.clear()
	perk_search_l_edit.clear()
	load_races(species_id)
	_ignore_changes = false


func on_race_selected(race_idx: int) -> void:
	if race_idx == -1:
		genders_tree.clear_gender_checks()
		stats_tree.clear_stat_checks()
		custom_data_tree.clear_custom_data()
		race_name_l_edit.clear()
		race_text_edit.clear()
		race_selected = false
		return
	
	if _saving_needed:
		save_active_race()
	
	_ignore_changes = true
	
	var species_id: String = species_opt_btn.get_item_text(species_opt_btn.selected)
	var race_id: String = race_opt_btn.get_item_text(race_idx)
	
	race_name_l_edit.text = _race_resource.get_race_name(species_id, race_id)
	race_text_edit.text = _race_resource.get_race_desc(species_id, race_id)
	
	genders_tree.clear_gender_checks()
	
	for gender in _race_resource.get_race_genders(species_id, race_id):
		genders_tree.set_gender_chekced(gender, true)
	
	stats_tree.clear_stat_checks()
	
	for stat in _race_resource.get_race_stats(species_id, race_id):
		stats_tree.set_stat_checked(stat, true)
	
	var custom_data: Dictionary = _race_resource.get_race_custom_data_dict(species_id, race_id)
	
	custom_data_tree.clear_custom_data()
	
	for data in custom_data:
		custom_data_tree.create_custom_data(data, custom_data_tree[data])
	
	_ignore_changes = false
	race_selected = true


func load_races(species_id: String) -> void:
	race_opt_btn.clear()
	
	for race in _race_resource.get_races(species_id):
		race_opt_btn.add_item(race)
	 
	if race_opt_btn.item_count != 0:
		race_opt_btn.select(0)
		on_race_selected(0)


func add_species(species_id: String) -> void:
	species_opt_btn.add_item(species_id)


func get_species_index(species_id: String) -> int:
	for species_idx in range(species_opt_btn.item_count):
		if species_opt_btn.get_item_metadata(species_idx) == species_id:
			return species_idx
	return -1


func delete_species() -> void:
	#var index_selected: int = species_opt_btn.selected
	_race_resource.remove_species(species_opt_btn.get_item_text(species_opt_btn.selected))
	species_opt_btn.remove_item(species_opt_btn.selected)
	#var new_index: int = mini(species_opt_btn.item_count - 1, index_selected)
	#species_opt_btn.select(new_index)
	#on_species_selected(new_index)
	on_species_selected(species_opt_btn.selected)


func delete_race() -> void:
	#var index_selected: int = race_opt_btn.selected
	_race_resource.remove_race(
			species_opt_btn.get_item_text(species_opt_btn.selected),
			race_opt_btn.get_item_text(race_opt_btn.selected))
	race_opt_btn.remove_item(race_opt_btn.selected)
	#var new_index: int = mini(race_opt_btn.item_count - 1, index_selected)
	#race_opt_btn.select(new_index)
	#on_race_selected(new_index)
	on_race_selected(race_opt_btn.selected)


func on_create_database_pressed() -> void:
	races_resource_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	races_resource_dialog.show()


func on_load_database_pressed() -> void:
	races_resource_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	races_resource_dialog.show()


func on_create_species(species_id: String) -> void:
	species_id_select_panel.visible = false
	_race_resource.create_species(species_id)
	species_opt_btn.add_item(species_id)
	species_opt_btn.select(species_opt_btn.item_count - 1)
	on_species_selected(species_opt_btn.item_count - 1)


func on_create_race(species_id: String, race_id: String) -> void:
	species_id_select_panel.visible = false
	_race_resource.create_race(species_id, race_id)
	race_opt_btn.add_item(race_id)
	race_opt_btn.select(race_opt_btn.item_count - 1)
	on_race_selected(race_opt_btn.item_count - 1)


func on_file_path_selected(file_path: String) -> void:
	if races_resource_dialog.file_mode == FileDialog.FileMode.FILE_MODE_SAVE_FILE:
		var new_races := NFRacesRes.new()
		if ResourceSaver.save(new_races, file_path) == OK:
			_race_resource = new_races
	else:
		var preload_res: Resource = load(file_path)
		if preload_res is NFRacesRes:
			_race_resource = preload_res
		else:
			printerr("[RACES] Selected resource isn't NFRacesRes")
		
	if _race_resource != null:
		ProjectSettings.set_setting(RACE_RES_PATH, file_path)
		ProjectSettings.save()
		_load_species()
		species_id_select_panel._race_resource = _race_resource
		main_container.visible = true
		no_race_panel.visible = false


func on_create_species_pressed() -> void:
	species_id_select_panel.create_new_species()


func on_create_race_pressed() -> void:
	species_id_select_panel.create_new_race(
			species_opt_btn.get_item_text(species_opt_btn.selected))


func on_something_changed() -> void:
	if not _saving_needed and not _ignore_changes:
		_saving_needed = true


func on_line_changed(_new_text: String) -> void:
	on_something_changed()


func on_create_custom_data_pressed(data_variant: Variant) -> void:
	custom_data_tree.create_custom_data("", data_variant)


func on_stat_search_changed(search_text: String) -> void:
	stats_tree.search_stat(search_text.strip_edges())


func on_data_search_changed(search_text: String) -> void:
	custom_data_tree.search_data(search_text.strip_edges())


func save_active_race() -> void:
	if species_opt_btn.item_count == 0 or species_opt_btn.selected == -1:
		return
	
	var species_id: String = species_opt_btn.get_item_text(species_opt_btn.selected)
	
	_race_resource.set_species_name(species_id, species_name_l_edit.text.strip_edges())
		
	if 0 < race_opt_btn.item_count:
		var race_id: String = race_opt_btn.get_item_text(race_opt_btn.selected)
		_race_resource.set_race_name(species_id, race_id, race_name_l_edit.text.strip_edges())
		_race_resource.set_race_description(species_id, race_id, race_text_edit.text.strip_edges())
		_race_resource.assign_race_genders(species_id, race_id, genders_tree.get_gender_data())
		_race_resource.assign_race_stats(species_id, race_id, stats_tree.get_selected_stats())
		_race_resource.set_race_custom_data_dict(species_id, race_id, custom_data_tree.get_custom_data_dict())
	
	_race_resource.save()
	_saving_needed = false
