@tool
extends ConfirmationDialog

signal dialog_finished(confirmed: bool, id: String)

var factions_resource: NFFactionRes
@onready var id_line_edit: LineEdit = $IDLineEdit


func _ready() -> void:
	id_line_edit.text_changed.connect(on_id_line_changed)
	id_line_edit.text_submitted.connect(on_line_text_submitted)
	confirmed.connect(on_confirmed)
	canceled.connect(on_cancelled)


func on_line_text_submitted(_text: String) -> void:
	if not get_ok_button().disabled:
		hide()
		on_confirmed()


func on_id_line_changed(new_id: String) -> void:
	var fixed_id: String = new_id.strip_edges()
	var id_exists: bool = true
	
	if not fixed_id.is_empty():
		id_exists = factions_resource.has_faction(fixed_id)
	
	get_ok_button().disabled = id_exists


func on_confirmed() -> void:
	dialog_finished.emit(true, id_line_edit.text.strip_edges())


func on_cancelled() -> void:
	dialog_finished.emit(false, "")
