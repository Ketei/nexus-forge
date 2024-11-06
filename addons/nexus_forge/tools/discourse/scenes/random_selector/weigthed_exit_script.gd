@tool
extends HBoxContainer


signal weight_changed

@onready var option_weight: SpinBox = $OptionWeight
@onready var out_label: Label = $OutLabel


func _ready() -> void:
	option_weight.value_changed.connect(on_weight_changed)


func on_weight_changed(new_value: float) -> void:
	weight_changed.emit()
