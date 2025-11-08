@tool
extends Control


var recipes_link: EditorItemRecipeLink = EditorItemRecipeLink.new()
var current_tab: int = 0
@onready var tool_count: int = $MainContainer/ToolContainer.get_child_count()
@onready var tool_tab_bar: TabBar = $MainContainer/ToolTabBar
@onready var splash_texture: TextureRect = $MainContainer/ToolContainer/NexusForge/SplashPanel/SplashTexture
#@onready var reload_image_btn: Button = $MainContainer/ToolContainer/NexusForge/SplashPanel/SplashTexture/ReloadImageBtn
# ----- Tools -----
@onready var nexus_forge: Control = $MainContainer/ToolContainer/NexusForge
@onready var discourse: PanelContainer = $MainContainer/ToolContainer/Discourse
@onready var variables: PanelContainer = $MainContainer/ToolContainer/Variables
@onready var characters: PanelContainer = $MainContainer/ToolContainer/Characters
@onready var species: PanelContainer = $MainContainer/ToolContainer/Species
@onready var talents: PanelContainer = $MainContainer/ToolContainer/Talents
@onready var items: PanelContainer = $MainContainer/ToolContainer/Items
@onready var recipes: PanelContainer = $MainContainer/ToolContainer/Recipes
@onready var quests: PanelContainer = $MainContainer/ToolContainer/Quests
@onready var phrase_maps: PanelContainer = $MainContainer/ToolContainer/PhraseMaps

# -----------------


func _ready() -> void:
	if Engine.is_editor_hint() and get_tree().edited_scene_root == self:
		set_process_input(false)
		return
	
	tool_tab_bar.set_tab_title(0, "")
	tool_tab_bar.set_tab_icon(0, load("res://addons/nexus_forge/icons/plugin_icon.svg"))
	
	go_to_tab(0)
	
	if recipes.recipes_resource != null:
		recipes_link.recipes = recipes.recipes_resource
	
	items.items_container.item_link = recipes_link
	
	recipes.recipes_loaded.connect(_on_recipes_loaded)
	recipes_link.item_created.connect(recipes.add_item)
	recipes_link.item_renamed.connect(recipes.change_item_name)
	recipes_link.item_id_changed.connect(recipes.change_item_id)
	recipes_link.item_erased.connect(recipes._on_item_erased)
	items.items_loaded.connect(_on_items_loaded)
	characters.import_species_data_pressed.connect(_on_import_species_data_pressed)
	tool_tab_bar.tab_changed.connect(_on_tab_changed)


func _on_import_species_data_pressed() -> void:
	if species._species_resource != null:
		characters.import_species_data(species._species_resource)


func _on_items_loaded() -> void:
	recipes.reload_items(recipes_link.items)


func _on_recipes_loaded() -> void:
	recipes_link.recipes = recipes.recipes_resource


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		if event.keycode == KEY_TAB and event.is_pressed() and not event.is_echo():
			if event.ctrl_pressed:
				if  event.shift_pressed:
					tool_tab_bar.current_tab = posmod(tool_tab_bar.current_tab - 1, tool_count)
				else:
					tool_tab_bar.current_tab = posmod(tool_tab_bar.current_tab + 1, tool_count)
				get_viewport().set_input_as_handled()


func _on_tab_changed(tab: int) -> void:
	if current_tab == species.get_index():
		if species.signal_change:
			species.signal_change = false
			characters.update_species_data(species._species_resource)
	nexus_forge.visible = tab == nexus_forge.get_index()
	discourse.visible = tab == discourse.get_index()
	variables.visible = tab == variables.get_index()
	characters.visible = tab == characters.get_index()
	species.visible = tab == species.get_index()
	talents.visible = tab == talents.get_index()
	items.visible = tab == items.get_index()
	recipes.visible = tab == recipes.get_index()
	quests.visible = tab == quests.get_index()
	phrase_maps.visible = tab == phrase_maps.get_index()
	current_tab = tab


func go_to_tab(tab: int) -> void:
	tool_tab_bar.current_tab = tab
	_on_tab_changed(tab)


func handle_resource(resource: Resource) -> void:
	if resource is EditorDiscourseDialog:
		go_to_tab(discourse.get_index())
		discourse.plugin_file_selected(resource)
	elif resource is CharacterSheet:
		go_to_tab(characters.get_index())
		characters.plugin_open_resource(resource)
	elif resource is PhraseMap:
		go_to_tab(phrase_maps.get_index())
		phrase_maps.plugin_open_resource(resource)
	else:
		if resource == null:
			print("This is null for some reason")
		else:
			printerr("[NexusForge] MainScene: Invalid resource opened: " + resource.resource_path)


func has_unsaved_changes() -> bool:
	return discourse.has_unsaved_files() or variables._unsaved or characters.has_unsaved_files() or species._unsaved or talents._unsaved or items._unsaved or recipes._unsaved or quests._unsaved or phrase_maps.has_unsaved_files()


func save_resources() -> void:
	if discourse.has_unsaved_files():
		discourse.save_all_dialogs()
	if variables._unsaved:
		variables.save()
	if characters.has_unsaved_files():
		characters.save()
	if species._unsaved:
		species.save()
	if talents._unsaved:
		talents.save()
	if items._unsaved:
		items.save()
	if recipes._unsaved:
		recipes.save()
	if quests._unsaved:
		quests.save()
	if phrase_maps.has_unsaved_files():
		phrase_maps.save_all()


func reload_stats() -> void:
	characters.update_talent_nodes() # 
	species.update_talent_nodes()#


func reload_traits() -> void:
	characters.update_talent_nodes()#
	species.update_talent_nodes()#
	talents.reload_traits()


func reload_skills() -> void:
	characters.update_talent_nodes() #
	species.update_talent_nodes()#
	talents.reload_skills()


func reload_character_sheet() -> void:
	characters.update_genders() #


func reload_items() -> void:
	items.items_container.reload_fields() #
