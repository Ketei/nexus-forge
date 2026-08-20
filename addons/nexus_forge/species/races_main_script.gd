@tool
extends PanelContainer


signal species_loaded

const UNDO_MAX_STEPS: int = 50

var _unsaved: bool = false
var _species_resource: SpeciesCatalog = null
var loaded_species: StringName = &""
var undo: UndoRedo = null
var expr: Expression = null
var _current_species: Array[StringName] = [] # Used for hybridization
var _gui_enabled: bool = false
var signal_change: bool = false

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


func _ready() -> void:
	set_process_input(false)


func ready_plugin() -> void:
	set_process_input(true)
	undo = UndoRedo.new()
	undo.max_steps = UNDO_MAX_STEPS
	race_data_tree.undo_redo_steps = UNDO_MAX_STEPS
	
	expr = Expression.new()
	
	races_tree.ready_plugin()
	race_data_tree.ready_plugin()
	
	set_ui_enabled(false)
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
	races_tree.erase_species_requested.connect(_on_erase_species_requested)
	races_tree.species_id_changed.connect(_on_species_id_changed)
	races_tree.something_changed.connect(_on_something_changed)
	races_tree.species_dehibridized.connect(_on_species_dehibridized)
	races_tree.species_moved.connect(_on_species_moved)
	
	race_name_ln_edt.text_changed.connect(_on_something_changed)
	race_name_ln_edt.editing_toggled.connect(_on_race_name_editing_toggled)
	race_desc_txt_edt.text_changed.connect(_on_something_changed)
	race_desc_txt_edt.focus_exited.connect(_on_desc_text_focus_lost)
	
	add_rc_int_button.pressed.connect(_on_add_data_pressed.bind("new_int", 0))
	add_rc_float_button.pressed.connect(_on_add_data_pressed.bind("new_float", 0.0))
	add_rc_bool_button.pressed.connect(_on_add_data_pressed.bind("new_bool", false))
	add_rc_string_button.pressed.connect(_on_add_data_pressed.bind("new_string", ""))
	add_dict_button.pressed.connect(_on_add_data_pressed.bind("new_folder", {}))
	race_data_tree.data_changed.connect(_on_data_tree_data_changed)
	
	edit_stat_block_btn.pressed.connect(_on_edit_statblock_pressed)
	edit_skill_set_btn.pressed.connect(_on_edit_skillset_pressed)
	edit_trait_block_btn.pressed.connect(_on_edit_traitblock_pressed)
	
	dom_opt_btn.item_selected.connect(_on_dominant_gene_selected)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	if event is InputEventKey:
		if event.echo or not event.pressed or not event.ctrl_pressed:
			return
		
		var current_focus: Control = get_viewport().gui_get_focus_owner()
		
		if current_focus != null:
			if current_focus is LineEdit:
				if current_focus.is_editing():
					return
			elif current_focus is TextEdit:
				return
		
		if event.keycode == KEY_Z:
			if event.shift_pressed:
				if undo.has_redo():
					var action_name: String = undo.get_action_name(undo.get_current_action() + 1)
					undo.redo()
					NFPluginGameHandler._log_msg(
							"",
							"Redo: " + action_name,
							NFPluginGameHandler._LogLevel.EDITOR)
					_on_something_changed()
			else:
				if undo.has_undo():
					var action_name: String = undo.get_action_name(undo.get_current_action())
					undo.undo()
					NFPluginGameHandler._log_msg(
							"",
							"Undo: " + action_name,
							NFPluginGameHandler._LogLevel.EDITOR)
					_on_something_changed()
			get_viewport().set_input_as_handled()
		if event.keycode == KEY_Y and not event.shift_pressed:
			if undo.has_redo():
				var action_name: String = undo.get_current_action_name()
				undo.redo()
				NFPluginGameHandler._log_msg(
							"",
							"Redo: " + action_name,
							NFPluginGameHandler._LogLevel.EDITOR)
				_on_something_changed()
			get_viewport().set_input_as_handled()


func _on_data_tree_data_changed() -> void:
	if race_data_tree.has_undo():
		undo.create_action("Data Changed")
		undo.add_do_method(_perform_data_action.bind(loaded_species, true))
		undo.add_undo_method(_perform_data_action.bind(loaded_species, false))
		undo.commit_action(false)
	_on_something_changed()


func _perform_data_action(species_id: StringName, is_do: bool) -> void:
	if not races_tree.has_species(species_id):
		return
	
	switch_to_species(species_id)
	
	if is_do:
		race_data_tree.redo()
	else:
		race_data_tree.undo()


func _on_race_name_editing_toggled(is_toggled: bool) -> void:
	if is_toggled:
		return
	
	var old_name: String = race_name_ln_edt.get_meta(&"old_value", "")
	var new_name: String = race_name_ln_edt.text
	
	if new_name == old_name:
		return
	
	race_name_ln_edt.set_meta(&"old_value", new_name)
	undo.create_action("Set Species '%s' Name" % loaded_species)
	undo.add_do_method(_do_set_race_name.bind(loaded_species, new_name))
	undo.add_undo_method(_do_set_race_name.bind(loaded_species, old_name))
	undo.commit_action(false)


func _do_set_race_name(species: StringName, new_name: String) -> void:
	if not races_tree.has_species(species):
		return
	
	switch_to_species(species)
	
	race_name_ln_edt.text = new_name


func _do_set_race_description(species: StringName, new_description: String) -> void:
	if not races_tree.has_species(species):
		return
	
	switch_to_species(species)
	
	race_desc_txt_edt.text = new_description


func _on_desc_text_focus_lost() -> void:
	if not race_desc_txt_edt.editable:
		return
	
	var old_desc: String = race_desc_txt_edt.get_meta(&"old_value")
	var new_desc: String = race_desc_txt_edt.text
	
	if new_desc == old_desc:
		return
	
	race_desc_txt_edt.set_meta(&"old_value", new_desc)
	
	undo.create_action("Set Species '%s' Description" % loaded_species)
	undo.add_do_method(_do_set_race_description.bind(loaded_species, new_desc))
	undo.add_undo_method(_do_set_race_description.bind(loaded_species, old_desc))
	undo.commit_action(false)


func _on_attribute_editing_toggled(is_toggled: bool, attribute: SpinBox) -> void:
	if is_toggled:
		return
	
	var line: LineEdit = attribute.get_line_edit()
	var old_value: float = attribute.get_meta(&"old_value")
	var new_value: float = _parse_value(line.text, attribute.value)
	
	if new_value == old_value:
		return
	
	var id: StringName = attribute.get_parent().get_meta(&"field_id")
	var parent: VBoxContainer = attribute.get_parent().get_parent()
	var type: int = 0
	
	var id_name: String = String(id).capitalize()
	
	attribute.set_meta(&"old_value", new_value)
	
	undo.create_action("Set '%s' %s" % [loaded_species, id_name])
	undo.add_do_method(_do_update_attribute.bind(loaded_species, id, new_value, type))
	undo.add_undo_method(_do_update_attribute.bind(loaded_species, id, old_value, type))
	undo.commit_action(false)


func _do_update_attribute(on_species: StringName, attribute_id: StringName, value: float, attribute_type: int,) -> void:
	if not races_tree.has_species(on_species):
		return
	
	switch_to_species(on_species)
	
	var container: VBoxContainer = race_stats_container if attribute_type == 0 else race_skill_container if attribute_type == 1 else race_traits_container
	
	for field in container.get_children():
		if field.get_meta(&"field_id") != attribute_id:
			continue
		field.get_meta(&"value").set_value_no_signal(value)
		return


func _on_attribute_value_changed(new_value: float, spin: SpinBox) -> void:
	var old_value: float = spin.get_meta(&"old_value")
	
	if new_value == old_value:
		return
	
	var id: StringName = spin.get_parent().get_meta(&"field_id")
	var parent: VBoxContainer = spin.get_parent().get_parent()
	var type: int = 0
	
	if parent == race_stats_container:
		type = 0
	elif parent == race_skill_container:
		type = 1
	else:
		type = 2
	
	var id_name: String = String(id).capitalize()
	
	spin.set_meta(&"old_value", new_value)
	
	undo.create_action("Set '%s' %s" % [loaded_species, id_name])
	undo.add_do_method(_do_update_attribute.bind(loaded_species, id, new_value, type))
	undo.add_undo_method(_do_update_attribute.bind(loaded_species, id, old_value, type))
	undo.commit_action(false)
	
	_on_something_changed()


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
	var submissive: StringName = sub_opt_btn.get_selected_metadata()
	var dominant: StringName = dom_opt_btn.get_selected_metadata()
	var action: String = "Move '%s'" % loaded_species if submissive.is_empty() else "Hybridize '%s'" % loaded_species
	var current_dominant: StringName = races_tree.get_dominant_gene(loaded_species)
	var current_recessive: StringName = races_tree.get_recessive_gene(loaded_species)
	
	undo.create_action(action)
	undo.add_do_method(_do_hybridize_species.bind(loaded_species, dominant, submissive))
	undo.add_undo_method(_do_hybridize_species.bind(loaded_species, current_dominant, current_recessive))
	undo.commit_action()


func _do_hybridize_species(target: StringName, dominant: StringName, recessive: StringName) -> void:
	#if loaded_species != target:
		#if not loaded_species.is_empty():
			#save_current_species()
		#switch_to_species(target)
	
	if recessive.is_empty():
		if races_tree.is_species_hybrid(target):
			races_tree.dehybridize_species(target, dominant)
		else:
			races_tree.set_species_as_subspecies_of(target, dominant)
		hybrid_info_container.visible = false
	else:
		races_tree.hybridize_species(target, dominant, recessive)
	
		hybrid_info_container.visible = true
		hybrid_a.text = dom_opt_btn.get_selected_metadata()
		hybrid_b.text = sub_opt_btn.get_selected_metadata()


func _on_hybridize_cancelled() -> void:
	hybridization_panel.visible = false


func _on_species_dehibridized(species_id: StringName, new_top: StringName, dom: StringName, sub: StringName) -> void:
	undo.create_action("Dehybridize '%s'" % species_id)
	undo.add_do_method(_do_dehibridize_species.bind(species_id, new_top))
	undo.add_undo_method(_undo_dehibridize_species.bind(species_id, dom, sub))
	undo.commit_action(false)
	
	if species_id == loaded_species and hybrid_info_container.visible:
		hybrid_info_container.visible = false


func _do_dehibridize_species(species_id: StringName, move_to: StringName) -> void:
	races_tree.dehybridize_species(species_id, move_to)
	if species_id == loaded_species and hybrid_info_container.visible:
		hybrid_info_container.visible = false


func _undo_dehibridize_species(species_id: StringName, dominant: StringName, submissive: StringName) -> void:
	races_tree.hybridize_species(species_id, dominant, submissive)
	if species_id == loaded_species:
		hybrid_info_container.visible = true
		hybrid_a.text = races_tree.get_dominant_gene(species_id)
		hybrid_b.text = races_tree.get_recessive_gene(species_id)


func reload_resource(first_load: bool = false) -> void:
	var was_null: bool = _species_resource == null
	_species_resource = null
	race_name_ln_edt.text = ""
	race_desc_txt_edt.text = ""
	undo.clear_history()
	race_data_tree.clear_data(false)
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


func _on_create_database_pressed(node: Control) -> void:
	var database_creator: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
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
	var database_creator: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
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
	if race_data_tree.has_undo():
		undo.create_action("Data Changed")
		undo.add_do_method(race_data_tree.redo)
		undo.add_undo_method(race_data_tree.undo)
		undo.commit_action(false)
	_on_something_changed()


func _on_species_id_changed(from: StringName, to: StringName) -> void:
	if from == to:
		return
	
	_species_resource._species[to] = _species_resource._species[from]
	_species_resource._species.erase(from)
	
	if loaded_species == from:
		loaded_species = to
	
	undo.create_action("Set Species ID")
	undo.add_do_method(_do_rename_species.bind(from, to))
	undo.add_undo_method(_do_rename_species.bind(to, from))
	undo.commit_action(false)
	
	_on_race_entries_changed()
	_on_something_changed()


func _do_rename_species(from: StringName, to: StringName) -> void:
	races_tree.set_species_id(from, to)
	_species_resource._species[to] = _species_resource._species[from]
	_species_resource._species.erase(from)
	
	if loaded_species == from:
		loaded_species = to
	_on_race_entries_changed()


func _on_search_species_text_changed(text: String) -> void:
	races_tree.search_species(text.strip_edges())


func _on_species_created(species_id: StringName) -> void:
	if not loaded_species.is_empty():
		save_current_species()
	
	var parent_species: StringName = races_tree.get_dominant_gene(species_id)
	
	_species_resource.create_species(species_id)
	_species_resource.set_species_name(species_id, "New Species")
	if not parent_species.is_empty():
		_species_resource.link_species(species_id, parent_species)
	
	undo.create_action("Create Species '%s'" % species_id)
	undo.add_do_method(_do_create_species.bind(species_id, parent_species))
	undo.add_undo_method(_undo_create_species.bind(species_id))
	undo.commit_action(false)
	
	races_tree.select_species(species_id, false)
	
	load_species(species_id)
	loaded_species = species_id
	
	_on_something_changed()
	_on_race_entries_changed()


func _do_create_species(species_id: StringName, on_species: StringName = &"") -> void:
	_species_resource.create_species(species_id)
	_species_resource.set_species_name(species_id, "New Species")
	if not on_species.is_empty():
		_species_resource.link_species(species_id, on_species)
	races_tree.create_species(species_id, on_species)


func _undo_create_species(species_id: StringName) -> void:
	_species_resource._species.erase(species_id)
	races_tree.erase_species(species_id)
	if loaded_species == species_id:
		race_name_ln_edt.text = ""
		race_desc_txt_edt.text = ""
		race_data_tree.clear_data(false)
		set_ui_enabled(false)
		default_talents()
		loaded_species = &""


func _on_species_selected(species_id: StringName) -> void:
	if loaded_species == species_id:
		return
	
	if not loaded_species.is_empty():
		save_current_species()
	
	load_species(species_id)
	manage_hybrid.disabled = _species_resource._species.size() <= 1
	loaded_species = species_id
	set_ui_enabled(true)


func _on_create_species_pressed() -> void:
	var id_creator: ConfirmationDialog = load("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
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
		
		var species_id: StringName = StringName(result[1])
		
		_species_resource.create_species(species_id)
		_species_resource.set_species_name(species_id, "New Species")
		
		undo.create_action("Create Species '%s'" % species_id)
		undo.add_do_method(_do_create_species.bind(species_id))
		undo.add_undo_method(_undo_create_species.bind(species_id))
		undo.commit_action(false)
		
		races_tree.create_species(species_id)
		races_tree.select_species(species_id, false)
		load_species(species_id)
		loaded_species = species_id
		
		set_ui_enabled(true)
		_on_something_changed()
		_on_race_entries_changed()
		
	id_creator.queue_free()


func _on_erase_species_requested(species: StringName) -> void:
	var dialog := preload("res://addons/nexus_forge/dialogs/confirmation.gd").new()
	dialog.title = "Delete species tree..."
	dialog.dialog_text = "Delete '%s' and all subspecies?" % species if races_tree.has_subspecies(species) else "Delete '%s'?" % species
	dialog.ok_button_text = "Delete"
	dialog.cancel_button_text = "Cancel"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	add_child(dialog)
	dialog.popup_centered()
	
	var delete: bool = await dialog.dialog_finished
	dialog.queue_free()
	
	if not delete:
		return
	
	var species_to_erase: Array[StringName] = races_tree.get_natural_subspecies_of(species)
	var backup: Dictionary[StringName, Dictionary] = {}
	var undo_map: Dictionary[StringName, Dictionary] = races_tree.get_subspecies_map_of(species)
	var parent_species: StringName = races_tree.get_dominant_gene(species)
	
	species_to_erase.append(species)
	for species_id in species_to_erase:
		backup[species_id] = _species_resource._species[species_id].duplicate(true)
	
	undo.create_action("Erase Species '%s'" % species)
	undo.add_do_method(_do_erase_species.bind(species))
	undo.add_undo_method(_undo_erase_species.bind(parent_species, backup, undo_map))
	undo.commit_action()
	_on_something_changed()


func _undo_erase_species(on: StringName, species_data: Dictionary[StringName, Dictionary], tree_map: Dictionary[StringName, Dictionary]) -> void:
	_species_resource._species.merge(species_data.duplicate(true), true)
	races_tree._restore_tree(tree_map, on)
	manage_hybrid.disabled = _species_resource._species.size() <= 1
	_on_race_entries_changed()


func _do_erase_species(species_id: StringName) -> void:
	var species_to_erase: Array[StringName] = races_tree.get_natural_subspecies_of(species_id)
	species_to_erase.append(species_id)
	
	for key in species_to_erase:
		_species_resource._species.erase(key)
	
	races_tree.erase_species(species_id)
	
	if species_to_erase.has(loaded_species):
		race_name_ln_edt.text = ""
		race_desc_txt_edt.text = ""
		race_data_tree.clear_data(false)
		set_ui_enabled(false)
		default_talents()
		loaded_species = &""
	
	manage_hybrid.disabled = _species_resource._species.size() <= 1
	_on_race_entries_changed()


func _on_species_moved(species: StringName, from: StringName, to: StringName) -> void:
	undo.create_action("Move Species '%s'" % species)
	undo.add_do_method(_do_move_species.bind(species, to))
	undo.add_undo_method(_do_move_species.bind(species, from))
	undo.commit_action(false)


func _do_move_species(what: StringName, to: StringName) -> void:
	races_tree.set_species_as_subspecies_of(what, to)


func _on_something_changed(_arg = null) -> void:
	if _unsaved:
		return
	
	_unsaved = true


func _on_race_entries_changed() -> void:
	if signal_change:
		return
	signal_change = true


func _on_value_field_toggled(toggled: bool, check: CheckBox, spin: SpinBox) -> void:
	var id: String = String(check.get_parent().get_meta(&"field_id"))
	spin.editable = toggled
	undo.create_action("%s Toggled" % id.capitalize())
	undo.add_do_method(_do_update_field_toggle.bind(check, spin, toggled))
	undo.add_undo_method(_do_update_field_toggle.bind(check, spin, not toggled))
	undo.commit_action(false)
	spin.editable = toggled
	_on_something_changed()


func _do_update_field_toggle(box: CheckBox, spin: SpinBox, to: bool) -> void:
	box.set_pressed_no_signal(to)
	spin.editable = to


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
	undo.clear_history()
	
	race_data_tree.clear_data(false)
	
	default_talents()
	
	var top_species: Array[StringName] = []
	var subspecies: Dictionary[StringName, Array] = {}
	var hybrid_species: Array[Dictionary] = []
	
	for species_key in _species_resource._species.keys():
		if _species_resource._species[species_key]["parent_dominant"].is_empty():
			top_species.append(species_key)
		else:
			if not subspecies.has(_species_resource._species[species_key]["parent_dominant"]):
				subspecies[_species_resource._species[species_key]["parent_dominant"]] = []
			subspecies[_species_resource._species[species_key]["parent_dominant"]].append(species_key)
		
		if not _species_resource._species[species_key]["parent_recessive"].is_empty():
			hybrid_species.append({
				"dom": _species_resource._species[species_key]["parent_dominant"],
				"sub": _species_resource._species[species_key]["parent_recessive"],
				"hybrid": species_key})
		
		var undo_dict: Dictionary[String, UndoRedo] = {
			"species": UndoRedo.new(),
			"data": UndoRedo.new()}
		
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
	var species_name: String = _species_resource.get_species_name(species_id)
	var species_desc: String = _species_resource.get_species_description(species_id)
	race_name_ln_edt.text = species_name
	race_name_ln_edt.set_meta(&"old_value", species_name)
	
	race_desc_txt_edt.text = species_desc
	race_desc_txt_edt.set_meta(&"old_value", species_desc)
	race_data_tree.clear_data(false)
	
	if races_tree.is_species_hybrid(species_id):
		hybrid_info_container.visible = true
		hybrid_a.text = races_tree.get_dominant_gene(species_id)
		hybrid_b.text = races_tree.get_recessive_gene(species_id)
	else:
		hybrid_info_container.visible = false
	
	for data_key in _species_resource.species_data_keys(species_id):
		race_data_tree.add_data(data_key, _species_resource.get_species_data(species_id, data_key), true)
	
	for stat in race_stats_container.get_children():
		var stat_id: StringName = stat.get_meta(&"field_id")
		var spn: SpinBox = stat.get_child(1)
		var chk: CheckBox = stat.get_child(0)
		if _species_resource.species_has_stat(species_id, stat_id):
			var stat_val: float = _species_resource.get_species_stat_value(species_id, stat_id)
			chk.set_pressed_no_signal(true)
			spn.editable = true
			spn.set_value_no_signal(_species_resource.get_species_stat_value(species_id, stat_id))
			spn.set_meta(&"old_value", stat_val)
		else:
			var stat_val: float = stat.get_meta(&"default_value", 0.0)
			chk.set_pressed_no_signal(false)
			spn.editable = false
			spn.set_value_no_signal(stat.get_meta(&"default_value", 0.0))
			spn.set_meta(&"old_value", stat_val)
	
	for skill in race_skill_container.get_children():
		var skill_id: StringName = skill.get_meta(&"field_id")
		var spn: SpinBox = skill.get_child(1)
		var chk: CheckBox = skill.get_child(0)
		var new_value: int = 0
		
		if _species_resource.species_has_skill(species_id, skill_id):
			chk.set_pressed_no_signal(true)
			spn.editable = true
		else:
			chk.set_pressed_no_signal(false)
			spn.editable = false
			new_value = skill.get_meta(&"default_value", 0)
		
		spn.set_value_no_signal(new_value)
		spn.set_meta(&"old_value", new_value)
	
	for trait_child in race_traits_container.get_children():
		var trait_id: StringName = trait_child.get_meta(&"field_id")
		var spn: SpinBox = trait_child.get_child(1)
		var chk: CheckBox = trait_child.get_child(0)
		var new_val: int = 0
		
		if _species_resource.species_has_trait(species_id, trait_id):
			chk.set_pressed_no_signal(true)
			spn.editable = true
			new_val = _species_resource.get_species_trait_value(species_id, trait_id)
		else:
			chk.set_pressed_no_signal(false)
			spn.editable = false
			new_val = trait_child.get_meta(&"default_value", 0)
		
		spn.set_meta(&"old_value", new_val)
		spn.set_value_no_signal(new_val)


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
		spn.set_value_no_signal(1.0)
	
	for skill in race_skill_container.get_children():
		var spn: SpinBox = skill.get_child(1)
		var chk: CheckBox = skill.get_child(0)
		chk.set_pressed_no_signal(false)
		spn.editable = false
		spn.set_value_no_signal(skill.get_meta(&"default_value", 0.0))
	
	for trait_child in race_traits_container.get_children():
		var spn: SpinBox = trait_child.get_child(1)
		var chk: CheckBox = trait_child.get_child(0)
		chk.set_pressed_no_signal(false)
		spn.editable = false
		spn.set_value_no_signal(trait_child.get_meta(&"default_value", 0.0))


func set_ui_enabled(enabled: bool) -> void:
	_gui_enabled = enabled
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
		child.get_child(1).editable = child.get_child(0).button_pressed and enabled
	
	for child in race_skill_container.get_children():
		child.get_child(0).disabled = disabled
		child.get_child(1).editable = child.get_child(0).button_pressed and enabled
	
	for child in race_traits_container.get_children():
		child.get_child(0).disabled = disabled
		child.get_child(1).editable = child.get_child(0).button_pressed and enabled


func update_talent_nodes() -> void:
	var skill_set: SkillSet = SkillSet.new()
	
	var trait_block: TraitBlock = TraitBlock.new()
	
	var stat_block: StatBlock = StatBlock.new()
	
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
			_set_focus_for_stat(stat_map[stat_id])
			stat_map.erase(stat_id)
		else:
			create_stat(stat_id, stat_default, stat_data[stat_id])
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
			_set_focus_for_skill(skill_map[skill_id])
			skill_map.erase(skill_id)
		else:
			create_skill(skill_id, skill_set.get(skill_id))
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
			_set_focus_for_trait(trait_map[trait_id])
			trait_map.erase(trait_id)
		else:
			create_trait(trait_id, trait_block.get(trait_id))
	for remaining_trait in trait_map.keys():
		trait_map[remaining_trait].queue_free()
	
	if loaded_species != &"":
		_on_something_changed()


func value_field_active(field: HBoxContainer) -> bool:
	return field.get_child(0).button_pressed


func create_stat(stat_id: StringName, default_value: float, type: int) -> void:
	var field: HBoxContainer = _create_value_field(stat_id, default_value, 1.0 if type == TYPE_INT else 0.01)
	field.get_child(0).disabled = not _gui_enabled
	field.get_child(1).editable = false
	race_stats_container.add_child(field)
	_set_focus_for_stat(field)


func create_skill(skill_id: StringName, default_value: int) -> void:
	var field: HBoxContainer = _create_value_field(skill_id, default_value, 1.0)
	field.get_child(0).disabled = not _gui_enabled
	field.get_child(1).editable = false
	race_skill_container.add_child(field)
	_set_focus_for_skill(field)


func create_trait(skill_id: StringName, default_value: int) -> void:
	var field: HBoxContainer = _create_value_field(skill_id, default_value, 1.0)
	field.get_child(0).disabled = not _gui_enabled
	field.get_child(1).editable = false
	race_traits_container.add_child(field)
	_set_focus_for_trait(field)


func _create_value_field(field_id: StringName, default_value: float, step: float) -> HBoxContainer:
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
	value.step = step
	
	value.value = default_value
	value.editable = false
	value.custom_minimum_size.y = 32
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.size_flags_stretch_ratio = 3.0
	
	new_field.add_child(activatable)
	new_field.add_child(value)
	
	new_field.set_meta(&"field_id", field_id)
	new_field.set_meta(&"default_value", default_value)
	new_field.set_meta(&"value", value)
	
	activatable.toggled.connect(_on_value_field_toggled.bind(activatable, value))
	value.value_changed.connect(_on_attribute_value_changed.bind(value))
	value.get_line_edit().editing_toggled.connect(_on_attribute_editing_toggled.bind(value))
	
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


func _parse_value(value: String, fallback: float) -> float:
	var error: int = expr.parse(value)

	if error != OK:
		return fallback
		
	var result: Variant = expr.execute([], null, false)
	
	if expr.has_execute_failed():
		return fallback
	
	var type: int = typeof(result)
	if type == TYPE_INT or type == TYPE_FLOAT:
		return result
	return fallback


func _set_focus_for_stat(stat: HBoxContainer) -> void:
	var spin: SpinBox = stat.get_meta(&"value")
	var line: LineEdit = spin.get_line_edit()
	var current_stats: int = race_stats_container.get_child_count()
	var stat_idx: int = stat.get_index()
	
	if 0 < stat_idx:
		var prev_stat: HBoxContainer = race_stats_container.get_child(stat_idx - 1)
		var prev_line: LineEdit = prev_stat.get_meta(&"value").get_line_edit()
		prev_line.focus_next = line.get_path()
		line.focus_previous = prev_line.get_path()
	else:
		line.focus_previous = ^""
	
	if stat_idx < current_stats - 1: # If it is not the last stat
		var next_stat: HBoxContainer = race_stats_container.get_child(stat_idx + 1)
		var next_line: LineEdit = next_stat.get_meta(&"value").get_line_edit()
		next_line.focus_previous = line.get_path()
		line.focus_next = next_line.get_path()
	elif 0 < race_skill_container.get_child_count():
		var next_skill: HBoxContainer = race_skill_container.get_child(0)
		var skill_line: LineEdit = next_skill.get_meta(&"value").get_line_edit()
		skill_line.focus_previous = line.get_path()
		line.focus_next = skill_line.get_path()
	elif 0 < race_traits_container.get_child_count():
		var next_trait: HBoxContainer = race_traits_container.get_child(0)
		var trait_line: LineEdit = next_trait.get_meta(&"value").get_line_edit()
		trait_line.focus_previous = line.get_path()
		line.focus_next = trait_line.get_path()
	else:
		line.focus_next = ^""


func _set_focus_for_skill(skill: HBoxContainer) -> void:
	var spin: SpinBox = skill.get_meta(&"value")
	var line: LineEdit = spin.get_line_edit()
	var current_skills: int = race_skill_container.get_child_count()
	var skill_idx: int = skill.get_index()
	
	if skill_idx < 0:
		var prev_skill: HBoxContainer = race_skill_container.get_child(skill_idx - 1)
		var prev_line: LineEdit = prev_skill.get_meta(&"value").get_line_edit()
		prev_line.focus_next = line.get_path()
		line.focus_previous = prev_line.get_path()
	elif 0 < race_stats_container.get_child_count():
		var prev_stat: HBoxContainer = race_stats_container.get_child(0)
		var prev_line: LineEdit = prev_stat.get_meta(&"value").get_line_edit()
		line.focus_previous = prev_line.get_path()
		prev_line.focus_next = line.get_path()
	else:
		line.focus_previous = ^""
	
	if skill_idx < current_skills - 1:
		var next_skill: HBoxContainer = race_skill_container.get_child(skill_idx + 1)
		var next_line: LineEdit = next_skill.get_meta(&"value").get_line_edit()
		line.focus_next = next_line.get_path()
		next_line.focus_previous = line.get_path()
	elif 0 < race_traits_container.get_child_count():
		var next_trait: HBoxContainer = race_traits_container.get_child(skill_idx + 1)
		var next_line: LineEdit = next_trait.get_meta(&"value").get_line_edit()
		line.focus_next = next_line.get_path()
		next_line.focus_previous = line.get_path()
	else:
		line.focus_next = ^""


func _set_focus_for_trait(trait_entry: HBoxContainer) -> void:
	var spin: SpinBox = trait_entry.get_meta(&"value")
	var line: LineEdit = spin.get_line_edit()
	var current_traits: int = race_traits_container.get_child_count()
	var trait_idx: int = trait_entry.get_index()
	
	if trait_idx < current_traits - 1:
		var next_trait: HBoxContainer = race_traits_container.get_child(trait_idx + 1)
		var next_line: LineEdit = next_trait.get_meta(&"value").get_line_edit()
		line.focus_next = next_line.get_path()
		next_line.focus_previous = line.get_path()
	else:
		line.focus_next = ^""
	
	if 0 < trait_idx:
		var prev_trait: HBoxContainer = race_traits_container.get_child(trait_idx - 1)
		var prev_line: LineEdit = prev_trait.get_meta(&"value").get_line_edit()
		prev_line.focus_next = line.get_path()
		line.focus_previous = prev_line.get_path()
	elif 0 < race_skill_container.get_child_count():
		var prev_skill: HBoxContainer = race_skill_container.get_child(-1)
		var prev_line: LineEdit = prev_skill.get_meta(&"value").get_line_edit()
		prev_line.focus_next = line.get_path()
		line.focus_previous = prev_line.get_path()
	elif 0 < race_stats_container.get_child_count():
		var prev_stat: HBoxContainer = race_stats_container.get_child(-1)
		var prev_line: LineEdit = prev_stat.get_meta(&"value").get_line_edit()
		prev_line.focus_next = line.get_path()
		line.focus_previous = prev_line.get_path()
	else:
		line.focus_previous = ^""


func switch_to_species(species_id: StringName) -> void:
	if loaded_species == species_id or not races_tree.has_species(species_id):
		return
	
	if not loaded_species.is_empty():
		save_current_species()
	
	races_tree.select_species(species_id, false)
	load_species(species_id)
	
	manage_hybrid.disabled = _species_resource._species.size() <= 1
	loaded_species = species_id
	set_ui_enabled(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(undo):
			undo.clear_history()
			undo.free()
			undo = null
