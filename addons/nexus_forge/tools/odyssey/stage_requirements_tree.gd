extends Tree


var root_tree: TreeItem = null

var required_items: TreeItem = null
var required_triggers: TreeItem = null
var required_variables: TreeItem = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	root_tree = create_item()
	root_tree.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	root_tree.set_text(0, "Requirements")
	root_tree.set_selectable(0, false)
	root_tree.set_selectable(1, false)
	root_tree.set_selectable(2, false)
	
	required_items = root_tree.create_child()
	required_triggers = root_tree.create_child()
	required_variables = root_tree.create_child()
	
	required_items.set_text(0, "Items")
	required_triggers.set_text(0, "Triggers")
	required_variables.set_text(0, "Variables")
	
	required_items.set_selectable(0, false)
	required_items.set_selectable(1, false)
	required_items.set_selectable(2, false)
	
	required_triggers.set_selectable(0, false)
	required_triggers.set_selectable(1, false)
	required_triggers.set_selectable(2, false)
	
	required_variables.set_selectable(0, false)
	required_variables.set_selectable(1, false)
	required_variables.set_selectable(2, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
