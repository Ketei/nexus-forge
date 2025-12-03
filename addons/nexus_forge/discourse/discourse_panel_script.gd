@tool
extends PanelContainer


signal new_conversation_pressed
signal open_conversation_pressed
signal save_conversation_pressed
signal change_default_language_pressed
signal close_conversation_pressed
signal localization_window_pressed
signal set_locale_group_pressed
signal check_for_issues_pressed
signal play_current_dialog_pressed


enum DiscourseFileMenuID {
	NEW_DIALOG,
	OPEN_DIALOG,
	SAVE_DIALOG,
	CLOSE_DIALOG,
	CHANGE_LANGUAGE,
	SET_LOCALE_GROUP,
	CHECK_ISSUES,
	PLAY_CURRENT_DIALOG,
	}

var _disabled: bool = true

var no_dialog_label: Label = null
var discourse_graph_edit: GraphEdit = null
var node_menu: MenuButton
var file_menu: MenuButton
var save_btn: Button
var play_current_dialog_btn: Button
var switch_localization: Button
var localization_menu: OptionButton

var base_language: String = ""
var current_language: String = ""
var current_country: String = "base":
	set(new_country):
		current_country = "base" if new_country.is_empty() else new_country

var locale_map: Dictionary[String, PackedStringArray] = {}


func _on_node_deleted(uuid: StringName) -> void:
	if localization.has(uuid):
		localization.erase(uuid)
		#conversation_changed.emit()


var localization: Dictionary[StringName, Dictionary] = {
	#"uuid": {
		#"node": "nodepath",
		#"localization": {
			#"en": {
				#"base": {"dialog": "Butts"},
				#"UK": {"options": ["Butts"]},
				#"US": {"dialog": "Hello World"}
			#}},
	#"uuid_2": {
		#"node": "node",
		#"lcoalization": {
			#"common": {"dialog": "2 + 2"}}}}
}


func _ready() -> void:
	if Engine.is_editor_hint() and owner == get_tree().edited_scene_root:
		return
	var content_container: VBoxContainer = VBoxContainer.new()
	var menu_panel: PanelContainer = PanelContainer.new()
	var menu_container: HBoxContainer = HBoxContainer.new()
	file_menu = MenuButton.new()
	node_menu = MenuButton.new()
	var file_popup: PopupMenu = file_menu.get_popup()
	var node_popup: PopupMenu = node_menu.get_popup()
	save_btn = Button.new()
	var open_btn: Button = Button.new()
	var toggle_visible_grid: Button = Button.new()
	var toggle_snap: Button = Button.new()
	var snap_distance: SpinBox = SpinBox.new()
	var localization_container: HBoxContainer = HBoxContainer.new()
	var localization_label: Label = Label.new()
	localization_menu = OptionButton.new()
	switch_localization = Button.new()
	var toggle_minimap: Button = Button.new()
	var sort_nodes: Button = Button.new()
	var graph_panel: PanelContainer = PanelContainer.new()
	no_dialog_label = Label.new()
	
	var new_style: StyleBoxFlat = StyleBoxFlat.new()
	
	# --- Node Menu Items ---
	var dialogs_submenu: PopupMenu = PopupMenu.new()
	var data_submenu: PopupMenu = PopupMenu.new()
	var setting_submenu: PopupMenu = PopupMenu.new()
	
	node_menu.disabled = true
	
	dialogs_submenu.min_size.x = 120
	
	dialogs_submenu.add_item("Dialog", DiscourseGraphNode.DialogueNodeType.DIALOG)
	dialogs_submenu.add_item("Options", DiscourseGraphNode.DialogueNodeType.OPTIONS)
	dialogs_submenu.add_separator("Flow")
	dialogs_submenu.add_item("Random", DiscourseGraphNode.DialogueNodeType.RANDOM)
	dialogs_submenu.add_item("Branch", DiscourseGraphNode.DialogueNodeType.BRANCH)
	dialogs_submenu.add_item("Match", DiscourseGraphNode.DialogueNodeType.MATCH)
	dialogs_submenu.add_item("Merge", DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE)
	dialogs_submenu.add_item("Pause", DiscourseGraphNode.DialogueNodeType.PAUSE)
	dialogs_submenu.add_separator("Anchors")
	dialogs_submenu.add_item("Pointer", DiscourseGraphNode.DialogueNodeType.ANCHOR_POINTER)
	dialogs_submenu.add_item("Target", DiscourseGraphNode.DialogueNodeType.ANCHOR)
	dialogs_submenu.add_separator()
	dialogs_submenu.add_item("Event", DiscourseGraphNode.DialogueNodeType.EVENT)
	dialogs_submenu.add_item("End", DiscourseGraphNode.DialogueNodeType.DIALOG_END)
	
	data_submenu.add_item("Value", DiscourseGraphNode.DialogueNodeType.VALUE)
	data_submenu.add_item("Variable", DiscourseGraphNode.DialogueNodeType.VARIABLE_GET)
	data_submenu.add_item("Random", DiscourseGraphNode.DialogueNodeType.RANDOM_VALUE)
	data_submenu.add_item("Localized Text", DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT)
	data_submenu.add_separator()
	data_submenu.add_item("Condition Value", DiscourseGraphNode.DialogueNodeType.CONDITION_SELECT)
	data_submenu.add_item("Comparation", DiscourseGraphNode.DialogueNodeType.COMPARATION)
	data_submenu.add_separator()
	data_submenu.add_item("Event", DiscourseGraphNode.DialogueNodeType.DATA_EVENT)
	data_submenu.add_item("Signal", DiscourseGraphNode.DialogueNodeType.SIGNAL)
	data_submenu.add_item("Method", DiscourseGraphNode.DialogueNodeType.CALLABLE)
	data_submenu.add_item("Method Return", DiscourseGraphNode.DialogueNodeType.CALLABLE_RETURN)
	data_submenu.add_separator()
	data_submenu.add_item("Type Guard", DiscourseGraphNode.DialogueNodeType.TYPE_GUARD)
	
	setting_submenu.add_item("Dialog", DiscourseGraphNode.DialogueNodeType.SETTINGS_DIALOG)
	setting_submenu.add_item("Character", DiscourseGraphNode.DialogueNodeType.SETTINGS_CHARACTER)
	setting_submenu.add_item("Option", DiscourseGraphNode.DialogueNodeType.SETTINGS_OPTION)
	
	node_popup.add_submenu_node_item(
			"Conversation",
			dialogs_submenu,
			100)
	node_popup.add_submenu_node_item(
			"Data",
			data_submenu,
			100)
	node_popup.add_submenu_node_item(
			"Settings",
			setting_submenu,
			100)
	node_popup.add_separator()
	node_popup.add_item("Comment", DiscourseGraphNode.DialogueNodeType.COMMENT)
	node_popup.add_item("Resource", DiscourseGraphNode.DialogueNodeType.RESOURCE)
	node_popup.add_separator()
	node_popup.add_item("Frame", 1000)
	
	no_dialog_label.name = &"NoDialogLbl"
	no_dialog_label.text = "No conversation selected"
	no_dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	discourse_graph_edit = preload("res://addons/nexus_forge/discourse/discourse_graph_edit.gd").new()
	discourse_graph_edit.name = &"DiscourseGraphEdit"
	discourse_graph_edit.visible = false
	
	graph_panel.name = &"GraphPanel"
	graph_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_panel.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	
	menu_panel.name = &"MenuPanel"
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	empty.content_margin_top = 4
	empty.content_margin_bottom = 4
	menu_panel.add_theme_stylebox_override(&"panel", empty)
	
	content_container.name = &"ContentContainer"
	
	file_menu.name = &"FileMenuButton"
	file_menu.switch_on_hover = true
	file_menu.text = "Discourse"
	
	node_menu.name = &"NodeMenuButton"
	node_menu.switch_on_hover = true
	node_menu.text = "Create"
	
	save_btn.icon = get_theme_icon("Save", "EditorIcons")
	save_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_btn.expand_icon = true
	save_btn.tooltip_text = "Save Dialog"
	save_btn.custom_minimum_size = Vector2(32.0, 32.0)
	save_btn.add_theme_constant_override(&"icon_max_width", 24)
	save_btn.disabled = true
	
	open_btn.icon = get_theme_icon("Load", "EditorIcons")
	open_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	open_btn.expand_icon = true
	open_btn.tooltip_text = "Open Dialog"
	open_btn.custom_minimum_size = Vector2(32.0, 32.0)
	open_btn.add_theme_constant_override(&"icon_max_width", 24)
	
	toggle_visible_grid.icon = get_theme_icon("GridToggle", "EditorIcons")
	toggle_visible_grid.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toggle_visible_grid.expand_icon = true
	toggle_visible_grid.tooltip_text = "Toggle grid"
	toggle_visible_grid.custom_minimum_size = Vector2(32.0, 32.0)
	toggle_visible_grid.toggle_mode = true
	toggle_visible_grid.button_pressed = true
	toggle_visible_grid.add_theme_constant_override(&"icon_max_width", 24)
	toggle_visible_grid.toggled.connect(_on_show_grid_toggled)
	toggle_visible_grid.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	
	toggle_snap.icon = get_theme_icon("SnapGrid", "EditorIcons")
	toggle_snap.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toggle_snap.expand_icon = true
	toggle_snap.tooltip_text = "Toggle grid snap"
	toggle_snap.custom_minimum_size = Vector2(32.0, 32.0)
	toggle_snap.toggle_mode = true
	toggle_snap.button_pressed = true
	toggle_snap.add_theme_constant_override(&"icon_max_width", 24)
	toggle_snap.toggled.connect(_on_grid_snapping_toggled)
	toggle_snap.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	
	snap_distance.min_value = 5.0
	snap_distance.value = 20
	snap_distance.tooltip_text = "Snapping distance"
	snap_distance.value_changed.connect(_on_snapping_distance_value_changed)
	
	toggle_minimap.icon = get_theme_icon("GridMinimap", "EditorIcons")
	toggle_minimap.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toggle_minimap.expand_icon = true
	toggle_minimap.tooltip_text = "Toggle minimap"
	toggle_minimap.custom_minimum_size = Vector2(32.0, 32.0)
	toggle_minimap.toggle_mode = true
	toggle_minimap.button_pressed = true
	toggle_minimap.add_theme_constant_override(&"icon_max_width", 24)
	toggle_minimap.toggled.connect(_on_minimap_toggled)
	toggle_minimap.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	
	sort_nodes.icon = get_theme_icon("layout", "GraphEdit")
	sort_nodes.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sort_nodes.expand_icon = true
	sort_nodes.tooltip_text = "Arrange nodes"
	sort_nodes.custom_minimum_size = Vector2(32.0, 32.0)
	sort_nodes.add_theme_constant_override(&"icon_max_width", 24)
	sort_nodes.pressed.connect(_on_sort_nodes_pressed)
	sort_nodes.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	
	play_current_dialog_btn = Button.new()
	play_current_dialog_btn.icon = get_theme_icon("Play", "EditorIcons")
	play_current_dialog_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#sort_nodes.expand_icon = true
	play_current_dialog_btn.disabled = true
	play_current_dialog_btn.tooltip_text = "Play current dialog"
	play_current_dialog_btn.custom_minimum_size = Vector2(32.0, 32.0)
	play_current_dialog_btn.add_theme_constant_override(&"icon_max_width", 24)
	play_current_dialog_btn.pressed.connect(_on_play_current_dialog_pressed)
	play_current_dialog_btn.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	
	
	localization_label.text = "Localization:"
	
	localization_menu.flat = true
	localization_menu.alignment = HORIZONTAL_ALIGNMENT_LEFT
	localization_menu.fit_to_longest_item = false
	localization_menu.disabled = true
	localization_menu.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
	localization_menu.custom_minimum_size = Vector2(140.0, 32.0)
	
	switch_localization.icon = get_theme_icon("Translation", "EditorIcons")
	switch_localization.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	switch_localization.tooltip_text = "Switch to localization window"
	switch_localization.custom_minimum_size = Vector2(32.0, 32.0)
	switch_localization.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	switch_localization.disabled = true
	
	localization_container.alignment = BoxContainer.ALIGNMENT_END
	localization_container.size_flags_horizontal = Control.SIZE_SHRINK_END + Control.SIZE_EXPAND
	
	new_style.bg_color = Color(0.212, 0.239, 0.29)
	new_style.content_margin_left = 8
	new_style.content_margin_right = 8
	new_style.content_margin_bottom = 8
	new_style.content_margin_top = 4
	
	add_theme_stylebox_override(&"panel", new_style)
	
	file_popup.add_icon_item(
			null,
			"New",
			DiscourseFileMenuID.NEW_DIALOG)
	file_popup.add_icon_item(
			null,
			"Open",
			DiscourseFileMenuID.OPEN_DIALOG)
	file_popup.add_icon_item(
			null,
			"Save",
			DiscourseFileMenuID.SAVE_DIALOG)
	file_popup.add_separator()
	file_popup.add_item(
			"Play current dialog",
			DiscourseFileMenuID.PLAY_CURRENT_DIALOG)
	file_popup.add_item(
			"Check for issues",
			DiscourseFileMenuID.CHECK_ISSUES)
	file_popup.add_separator()
	file_popup.add_item(
			"Set file locale group",
			DiscourseFileMenuID.SET_LOCALE_GROUP)
	file_popup.add_separator()
	file_popup.add_item(
			"Change default language",
			DiscourseFileMenuID.CHANGE_LANGUAGE)
	file_popup.add_separator()
	file_popup.add_icon_item(
			null,
			"Close",
			DiscourseFileMenuID.CLOSE_DIALOG)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.SAVE_DIALOG),
			true)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.CHECK_ISSUES),
					true)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.CLOSE_DIALOG),
			true)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.SET_LOCALE_GROUP),
			true)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.PLAY_CURRENT_DIALOG),
			true)
	
	var menu_items: Array = [
		file_menu,
		node_menu,
		VSeparator.new(),
		save_btn,
		open_btn,
		VSeparator.new(),
		toggle_visible_grid,
		toggle_snap,
		snap_distance,
		VSeparator.new(),
		toggle_minimap,
		sort_nodes,
		VSeparator.new(),
		play_current_dialog_btn,
		localization_container]
	
	localization_container.add_child(localization_label)
	localization_container.add_child(localization_menu)
	localization_container.add_child(switch_localization)
	
	for menu_item in menu_items:
		menu_container.add_child(menu_item)
	
	menu_panel.add_child(menu_container)
	
	graph_panel.add_child(no_dialog_label)
	graph_panel.add_child(discourse_graph_edit)
	
	content_container.add_child(menu_panel)
	content_container.add_child(graph_panel)
	
	add_child(content_container)
	
	discourse_graph_edit.node_deleted.connect(_on_node_deleted)
	discourse_graph_edit.localization_enabled.connect(_on_node_localized)
	discourse_graph_edit.localized_text_created.connect(_on_node_localized)
	dialogs_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	data_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	setting_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	node_popup.id_pressed.connect(_on_create_dialog_id_pressed)
	switch_localization.pressed.connect(localization_window_pressed.emit)
	file_popup.id_pressed.connect(_on_file_menu_id_pressed)
	localization_menu.item_selected.connect(_on_localization_selected)


#func _ready() -> void:
	#await get_tree().create_timer(1.0).timeout
	#set_graph_edit_visible(true)
	#set_conversation_options_enabled(true)
	#discourse_graph_edit.fix_scroll_offset_for_new(size)
	

func _on_play_current_dialog_pressed() -> void:
	play_current_dialog_pressed.emit()



func _on_localization_selected(idx: int) -> void:
	if not current_language.is_empty():
		save_current_locale()
	
	if idx == -1:
		current_language = ""
		current_country = ""
		localization_menu.tooltip_text = ""
	else:
		var locale_data: Dictionary = localization_menu.get_item_metadata(idx)
		current_language = locale_data["language_code"]
		current_country = locale_data["country_code"]
		set_localization(locale_data["language_code"], locale_data["country_code"])
		localization_menu.tooltip_text = localization_menu.get_item_text(idx)


func _on_file_menu_id_pressed(id: int) -> void:
	match id as DiscourseFileMenuID:
		DiscourseFileMenuID.NEW_DIALOG:
			new_conversation_pressed.emit()
		DiscourseFileMenuID.OPEN_DIALOG:
			open_conversation_pressed.emit()
		DiscourseFileMenuID.SAVE_DIALOG:
			save_conversation_pressed.emit()
		DiscourseFileMenuID.CLOSE_DIALOG:
			close_conversation_pressed.emit()
		DiscourseFileMenuID.CHANGE_LANGUAGE:
			change_default_language_pressed.emit()
		DiscourseFileMenuID.SET_LOCALE_GROUP:
			set_locale_group_pressed.emit()
		DiscourseFileMenuID.CHECK_ISSUES:
			check_for_issues_pressed.emit()
		DiscourseFileMenuID.PLAY_CURRENT_DIALOG:
			play_current_dialog_pressed.emit()


func _on_create_dialog_id_pressed(id: int) -> void:
	if id != 1000:
		discourse_graph_edit.add_dialog_node_to_graph(
				id as DiscourseGraphNode.DialogueNodeType)
	else:
		discourse_graph_edit.add_frame_to_graph()
	
	#conversation_changed.emit()


func _on_show_grid_toggled(toggle: bool) -> void:
	discourse_graph_edit.show_grid = toggle


func _on_grid_snapping_toggled(toggle: bool) -> void:
	discourse_graph_edit.snapping_enabled = toggle


func _on_snapping_distance_value_changed(distance: int) -> void:
	discourse_graph_edit.snapping_distance = distance


func _on_minimap_toggled(toggle: bool) -> void:
	discourse_graph_edit.minimap_enabled = toggle


func _on_sort_nodes_pressed() -> void:
	discourse_graph_edit.arrange_nodes()
	#conversation_changed.emit()


func _on_node_localized(node: DiscourseGraphNode) -> void:
	var uuid: StringName = node.get_node_uuid()
	var original_data: Dictionary = {}
	var localization_data: Dictionary = {}
	
	match node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			original_data["dialog"] = node.get_dialog_text()
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			original_data["options"] = node.get_options()
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			original_data["text"] = node.get_text()
	
	for language in locale_map.keys():
		localization_data[language] = {"base": original_data.duplicate(true)}
		
		for country in locale_map[language]:
			localization_data[language][country] = original_data.duplicate(true)
	
	localization[uuid] = {
		"node": node,
		"localization": localization_data}
	
	#conversation_changed.emit()


func _locale_sort_custom(locale_a: Dictionary, locale_b: Dictionary):
	var language_comp: int = locale_a["language_name"].naturalnocasecmp_to(locale_b["language_name"])
	
	if language_comp == 0:
		return locale_a["country_code"].naturalnocasecmp_to(locale_b["country_code"]) < 0
	else:
		return language_comp < 0


func set_locale_map(new_map: Dictionary[String, PackedStringArray]) -> void:
	for existing_language in locale_map.keys():
		if not new_map.has(existing_language):
			remove_locale(existing_language)
		else:
			for existing_region in locale_map[existing_language]:
				if not new_map[existing_language].has(existing_region):
					remove_locale(existing_language, existing_region)
	
	for language in new_map.keys():
		if locale_map.has(language):
			for region in new_map:
				if not locale_map[language].has(region):
					add_locale(language, region)
		else:
			add_locale(language)
			for region in new_map[language]:
				add_locale(language, region)


func clear_locales() -> void:
	for locale in locale_map.keys():
		remove_locale(locale)
	
	locale_map.clear()


func remove_locale(language: String, region: String = "base") -> void:
	if not locale_map.has(language) or not locale_map[language].has(region):
		return
	
	if region == "base":
		var current: int = localization_menu.selected
		var new_index: int = localization_menu.selected
		var item_count: int = localization_menu.item_count
		locale_map.erase(language)
		for item_idx in range(localization_menu.item_count):
			var mtdt: Dictionary = localization_menu.get_item_metadata(item_idx)
			if mtdt["language_code"] != language:
				continue
			if new_index == item_idx:
				new_index = clampi(
					item_idx - 1,
					-1 if localization_menu.item_count == 1 else 0,
					item_count - 2)
			localization_menu.remove_item(item_idx)
		
		if current != new_index:
			if new_index != -1:
				var metadata: Dictionary = localization_menu.get_item_metadata(new_index)
				localization_menu.select(new_index)
				current_language = metadata["language_code"]
				current_country = metadata["country_code"]
				set_localization(current_language, current_country)
				localization_menu.tooltip_text = localization_menu.get_item_text(new_index)
			else:
				current_language = base_language
				current_country = "base"
				localization_menu.tooltip_text = ""
	else:
		locale_map[language].remove_at(locale_map[language].find(region))
		for item_idx in range(localization_menu.item_count):
			var mtdt: Dictionary = localization_menu.get_item_metadata(item_idx)
			if mtdt["language_code"] != language or mtdt["country_code"] != region:
				continue
			if item_idx == localization_menu.selected:
				var new_idx: int = clampi(
						item_idx - 1,
						-1 if localization_menu.item_count == 1 else 0,
						localization_menu.item_count - 2)
				if new_idx != -1:
					localization_menu.select(new_idx)
					current_language = mtdt["language_code"]
					current_country = mtdt["country_code"]
					set_localization(current_language, current_country)
					localization_menu.tooltip_text = localization_menu.get_item_text(new_idx)
				else:
					current_language = ""
					current_country = ""
					localization_menu.tooltip_text = ""
			localization_menu.remove_item(item_idx)
			break


func add_locale(language: String, region: String = "base") -> void:
	if current_language == base_language and current_country == "base":
		save_current_locale()
	
	var selected_language: String = ""
	var selected_country: String = ""
	var existing_locales: Array[Dictionary] = []
	
	if localization_menu.selected != -1:
		var item_meta: Dictionary = localization_menu.get_item_metadata(localization_menu.selected)
		selected_language = item_meta["language_code"]
		selected_country = item_meta["country_code"]
	
	for item in range(localization_menu.item_count):
		var item_meta: Dictionary = localization_menu.get_item_metadata(item)
		if item_meta["language_code"] == language and item_meta["country_code"] == region:
			return
		existing_locales.append(item_meta)
	
	existing_locales.append({
		"language_code" = language,
		"language_name" = TranslationServer.get_language_name(language),
		"country_code" = region})
	
	existing_locales.sort_custom(_locale_sort_custom)
	
	localization_menu.clear()
	
	var idx: int = -1
	for existing_locale in existing_locales:
		var display_text: String = existing_locale["language_name"] if\
				existing_locale["country_code"] == "base" else\
				existing_locale["language_name"] + " (" + existing_locale["country_code"] + ")"
		idx += 1
		localization_menu.add_item(display_text)
		localization_menu.set_item_metadata(idx, existing_locale)
		if existing_locale["language_code"] == selected_language and existing_locale["country_code"] == selected_country:
			localization_menu.select(idx)
			localization_menu.tooltip_text = display_text
	
	if selected_language.is_empty() and selected_country.is_empty():
		localization_menu.tooltip_text = localization_menu.get_item_text(0)
	
	for uuid in localization.keys():
		if not localization[uuid]["localization"].has(language):
			localization[uuid]["localization"][language] = {}
		match localization[uuid]["node"].node_type:
			DiscourseGraphNode.DialogueNodeType.DIALOG:
				localization[uuid]["localization"][language][region] = {"dialog": localization[uuid]["localization"][base_language]["base"]["dialog"]}
			DiscourseGraphNode.DialogueNodeType.OPTIONS:
				localization[uuid]["localization"][language][region] = {"options": localization[uuid]["localization"][base_language]["base"]["options"].duplicate()}
			DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				localization[uuid]["localization"][language][region] = {"text": localization[uuid]["localization"][base_language]["base"]["text"]}


# Sets options relevant to having a conversation loaded or not (ex. save/close)
func set_conversation_options_enabled(are_enabled: bool) -> void:
	var disabled: bool = !are_enabled
	var file_popup: PopupMenu = file_menu.get_popup()
	
	node_menu.disabled = disabled
	switch_localization.disabled = disabled
	save_btn.disabled = disabled
	localization_menu.disabled = disabled
	play_current_dialog_btn.disabled = disabled
	
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.SAVE_DIALOG),
					disabled)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.SET_LOCALE_GROUP),
			disabled)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.PLAY_CURRENT_DIALOG),
			disabled)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.CHECK_ISSUES),
			disabled)
	
	enable_close_dialog(are_enabled)
	
	_disabled = disabled


func are_conversation_options_enabled() -> bool:
	return not _disabled


func set_graph_edit_visible(graph_visible: bool) -> void:
	no_dialog_label.visible = not graph_visible
	discourse_graph_edit.visible = graph_visible
	if graph_visible and discourse_graph_edit.size != size:
		discourse_graph_edit.size = size


func set_base_language(language: String) -> void:
	base_language = language


func erase_localization(uuid: StringName) -> void:
	localization.erase(uuid)


func set_localization(language: String, country: String = "") -> void:
	current_language = language
	current_country = country
	
	if country.is_empty():
		country = "base"
	
	for uuid in localization.keys():
		var node: DiscourseGraphNode = localization[uuid]["node"]
		match node.node_type:
			DiscourseGraphNode.DialogueNodeType.DIALOG:
				node.set_dialog_text(localization[uuid]["localization"][language][country]["dialog"])
			DiscourseGraphNode.DialogueNodeType.OPTIONS:
				for option_idx in range(localization[uuid]["localization"][language][country]["options"].size()):
					node.set_option_text(
							option_idx + 1,
							localization[uuid]["localization"][language][country]["options"][option_idx])
			DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				node.set_text(
						localization[uuid]["localization"][language][country]["text"])
			_:
				continue


func set_localization_dialog(uuid: StringName, dialog: String, language: String, region: String = "base") -> void:
	if language.is_empty():
		localization[uuid]["localization"]["common"]["dialog"] = dialog
	else:
		localization[uuid]["localization"][language][region]["dialog"] = dialog


func set_localization_text(uuid: StringName, text: String, language: String, region: String = "base") -> void:
	if language.is_empty():
		localization[uuid]["localization"]["common"]["text"] = text
	else:
		localization[uuid]["localization"][language][region]["text"] = text


func set_localization_options(uuid: StringName, options: Array[String], language: String, region: String = "base") -> void:
	var current_count: int = 0
	var given_count: int = options.size()
	var given_options: Array[String] = options.duplicate()
	if language.is_empty():
		current_count = localization[uuid]["localization"]["common"]["options"].size()
		if current_count < given_count:
			given_options.resize(current_count)
		elif given_count < current_count:
			for missing in range(given_count, current_count):
				given_options.append(localization[uuid]["localization"]["common"]["options"][missing])
		localization[uuid]["localization"]["common"]["options"] = given_options
	else:
		current_count = localization[uuid]["localization"][language][region]["options"].size()
		if current_count < given_count:
			given_options.resize(current_count)
		elif given_count < current_count:
			for missing in range(given_count, current_count):
				given_options.append(localization[uuid]["localization"][language][region]["options"][missing])
		localization[uuid]["localization"][language][region]["options"] = given_options


func load_conversation(conversation: EditorDiscourseDialog) -> bool:
	#for language in conversation.locale_map.keys():
		#if not has_locale(language):
			#add_locale(language)
		#for region in conversation.locale_map[language]:
			#if not has_locale(language, region):
				#add_locale(language, region)
	locale_map.clear()
	localization.clear()
	
	if conversation == null:
		discourse_graph_edit.clear_dialog_nodes()
		return false
	
	locale_map.assign(conversation.locale_map.duplicate(true))
	#set_locale_map(conversation.locale_map)
	
	
	# Clears the dialog nodes and loads conversation data.
	# Should trigger registry signals for this node to catch.
	var needs_resaving: bool = discourse_graph_edit.load_conversation_data(
			conversation,
			current_language,
			current_country)
	
	var data: Dictionary[StringName, Dictionary] = conversation.get_node_localization_data()
	
	for node_uuid in data.keys():
		for language in data[node_uuid].keys():
			if not localization[node_uuid]["localization"].has(language):
				localization[node_uuid]["localization"][language] = {}
			for region in data[node_uuid][language].keys():
				localization[node_uuid]["localization"][language][region] = data[node_uuid][language][region]
		
	return needs_resaving


func has_locale(language: String, region: String = "base") -> bool:
	if locale_map.has(language):
		return region == "base" or locale_map[language].has(region)
	return false


func get_localization_argument(uuid: StringName, language: String, region: String = "base") -> Variant:
	if region.is_empty():
		region = "base"
	match localization[uuid]["node"].node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			if language.is_empty():
				return localization[uuid]["localization"]["common"]["dialog"]
			else:
				return localization[uuid]["localization"][language][region]["dialog"]
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			if language.is_empty():
				return localization[uuid]["localization"]["common"]["options"]
			else:
				return localization[uuid]["localization"][language][region]["options"]
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			if language.is_empty():
				return localization[uuid]["localization"]["common"]["text"]
			else:
				return localization[uuid]["localization"][language][region]["text"]
		_:
			return ""


func save_current_locale() -> void:
	for uuid in localization.keys():
		var node: DiscourseGraphNode = localization[uuid]["node"]
		match node.node_type:
			DiscourseGraphNode.DialogueNodeType.DIALOG:
				localization[uuid]["localization"][current_language][current_country]["dialog"] = node.get_dialog_text()
			DiscourseGraphNode.DialogueNodeType.OPTIONS:
				localization[uuid]["localization"][current_language][current_country]["options"] = node.get_options()
			DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				localization[uuid]["localization"][current_language][current_country]["text"] = node.get_text()


func enable_close_dialog(enabled: bool) -> void:
	var popup: PopupMenu = file_menu.get_popup()
	popup.set_item_disabled(popup.get_item_index(DiscourseFileMenuID.CLOSE_DIALOG), not enabled)


func get_base_language_option_index() -> int:
	for item in range(localization_menu.item_count):
		var metadata: Dictionary = localization_menu.get_item_metadata(item)
		if metadata["language_code"] == base_language and metadata["country_code"] == "base":
			return item
	return -1
