extends Control


@onready var tool_tab_bar: TabBar = $MainContainer/ToolTabBar

# ----- Tools -----
@onready var nexus_forge: Control = $MainContainer/ToolContainer/NexusForge
@onready var discourse: Control = $MainContainer/ToolContainer/Discourse
@onready var variables: Control = $MainContainer/ToolContainer/Variables
@onready var kinds: Control = $MainContainer/ToolContainer/Kinds
@onready var talents: Control = $MainContainer/ToolContainer/Talents
@onready var depot: Control = $MainContainer/ToolContainer/Depot
@onready var odyssey: Control = $MainContainer/ToolContainer/Odyssey
# -----------------


func _ready() -> void:
	tool_tab_bar.tab_changed.connect(on_tab_changed)
	tool_tab_bar.current_tab = 0
	on_tab_changed(0)


func on_tab_changed(tab: int) -> void:
	nexus_forge.visible = tab == 0
	discourse.visible = tab == 1
	variables.visible = tab == 2
	kinds.visible = tab == 3
	talents.visible = tab == 4
	depot.visible = tab == 5
	odyssey.visible = tab == 6
