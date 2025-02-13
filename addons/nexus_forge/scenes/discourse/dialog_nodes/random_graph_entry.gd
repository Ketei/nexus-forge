@tool
extends HBoxContainer


signal field_updated

var _weight_spnbx: SpinBox = null
var _out_label: Label = null


func _ready() -> void:
	alignment = ALIGNMENT_END
	
	_weight_spnbx = SpinBox.new()
	_out_label = Label.new()
	
	add_child(_weight_spnbx)
	add_child(_out_label)
	
	_weight_spnbx.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_weight_spnbx.min_value = 0.01
	_weight_spnbx.step = 0.01
	_weight_spnbx.value = 1
	_weight_spnbx.allow_greater = true
	
	_out_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	_weight_spnbx.value_changed.connect(on_field_updated)


func on_field_updated(_arg: Variant = null) -> void:
	field_updated.emit()


func use_weights(use: bool) -> void:
	_weight_spnbx.editable = use


func set_weight(weight: float) -> void:
	_weight_spnbx.value = weight


func set_text(new_text: String) -> void:
	_out_label.text = new_text


func get_weigth() -> float:
	return _weight_spnbx.value
