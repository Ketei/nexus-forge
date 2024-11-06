@tool
extends PanelContainer


signal create_db_pressed
signal load_db_pressed
signal check_res_pressed


@onready var create_db_button: Button = $CenterContainer/InfoContainer/ButtonsContainer/CharaButtonContainer/CreateDBButton
@onready var load_db_button: Button = $CenterContainer/InfoContainer/ButtonsContainer/CharaButtonContainer/LoadDBButton
@onready var check_resources_btn: Button = $CenterContainer/InfoContainer/ButtonsContainer/CheckResourcesBtn
@onready var success_char_texture: TextureRect = $CenterContainer/InfoContainer/RacesMissingContainer/CharDBContainer/SuccessCharTexture
@onready var failure_char_texture: TextureRect = $CenterContainer/InfoContainer/RacesMissingContainer/CharDBContainer/FailureCharTexture
@onready var success_races_texture: TextureRect = $CenterContainer/InfoContainer/RacesMissingContainer/RaceResContainer/SuccessRacesTexture
@onready var failure_races_texture: TextureRect = $CenterContainer/InfoContainer/RacesMissingContainer/RaceResContainer/FailureRacesTexture
@onready var success_facc_texture: TextureRect = $CenterContainer/InfoContainer/RacesMissingContainer/FaccResContainer/SuccessFaccTexture
@onready var failure_facc_texture: TextureRect = $CenterContainer/InfoContainer/RacesMissingContainer/FaccResContainer/FailureFaccTexture
@onready var success_tal_texture: TextureRect = $CenterContainer/InfoContainer/RacesMissingContainer/TalentsResContainer/SuccessTalTexture
@onready var failure_tal_texture: TextureRect = $CenterContainer/InfoContainer/RacesMissingContainer/TalentsResContainer/FailureTalTexture


func _ready() -> void:
	create_db_button.pressed.connect(create_db_pressed.emit)
	load_db_button.pressed.connect(load_db_pressed.emit)
	check_resources_btn.pressed.connect(check_res_pressed.emit)


func set_tal_success(is_loaded: bool) -> void:
	success_tal_texture.visible = is_loaded
	failure_tal_texture.visible = not is_loaded


func set_facc_success(is_loaded: bool) -> void:
	success_facc_texture.visible = is_loaded
	failure_facc_texture.visible = not is_loaded


func set_race_success(is_loaded: bool) -> void:
	success_races_texture.visible = is_loaded
	failure_races_texture.visible = not is_loaded


func set_char_success(is_loaded: bool) -> void:
	success_char_texture.visible = is_loaded
	failure_char_texture.visible = not is_loaded
	create_db_button.disabled = is_loaded
	load_db_button.disabled = is_loaded
