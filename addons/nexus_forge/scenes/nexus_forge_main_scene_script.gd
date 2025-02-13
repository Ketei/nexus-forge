@tool
extends Control


@onready var tool_tab_bar: TabBar = $MainContainer/ToolTabBar
@onready var splash_texture: TextureRect = $MainContainer/ToolContainer/NexusForge/SplashPanel/SplashTexture

# ----- Tools -----
@onready var nexus_forge: Control = $MainContainer/ToolContainer/NexusForge
@onready var discourse: Control = $MainContainer/ToolContainer/Discourse
@onready var variables: Control = $MainContainer/ToolContainer/Variables
@onready var kinds: Control = $MainContainer/ToolContainer/Kinds
@onready var characters: Control = $MainContainer/ToolContainer/Kinds/TabContainer/Characters
@onready var races: Control = $MainContainer/ToolContainer/Kinds/TabContainer/Races
@onready var factions: Control = $MainContainer/ToolContainer/Kinds/TabContainer/Factions
@onready var talents: Control = $MainContainer/ToolContainer/Talents
@onready var depot: Control = $MainContainer/ToolContainer/Depot
@onready var odyssey: Control = $MainContainer/ToolContainer/Odyssey
# -----------------


func _ready() -> void:
	tool_tab_bar.tab_changed.connect(on_tab_changed)
	tool_tab_bar.current_tab = 0
	tool_tab_bar.set_tab_title(0, "")
	tool_tab_bar.set_tab_icon(0, load("res://addons/nexus_forge/common_icons/temp_icon.svg"))
	var potential_splash: Array[String] = []
	
	for file in DirAccess.get_files_at("res://addons/nexus_forge/splash/"):
		var ext: String = file.get_extension()
		if ext == "png" or ext == "jpg" or ext == "webp":
			potential_splash.append(file)
	
	if not potential_splash.is_empty():
		var selected_splash: String = potential_splash.pick_random()
		splash_texture.texture = load("res://addons/nexus_forge/splash/" + selected_splash)
	
	on_tab_changed(0)


func _input(event: InputEvent) -> void:
	if visible:
		if Input.is_action_just_pressed(&"ui_focus_next"):
			if Input.is_key_pressed(KEY_CTRL):
				if Input.is_key_pressed(KEY_SHIFT):
					tool_tab_bar.current_tab = posmod(tool_tab_bar.current_tab - 1, 7)
				else:
					tool_tab_bar.current_tab = posmod(tool_tab_bar.current_tab + 1, 7)
			get_viewport().set_input_as_handled()


func on_tab_changed(tab: int) -> void:
	nexus_forge.visible = tab == 0
	discourse.visible = tab == 1
	variables.visible = tab == 2
	kinds.visible = tab == 3
	talents.visible = tab == 4
	depot.visible = tab == 5
	odyssey.visible = tab == 6


func has_unsaved_changes() -> bool:
	return discourse.has_unsaved_changes() or variables.has_unsaved_changes() or characters.has_unsaved_changes() or races.has_unsaved_changes() or factions.has_unsaved_changes() or talents.has_unsaved_changes() or depot.has_unsaved_changes() or odyssey.has_unsaved_changes()


func save_resources() -> void:
	discourse.save_all()
	variables.save()
	characters.save()
	races.save()
	factions.save()
	talents.save()
	depot.save()
	odyssey.save()
