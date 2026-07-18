@tool
extends Control


var recipes_link: EditorItemRecipeLink = EditorItemRecipeLink.new()
var current_tab: int = 0
var tool_count: int = 0
@onready var tool_container: PanelContainer = $MainContainer/ToolScroll/ToolContainer
@onready var tool_tab_bar: TabBar = $MainContainer/ToolTabBar
@onready var splash_texture: TextureRect = $MainContainer/ToolScroll/ToolContainer/NexusForge/SplashPanel/SplashTexture
#@onready var reload_image_btn: Button = $MainContainer/ToolContainer/NexusForge/SplashPanel/SplashTexture/ReloadImageBtn
# ----- Tools -----
var discourse: PanelContainer = null
var variables: PanelContainer = null
var characters: PanelContainer = null
var species: PanelContainer = null
var talents: PanelContainer = null
var items: PanelContainer = null
var recipes: PanelContainer = null
var quests: PanelContainer = null
var phrase_maps: PanelContainer = null
@onready var nexus_forge: Control = $MainContainer/ToolScroll/ToolContainer/NexusForge
# -----------------


func _ready() -> void:
	set_process_input(false)


func ready_plugin(use_discourse: bool, use_characters: bool, use_species: bool, use_stats: bool, use_skills: bool, use_traits: bool, use_items: bool, use_currencies: bool, use_recipes: bool, use_quests: bool, use_phrases: bool, discourse_base_lang: String) -> void:
	set_process_input(true)
	
	variables = load("res://addons/nexus_forge/variables/variables_main.tscn").instantiate()
	
	if use_discourse:
		discourse = load("res://addons/nexus_forge/discourse/discourse_main_scene.tscn").instantiate()
	if use_characters:
		characters = load("res://addons/nexus_forge/characters/new_characters.tscn").instantiate()
	if use_species:
		species = load("res://addons/nexus_forge/species/species_main.tscn").instantiate()
	if use_stats or use_skills or use_traits:
		talents = load("res://addons/nexus_forge/talents/talents_main.tscn").instantiate()
	if use_items or use_currencies:
		items = load("res://addons/nexus_forge/depot/depot_scene.tscn").instantiate()
	if use_recipes:
		recipes = load("res://addons/nexus_forge/recipes/recipes_scene.tscn").instantiate()
	if use_quests:
		quests = load("res://addons/nexus_forge/quests/new_quests.tscn").instantiate()
	if use_phrases:
		phrase_maps = load("res://addons/nexus_forge/phrases/localization_resources.tscn").instantiate()
	
	if discourse != null:
		tool_container.add_child(discourse)
		discourse.code_editor_variables_requested.connect(_on_discourse_code_editor_variables_requested)
		tool_tab_bar.add_tab("Discourse", load("res://addons/nexus_forge/icons/speech_bubble.svg"))
	tool_container.add_child(variables)
	tool_tab_bar.add_tab("Blackboard", load("res://addons/nexus_forge/icons/variable_icon.svg"))
	if characters != null:
		tool_container.add_child(characters)
		tool_tab_bar.add_tab("Characters", load("res://addons/nexus_forge/icons/character_icon.svg"))
	if species != null:
		tool_container.add_child(species)
		tool_tab_bar.add_tab("Species", load("res://addons/nexus_forge/icons/dna.svg"))
	if talents != null:
		tool_container.add_child(talents)
		tool_tab_bar.add_tab("Talents", load("res://addons/nexus_forge/icons/star.svg"))
	if items != null:
		tool_container.add_child(items)
		tool_tab_bar.add_tab("Items", load("res://addons/nexus_forge/icons/chest_full.svg"))
	if recipes != null:
		tool_container.add_child(recipes)
		tool_tab_bar.add_tab("Recipes", load("res://addons/nexus_forge/icons/bluepring_fill.svg"))
	if quests != null:
		tool_container.add_child(quests)
		tool_tab_bar.add_tab("Quests", load("res://addons/nexus_forge/icons/scroll.svg"))
	if phrase_maps != null:
		tool_container.add_child(phrase_maps)
		phrase_maps.code_editor_variables_requested.connect(_on_phrase_maps_code_editor_variables_requested)
		tool_tab_bar.add_tab("Phrase Maps", load("res://addons/nexus_forge/icons/brackets_speech.svg"))
	
	if discourse != null:
		discourse.ready_plugin(discourse_base_lang)
	variables.ready_plugin()
	if characters != null:
		characters.ready_plugin()
	if species != null:
		species.ready_plugin()
	if talents != null:
		talents.ready_plugin(use_stats, use_skills, use_traits)
	if items != null:
		items.ready_plugin(use_items, use_currencies)
	if recipes != null:
		recipes.ready_plugin()
	if quests != null:
		quests.ready_plugin()
	if phrase_maps != null:
		phrase_maps.ready_plugin()
	
	tool_count = tool_container.get_child_count()
	
	tool_tab_bar.set_tab_title(0, "")
	
	go_to_tab(0)
	
	if recipes != null:
		if recipes.recipes_resource != null:
			recipes_link.recipes = recipes.recipes_resource
		recipes.recipes_loaded.connect(_on_recipes_loaded)
		recipes_link.item_created.connect(recipes.add_item)
		recipes_link.item_renamed.connect(recipes.change_item_name)
		recipes_link.item_id_changed.connect(recipes.change_item_id)
		recipes_link.item_erased.connect(recipes._on_item_erased)
	
	if items != null:
		items.items_container.item_link = recipes_link
		items.items_loaded.connect(_on_items_loaded)
	
	if characters != null:
		characters.import_species_data_pressed.connect(_on_import_species_data_pressed)
	
	if species != null:
		species.species_loaded.connect(_on_species_loaded)
	
	tool_tab_bar.tab_changed.connect(_on_tab_changed)


func _on_discourse_code_editor_variables_requested(path: String) -> void:
	discourse.set_text_code_editor_variable_paths(
			_get_variables_for(path))


func _on_phrase_maps_code_editor_variables_requested(path: String) -> void:
	phrase_maps.set_text_code_editor_variable_paths(
			_get_variables_for(path))


func _get_variables_for(path: String) -> Array[Dictionary]:
	var paths: Array[Dictionary] = [] # is_folder, path
	
	if variables._variables_resource == null:
		return paths
	
	var data: BlackboardData = variables._variables_resource
	
	for folder_path in data.folders():
		if folder_path.begins_with(path):
			paths.append({"is_folder": true, "path": folder_path})
	
	for variable in data.variables(path):
		paths.append({"is_folder": false, "path": path.path_join(variable)})
	
	paths.sort_custom(
		func(a:Dictionary, b:Dictionary):
			var distance_a: float = StringUtils.levenshtein_distance(a["path"], path)
			var distance_b: float = StringUtils.levenshtein_distance(b["path"], path)
			return distance_a < distance_b)
	
	return paths


func _on_species_loaded() -> void:
	if characters != null and species != null:
		characters.update_species_data(species._species_resource)


func _on_import_species_data_pressed() -> void:
	if species == null or characters == null or species._species_resource == null:
		return

	var confirmation_dialog: ConfirmationDialog = load("res://addons/nexus_forge/characters/import_stat_data_cdialog.gd").new()
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()
	
	var use_inheritance : int = await confirmation_dialog.dialog_finished
	
	if use_inheritance == 0:
		confirmation_dialog.queue_free()
		return
	
	if not species.loaded_species.is_empty():
		species.save_current_species()
	
	characters.import_species_data(species._species_resource, use_inheritance == 1)
	
	confirmation_dialog.queue_free()


func _on_items_loaded() -> void:
	if recipes != null:
		recipes.reload_items(recipes_link.items)


func _on_recipes_loaded() -> void:
	if recipes != null:
		recipes_link.recipes = recipes.recipes_resource


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		if not event.is_pressed() or event.is_echo():
			return
		if event.keycode == KEY_TAB:
			if event.ctrl_pressed:
				if  event.shift_pressed:
					tool_tab_bar.current_tab = posmod(tool_tab_bar.current_tab - 1, tool_count)
				else:
					tool_tab_bar.current_tab = posmod(tool_tab_bar.current_tab + 1, tool_count)
				get_viewport().set_input_as_handled()
		if event.keycode == KEY_W:
			if event.ctrl_pressed:
				if discourse != null and discourse.visible:
					discourse.close_active_conversation()
					get_viewport().set_input_as_handled()
				elif characters != null and characters.visible:
					characters.close_active_character()
					get_viewport().set_input_as_handled()
				elif phrase_maps != null and phrase_maps.visible:
					phrase_maps.close_active_map()
					get_viewport().set_input_as_handled()


func _on_tab_changed(tab: int) -> void:
	if species != null and current_tab == species.get_index():
		if species.signal_change:
			species.signal_change = false
			if characters != null:
				characters.update_species_data(species._species_resource)
	
	var idx: int = -1
	for node in tool_container.get_children():
		idx += 1
		node.visible = idx == tab
	current_tab = tab


func save_layouts() -> void:
	if discourse != null:
		discourse.save_layouts()
	variables.save_layout()


func go_to_tab(tab: int) -> void:
	tab = mini(tab, tool_tab_bar.tab_count - 1)
	tool_tab_bar.current_tab = tab
	_on_tab_changed(tab)


func handle_resource(resource: Resource) -> void:
	if resource is EditorDiscourseDialog:
		if discourse == null:
			NFPluginGameHandler._log_msg(
					"editor",
					"Dialogs are disabled. Can't edit resource.",
					NFPluginGameHandler._LogLevel.INFO)
		else:
			go_to_tab(discourse.get_index())
		discourse.plugin_file_selected(resource)
	elif resource is CharacterSheet:
		if characters == null:
			NFPluginGameHandler._log_msg(
					"editor",
					"Characters are disabled. Can't edit resource.",
					NFPluginGameHandler._LogLevel.INFO)
		else:
			go_to_tab(characters.get_index())
			characters.plugin_open_resource(resource)
	elif resource is PhraseMap:
		if PhraseMap == null:
			NFPluginGameHandler._log_msg(
					"editor",
					"Phrase Maps are disabled. Can't edit resource.",
					NFPluginGameHandler._LogLevel.INFO)
		else:
			go_to_tab(phrase_maps.get_index())
			phrase_maps.plugin_open_resource(resource)
	elif resource is Quest:
		if discourse == null:
			NFPluginGameHandler._log_msg(
					"editor",
					"Quests are disabled. Can't edit resource.",
					NFPluginGameHandler._LogLevel.INFO)
		else:
			go_to_tab(quests.get_index())
			quests.plugin_handle_resource(resource)
	else:
		if resource == null:
			NFPluginGameHandler._log_msg(
				"editor",
				"Tried to open a null resource. This shouldn't have happened",
				NFPluginGameHandler._LogLevel.WARNING)
		else:
			NFPluginGameHandler._log_msg(
				"editor",
				"Tried to open an invalid resource: '%s'. This shouldn't have happened." % resource.resource_path,
				NFPluginGameHandler._LogLevel.WARNING)


func has_unsaved_changes() -> bool:
	var discourse_unsaved: bool = discourse.has_unsaved_files() if discourse != null else false
	var characters_unsaved: bool = characters.has_unsaved_files() if characters != null else false
	var species_unsaved: bool = species._unsaved if species != null else false
	var talents_unsaved: bool = talents.has_unsaved_changes() if talents != null else false
	var items_unsaved: bool = items.has_unsaved_changes() if items != null else false
	var recipes_unsaved: bool = recipes._unsaved if recipes != null else false
	var quests_unsaved: bool = quests.has_unsaved_files() if quests != null else false
	var phrases_unsaved: bool = phrase_maps.has_unsaved_files() if phrase_maps != null else false
	
	return discourse_unsaved or variables._unsaved or characters_unsaved or species_unsaved or talents_unsaved or items_unsaved or recipes_unsaved or quests_unsaved or phrases_unsaved


func save_resources() -> void:
	if discourse != null and discourse.has_unsaved_files():
		discourse.save_all_dialogs()
	if variables.has_unsaved_changes():
		variables.save()
	if characters != null and characters.has_unsaved_files():
		characters.save()
	if species != null and species._unsaved:
		species.save()
	if talents != null and talents.has_unsaved_changes():
		talents.save()
	if items != null and items.has_unsaved_changes():
		items.save()
	if recipes != null and recipes._unsaved:
		recipes.save()
	if quests != null and quests.has_unsaved_files():
		quests.save_resource()
	if phrase_maps != null and phrase_maps.has_unsaved_files():
		phrase_maps.save_all()


func reload_stats() -> void:
	if characters != null:
		characters.update_talent_nodes()
	if species != null:
		species.update_talent_nodes()


func reload_traits() -> void:
	if characters != null:
		characters.update_talent_nodes()
	if species != null:
		species.update_talent_nodes()
	if talents != null:
		talents.reload_traits()


func reload_skills() -> void:
	if characters != null:
		characters.update_talent_nodes()
	if species != null:
		species.update_talent_nodes()
	if talents != null:
		talents.reload_skills()


func reload_character_sheet() -> void:
	if characters != null:
		characters.update_genders()


func reload_items() -> void:
	if items != null:
		items.items_container.reload_fields()


func reload_quest_data_types() -> void:
	if quests != null:
		quests.update_type_button(1)


func reload_quest_stage_types() -> void:
	if quests != null:
		quests.update_type_button(2)


func reload_quest_objective_types() -> void:
	if quests != null:
		quests.update_type_button(3)


func reload_discourse_api() -> void:
	if discourse != null:
		discourse.reload_signals.call_deferred()
		discourse.reload_methods.call_deferred()
