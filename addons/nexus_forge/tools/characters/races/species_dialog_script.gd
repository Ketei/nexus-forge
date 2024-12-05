extends ConfirmationDialog


signal dialog_finished(confirmed: bool, id: String)

var species_mode: bool = true
var species_id: String = ""
var race_resource: NFRacesRes = null


@onready var id_line_edit: LineEdit = $IDLineEdit


func _ready() -> void:
	if species_mode:
		title = "Create Species..."
		id_line_edit.placeholder_text = "Species ID"
	else:
		title = "Create " + species_id + " Race..."
		id_line_edit.placeholder_text = "Race ID"
	
	id_line_edit.text_changed.connect(on_id_line_changed)
	id_line_edit.text_submitted.connect(on_id_submitted)
	confirmed.connect(on_confirmed)
	canceled.connect(on_cancelled)


func on_id_line_changed(new_id: String) -> void:
	var stripped_id: String = new_id.strip_edges()
	var id_exists: bool = true
	
	if not stripped_id.is_empty():
		if species_mode:
			id_exists = race_resource.has_species(stripped_id)
		else:
			id_exists = race_resource.has_race(species_id, stripped_id)
	
	get_ok_button().disabled = id_exists


func on_id_submitted(_id_text: String) -> void:
	if not get_ok_button().disabled:
		hide()
		on_confirmed()


func on_confirmed() -> void:
	dialog_finished.emit(true, id_line_edit.text.strip_edges())


func on_cancelled() -> void:
	dialog_finished.emit(false, "")
