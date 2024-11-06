@tool
extends PanelContainer


signal create_species_pressed(species_id: String)
signal create_race_pressed(on_species: String, race_id: String)

const INVALID_COLOR: Color = Color("e1323c")
const VALID_COLOR: Color = Color("64d732")

const ERROR_ICON = preload("res://addons/nexus_forge/common_icons/error_icon.svg")
const CHECK_ICON = preload("res://addons/nexus_forge/common_icons/check_icon.svg")

var species_mode: bool = true
var species_id: String = ""
var _race_resource: NFRacesRes = null

@onready var popup_title_lbl: Label = $CenterContainer/PromptContainer/HeaderPanel/PopupTitleLbl
@onready var id_line_edit: LineEdit = $CenterContainer/PromptContainer/PopupDataPanel/DataContainer/IDContainer/IDLineEdit
@onready var valid_text_rect: TextureRect = $CenterContainer/PromptContainer/PopupDataPanel/DataContainer/IDContainer/ValidTextRect
@onready var cancel_btn: Button = $CenterContainer/PromptContainer/PopupDataPanel/DataContainer/ButtonsContainer/CancelBtn
@onready var create_btn: Button = $CenterContainer/PromptContainer/PopupDataPanel/DataContainer/ButtonsContainer/CreateBtn


func _ready() -> void:
	id_line_edit.text_submitted.connect(on_id_submitted)
	id_line_edit.text_changed.connect(on_id_line_changed)
	create_btn.pressed.connect(on_create_pressed)
	cancel_btn.pressed.connect(on_cancel_pressed)
	if visible:
		visible = false


func create_new_species() -> void:
	id_line_edit.clear()
	popup_title_lbl.text = "New Species ID"
	species_mode = true
	id_line_edit.grab_focus()
	visible = true


func create_new_race(on_species: String) -> void:
	id_line_edit.clear()
	popup_title_lbl.text = "New Race ID"
	species_mode = false
	species_id = on_species
	id_line_edit.grab_focus()
	visible = true


func on_id_line_changed(new_id: String) -> void:
	var stripped_id: String = new_id.strip_edges()
	
	if stripped_id.is_empty():
		valid_text_rect.texture = ERROR_ICON
		valid_text_rect.modulate = INVALID_COLOR
		create_btn.disabled = true
		return
	
	if species_mode:
		if _race_resource.has_species(stripped_id):
			valid_text_rect.texture = ERROR_ICON
			valid_text_rect.modulate = INVALID_COLOR
			create_btn.disabled = true
		else:
			valid_text_rect.texture = CHECK_ICON
			valid_text_rect.modulate = VALID_COLOR
			create_btn.disabled = false
	else:
		if _race_resource.has_race(species_id, stripped_id):
			valid_text_rect.texture = ERROR_ICON
			valid_text_rect.modulate = INVALID_COLOR
			create_btn.disabled = true
		else:
			valid_text_rect.texture = CHECK_ICON
			valid_text_rect.modulate = VALID_COLOR
			create_btn.disabled = false


func on_id_submitted(_id_text: String) -> void:
	if not create_btn.disabled:
		on_create_pressed()


func on_create_pressed() -> void:
	if species_mode:
		create_species_pressed.emit(id_line_edit.text.strip_edges())
	else:
		create_race_pressed.emit(species_id, id_line_edit.text.strip_edges())


func on_cancel_pressed() -> void:
	visible = false
