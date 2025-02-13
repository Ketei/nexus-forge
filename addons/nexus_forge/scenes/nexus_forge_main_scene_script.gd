@tool
extends Control


@onready var tool_tab_bar: TabBar = $MainContainer/ToolTabBar

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
	on_tab_changed(0)
	


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
