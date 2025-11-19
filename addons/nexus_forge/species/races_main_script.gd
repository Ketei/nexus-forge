@tool
extends PanelContainer


signal species_loaded
const LineEditConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd")

var _unsaved: bool = false
var _species_resource: SpeciesCatalog = null
var listen_select: bool = true
var loaded_species: StringName = &""
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
@onready var race_custom_data_search_line: LineEdit = $RacesContainer/RacesBasicSplit/BasicDataContainer/CustomDataContainer/RaceCustomDataSearchLine
@onready var race_data_tree: Tree = $RacesContainer/RacesBasicSplit/BasicDataContainer/CustomDataContainer/RaceDataTree
@onready var race_stats_container: VBoxContainer = $RacesContainer/StatTraitSplit/ValuesContainer/StatVBox/StatScroll/RaceStatsContainer
@onready var race_skill_container: VBoxContainer = $RacesContainer/StatTraitSplit/ValuesContainer/SkillVBox/SkillScroll/RaceSkillContainer
@onready var race_traits_container: VBoxContainer = $RacesContainer/StatTraitSplit/TraitsContainer/ScrollContainer/RaceTraitsContainer



func _ready() -> void:
	if Engine.is_editor_hint() and get_tree().edited_scene_root == self:
		return
	
	race_custom_data_search_line.right_icon = get_theme_icon("Search", "EditorIcons")
	
	var res_path: String = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("species"), "")
	
	if res_path != "" and FileAccess.file_exists(res_path):
		var preload_res: Resource = load(res_path)
		if preload_res is SpeciesCatalog:
			_species_resource = preload_res
	
	if _species_resource == null:
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
	
	update_talent_nodes()
	set_ui_enabled(false)
	
	search_race_ln_edt.text_changed.connect(_on_search_species_text_changed)
	new_race_btn.pressed.connect(_on_create_species_pressed)
	
	races_tree.species_created.connect(_on_species_created, CONNECT_DEFERRED)
	races_tree.species_selected.connect(_on_species_selected, CONNECT_DEFERRED)
	races_tree.species_erased.connect(_on_species_erased, CONNECT_DEFERRED)
	races_tree.species_id_changed.connect(_on_species_id_changed, CONNECT_DEFERRED)
	race_name_ln_edt.text_changed.connect(_on_something_changed)
	race_desc_txt_edt.text_changed.connect(_on_something_changed)
	
	add_rc_int_button.pressed.connect(_on_add_data_pressed.bind("new_int", 0))
	add_rc_float_button.pressed.connect(_on_add_data_pressed.bind("new_float", 0.0))
	add_rc_bool_button.pressed.connect(_on_add_data_pressed.bind("new_bool", false))
	add_rc_string_button.pressed.connect(_on_add_data_pressed.bind("new_string", ""))
	race_data_tree.data_changed.connect(_on_something_changed)


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
				EditorNFPlugin.get_project_settings_path("species"),
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
			EditorNFPlugin.get_project_settings_path("species"),
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
					EditorNFPlugin.get_project_settings_path("species"),
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
	print("Changed")
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
	var species_tree: Dictionary[StringName, Dictionary] = _species_resource.get_species_map()
	buid_species_map(species_tree)
	species_loaded.emit()


func buid_species_map(map: Dictionary, _on: TreeItem = races_tree.get_root()) -> void:
	for top_species in map.keys():
		var parent_species: TreeItem = races_tree.add_species(top_species, false, _on)
		buid_species_map(map[top_species], parent_species)


func load_species(species_id: StringName) -> void:
	race_name_ln_edt.text = _species_resource.get_species_name(species_id)
	race_desc_txt_edt.text = _species_resource.get_species_description(species_id)
	race_data_tree.clear_data()
	
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
			spn.set_value_no_signal(1.0)
	
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
			spn.value = 0.0
	
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
			spn.value = 0.0


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
	
	for child in race_stats_container.get_children():
		child.get_child(0).disabled = disabled
	
	for child in race_skill_container.get_children():
		child.get_child(0).disabled = disabled
	
	for child in race_traits_container.get_children():
		child.get_child(0).disabled = disabled


func update_talent_nodes() -> void:
	var skill_set: SkillSet = SkillSet.new()
	
	var trait_block: TraitBlock = TraitBlock.new()
	
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
		if stat_map.has(stat_id):
			race_stats_container.add_child(stat_map[stat_id])
			if stat_data[stat_id] != stat_map[stat_id].get_meta(&"type"):
				stat_map[stat_id].get_meta(&"value").step = 1.0 if stat_data[stat_id] == TYPE_INT else 0.01
			stat_map.erase(stat_id)
		else:
			var stat = create_value_field(stat_id, stat_data[stat_id], true)
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


func create_value_field(field_id: StringName, default_value: int, is_type: bool = false) -> HBoxContainer:
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
	
	if is_type:
		if default_value == TYPE_INT:
			value.step = 1.0
		else:
			value.step = 0.01
		value.value = 0.0
		new_field.set_meta(&"type", default_value)
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
	if _species_resource == null:
		return
	if not loaded_species.is_empty():
		save_current_species()
	var species_data: Dictionary = races_tree.get_species_tree()
	
	# We clear the top species link, as they are a subspecies of nothing.
	for top_species in species_data.keys():
		_species_resource.link_species(top_species, &"")
	
	_set_species_tree(species_data)
	ResourceSaver.save(_species_resource)
	_unsaved = false


func _set_species_tree(tree: Dictionary) -> void:
	for parent_species in tree.keys():
		for subspecies in tree[parent_species]:
			_species_resource.link_species(subspecies, parent_species)
			_set_species_tree(tree[parent_species])
