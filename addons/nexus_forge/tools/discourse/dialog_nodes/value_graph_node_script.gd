@tool
extends DiscourseGraphNode


var type_locked: bool = false:
	set(is_locked):
		type_locked = is_locked
		val_type_opt_btn.disabled = is_locked

@onready var val_type_opt_btn: OptionButton = $HBoxContainer/ValTypeOptBtn
@onready var bool_chk_btn: CheckButton = $HBoxContainer/PanelContainer/BoolChkBtn
@onready var val_spn_bx: SpinBox = $HBoxContainer/PanelContainer/ValSpnBx
@onready var text_var_ln_edt: LineEdit = $HBoxContainer/PanelContainer/TextVarLnEdt
@onready var null_label: Label = $HBoxContainer/PanelContainer/NullLabel


func _ready() -> void:
	graph_type = GraphType.VALUE
	register_output_connection("value", 0, true)
	
	val_type_opt_btn.clear()
	
	val_type_opt_btn.add_item("int", ValueType.TYPE_INT)
	val_type_opt_btn.add_item("flt", ValueType.TYPE_FLOAT)
	val_type_opt_btn.add_item("bool", ValueType.TYPE_BOOL)
	val_type_opt_btn.add_item("str", ValueType.TYPE_STRING)
	val_type_opt_btn.add_item("var", ValueType.TYPE_VARIABLE)
	val_type_opt_btn.add_item("null", ValueType.TYPE_NIL)
	
	val_type_opt_btn.select(0)
	add_utility()
	
	val_type_opt_btn.item_selected.connect(on_type_selected)
	val_type_opt_btn.item_selected.connect(field_updated)
	bool_chk_btn.toggled.connect(field_updated)
	bool_chk_btn.toggled.connect(on_bool_toggled)
	val_spn_bx.value_changed.connect(field_updated)
	text_var_ln_edt.text_changed.connect(field_updated)


func _get_node_data() -> Dictionary:
	var return_value: Dictionary = {
		"var_type": val_type_opt_btn.get_item_id(val_type_opt_btn.selected),
		"_type": graph_type,
		"_offset": position_offset}
	
	match return_value["var_type"]:
		ValueType.TYPE_INT:
			return_value["value"] = int(val_spn_bx.value)
		ValueType.TYPE_FLOAT:
			return_value["value"] = val_spn_bx.value
		ValueType.TYPE_BOOL:
			return_value["value"] = bool_chk_btn.button_pressed
		ValueType.TYPE_VARIABLE:
			return_value["value"] = text_var_ln_edt.text.strip_edges()
		ValueType.TYPE_STRING:
			return_value["value"] = text_var_ln_edt.text.strip_edges()
		ValueType.TYPE_NIL:
			return_value["value"] = null
	
	return return_value


func _is_orphan() -> bool:
	if has_any_output_connection("value"):
		return get_output_connections("output")[0]._is_orphan()
	return true


func _connection_set(_is_input: bool, _connection_id: String, node: DiscourseGraphNode) -> void:
	if node == null:
		type_locked = false
		set_all_enabled(true)
	elif node != null:
		if node.graph_type == GraphType.VAR_SET:
			set_type(op_native_to_type(node.get_variant_type()), true)
		elif node.graph_type == GraphType.MATH:
			set_type_enabled(ValueType.TYPE_BOOL, false)
			set_type_enabled(ValueType.TYPE_NIL, false)
			set_type_enabled(ValueType.TYPE_STRING, false)
			if val_type_opt_btn.is_item_disabled(val_type_opt_btn.selected):
				val_type_opt_btn.select(0)
				on_type_selected(0)


func get_type() -> int:
	return val_type_opt_btn.get_item_id(val_type_opt_btn.selected)


func on_bool_toggled(is_toggled: bool) -> void:
	bool_chk_btn.text = "True" if is_toggled else "False"


func field_updated(_var: Variant = null) -> void:
	node_updated.emit()


func set_type(type: int, lock_type: bool = false) -> void:
	for idx in range(val_type_opt_btn.item_count):
		if val_type_opt_btn.get_item_id(idx) == type:
			val_type_opt_btn.select(idx)
			on_type_selected(idx)
			break
	if type_locked != lock_type:
		type_locked = lock_type


func set_value(value: Variant) -> void:
	var type: int = typeof(value)
	match type:
		TYPE_INT:
			val_spn_bx.value = value
		TYPE_FLOAT:
			val_spn_bx.value = value
		TYPE_BOOL:
			bool_chk_btn.button_pressed = value
		TYPE_STRING:
			text_var_ln_edt.text = value


func op_native_to_type(type: int) -> int:
	match type:
		TYPE_INT:
			return ValueType.TYPE_INT
		TYPE_BOOL:
			return ValueType.TYPE_BOOL
		TYPE_FLOAT:
			return ValueType.TYPE_FLOAT
		TYPE_STRING:
			return ValueType.TYPE_STRING
		TYPE_NIL:
			return ValueType.TYPE_NIL
		_:
			return ValueType.TYPE_INT


func set_type_enabled(type: int, is_enabled: bool) -> void:
	for idx in range(val_type_opt_btn.item_count):
		if val_type_opt_btn.get_item_id(idx) == type:
			val_type_opt_btn.set_item_disabled(idx, not is_enabled)


func set_all_enabled(set_enabled: bool) -> void:
	for idx in range(val_type_opt_btn.item_count):
		val_type_opt_btn.set_item_disabled(idx, not set_enabled)


func on_type_selected(type_idx: int) -> void:
	var type_id: int = val_type_opt_btn.get_item_id(type_idx)
	text_var_ln_edt.visible = type_id == ValueType.TYPE_STRING or type_id == ValueType.TYPE_VARIABLE
	val_spn_bx.visible = type_id == ValueType.TYPE_INT or type_id == ValueType.TYPE_FLOAT
	if val_spn_bx.visible:
		val_spn_bx.step = 0.01 if type_id == ValueType.TYPE_FLOAT else 1.0
	null_label.visible = type_id == ValueType.TYPE_NIL
	bool_chk_btn.visible = type_id == ValueType.TYPE_BOOL
	
	if has_any_output_connection("value"):
		for out_con in get_output_connections("value"):
			if out_con.graph_type == GraphType.MATCH:
				out_con.set_match_type(type_id)
