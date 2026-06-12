@tool
extends PanelContainer


signal code_editor_variables_requested(path: String)

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
	LOCALIZATION_WINDOW,
	CHECK_ISSUES,
	PLAY_CURRENT_DIALOG,
	DISPLAY_DIALOG_ID_FIELD,
	RECENT_OPEN_FILES,
	}
# ------------------

const RECENT_FILE_AMOUNT_MAX: int = 10

var active_conversation: EditorDiscourseDialog = null

var localization_node_selected: DiscourseGraphNode = null

var listen_offset: bool = true

var selected_key: LineEdit = null

var _unsaved: bool = false

# ----------------------------
var _conversation_options_disabled: bool = true

var base_language: String = ""
var _included_languages: Dictionary[String, Dictionary] = {}
var current_locale: String = ""
var text_editor: Window = null
var _recently_opened_files: Array[String] = []
var _recently_opened_popup: PopupMenu = null

var phrases_index: int = -1
# ----------------------------

# --- Discourse Graph ---
@onready var conversation_tree: Tree = $MainSplitContainer/MainSidebar/SidebarSplitContainer/ConversationContainer/ConversationTree
@onready var node_search_ln_edt: LineEdit = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/SearchHbox/NodeSearchLnEdt
@onready var discourse_nodes_tree: Tree = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/NodesTree
@onready var new_folder_button: Button = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/SearchHbox/NewFolderButton
@onready var hide_issues_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/ErrorContainer/IssuesVBox/HeaderContainer/HideIssuesBtn
@onready var issues_tree: Tree = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/ErrorContainer/IssuesVBox/IssuesTree
@onready var error_container: PanelContainer = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/ErrorContainer
@onready var discourse_split_container: VSplitContainer = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer
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

@onready var locale_label: Label = $LocalizationContainer/FooterContainer/LocaleLabel
#@onready var return_discourse_btn: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/HeaderPanel/PhrasesHeader/ReturnDiscourseBtn
@onready var choices_container: VBoxContainer = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer/ChoicesScroller/ChoicesContainer

# --- Phrases ---
@onready var key_container: VBoxContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer/KeyScroll/KeySplitContainer/KeyContainer
@onready var text_container: VBoxContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer/KeyScroll/KeySplitContainer/TextContainer
@onready var case_node_container: VBoxContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/KeyScroll/CasesSplit/CaseContainer/CaseNodeContainer
@onready var result_node_container: VBoxContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/KeyScroll/CasesSplit/ResultContainer/ResultNodeContainer
@onready var default_case_ln_edt: LineEdit = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/KeyScroll/CasesSplit/ResultContainer/DefaultCaseLnEdt
@onready var argument_opt_btn: OptionButton = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/ArgumentContainer/ArgumentOptBtn
@onready var copy_arg_btn: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/ArgumentContainer/CopyArgBtn
@onready var new_case_btn: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/HeaderContainer/NewCaseBtn
@onready var new_text_button: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer/HBoxContainer/NewTextButton
@onready var search_case_ln_edt: LineEdit = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/HeaderContainer/SearchCaseLnEdt
@onready var key_display_label: Label = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/CaseKeyContainer/KeyDisplayLabel
@onready var key_box_container: VBoxContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer
@onready var case_box_container: VBoxContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer
@onready var save_case_btn: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/CaseKeyContainer/SaveCaseBtn
@onready var search_text_ln_edt: LineEdit = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer/HBoxContainer/SearchTextLnEdt
@onready var key_header_split: HSplitContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer/KeyHeaderSplit
@onready var key_split_container: HSplitContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer/KeyScroll/KeySplitContainer
@onready var case_header_split: HSplitContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/CaseHeaderSplit
@onready var cases_split: HSplitContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/KeyScroll/CasesSplit

# ----------------------------------------------

@onready var no_dialog_label: Label = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/GraphPanel/NoDialogLbl
@onready var discourse_graph_edit: GraphEdit = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/GraphPanel/DiscourseGraphEdit
var node_popup: PopupMenu = null
var file_popup: PopupMenu = null
var locale_popup: PopupMenu = null
@onready var node_menu_btn: MenuButton = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/NodeMenuBtn
@onready var save_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/SaveBtn
@onready var play_current_dialog_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/PlayDialogBtn
#@onready var localization_menu: OptionButton = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/LocalizationContainer/LocalizationMenu
@onready var close_localizer_btn: Button = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/HeaderContainer/CloseLocalizerBtn
@onready var snap_distance_spn_bx: SpinBox = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/SnapDistanceSpnBx
@onready var dialog_scene_previewer: PanelContainer = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer
@onready var phrases_lang_menu: OptionButton = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/HeaderPanel/PhrasesHeader/PhrasesLangMenu


var dialog_previewer: Node = null


func ready_plugin(base_locale: String = "") -> void:
	base_locale = TranslationServer.standardize_locale(base_locale)
	node_popup = node_menu_btn.get_popup()
	locale_popup = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/LocaleMenuBtn.get_popup()
	file_popup = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/FileMenuBtn.get_popup()
	locale_popup.max_size.y = 150
	phrases_lang_menu.get_popup().max_size.y = 250
	var open_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/OpenBtn
	var toggle_grid_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/ToggleGridBtn
	var toggle_snap_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/ToggleSnapBtn
	var toggle_minimap_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/ToggleMinimapBtn
	var sort_nodes_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/SortNodesBtn
	var collapse_left_btn: Button = $MainSplitContainer/MainSidebar/SidebarSplitContainer/ConversationContainer/HeaderContainer/CollapseLeftBtn
	var uncollapse_left_button: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/UncollapseButton
	var collapse_right_btn: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/HeaderPanel/PhrasesHeader/CollapseRigthBtn
	var uncollapse_right_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/UncollapseRightBtn
	
	var uncollapse_previewer: Button = $LocalizationContainer/FooterContainer/UncollapsePreviewBtn
	var collapse_previewer: Button = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer/HBoxContainer/ButtonContaienr/CollapsePreviewBtn
	var auto_update_previewer: Button = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer/HBoxContainer/ButtonContaienr/AutoUpdateBtn
	var play_previewer: Button = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer/HBoxContainer/ButtonContaienr/PlayTextBtn
	# --- Node Menu Items ---
	var dialogs_submenu: PopupMenu = PopupMenu.new()
	var data_submenu: PopupMenu = PopupMenu.new()
	var setting_submenu: PopupMenu = PopupMenu.new()
	_recently_opened_popup = PopupMenu.new()
	
	_recently_opened_popup.size = Vector2.ZERO
	_recently_opened_popup.max_size.x = 250
	
	dialogs_submenu.min_size.x = 120
	
	dialogs_submenu.add_theme_constant_override(&"icon_max_width", 16)
	data_submenu.add_theme_constant_override(&"icon_max_width", 16)
	setting_submenu.add_theme_constant_override(&"icon_max_width", 16)
	node_popup.add_theme_constant_override(&"icon_max_width", 16)
	
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/speech_bubble.svg"), "Dialog", DiscourseGraphNode.DialogueNodeType.DIALOG)
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/list_icon.svg"), "Options", DiscourseGraphNode.DialogueNodeType.OPTIONS)
	dialogs_submenu.add_separator("Flow")
	dialogs_submenu.add_icon_item(get_theme_icon("RandomNumberGenerator", "EditorIcons"), "Random", DiscourseGraphNode.DialogueNodeType.RANDOM)
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/branch_icon.svg"), "Branch", DiscourseGraphNode.DialogueNodeType.BRANCH)
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/match_icon.svg"), "Match", DiscourseGraphNode.DialogueNodeType.MATCH)
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/merge_icon.svg"), "Merge", DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE)
	dialogs_submenu.add_icon_item(get_theme_icon("Pause", "EditorIcons"), "Pause", DiscourseGraphNode.DialogueNodeType.PAUSE)
	dialogs_submenu.add_separator("Anchors")
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/dialog_entry.svg"), "Pointer", DiscourseGraphNode.DialogueNodeType.ANCHOR_POINTER)
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/dialog_exit.svg"), "Target", DiscourseGraphNode.DialogueNodeType.ANCHOR)
	dialogs_submenu.add_separator()
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/bulb_icon.svg"), "Event", DiscourseGraphNode.DialogueNodeType.EVENT)
	dialogs_submenu.add_icon_item(get_theme_icon("Stop", "EditorIcons"), "End", DiscourseGraphNode.DialogueNodeType.DIALOG_END)
	
	data_submenu.add_icon_item(load("res://addons/nexus_forge/icons/variable_icon.svg"), "Value", DiscourseGraphNode.DialogueNodeType.VALUE)
	data_submenu.add_icon_item(get_theme_icon("LocalVariable", "EditorIcons"), "Variable", DiscourseGraphNode.DialogueNodeType.VARIABLE_GET)
	data_submenu.add_icon_item(get_theme_icon("RandomNumberGenerator", "EditorIcons"), "Random", DiscourseGraphNode.DialogueNodeType.RANDOM_VALUE)
	data_submenu.add_icon_item(get_theme_icon("Translation", "EditorIcons"), "Localized Text", DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT)
	data_submenu.add_separator()
	data_submenu.add_icon_item(load("res://addons/nexus_forge/icons/x_or_y_icon.svg"), "Condition Value", DiscourseGraphNode.DialogueNodeType.CONDITION_SELECT)
	data_submenu.add_icon_item(load("res://addons/nexus_forge/icons/scale_icon.svg"), "Comparation", DiscourseGraphNode.DialogueNodeType.COMPARATION)
	data_submenu.add_separator()
	data_submenu.add_icon_item(load("res://addons/nexus_forge/icons/bulb_icon.svg"), "Event", DiscourseGraphNode.DialogueNodeType.DATA_EVENT)
	data_submenu.add_icon_item(get_theme_icon("Signals", "EditorIcons"), "Signal", DiscourseGraphNode.DialogueNodeType.SIGNAL)
	data_submenu.add_icon_item(get_theme_icon("Callable", "EditorIcons"), "Method", DiscourseGraphNode.DialogueNodeType.CALLABLE)
	data_submenu.add_icon_item(load("res://addons/nexus_forge/icons/callable_return_icon.svg"), "Method Return", DiscourseGraphNode.DialogueNodeType.CALLABLE_RETURN)
	data_submenu.add_separator()
	data_submenu.add_icon_item(load("res://addons/nexus_forge/icons/shield_icon.svg"), "Type Guard", DiscourseGraphNode.DialogueNodeType.TYPE_GUARD)
	data_submenu.add_separator()
	data_submenu.add_icon_item(load("res://addons/nexus_forge/icons/metadata_icon.svg"), "Metadata", DiscourseGraphNode.DialogueNodeType.METADATA)
	
	setting_submenu.add_icon_item(load("res://addons/nexus_forge/icons/gear_icon.png"), "Dialog", DiscourseGraphNode.DialogueNodeType.SETTINGS_DIALOG)
	setting_submenu.add_icon_item(load("res://addons/nexus_forge/icons/gear_icon.png"), "Character", DiscourseGraphNode.DialogueNodeType.SETTINGS_CHARACTER)
	setting_submenu.add_icon_item(load("res://addons/nexus_forge/icons/gear_icon.png"), "Option", DiscourseGraphNode.DialogueNodeType.SETTINGS_OPTION)
	
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
	node_popup.add_icon_item(load("res://addons/nexus_forge/icons/comment_icon.svg"), "Comment", DiscourseGraphNode.DialogueNodeType.COMMENT)
	node_popup.add_icon_item(get_theme_icon("ResourcePreloader", "EditorIcons"), "Resource", DiscourseGraphNode.DialogueNodeType.RESOURCE)
	node_popup.add_separator()
	node_popup.add_icon_item(load("res://addons/nexus_forge/icons/frame_icon.svg"), "Frame", 1000)
	
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
	
	close_localizer_btn.icon = get_theme_icon("GuiClose", "EditorIcons")
	
	file_popup.hide_on_checkable_item_selection = false
	
	file_popup.add_icon_item(
			get_theme_icon("New", "EditorIcons"),
			"New",
			DiscourseFileMenuID.NEW_DIALOG)
	file_popup.add_icon_item(
			get_theme_icon("Load", "EditorIcons"),
			"Open",
			DiscourseFileMenuID.OPEN_DIALOG)
	file_popup.add_submenu_node_item(
			"Recent",
			_recently_opened_popup,
			DiscourseFileMenuID.RECENT_OPEN_FILES)
	file_popup.add_icon_item(
			get_theme_icon("Save", "EditorIcons"),
			"Save",
			DiscourseFileMenuID.SAVE_DIALOG)
	file_popup.add_separator()
	file_popup.add_icon_item(
			get_theme_icon("Play", "EditorIcons"),
			"Play current dialog",
			DiscourseFileMenuID.PLAY_CURRENT_DIALOG)
	file_popup.add_item(
			"Check for issues",
			DiscourseFileMenuID.CHECK_ISSUES)
	file_popup.add_separator()
	file_popup.add_icon_item(
			get_theme_icon("Translation", "EditorIcons"),
			"Localization Window",
			DiscourseFileMenuID.LOCALIZATION_WINDOW)
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
			get_theme_icon("Close", "EditorIcons"),
			"Close",
			DiscourseFileMenuID.CLOSE_DIALOG)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.SAVE_DIALOG),
			true)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.RECENT_OPEN_FILES),
			_recently_opened_files.is_empty())
	
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
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.LOCALIZATION_WINDOW),
			true)
	
	play_previewer.icon = get_theme_icon("Play", "EditorIcons")
	# --------------------------------------------------------
	
	#update_localization_button_compact.call_deferred()
	
	search_nodes_ln_edt.right_icon = get_theme_icon("Search", "EditorIcons")
	
	conversation_tree.ready_plugin()
	discourse_nodes_tree.ready_plugin()
	issues_tree.ready_plugin()
	
	languages_tree.ready_plugin()
	localization_nodes_tree.ready_plugin()
	
	var discourse_panel: PanelContainer = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/GraphPanel
	var style: StyleBoxFlat = load("res://addons/nexus_forge/discourse/discourse_editor_stylebox.tres")
	
	style.bg_color = get_theme_color("base_color", "Editor")
	discourse_panel.add_theme_stylebox_override(&"panel", style)
	
	var system_lang = OS.get_locale_language() if base_locale.is_empty() else base_locale
	languages_tree.create_language(system_lang, true)
	add_locale(system_lang)
	base_language = system_lang
	languages_tree.set_default_language(system_lang)
	current_locale = system_lang
	set_graph_locale_tip(system_lang)
	set_phrase_button_locale(system_lang)
	
	var locale_settings: PackedStringArray = StringUtils.split_and_strip(
			ProjectSettings.get_setting(
					EditorNFPlugin.get_project_settings_path("discourse_use_languages"), ""),
			",",
			false)
	
	for entry in locale_settings:
		var parts: PackedStringArray = entry.split("_", false)
		var part_size: int = parts.size()
		if part_size <= 0 or 2 < part_size:
			push_warning(
				"[NEXUS FORGE] Discourse - Discourse languages only support language + region: " + entry)
			continue
		
		if not _included_languages.has(parts[0]):
			_included_languages[parts[0]] = {}
		
		if 1 < part_size:
			_included_languages[parts[0]][parts[1]] = null
	
	if discourse_graph_edit.entry_node != null:
		_on_discourse_node_created(discourse_graph_edit.entry_node)
	
	$MainSplitContainer.visible = true
	$LocalizationContainer.visible = false
	new_folder_button.disabled = true
	new_folder_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	
	#return_discourse_btn.icon = get_theme_icon("GuiClose", "EditorIcons")
	
	save_case_btn.icon = get_theme_icon("ArrowLeft", "EditorIcons")
	
	hide_issues_btn.icon = get_theme_icon("GuiClose", "EditorIcons")
	
	discourse_graph_edit.panning_scheme = GraphEdit.SCROLL_PANS if ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("discourse_panning_scheme"), true) else GraphEdit.SCROLL_ZOOMS
	
	play_current_dialog_btn.icon = get_theme_icon("MainPlay", "EditorIcons")
	
	copy_arg_btn.icon = get_theme_icon("ActionCopy", "EditorIcons")
	
	if EditorNFPlugin.is_preview_scene_valid(false):
		var path: String = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("discourse_localization_preview_scene"))
		uncollapse_previewer.visible = true
		dialog_previewer = load(path).instantiate()
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer/HBoxContainer/PreviewPanel.add_child(dialog_previewer)
	else:
		uncollapse_previewer.visible = false
	
	var lambda: Callable = func() -> void:
		key_header_split.split_offset = key_split_container.split_offset
	
	lambda.call_deferred()
	
	$MainSplitContainer/ActiveWindowSplit/PhrasesContainer.visible = false
	
	
	# --------------------------------------------------------
	dialogs_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	data_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	setting_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	_recently_opened_popup.index_pressed.connect(_on_recent_file_index_pressed)
	node_popup.id_pressed.connect(_on_create_dialog_id_pressed)
	close_localizer_btn.pressed.connect(_on_switch_window_pressed)
	file_popup.id_pressed.connect(_on_file_menu_id_pressed)
	#localization_menu.item_selected.connect(_on_localization_selected)
	#localization_menu.resized.connect(_on_localization_resized)
	# --------------------------------------------------------
	
	open_btn.pressed.connect(_on_open_conversation_pressed)
	save_btn.pressed.connect(_on_save_conversation_pressed)
	
	discourse_graph_edit.dialog_changed.connect(_on_conversation_changed)
	discourse_graph_edit.localization_enabled.connect(_on_localize_node)
	discourse_graph_edit.nodes_removed.connect(_on_nodes_removed)
	discourse_graph_edit.node_created.connect(_on_discourse_node_created)
	discourse_graph_edit.node_duplication_requested.connect(_on_graph_edit_node_duplication_requested)
	discourse_graph_edit.paste_nodes_requested.connect(_on_graph_edit_paste_requested)
	discourse_graph_edit.use_code_editor_requested.connect(_on_open_code_editor_graph_request)
	
	discourse_graph_edit.discourse_node_selected.connect(_on_discourse_node_selected)
	discourse_graph_edit.scroll_offset_changed.connect(_on_graph_edit_offset_changed)
	
	node_search_ln_edt.text_changed.connect(_on_discourse_node_search_text_changed)
	new_language_btn.pressed.connect(_on_new_lang_pressed)
	languages_tree.locale_changed.connect(_on_side_editor_locale_changed, CONNECT_DEFERRED)
	languages_tree.region_created.connect(_on_region_created)
	languages_tree.locale_deleted.connect(_on_locale_deleted)
	
	discourse_nodes_tree.directory_edited.connect(_on_conversation_changed)
	discourse_nodes_tree.item_renamed.connect(_on_discourse_item_renamed)
	discourse_nodes_tree.node_structure_changed.connect(_on_conversation_changed)
	discourse_nodes_tree.node_activated.connect(_on_discourse_node_activated)
	discourse_nodes_tree.collapsed_state_changed.connect(_on_collapsed_state_changed)
	localization_nodes_tree.dialog_selected.connect(_on_localizer_node_selected)
	localization_nodes_tree.node_delocalized.connect(_on_node_delocalized)
	localization_nodes_tree.dialog_item_edited.connect(_on_localizer_item_renamed)
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
	
	copy_arg_btn.pressed.connect(_on_copy_format_pressed, CONNECT_DEFERRED)
	
	collapse_left_btn.pressed.connect(_on_collapse_left_pressed)
	uncollapse_left_button.pressed.connect(_on_uncollapse_left_pressed)
	
	collapse_right_btn.pressed.connect(_on_collapse_right_pressed)
	uncollapse_right_btn.pressed.connect(_on_uncollapse_right_pressed)
	
	phrases_lang_menu.item_selected.connect(_on_phrase_button_item_selected)
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer/HBoxContainer/ButtonContaienr/AutoUpdateBtn.toggled.connect(_on_auto_update_toggled)


func get_column_left() -> Control:
	return $MainSplitContainer/MainSidebar


func _add_locale_phrase_menu(lang: String, country: String) -> void:
	# Title, code
	var entries: Dictionary[String, String] = {}
	var entry_found: bool = false
	var locale_code: String = lang if country.is_empty() else lang + "_" + country
	
	for item_idx in range(phrases_lang_menu.item_count):
		var code: String = phrases_lang_menu.get_item_metadata(item_idx)
		entries[phrases_lang_menu.get_item_text(item_idx)] = code
		if code == locale_code:
			entry_found = true
	
	if entry_found:
		return
	
	var selected: String = phrases_lang_menu.get_item_text(phrases_lang_menu.selected) if phrases_lang_menu.selected != -1 else ""
	var item_selected: bool = phrases_lang_menu.selected != -1
	var title: String = TranslationServer.get_language_name(lang)
	if not country.is_empty():
		title += " (" + TranslationServer.get_country_name(country) + ")"
	
	entries[title] = locale_code
	
	var all_titles: Array[String] = []
	all_titles.assign(entries.keys())
	all_titles.sort()
	
	phrases_lang_menu.clear()
	
	for item in all_titles:
		phrases_lang_menu.add_item(item)
		phrases_lang_menu.set_item_metadata(-1, entries[item])
	
	if item_selected:
		phrases_index = all_titles.find(selected)
		phrases_lang_menu.select(phrases_index)
	else:
		phrases_lang_menu.select(-1)
		phrases_index = -1


func _remove_locale_phrase_menu(lang: String, country: String) -> void:
	var locale: String = lang if country.is_empty() else lang + "_" + country
	var new_select: int = -1
	var selected: String = "" if phrases_lang_menu.selected == -1 else phrases_lang_menu.get_selected_metadata()
	var entries: Dictionary[String, String] = {}
	var reload: bool = false
	
	for idx in range(phrases_lang_menu.item_count):
		entries[phrases_lang_menu.get_item_metadata(idx)] = phrases_lang_menu.get_item_text(idx)
	
	if not entries.has(locale):
		return
	
	entries.erase(locale)
	
	var codes: Array[String] = []
	codes.assign(entries.keys())
	codes.sort_custom(func(a,b): return entries[a] < entries[b])
	
	phrases_lang_menu.clear()
	new_select = codes.find(selected)
	
	for locale_code in codes:
		phrases_lang_menu.add_item(entries[locale_code])
		phrases_lang_menu.set_item_metadata(-1, locale_code)
	
	phrases_lang_menu.select(new_select)


func set_phrase_button_locale(locale: String) -> void:
	for idx in range(phrases_lang_menu.item_count):
		if phrases_lang_menu.get_item_metadata(idx) == locale:
			phrases_lang_menu.select(idx)
			phrases_lang_menu.text = locale
			phrases_index = idx
			return


func _on_phrase_button_item_selected(idx: int) -> void:
	var locale: String = phrases_lang_menu.get_item_metadata(idx)
	var prev_locale: String = "" if phrases_index == -1 else phrases_lang_menu.get_item_metadata(phrases_index)
	phrases_lang_menu.text = locale
	phrases_lang_menu.tooltip_text = phrases_lang_menu.get_item_text(idx)
	save_phrase_keys(prev_locale)
	set_phrases_locale(locale)
	phrases_index = idx


func set_phrases_locale(locale: String) -> void:
	for item_index in range(key_container.get_child_count()):
		var line: LineEdit = key_container.get_child(item_index).get_child(1)
		var text_field: LineEdit = text_container.get_child(item_index).get_child(0)
		var key: String = line.get_meta(&"phrase_key")
		
		text_field.text = active_conversation.get_format_string(
				key,
				locale)


func add_locale(locale_code: String) -> void:
	var locale_parts: PackedStringArray = locale_code.split("_", false, 1)
	var language: String = locale_parts[0]
	var region: String = locale_parts[1] if locale_parts.size() == 2 else ""
	var selected_language: String = ""
	var selected_country: String = ""
	var existing_locales: Array[Dictionary] = []
	
	var lang_index: int = -1
	
	for idx in range(locale_popup.item_count):
		if locale_popup.get_item_metadata(idx) == language:
			lang_index = idx
			break
	
	if lang_index == -1:
		var lang_name: String = TranslationServer.get_language_name(language)
		var items: Dictionary[String, Dictionary] = {
			language: {"name": lang_name, "popup": _new_lang_submenu()}}
		var orphans: Array[PopupMenu] = []
		
		for item_idx in range(locale_popup.item_count):
			var lang_code: String = locale_popup.get_item_metadata(item_idx)
			var popup: PopupMenu = locale_popup.get_item_submenu_node(item_idx)
			if items.has(lang_code):
				orphans.append(popup)
			else:
				items[lang_code] = {
					"name": locale_popup.get_item_text(item_idx),
					"popup": popup}
		
		var existing_menus: Array[String] = []
		existing_menus.assign(items.keys())
		existing_menus.sort()
		
		locale_popup.clear(false)
		for orp in orphans:
			orp.free()
		
		for lang_code in existing_menus:
			locale_popup.add_submenu_node_item(
					items[lang_code]["name"],
					items[lang_code]["popup"])
			locale_popup.set_item_metadata(-1, lang_code)
		
		lang_index = existing_menus.find(language)
	
	_add_locale_phrase_menu(language, region)
	
	if region.is_empty():
		return
	
	var submenu: PopupMenu = locale_popup.get_item_submenu_node(lang_index)
	var found: bool = false
	
	for idx in range(submenu.item_count):
		if submenu.get_item_metadata(0) == region:
			found = true
			break
	
	if not found:
		var existing_items: Dictionary[String, String] = {
			region: TranslationServer.get_country_name(region)}
		for idx in range(submenu.item_count):
			existing_items[submenu.get_item_metadata(idx)] = submenu.get_item_text(idx)
		
		submenu.clear()
		var items: Array[String] = []
		items.assign(existing_items.keys())
		items.sort()
		
		for lang_code in items:
			submenu.add_item(existing_items[lang_code])
			submenu.set_item_metadata(-1, lang_code)


func _new_lang_submenu() -> PopupMenu:
	var pop: PopupMenu = PopupMenu.new()
	pop.add_item("Base")
	pop.set_item_metadata(0, "")
	pop.size = Vector2i.ZERO
	pop.index_pressed.connect(_on_locale_submenu_idx_pressed.bind(pop))
	pop.max_size.y = 150
	return pop


func has_locale(locale: String) -> bool:
	if locale.is_empty():
		return false
	
	var parts: PackedStringArray = TranslationServer.standardize_locale(locale).split("_", false, 1)
	var lang_code: String = parts[0]
	var reg_code: String = parts[1] if parts.size() == 2 else ""
	
	for idx in range(locale_popup.item_count):
		if locale_popup.get_item_metadata(idx) == lang_code:
			if reg_code.is_empty():
				return true
			else:
				var sub: PopupMenu = locale_popup.get_item_submenu_node(idx)
				for sub_idx in range(sub.item_count):
					if sub.get_item_metadata(sub_idx) == reg_code:
						return true
			break
	
	return false


func clear_locales(clear_main: bool = true) -> void:
	locale_popup.clear(true)
	if not clear_main:
		add_locale(base_language)
	
	current_locale = "" if clear_main else base_language
	languages_tree.clear_languages(clear_main)
	localization_nodes_tree.get_root().collapsed = true


func remove_locale(locale: String) -> void:
	if locale.is_empty():
		return
	
	var parts: PackedStringArray = TranslationServer.standardize_locale(locale).split("_")
	var lang: String = parts[0]
	var reg: String = parts[1] if parts.size() == 2 else ""
	
	_remove_locale_phrase_menu(lang, reg)
	
	if locale == current_locale:
		current_locale = base_language
		set_graph_locale_tip(base_language)
		_on_graph_editor_locale_changed("", base_language)
	
	if phrases_index != -1 and phrases_lang_menu.get_selected_metadata() == locale:
		set_phrases_locale(base_language)
		set_phrase_button_locale(base_language)
	
	for idx in range(locale_popup.item_count):
		if locale_popup.get_item_metadata(idx) == lang:
			if reg.is_empty():
				locale_popup.get_item_submenu_node(idx).free()
				locale_popup.remove_item(idx)
				break
			else:
				var sub: PopupMenu = locale_popup.get_item_submenu_node(idx)
				for sub_idx in range(sub.item_count):
					if sub.get_item_metadata(sub_idx) == reg:
						sub.remove_item(sub_idx)
						break
			break


func set_graph_edit_visible(graph_visible: bool) -> void:
	no_dialog_label.visible = not graph_visible
	discourse_graph_edit.visible = graph_visible
	if graph_visible and discourse_graph_edit.size != size:
		discourse_graph_edit.size = size


func set_conversation_options_enabled(are_enabled: bool) -> void:
	var disabled: bool = !are_enabled
	node_menu_btn.disabled = disabled
	$MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/LocaleMenuBtn.disabled = disabled
	save_btn.disabled = disabled
	play_current_dialog_btn.disabled = disabled
	snap_distance_spn_bx.editable = are_enabled
	phrases_lang_menu.disabled = disabled
	
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
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.LOCALIZATION_WINDOW),
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


#func _on_localization_selected(idx: int) -> void:
	#var old_locale: String = current_locale
	#
	#if idx == -1:
		#localization_menu.tooltip_text = ""
		#current_locale = ""
	#else:
		#var locale_data: Dictionary = localization_menu.get_item_metadata(idx)
		#var lang_code: String = locale_data["language_code"]
		#var count_code: String = locale_data["country_code"]
		#if locale_button_compact:
			#if count_code.is_empty():
				#localization_menu.text = lang_code
			#else:
				#localization_menu.text = lang_code + "_" + count_code
		#current_locale = TranslationServer.standardize_locale(lang_code if count_code.is_empty() else lang_code + "_" + count_code)
		#localization_menu.tooltip_text = localization_menu.get_item_text(idx)
	#
	#_on_graph_editor_locale_changed(old_locale, current_locale)


func _on_locale_submenu_idx_pressed(idx: int, submenu: PopupMenu) -> void:
	var from: String = current_locale
	var count: String = submenu.get_item_metadata(idx)
	var lang: String = ""
	
	for item_idx in range(locale_popup.item_count):
		if locale_popup.get_item_submenu_node(item_idx) == submenu:
			lang = locale_popup.get_item_metadata(item_idx)
			break
	
	if lang.is_empty():
		push_error("[DISCOURSE] ERROR SELECTING LOCALE")
		return
	
	var to: String = lang if count.is_empty() else lang + "_" + count
	
	set_graph_locale_tip(to)
	_on_graph_editor_locale_changed(from, to)
	current_locale = to


func set_graph_locale_tip(locale: String) -> void:
	var label: Label = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/GraphLocaleLbl
	
	if locale.is_empty():
		label.text = "Current Locale:"
		return
	
	var locale_parts: PackedStringArray = locale.split("_", false, 1)
	var language: String = locale_parts[0]
	var region: String = locale_parts[1] if locale_parts.size() == 2 else ""
	
	var language_name: String = TranslationServer.get_language_name(language)
	
	var locale_text: String = "" if region.is_empty() else TranslationServer.get_country_name(region) 
	
	if not locale_text.is_empty():
		if locale_text.to_lower().ends_with("s"):
			locale_text += "' "
		else:
			locale_text += "'s "
	
	locale_text += language_name
	
	label.text = "Current Locale: " + locale_text


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
			var idx: int = file_popup.get_item_index(id)
			var display: bool = !file_popup.is_item_checked(idx)
			file_popup.set_item_checked(idx, display)
			
			_on_display_dialog_id_toggled(display)
		DiscourseFileMenuID.LOCALIZATION_WINDOW:
			_on_switch_window_pressed()


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


func _on_collapsed_state_changed() -> void:
	if not listen_offset or conversation_tree.active_conversation_item == null or conversation_tree.active_offset_changed:
		return
	
	conversation_tree.active_offset_changed = true


func _on_graph_edit_offset_changed(_offset: Vector2) -> void:
	if not listen_offset or conversation_tree.active_conversation_item == null or conversation_tree.active_offset_changed:
		return
	
	conversation_tree.active_offset_changed = true


func _on_conversation_close_pressed(dialog: EditorDiscourseDialog, save_required: bool, offset_changed: bool) -> void:
	var close_current: bool = dialog == active_conversation
	if save_required:
		var unsaved_prompt: AcceptDialog = preload("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
		add_child(unsaved_prompt)
		unsaved_prompt.show()
		var result: int = await unsaved_prompt.dialog_finished
		if result == 0: # Save
			if close_current:
				save_current_dialog()
		elif result == 1: # Don't save
			offset_changed = false
		elif result == 2: # Cancel
			unsaved_prompt.queue_free()
			return
		unsaved_prompt.queue_free()
	
	if offset_changed:
		var layout_data: Dictionary[String, Variant] = {
			"collapsed_state": discourse_nodes_tree.get_collapsed_folders() if close_current else dialog.collapsed_state,
			"zoom": discourse_graph_edit.zoom if close_current else dialog.zoom,
			"scroll_offset": discourse_graph_edit.scroll_offset if close_current else dialog.scroll_offset}
		
		_save_file_layout_for(
				dialog.resource_path,
				layout_data)
	
	conversation_tree.remove_conversation(dialog)
	
	if not close_current:
		return
	
	key_box_container.visible = true
	case_box_container.visible = false
	
	if conversation_tree.active_conversation_item == null:
		active_conversation = null
		set_conversation_active(false)
		display_conversation(null)
		clear_localized_keys()
		clear_cases()
		conversation_tree.active_unsaved = false
		selected_key = null
		new_text_button.disabled = true
		return
	
	var new_resource: EditorDiscourseDialog = conversation_tree.get_active_resource()
	
	if open_conversation(new_resource):
		conversation_tree.active_unsaved = true
	
	_unsaved = conversation_tree.active_unsaved
	selected_key = null


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
		elif result == 1: # Don't save
			pass
		elif result == 2: # Cancel
			unsaved_prompt.queue_free()
			return
		unsaved_prompt.queue_free()
	elif conversation_tree.active_offset_changed:
		var layout_data: Dictionary[String, Variant] = {
			"collapsed_state": discourse_nodes_tree.get_collapsed_folders(),
			"zoom": discourse_graph_edit.zoom,
			"scroll_offset": discourse_graph_edit.scroll_offset}
		
		_save_file_layout_for(
				active_conversation.resource_path,
				layout_data)
	
	key_box_container.visible = true
	case_box_container.visible = false
	conversation_tree.remove_conversation(active_conversation)
	
	if conversation_tree.active_conversation_item == null:
		active_conversation = null
		set_conversation_active(false)
		display_conversation(null)
		clear_localized_keys()
		clear_cases()
		conversation_tree.active_unsaved = false
		selected_key = null
		new_text_button.disabled = true
		return
	
	var new_resource: EditorDiscourseDialog = conversation_tree.get_active_resource()
	
	if open_conversation(new_resource):
		conversation_tree.active_unsaved = true
	
	_unsaved = conversation_tree.active_unsaved
	selected_key = null
	#selected_format = ""


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
	window.select_language(base_language)
	add_child(window)
	window.popup()
	window.focus_option_button()
	var result: String = await window.dialog_finished
	
	if result != "":
		if not languages_tree.has_language(result):
			languages_tree.create_language(result, true)
			add_locale(result)
			active_conversation.add_locale(result)
			
		ProjectSettings.set_setting(
				EditorNFPlugin.get_project_settings_path(
						"discourse_base_language"),
				result)
		ProjectSettings.save()
		base_language = result
		languages_tree.set_default_language(result)
	window.queue_free()


func _on_translation_text_changed() -> void:
	if languages_tree.get_active_locale() == base_language:
		base_text_edt.text = translation_txt_box.text
	_on_text_changed_sync(translation_txt_box.text)


func _on_conversation_changed(_arg = null) -> void:
	if not _unsaved:
		_unsaved = true
	
	if active_conversation != null:
		conversation_tree.active_unsaved = true


func _on_graph_editor_locale_changed(from: String, to: String) -> void:
	if not from.is_empty():
		discourse_graph_edit.update_localization_data(active_conversation, from)
		#save_phrase_keys(from)
	
	clear_cases()
	default_case_ln_edt.text = ""
	search_case_ln_edt.text = ""
	search_case_ln_edt.set_meta(&"current_search", "")
	argument_opt_btn.clear()
	
	search_text_ln_edt.text = ""
	search_text_ln_edt.set_meta(&"current_search", "")
	
	if to.is_empty():
		return
	
	var data: Dictionary = active_conversation.get_display_localization_data(to)
	update_localization_display(data)
	


func _on_side_editor_locale_changed(from: String, to: String) -> void:
	var invalid_language: bool = to.is_empty()
	var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	localization_nodes_tree.get_root().collapsed = invalid_language
	
	set_localization_tip(to)
	
	if not from.is_empty():
		#save_phrase_keys(from)
		save_localizer_data(from)
		
		if active_node != null and from == current_locale:
			var uuid: StringName = active_node.get_node_uuid()
			match active_node.node_type:
				DiscourseGraphNode.DialogueNodeType.DIALOG:
					var text: String = translation_txt_box.text.strip_edges()
					active_node.set_dialog_text(text)
				DiscourseGraphNode.DialogueNodeType.OPTIONS:
					var choices: = get_localizer_choices()
					var choice_n: int = 0
					for choice in choices:
						choice_n += 1
						active_node.set_option_text(choice_n, choice)
				DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
					var text: String = translation_txt_box.text.strip_edges()
					active_node.set_text(translation_txt_box.text.strip_edges())
	#save_phrase_keys(from)
	#clear_cases()
	#default_case_ln_edt.text = ""
	#search_case_ln_edt.text = ""
	#search_case_ln_edt.set_meta(&"current_search", "")
	#argument_opt_btn.clear()
	#
	#search_text_ln_edt.text = ""
	#search_text_ln_edt.set_meta(&"current_search", "")
	
	if to.is_empty():
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = false
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = false
		return
	
	#for item_index in range(key_container.get_child_count()):
		#var line: LineEdit = key_container.get_child(item_index).get_child(1)
		#var text_field: LineEdit = text_container.get_child(item_index).get_child(0)
		#var key: String = line.get_meta(&"phrase_key")
		#
		#text_field.text = active_conversation.get_format_string(
				#key,
				#to)
	
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
		var base_size: int = base_options.size()
		
		if base_size != active_node.choice_count():
			base_options.resize(active_node.choice_count())
		
		var localized_options: Array[String] = active_conversation.get_choices_entry(
				active_node.get_node_uuid(),
				to)
		
		var localized_size: int = localized_options.size()
		
		if localized_size < base_size:
			localized_options.append_array(base_options.slice(localized_size))
		
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
				var options: Array[String] = get_localizer_choices()
				
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
			var base_size: int = options_base.size()
			if base_size != new_node.choice_count():
				options_base.resize(new_node.choice_count())
			var options_localized: Array[String] = active_conversation.get_choices_entry(uuid, active_locale)
			var localized_size: int = options_localized.size()
			
			if localized_size < base_size:
				options_localized.append_array(options_base.slice(localized_size))
			
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
			localization_nodes_tree.create_dialog_node(node.get_node_id(), node)
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			var text_options: Array[String] = node.get_options()
			active_conversation.set_choices_entry(
					node.get_node_uuid(),
					text_options,
					current_locale)
			localization_nodes_tree.create_options_node(node.get_node_id(), node)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			active_conversation.set_text_entry(
					node.get_node_uuid(),
					node.get_text(),
					current_locale)
			localization_nodes_tree.create_localized_text_node(node.get_node_id(), node)


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
			
			if dialog_previewer != null:
				dialog_previewer.set_choices(options)
				
		else: # Either dialog or localized text. Same method can be used.
			var text: String = active_conversation.get_text_entry(
					active_node.get_node_uuid(),
					localizer_locale,
					"")
			base_text_edt.text = active_conversation.get_text_entry(
					active_node.get_node_uuid(),
					languages_tree.get_base_language())
			translation_txt_box.text = text
			
			if dialog_previewer != null:
				dialog_previewer.set_dialog(text)
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
		var active_locale: String = languages_tree.get_active_locale()
		if selected_key != null and argument_opt_btn.selected != -1 and not active_locale.is_empty():# selected_format != "":
			save_current_phrase_key(active_locale)
		
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
		issues_tree.add_issue("No issue found", &"")
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


func get_recenlty_opened_files() -> Array[String]:
	return _recently_opened_files.duplicate()


func set_recently_opened_files(new_files: Array[String]) -> void:
	var files: Array[String] = []
	
	if RECENT_FILE_AMOUNT_MAX < new_files.size():
		files.assign(new_files.slice(0, RECENT_FILE_AMOUNT_MAX))
	else:
		files.assign(new_files)
	
	_recently_opened_files.assign(files)
	update_recently_opened_files()


func update_recently_opened_files() -> void:
	var existing_items: Dictionary[String, String] = {}
	
	for existing_idx in range(_recently_opened_popup.item_count):
		existing_items[_recently_opened_popup.get_item_metadata(existing_idx)] = _recently_opened_popup.get_item_text(existing_idx)
	
	_recently_opened_popup.clear()
	
	for path_index in range(_recently_opened_files.size() - 1, -1, -1):
		var display: String = ""
		var filepath: String = _recently_opened_files[path_index]
		
		if existing_items.has(filepath):
			display = existing_items[filepath]
		else:
			var file_name: String = filepath.get_file().get_basename()
			var full_string: String = file_name + " [" + filepath + "]"
			display = _truncate_with_elipsis(full_string, 200)
		
		_recently_opened_popup.add_item(display)
		_recently_opened_popup.set_item_metadata(-1, filepath)
		_recently_opened_popup.set_item_tooltip(-1, filepath)
	
	file_popup.set_item_disabled(
			file_popup.get_item_index(
					DiscourseFileMenuID.RECENT_OPEN_FILES),
			_recently_opened_files.is_empty())
	
	_reset_recent_popup_size.call_deferred()


func load_dialog_files(files: Array[String]) -> void:
	for file in files:
		if not FileAccess.file_exists(file):
			continue
		var loaded: Resource = load(file)
		if loaded != null and loaded is EditorDiscourseDialog:
			var filename: String = file.get_file()
			var path_hash: String = file.md5_text()
			var absolute_path: String = ProjectSettings.globalize_path("res://.godot/editor/")
			var config_filename: String = filename + "-graphstate-" + path_hash + ".cfg"
			var full_path: String = absolute_path.path_join(config_filename)
			if FileAccess.file_exists(full_path):
				var cfg: ConfigFile = ConfigFile.new()
				if cfg.load(full_path) == OK:
					var position_offset: Vector2 = cfg.get_value("Layout", "scroll_offset", Vector2.ZERO)
					var zoom: float = cfg.get_value("Layout", "zoom", 1.0)
					var collapsed_state: Dictionary[String, bool] = {}
					var cfg_collapsed = cfg.get_value("Layout", "collapsed_state", {})
					if typeof(cfg_collapsed) == TYPE_DICTIONARY:
						for key in cfg_collapsed.keys():
							if typeof(key) == TYPE_STRING and typeof(cfg_collapsed[key]) == TYPE_BOOL:
								collapsed_state[key] = cfg_collapsed[key]
					loaded.scroll_offset = position_offset
					loaded.zoom = zoom
					loaded.collapsed_state.assign(collapsed_state)
			
			if conversation_tree.is_conversation_open(loaded):
				continue
			else:
				load_conversation(loaded, false)


func save_current_dialog_to_memory() -> void:
	# Saves the current unsaved node data to the file and assings the localized
	# data to the current selected dropdown locale.
	discourse_graph_edit.update_conversation_file(active_conversation, current_locale)
	
	active_conversation.collapsed_state = discourse_nodes_tree.get_collapsed_folders()
	active_conversation.zoom = discourse_graph_edit.zoom
	active_conversation.scroll_offset = discourse_graph_edit.scroll_offset
	active_conversation.node_structure = discourse_nodes_tree.get_folder_structure()
	active_conversation.dialog_id = dialog_id_ln_edt.text.strip_edges()


func _on_conversation_selected(dialog: EditorDiscourseDialog) -> void:
	if _conversation_options_disabled:
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
	
	localization_lnedt.text_changed.connect(_on_choice_text_changed.bind(new_container.get_index()))


func get_localizer_choices() -> Array[String]:
	var choices: Array[String] = []
	
	for choice in choices_container.get_children():
		choices.append(choice.get_child(2).text.strip_edges())
	
	return choices


func _on_localizer_item_renamed(node_uuid: StringName, desired_id: String) -> void:
	var node: DiscourseGraphNode = discourse_nodes_tree.get_discourse_node(node_uuid)
	
	if node == null:
		return
	
	var proper_name: StringName = discourse_graph_edit.get_unique_node_name(
			StringName(desired_id),
			node_uuid)
	
	var proper_string: String = String(proper_name)
	
	node.set_node_id(proper_name)
	
	localization_nodes_tree.set_node_name(node_uuid, proper_string)
	discourse_nodes_tree.set_node_id(node_uuid, proper_string)
	
	_on_conversation_changed()


func _on_new_conversation_pressed() -> void:
	var file_saver: AcceptDialog = preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	file_saver.file_mode = file_saver.FILE_MODE_SAVE_FILE
	add_child(file_saver)
	file_saver.popup_centered()
	
	var result: Array = await file_saver.dialog_finished
	
	if result[0]:
		listen_offset = false
		if active_conversation != null:
			save_current_dialog_to_memory()
		var new_conv: EditorDiscourseDialog = EditorDiscourseDialog.new()
		new_conv.locale_map.assign(get_settings_languages_as_map())
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
		
		discourse_graph_edit.reset_scroll_offset.call_deferred()
		
		set_deferred(&"listen_offset", true)
		
		add_to_recently_opened_files(result[1])
		
	file_saver.queue_free()


func get_settings_languages_as_map() -> Dictionary:
	var language_map: Dictionary[String, Dictionary] = _included_languages.duplicate(true)
	if not language_map.has(base_language):
		language_map[base_language] = {}
	
	return language_map


func load_dialog_from_file(file_path: String) -> EditorDiscourseDialog:
	var resource = load(file_path)
	if resource == null or not resource is EditorDiscourseDialog:
		return null
	
	var dialog_resource: EditorDiscourseDialog = resource
	
	if conversation_tree.is_conversation_open(dialog_resource):
		return dialog_resource
	
	var filename: String = file_path.get_file()
	var path_hash: String = file_path.md5_text()
	var absolute_path: String = ProjectSettings.globalize_path("res://.godot/editor/")
	var config_filename: String = filename + "-graphstate-" + path_hash + ".cfg"
	var full_path: String = absolute_path.path_join(config_filename)
	
	if FileAccess.file_exists(full_path):
		var cfg: ConfigFile = ConfigFile.new()
		if cfg.load(full_path) == OK:
			var position_offset: Vector2 = cfg.get_value("Layout", "scroll_offset", Vector2.ZERO)
			var zoom: float = cfg.get_value("Layout", "zoom", 1.0)
			var collapsed_state: Dictionary[String, bool] = {}
			var cfg_collapsed = cfg.get_value("Layout", "collapsed_state", {})
			
			if typeof(cfg_collapsed) == TYPE_DICTIONARY:
				for key in cfg_collapsed.keys():
					if typeof(key) == TYPE_STRING and typeof(cfg_collapsed[key]) == TYPE_BOOL:
						collapsed_state[key] = cfg_collapsed[key]
			
			dialog_resource.collapsed_state.assign(collapsed_state)
			dialog_resource.scroll_offset = position_offset
			dialog_resource.zoom = zoom
	
	load_conversation(dialog_resource, false)
	
	return dialog_resource


func _on_open_conversation_pressed() -> void:
	var file_opener: AcceptDialog = preload("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	file_opener.file_mode = file_opener.FILE_MODE_OPEN_FILE
	add_child(file_opener)
	file_opener.popup_centered()
	
	var result: Array = await file_opener.dialog_finished
	
	if result[0] and FileAccess.file_exists(result[1]):
		listen_offset = false
		var resource: Resource = load(result[1])
		if resource != null and resource is EditorDiscourseDialog:
			var filename: String = result[1].get_file()
			var path_hash: String = result[1].md5_text()
			var absolute_path: String = ProjectSettings.globalize_path("res://.godot/editor/")
			var config_filename: String = filename + "-graphstate-" + path_hash + ".cfg"
			var full_path: String = absolute_path.path_join(config_filename)
			if FileAccess.file_exists(full_path):
				var cfg: ConfigFile = ConfigFile.new()
				if cfg.load(full_path) == OK:
					var position_offset: Vector2 = cfg.get_value("Layout", "scroll_offset", Vector2.ZERO)
					var zoom: float = cfg.get_value("Layout", "zoom", 1.0)
					var collapsed_state: Dictionary[String, bool] = {}
					var cfg_collapsed = cfg.get_value("Layout", "collapsed_state", {})
					
					if typeof(cfg_collapsed) == TYPE_DICTIONARY:
						for key in cfg_collapsed.keys():
							if typeof(key) == TYPE_STRING and typeof(cfg_collapsed[key]) == TYPE_BOOL:
								collapsed_state[key] = cfg_collapsed[key]
					
					resource.collapsed_state.assign(collapsed_state)
					resource.scroll_offset = position_offset
					resource.zoom = zoom
			
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
			
			add_to_recently_opened_files(result[1])
		
		set_deferred(&"listen_offset", true)
	
	file_opener.queue_free()


func _on_play_current_dialog_pressed() -> void:
	if active_conversation == null:
		return
	var res_path: String = active_conversation.resource_path
	var custom_scene: String = ProjectSettings.get_setting(EditorNFPlugin.get_project_settings_path("discourse_custom_dialog_debug_scene"), "").strip_edges()
	var scene_path: String = "res://addons/nexus_forge/discourse/dialog_previewer.tscn" if custom_scene.is_empty() or not FileAccess.file_exists(custom_scene) else custom_scene
	
	if res_path.is_empty():
		push_error("[NexusForge] Discourse: Path of current conversation is empty.")
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
		if not item.has("is_node"):
			continue
		
		if item["is_node"]:
			if item.has("uuid"):
				level.add_child(_map[item["uuid"]])
				_map.erase(item["uuid"])
		else:
			var new_folder: TreeItem = level.create_child()
			new_folder.set_text(
					0,
					discourse_nodes_tree.get_unique_name_on_tree(
							level,
							item["name"] if item.has("name") else "new_folder",
							new_folder))
			
			new_folder.set_editable(0, true)
			new_folder.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
			if item.has("collapsed"):
				new_folder.collapsed = item["collapsed"]
			new_folder.add_button(
					0,
					get_theme_icon("Remove", "EditorIcons"),
					-1,
					false,
					"Delete Group")
			new_folder.set_metadata(0, {"is_node": false})
			if item.has("items"):
				set_up_node_structure(item["items"], new_folder, _map)


func _on_discourse_item_renamed(uuid: StringName, new_name: String) -> void:
	var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(uuid)
	var new_named: StringName = StringName(new_name)
	if node == null or node.get_node_id() == new_named:
		return
	
	node.set_node_id(new_name)
	
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
	
	var connection_deaf_nodes: Array[DiscourseGraphNode] = []
	
	for node_stnm_uuid:StringName in conversation.get_node_uuids():
		var node_uuid: String = String(node_stnm_uuid)
		var data: Dictionary = conversation.get_node_data(node_stnm_uuid, current_locale)
		var metadata: Dictionary = data["metadata"]
		var d_node: DiscourseGraphNode = discourse_graph_edit.spawn_node(data["type"], node_stnm_uuid, data)
		
		if d_node.node_type == DiscourseGraphNode.DialogueNodeType.CALLABLE or d_node.node_type == DiscourseGraphNode.DialogueNodeType.CALLABLE_RETURN:
			if metadata.has("method") and not metadata["method"].is_empty():
				if not d_node.available_methods.has(metadata["method"]):
					push_warning("Node ", data["name"], " calls method ", metadata["method"], " but the method isn't available.")
					needs_resaving = true
		elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.SIGNAL:
			if metadata.has("signal") and not metadata["signal"].is_empty():
				if not d_node.available_signals.has(metadata["signal"]):
					push_warning("Node ", data["name"], " calls signal ", metadata["signal"], " but the signal isn't available.")
					needs_resaving = true
		elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.ENTRY:
			discourse_graph_edit.entry_node = d_node
		elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE or d_node.node_type == DiscourseGraphNode.DialogueNodeType.METADATA:
			d_node._connection_updates_disabled = true
			connection_deaf_nodes.append(d_node)
		if node_relationships.has(node_uuid):
			discourse_graph_edit.set_node_in_frame(node_stnm_uuid, node_relationships[node_uuid].get_frame_uuid())
		graph_map[node_uuid] = d_node
		
		var new_connections: Array[Dictionary] = discourse_graph_edit.get_connection_dictionary(
				node_stnm_uuid,
				data)
		if not new_connections.is_empty():
			node_connections.append_array(new_connections)
		
		discourse_nodes_tree.create_node(d_node)
		
		if d_node.is_node_localized():
			if d_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG:
				localization_nodes_tree.create_dialog_node(d_node.get_node_id(), d_node)
			elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.OPTIONS:
				localization_nodes_tree.create_options_node(d_node.get_node_id(), d_node)
			elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				localization_nodes_tree.create_localized_text_node(d_node.get_node_id(), d_node)
	
	for output_connection in node_connections:
		if not graph_map.has(output_connection["from"]) or not graph_map.has(output_connection["to"]):
			continue
		if not discourse_graph_edit.connect_discourse_nodes(
				graph_map[output_connection["from"]].get_node_uuid(),
				output_connection["from_port"],
				graph_map[output_connection["to"]].get_node_uuid(),
				output_connection["to_port"]):
			push_warning(
				"Connection from node ",
				graph_map[output_connection["from"]].get_node_id(),
				" from port ",
				output_connection["from_port"],
				 " to node ",
				graph_map[output_connection["to"]].get_node_id(),
				" to port ",
				output_connection["to_port"],
				" failed.")
			needs_resaving = true
	
	if discourse_graph_edit.entry_node == null:
		var en_node: DiscourseGraphNode = discourse_graph_edit.spawn_node(DiscourseGraphNode.DialogueNodeType.ENTRY)
		en_node.set_node_id(&"Entry")
		discourse_graph_edit.entry_node = en_node
		_on_discourse_node_created(en_node)
	
	for node in connection_deaf_nodes:
		node._connection_updates_disabled = false
	
	discourse_graph_edit.zoom = conversation.zoom
	discourse_graph_edit.scroll_offset = conversation.scroll_offset
	
	return needs_resaving


# Loads a conversation into discourse.
func open_conversation(conversation: EditorDiscourseDialog) -> bool:
	dialog_id_ln_edt.text = conversation.dialog_id
	
	# Clears discourse_nodes_tree's items
	discourse_nodes_tree.clear_tree()
	
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
	clear_locales(false)
	languages_tree.clear_languages(false)
	base_text_edt.text = ""
	translation_txt_box.text = ""
	clear_localized_options()
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = false
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = false
	
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
	
	discourse_nodes_tree.set_collapsed_folders(
			conversation.collapsed_state)
	
	var graphs_locale: String = current_locale
	var side_locale: String = languages_tree.get_active_locale()
	
	for localized_key in conversation.format_strings.keys():
		var localized_text: String = ""
		if not current_locale.is_empty():
			localized_text = conversation.get_format_string(
					localized_key,
					current_locale)
		add_new_phrase(localized_key, localized_text, false)
	
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
	
	if locale_popup.item_count == 0:
		add_locale(base_language)
	current_locale = base_language
	set_graph_locale_tip(base_language)
	
	new_text_button.disabled = current_locale.is_empty()
	
	active_conversation = conversation
	
	return reload_needed


# Adds a conversation into the list, can open it.
func load_conversation(data: EditorDiscourseDialog, open_conv: bool = true) -> void:
	conversation_tree.add_conversation(data, open_conv, false)
	
	if open_conv:
		conversation_tree.set_conversation_item_active(data)
		if open_conversation(data):
			conversation_tree.active_unsaved = true


func save_localizer_data(for_locale: String) -> void:
	if active_conversation == null:
		return
	
	var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	
	if active_node == null:
		return
	
	#var current_locale: String = languages_tree.get_active_locale()
	match active_node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			active_conversation.set_text_entry(
					active_node.get_node_uuid(),
					translation_txt_box.text,
					for_locale)
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			var options: Array[String] = get_localizer_choices()
			active_conversation.set_choices_entry(
					active_node.get_node_uuid(),
					options,
					for_locale)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			active_conversation.set_text_entry(
					active_node.get_node_uuid(),
					translation_txt_box.text,
					for_locale)


func _on_save_conversation_pressed() -> void:
	if active_conversation == null:
		return
	
	save_current_dialog()
	conversation_tree.active_offset_changed = false
	conversation_tree.active_unsaved = false


func _on_godot_save_triggered() -> void:
	if active_conversation != null and phrases_lang_menu.selected != -1:
		save_phrase_keys(phrases_lang_menu.get_selected_metadata())
	
	save_all_dialogs()
	conversation_tree.set_conversations_saved()


func save_current_dialog() -> void:
	if phrases_lang_menu.selected != -1:
		save_phrase_keys(phrases_lang_menu.get_selected_metadata())
	if $LocalizationContainer.visible and localization_nodes_tree.get_active_node() != null:
		save_localizer_data(languages_tree.get_active_locale())
	
	if conversation_tree.active_offset_changed:
		var layout_data: Dictionary[String, Variant] = {
			"collapsed_state": discourse_nodes_tree.get_collapsed_folders(),
			"zoom": active_conversation.zoom,
			"scroll_offset": active_conversation.scroll_offset}
		
		_save_file_layout_for(
				active_conversation.resource_path,
				layout_data)
		conversation_tree.active_offset_changed = false
	
	if not _unsaved:
		return
	
	discourse_graph_edit.update_conversation_file(active_conversation, current_locale)
	
	var locale_map: Dictionary[String, Dictionary] = languages_tree.as_map()
	
	active_conversation.node_structure = discourse_nodes_tree.get_folder_structure()
	active_conversation.locale_map = locale_map.duplicate(true)
	active_conversation.dialog_id = dialog_id_ln_edt.text.strip_edges()
	
	_unsaved = false
	ResourceSaver.save(active_conversation)
	conversation_tree.active_unsaved = false
	conversation_tree.active_offset_changed = false


func save_all_dialogs() -> void:
	if $LocalizationContainer.visible and localization_nodes_tree.get_active_node() != null:
		save_localizer_data(languages_tree.get_active_locale())
	
	# Save all unsaved conversations
	for unsaved_conversation:EditorDiscourseDialog in conversation_tree.get_unsaved_conversation_resources():
		# Including our active one
		if unsaved_conversation == active_conversation:
			if phrases_lang_menu.selected != -1:
				save_phrase_keys(phrases_lang_menu.get_selected_metadata())
			discourse_graph_edit.update_conversation_file(active_conversation, current_locale)
			active_conversation.dialog_id = dialog_id_ln_edt.text.strip_edges()
			
			active_conversation.node_structure = discourse_nodes_tree.get_folder_structure()
			
			ResourceSaver.save(active_conversation)
		else:
			ResourceSaver.save(unsaved_conversation)
	
	for unsaved_layout: EditorDiscourseDialog in conversation_tree.get_unsaved_layout_resources():
		var layout_data: Dictionary[String, Variant] = {
			"collapsed_state": unsaved_layout.collapsed_state,
			"zoom": unsaved_layout.zoom,
			"scroll_offset": unsaved_layout.scroll_offset}
		
		_save_file_layout_for(
				unsaved_layout.resource_path,
				layout_data)
	
	_unsaved = false
	conversation_tree.set_all_files_saved()


func save_layouts() -> void:
	for unsaved_layout: EditorDiscourseDialog in conversation_tree.get_unsaved_layout_resources():
		var layout_data: Dictionary[String, Variant] = {
			"collapsed_state": unsaved_layout.collapsed_state,
			"zoom": unsaved_layout.zoom,
			"scroll_offset": unsaved_layout.scroll_offset}
		
		_save_file_layout_for(
				unsaved_layout.resource_path,
				layout_data)


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
		discourse_graph_edit.duplicate_single(uuids[0], new_uuid)
	else:
		var uuid_map: Dictionary[StringName, StringName] = {}
		for uuid in uuids:
			uuid_map[uuid] = StringName(UUID.generate_new())
		var undo_targets: Array[StringName] = []
		undo_targets.assign(uuid_map.values())
		discourse_graph_edit.duplicate_multiple(uuid_map)
	_on_conversation_changed()


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
	_on_conversation_changed()


func _save_file_layout_for(file_path: String, keys: Dictionary[String, Variant]) -> void:
	if file_path.is_empty():
		push_error("[DISCOURSE] Can't save data for an empty filepath")
		return
	
	var cfg: ConfigFile = ConfigFile.new()
	for key in keys.keys():
		cfg.set_value("Layout", key, keys[key])
	var file: String = file_path.get_file()
	var path_hash: String = file_path.md5_text()
	var absolute_path: String = ProjectSettings.globalize_path("res://.godot/editor/")
	var config_filename: String = file + "-graphstate-" + path_hash + ".cfg"
	
	if not DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.make_dir_recursive_absolute(absolute_path)
	
	if cfg.save(absolute_path.path_join(config_filename)) != OK:
		push_warning("[DISCOURSE] Couldn't save layout settings for file \"", file_path, "\"")


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


func _on_erase_case_button_pressed(case_line: Control) -> void:
	erase_case(case_line.get_index())
	_on_case_line_text_changed()


func _on_open_discourse_text_editor_pressed(target: LineEdit) -> void:
	if text_editor != null:
		return
	
	var method_strings: Array[String] = []
	var var_strings: Array[String] = []
	var plain_formats: Array[String] = []
	
	for idx in range(argument_opt_btn.item_count):
		var text: String = argument_opt_btn.get_item_text(idx)
		if text.begins_with("!"):
			method_strings.append(text.trim_prefix("!"))
		elif text.begins_with("$"):
			var_strings.append(text.trim_prefix("$"))
		else:
			plain_formats.append(text)
	
	text_editor = preload("res://addons/nexus_forge/discourse/discourse_text_editor.tscn").instantiate()
	add_child(text_editor)
	text_editor.signal_variables = false
	text_editor.plain_formats = plain_formats
	text_editor.methods = method_strings
	text_editor.variables = var_strings
	
	text_editor.set_code_text(target.text)
	text_editor.connect_signals()
	text_editor.popup_centered()
	text_editor.grab_code_focus()
	
	var result = await text_editor.action_finished
	
	if result[0]:
		target.text = result[1]
	
	text_editor.queue_free()
	text_editor = null


func _on_open_code_editor_graph_request(target: Control, initial_text: String) -> void:
	if text_editor != null:
		return
	
	var api_methods: Dictionary = get_api_user_methods()
	var method_strings: Array[String] = []
	method_strings.assign(api_methods.keys())
	var string_keys: Array[String] = []
	string_keys.assign(active_conversation.format_strings.keys())
	
	text_editor = preload("res://addons/nexus_forge/discourse/discourse_text_editor.tscn").instantiate()
	add_child(text_editor)
	text_editor.phrase_keys = string_keys
	text_editor.methods = method_strings
	text_editor.variable_called.connect(_on_editor_variable_called)
	text_editor.set_code_text(initial_text)
	text_editor.connect_signals()
	text_editor.popup_centered()
	text_editor.grab_code_focus()
	
	var result = await text_editor.action_finished
	
	if result[0]:
		var notify_change: bool = false
		if target is LineEdit:
			notify_change = target.text != result[1]
			target.text = result[1]
		elif target is TextEdit:
			notify_change = target.text != result[1]
			target.text = result[1]
		
		if notify_change:
			_on_conversation_changed()
	
	text_editor.queue_free()
	text_editor = null



func _on_editor_variable_called(path: String) -> void:
	code_editor_variables_requested.emit(path.strip_edges().simplify_path())


func set_text_code_editor_variable_paths(paths: Array[Dictionary]) -> void:
	if text_editor == null:
		return
	
	text_editor.display_completion_options_variables(paths)


func _on_case_line_text_changed(_text: String = "") -> void:
	var all_ids: Dictionary[String, Array] = {}
	
	for container:HBoxContainer in case_node_container.get_children():
		var item: LineEdit = container.get_child(1)
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
	case_box_container.visible = false
	key_box_container.visible = true
	phrases_lang_menu.disabled = false
	
	if argument_opt_btn.selected == -1:# selected_format.is_empty():
		return
	
	save_current_phrase_key(languages_tree.get_active_locale())
	clear_cases()
	default_case_ln_edt.text = ""
	search_case_ln_edt.text = ""
	search_case_ln_edt.set_meta(&"current_search", "")
	argument_opt_btn.clear()
	#selected_format = ""


func _on_edit_cases_pressed(text_line: LineEdit, key: LineEdit, button: Button) -> void:
	var phrase_key: StringName = key.get_meta(&"phrase_key")
	var clean_string: String = text_line.text.strip_edges()
	var locale_code: String = phrases_lang_menu.get_selected_metadata()
	
	if locale_code.is_empty():
		push_error("[DISCOURSE] OPTIONMENU LOCALE CODE EMPTY. CAN'T LOAD ITEMS")
		return
	
	phrases_lang_menu.disabled = true
	key_display_label.text = key.text.strip_edges()
	
	if not active_conversation.has_format_string(phrase_key, locale_code):
		active_conversation.set_format_string(
				phrase_key,
				clean_string,
				locale_code)
	
	if active_conversation.get_format_string(phrase_key, locale_code) != clean_string:
		var new_cases: Dictionary[String, Variant] = {}
		
		for existing_case in EditorDiscourseDialog.get_phrase_arguments(clean_string, true):
			new_cases[existing_case] = null
		for format in active_conversation.get_format_string_formats(phrase_key, locale_code):
			if not new_cases.has(format):
				active_conversation.erase_format_string_format(
						phrase_key,
						locale_code,
						format)
			
		active_conversation.set_format_string(
				phrase_key,
				clean_string,
				locale_code)
	
	argument_opt_btn.clear()
	clear_cases()
	
	for existing_key in EditorDiscourseDialog.get_phrase_arguments(clean_string, true):
		argument_opt_btn.add_item(existing_key)
	
	selected_key = key
	default_case_ln_edt.editable = 0 < argument_opt_btn.item_count
	argument_opt_btn.disabled = not default_case_ln_edt.editable
	new_case_btn.disabled = argument_opt_btn.disabled
	
	if 0 < argument_opt_btn.item_count:
		var argument_format: String = argument_opt_btn.get_item_text(0)
		argument_opt_btn.select(0)
		default_case_ln_edt.text = active_conversation.get_format_string_default_case(phrase_key, locale_code, argument_format)
		
		if DictUtils.has_nested_path(active_conversation.format_strings, [phrase_key, locale_code, "format", argument_format, "cases"]):
			for custom_case in active_conversation.format_strings[phrase_key][locale_code]["format"][argument_format]["cases"].keys():
				add_new_case(
						custom_case,
						active_conversation.get_format_string_case(phrase_key, locale_code, argument_format, custom_case))
	
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
		#selected_format = ""
		clear_cases()
		default_case_ln_edt.text = ""
		default_case_ln_edt.editable = false
		argument_opt_btn.clear()
		argument_opt_btn.disabled = true
		new_case_btn.disabled = true
	
	active_conversation.format_strings.erase(key.get_meta(&"phrase_key"))
	
	erase_key(
		key.get_parent().get_index())
	
	_on_key_line_text_changed()


func _on_new_key_field_button_pressed() -> void:
	var phrase_key: String = add_new_phrase()
	_on_conversation_changed()


func add_new_phrase(key: String = "", text: String = "", unsaved: bool = true) -> String:
	var new_key: HBoxContainer = new_key_container(key, unsaved)
	var new_text: HBoxContainer = new_text_field(text)
	
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
	var erase_case_btn: Button = Button.new()
	var case_result: HBoxContainer = new_case_result_node()
	var result_line: LineEdit = case_result.get_child(0)
	var case_container: HBoxContainer = HBoxContainer.new()
	
	erase_case_btn.tooltip_text = "Erase case"
	erase_case_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_case_btn.flat = true
	erase_case_btn.icon = get_theme_icon("Remove", "EditorIcons")
	erase_case_btn.custom_minimum_size = Vector2(32.0, 32.0)
	erase_case_btn.pressed.connect(_on_erase_case_button_pressed.bind(case_container))
	
	new_case.placeholder_text = "Case"
	new_case.custom_minimum_size.y = 32.0
	new_case.text = case
	new_case.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	result_line.text = case_text
	
	case_container.add_child(erase_case_btn)
	case_container.add_child(new_case)
	
	case_node_container.add_child(case_container)
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


func new_key_container(key: String = "", unsaved: bool = true) -> HBoxContainer:
	var new_key: HBoxContainer = HBoxContainer.new()
	var key_line: LineEdit = LineEdit.new()
	var erase_button: Button = Button.new()
	var empty_key: bool = key.is_empty()
	
	if key.is_empty():
		key = get_valid_format_key_id()
	else:
		key= get_valid_format_key_id(key)
	
	key_line.set_meta(&"phrase_key", key)
	key_line.set_meta(&"unsaved", unsaved)
	
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


func get_valid_format_key_id(desired_id: String = "NEW_PHRASE") -> String:
	var used_keys: Dictionary[String, Variant] = {}
	
	for container in key_container.get_children():
		var line: LineEdit = container.get_child(1)
		var assigned_key: String = line.get_meta(&"phrase_key", "")
		used_keys[assigned_key] = null
	
	if not used_keys.has(desired_id):
		return desired_id
	
	var base: String = desired_id
	var modified: String = desired_id
	var trailing_data: Dictionary = StringUtils.get_trailing_integer(desired_id)
	var iteration: int = trailing_data["integer"]
	if trailing_data["has_integer"]:
		base = desired_id.trim_suffix(str(iteration))
	
	while used_keys.has(modified):
		iteration += 1
		modified = base + str(iteration)
	
	return modified


func new_case_result_node() -> HBoxContainer:
	var new_case: HBoxContainer = HBoxContainer.new()
	var case_text: LineEdit = load("res://addons/nexus_forge/item_quest_lineedit_script.gd").new()
	var open_editor_btn: Button = Button.new()
	
	case_text.placeholder_text = "Case format"
	case_text.custom_minimum_size.y = 32.0
	case_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	open_editor_btn.tooltip_text = "Open Editor"
	open_editor_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	open_editor_btn.flat = true
	open_editor_btn.icon = get_theme_icon("DistractionFree", "EditorIcons")
	open_editor_btn.custom_minimum_size = Vector2(32.0, 32.0)
	open_editor_btn.pressed.connect(_on_open_discourse_text_editor_pressed.bind(case_text))
	
	new_case.add_child(case_text)
	new_case.add_child(open_editor_btn)
	
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


func save_current_phrase_key(locale_code: String) -> void:
	if selected_key == null:
		return
	var phrase_key: String = selected_key.get_meta(&"phrase_key")
	#var locale_code = languages_tree.get_active_locale()
	var selected_format: String = argument_opt_btn.get_item_text(argument_opt_btn.selected)
	
	active_conversation.set_format_string_default_case(
		phrase_key,
		locale_code,
		selected_format,
		default_case_ln_edt.text.strip_edges())
	
	var case_idx: int = 0
	var desired: String = ""
	var modified: String = ""
	var iteration: int = 0
	
	var cases: Array[Dictionary] = []
	
	# Fixing the cases:
	for case_container:HBoxContainer in case_node_container.get_children():
		var case_key: LineEdit = case_container.get_child(1)
		case_key.text = case_key.text.strip_edges()
		cases.append({
			"key_line": case_key,
			"text_line": result_node_container.get_child(case_idx).get_child(0)})
		case_idx += 1
	
	var assigned_keys: Dictionary[String, Variant] = {}
	var keys_changed: bool = false
	for item_index in range(cases.size()):
		desired = cases[item_index]["key_line"].text
		
		if not _phrase_key_used(desired, cases, item_index):
			continue
		
		var trailing_data: Dictionary = StringUtils.get_trailing_integer(desired)
		var base: String = desired
		iteration = trailing_data["integer"]
		if trailing_data["has_integer"]:
			base = base.trim_suffix(str(iteration))
		modified = desired
		while _phrase_key_used(modified, cases, item_index):
			iteration += 1
			modified = base + str(iteration)
	
		cases[item_index]["key_line"].text = modified
		if not keys_changed:
			keys_changed = true
	
	active_conversation.clear_format_string_cases(
			phrase_key,
			locale_code,
			selected_format)
	
	for case in cases:
		active_conversation.set_format_string_case(
			phrase_key,
			locale_code,
			selected_format,
			case["key_line"].text,
			case["text_line"].text)
	
	if keys_changed:
		_on_case_line_text_changed()


func save_phrase_keys(locale: String) -> void:
	if locale.is_empty():
		return
	
	var current_items: Array[Dictionary] = []
	
	var idx: int = 0
	for key_child in key_container.get_children():
		var item: LineEdit = key_child.get_child(1)
		item.text = item.text.strip_edges()
		current_items.append({
			"key_line": item,
			"text_line": text_container.get_child(idx).get_child(0)})
		idx += 1
	
	var claimed_keys: Dictionary[String, Variant] = {}
	for item_index in range(current_items.size()):
		var item: Dictionary = current_items[item_index]
		var key_line: LineEdit = item["key_line"]
		var text_line: LineEdit = item["text_line"]
		
		var unsaved: bool = key_line.get_meta(&"unsaved", false)
		var old_key: String = key_line.get_meta(&"phrase_key", "")
		
		var clean: String = key_line.text.strip_edges()
		if clean.is_empty():
			clean = "phrase_key"
		
		if _phrase_key_used(clean, current_items, item_index):
			var base_name: String = clean
			var trailing_data: Dictionary = StringUtils.get_trailing_integer(clean)
			var iteration: int = trailing_data["integer"]
			if trailing_data["has_integer"]:
				base_name = clean.trim_suffix(str(iteration))
			
			var modified: String = clean
			
			while _phrase_key_used(modified, current_items, item_index):
				iteration += 1
				modified = base_name + str(iteration)
			
			clean = modified
		
		if unsaved: # Create the key-value entry. Set as created
			key_line.set_meta(&"unsaved", false)
		
		elif old_key != clean: # Move the value to the new key, clean the old key.
			active_conversation.format_strings[clean] = active_conversation.format_strings[old_key]
			active_conversation.format_strings.erase(old_key)
		
		active_conversation.set_format_string(
				clean,
				item["text_line"].text,
				locale)
		
		key_line.set_meta(&"phrase_key", clean)
		key_line.text = clean
		
		claimed_keys[clean] = null
	
	# Remove keys no longer used
	for existing_key in active_conversation.format_strings.keys():
		if claimed_keys.has(existing_key):
			continue
		active_conversation.format_strings.erase(existing_key)
	
	# Saving this last because keys could shift above OR new keys could be
	# assigned.
	if -1 < argument_opt_btn.selected:# not selected_format.is_empty():
		save_current_phrase_key(locale)


func _phrase_key_used(desired: String, items: Array[Dictionary], skip_index: int = -1) -> bool:
	for index in range(items.size()):
		if index == skip_index:
			continue
		if items[index]["key_line"].text == desired:
			return true
	return false


#endregion


func _on_recent_file_index_pressed(index: int) -> void:
	var file_path: String = _recently_opened_popup.get_item_metadata(index)
	
	if FileAccess.file_exists(file_path):
		var file: EditorDiscourseDialog = load_dialog_from_file(file_path)
		if file == null:
			push_error("[DISCOURSE]: Couldn't open \"", file_path, "\"")
			return
		conversation_tree.select_conversation.call_deferred(file)
		add_to_recently_opened_files(file_path)
	else:
		push_error("[DISCOURSE]: File not found: \"", file_path, "\"")
		_recently_opened_files.erase(file_path)
		_recently_opened_popup.remove_item(index)
		_reset_recent_popup_size.call_deferred()


func _reset_recent_popup_size() -> void:
	_recently_opened_popup.size = Vector2i.ZERO


func add_to_recently_opened_files(file: String) -> void:
	if _recently_opened_files.has(file):
		var index: int = _recently_opened_files.find(file)
		_recently_opened_files.remove_at(index)
	elif RECENT_FILE_AMOUNT_MAX < _recently_opened_files.size():
		_recently_opened_files.resize(RECENT_FILE_AMOUNT_MAX - 1)
	
	_recently_opened_files.append(file)
	
	update_recently_opened_files()


func _truncate_with_elipsis(text: String, max_size: int, elipsis: String = "...") -> String:
	if max_size <= 0:
		return ""
	
	var font: Font = _recently_opened_popup.get_theme_font("font")
	var font_size: int = _recently_opened_popup.get_theme_font_size("font_size")
	
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x < max_size:
		return text
	
	var ellipsis_width: float = font.get_string_size(elipsis, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var available_width: float = max_size - ellipsis_width
	
	var truncated: String = ""
	for char_index in range(text.length()):
		var test_string: String = text.substr(0, char_index)
		var current_width: int = font.get_string_size(test_string, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		
		if current_width <= available_width:
			truncated = test_string
		else:
			break
			
	return truncated + elipsis


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


func _on_copy_format_pressed() -> void:
	if argument_opt_btn.selected == -1:
		return
	
	var selected_text: String = argument_opt_btn.get_item_text(argument_opt_btn.selected)
	
	DisplayServer.clipboard_set("{" + selected_text + "}")


func get_api_user_methods() -> Dictionary:
	var methods: Dictionary = {}
	
	var method_blacklsit: Array[String] = []
	var singleton: DiscourseAPI = DiscourseAPI.new()
	var base_methods: Array = ClassDB.class_get_method_list(&"RefCounted")
	
	for method in base_methods:
		method_blacklsit.append(method["name"])
		
	for method:Dictionary in singleton.get_method_list():
		if method["name"] in method_blacklsit or method["return"]["type"] == TYPE_NIL:
			continue
		
		var default_count: int = method["default_args"].size()
		var default_index: int = method["args"].size() - default_count
		var args: Array[Dictionary] = []
		var arg_idx: int = -1
		for arg: Dictionary in method["args"]:
			arg_idx += 1
			args.append({
				"name": arg["name"],
				"type": arg["type"],
				"has_default": default_index <= arg_idx})
		methods[method["name"]] = {"return_type": method["return"]["type"], "arguments": args}
	
	return methods


func _on_collapse_left_pressed() -> void:
	var column: Control = get_column_left()
	var uncollapse: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/UncollapseButton
	column.visible = false
	uncollapse.visible = true


func _on_uncollapse_left_pressed() -> void:
	var column: Control = get_column_left()
	var uncollapse: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/UncollapseButton
	column.visible = true
	uncollapse.visible = false


func _on_uncollapse_right_pressed() -> void:
	$MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/UncollapseRightBtn.visible = false
	$MainSplitContainer/ActiveWindowSplit/PhrasesContainer/HeaderPanel/PhrasesHeader/CollapseRigthBtn.visible = true
	$MainSplitContainer/ActiveWindowSplit/PhrasesContainer.visible = true


func _on_collapse_right_pressed() -> void:
	$MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/UncollapseRightBtn.visible = true
	$MainSplitContainer/ActiveWindowSplit/PhrasesContainer/HeaderPanel/PhrasesHeader/CollapseRigthBtn.visible = false
	$MainSplitContainer/ActiveWindowSplit/PhrasesContainer.visible = false


func _on_uncollapse_previewer_pressed() -> void:
	dialog_scene_previewer.visible = true
	$LocalizationContainer/FooterContainer/UncollapsePreviewBtn.visible = false


func _on_collapse_previewer_pressed() -> void:
	dialog_scene_previewer.visible = true
	$LocalizationContainer/FooterContainer/UncollapsePreviewBtn.visible = false


func _on_text_changed_sync(text: String) -> void:
	if dialog_previewer == null or not dialog_scene_previewer.visible or not $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer/HBoxContainer/ButtonContaienr/AutoUpdateBtn.button_pressed:
		return
	
	dialog_previewer.dialog_text_changed.emit(text)


func _on_choice_text_changed(text: String, index: int) -> void:
	if dialog_previewer == null or not dialog_scene_previewer.visible or not $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer/HBoxContainer/ButtonContaienr/AutoUpdateBtn.button_pressed:
		return
	
	dialog_previewer.choice_text_changed.emit(text, index)


func _on_auto_update_toggled(toggled_on: bool) -> void:
	if not toggled_on or dialog_previewer == null:
		return
	
	var node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	
	if node == null:
		return
	
	if node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG:
		dialog_previewer.set_dialog(
				translation_txt_box.text)
	else:
		dialog_previewer.set_choices(
				get_localizer_choices())
		
