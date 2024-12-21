extends Tree


const VAR_RANGE: int = 9999
const FLOAT_STEP: float = 0.01

var root_tree: TreeItem = null

var required_items: TreeItem = null
var required_triggers: TreeItem = null
var required_variables: TreeItem = null


func _ready() -> void:
	root_tree = create_item()
	root_tree.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	root_tree.set_text(0, "Requirements")
	root_tree.set_selectable(0, false)
	root_tree.set_selectable(1, false)
	root_tree.set_selectable(2, false)
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	
	set_column_custom_minimum_width(1, 48)
	
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
	
	create_required_item("item_test")
	create_required_trigger("trigger_test")
	create_required_variable("stats/stamina", 0, OP_EQUAL)


func create_required_variable(var_path: String, var_value: Variant, operator: int) -> void:
	var new_variable: TreeItem = required_variables.create_child()
	
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variable.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_variable.set_text(1, "==,!=,<,<=,>,>=")
	new_variable.set_range(1, operator_to_range(operator))
	new_variable.set_text(0, var_path)
	
	match typeof(var_value):
		TYPE_INT:
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VAR_RANGE, VAR_RANGE, 1.0)
			new_variable.set_range(2, var_value)
		TYPE_FLOAT:
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VAR_RANGE, VAR_RANGE, FLOAT_STEP)
			new_variable.set_range(2, var_value)
		TYPE_BOOL:
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_variable.set_checked(2, var_value)
		TYPE_STRING:
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_variable.set_text(2, var_value)
	
	new_variable.set_editable(0, true)
	new_variable.set_editable(1, true)
	new_variable.set_editable(2, true)


func create_required_item(item_id: String = "", amount: int = 1, operator: int = OP_EQUAL) -> void:
	var new_item: TreeItem = required_items.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_text(1, "==,!=,<,<=,>,>=")
	new_item.set_range_config(2, 0, VAR_RANGE, 1)
	new_item.set_range(1, operator_to_range(operator))
	
	new_item.set_range(2, amount)
	new_item.set_text(0, item_id)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)


func create_required_trigger(trigger_id: String = "", count: int = 1, operator: int = OP_EQUAL) -> void:
	var new_item: TreeItem = required_triggers.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_text(0, trigger_id)
	
	new_item.set_text(1, "==,!=,<,<=,>,>=")
	new_item.set_range_config(2, 0, VAR_RANGE, 1)
	new_item.set_range(1, operator_to_range(operator))
	new_item.set_range(2, count)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)


func operator_to_range(operator: int) -> int:
	match operator:
		OP_EQUAL:
			return 0
		OP_NOT_EQUAL:
			return 1
		OP_LESS:
			return 2
		OP_LESS_EQUAL:
			return 3
		OP_GREATER:
			return 4
		OP_GREATER_EQUAL:
			return 5
		_:
			return 0


func range_to_operator(range: int) -> int:
	match range:
		0:
			return OP_EQUAL
		1:
			return OP_NOT_EQUAL
		2:
			return OP_LESS
		3:
			return OP_LESS_EQUAL
		4:
			return OP_GREATER
		5:
			return OP_GREATER_EQUAL
		_:
			return OP_EQUAL


func clear_requirements() -> void:
	for req in required_items.get_children():
		req.free()
	for req in required_triggers.get_children():
		req.free()
	for req in required_variables.get_children():
		req.free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
