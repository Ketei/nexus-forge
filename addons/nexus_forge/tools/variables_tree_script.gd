extends Tree


const INT_ICON = preload("res://addons/nexus_forge/common_icons/variables/int.svg")
const FLOAT_ICON = preload("res://addons/nexus_forge/common_icons/variables/float.svg")
const BOOL_ICON = preload("res://addons/nexus_forge/common_icons/variables/bool.svg")
const STRING_ICON = preload("res://addons/nexus_forge/common_icons/variables/string.svg")
const VALUE_MAX_RANGE: int = 9999
const FLOAT_STEP: float = 0.01

var root_tree: TreeItem


func _ready() -> void:
	root_tree = create_item()
	set_column_title(0, "Name")
	set_column_title(2, "Default Value")
	set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	set_column_title_alignment(2, HORIZONTAL_ALIGNMENT_LEFT)
	set_column_expand(0, true)
	set_column_expand(1, true)
	set_column_expand(2, true)
	set_column_expand_ratio(0, 8)
	set_column_expand_ratio(1, 1)
	set_column_expand_ratio(2, 8)
	#root_tree.add_child()
	create_variable("asd", TYPE_STRING)
	create_variable("asd", TYPE_BOOL)
	create_variable("asd", TYPE_INT)
	


func create_variable(variable_name: String, variable_type: Variant.Type) -> TreeItem:
	var new_variable: TreeItem = create_item(root_tree)
	
	# Setting cell modes (and icon)
	new_variable.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_variable.set_cell_mode(1, TreeItem.CELL_MODE_ICON)
	match variable_type: 
		TYPE_INT:
			new_variable.set_icon(1, INT_ICON)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VALUE_MAX_RANGE, VALUE_MAX_RANGE, 1.0)
		TYPE_FLOAT:
			new_variable.set_icon(1, FLOAT_ICON)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_RANGE)
			new_variable.set_range_config(2, -VALUE_MAX_RANGE, VALUE_MAX_RANGE, FLOAT_STEP)
		TYPE_BOOL:
			new_variable.set_icon(1, BOOL_ICON)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			new_variable.set_text(2, "Enabled")
			
		_:
			new_variable.set_icon(1, STRING_ICON)
			new_variable.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
	# ------------------
	
	# Setting editability
	new_variable.set_editable(0, true) # The name
	new_variable.set_editable(2, true) # The value
	# -------------------
	
	# Setting the initial name
	new_variable.set_text(0, variable_name)
	# ------------------------
	
	new_variable.set_selectable(1, false)
	
	return new_variable


func _get_variant_instance(variant_type: Variant.Type) -> Control:
	var new_variant: Control
	if variant_type == TYPE_INT:
		new_variant = SpinBox.new()
		new_variant.step = 1.0
	elif variant_type == TYPE_FLOAT:
		new_variant = SpinBox.new()
		new_variant.step = 0.01
	elif variant_type == TYPE_BOOL:
		new_variant = CheckBox.new()
		new_variant.text = "Enabled"
	else:
		new_variant = LineEdit.new()
	
	return new_variant
