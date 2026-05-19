@tool
extends PanelContainer


enum TreeButtonID {
	DELETE,
	NEW_PHRASE_ARGUMENT,
	RENAME_LOCALIZED_NODE}

# ------------------
enum DiscourseFileMenuID {
	NEW_DIALOG,
	OPEN_DIALOG,
	SAVE_DIALOG,
	CLOSE_DIALOG,
	CHANGE_LANGUAGE,
	SET_LOCALE_GROUP,
	CHECK_ISSUES,
	PLAY_CURRENT_DIALOG,
	DISPLAY_DIALOG_ID_FIELD,
	}
# ------------------

var active_conversation: EditorDiscourseDialog = null

var localization_node_selected: DiscourseGraphNode = null

var listen_offset: bool = true

var selected_key: LineEdit = null
var selected_format: String = ""

var _unsaved: bool = false

# ----------------------------
var _conversation_options_disabled: bool = true

var base_language: String = ""
var current_locale: String = ""
# ----------------------------

# --- Discourse Graph ---
@onready var conversation_tree: Tree = $MainSplitContainer/MainSidebar/SidebarSplitContainer/ConversationContainer/ConversationTree
@onready var node_search_ln_edt: LineEdit = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/SearchHbox/NodeSearchLnEdt
@onready var discourse_nodes_tree: Tree = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/NodesTree
@onready var new_folder_button: Button = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/SearchHbox/NewFolderButton
@onready var hide_issues_btn: Button = $MainSplitContainer/DiscourseSplitContainer/ErrorContainer/IssuesVBox/HeaderContainer/HideIssuesBtn
@onready var issues_tree: Tree = $MainSplitContainer/DiscourseSplitContainer/ErrorContainer/IssuesVBox/IssuesTree
@onready var error_container: PanelContainer = $MainSplitContainer/DiscourseSplitContainer/ErrorContainer
@onready var discourse_split_container: VSplitContainer = $MainSplitContainer/DiscourseSplitContainer
@onready var dialog_id_container: HBoxContainer = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/DialogIDContainer
@onready var dialog_id_ln_edt: LineEdit = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/DialogIDContainer/DialogIDLnEdt

# --- Localization Window ---
@onready var new_language_btn: Button = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LanguagesSplitContainer/LanguagesContainer/HeaderContainer/NewLanguageBtn
@onready var search_language_ln_edt: LineEdit = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LanguagesSplitContainer/LanguagesContainer/SearchLanguageLnEdt
@onready var languages_tree: Tree = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LanguagesSplitContainer/LanguagesContainer/LanguagesTree
@onready var search_nodes_ln_edt: LineEdit = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LanguagesSplitContainer/NodesContainer/SearchNodesLnEdt
@onready var localization_nodes_tree: Tree = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LanguagesSplitContainer/NodesContainer/NodesTree
@onready var base_text_edt: TextEdit = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer/BasePanelContainer/BaseContainer/BaseTextEdt
@onready var translation_txt_box: TextEdit = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer/TranslationPanel/TranslationContainer/TranslationTxtBox

@onready var locale_label: Label = $LocalizationContainer/LocaleLabel
@onready var return_discourse_btn: Button = $LocalizationContainer/MainSplitContainer/PhrasesContainer/HeaderPanel/PhrasesHeader/ReturnDiscourseBtn
@onready var choices_container: VBoxContainer = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer/ChoicesScroller/ChoicesContainer

# --- Phrases ---
@onready var key_container: VBoxContainer = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/KeyBoxContainer/KeyScroll/KeySplitContainer/KeyContainer
@onready var text_container: VBoxContainer = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/KeyBoxContainer/KeyScroll/KeySplitContainer/TextContainer
@onready var case_node_container: VBoxContainer = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/KeyScroll/CasesSplit/CaseContainer/CaseNodeContainer
@onready var result_node_container: VBoxContainer = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/KeyScroll/CasesSplit/ResultContainer/ResultNodeContainer
@onready var default_case_ln_edt: LineEdit = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/KeyScroll/CasesSplit/ResultContainer/DefaultCaseLnEdt
@onready var argument_opt_btn: OptionButton = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/ArgumentOptBtn
@onready var new_case_btn: Button = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/HeaderContainer/NewCaseBtn
@onready var new_text_button: Button = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/KeyBoxContainer/HBoxContainer/NewTextButton
@onready var search_case_ln_edt: LineEdit = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/HeaderContainer/SearchCaseLnEdt
@onready var key_display_label: Label = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer/CaseKeyContainer/KeyDisplayLabel
@onready var key_box_container: VBoxContainer = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/KeyBoxContainer
@onready var case_box_container: VBoxContainer = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer
@onready var save_case_btn: Button = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer/CaseKeyContainer/SaveCaseBtn
@onready var search_text_ln_edt: LineEdit = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/KeyBoxContainer/HBoxContainer/SearchTextLnEdt
@onready var key_header_split: HSplitContainer = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/KeyBoxContainer/KeyHeaderSplit
@onready var key_split_container: HSplitContainer = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/KeyBoxContainer/KeyScroll/KeySplitContainer
@onready var case_header_split: HSplitContainer = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/CaseHeaderSplit
@onready var cases_split: HSplitContainer = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/KeyScroll/CasesSplit

# ----------------------------------------------

@onready var no_dialog_label: Label = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/GraphPanel/NoDialogLbl
@onready var discourse_graph_edit: GraphEdit = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/GraphPanel/DiscourseGraphEdit
var node_popup: PopupMenu = null
var file_popup: PopupMenu = null
@onready var node_menu_btn: MenuButton = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/NodeMenuBtn
@onready var save_btn: Button = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/SaveBtn
@onready var play_current_dialog_btn: Button = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/PlayDialogBtn
@onready var switch_localization: Button = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/LocalizationContainer/SwitchLocaleBtn
@onready var localization_menu: OptionButton = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/LocalizationContainer/LocalizationMenu
#@onready var tool_menu: MenuBar = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/MenuBar


@onready var snap_distance_spn_bx: SpinBox = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/SnapDistanceSpnBx


#func _ready() -> void:
	#ready_plugin()


func ready_plugin() -> void:
	node_popup = node_menu_btn.get_popup()
	file_popup = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/FileMenuBtn.get_popup()
	#var file_popup: PopupMenu = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuVBox/MenuBar/FileMenu
	#var node_popup: PopupMenu = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuVBox/MenuBar/NodeMenu
	var open_btn: Button = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/OpenBtn
	var toggle_grid_btn: Button = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/ToggleGridBtn
	var toggle_snap_btn: Button = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/ToggleSnapBtn
	var toggle_minimap_btn: Button = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/ToggleMinimapBtn
	var sort_nodes_btn: Button = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/SortNodesBtn
	
	# --- Node Menu Items ---
	var dialogs_submenu: PopupMenu = PopupMenu.new()
	var data_submenu: PopupMenu = PopupMenu.new()
	var setting_submenu: PopupMenu = PopupMenu.new()
	
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
	data_submenu.add_separator()
	data_submenu.add_item("Metadata", DiscourseGraphNode.DialogueNodeType.METADATA)
	
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
	
	save_btn.icon = get_theme_icon("Save", "EditorIcons")
	
	open_btn.icon = get_theme_icon("Load", "EditorIcons")
	
	toggle_grid_btn.icon = get_theme_icon("GridToggle", "EditorIcons")
	
	toggle_grid_btn.toggled.connect(_on_show_grid_toggled)
	
	toggle_snap_btn.icon = get_theme_icon("SnapGrid", "EditorIcons")
	
	toggle_snap_btn.toggled.connect(_on_grid_snapping_toggled)
	
	snap_distance_spn_bx.value_changed.connect(_on_snapping_distance_value_changed)
	
	toggle_minimap_btn.icon = get_theme_icon("GridMinimap", "EditorIcons")
	
	toggle_minimap_btn.toggled.connect(_on_minimap_toggled)
	
	sort_nodes_btn.icon = get_theme_icon("layout", "GraphEdit")
	
	sort_nodes_btn.pressed.connect(_on_sort_nodes_pressed)
	
	play_current_dialog_btn.pressed.connect(_on_play_current_dialog_pressed)
	
	switch_localization.icon = get_theme_icon("Translation", "EditorIcons")
	
	file_popup.hide_on_checkable_item_selection = false
	
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
	file_popup.add_check_item(
			"Dialog ID field visible",
			DiscourseFileMenuID.DISPLAY_DIALOG_ID_FIELD)
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
	# --------------------------------------------------------
	
	search_nodes_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	
	conversation_tree.ready_plugin()
	discourse_nodes_tree.ready_plugin()
	issues_tree.ready_plugin()
	
	languages_tree.ready_plugin()
	localization_nodes_tree.ready_plugin()
	
	var discourse_panel: PanelContainer = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/GraphPanel
	#discourse_window.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#discourse_split_container.add_child(discourse_window)
	#discourse_split_container.move_child(discourse_window, 0)
	var style: StyleBoxFlat = load("res://addons/nexus_forge/discourse/discourse_editor_stylebox.tres")
	
	style.bg_color = get_theme_color("base_color", "Editor")
	discourse_panel.add_theme_stylebox_override(&"panel", style)
	
	var system_lang = OS.get_locale_language()
	languages_tree.create_language(system_lang, true)
	add_locale(system_lang)
	base_language = system_lang
	languages_tree.set_default_language(system_lang)
	
	if discourse_graph_edit.entry_node != null:
		_on_discourse_node_created(discourse_graph_edit.entry_node)
	
	$MainSplitContainer.visible = true
	$LocalizationContainer.visible = false
	new_folder_button.disabled = true
	new_folder_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	
	return_discourse_btn.icon = get_theme_icon("Back", "EditorIcons")
	
	save_case_btn.icon = get_theme_icon("Save", "EditorIcons")
	
	hide_issues_btn.icon = get_theme_icon("GuiClose", "EditorIcons")
	
	discourse_graph_edit.panning_scheme = GraphEdit.SCROLL_PANS if ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("discourse_panning_scheme"), true) else GraphEdit.SCROLL_ZOOMS
	
	play_current_dialog_btn.icon = get_theme_icon("MainPlay", "EditorIcons")
	
	# --------------------------------------------------------
	dialogs_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	data_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	setting_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	node_popup.id_pressed.connect(_on_create_dialog_id_pressed)
	switch_localization.pressed.connect(_on_switch_window_pressed)
	file_popup.id_pressed.connect(_on_file_menu_id_pressed)
	localization_menu.item_selected.connect(_on_localization_selected)
	# --------------------------------------------------------
	
	discourse_graph_edit.dialog_changed.connect(_on_conversation_changed)
	discourse_graph_edit.localization_enabled.connect(_on_localize_node)
	discourse_graph_edit.nodes_removed.connect(_on_nodes_removed)
	discourse_graph_edit.node_created.connect(_on_discourse_node_created)
	discourse_graph_edit.node_duplication_requested.connect(_on_graph_edit_node_duplication_requested)
	discourse_graph_edit.paste_nodes_requested.connect(_on_graph_edit_paste_requested)
	
	discourse_graph_edit.discourse_node_selected.connect(_on_discourse_node_selected)
	discourse_graph_edit.scroll_offset_changed.connect(_on_graph_edit_offset_changed)
	
	return_discourse_btn.pressed.connect(_on_switch_window_pressed)
	node_search_ln_edt.text_changed.connect(_on_discourse_node_search_text_changed)
	new_language_btn.pressed.connect(_on_new_lang_pressed)
	languages_tree.locale_changed.connect(_on_side_editor_locale_changed)
	languages_tree.region_created.connect(_on_region_created)
	languages_tree.locale_deleted.connect(_on_locale_deleted)
	
	discourse_nodes_tree.directory_edited.connect(_on_conversation_changed)
	discourse_nodes_tree.item_renamed.connect(_on_discourse_item_edited)
	discourse_nodes_tree.node_activated.connect(_on_discourse_node_activated)
	localization_nodes_tree.dialog_selected.connect(_on_localizer_node_selected)
	localization_nodes_tree.node_delocalized.connect(_on_node_delocalized)
	localization_nodes_tree.dialog_item_edited.connect(_on_localizer_item_edited)
	translation_txt_box.text_changed.connect(_on_text_field_changed)
	translation_txt_box.text_changed.connect(_on_translation_text_changed)
	
	new_folder_button.pressed.connect(_on_new_folder_button_pressed)
	conversation_tree.conversation_selected.connect(_on_conversation_selected)
	
	save_case_btn.pressed.connect(_on_save_cases_btn_pressed)
	new_text_button.pressed.connect(_on_new_key_field_button_pressed)
	new_case_btn.pressed.connect(_on_new_case_button_pressed)
	search_text_ln_edt.text_changed.connect(_on_key_search_text_changed)
	search_case_ln_edt.text_changed.connect(_on_case_search_text_changed)
	
	key_split_container.dragged.connect(_on_scroll_dragged.bind(key_header_split))
	cases_split.dragged.connect(_on_scroll_dragged.bind(case_header_split))
	
	default_case_ln_edt.text_changed.connect(_on_conversation_changed)
	conversation_tree.conversation_close_pressed.connect(_on_conversation_close_pressed)
	
	hide_issues_btn.pressed.connect(_on_hide_issues_pressed)
	issues_tree.issue_activated.connect(_on_issue_activated)
	
	dialog_id_ln_edt.text_changed.connect(_on_conversation_changed)


func add_locale(locale_code: String) -> void:
	var locale_parts: PackedStringArray = locale_code.split("_", false, 1)
	var language: String = locale_parts[0]
	var region: String = locale_parts[1] if locale_parts.size() == 2 else ""
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
				existing_locale["country_code"].is_empty() else\
				existing_locale["language_name"] + " (" + existing_locale["country_code"] + ")"
		idx += 1
		localization_menu.add_item(display_text)
		localization_menu.set_item_metadata(idx, existing_locale)
		if existing_locale["language_code"] == selected_language and existing_locale["country_code"] == selected_country:
			localization_menu.select(idx)
			localization_menu.tooltip_text = display_text
	
	if selected_language.is_empty() and selected_country.is_empty():
		localization_menu.tooltip_text = localization_menu.get_item_text(0)


func has_locale(locale: String) -> bool:
	if locale.is_empty():
		return false
	
	var parts: PackedStringArray = TranslationServer.standardize_locale(locale).split("_", false, 1)
	var lang_code: String = parts[0]
	var reg_code: String = parts[1] if parts.size() == 2 else ""
	
	for option_idx in range(localization_menu.item_count):
		var metadata: Dictionary = localization_menu.get_item_metadata(option_idx)
		if metadata["language_code"] == lang_code and metadata["country_code"] == reg_code:
			return true
	return false


func remove_locale(locale: String) -> void:
	if locale.is_empty():
		return
	
	var parts: PackedStringArray = TranslationServer.standardize_locale(locale).split("_")
	var lang: String = parts[0]
	var reg: String = parts[1] if parts.size() == 2 else ""
	
	var current: int = localization_menu.selected
	var new_index: int = current
	var item_count: int = localization_menu.item_count 
	
	for item_idx in range(localization_menu.item_count):
		var mtdt: Dictionary = localization_menu.get_item_metadata(item_idx)
		
		if mtdt["language_code"] != lang or mtdt["country_code"] != reg:
			continue
		localization_menu.remove_item(item_idx)
		
		if item_idx == current:
			var new_idx: int = clampi(
					item_idx - 1,
					-1 if item_count == 1 else 0,
					item_count - 2)
			
			if new_idx != -1:
				localization_menu.select(new_idx)
				current_locale = TranslationServer.standardize_locale(mtdt["language_code"] if mtdt["country_code"].is_empty() else mtdt["language_code"] + "_" + mtdt["country_code"])
				localization_menu.tooltip_text = localization_menu.get_item_text(new_idx)
			else:
				current_locale = ""
				localization_menu.tooltip_text = ""
			
			localization_menu.select(new_idx)
		
		return


func set_graph_edit_visible(graph_visible: bool) -> void:
	no_dialog_label.visible = not graph_visible
	discourse_graph_edit.visible = graph_visible
	if graph_visible and discourse_graph_edit.size != size:
		discourse_graph_edit.size = size


func set_conversation_options_enabled(are_enabled: bool) -> void:
	var disabled: bool = !are_enabled
	#node_menu.disabled = disabled
	node_menu_btn.disabled = disabled
	switch_localization.disabled = disabled
	save_btn.disabled = disabled
	localization_menu.disabled = disabled
	play_current_dialog_btn.disabled = disabled
	snap_distance_spn_bx.editable = are_enabled
	
	
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
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.CLOSE_DIALOG),
					disabled)
	
	_conversation_options_disabled = disabled




func update_localization_display(data: Dictionary) -> void:
	discourse_graph_edit.set_localization_data(data)


func _locale_sort_custom(locale_a: Dictionary, locale_b: Dictionary):
	var language_comp: int = locale_a["language_name"].naturalnocasecmp_to(locale_b["language_name"])
	
	if language_comp == 0:
		return locale_a["country_code"].naturalnocasecmp_to(locale_b["country_code"]) < 0
	else:
		return language_comp < 0


func _on_localization_selected(idx: int) -> void:
	var old_locale: String = current_locale
	
	if idx == -1:
		localization_menu.tooltip_text = ""
		current_locale = ""
	else:
		var locale_data: Dictionary = localization_menu.get_item_metadata(idx)
		current_locale = TranslationServer.standardize_locale(locale_data["language_code"] if locale_data["country_code"].is_empty() else locale_data["language_code"] + "_" + locale_data["country_code"])
		localization_menu.tooltip_text = localization_menu.get_item_text(idx)
	
	_on_graph_editor_locale_changed(old_locale, current_locale)


func _on_file_menu_id_pressed(id: int) -> void:
	match id as DiscourseFileMenuID:
		DiscourseFileMenuID.NEW_DIALOG:
			_on_new_conversation_pressed()
		DiscourseFileMenuID.OPEN_DIALOG:
			_on_open_conversation_pressed()
		DiscourseFileMenuID.SAVE_DIALOG:
			_on_save_conversation_pressed()
		DiscourseFileMenuID.CLOSE_DIALOG:
			_on_menu_close_pressed()
		DiscourseFileMenuID.CHANGE_LANGUAGE:
			_on_change_default_language_pressed()
		DiscourseFileMenuID.SET_LOCALE_GROUP:
			_on_change_locale_group_pressed()
		DiscourseFileMenuID.CHECK_ISSUES:
			_on_get_issues_pressed()
		DiscourseFileMenuID.PLAY_CURRENT_DIALOG:
			_on_play_current_dialog_pressed()
		DiscourseFileMenuID.DISPLAY_DIALOG_ID_FIELD:
			#var menu: PopupMenu = file_menu.get_popup()
			var idx: int = file_popup.get_item_index(id)
			var display: bool = !file_popup.is_item_checked(idx)
			file_popup.set_item_checked(idx, display)
			
			_on_display_dialog_id_toggled(display)


func _on_create_dialog_id_pressed(id: int) -> void:
	if id != 1000:
		discourse_graph_edit.spawn_node_at_center(
				id as DiscourseGraphNode.DialogueNodeType)
	else:
		discourse_graph_edit.spawn_frame_at_center()


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


func _on_display_dialog_id_toggled(id_line_visible: bool) -> void:
	dialog_id_container.visible = id_line_visible


func _on_discourse_node_selected(node_uuid: StringName) -> void:
	discourse_nodes_tree.select_node(node_uuid)


func _on_discourse_node_search_text_changed(text: String) -> void:
	discourse_nodes_tree.search_for_node(text.strip_edges())


func _on_discourse_node_activated(node_uuid: StringName) -> void:
	discourse_graph_edit.focus_graph_node(node_uuid)


func _on_change_locale_group_pressed() -> void:
	var line_confirmation := preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
	line_confirmation.allow_empty = false
	line_confirmation.set_line_text(active_conversation.locale_group)
	add_child(line_confirmation)
	line_confirmation.show()
	var new_group: Array = await line_confirmation.dialog_finished
	if new_group[0]:
		active_conversation.locale_group = new_group[1]
	line_confirmation.queue_free()


func _on_graph_edit_offset_changed(_offset: Vector2) -> void:
	if not listen_offset or conversation_tree.active_conversation_item == null or conversation_tree.active_offset_changed:
		return
	
	conversation_tree.active_offset_changed = true


func _on_conversation_close_pressed(dialog: EditorDiscourseDialog, save_required: bool, offset_changed: bool) -> void:
	if save_required:
		var unsaved_prompt: AcceptDialog = preload("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
		add_child(unsaved_prompt)
		unsaved_prompt.show()
		var result: int = await unsaved_prompt.dialog_finished
		if result == 0: # Save
			ResourceSaver.save(dialog)
		elif result == 2: # Cancel
			unsaved_prompt.queue_free()
			return
		unsaved_prompt.queue_free()
	elif offset_changed:
		if dialog == active_conversation:
			dialog.scroll_offset = discourse_graph_edit.scroll_offset
			dialog.zoom = discourse_graph_edit.zoom
		ResourceSaver.save(dialog)
	
	if dialog == active_conversation:
		var item: TreeItem = conversation_tree.active_conversation_item
		var total_items: int = conversation_tree.get_root().get_child_count()
		var new_item: TreeItem = null
		
		if 1 < total_items:
			if item.get_index() == total_items - 1: # Get a -1
				new_item = conversation_tree.get_root().get_child(item.get_index() - 1)
			else: # Get the same index
				new_item = conversation_tree.get_root().get_child(item.get_index() + 1)
			
		if new_item == null:
			active_conversation = null
			set_conversation_active(false)
			display_conversation(null)
			conversation_tree.active_unsaved = false
		else:
			var new_conv: EditorDiscourseDialog = new_item.get_metadata(0)["resource"]
			conversation_tree.set_conversation_item_active(new_conv)
			if open_conversation(new_conv):
				conversation_tree.active_unsaved = true
		_unsaved = conversation_tree.active_unsaved
		selected_key = null
		selected_format = ""
	conversation_tree.remove_conversation(dialog)


func _on_menu_close_pressed() -> void:
	if active_conversation == null:
		return
	
	if discourse_graph_edit.focus_tween != null:
		discourse_graph_edit.stop_focus_animation()
	if conversation_tree.active_unsaved:
		var unsaved_prompt: AcceptDialog = preload("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
		add_child(unsaved_prompt)
		unsaved_prompt.show()
		var result: int = await unsaved_prompt.dialog_finished
		if result == 0: # Save
			save_current_dialog()
		elif result == 2: # Cancel
			unsaved_prompt.queue_free()
			return
		unsaved_prompt.queue_free()
	elif conversation_tree.active_offset_changed:
		active_conversation.scroll_offset = discourse_graph_edit.scroll_offset
		active_conversation.zoom = discourse_graph_edit.zoom
		ResourceSaver.save(active_conversation)
	
	var item: TreeItem = conversation_tree.active_conversation_item
	var total_items: int = conversation_tree.get_root().get_child_count()
	var new_item: TreeItem = null
	
	if 1 < total_items:
		if item.get_index() == total_items - 1: # Get a -1
			new_item = conversation_tree.get_root().get_child(item.get_index() - 1)
		else: # Get the same index
			new_item = conversation_tree.get_root().get_child(item.get_index() + 1)
		
	conversation_tree.remove_conversation(active_conversation)
	
	if new_item == null:
		set_conversation_active(false)
		display_conversation(null)
		active_conversation = null
		conversation_tree.active_unsaved = false
	else:
		conversation_tree.set_conversation_item_active(new_item.get_metadata(0)["resource"])
		if open_conversation(active_conversation):
			conversation_tree.active_unsaved = true
	
	selected_key = null
	selected_format = ""
	_unsaved = conversation_tree.active_unsaved


func _on_new_folder_button_pressed() -> void:
	var new_name: String = get_unique_name_on_tree(
			discourse_nodes_tree.get_root(),
			"NewGroup")
	
	var selected_item: TreeItem = discourse_nodes_tree.get_selected()
	
	if selected_item != null and discourse_nodes_tree.is_folder(selected_item):
		discourse_nodes_tree.create_folder(new_name, selected_item)
	else:
		discourse_nodes_tree.create_folder(new_name)
	
	_on_conversation_changed()


func _on_change_default_language_pressed() -> void:
	var language_options: Array[Dictionary] = []
	
	for language_code in TranslationServer.get_all_languages():
		language_options.append({
			"code": language_code,
			"disabled": false,
			"name": TranslationServer.get_language_name(language_code)})
	
	var window: ConfirmationDialog = preload("res://addons/nexus_forge/discourse/locale_creation_confirm_dialog.gd").new()
	window.sort_codes_array(language_options)
	window.title = "Select Language..."
	window.ok_button_text = "Set default"
	window.set_codes(language_options)
	add_child(window)
	window.show()
	window.focus_option_button()
	var result: String = await window.dialog_finished
	
	if result != "":
		if not languages_tree.has_language(result):
			languages_tree.create_language(result, true)
			add_locale(result)
			active_conversation.add_locale(result)
			
			
		base_language = result
		languages_tree.set_default_language(result)
	window.queue_free()


func _on_translation_text_changed() -> void:
	if languages_tree.get_base_language() == languages_tree.get_active_language() and languages_tree.get_active_region() == "base":
		base_text_edt.text = translation_txt_box.text


func _on_conversation_changed(_arg = null) -> void:
	if not _unsaved:
		_unsaved = true
	
	if active_conversation != null:
		conversation_tree.active_unsaved = true


func _on_graph_editor_locale_changed(from: String, to: String) -> void:
	if not from.is_empty():
		discourse_graph_edit.update_localization_data(active_conversation, from)
	if not to.is_empty():
		var data: Dictionary = active_conversation.get_display_localization_data(to)
		update_localization_display(data)


func _on_side_editor_locale_changed(from: String, to: String) -> void:
	var invalid_language: bool = to.is_empty()
	var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	localization_nodes_tree.get_root().collapsed = invalid_language
	new_text_button.disabled = invalid_language
	
	set_localization_tip(to)
	
	if not from.is_empty():
		if not selected_format.is_empty():
			save_current_phrase_key()
		
		for key_item in key_container.get_children():
			var key: String = key_item.get_child(1).get_meta(&"phrase_key")
			var text: String = text_container.get_child(key_item.get_index()).get_child(0).text.strip_edges()
			
			active_conversation.set_format_string(
					key,
					text,
					from)
		
		if active_node != null and from == current_locale:
			var uuid: StringName = active_node.get_node_uuid()
			match active_node.node_type:
				DiscourseGraphNode.DialogueNodeType.DIALOG:
					active_node.set_dialog_text(translation_txt_box.text.strip_edges())
				DiscourseGraphNode.DialogueNodeType.OPTIONS:
					var choices: = get_localizer_choices()
					var choice_n: int = 0
					for choice in choices:
						choice_n += 1
						active_node.set_option_text(choice_n, choice)
				DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
					active_node.set_text(translation_txt_box.text.strip_edges())
	
	clear_cases()
	default_case_ln_edt.text = ""
	search_case_ln_edt.text = ""
	search_case_ln_edt.set_meta(&"current_search", "")
	argument_opt_btn.clear()
	
	search_text_ln_edt.text = ""
	search_text_ln_edt.set_meta(&"current_search", "")
	
	if to.is_empty(): # TEST: This was from.is_empty. If fails, revert.
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = false
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = false
		key_box_container.visible = false
		case_box_container.visible = false
		return
	
	key_box_container.visible = languages_tree.is_lang_selected()
	case_box_container.visible = false
	
	for item in key_container.get_children():
		var line: LineEdit = item.get_child(1)
		var text_field: LineEdit = text_container.get_child(item.get_index()).get_child(0)
		var key: String = line.get_meta(&"phrase_key")
		
		text_field.text = active_conversation.get_localized_string(
				key,
				from)
	
	if active_node == null:
		return
	
	var base_locale: String = languages_tree.get_base_language()
	if active_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG or active_node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
		base_text_edt.text = active_conversation.get_text_entry(
				active_node.get_node_uuid(),
				base_locale)
		translation_txt_box.text = active_conversation.get_text_entry(
				active_node.get_node_uuid(),
				to)
	elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.OPTIONS:
		clear_localized_options()
		var base_options: Array[String] = active_conversation.get_choices_entry(
				active_node.get_node_uuid(),
				base_locale)
		var localized_options: Array[String] = active_conversation.get_choices_entry(
				active_node.get_node_uuid(),
				to)
		for option_idx in range(base_options.size()):
			create_choice_node(
					base_options[option_idx],
					localized_options[option_idx])


func _on_localizer_node_selected(uuid: StringName) -> void:
	if uuid.is_empty():
		localization_node_selected = null
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = false
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = false
		return
	
	var old_node: DiscourseGraphNode = localization_node_selected
	var new_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	
	var active_locale: String = languages_tree.get_active_locale()
	
	if active_locale.is_empty():
		return
	
	# Save previous node if needed.
	if old_node != null:
		var update_node: bool = active_locale == current_locale
		# Save data to localization dictionary and update node if needed.
		match old_node.node_type:
			DiscourseGraphNode.DialogueNodeType.DIALOG:
				active_conversation.set_text_entry(
						old_node.get_node_uuid(),
						translation_txt_box.text.strip_edges(),
						active_locale)
				if update_node:
					old_node.set_dialog_text(translation_txt_box.text)
			DiscourseGraphNode.DialogueNodeType.OPTIONS:
				var options: Array[String] = []
				for option_child in choices_container.get_children():
					options.append(option_child.get_child(2).text)
				
				active_conversation.set_choices_entry(
						old_node.get_node_uuid(),
						options,
						active_locale)
				
				if update_node:
					for option_idx in range(options.size()):
						old_node.set_option_text(
								option_idx + 1,
								options[option_idx])
			DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				active_conversation.set_text_entry(
						old_node.get_node_uuid(),
						translation_txt_box.text.strip_edges(),
						active_locale)
				if update_node:
					old_node.set_text(translation_txt_box.text)
	
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = new_node.node_type == DiscourseGraphNode.DialogueNodeType.OPTIONS
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = !$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible
	# Get the data & set to localizer
	var base_language: String = languages_tree.get_default_language()
	
	match new_node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			base_text_edt.text = active_conversation.get_text_entry(
					uuid,
					base_language)
			translation_txt_box.text = active_conversation.get_text_entry(
					uuid,
					active_locale)
			
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			clear_localized_options()
			var options_base: Array[String] = active_conversation.get_choices_entry(uuid, base_language)
			var options_localized: Array[String] = active_conversation.get_choices_entry(uuid, active_locale)
			for option_idx in range(options_base.size()):
				create_choice_node(
						options_base[option_idx],
						options_localized[option_idx])
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			base_text_edt.text = active_conversation.get_text_entry(uuid, base_language)
			translation_txt_box.text = active_conversation.get_text_entry(uuid, active_locale)
	
	localization_node_selected = new_node


func _on_localize_node(node: DiscourseGraphNode) -> void:
	match node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			active_conversation.set_text_entry(
					node.get_node_uuid(),
					node.get_dialog_text(),
					current_locale)
			localization_nodes_tree.create_dialog_node(node.name, node)
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			var text_options: Array[String] = node.get_options()
			active_conversation.set_choices_entry(
					node.get_node_uuid(),
					text_options,
					current_locale)
			localization_nodes_tree.create_options_node(node.name, node)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			active_conversation.set_text_entry(
					node.get_node_uuid(),
					node.get_text(),
					current_locale)
			localization_nodes_tree.create_localized_text_node(node.name, node)


func _on_node_delocalized(node: DiscourseGraphNode) -> void:
	var base_language: String = languages_tree.get_default_language()
	
	match node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			var dialog: String = node.get_dialog_text()
			active_conversation.set_text_entry(
					node.get_node_uuid(),
					dialog)
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			var options: Array[String] = []
			options.assign(
					active_conversation.get_choices_entry(
							node.get_node_uuid(),
							base_language))
			active_conversation.set_choices_entry(
					node.get_node_uuid(),
					options)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			var text: String = node.get_text()
			active_conversation.set_text_entry(
					node.get_node_uuid(),
					text)
	
	node.set_node_localized(false)
	#discourse_window.erase_localization(node.get_node_uuid())
	
	if localization_node_selected == node:
		localization_node_selected = null


func _on_switch_window_pressed() -> void:
	var to_localizer: bool = $MainSplitContainer.visible
	var localizer_locale: String = languages_tree.get_active_locale()
	var on_same_locale: bool = localizer_locale == current_locale
	var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	
	# --- This part is storing the data from the graphedit/localizer onto the file ---
	if to_localizer: # If we travel to side window
		# Update the active conversation from the node data if a localization exist.
		if not current_locale.is_empty():
			discourse_graph_edit.update_localization_data(active_conversation, current_locale)
	else: # We travel to main window
		# Update the active node on the active file if a lang and node is selected.
		if not localizer_locale.is_empty() and active_node != null:
			if active_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG:
				active_conversation.set_text_entry(
						active_node.get_node_uuid(),
						translation_txt_box.text.strip_edges(),
						localizer_locale)
			elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				active_conversation.set_text_entry(
						active_node.get_node_uuid(),
						translation_txt_box.text.strip_edges(),
						localizer_locale)
			elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.OPTIONS:
				var choices: Array[String] = get_localizer_choices()
				var target_size: int = active_node.choice_count()
				if choices.size() != target_size:
					choices.resize(target_size)
				active_conversation.set_choices_entry(
						active_node.get_node_uuid(),
						choices,
						localizer_locale)
	# --------------------------------------------------------------------------------
	
	$MainSplitContainer.visible = !to_localizer
	$LocalizationContainer.visible = to_localizer
	
	if not on_same_locale: # SInce we're not on the same locale, update ins't needed.
		return
	
	# --- This part loads the data from the file, to the relevant window ---
	if to_localizer:
		# If there is no node selected or no locale selected, we stop to prevent
		# bad data assignation.
		if active_node == null or localizer_locale.is_empty():
			return
		# Node is option. Specific method call is needed
		if active_node.node_type == DiscourseGraphNode.DialogueNodeType.OPTIONS:
			var target_choices: int = active_node.choice_count()
			var options: Array[String] = active_conversation.get_choices_entry(
					active_node.get_node_uuid(),
					localizer_locale)
			var base_lang: Array[String] = active_conversation.get_choices_entry(
					active_node.get_node_uuid(),
					languages_tree.get_base_language())
			
			if options.size() != target_choices:
				options.resize(target_choices)
			if base_lang.size() != target_choices:
				base_lang.resize(target_choices)
			
			clear_localized_options()
			for option_idx in range(target_choices):
				create_choice_node(
						base_lang[option_idx],
						options[option_idx])
		else: # Either dialog or localized text. Same method can be used.
			var text: String = active_conversation.get_text_entry(
					active_node.get_node_uuid(),
					localizer_locale,
					"")
			base_text_edt.text = active_conversation.get_text_entry(
					active_node.get_node_uuid(),
					languages_tree.get_base_language())
			translation_txt_box.text = text
	else:
		# If no active node was selected or no locale is selected we stop to prevent
		# bad data assignation.
		if active_node == null or current_locale.is_empty():
			return
		
		if active_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG:
			active_node.set_dialog_text(
					translation_txt_box.text.strip_edges())
		elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.OPTIONS:
			var option_number: int = 0
			for option_node in choices_container.get_children():
				option_number += 1
				active_node.set_option_text(
						option_number,
						option_node.get_child(2).text)
		elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			active_node.set_text(
					translation_txt_box.text)
	# ----------------------------------------------------------------------


func _on_region_created(language: String, region: String) -> void:
	var locale_code: String = TranslationServer.standardize_locale(language if region.is_empty() else language + "_" + region)
	
	add_locale(locale_code)
	active_conversation.add_locale(locale_code)
	_on_conversation_changed()


func _on_new_lang_pressed() -> void:
	var used_lang_codes: PackedStringArray = languages_tree.get_used_language_codes()
	var language_options: Array[Dictionary] = []
	
	for language_code in TranslationServer.get_all_languages():
		language_options.append({
			"code": language_code,
			"disabled": language_code in used_lang_codes,
			"name": TranslationServer.get_language_name(language_code)})
	
	var window: ConfirmationDialog = preload("res://addons/nexus_forge/discourse/locale_creation_confirm_dialog.gd").new()
	window.sort_codes_array(language_options)
	window.title = "Select Language..."
	window.set_codes(language_options)
	add_child(window)
	window.show()
	window.focus_option_button()
	var result: String = await window.dialog_finished
	
	if result != "":
		languages_tree.create_language(result)
		add_locale(result)
		if selected_key != null and selected_format != "":
			save_current_phrase_key(true)
		
		active_conversation.add_locale(result)
		_on_conversation_changed()
	window.queue_free()


func _on_locale_deleted(locale: String) -> void:
	remove_locale(locale)
	active_conversation.remove_locale(locale)


func _on_issue_activated(issue_uuid: StringName) -> void:
	discourse_graph_edit.focus_graph_node(issue_uuid)


func _on_hide_issues_pressed() -> void:
	issues_tree.clear_issues()
	error_container.visible = false
	discourse_split_container.dragging_enabled = false
	discourse_split_container.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED


func _on_get_issues_pressed() -> void:
	issues_tree.clear_issues()
	var issues: Array[Dictionary] = discourse_graph_edit.get_issues()
	if not error_container.visible:
		error_container.visible = true
		discourse_split_container.dragging_enabled = true
		discourse_split_container.dragger_visibility = SplitContainer.DRAGGER_VISIBLE
	
	if issues.is_empty():
		issues_tree.add_issue("No issue found", null)
		return
	
	for issue in issues:
		for node_issue:String in issue["issues"]:
			issues_tree.add_issue(node_issue, issue["node"])


func set_localization_tip(locale: String) -> void:
	if locale.is_empty():
		locale_label.text = "Current Locale:"
		return
	
	var locale_parts: PackedStringArray = locale.split("_", false, 1)
	var language: String = locale_parts[0]
	var region: String = locale_parts[1] if locale_parts.size() == 2 else ""
	
	var language_name: String = TranslationServer.get_language_name(language)
	
	var locale_text: String = "Current Locale: " 
	if not region.is_empty():
		var country_name: String = TranslationServer.get_country_name(region)
		locale_text += country_name
		if country_name.ends_with("s"):
			locale_text += "' "
		else:
			locale_text += "'s "
	
	locale_text += language_name
	locale_label.text = locale_text


func get_open_files() -> Array[String]:
	return conversation_tree.get_open_file_paths()


func load_dialog_files(files: Array[String]) -> void:
	for file in files:
		if not FileAccess.file_exists(file):
			continue
		var loaded: Resource = load(file)
		if loaded != null and loaded is EditorDiscourseDialog:
			if conversation_tree.is_conversation_open(loaded):
				continue
			else:
				load_conversation(loaded, false)


func save_current_dialog_to_memory() -> void:
	# Saves the current unsaved node data to the file and assings the localized
	# data to the current selected dropdown locale.
	discourse_graph_edit.update_conversation_file(active_conversation, current_locale)
	
	active_conversation.base_language = languages_tree.get_base_language()
	active_conversation.zoom = discourse_graph_edit.zoom
	active_conversation.scroll_offset = discourse_graph_edit.scroll_offset
	active_conversation.node_structure = discourse_nodes_tree.get_folder_structure()
	active_conversation.dialog_id = dialog_id_ln_edt.text.strip_edges()


func _on_conversation_selected(dialog: EditorDiscourseDialog) -> void:
	if not _conversation_options_disabled:
		set_graph_edit_visible(true)
		set_conversation_options_enabled(true)
		discourse_nodes_tree.get_root().collapsed = false
		new_folder_button.disabled = false
		dialog_id_ln_edt.editable = true
		
	if active_conversation != null:
		save_current_dialog_to_memory()
	
	active_conversation = dialog
	conversation_tree.set_conversation_item_active(dialog)
	if open_conversation(dialog):
		conversation_tree.active_unsaved = true


func _on_text_field_changed(_arg: Variant = null) -> void:
	_on_conversation_changed()


func clear_localized_options() -> void:
	for node in choices_container.get_children():
		node.queue_free()
		choices_container.remove_child(node)


func create_choice_node(base_text: String, localized_text: String) -> void:
	var new_container: HBoxContainer = HBoxContainer.new()
	var new_choice_count: Label = Label.new()
	var base_text_label: Label = Label.new()
	var localization_lnedt: LineEdit = LineEdit.new()
	
	base_text_label.text = base_text
	base_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	base_text_label.size_flags_stretch_ratio = 2.0
	base_text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	base_text_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	base_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	base_text_label.tooltip_text = base_text
	
	localization_lnedt.placeholder_text = "Translation"
	localization_lnedt.text = localized_text
	localization_lnedt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	localization_lnedt.size_flags_stretch_ratio = 2.0
	
	new_choice_count.text = "Choice #" + str(choices_container.get_child_count() + 1)
	new_choice_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_choice_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	localization_lnedt.text_changed.connect(_on_text_field_changed)
	
	choices_container.add_child(new_container)
	new_container.add_child(new_choice_count)
	new_container.add_child(base_text_label)
	new_container.add_child(localization_lnedt)


func get_localizer_choices() -> Array[String]:
	var choices: Array[String] = []
	
	for choice in choices_container.get_children():
		choices.append(choice.get_child(2).text.strip_edges())
	
	return choices


func _on_localizer_item_edited(item: TreeItem) -> void:
	var target_item: TreeItem = null
	var node: DiscourseGraphNode = item.get_metadata(0)["node"]
	
	for discourse_item in discourse_nodes_tree.get_root().get_children():
		if node == discourse_item.get_metadata(0)["node"]:
			target_item = discourse_item
			break
	
	var proper_name: String = get_unique_name_on_tree(
			discourse_nodes_tree.get_root(),
			item.get_text(0),
			target_item)
	
	node.custom_id = proper_name
	target_item.set_text(0, proper_name)
	item.set_text(0, proper_name)
	item.get_metadata(0)["name"] = proper_name
	
	_on_conversation_changed()


func _on_new_conversation_pressed() -> void:
	var file_saver: AcceptDialog = preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	file_saver.file_mode = file_saver.FILE_MODE_SAVE_FILE
	add_child(file_saver)
	file_saver.show()
	
	var result: Array = await file_saver.dialog_finished
	
	if result[0]:
		var wait_visible: bool = no_dialog_label.visible
		listen_offset = false
		if active_conversation != null:
			save_current_dialog_to_memory()
		var new_conv: EditorDiscourseDialog = EditorDiscourseDialog.new()
		new_conv.locale_map.assign(languages_tree.as_map())
		if ResourceLoader.has_cached(result[1]):
			new_conv.take_over_path(result[1])
		ResourceSaver.save(
				new_conv,
				result[1])
		new_conv.resource_path = result[1]
		if _conversation_options_disabled:
			set_graph_edit_visible(true)
			set_conversation_options_enabled(true)
			discourse_nodes_tree.get_root().collapsed = false
			new_folder_button.disabled = false
			dialog_id_ln_edt.editable = true
		load_conversation(new_conv, true)
		
		discourse_graph_edit.reset_scroll_offset(
				$MainSplitContainer/DiscourseSplitContainer/DiscourseWindow/ContentVBox/GraphPanel.size)
		if wait_visible:
			await get_tree().process_frame
		listen_offset = true
	file_saver.queue_free()


func _on_open_conversation_pressed() -> void:
	var file_opener: AcceptDialog = preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	file_opener.file_mode = file_opener.FILE_MODE_OPEN_FILE
	add_child(file_opener)
	file_opener.show()
	
	var result: Array = await file_opener.dialog_finished
	
	if result[0] and FileAccess.file_exists(result[1]):
		listen_offset = false
		var resource: Resource = load(result[1])
		if resource != null and resource is EditorDiscourseDialog:
			var wait_visible: bool = no_dialog_label.visible
			if _conversation_options_disabled:
				set_graph_edit_visible(true)
				set_conversation_options_enabled(true)
				discourse_nodes_tree.get_root().collapsed = false
				new_folder_button.disabled = false
				dialog_id_ln_edt.editable = true
			if active_conversation != null:
				save_current_dialog_to_memory()
			if conversation_tree.is_conversation_open(resource):
				conversation_tree.set_conversation_item_active(resource)
				if open_conversation(resource):
					conversation_tree.active_unsaved = true
			else:
				_unsaved = false
				load_conversation(resource)
			if wait_visible:
				await get_tree().process_frame
		listen_offset = true
	
	file_opener.queue_free()


func _on_play_current_dialog_pressed() -> void:
	if active_conversation == null:
		return
	var res_path: String = active_conversation.resource_path
	var custom_scene: String = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("discourse_custom_dialog_debug_scene"), "").strip_edges()
	var scene_path: String = "res://addons/nexus_forge/discourse/dialog_previewer.tscn" if custom_scene.is_empty() or not FileAccess.file_exists(custom_scene) else custom_scene
	
	if res_path.is_empty():
		printerr("[NexusForge] Discourse: Path of current conversation is empty.")
		return
	
	var cfg: ConfigFile = ConfigFile.new()
	
	if FileAccess.file_exists("user://nexus_forge/discourse_settings.cfg"):
		cfg.load("user://nexus_forge/discourse_settings.cfg")
	
	cfg.set_value("Discourse", "active_scene", res_path)
	
	if not DirAccess.dir_exists_absolute("user://nexus_forge/"):
		DirAccess.make_dir_absolute("user://nexus_forge/")
	
	cfg.save("user://nexus_forge/discourse_settings.cfg")
	if conversation_tree.active_unsaved:
		save_current_dialog()
	EditorInterface.play_custom_scene(scene_path)


func plugin_file_selected(file: EditorDiscourseDialog):
	if _conversation_options_disabled:
		set_graph_edit_visible(true)
		set_conversation_options_enabled(true)
		discourse_nodes_tree.get_root().collapsed = false
		new_folder_button.disabled = false
		dialog_id_ln_edt.editable = true
	
	if active_conversation == file:
		return
	elif active_conversation != null:
		save_current_dialog_to_memory()
	
	if conversation_tree.is_conversation_open(file):
		conversation_tree.set_conversation_item_active(file)
		if open_conversation(file):
			conversation_tree.active_unsaved = true
	else:
		load_conversation(file)


func reload_signals() -> void:
	discourse_graph_edit.update_signals()


func reload_methods() -> void:
	discourse_graph_edit.update_methods()


#region Discourse dialog node tree
func _on_discourse_node_created(node: DiscourseGraphNode) -> void:
	discourse_nodes_tree.create_node(node)
	if node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
		_on_localize_node(node)



func get_unique_name_on_tree(on_tree: TreeItem, desired_name: String, skip_item: TreeItem = null) -> String:
	var edited_name: String = desired_name
	var iteration: int = 0
	
	while has_text_on_tree(on_tree, edited_name, 0, skip_item):
		iteration += 1
		edited_name = desired_name + str(iteration)
	
	return edited_name


func has_text_on_tree(on_tree: TreeItem, text: String, column: int, skip_item: TreeItem = null) -> bool:
	for item in on_tree.get_children():
		if item == skip_item:
			continue
		if item.get_text(column) == text:
			return true
	return false


func set_up_node_structure(structure: Array, level: TreeItem, _map: Dictionary[String, TreeItem]) -> void:
	#Remove from _map as we add them.
	for item:Dictionary in structure: # Order has the order.
		if item["is_node"]:
			level.add_child(_map[item["uuid"]])
			_map.erase(item["uuid"])
		else:
			var new_folder: TreeItem = level.create_child()
			new_folder.set_text(0, item["name"])
			new_folder.set_editable(0, true)
			new_folder.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
			new_folder.add_button(
					0,
					get_theme_icon("Remove", "EditorIcons"),
					-1,
					false,
					"Delete Group")
			new_folder.set_metadata(0, {"is_node": false})
			set_up_node_structure(item["items"], new_folder, _map)


func _on_discourse_item_edited(uuid: StringName, new_name: String) -> void:
	var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(uuid)
	var new_named: StringName = StringName(new_name)
	if node == null or node.name == new_named:
		return
	node.name = new_named
	if node.is_node_localized():
		match node.node_type:
			DiscourseGraphNode.DialogueNodeType.DIALOG:
				localization_nodes_tree.rename_dialog_node(uuid, new_name)
			DiscourseGraphNode.DialogueNodeType.OPTIONS:
				localization_nodes_tree.rename_options_node(uuid, new_name)
			DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				localization_nodes_tree.rename_text_node(uuid, new_name)
	
	_on_conversation_changed()

#endregion

func display_conversation(conversation: EditorDiscourseDialog) -> bool:
	if conversation == null:
		discourse_graph_edit.clear_dialog_nodes()
		return false
	
	# -----------------------------
	var needs_resaving: bool = false
	
	discourse_graph_edit.clear_dialog_nodes(false)
	
	var node_connections: Array[Dictionary] = []
	var graph_map: Dictionary[String, DiscourseGraphNode] = {}
	
	var node_relationships: Dictionary[String, GraphFrame] = {}
	
	for frame_uuid:String in conversation.get_frames_uuids():
		var frame_data: Dictionary = conversation.get_frame_data(frame_uuid)
		var frame: GraphFrame = discourse_graph_edit.spawn_frame(frame_uuid, frame_data["position"])
		frame.title = frame_data["title"]
		frame.size = frame_data["size"]
		frame.tint_color = frame_data["tint_color"]
		for child_node:String in frame_data["nodes"]:
			node_relationships[child_node] = frame
	
	for node_stnm_uuid:StringName in conversation.get_node_uuids():
		var node_uuid: String = String(node_stnm_uuid)
		var data: Dictionary = conversation.get_node_data(node_stnm_uuid, current_locale)
		var metadata: Dictionary = data["metadata"]
		var d_node: DiscourseGraphNode = discourse_graph_edit.spawn_node(data["type"], node_stnm_uuid, data)
		
		if d_node.node_type == DiscourseGraphNode.DialogueNodeType.CALLABLE or d_node.node_type == DiscourseGraphNode.DialogueNodeType.CALLABLE_RETURN:
			if metadata.has("method"):
				if not d_node.available_methods.has(metadata["method"]):
					needs_resaving = true
		elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.SIGNAL:
			if metadata.has("signal"):
				if not d_node.available_signals.has(metadata["signal"]):
					needs_resaving = true
		elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.ENTRY:
			discourse_graph_edit.entry_node = d_node
		
		if node_relationships.has(node_uuid):
			discourse_graph_edit.set_node_in_frame(node_stnm_uuid, node_relationships[node_uuid].get_frame_uuid())
		graph_map[node_uuid] = d_node
		var new_connections: Array[Dictionary] = discourse_graph_edit.get_connection_dictionary(
				node_stnm_uuid,
				data)
		if not new_connections.is_empty():
			node_connections.append_array(new_connections)
		
		_on_discourse_node_created(d_node)
		
		if d_node.is_node_localized():
			_on_localize_node(d_node)
	
	for output_connection in node_connections:
		if not graph_map.has(output_connection["from"]) or not graph_map.has(output_connection["to"]):
			continue
		discourse_graph_edit.connect_discourse_nodes(
				graph_map[output_connection["from"]].get_node_uuid(),
				output_connection["from_port"],
				graph_map[output_connection["to"]].get_node_uuid(),
				output_connection["to_port"])
	
	if discourse_graph_edit.entry_node == null:
		var en_node: DiscourseGraphNode = discourse_graph_edit.spawn_node(DiscourseGraphNode.DialogueNodeType.ENTRY)
		en_node.name = &"Entry"
		discourse_graph_edit.entry_node = en_node
		_on_discourse_node_created(en_node)
	
	discourse_graph_edit.zoom = conversation.zoom
	discourse_graph_edit.scroll_offset = conversation.scroll_offset
	
	return needs_resaving


# Loads a conversation into discourse.
func open_conversation(conversation: EditorDiscourseDialog) -> bool:
	dialog_id_ln_edt.text = conversation.dialog_id
	
	# Clears discourse_nodes_tree's items
	discourse_nodes_tree.clear_tree()
	
	# This fills the discourse_nodes_tree with items
	var reload_needed: bool = display_conversation(conversation) # Load conversation
	
	# We put them in a dictionary for sorting.
	if not conversation.node_structure.is_empty():
		var node_map: Dictionary[String, TreeItem] = {}
		var root: TreeItem = discourse_nodes_tree.get_root()
		for item in root.get_children():
			node_map[item.get_metadata(0)["uuid"]] = item
			root.remove_child(item)
		
		set_up_node_structure(conversation.node_structure, discourse_nodes_tree.get_root(), node_map)
		
		if not node_map.is_empty(): # We left some nodes outside the tree
			for node_uuid in node_map.keys():
				root.add_child(node_map[node_uuid])
	
	default_case_ln_edt.text = ""
	search_case_ln_edt.text = ""
	search_case_ln_edt.set_meta(&"current_search", "")
	argument_opt_btn.clear()
	
	search_text_ln_edt.text = ""
	search_text_ln_edt.set_meta(&"current_search", "")
	
	clear_cases()
	clear_localized_keys()
	localization_nodes_tree.clear_nodes()
	
	if issues_tree.has_issues():
		issues_tree.clear_issues()
	var graphs_locale: String = current_locale
	var side_locale: String = languages_tree.get_active_locale()
	
	for localized_key in conversation.format_strings.keys():
		var localized_text: String = "" if side_locale.is_empty() else conversation.get_format_string(localized_key, side_locale)
		add_new_phrase(localized_key, localized_text)
	
	for language in conversation.locale_map.keys():
		if not has_locale(language):
			add_locale(language)
		if not languages_tree.has_locale(language):
			languages_tree.create_language(language)
		for region in conversation.locale_map[language].keys():
			if not languages_tree.has_locale(language, region):
				languages_tree.create_region(language, region)
			var lang_code: String = language.to_lower() + "_" + region.to_upper()
			if not has_locale(lang_code):
				add_locale(lang_code)
	
	case_box_container.visible = false
	key_box_container.visible = languages_tree.is_lang_selected()
	
	active_conversation = conversation
	
	return reload_needed


# Adds a conversation into the list, can open it.
func load_conversation(data: EditorDiscourseDialog, open_conv: bool = true) -> void:
	conversation_tree.add_conversation(data, open_conv, false)
	
	if open_conv:
		#active_conversation_item = new_conversation
		conversation_tree.set_conversation_item_active(data)
		if open_conversation(data):
			conversation_tree.active_unsaved = true


func save_localizer_data() -> void:
	if active_conversation == null:
		return
	
	var current_locale: String = languages_tree.get_active_locale()
	
	var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	match active_node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			active_conversation.set_localization_text(
					active_node.get_node_uuid(),
					translation_txt_box.text,
					current_locale)
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			var options: Array[String] = []
			for option_child in choices_container.get_children():
				options.append(option_child.get_child(2).text)
			
			active_conversation.set_localization_choices(
					active_node.get_node_uuid(),
					options,
					current_locale)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			active_conversation.set_localization_text(
					active_node.get_node_uuid(),
					translation_txt_box.text,
					current_locale)


func _on_save_conversation_pressed() -> void:
	if active_conversation == null:
		return
	
	save_current_dialog()
	conversation_tree.active_offset_changed = false
	conversation_tree.active_unsaved = false


func _on_godot_save_triggered() -> void:
	if active_conversation != null:
		save_phrase_keys(true)
	save_all_dialogs()
	conversation_tree.set_conversations_saved()


func save_current_dialog() -> void:
	save_phrase_keys(true)
	if $LocalizationContainer.visible and localization_nodes_tree.get_active_node() != null:
		save_localizer_data()
	if not _unsaved and conversation_tree.active_offset_changed:
		active_conversation.scroll_offset = discourse_graph_edit.scroll_offset
		active_conversation.zoom = discourse_graph_edit.zoom
		ResourceSaver.save(active_conversation)
		conversation_tree.active_offset_changed = false
		return
	
	discourse_graph_edit.update_conversation_file(active_conversation, current_locale)

	var locale_map: Dictionary[String, Dictionary] = languages_tree.as_map()
	
	active_conversation.zoom = discourse_graph_edit.zoom
	active_conversation.scroll_offset = discourse_graph_edit.scroll_offset
	active_conversation.node_structure = discourse_nodes_tree.get_folder_structure()
	active_conversation.locale_map = locale_map.duplicate(true)
	active_conversation.dialog_id = dialog_id_ln_edt.text.strip_edges()
	
	_unsaved = false
	ResourceSaver.save(active_conversation)
	conversation_tree.active_unsaved = false
	conversation_tree.active_offset_changed = false


func save_all_dialogs() -> void:
	if $LocalizationContainer.visible and localization_nodes_tree.get_active_node() != null:
		save_localizer_data()
	
	if active_conversation != null:
		active_conversation.zoom = discourse_graph_edit.zoom
		active_conversation.scroll_offset = discourse_graph_edit.scroll_offset
	
	# Save all unsaved conversations
	for unsaved_conversation:EditorDiscourseDialog in conversation_tree.get_unsaved_conversation_resources():
		# Including our active one
		if unsaved_conversation == active_conversation:
			save_phrase_keys(true)
			discourse_graph_edit.update_conversation_file(active_conversation, current_locale)
			active_conversation.dialog_id = dialog_id_ln_edt.text.strip_edges()
			
			active_conversation.node_structure = discourse_nodes_tree.get_folder_structure()
			
			ResourceSaver.save(active_conversation)
		else:
			ResourceSaver.save(unsaved_conversation)
	
	_unsaved = false
	conversation_tree.set_all_files_saved()


func set_conversation_active(is_active: bool) -> void:
	discourse_nodes_tree.get_root().collapsed = not is_active
	set_graph_edit_visible(is_active)
	set_conversation_options_enabled(is_active)
	new_folder_button.disabled = not is_active


func has_unsaved_files() -> bool:
	for item in conversation_tree.get_root().get_children():
		if item.get_metadata(0)["unsaved"]:
			return true
	return false


func _on_nodes_removed(nodes_data: Dictionary) -> void:
	for node_uuid in nodes_data.keys():
		discourse_nodes_tree.remove_dialog_node(node_uuid)
		localization_nodes_tree.remove_node(node_uuid)
		active_conversation.remove_node(node_uuid)


func _on_graph_edit_node_duplication_requested(uuids: Array[StringName]) -> void:
	var uuid_size: int = uuids.size()
	if uuid_size == 0:
		return
	elif uuid_size == 1:
		var new_uuid: StringName = StringName(UUID.generate_new())
		discourse_graph_edit._duplicate_single(uuids[0], new_uuid)
	else:
		var uuid_map: Dictionary[StringName, StringName] = {}
		for uuid in uuids:
			uuid_map[uuid] = StringName(UUID.generate_new())
		var undo_targets: Array[StringName] = []
		undo_targets.assign(uuid_map.values())
		discourse_graph_edit._duplicate_multiple(uuid_map)


func _on_graph_edit_paste_requested() -> void:
	var uuid_map: Dictionary[StringName, StringName] = {}
	var clipboard: Array[Dictionary] = discourse_graph_edit.node_clipboard.duplicate(true)
	
	for clipboard_data in clipboard:
		if discourse_graph_edit.graph_nodes.has(clipboard_data["node_uuid"]): # Change to reference the GraphEdit
			uuid_map[clipboard_data["node_uuid"]] = StringName(UUID.generate_new())
		else:
			uuid_map[clipboard_data["node_uuid"]] = clipboard_data["node_uuid"]
	
	# TODO: Write the undoredo action
	# with the below being the "do" action v
	discourse_graph_edit.paste_node_clipboard(clipboard, uuid_map)


#region Phrases

func _on_scroll_dragged(offset: int, container: HSplitContainer) -> void:
	container.split_offset = offset


func _on_key_search_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	
	if clean_text == search_text_ln_edt.get_meta(&"current_search", ""):
		return
	
	var mode: int = 1 if clean_text.begins_with("key:") else 2 if clean_text.begins_with("text:") else 0
	
	if mode != 0:
		clean_text = clean_text.trim_prefix("key:" if mode == 1 else "text:")
	
	var idx: int = -1
	
	for key_child in key_container.get_children():
		idx += 1
		if clean_text.is_empty():
			key_child.visible = true
		else:
			if mode == 0:
				key_child.visible = key_child.get_child(1).text.containsn(clean_text) or text_container.get_child(idx).get_child(0).text.containsn(clean_text)
			elif mode == 1:
				key_child.visible = key_child.get_child(1).text.containsn(clean_text)
			elif mode == 2:
				key_child.visible = text_container.get_child(idx).get_child(0).text.containsn(clean_text)
		
		text_container.get_child(idx).visible = key_child.visible
	
	search_text_ln_edt.set_meta(&"current_search", clean_text)


func _on_case_search_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	
	if clean_text == search_case_ln_edt.get_meta(&"current_search", ""):
		return
	
	var mode: int = 1 if clean_text.begins_with("case:") else 2 if clean_text.begins_with("result:") else 0
	
	if mode != 0:
		clean_text = clean_text.trim_prefix("case:" if mode == 1 else "result:")
	
	
	var idx: int = -1
	for case:LineEdit in case_node_container.get_children():
		idx += 1
		
		if clean_text.is_empty():
			case.visible = true
		else:
			if mode == 0:
				case.visible = case.text.containsn(clean_text) or result_node_container.get_child(idx).get_child(0).text.containsn(clean_text)
			elif mode == 1:
				case.visible = case.text.containsn(clean_text)
			elif mode == 2:
				case.visible = result_node_container.get_child(idx).get_child(0).text.containsn(clean_text)
		
		result_node_container.get_child(idx).visible = case.visible
	
	search_case_ln_edt.set_meta(&"current_search", clean_text)


func _on_new_case_button_pressed() -> void:
	add_new_case()
	_on_conversation_changed()


func _on_erase_case_button_pressed(case_line: LineEdit) -> void:
	erase_case(case_line.get_index())
	_on_case_line_text_changed()


func _on_case_line_text_changed(_text: String = "") -> void:
	var all_ids: Dictionary[String, Array] = {}
	
	for item:LineEdit in case_node_container.get_children():
		#var line: LineEdit = item
		var key: String = item.text.strip_edges()
		
		if key.is_empty():
			continue
		
		if all_ids.has(key) == false:
			all_ids[key] = []
		all_ids[key].append(item)
	
	for item_key:String in all_ids.keys():
		if 1 < all_ids[item_key].size():
			for item:LineEdit in all_ids[item_key]:
				item.add_theme_color_override(&"font_color", Color(1.0, 0.29, 0.325))
		else:
			for item:LineEdit in all_ids[item_key]:
				if item.has_theme_color(&"font_color"):
					item.remove_theme_color_override(&"font_color")


func _on_text_line_text_submitted(_text: String, edit_btn: Button) -> void:
	edit_btn.grab_focus()


func _on_save_cases_btn_pressed() -> void:
	if selected_format != "":
		save_current_phrase_key()
		clear_cases()
		default_case_ln_edt.text = ""
		search_case_ln_edt.text = ""
		search_case_ln_edt.set_meta(&"current_search", "")
		argument_opt_btn.clear()
		selected_format = ""
	case_box_container.visible = false
	key_box_container.visible = true


func _on_edit_cases_pressed(text_line: LineEdit, key: LineEdit, button: Button) -> void:
	var phrase_key: StringName = key.get_meta(&"phrase_key")
	var lang: String = languages_tree.get_active_language()
	var reg: String = languages_tree.get_active_region()
	
	key_display_label.text = key.text.strip_edges()
	
	if not active_conversation.localized_strings.has(phrase_key):
		active_conversation.set_localized_string(
				phrase_key,
				text_line.text.strip_edges(),
				lang,
				reg)

	if active_conversation.get_localized_string(phrase_key, lang, reg) != text_line.text.strip_edges():
		active_conversation.set_localized_string(
				phrase_key,
				text_line.text.strip_edges(),
				lang,
				reg)
	
	argument_opt_btn.clear()
	
	for existing_key in active_conversation.get_localized_string_formats(phrase_key, lang, reg):
		argument_opt_btn.add_item(existing_key)
	
	selected_key = key
	default_case_ln_edt.editable = 0 < argument_opt_btn.item_count
	argument_opt_btn.disabled = not default_case_ln_edt.editable
	new_case_btn.disabled = argument_opt_btn.disabled
	
	if 0 < argument_opt_btn.item_count:
		var argument_format: String = argument_opt_btn.get_item_text(0)
		argument_opt_btn.select(0)
		default_case_ln_edt.text = active_conversation.get_localized_string_argument_default_case(phrase_key, lang, reg, argument_format)
		
		for custom_case in active_conversation.localized_strings[phrase_key][lang][reg]["arguments"][argument_format]["custom"].keys():
			add_new_case(
					custom_case,
					active_conversation.localized_strings[phrase_key][lang][reg]["arguments"][argument_format]["custom"][custom_case])
		selected_format = argument_format
	
	case_box_container.visible = true
	key_box_container.visible = false


func _on_key_line_text_changed(_text: String = "") -> void:
	var all_ids: Dictionary[String, Array] = {}
	
	for item in key_container.get_children():
		var line: LineEdit = item.get_child(1)
		var key: String = line.text.strip_edges()
		
		if key.is_empty():
			continue
		
		if all_ids.has(key) == false:
			all_ids[key] = []
		all_ids[key].append(line)
	
	for item_key:String in all_ids.keys():
		if 1 < all_ids[item_key].size():
			for item:LineEdit in all_ids[item_key]:
				item.add_theme_color_override(&"font_color", Color(1.0, 0.29, 0.325))
		else:
			for item:LineEdit in all_ids[item_key]:
				if item.has_theme_color(&"font_color"):
					item.remove_theme_color_override(&"font_color")
	
	_on_conversation_changed()


func _on_erase_key_button_pressed(key: LineEdit) -> void:
	if selected_key == key:
		selected_key = null
		selected_format = ""
		clear_cases()
		default_case_ln_edt.text = ""
		default_case_ln_edt.editable = false
		argument_opt_btn.clear()
		argument_opt_btn.disabled = true
		new_case_btn.disabled = true
	
	active_conversation.localized_strings.erase(key.get_meta(&"phrase_key"))
	
	erase_key(
		key.get_parent().get_index())
	
	_on_key_line_text_changed()


func _on_new_key_field_button_pressed() -> void:
	var phrase_key: String = add_new_phrase()
	active_conversation.create_localized_string(phrase_key, "")
	_on_conversation_changed()


func add_new_phrase(key: String = "", text: String = "") -> String:
	var new_key: HBoxContainer = new_key_container(key)
	var new_text: = new_text_field(text)
	
	key_container.add_child(new_key)
	text_container.add_child(new_text)
	
	var text_edit: LineEdit = new_text.get_child(0)
	var key_edit: LineEdit = new_key.get_child(1)
	var text_edit_btn: Button = new_text.get_child(1)
	
	if 0 < key_container.get_child_count() - 1:
		var btn: Button = text_container.get_child(-2).get_child(1)
		btn.focus_next = key_edit.get_path()
		key_edit.focus_previous = btn.get_path()
	else:
		new_text_button.focus_next = key_edit.get_path()
		key_edit.focus_previous = new_text_button.get_path()
	
	key_edit.focus_next = text_edit.get_path()
	key_edit.focus_neighbor_right = text_edit.get_path()
	
	text_edit.focus_previous = key_edit.get_path()
	text_edit.focus_neighbor_left = key_edit.get_path()
	text_edit.focus_next = text_edit_btn.get_path()
	
	text_edit_btn.focus_previous = text_edit.get_path()
	
	text_edit_btn.pressed.connect(_on_edit_cases_pressed.bind(text_edit, key_edit, text_edit_btn))
	
	return key_edit.get_meta(&"phrase_key")


func add_new_case(case: String = "", case_text: String = "") -> void:
	var new_case: LineEdit = LineEdit.new()
	var case_result: HBoxContainer = new_case_result_node()
	var result_line: LineEdit = case_result.get_child(0)
	
	new_case.placeholder_text = "Case"
	new_case.custom_minimum_size.y = 32.0
	new_case.text = case
	
	result_line.text = case_text
	
	case_node_container.add_child(new_case)
	result_node_container.add_child(case_result)
	
	new_case.focus_neighbor_right = result_line.get_path()
	result_line.focus_neighbor_left = new_case.get_path()
	new_case.focus_next = result_line.get_path()
	result_line.focus_previous = new_case.get_path()
	
	if 0 < result_node_container.get_child_count() - 1:
		var prev_case_result: LineEdit = result_node_container.get_child(-2).get_child(0)
		prev_case_result.focus_next = new_case.get_path()
		new_case.focus_previous = prev_case_result.get_path()
	else:
		new_case.focus_previous = default_case_ln_edt.get_path()
		default_case_ln_edt.focus_next = new_case.get_path()
	
	new_case.text_changed.connect(_on_case_line_text_changed)


func erase_case(index: int) -> void:
	var case: LineEdit = case_node_container.get_child(index)
	var text: Control = result_node_container.get_child(index)
	
	if case_node_container.get_child_count() - 1 <= 0:
		new_case_btn.focus_next = ^""
	else:
		if index == 0: # It's the first item
			var target_ln: LineEdit = case_node_container.get_child(1)
			new_text_button.focus_next = target_ln.get_path()
			target_ln.focus_previous = new_text_button.get_path()
		elif case_node_container.get_child_count() - 1 == index: # It's the last item
			var target_text: LineEdit = result_node_container.get_child(-2).get_child(0)
			target_text.focus_next = ^""
		else: # It's between 2 items
			var line_up: LineEdit = result_node_container.get_child(index - 1).get_child(0)
			var line_down: LineEdit = case_node_container.get_child(index + 1)
			line_up.focus_next = line_down.get_path()
			line_down.focus_previous = line_up.get_path()
	
	case_node_container.remove_child(case)
	result_node_container.remove_child(text)
	
	case.queue_free()
	text.queue_free()


func new_key_container(key: String = "") -> HBoxContainer:
	var new_key: HBoxContainer = HBoxContainer.new()
	var key_line: LineEdit = LineEdit.new()
	var erase_button: Button = Button.new()
	
	if key.is_empty():
		key_line.set_meta(&"phrase_key", UUID.generate_new())
	else:
		key_line.set_meta(&"phrase_key", key)
	
	key_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_line.custom_minimum_size.y = 32.0
	key_line.placeholder_text = "Key"
	key_line.text = String(key)
	
	erase_button.icon = get_theme_icon("Remove", "EditorIcons")
	erase_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_button.tooltip_text = "Erase key"
	erase_button.flat = true
	erase_button.custom_minimum_size = Vector2(32.0, 32.0)
	
	key_line.text_changed.connect(_on_key_line_text_changed)
	erase_button.pressed.connect(_on_erase_key_button_pressed.bind(key_line))
	
	new_key.add_child(erase_button)
	new_key.add_child(key_line)
	
	return new_key


func new_case_result_node() -> HBoxContainer:
	var new_case: HBoxContainer = HBoxContainer.new()
	var case_text: LineEdit = LineEdit.new()
	var erase_case_btn: Button = Button.new()
	
	case_text.placeholder_text = "Case format"
	case_text.custom_minimum_size.y = 32.0
	case_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	erase_case_btn.tooltip_text = "Erase case"
	erase_case_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_case_btn.flat = true
	erase_case_btn.icon = get_theme_icon("Remove", "EditorIcons")
	erase_case_btn.custom_minimum_size = Vector2(32.0, 32.0)
	erase_case_btn.pressed.connect(_on_erase_case_button_pressed.bind(case_text))
	
	new_case.add_child(case_text)
	new_case.add_child(erase_case_btn)
	
	case_text.text_changed.connect(_on_conversation_changed)
	
	return new_case


func new_text_field(text: String = "") -> HBoxContainer:
	var new_text: HBoxContainer = HBoxContainer.new()
	var new_line: LineEdit = LineEdit.new()
	var edit_button: Button = Button.new()
	
	new_line.text = text
	
	new_text.add_child(new_line)
	new_text.add_child(edit_button)
	
	new_line.custom_minimum_size.y = 32.0
	new_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_line.placeholder_text = "Phrase Text"
	edit_button.custom_minimum_size = Vector2(32.0, 32.0)
	edit_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit_button.flat = true
	edit_button.icon = get_theme_icon("Edit", "EditorIcons")
	edit_button.tooltip_text = "Edit Cases"
	
	new_line.text_submitted.connect(_on_text_line_text_submitted.bind(edit_button))
	new_line.text_changed.connect(_on_conversation_changed)
	
	return new_text


func erase_key(index: int) -> void:
	var key: Control = key_container.get_child(index)
	var text: Control = text_container.get_child(index)
	
	if key_container.get_child_count() - 1 <= 0:
		new_text_button.focus_next = ^""
	else:
		if index == 0: # It's the first item
			var target_ln: LineEdit = text_container.get_child(1).get_child(0)
			new_text_button.focus_next = target_ln.get_path()
			target_ln.focus_previous = new_text_button.get_path()
		elif key_container.get_child_count() - 1 == index: # It's the last item
			var target_btn: Button = text_container.get_child(-2).get_child(1)
			target_btn.focus_next = ^""
		else: # It's between 2 items
			var button_up: Button = text_container.get_child(index - 1).get_child(1)
			var line_down: LineEdit = text_container.get_child(index + 1).get_child(0)
			button_up.focus_next = line_down.get_path()
			line_down.focus_previous = button_up.get_path()
	
	key_container.remove_child(key)
	text_container.remove_child(text)
	
	key.queue_free()
	text.queue_free()


func clear_cases() -> void:
	for case_key in case_node_container.get_children():
		case_node_container.remove_child(case_key)
		case_key.queue_free()
	for case_result in result_node_container.get_children():
		result_node_container.remove_child(case_result)
		case_result.queue_free()


func clear_localized_keys() -> void:
	for format_key in key_container.get_children():
		key_container.remove_child(format_key)
		format_key.queue_free()
	for key_text in text_container.get_children():
		text_container.remove_child(key_text)
		key_text.queue_free()


func save_current_phrase_key(fix_cases: bool = false) -> void:
	if selected_key == null:
		return
	
	var phrase_key: String = selected_key.get_meta(&"phrase_key")
	var locale_code = languages_tree.get_active_locale()
	
	var cases: Dictionary[String, String] = {}
	var node_map: Dictionary[String, LineEdit] = {}
	
	active_conversation.set_format_string_default_case(
		phrase_key,
		locale_code,
		selected_format,
		default_case_ln_edt.text.strip_edges())
	
	var case_idx: int = -1
	var desired: String = ""
	var modified: String = ""
	var iteration: int = 0
	
	for case_key:LineEdit in case_node_container.get_children():
		case_idx += 1
		desired = case_key.text.strip_edges()
		modified = desired
		iteration = 0
		while cases.has(modified):
			iteration += 1
			modified = desired + str(iteration)
		cases[modified] = result_node_container.get_child(case_idx).get_child(0).text
		node_map[modified] = case_key
	
	active_conversation.clear_format_string_cases(
			phrase_key,
			locale_code,
			selected_format)
	
	for case in cases.keys():
		active_conversation.set_format_string_case(
			phrase_key,
			locale_code,
			selected_format,
			case,
			cases[case])
		
		if fix_cases and case != node_map[case].text.strip_edges():
			node_map[case] = case
	
	if fix_cases:
		_on_case_line_text_changed()


func save_phrase_keys(fix_keys: bool = false) -> void:
	if not languages_tree.is_lang_selected():
		return
	
	if selected_format != "":
		save_current_phrase_key(fix_keys)
	
	var lang: String = languages_tree.get_active_language()
	var reg: String = languages_tree.get_active_region()
	
	# Correct key: Current text
	var keys: Dictionary[String, String] = {}
	
	# Correct key: Line field
	var node_map: Dictionary[String, LineEdit] = {}
	
	var idx: int = -1
	var key_line: LineEdit = null
	var current_text: String = ""
	var desired: String = ""
	var iteration: int = 0
	
	for key_node in key_container.get_children():
		idx += 1
		key_line = key_node.get_child(1)
		current_text = key_line.text.strip_edges()
		desired = current_text
		iteration = 0
		while keys.has(desired):
			iteration += 1
			desired = current_text + str(iteration)
		
		keys[desired] = text_container.get_child(idx).get_child(0).text
		node_map[desired] = key_line
	
	# Duplicate old map for separate key reassignement.
	var old_phrases: Dictionary[String, Dictionary] = active_conversation.localized_strings.duplicate()
	
	active_conversation.localized_strings.clear()
	
	# Separate key reassignement is important, because if we have {a:{}, b:{}}
	# And we changed the key a -> b and b -> a, on a single dictionary we would
	# do Dictionary[b] = [a] Dictionary.erase(a), and then we would only have
	# {b: {}} so when it came to do b -> a we would've lost data of the original
	# a. So instead we duplicate the dictionary and assign the new key to the
	# old value. No data lost.
	for key in keys.keys():
		active_conversation.localized_strings[key] = old_phrases[node_map[key].get_meta(&"phrase_key")]
		node_map[key].set_meta(&"phrase_key", key)
	
	for key in keys.keys():
		if active_conversation.get_localized_string(key, lang, reg) != keys[key]:
			active_conversation.set_localized_string(key, keys[key], lang, reg)
 		
		if fix_keys and node_map[key].text.strip_edges() != key:
			node_map[key].text = key
	
	if fix_keys:
		_on_key_line_text_changed()
#endregion

func filesystem_resource_removed(resource: Resource) -> void:
	if resource == null:
		return
	conversation_tree.remove_conversation(resource)
	if resource == active_conversation:
		active_conversation = null
		set_conversation_active(false)
		_unsaved = false


func close_active_conversation() -> void:
	if active_conversation != null:
		_on_menu_close_pressed()


func display_dialog_id_checked() -> bool:
	var idx: int = file_popup.get_item_index(DiscourseFileMenuID.DISPLAY_DIALOG_ID_FIELD)
	return file_popup.is_item_checked(idx)


func set_display_dialog_id_checked(set_checked: bool) -> void:
	var idx: int = file_popup.get_item_index(DiscourseFileMenuID.DISPLAY_DIALOG_ID_FIELD)
	file_popup.set_item_checked(idx, set_checked)
	
	dialog_id_container.visible = set_checked
