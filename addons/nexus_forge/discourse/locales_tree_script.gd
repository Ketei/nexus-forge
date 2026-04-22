@tool
extends Tree


signal region_created(language: String, region: String)
signal locale_changed(from: String, to: String)
#signal region_deleted(language: String, region: String)
#signal language_deleted(language: String)
signal locale_deleted(locale: String)

#var NEW_REGION_BUTTON: Texture2D = get_theme_icon("New", "EditorIcons")

const ACTIVE_COLOR: Color = Color.SKY_BLUE

var main_language: TreeItem = null:
	set(new_main):
		if main_language != null:
			main_language.set_icon(0, null)
			main_language.set_button_disabled(0, 1, false)
		main_language = new_main
		if new_main != null:
			new_main.set_icon(
					0,
					get_theme_icon("Favorites", "EditorIcons"))
			new_main.set_button_disabled(0, 1, true)
var active_language: TreeItem = null:
	set(new_lang):
		if active_language != null:
			active_language.clear_custom_color(0)
		active_language = new_lang
		if new_lang != null:
			new_lang.set_custom_color(0, ACTIVE_COLOR)
var active_region: TreeItem = null:
	set(new_loc):
		if active_region != null:
			active_region.clear_custom_color(0)
		active_region = new_loc
		if new_loc != null:
			new_loc.set_custom_color(0, ACTIVE_COLOR)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	create_item()
	
	button_clicked.connect(_on_language_button_clicked)
	item_activated.connect(_on_lang_item_activated)


func _on_language_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	match id:
		0:
			_on_create_region_pressed(item.get_metadata(0)["language_code"])
		1:
			var old_locale: String = get_active_locale()
			
			if item.get_parent() == get_root():
				locale_deleted.emit(TranslationServer.standardize_locale(item.get_metadata(0)["language_code"]))
				#language_deleted.emit(
						#item.get_metadata(0)["language_code"])
			else:
				locale_deleted.emit(TranslationServer.standardize_locale(
						item.get_parent().get_metadata(0)["language_code"] +\
						"_" +\
						item.get_metadata(0)["region_code"]))
				#region_deleted.emit(
						#item.get_parent().get_metadata(0)["language_code"],
						#item.get_metadata(0)["region_code"])
			
			if item == active_region:
				active_region = null
				locale_changed.emit(old_locale, get_active_locale())
			elif item == active_language:
				active_language = null
				active_region = null
				locale_changed.emit(old_locale, "")
			item.free()


func _on_lang_item_activated() -> void:
	var old_locale: String = get_active_locale()
	var activated: TreeItem = get_selected()
	var is_language: bool = activated.get_parent() == get_root()
	
	if is_language:
		if active_language == activated and active_region == null:
			return
		if active_region != null:
			active_region = null
		active_language = activated
	else:
		if active_language == activated.get_parent() and active_region == activated:
			return
		var language: TreeItem = activated.get_parent()
		if language != active_language:
			active_language = language
		active_region = activated
	
	locale_changed.emit(
		old_locale,
		get_active_locale())


func _on_create_region_pressed(at_lang: String) -> void:
	var regions: Array[Dictionary] = []
	var used_regions: PackedStringArray = []
	
	for region in get_language_item(at_lang).get_children():
		used_regions.append(region.get_metadata(0)["region_code"])
	
	var region_codes: PackedStringArray = TranslationServer.get_all_countries()
	
	for region_code in region_codes:
		regions.append({
				"code": region_code,
				"disabled": region_code in used_regions,
				"name": TranslationServer.get_country_name(region_code)})
	
	var window := preload("res://addons/nexus_forge/discourse/locale_creation_confirm_dialog.gd").new()
	window.sort_codes_array(regions)
	window.title = "Select Region..."
	window.set_codes(regions)
	add_child(window)
	window.show()
	window.focus_option_button()
	var result_code: String = await window.dialog_finished
	
	if result_code != "":
		create_region(at_lang, result_code)
		region_created.emit(at_lang, result_code)
	window.queue_free()


func get_active_language() -> String:
	if active_language == null:
		return ""
	return active_language.get_metadata(0)["language_code"]


func get_active_region() -> String:
	if active_region == null:
		return ""
	return active_region.get_metadata(0)["region_code"]


func get_active_locale() -> String:
	var lang: String = get_active_language()
	var reg: String = get_active_region()
	var code: String = lang if reg.is_empty() else lang + "_" + reg
	return TranslationServer.standardize_locale(code)


func get_base_language() -> String:
	if main_language == null:
		return ""
	return TranslationServer.standardize_locale(main_language.get_metadata(0)["language_code"])


func create_language(language_code: String, is_main: bool = false) -> void:
	language_code = TranslationServer.standardize_locale(language_code)
	
	var root: TreeItem = get_root()
	var new_language: TreeItem = root.create_child()
	
	new_language.add_button(0, get_theme_icon("New", "EditorIcons"), 0, false, "New Region")
	new_language.add_button(0, get_theme_icon("Remove", "EditorIcons"), 1, is_main, "Delete Language")
	
	new_language.set_text(0, TranslationServer.get_language_name(language_code))
	new_language.set_metadata(0, {"language_code": language_code})
	new_language.set_text_overrun_behavior(0, TextServer.OVERRUN_TRIM_ELLIPSIS)
	
	if is_main:
		main_language = new_language


func has_language(language: String) -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["language_code"] == language:
			return true
	return false


func has_locale(language: String, region: String = "") -> bool:
	for item in get_root().get_children():
		if item.get_metadata(0)["language_code"] == language:
			if region.is_empty():
				return true
			else:
				for region_item in item.get_children():
					if region_item.get_metadata(0)["region_code"] == region:
						return true
	return false


func create_region(on_lang: String, region_code: String) -> void:
	var language: TreeItem = get_language_item(on_lang)
	var region: TreeItem = language.create_child()
	region.set_text(0, TranslationServer.get_country_name(region_code))
	region.add_button(0, get_theme_icon("Remove", "EditorIcons"), 1, false, "Delete Region")
	region.set_metadata(0, {"region_code": region_code})
	region.set_text_overrun_behavior(0, TextServer.OVERRUN_TRIM_ELLIPSIS)


func get_language_item(lang_code: String) -> TreeItem:
	for item in get_root().get_children():
		if item.get_metadata(0)["language_code"] == lang_code:
			return item
	return null


func search_language(text: String) -> void:
	for language in get_root().get_children():
		var lang_visible: bool = false
		for region in language.get_children():
			if region.get_text(0).containsn(text) or region.get_metadata(0)["region_code"].containsn(text):
				region.visible = true
				if not lang_visible:
					lang_visible = true
		
		language.visible = lang_visible or language.get_text(0).containsn(text) or language.get_metadata(0)["language_code"].containsn(text)


func set_default_language(lang_code: String) -> void:
	var item: TreeItem = get_language_item(lang_code)
	if item != null:
		main_language = item


func get_default_language() -> String:
	if main_language == null:
		return ""
	return main_language.get_metadata(0)["language_code"]


func get_used_language_codes() -> PackedStringArray:
	var used_codes: PackedStringArray = []
	
	for language in get_root().get_children():
		used_codes.append(language.get_metadata(0)["language_code"])
	return used_codes


func is_lang_selected() -> bool:
	return active_language != null


func as_map() -> Dictionary[String, Dictionary]:
	var map: Dictionary[String, Dictionary] = {}
	
	for main_language in get_root().get_children():
		var regions: Dictionary[String, Variant] = {}
		for region in main_language.get_children():
			regions[region.get_metadata(0)["region_code"]] = null
		map[main_language.get_metadata(0)["language_code"]] = regions
	
	return map


func clear_languages() -> void:
	main_language = null
	active_language = null
	active_region = null
	for item in get_root().get_children():
		item.free()
