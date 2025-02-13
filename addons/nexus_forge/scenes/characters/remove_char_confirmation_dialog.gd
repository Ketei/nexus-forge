extends ConfirmationDialog


signal dialog_finished(success: bool)

var character_id: String = ""
@onready var label: Label = $Label


func _ready() -> void:
	label.text = "Are you sure you want to remove the character {0}?\nResource will be removed from characters but NOT deleted.".format([character_id])
	confirmed.connect(on_confirmed)
	canceled.connect(on_cancelled)


func on_confirmed() -> void:
	dialog_finished.emit(true)


func on_cancelled() -> void:
	dialog_finished.emit(false)
