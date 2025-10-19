#@tool
extends Control


@onready var tool_tab_bar: TabBar = $MainContainer/ToolTabBar
@onready var splash_texture: TextureRect = $MainContainer/ToolContainer/NexusForge/SplashPanel/SplashTexture
#@onready var reload_image_btn: Button = $MainContainer/ToolContainer/NexusForge/SplashPanel/SplashTexture/ReloadImageBtn
var recipes_link: EditorItemRecipeLink = EditorItemRecipeLink.new()
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

# -----------------


func _ready() -> void:
	#$MainContainer/ToolContainer.add_theme_stylebox_override(&"panel", get_theme_stylebox("Content", "EditorStyles"))
	tool_tab_bar.current_tab = 0
	tool_tab_bar.set_tab_title(0, "")
	tool_tab_bar.set_tab_icon(0, load("res://addons/nexus_forge/icons/plugin_icon.svg"))
	
	_on_tab_changed(0)
	if recipes.recipes_resource != null:
		recipes_link.recipes = recipes.recipes_resource
	
	items.items_container.item_link = recipes_link
	
	recipes.recipes_loaded.connect(_on_recipes_loaded)
	recipes_link.item_created.connect(recipes.add_item)
	recipes_link.item_renamed.connect(recipes.change_item_name)
	recipes_link.item_id_changed.connect(recipes.change_item_id)
	recipes_link.item_erased.connect(recipes._on_item_erased)
	
	tool_tab_bar.tab_changed.connect(_on_tab_changed)


func _on_recipes_loaded() -> void:
	recipes_link.recipes = recipes.recipes_resource


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		if event.keycode == KEY_TAB:
			if event.ctrl_pressed:
				if  event.shift_pressed:
					tool_tab_bar.current_tab = posmod(tool_tab_bar.current_tab - 1, 7)
				else:
					tool_tab_bar.current_tab = posmod(tool_tab_bar.current_tab + 1, 7)
			get_viewport().set_input_as_handled()


func _on_tab_changed(tab: int) -> void:
	nexus_forge.visible = tab == 0
	discourse.visible = tab == 1
	variables.visible = tab == 2
	characters.visible = tab == 3
	species.visible = tab == 4
	talents.visible = tab == 5
	items.visible = tab == 6
	recipes.visible = tab == 7 
	quests.visible = tab == 8


func has_unsaved_changes() -> bool:
	return discourse.has_unsaved_files() or variables._unsaved or characters.has_unsaved_files() or species._unsaved or talents._unsaved or items._unsaved or recipes._unsaved or quests._unsaved


func save_resources() -> void:
	discourse.save_all_dialogs()
	variables.save()
	characters.save()
	species.save()
	talents.save()
	items.save()
	recipes.save()
	quests.save()
