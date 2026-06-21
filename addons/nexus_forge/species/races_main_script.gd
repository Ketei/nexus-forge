@tool
extends PanelContainer


signal species_loaded
const LineEditConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd")

var _unsaved: bool = false
var _species_resource: SpeciesCatalog = null
var listen_select: bool = true
var loaded_species: StringName = &""
var signal_change: bool = false
var _current_species: Array[StringName] = []

@onready var search_race_ln_edt: LineEdit = $RacesContainer/RacesBasicSplit/RaceTreeContainer/SearchRaceContainer/SearchRaceLnEdt
@onready var new_race_btn: Button = $RacesContainer/RacesBasicSplit/RaceTreeContainer/SearchRaceContainer/NewRaceBtn
@onready var races_tree: Tree = $RacesContainer/RacesBasicSplit/RaceTreeContainer/RacesTree
@onready var race_name_ln_edt: LineEdit = $RacesContainer/RacesBasicSplit/BasicDataContainer/NameContainer/RaceNameLnEdt
@onready var race_desc_txt_edt: TextEdit = $RacesContainer/RacesBasicSplit/BasicDataContainer/DescContainer/RaceDescTxtEdt
@onready var add_rc_int_button: Button = $RacesContainer/RacesBasicSplit/BasicDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddRcIntButton
@onready var add_rc_float_button: Button = $RacesContainer/RacesBasicSplit/BasicDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddRcFloatButton
@onready var add_rc_bool_button: Button = $RacesContainer/RacesBasicSplit/BasicDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddRcBoolButton
@onready var add_rc_string_button: Button = $RacesContainer/RacesBasicSplit/BasicDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddRcStringButton
@onready var add_dict_button: Button = $RacesContainer/RacesBasicSplit/BasicDataContainer/CustomDataContainer/CDHeaderContainer/AddButtonsContainer/AddDictButton
@onready var race_custom_data_search_line: LineEdit = $RacesContainer/RacesBasicSplit/BasicDataContainer/CustomDataContainer/RaceCustomDataSearchLine
@onready var race_data_tree: Tree = $RacesContainer/RacesBasicSplit/BasicDataContainer/CustomDataContainer/RaceDataTree
@onready var race_stats_container: VBoxContainer = $RacesContainer/StatTraitSplit/ValuesContainer/StatVBox/StatScroll/RaceStatsContainer
@onready var race_skill_container: VBoxContainer = $RacesContainer/StatTraitSplit/ValuesContainer/SkillVBox/SkillScroll/RaceSkillContainer
@onready var race_traits_container: VBoxContainer = $RacesContainer/StatTraitSplit/TraitsContainer/ScrollContainer/RaceTraitsContainer

@onready var edit_stat_block_btn: Button = $RacesContainer/StatTraitSplit/ValuesContainer/StatVBox/StatLbl/EditStatBlockBtn
@onready var edit_skill_set_btn: Button = $RacesContainer/StatTraitSplit/ValuesContainer/SkillVBox/StatLbl/EditSkillSetBtn
@onready var edit_trait_block_btn: Button = $RacesContainer/StatTraitSplit/TraitsContainer/StatLbl/EditTraitBlockBtn

@onready var manage_hybrid: Button = $RacesContainer/RacesBasicSplit/BasicDataContainer/ManageHybrid
@onready var hybridization_panel: PanelContainer = $HybridizationPanel
@onready var dom_opt_btn: OptionButton = $HybridizationPanel/CenterContainer/MainPanel/ItemVBox/DominantSpecies/DomOptBtn
@onready var sub_opt_btn: OptionButton = $HybridizationPanel/CenterContainer/MainPanel/ItemVBox/RecessiveSpecies/SubOptBtn
@onready var cancel_hybrid: Button = $HybridizationPanel/CenterContainer/MainPanel/ItemVBox/ButtonBox/CancelHybrid
@onready var commit_hybrid: Button = $HybridizationPanel/CenterContainer/MainPanel/ItemVBox/ButtonBox/CommitHybrid
@onready var hybrid_info_container: HBoxContainer = $RacesContainer/RacesBasicSplit/BasicDataContainer/HybridInfoContainer
@onready var hybrid_a: Label = $RacesContainer/RacesBasicSplit/BasicDataContainer/HybridInfoContainer/HybridA
@onready var hybrid_b: Label = $RacesContainer/RacesBasicSplit/BasicDataContainer/HybridInfoContainer/HybridB


func ready_plugin() -> void:
	races_tree.ready_plugin()
	race_data_tree.ready_plugin()
	
	reload_resource(true)
	update_talent_nodes()
	
	search_race_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	
	add_dict_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	race_custom_data_search_line.right_icon = get_theme_icon("Search", "EditorIcons")
	edit_stat_block_btn.icon = get_theme_icon("Edit", "EditorIcons")
	edit_skill_set_btn.icon = get_theme_icon("Edit", "EditorIcons")
	edit_trait_block_btn.icon = get_theme_icon("Edit", "EditorIcons")
	
	manage_hybrid.pressed.connect(_on_hybridize_pressed)
	commit_hybrid.pressed.connect(_on_hybridize_confirmed)
	cancel_hybrid.pressed.connect(_on_hybridize_cancelled)
	
	search_race_ln_edt.text_changed.connect(_on_search_species_text_changed)
	new_race_btn.pressed.connect(_on_create_species_pressed)
	
	races_tree.species_created.connect(_on_species_created, CONNECT_DEFERRED)
	races_tree.species_selected.connect(_on_species_selected, CONNECT_DEFERRED)
	races_tree.species_erased.connect(_on_species_erased, CONNECT_DEFERRED)
	races_tree.species_id_changed.connect(_on_species_id_changed, CONNECT_DEFERRED)
	races_tree.something_changed.connect(_on_something_changed)
	races_tree.species_dehibridized.connect(_on_species_dehibridized)
	race_name_ln_edt.text_changed.connect(_on_something_changed)
	race_desc_txt_edt.text_changed.connect(_on_something_changed)
	
	add_rc_int_button.pressed.connect(_on_add_data_pressed.bind("new_int", 0))
	add_rc_float_button.pressed.connect(_on_add_data_pressed.bind("new_float", 0.0))
	add_rc_bool_button.pressed.connect(_on_add_data_pressed.bind("new_bool", false))
	add_rc_string_button.pressed.connect(_on_add_data_pressed.bind("new_string", ""))
	add_dict_button.pressed.connect(_on_add_data_pressed.bind("new_folder", {}))
	race_data_tree.data_changed.connect(_on_something_changed)
	
	edit_stat_block_btn.pressed.connect(_on_edit_statblock_pressed)
	edit_skill_set_btn.pressed.connect(_on_edit_skillset_pressed)
	edit_trait_block_btn.pressed.connect(_on_edit_traitblock_pressed)
	
	dom_opt_btn.item_selected.connect(_on_dominant_gene_selected)


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


func _on_hybridize_pressed() -> void:
	hybridization_panel.visible = true
	
	dom_opt_btn.clear()
	sub_opt_btn.clear()
	_current_species.clear()
	
	sub_opt_btn.add_item("- None -")
	sub_opt_btn.set_item_metadata(0, &"")
	
	var species: Array[String] = races_tree.get_all_species()
	species.sort()
	
	var parent_species: StringName = races_tree.get_parent_species_of(loaded_species)
	var hybrid_species: Dictionary[StringName, Variant] = {}
	
	for species_id in races_tree.get_subspecies_of(loaded_species):
		hybrid_species[species_id] = null
	
	for id in species:
		var strn_id: StringName = StringName(id)
		if hybrid_species.has(strn_id):
			continue
		_current_species.append(strn_id)
		if strn_id == loaded_species:
			continue
		dom_opt_btn.add_item(id)
		dom_opt_btn.set_item_metadata(-1, strn_id)
	
	for idx in range(dom_opt_btn.item_count):
		if dom_opt_btn.get_item_metadata(idx) == parent_species:
			dom_opt_btn.select(idx)
			break
	
	var dom_metadata: StringName = dom_opt_btn.get_selected_metadata() if -1 < dom_opt_btn.selected else &""
	
	for id in _current_species:
		if id == loaded_species or id == dom_metadata or hybrid_species.has(id):
			continue
		sub_opt_btn.add_item(String(id))
		sub_opt_btn.set_item_metadata(-1, id)
	
	sub_opt_btn.grab_focus()


func _on_dominant_gene_selected(idx: int) -> void:
	var dom_gene: StringName = dom_opt_btn.get_item_metadata(idx)
	var sub_selected: StringName = sub_opt_btn.get_selected_metadata()
	var new_idx: int = 0
	sub_opt_btn.clear()
	
	sub_opt_btn.add_item("- None -")
	sub_opt_btn.set_item_metadata(0, &"")
	
	var index: int = 0
	for item in _current_species:
		if item == loaded_species or item == dom_gene:
			continue
		index += 1
		sub_opt_btn.add_item(String(item))
		sub_opt_btn.set_item_metadata(index, item)
		if item == sub_selected:
			new_idx = index
	
	if sub_selected != dom_gene:
		sub_opt_btn.select(new_idx)
	else:
		sub_opt_btn.select(0)


func _on_hybridize_confirmed() -> void:
	hybridization_panel.visible = false
	
	if sub_opt_btn.get_selected_metadata().is_empty():
		if races_tree.is_species_hybrid(loaded_species):
			var species_id: StringName = dom_opt_btn.get_selected_metadata()
			races_tree.set_species_as_subspecies_of(
					loaded_species,
					dom_opt_btn.get_selected_metadata())
			hybrid_info_container.visible = false
		return
	
	races_tree.hybridize_species(loaded_species, StringName(dom_opt_btn.get_selected_metadata()), StringName(sub_opt_btn.get_selected_metadata()))
	hybrid_a.text = dom_opt_btn.get_selected_metadata()
	hybrid_b.text = sub_opt_btn.get_selected_metadata()
	hybrid_info_container.visible = true


func _on_hybridize_cancelled() -> void:
	hybridization_panel.visible = false


func _on_species_dehibridized(species_id: StringName) -> void:
	if species_id == loaded_species and hybrid_info_container.visible:
		hybrid_info_container.visible = false


func reload_resource(first_load: bool = false) -> void:
	var was_null: bool = _species_resource == null
	_species_resource = null
	race_name_ln_edt.text = ""
	race_desc_txt_edt.text = ""
	race_data_tree.clear_data()
	default_talents()
	
	var res_path: String = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("species"), "")
	
	if res_path != "" and FileAccess.file_exists(res_path):
		var preload_res: Resource = load(res_path)
		if preload_res is SpeciesCatalog:
			_species_resource = preload_res
	
	if _species_resource == null:
		if not was_null or first_load:
			$RacesContainer.visible = false
			var no_db = preload("res://addons/nexus_forge/no_db_container.tscn").instantiate()
			add_child(no_db)
			no_db.message_minimum_size.x = 450
			no_db.set_resource_type("SpeciesCatalog", "Species", "Species")
			no_db.create_resource_pressed.connect(_on_create_database_pressed.bind(no_db))
			no_db.load_resource_pressed.connect(_on_load_database_pressed.bind(no_db))
			no_db.resource_dropped.connect(_on_resource_dropped.bind(no_db))
	else:
		$RacesContainer.visible = true
		load_species_resource()
	
	set_ui_enabled(false)


func _on_race_display_changed() -> void:
	if signal_change:
		return
	signal_change = true


func _on_create_database_pressed(node: Control) -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_SAVE_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		_species_resource = SpeciesCatalog.new()
		ResourceSaver.save(_species_resource, result[1])
		_species_resource.resource_path = result[1]
		ProjectSettings.set_setting(
				NFPluginGameHandler.get_setting_path("species"),
				result[1])
		if Engine.is_editor_hint():
			ProjectSettings.save()
		load_species_resource()
		$RacesContainer.visible = true
		node.visible = false
		node.queue_free()
	
	database_creator.queue_free()


func _on_resource_dropped(resource: Resource, panel: Control) -> void:
	_species_resource = resource
	ProjectSettings.set_setting(
			NFPluginGameHandler.get_setting_path("species"),
			resource.resource_path)
	if Engine.is_editor_hint():
		ProjectSettings.save()
	panel.visible = false
	panel.queue_free()
	$RacesContainer.visible = true
	load_species_resource()


func _on_load_database_pressed(node: Control) -> void:
	var database_creator := preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	database_creator.file_mode = database_creator.FILE_MODE_OPEN_FILE
	add_child(database_creator)
	database_creator.show()
	
	var result = await database_creator.dialog_finished
	
	if result[0]:
		var res_pre: Resource = load(result[1])
		if res_pre != null and res_pre is SpeciesCatalog:
			_species_resource = res_pre
			ProjectSettings.set_setting(
					NFPluginGameHandler.get_setting_path("species"),
					result[1])
			if Engine.is_editor_hint():
				ProjectSettings.save()
			load_species_resource()
			$RacesContainer.visible = true
			node.visible = false
			node.queue_free()
	
	database_creator.queue_free()


func _on_add_data_pressed(data_name: String, value: Variant) -> void:
	race_data_tree.add_data(data_name, value)
	_on_something_changed()


func _on_species_id_changed(from: StringName, to: StringName) -> void:
	if from == to:
		return
	_species_resource._species[to] = _species_resource._species[from]
	_species_resource._species.erase(from)
	for species in _species_resource._species.keys():
		if _species_resource._species[species]["parent_key"] == from:
			_species_resource._species[species]["parent_key"] = to
	if loaded_species == from:
		loaded_species = to
	_on_something_changed()
	_on_race_display_changed()


func _on_species_erased(species: Array[StringName]) -> void:
	for species_id in species:
		_species_resource._species.erase(species_id)
	if species.has(loaded_species):
		race_name_ln_edt.text = ""
		race_desc_txt_edt.text = ""
		race_data_tree.clear_data()
		set_ui_enabled(false)
		default_talents()
		loaded_species = &""
	manage_hybrid.disabled = _species_resource._species.size() <= 1
	_on_something_changed()
	_on_race_display_changed()


func _on_search_species_text_changed(text: String) -> void:
	races_tree.search_species(text.strip_edges())


func _on_species_created(species_id: StringName, item: TreeItem) -> void:
	if not loaded_species.is_empty():
		save_current_species()
	listen_select = false
	_species_resource.create_species(species_id)
	_species_resource.set_species_name(species_id, "New Species")
	load_species(species_id)
	loaded_species = species_id
	item.select(0)
	listen_select = true
	_on_something_changed()
	save()
	_on_race_display_changed()


func _on_species_selected(species_id: StringName) -> void:
	if not listen_select or loaded_species == species_id:
		return
	
	if not loaded_species.is_empty():
		save_current_species()
	
	load_species(species_id)
	manage_hybrid.disabled = _species_resource._species.size() <= 1
	loaded_species = species_id
	set_ui_enabled(true)


func _on_create_species_pressed() -> void:
	var id_creator := LineEditConfirmationDialog.new()
	id_creator.line_placeholder_text = "Species ID"
	id_creator.allow_empty = false
	id_creator.use_blacklist = true
	id_creator.character_blacklist.append(" ")
	id_creator.text_blacklist.assign(races_tree.get_all_species())
	id_creator.title = "Create Species"
	id_creator.ok_button_text = "Create"
	add_child(id_creator)
	id_creator.show()
	id_creator.grab_text_focus()
	
	var result: Array = await id_creator.dialog_finished
	
	if result[0]:
		if not loaded_species.is_empty():
			save_current_species()
		listen_select = false
		var species_id: StringName = StringName(result[1])
		races_tree.add_species(species_id, true)
		_species_resource.create_species(species_id)
		_species_resource.set_species_name(species_id, "New Species")
		load_species(species_id)
		loaded_species = species_id
		listen_select = true
		set_ui_enabled(true)
		_on_something_changed()
		_on_race_display_changed()
		
	id_creator.queue_free()


func _on_something_changed(_arg = null) -> void:
	if _unsaved:
		return
	
	_unsaved = true


func _on_value_field_toggled(toggled: bool, spin: SpinBox) -> void:
	spin.editable = toggled
	_on_something_changed()


func save_current_species() -> void:
	_species_resource.set_species_name(loaded_species, race_name_ln_edt.text.strip_edges())
	_species_resource.set_species_description(loaded_species, race_desc_txt_edt.text.strip_edges())
	_species_resource.clear_species_data(loaded_species)
	var data: Dictionary[String, Variant] = race_data_tree.get_data()
	
	for data_key in data.keys():
		_species_resource.set_species_data(
				loaded_species,
				data_key,
				data[data_key])
	
	_species_resource.clear_species_stats(loaded_species)
	
	for stat in race_stats_container.get_children():
		if stat.get_child(0).button_pressed == false:
			continue
		
		_species_resource.set_species_stat_value(
				loaded_species,
				stat.get_meta(&"field_id"),
				int(stat.get_child(1).value))
	
	_species_resource.clear_species_skills(loaded_species)
	
	for skill in race_skill_container.get_children():
		if skill.get_child(0).button_pressed == false:
			continue
		
		_species_resource.set_species_skill_value(
				loaded_species,
				skill.get_meta(&"field_id"),
				int(skill.get_child(1).value))
	
	_species_resource.clear_species_traits(loaded_species)
	
	for trait_child in race_traits_container.get_children():
		if trait_child.get_child(0).button_pressed == false:
			continue
		
		_species_resource.set_species_trait_value(
				loaded_species,
				trait_child.get_meta(&"field_id"),
				int(trait_child.get_child(1).value))


func load_species_resource() -> void:
	race_name_ln_edt.text = ""
	race_desc_txt_edt.text = ""
	race_data_tree.clear_data()
	default_talents()
	var top_species: Array[StringName] = []
	var subspecies: Dictionary[StringName, Array] = {}
	var hybrid_species: Array[Dictionary] = []
	
	for species_key in _species_resource._species.keys():
		if _species_resource._species[species_key]["parent_dominant"].is_empty():
			top_species.append(species_key)
		else:
		#elif _species_resource[species_key]["parent_recessive"].is_empty():
			if not subspecies.has(_species_resource._species[species_key]["parent_dominant"]):
				subspecies[_species_resource._species[species_key]["parent_dominant"]] = []
			subspecies[_species_resource._species[species_key]["parent_dominant"]].append(species_key)
		
		if not _species_resource._species[species_key]["parent_recessive"].is_empty():
			hybrid_species.append({
				"dom": _species_resource._species[species_key]["parent_dominant"],
				"sub": _species_resource._species[species_key]["parent_recessive"],
				"hybrid": species_key})
			
	races_tree.clear_species()
	
	for id in top_species:
		races_tree.create_species(id)
		if subspecies.has(id):
			for sub_id in subspecies[id]:
				_build_branch(sub_id, id, subspecies)
	
	for hybrid_data in hybrid_species:
		races_tree.hybridize_species(
				hybrid_data["hybrid"],
				hybrid_data["dom"],
				hybrid_data["sub"])
	
	species_loaded.emit()

func _build_branch(species: StringName, parent_of: StringName, subspecies_list: Dictionary[StringName, Array]) -> void:
	races_tree.create_species(species, parent_of)
	if subspecies_list.has(species):
		for sub_id in subspecies_list[species]:
			_build_branch(sub_id, species, subspecies_list)


func load_species(species_id: StringName) -> void:
	race_name_ln_edt.text = _species_resource.get_species_name(species_id)
	race_desc_txt_edt.text = _species_resource.get_species_description(species_id)
	race_data_tree.clear_data()
	
	if races_tree.is_species_hybrid(species_id):
		hybrid_info_container.visible = true
		hybrid_a.text = races_tree.get_dominant_gene(species_id)
		hybrid_b.text = races_tree.get_recessive_gene(species_id)
	else:
		hybrid_info_container.visible = false
	
	for data_key in _species_resource.species_data_keys(species_id):
		race_data_tree.add_data(data_key, _species_resource.get_species_data(species_id, data_key))
	
	for stat in race_stats_container.get_children():
		var stat_id: StringName = stat.get_meta(&"field_id")
		var spn: SpinBox = stat.get_child(1)
		var chk: CheckBox = stat.get_child(0)
		if _species_resource.species_has_stat(species_id, stat_id):
			chk.set_pressed_no_signal(true)
			spn.editable = true
			spn.set_value_no_signal(_species_resource.get_species_stat_value(species_id, stat_id))
		else:
			chk.set_pressed_no_signal(false)
			spn.editable = false
			spn.set_value_no_signal(stat.get_meta(&"default_value", 0.0))
	
	for skill in race_skill_container.get_children():
		var skill_id: StringName = skill.get_meta(&"field_id")
		var spn: SpinBox = skill.get_child(1)
		var chk: CheckBox = skill.get_child(0)
		
		if _species_resource.species_has_skill(species_id, skill_id):
			chk.set_pressed_no_signal(true)
			spn.editable = true
			spn.value = _species_resource.get_species_skill_value(species_id, skill_id)
		else:
			chk.set_pressed_no_signal(false)
			spn.editable = false
			spn.set_value_no_signal(skill.get_meta(&"default_value", 0.0))
	
	for trait_child in race_traits_container.get_children():
		var trait_id: StringName = trait_child.get_meta(&"field_id")
		var spn: SpinBox = trait_child.get_child(1)
		var chk: CheckBox = trait_child.get_child(0)
		if _species_resource.species_has_trait(species_id, trait_id):
			chk.set_pressed_no_signal(true)
			spn.editable = true
			spn.value = _species_resource.get_species_trait_value(species_id, trait_id)
		else:
			chk.set_pressed_no_signal(false)
			spn.editable = false
			spn.set_value_no_signal(trait_child.get_meta(&"default_value", 0.0))


func clear_talents() -> void:
	for child in race_stats_container.get_children():
		race_stats_container.remove_child(child)
		child.queue_free()
	
	for child in race_skill_container.get_children():
		race_skill_container.remove_child(child)
		child.queue_free()
	
	for child in race_traits_container.get_children():
		race_traits_container.remove_child(child)
		child.queue_free()


func default_talents() -> void:
	for stat in race_stats_container.get_children():
		var spn: SpinBox = stat.get_child(1)
		var chk: CheckBox = stat.get_child(0)
		chk.set_pressed_no_signal(false)
		spn.editable = false
		spn.value = 1.0
	
	
	for skill in race_skill_container.get_children():
		var spn: SpinBox = skill.get_child(1)
		var chk: CheckBox = skill.get_child(0)
		chk.set_pressed_no_signal(false)
		spn.editable = false
		spn.value = skill.get_meta(&"default_value", 0.0)
	
	for trait_child in race_traits_container.get_children():
		var spn: SpinBox = trait_child.get_child(1)
		var chk: CheckBox = trait_child.get_child(0)
		chk.set_pressed_no_signal(false)
		spn.editable = false
		spn.value = trait_child.get_meta(&"default_value", 0.0)


func set_ui_enabled(enabled: bool) -> void:
	var disabled: bool = not enabled
	
	race_custom_data_search_line.editable = enabled
	race_name_ln_edt.editable = enabled
	race_desc_txt_edt.editable = enabled
	add_rc_int_button.disabled = disabled
	add_rc_float_button.disabled = disabled
	add_rc_bool_button.disabled = disabled
	add_rc_string_button.disabled = disabled
	add_dict_button.disabled = disabled
	race_data_tree.enabled = enabled
	
	for child in race_stats_container.get_children():
		child.get_child(0).disabled = disabled
	
	for child in race_skill_container.get_children():
		child.get_child(0).disabled = disabled
	
	for child in race_traits_container.get_children():
		child.get_child(0).disabled = disabled


func update_talent_nodes() -> void:
	var skill_set: SkillSet = SkillSet.new(false)
	
	var trait_block: TraitBlock = TraitBlock.new(false)
	
	var stat_block: StatBlock = StatBlock.new(false)
	
	var stat_data: Dictionary[StringName, int] = StatBlock.stats()
	var stats: Array[StringName] = []
	stats.assign(stat_data.keys())
	stats.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	var stat_map: Dictionary[StringName, HBoxContainer] = {}
	for existing_stat in race_stats_container.get_children():
		race_stats_container.remove_child(existing_stat)
		if existing_stat.get_meta(&"field_id") in stats:
			stat_map[existing_stat.get_meta(&"field_id")] = existing_stat
		else:
			existing_stat.queue_free()
	
	for stat_id in stats:
		var stat_default: float = 0.0
		var stat_item: ValueRange = stat_block.get(stat_id)
		if stat_item != null:
			stat_default = stat_item.value
		
		if stat_map.has(stat_id):
			race_stats_container.add_child(stat_map[stat_id])
			stat_map[stat_id].set_meta(&"default_value", stat_default)
			if stat_data[stat_id] != stat_map[stat_id].get_meta(&"type"):
				stat_map[stat_id].get_meta(&"value").step = 1.0 if stat_data[stat_id] == TYPE_INT else 0.01
			stat_map.erase(stat_id)
		else:
			var stat = create_value_field(stat_id, stat_default, stat_data[stat_id])
			race_stats_container.add_child(stat)
	for remaining_stat in stat_map:
		stat_map[remaining_stat].queue_free()
	
	var skills: Array[StringName] = SkillSet.skills()
	skills.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	var skill_map: Dictionary[StringName, HBoxContainer] = {}
	for existing_skill in race_skill_container.get_children():
		race_skill_container.remove_child(existing_skill)
		if skills.has(existing_skill.get_meta(&"field_id")):
			skill_map[existing_skill.get_meta(&"field_id")] = existing_skill
		else:
			existing_skill.queue_free()
	
	for skill_id in skills:
		if skill_map.has(skill_id):
			skill_map[skill_id].set_meta(&"default_value", skill_set.get(skill_id))
			race_skill_container.add_child(skill_map[skill_id])
			skill_map.erase(skill_id)
		else:
			var skill = create_value_field(skill_id, skill_set.get(skill_id))
			race_skill_container.add_child(skill)
	for remaining_skill in skill_map.keys():
		skill_map[remaining_skill].queue_free()
	
	var traits: Array[StringName] = TraitBlock.traits()
	
	traits.sort_custom(func(a,b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	
	var trait_map: Dictionary[StringName, HBoxContainer] = {}
	for existing_trait in race_traits_container.get_children():
		race_traits_container.remove_child(existing_trait)
		if traits.has(existing_trait.get_meta(&"field_id")):
			trait_map[existing_trait.get_meta(&"field_id")] = existing_trait
		else:
			existing_trait.queue_free()
	
	for trait_id in traits:
		if trait_map.has(trait_id):
			trait_map[trait_id].set_meta(&"default_value", trait_block.get(trait_id))
			race_traits_container.add_child(trait_map[trait_id])
			trait_map.erase(trait_id)
		else:
			var new_trait: HBoxContainer = create_value_field(trait_id, trait_block.get(trait_id))
			race_traits_container.add_child(new_trait)
	for remaining_trait in trait_map.keys():
		trait_map[remaining_trait].queue_free()
	
	if loaded_species != &"":
		_on_something_changed()


func value_field_active(field: HBoxContainer) -> bool:
	return field.get_child(0).button_pressed


func create_value_field(field_id: StringName, default_value: int, type: int = TYPE_NIL) -> HBoxContainer:
	var new_field: HBoxContainer = HBoxContainer.new()
	var activatable: CheckBox = CheckBox.new()
	var value: SpinBox = SpinBox.new()
	
	activatable.text = String(field_id).capitalize()
	activatable.tooltip_text = activatable.text
	activatable.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	activatable.custom_minimum_size.y = 32.0
	activatable.size_flags_stretch_ratio = 2.0
	activatable.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	value.allow_greater = true
	value.allow_lesser = true
	
	if type != TYPE_NIL:
		if type == TYPE_INT:
			value.step = 1.0
		else:
			value.step = 0.01
		new_field.set_meta(&"type", type)
		
	else:
		value.step = 1.0
	
	value.value = default_value
	value.editable = false
	value.update_on_text_changed = true
	value.custom_minimum_size.y = 32
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.size_flags_stretch_ratio = 3.0
	
	new_field.add_child(activatable)
	new_field.add_child(value)
	
	new_field.set_meta(&"field_id", field_id)
	new_field.set_meta(&"default_value", default_value)
	new_field.set_meta(&"value", value)
	
	activatable.toggled.connect(_on_value_field_toggled.bind(value))
	value.value_changed.connect(_on_something_changed)
	
	return new_field


func save() -> void:
	_unsaved = false
	if _species_resource == null:
		return
	if not loaded_species.is_empty():
		save_current_species()
	var species_data: Array[Dictionary] = races_tree.get_species_map()
	var top_species: Array[StringName] = []
	var sub_species: Array[Dictionary] = []
	
	# We clear the top species link, as they are a subspecies of nothing.
	for species in species_data:
		var id: StringName = species["species_id"]
		var dom: StringName = species["dominant_species"]
		var sub: StringName = species["recessive_species"]
		
		_species_resource.link_species(id, dom, sub)
		
	ResourceSaver.save(_species_resource)
