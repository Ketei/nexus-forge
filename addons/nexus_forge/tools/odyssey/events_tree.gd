extends Tree


signal event_item_created(item_id: String, operator: int, on_success: bool)
signal event_item_changed(item_idx: int, item_id: String, item_op: int, item_count: int, on_success: bool)
signal event_variable_created(var_path: String, value: Variant, operator: int, on_success: bool)
signal event_var_changed(var_idx: int, var_path: String, operator: int, on_success: bool)
signal event_currency_created(currency_id: String, operator: int, on_success: bool)
signal event_currency_changed(currency_idx: int, currency_id: String, operator: int, on_success: bool)
signal event_item_removed(item_idx: int, on_success: bool)
signal event_variable_removed(item_idx: int, on_success: bool)
signal event_currency_removed(item_idx: int, on_success: bool)

const ICON_ADD = preload("res://addons/nexus_forge/common_icons/plus_icon.svg")
const ICON_ADD_BOOL = preload("res://addons/nexus_forge/tools/variables/icons/add_bool.svg")
const ICON_ADD_FLOAT = preload("res://addons/nexus_forge/tools/variables/icons/add_float.svg")
const ICON_ADD_INT = preload("res://addons/nexus_forge/tools/variables/icons/add_int.svg")
const ICON_ADD_STRING = preload("res://addons/nexus_forge/tools/variables/icons/add_string.svg")
const ICON_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")
const ICON_BOOL = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const ICON_FLOAT = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const ICON_INT = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const ICON_STRING = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
const MAX_ITEM_RANGE: int = 100
const MAX_CURRENCY_RANGE: int = 100

const VAR_VAL_RANGE: int = 9999
const FLOAT_STEP: float = 0.01

var root_tree: TreeItem = null
#var completion_tree: TreeItem = null
#var failure_tree: TreeItem = null

var completed_items: TreeItem = null
var completed_vars: TreeItem = null
var completed_currency: TreeItem = null
var failed_items: TreeItem = null
var failed_vars: TreeItem = null
var failed_currency: TreeItem = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	root_tree = create_item()
	
	set_column_expand(0, true)
	set_column_expand(1, false)
	set_column_expand(2, true)
	
	set_column_custom_minimum_width(1, 48)
	
	var completion_tree: TreeItem = root_tree.create_child()
	var failure_tree: TreeItem = root_tree.create_child()
	
	completion_tree.set_text(0, "Quest Successful")
	failure_tree.set_text(0, "Quest Failed")
	
	completion_tree.set_selectable(0, false)
	completion_tree.set_selectable(1, false)
	completion_tree.set_selectable(2, false)
	
	failure_tree.set_selectable(0, false)
	failure_tree.set_selectable(1, false)
	failure_tree.set_selectable(2, false)
	
	completed_items = completion_tree.create_child()
	completed_currency = completion_tree.create_child()
	completed_vars = completion_tree.create_child()
	
	failed_items = failure_tree.create_child()
	failed_currency = failure_tree.create_child()
	failed_vars = failure_tree.create_child()
	
	completed_items.set_text(0, "Items")
	completed_vars.set_text(0, "Variables")
	completed_currency.set_text(0, "Currency")
	
	failed_items.set_text(0, "Items")
	failed_currency.set_text(0, "Currency")
	failed_vars.set_text(0, "Variables")
	
	completed_items.add_button(2, ICON_ADD, 0, false, "Add Item")
	completed_currency.add_button(2, ICON_ADD, 1, false, "Add Currency")
	completed_vars.add_button(2, ICON_ADD_INT, 2, false, "Add Integer")
	completed_vars.add_button(2, ICON_ADD_FLOAT, 3, false, "Add Float")
	completed_vars.add_button(2, ICON_ADD_BOOL, 4, false, "Add Bool")
	completed_vars.add_button(2, ICON_ADD_STRING, 5, false, "Add String")
	
	failed_items.add_button(2, ICON_ADD, 0, false, "Add Item")
	failed_currency.add_button(2, ICON_ADD, 1, false, "Add Currency")
	failed_vars.add_button(2, ICON_ADD_INT, 2, false, "Add Integer")
	failed_vars.add_button(2, ICON_ADD_FLOAT, 3, false, "Add Float")
	failed_vars.add_button(2, ICON_ADD_BOOL, 4, false, "Add Bool")
	failed_vars.add_button(2, ICON_ADD_STRING, 5, false, "Add String")
	
	completed_items.set_selectable(0, false)
	completed_items.set_selectable(1, false)
	completed_items.set_selectable(2, false)
	
	completed_vars.set_selectable(0, false)
	completed_vars.set_selectable(1, false)
	completed_vars.set_selectable(2, false)
	
	completed_currency.set_selectable(0, false)
	completed_currency.set_selectable(1, false)
	completed_currency.set_selectable(2, false)
	
	failed_items.set_selectable(0, false)
	failed_items.set_selectable(1, false)
	failed_items.set_selectable(2, false)
	
	failed_vars.set_selectable(0, false)
	failed_vars.set_selectable(1, false)
	failed_vars.set_selectable(2, false)
	
	failed_currency.set_selectable(0, false)
	failed_currency.set_selectable(1, false)
	failed_currency.set_selectable(2, false)
	
	completion_tree.collapsed = true
	failure_tree.collapsed = true
	
	button_clicked.connect(_on_button_clicked)
	

func create_tree_item(on_tree: TreeItem, item_id: String = "", item_op: int = 0, item_count: int = 1) -> void:
	var new_item: TreeItem = on_tree.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_range_config(1, 0, 2, 1)
	new_item.set_range_config(2, 1, MAX_ITEM_RANGE, 1)
	
	new_item.set_text(0, item_id)
	new_item.set_text(1, "=,+,-")
	new_item.set_range(1, 1)
	new_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)
	
	new_item.add_button(
			2,
			ICON_BIN,
			6,
			false,
			"Remove Item")


func create_tree_currency(on_tree: TreeItem, currency_id: String = "", item_op: int = 0, item_count: int = 1) -> void:
	var new_item: TreeItem = on_tree.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_range_config(1, 0, 2, 1)
	new_item.set_range_config(2, 1, MAX_ITEM_RANGE, 1)
	
	new_item.set_text(0, currency_id)
	new_item.set_text(1, "=,+,-")
	new_item.set_range(1, 1)
	
	new_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)
	
	new_item.add_button(
			2,
			ICON_BIN,
			7,
			false,
			"Remove Currency")


func create_tree_variable(on_tree: TreeItem, path: String, item_op: int, value: Variant) -> void:
	var new_item: TreeItem = on_tree.create_child()
	new_item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	
	new_item.set_text(1, "=,+,-")
	
	match typeof(value):
		TYPE_INT:
			new_item.set_icon(0, ICON_INT)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_item.set_range_config(2, -VAR_VAL_RANGE, VAR_VAL_RANGE, 1.0)
			new_item.set_range(2, value)
		TYPE_FLOAT:
			new_item.set_icon(0, ICON_FLOAT)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_item.set_range_config(2, -VAR_VAL_RANGE, VAR_VAL_RANGE, FLOAT_STEP)
			new_item.set_range(2, value)
		TYPE_BOOL:
			new_item.set_icon(0, ICON_BOOL)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_item.set_checked(2, value)
			new_item.set_text(2, "Enabled")
			new_item.set_text(1, "=")
		TYPE_STRING:
			new_item.set_icon(0, ICON_STRING)
			new_item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
			new_item.set_text(2, value)
			new_item.set_text(1, "=")
	
	new_item.set_text(0, path)
	
	new_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	
	new_item.set_editable(0, true)
	new_item.set_editable(1, true)
	new_item.set_editable(2, true)
	
	new_item.add_button(
			2,
			ICON_BIN,
			8,
			false,
			"Remove Variable")


func operator_to_range(operator: int) -> int:
	match operator:
		OP_EQUAL:
			return 0
		OP_ADD:
			return 1
		OP_SUBTRACT:
			return 2
		_:
			return 0


func range_to_operator(range: int) -> int:
	match range:
		0:
			return OP_EQUAL
		1:
			return OP_ADD
		2:
			return OP_SUBTRACT
		_:
			return OP_ADD


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	match id:
		0:
			create_tree_item(item)
			event_item_created.emit("", 0, item == completed_items)
		1:
			create_tree_currency(item)
			event_currency_created.emit("", 0, item == completed_currency)
		2:
			create_tree_variable(item, "", 0, 0)
			event_variable_created.emit("", 0, 0, item == completed_vars)
		3:
			create_tree_variable(item, "", 0, 0.0)
			event_variable_created.emit("", 0.0, 0, item == completed_vars)
		4:
			create_tree_variable(item, "", 0, false)
			event_variable_created.emit("", false, 0, item == completed_vars)
		5:
			create_tree_variable(item, "", 0, "")
			event_variable_created.emit("", "", 0, item == completed_vars)
		6:
			event_item_removed.emit(item.get_index(), item.get_parent() == completed_items)
			item.free()
		7:
			event_currency_removed.emit(item.get_index(), item.get_parent() == completed_currency)
			item.free()
		8:
			event_variable_removed.emit(item.get_index(), item.get_parent() == completed_vars)
			item.free()
