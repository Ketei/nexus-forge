@tool
extends PanelContainer


signal id_changed(defined_id: String)
signal id_submitted(id_submit: String)

#@onready var id_line_panel: PanelContainer = $MainCenterContainer/ItemsContainer/DataPanel/ItemsContainer/IDContainer/IDLinePanel
@onready var id_line: LineEdit = $MainCenterContainer/ItemsContainer/DataPanel/ItemsContainer/IDContainer/IDLinePanel/IDLine
@onready var accept_button: Button = $MainCenterContainer/ItemsContainer/DataPanel/ItemsContainer/ButtonsContainer/AcceptButton
@onready var cancel_button: Button = $MainCenterContainer/ItemsContainer/DataPanel/ItemsContainer/ButtonsContainer/CancelButton

@onready var valid_id_texture: TextureRect = $MainCenterContainer/ItemsContainer/DataPanel/ItemsContainer/IDContainer/ValidIDTexture
@onready var invalid_id_texture: TextureRect = $MainCenterContainer/ItemsContainer/DataPanel/ItemsContainer/IDContainer/InvalidIDTexture


func _ready() -> void:
	if visible:
		visible = false
	id_line.text_changed.connect(on_id_text_changed)
	id_line.text_submitted.connect(on_id_text_submitted)
	accept_button.pressed.connect(on_id_submit_pressed)
	cancel_button.pressed.connect(on_cancel_pressed)


func clear_id() -> void:
	id_line.clear()


func on_cancel_pressed() -> void:
	if cancel_button.has_focus():
		cancel_button.release_focus()
	visible = false


func on_id_text_changed(new_id: String) -> void:
	var clean_id: String = new_id.strip_edges()
	if clean_id.is_empty():
		set_valid_id(false)
	else:
		id_changed.emit(clean_id)


func on_id_text_submitted(_text_submitted: String) -> void:
	if not accept_button.disabled:
		on_id_submit_pressed()


func on_id_submit_pressed() -> void:
	var id_line: String = id_line.text.strip_edges()
	if accept_button.has_focus():
		accept_button.release_focus()
	id_submitted.emit(id_line)


func set_valid_id(is_valid: bool) -> void:
	accept_button.disabled = not is_valid
	valid_id_texture.visible = is_valid
	invalid_id_texture.visible = not is_valid
