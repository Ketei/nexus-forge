@tool
extends PanelContainer


signal code_editor_variables_requested(path: String)
signal character_browser_requested(target: LineEdit)

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

const TEXT_CODE_EDITOR = preload("res://addons/nexus_forge/discourse/discourse_text_editor.tscn")
const BracketHandler = preload("res://addons/nexus_forge/discourse/textedit_bracket_handler.gd")
const RECENT_FILE_AMOUNT_MAX: int = 10
# Used on Phrases only
const MAX_LINES: int = 3
const EXTRA_Y_PADDING: int = 8
# --------------------

var active_conversation: EditorDiscourseDialog = null
var previous_conversation: int = 0

var localization_node_selected: DiscourseGraphNode = null

var listen_offset: bool = true

var selected_phrase_format: String = ""
var selected_phrase_index: int = -1

var _unsaved: bool = false:
	set(u):
		if active_conversation == null:
			return
		var id: int = active_conversation.get_instance_id()
		_open_files[id]["unsaved"] = u
		conversation_tree.active_unsaved = u
	get():
		if active_conversation == null:
			return false
		return _open_files[active_conversation.get_instance_id()]["unsaved"]
# Keys: resource, undo, unsaved, offset_changed
var _open_files: Dictionary[int, Dictionary] = {}
var undo: UndoRedo

var node_popup: PopupMenu = null
var file_popup: PopupMenu = null
var locale_popup: PopupMenu = null
var dialog_previewer: Node = null

# ----------------------------
var _conversation_options_disabled: bool = true

var base_language: String = ""
var _included_languages: Dictionary[String, Dictionary] = {}
var current_locale: String = ""
var text_editor: Window = null
var _recently_opened_files: Array[String] = []
var _recently_opened_popup: PopupMenu = null
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
@onready var choices_container: VBoxContainer = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer/ChoicesScroller/ChoicesContainer

# --- Phrases ---
@onready var default_case_edt: TextEdit = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/KeyScroll/PhraseCasesEntries/DefaultCase/DefaultCaseEdt
@onready var argument_opt_btn: OptionButton = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/ArgumentContainer/ArgumentOptBtn
@onready var copy_arg_btn: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/ArgumentContainer/CopyArgBtn
@onready var new_case_btn: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/HeaderContainer/NewCaseBtn
@onready var new_text_button: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer/HBoxContainer/NewTextButton
@onready var search_case_ln_edt: LineEdit = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/HeaderContainer/SearchCaseLnEdt
@onready var key_display_label: Label = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/CaseKeyContainer/KeyDisplayLabel
@onready var key_box_container: VBoxContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer
@onready var case_box_container: VBoxContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer
@onready var save_case_btn: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/SaveCaseBtn
@onready var search_text_ln_edt: LineEdit = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer/HBoxContainer/SearchTextLnEdt
@onready var key_header_split: HBoxContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/KeyBoxContainer/KeyHeaderSplit
@onready var case_header_split: HBoxContainer = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/CaseHeaderSplit

# ----------------------------------------------

@onready var no_dialog_label: Label = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/GraphPanel/NoDialogLbl
@onready var discourse_graph_edit: GraphEdit = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/GraphPanel/DiscourseGraphEdit

@onready var node_menu_btn: MenuButton = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/NodeMenuBtn
@onready var save_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/SaveBtn
@onready var play_current_dialog_btn: Button = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/PlayDialogBtn
@onready var close_localizer_btn: Button = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/HeaderContainer/CloseLocalizerBtn
@onready var snap_distance_spn_bx: SpinBox = $MainSplitContainer/ActiveWindowSplit/DiscourseSplitContainer/DiscourseWindow/ContentVBox/MenuPanel/MenuVBox/SnapDistanceSpnBx
@onready var dialog_scene_previewer: PanelContainer = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer
@onready var phrases_lang_menu: OptionButton = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/HeaderPanel/PhrasesHeader/PhrasesLangMenu
@onready var auto_update_previewer: Button = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer/HBoxContainer/ButtonContaienr/AutoUpdateBtn


func _ready() -> void:
	set_process_input(false)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or undo == null:
		return
	
	if event is InputEventKey:
		if event.echo or not event.pressed or not event.ctrl_pressed:
			return
		
		var current_focus: Control = get_viewport().gui_get_focus_owner()
		
		if current_focus != null:
			if current_focus is LineEdit:
				if current_focus.is_editing():
					return
			elif current_focus is TextEdit:
				return
		
		if event.keycode == KEY_Z:
			if event.shift_pressed:
				if undo.has_redo():
					var action_name: String = undo.get_action_name(undo.get_current_action() + 1)
					undo.redo()
					NFPluginGameHandler._log_msg(
						"",
						"Redo: " + action_name,
						NFPluginGameHandler._LogLevel.EDITOR)
					_on_conversation_changed()
			else:
				if undo.has_undo():
					var action_name: String = undo.get_current_action_name()
					undo.undo()
					NFPluginGameHandler._log_msg(
						"",
						"Undo: " + action_name,
						NFPluginGameHandler._LogLevel.EDITOR)
					_on_conversation_changed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Y and not event.shift_pressed:
			if undo.has_redo():
				var action_name: String = undo.get_action_name(undo.get_current_action() + 1)
				undo.redo()
				NFPluginGameHandler._log_msg(
					"",
					"Redo: " + action_name,
					NFPluginGameHandler._LogLevel.EDITOR)
				_on_conversation_changed()
			get_viewport().set_input_as_handled()


func ready_plugin(base_locale: String = "") -> void:
	set_process_input(true)
	text_editor = TEXT_CODE_EDITOR.instantiate()
	add_child(text_editor)
	text_editor.ready_plugin()
	
	var highlighter: NFEditorDialogSyntaxHighlighter = text_editor.text_code_edit.syntax_highlighter
	
	highlighter.set_use_token("*", false)
	
	text_editor.variable_called.connect(_on_editor_variable_called)
	if text_editor.visible:
		text_editor.hide()
	
	var def_highlighter: NFEditorDialogSyntaxHighlighter = NFEditorDialogSyntaxHighlighter.new()
	def_highlighter.set_use_token("&", false)
	def_highlighter.set_use_token("?", false)
	def_highlighter.set_use_token("*", false)
	
	default_case_edt.set_script(BracketHandler)
	default_case_edt.enter_shifts_focus = true
	default_case_edt.syntax_highlighter = def_highlighter
	default_case_edt.set_meta(&"old_value", "")
	
	dialog_id_ln_edt.set_meta(&"old_value", "")
	
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
	var play_previewer: Button = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer/HBoxContainer/ButtonContaienr/PlayTextBtn
	var default_expand_button: Button = $MainSplitContainer/ActiveWindowSplit/PhrasesContainer/PanelContainer/CaseBoxContainer/VBoxContainer2/KeyScroll/PhraseCasesEntries/DefaultCase/DefaultExpandButton
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
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/list_icon.svg"), "Choices", DiscourseGraphNode.DialogueNodeType.CHOICES)
	dialogs_submenu.add_separator("Flow")
	dialogs_submenu.add_icon_item(get_theme_icon("RandomNumberGenerator", "EditorIcons"), "Random", DiscourseGraphNode.DialogueNodeType.RANDOM)
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/branch_icon.svg"), "Branch", DiscourseGraphNode.DialogueNodeType.BRANCH)
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/match_icon.svg"), "Match", DiscourseGraphNode.DialogueNodeType.MATCH)
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/merge_icon.svg"), "Merge", DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE)
	dialogs_submenu.add_icon_item(get_theme_icon("Pause", "EditorIcons"), "Pause", DiscourseGraphNode.DialogueNodeType.PAUSE)
	dialogs_submenu.add_separator("Anchors")
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/dialog_entry.svg"), "Shortcut", DiscourseGraphNode.DialogueNodeType.SHORTCUT)
	dialogs_submenu.add_icon_item(load("res://addons/nexus_forge/icons/dialog_exit.svg"), "Shortuct Target", DiscourseGraphNode.DialogueNodeType.SHORTCUT_TARGET)
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
			NFPluginGameHandler.get_setting_path("discourse_use_languages"), ""),
		",",
		false)
	
	for entry in locale_settings:
		var parts: PackedStringArray = entry.split("_", false)
		var part_size: int = parts.size()
		if part_size <= 0 or 2 < part_size:
			NFPluginGameHandler._log_msg(
				"discourse - editor",
				"Discourse languages only support language & country. Attepmted to use '%s'" % entry,
				NFPluginGameHandler._LogLevel.WARNING)
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
	
	hide_issues_btn.icon = get_theme_icon("GuiClose", "EditorIcons")
	
	discourse_graph_edit.panning_scheme = GraphEdit.SCROLL_PANS if ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("discourse_panning_scheme"), true) else GraphEdit.SCROLL_ZOOMS
	
	play_current_dialog_btn.icon = get_theme_icon("MainPlay", "EditorIcons")
	
	copy_arg_btn.icon = get_theme_icon("ActionCopy", "EditorIcons")
	
	if _is_preview_scene_valid(false):
		var path: String = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("discourse_localization_preview_scene"))
		uncollapse_previewer.visible = true
		collapse_previewer.pressed.connect(_on_collapse_previewer_pressed)
		uncollapse_previewer.pressed.connect(_on_uncollapse_previewer_pressed)
		dialog_previewer = load(path).instantiate()
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/DialogScenePreviewer/HBoxContainer/PreviewPanel.add_child(dialog_previewer)
	else:
		uncollapse_previewer.visible = false
	
	$MainSplitContainer/ActiveWindowSplit/PhrasesContainer.visible = false
	
	default_expand_button.icon = get_theme_icon("DistractionFree", "EditorIcons")
	
	# --------------------------------------------------------
	dialogs_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	data_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	setting_submenu.id_pressed.connect(_on_create_dialog_id_pressed)
	_recently_opened_popup.index_pressed.connect(_on_recent_file_index_pressed)
	node_popup.id_pressed.connect(_on_create_dialog_id_pressed)
	close_localizer_btn.pressed.connect(_on_switch_window_pressed)
	file_popup.id_pressed.connect(_on_file_menu_id_pressed)
	# --------------------------------------------------------
	
	open_btn.pressed.connect(_on_open_conversation_pressed)
	save_btn.pressed.connect(_on_save_conversation_pressed)
	
	argument_opt_btn.item_selected.connect(_on_argument_button_item_selected)
	
	node_search_ln_edt.text_changed.connect(_on_discourse_node_search_text_changed)
	new_language_btn.pressed.connect(_on_new_lang_pressed)
	languages_tree.locale_changed.connect(_on_side_editor_locale_changed, CONNECT_DEFERRED)
	languages_tree.locale_creation_requested.connect(_on_languages_tree_locale_creation_requested)
	languages_tree.locale_delete_requested.connect(_on_locale_delete_requested, CONNECT_DEFERRED)
	
	discourse_nodes_tree.node_activated.connect(_on_discourse_node_activated)
	discourse_nodes_tree.item_renamed.connect(_on_discourse_item_renamed)
	discourse_nodes_tree.folder_renamed.connect(_on_discourse_folder_renamed)
	discourse_nodes_tree.item_moved.connect(_on_discourse_item_moved)
	discourse_nodes_tree.directory_removed.connect(_on_discourse_directory_removed)
	discourse_nodes_tree.collapsed_state_changed.connect(_on_collapsed_state_changed)
	
	localization_nodes_tree.dialog_selected.connect(_on_localizer_node_selected)
	localization_nodes_tree.node_delocalization_requested.connect(_on_node_delocalization_requested)
	localization_nodes_tree.dialog_item_edited.connect(_on_localizer_item_renamed)
	translation_txt_box.text_changed.connect(_on_translation_text_changed)
	translation_txt_box.focus_exited.connect(_on_localization_text_edit_focus_exited)
	
	new_folder_button.pressed.connect(_on_new_folder_button_pressed)
	
	save_case_btn.pressed.connect(_on_save_cases_btn_pressed)
	new_text_button.pressed.connect(_on_new_key_field_button_pressed)
	new_case_btn.pressed.connect(_on_new_case_button_pressed)
	search_text_ln_edt.text_changed.connect(_on_key_search_text_changed)
	search_case_ln_edt.text_changed.connect(_on_case_search_text_changed)
	
	default_case_edt.text_changed.connect(_on_phrase_text_field_changed.bind(default_case_edt))
	default_case_edt.resized.connect(_update_choice_textbox_size.bind(default_case_edt))
	default_case_edt.focus_exited.connect(_on_phrase_case_result_focus_exited.bind(default_case_edt))
	
	hide_issues_btn.pressed.connect(_on_hide_issues_pressed)
	issues_tree.issue_activated.connect(_on_issue_activated)
	
	dialog_id_ln_edt.text_changed.connect(_on_conversation_changed)
	dialog_id_ln_edt.editing_toggled.connect(_on_dialog_id_edit_toggled)
	
	copy_arg_btn.pressed.connect(_on_copy_format_pressed, CONNECT_DEFERRED)
	
	collapse_left_btn.pressed.connect(_on_collapse_left_pressed)
	uncollapse_left_button.pressed.connect(_on_uncollapse_left_pressed)
	
	collapse_right_btn.pressed.connect(_on_collapse_right_pressed)
	uncollapse_right_btn.pressed.connect(_on_uncollapse_right_pressed)
	
	phrases_lang_menu.item_selected.connect(_on_phrase_button_item_selected)
	auto_update_previewer.toggled.connect(_on_auto_update_toggled)
	
	play_previewer.pressed.connect(_on_play_live_preview_pressed)
	default_expand_button.pressed.connect(_on_default_case_focus_pressed)
	
	conversation_tree.conversation_selected.connect(_on_conversation_selected)
	conversation_tree.conversation_close_pressed.connect(_on_conversation_close_pressed)
	
	discourse_graph_edit.dialog_changed.connect(_on_conversation_changed)
	discourse_graph_edit.localization_enabled.connect(_on_localize_node)
	discourse_graph_edit.nodes_removed.connect(_on_nodes_removed)
	discourse_graph_edit.node_created.connect(_on_discourse_node_created)
	discourse_graph_edit.node_duplication_requested.connect(_on_graph_edit_node_duplication_requested)
	discourse_graph_edit.paste_nodes_requested.connect(_on_graph_edit_paste_requested)
	discourse_graph_edit.use_code_editor_requested.connect(_on_open_code_editor_graph_request)
	discourse_graph_edit.browse_character_requested.connect(_on_open_character_browser_request)
	
	discourse_graph_edit.discourse_node_selected.connect(_on_discourse_node_selected)
	discourse_graph_edit.scroll_offset_changed.connect(_on_graph_edit_offset_changed)
	discourse_graph_edit.nodes_moved.connect(_on_nodes_moved)
	discourse_graph_edit.nodes_created.connect(_on_nodes_created_batch, CONNECT_DEFERRED)
	
	discourse_graph_edit.node_connected.connect(_on_node_connected)
	discourse_graph_edit.node_disconnected.connect(_on_node_disconnected)
	discourse_graph_edit.node_connection_switched.connect(_on_node_connection_switched)
	
	discourse_graph_edit.node_resized.connect(_on_node_resized)
	discourse_graph_edit.comment_node_text_changed.connect(_on_comment_node_text_changed)
	discourse_graph_edit.comparation_node_operator_changed.connect(_on_comparation_node_operator_changed)
	discourse_graph_edit.dialog_node_character_id_changed.connect(_on_dialog_node_character_id_changed)
	discourse_graph_edit.dialog_node_text_changed.connect(_on_dialog_node_text_changed)
	discourse_graph_edit.dialog_node_presist_toggled.connect(_on_dialog_node_presist_toggled)
	discourse_graph_edit.choice_node_text_changed.connect(_on_choice_node_text_changed)
	discourse_graph_edit.choices_node_resized.connect(_on_choices_node_resized)
	discourse_graph_edit.shortcut_node_target_changed.connect(_on_shortcut_node_target_changed)
	discourse_graph_edit.shortcut_node_id_changed.connect(shortcut_node_id_changed) # Note: no _on_ prefix as defined in your methods
	discourse_graph_edit.localized_node_text_changed.connect(_on_localized_node_text_changed)
	discourse_graph_edit.match_node_cases_resized.connect(_on_match_node_cases_resized)
	discourse_graph_edit.match_node_field_updated.connect(_on_match_node_field_updated)
	discourse_graph_edit.match_node_mode_changed.connect(_on_match_node_mode_changed)
	discourse_graph_edit.metadata_node_key_changed.connect(_on_metadata_node_key_changed)
	discourse_graph_edit.call_node_method_changed.connect(_on_call_node_method_changed)
	discourse_graph_edit.call_return_method_changed.connect(_on_call_return_method_changed)
	discourse_graph_edit.random_node_count_state_changed.connect(_on_random_node_count_state_changed)
	discourse_graph_edit.random_val_node_mode_changed.connect(_on_random_val_node_mode_changed)
	discourse_graph_edit.random_val_node_range_changed.connect(_on_random_val_node_range_changed)
	discourse_graph_edit.resource_node_path_changed.connect(_on_resource_node_path_changed)
	discourse_graph_edit.signal_node_signal_changed.connect(_on_signal_node_signal_changed)
	discourse_graph_edit.guard_node_fallback_changed.connect(_on_guard_node_fallback_changed)
	discourse_graph_edit.value_node_value_changed.connect(_on_value_node_value_changed)
	discourse_graph_edit.value_node_type_changed.connect(_on_value_node_type_changed)
	discourse_graph_edit.variable_node_type_changed.connect(_on_variable_node_type_changed)
	discourse_graph_edit.variable_node_path_changed.connect(_on_variable_node_path_changed)
	discourse_graph_edit.close_frame_requested.connect(_on_close_frame_requested)
	discourse_graph_edit.frame_title_changed.connect(_on_frame_title_changed)
	discourse_graph_edit.frame_color_changed.connect(_on_frame_color_changed)
	discourse_graph_edit.event_path_changed.connect(_on_event_node_path_changed)
	discourse_graph_edit.data_event_path_changed.connect(_on_data_event_node_path_changed)


func get_column_left() -> Control:
	return $MainSplitContainer/MainSidebar


func _add_phrase_menu_locale(lang: String, country: String) -> void:
	# Title, code
	var locale_entries: Dictionary[String, String] = {}
	var locale_code: String = lang if country.is_empty() else lang + "_" + country
	var selected_lang: String = "" if phrases_lang_menu.selected == -1 else phrases_lang_menu.get_item_metadata(phrases_lang_menu.selected)
	var new_index: int = -1
	
	for item_idx in range(phrases_lang_menu.item_count):
		var code: String = phrases_lang_menu.get_item_metadata(item_idx)
		locale_entries[phrases_lang_menu.get_item_text(item_idx)] = code
		if code == locale_code:
			return
	
	var locale_title: String = TranslationServer.get_language_name(lang)
	if not country.is_empty():
		locale_title += " (" + TranslationServer.get_country_name(country) + ")"
	
	locale_entries[locale_title] = locale_code
	
	var all_titles: Array[String] = []
	all_titles.assign(locale_entries.keys())
	all_titles.sort()
	
	for title_idx in range(all_titles.size()):
		if locale_entries[all_titles[title_idx]] == selected_lang:
			new_index = title_idx
			break
	
	phrases_lang_menu.clear()
	
	for item in all_titles:
		phrases_lang_menu.add_item(item)
		phrases_lang_menu.set_item_metadata(-1, locale_entries[item])
	
	if -1 < new_index:
		phrases_lang_menu.select(new_index)
	else:
		phrases_lang_menu.select(0)
		phrases_lang_menu.set_meta(&"old_value", phrases_lang_menu.get_item_metadata(0))


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
			return


func _on_phrase_button_item_selected(idx: int) -> void:
	var locale: String = phrases_lang_menu.get_item_metadata(idx)
	var prev_locale: String = phrases_lang_menu.get_meta(&"old_value", "")
	phrases_lang_menu.text = locale
	phrases_lang_menu.tooltip_text = phrases_lang_menu.get_item_text(idx)
	if not prev_locale.is_empty():
		save_phrase_keys(prev_locale)
	set_phrases_locale(locale)
	phrases_lang_menu.set_meta(&"old_value", phrases_lang_menu.get_item_metadata(idx))


func set_phrases_locale(locale: String) -> void:
	for entry in %PhrasesEntries.get_children():
		var line: LineEdit = entry.get_child(1)
		var text_field: TextEdit = entry.get_child(2)
		var key: String = entry.get_meta(&"phrase_key")
		
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
	
	_add_phrase_menu_locale(language, region)
	
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
	phrases_lang_menu.clear()
	
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
	
	if -1 < selected_phrase_index and phrases_lang_menu.get_selected_metadata() == locale:
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


func _on_locale_submenu_idx_pressed(idx: int, submenu: PopupMenu) -> void:
	var from: String = current_locale
	var count: String = submenu.get_item_metadata(idx)
	var lang: String = ""
	
	for item_idx in range(locale_popup.item_count):
		if locale_popup.get_item_submenu_node(item_idx) == submenu:
			lang = locale_popup.get_item_metadata(item_idx)
			break
	
	if lang.is_empty():
		NFPluginGameHandler._log_msg(
			"discourse - editor",
			"Error selecting locale",
			NFPluginGameHandler._LogLevel.ERROR)
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
		discourse_graph_edit.spawn_node_at_center(id)
	else:
		var uuid: StringName = discourse_graph_edit.spawn_frame_at_center()
		var frame: GraphFrame = discourse_graph_edit.get_discourse_frame(uuid)
		var action_data: Dictionary = {
			"uuid": uuid,
			"frame_data": frame.get_frame_data(),
			"attached_elements": {}}
		
		undo.create_action("Create Frame")
		undo.add_do_method(_undo_remove_frame.bind(action_data))
		undo.add_undo_method(_do_remove_frame.bind(uuid))
		undo.commit_action(false)
	_on_conversation_changed()


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
	line_confirmation.allow_empty = true
	line_confirmation.set_line_text(active_conversation.locale_group)
	add_child(line_confirmation)
	line_confirmation.show()
	var result: Array = await line_confirmation.dialog_finished
	line_confirmation.queue_free()
	
	if not result[0] or result[1] == active_conversation.locale_group:
		return
	
	var old_group: String = active_conversation.locale_group
	var new_group: String = result[1]
	
	undo.create_action("Set Locale Group")
	undo.add_do_method(_do_update_locale_group.bind(new_group))
	undo.add_undo_method(_do_update_locale_group.bind(old_group))
	undo.commit_action()
	
	_on_conversation_changed()


func _on_collapsed_state_changed() -> void:
	if active_conversation == null:
		return
	_unsaved = true


func _on_graph_edit_offset_changed(_offset: Vector2) -> void:
	if not listen_offset or active_conversation == null:
		return
	_open_files[active_conversation.get_instance_id()]["offset_changed"] = true


func _on_conversation_close_pressed(dialog_id: int) -> void:
	if not _open_files.has(dialog_id):
		return
	
	var is_active: bool = false if active_conversation == null else active_conversation.get_instance_id() == dialog_id
	
	if _open_files[dialog_id]["unsaved"]:
		var unsaved_prompt: AcceptDialog = preload("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
		add_child(unsaved_prompt)
		unsaved_prompt.show()
		var result: int = await unsaved_prompt.dialog_finished
		if result == 0: # Save
			if is_active:
				save_current_dialog_to_memory()
			ResourceSaver.save(_open_files[dialog_id]["resource"])
		elif result == 1: # Don't save
			_open_files[dialog_id]["offset_changed"] = false
		elif result == 2: # Cancel
			unsaved_prompt.queue_free()
			return
		unsaved_prompt.queue_free()
	
	if _open_files[dialog_id]["offset_changed"]:
		save_layout_of(dialog_id)
	
	close_dialog_resource(dialog_id)


func close_dialog_resource(dialog_id: int, open_previous: bool = true) -> void:
	if not _open_files.has(dialog_id):
		return
	
	var is_active: bool = false if active_conversation == null else active_conversation.get_instance_id() == dialog_id
	
	conversation_tree.remove_conversation(dialog_id)
	_open_files[dialog_id]["undo"].clear_history()
	_open_files[dialog_id]["undo"].free()
	_open_files.erase(dialog_id)
	
	if is_active:
		if is_instance_valid(discourse_graph_edit.focus_tween):
			discourse_graph_edit.stop_focus_animation()
		key_box_container.visible = true
		case_box_container.visible = false
		selected_phrase_index = -1
		
		if not open_previous:
			active_conversation = null
			set_conversation_active(false)
			display_conversation(null)
			clear_localized_keys()
			clear_cases()
			dialog_id_ln_edt.text = ""
			conversation_tree.active_unsaved = false
			new_text_button.disabled = true
			dialog_scene_previewer.visible = false
			return
	else:
		return
	
	conversation_tree.select_conversation(previous_conversation, false)
	
	var save_required: bool = open_conversation(
		_open_files[previous_conversation]["resource"])
	
	if save_required:
		_unsaved = true


func _on_menu_close_pressed() -> void:
	if active_conversation == null:
		return
	
	var dialog_id: int = active_conversation.get_instance_id()
	
	if _open_files[dialog_id]["unsaved"]:
		var unsaved_prompt: AcceptDialog = preload("res://addons/nexus_forge/dialogs/unsaved_dialog_script.gd").new()
		add_child(unsaved_prompt)
		unsaved_prompt.show()
		var result: int = await unsaved_prompt.dialog_finished
		unsaved_prompt.queue_free()
		if result == 0: # Save
			save_dialog_resource(dialog_id)
		elif result == 1: # Don't save
			_open_files[dialog_id]["offset_changed"] = false
		elif result == 2: # Cancel
			return
	
	if _open_files[dialog_id]["offset_changed"]:
		save_layout_of(dialog_id)
	
	close_dialog_resource(dialog_id)


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
	window.queue_free()
	
	if result.is_empty() or base_language == result:
		return
	
	var created_new: bool = not languages_tree.has_language(result)
	var old_default: String = base_language
	
	undo.create_action("Set Default Locale (%s)" % result)
	undo.add_do_method(_do_set_default_locale.bind(result, created_new))
	undo.add_undo_method(_undo_set_default_locale.bind(old_default, result, created_new))
	undo.commit_action()
	
	_on_conversation_changed()


func _on_translation_text_changed() -> void:
	_on_conversation_changed()
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
	
	default_case_edt.clear()
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
		save_localizer_data(from)
		
		if active_node != null and from == current_locale:
			var uuid: StringName = active_node.get_node_uuid()
			match active_node.node_type:
				DiscourseGraphNode.DialogueNodeType.DIALOG:
					var text: String = translation_txt_box.text.strip_edges()
					active_node.set_dialog_text(text)
				DiscourseGraphNode.DialogueNodeType.CHOICES:
					var choices: = get_localizer_choices()
					var choice_n: int = 0
					for choice in choices:
						choice_n += 1
						active_node.set_choice_text(choice_n, choice)
				DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
					var text: String = translation_txt_box.text.strip_edges()
					active_node.set_text(translation_txt_box.text.strip_edges())
	
	if to.is_empty() or active_node == null:
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = false
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = false
		if dialog_scene_previewer.visible:
			dialog_scene_previewer.visible = false
			$LocalizationContainer/FooterContainer/UncollapsePreviewBtn.visible = true
		return
	
	var base_locale: String = languages_tree.get_base_language()
	var node_uuid: StringName = active_node.get_node_uuid()
	
	if active_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG or active_node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
		var base_text: String = ""
		var new_text: String = ""
		
		new_text = DictUtils.get_nested_value(
			active_conversation.localization,
			[node_uuid, "locales", to],
			"",
			true)
		
		base_text = DictUtils.get_nested_value(
			active_conversation.localization,
			[node_uuid, "locales", base_locale],
			base_text_edt.text,
			true)
		
		base_text_edt.text = base_text
		translation_txt_box.text = new_text
		
		if dialog_scene_previewer.visible:
			dialog_previewer.set_dialog(new_text)
	elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.CHOICES:
		var localized_options: Array[String] = []
		var base_options: Array[String] = []
		
		localized_options.assign(DictUtils.get_nested_value(
			active_conversation.localization,
			[node_uuid, "locales", to],
			[],
			true))
		
		base_options.assign(DictUtils.get_nested_value(
			active_conversation.localization,
			[node_uuid, "locales", base_locale],
			[],
			true))
		
		clear_localized_options()
		var choice_size: int = active_node.choice_count()
		
		if base_options.size() != choice_size:
			base_options.resize(choice_size)
		
		var localized_size: int = localized_options.size()
		
		if localized_size < choice_size:
			localized_options.append_array(base_options.slice(localized_size))
		
		for option_idx in range(base_options.size()):
			create_choice_node(
				base_options[option_idx],
				localized_options[option_idx])
		
		if dialog_scene_previewer.visible:
			dialog_previewer.set_choices(localized_options)


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
				active_conversation.set_dialog_text(
					old_node.get_node_uuid(),
					translation_txt_box.text.strip_edges(),
					active_locale)
				if update_node:
					old_node.set_dialog_text(translation_txt_box.text)
			DiscourseGraphNode.DialogueNodeType.CHOICES:
				var options: Array[String] = get_localizer_choices()
				
				active_conversation.set_choices_array(
					old_node.get_node_uuid(),
					options,
					active_locale)
				
				if update_node:
					for option_idx in range(options.size()):
						old_node.set_choice_text(
							option_idx + 1,
							options[option_idx])
			DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				active_conversation.set_dialog_text(
					old_node.get_node_uuid(),
					translation_txt_box.text.strip_edges(),
					active_locale)
				if update_node:
					old_node.set_text(translation_txt_box.text)
	
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = new_node.node_type == DiscourseGraphNode.DialogueNodeType.CHOICES
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = !$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible
	# Get the data & set to localizer
	var new_node_uuid: StringName = new_node.get_node_uuid()
	
	match new_node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			var base_text: String = ""
			var new_text: String = ""
			
			new_text = DictUtils.get_nested_value(
				active_conversation.localization,
				[new_node_uuid, "locales", active_locale],
				"",
				true)
			
			base_text = DictUtils.get_nested_value(
				active_conversation.localization,
				[new_node_uuid, "locales", base_language],
				base_text_edt.text,
				true)
			
			base_text_edt.text = base_text
			translation_txt_box.text = new_text
			if dialog_previewer != null and dialog_scene_previewer.visible:
				dialog_previewer.set_dialog(new_text)
			
		DiscourseGraphNode.DialogueNodeType.CHOICES:
			_set_localization_window_choices(new_node)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			var new_text: String = DictUtils.get_nested_value(
				active_conversation.localization,
				[uuid, "locales", active_locale],
				"",
				true)
			var base_text: String = DictUtils.get_nested_value(
				active_conversation.localization,
				[uuid, "locales", base_language],
				"",
				true)
			
			base_text_edt.text = base_text
			translation_txt_box.text = new_text
			
			if dialog_previewer != null and dialog_scene_previewer.visible:
				dialog_previewer.set_dialog(new_text)
	
	localization_node_selected = new_node


func localize_node(node_uuid: StringName) -> void:
	if not discourse_graph_edit.has_discourse_node(node_uuid):
		return
	
	var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(node_uuid)
	
	if node.is_node_localized():
		return
	
	match node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			active_conversation.set_dialog_text(
				node.get_node_uuid(),
				node.get_dialog_text(),
				current_locale)
			localization_nodes_tree.create_dialog_node(node.get_node_id(), node)
		DiscourseGraphNode.DialogueNodeType.CHOICES:
			var text_options: Array[String] = node.get_options()
			active_conversation.set_choices_array(
				node.get_node_uuid(),
				text_options,
				current_locale)
			localization_nodes_tree.create_options_node(node.get_node_id(), node)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			active_conversation.set_dialog_text(
				node.get_node_uuid(),
				node.get_text(),
				current_locale)
			localization_nodes_tree.create_localized_text_node(node.get_node_id(), node)


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
				active_conversation.set_dialog_text(
					active_node.get_node_uuid(),
					translation_txt_box.text.strip_edges(),
					localizer_locale)
			elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				active_conversation.set_dialog_text(
					active_node.get_node_uuid(),
					translation_txt_box.text.strip_edges(),
					localizer_locale)
			elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.CHOICES:
				var choices: Array[String] = get_localizer_choices()
				var target_size: int = active_node.choice_count()
				if choices.size() != target_size:
					choices.resize(target_size)
				active_conversation.set_choices_array(
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
		
		var node_uuid: StringName = active_node.get_node_uuid()
		# Node is option. Specific method call is needed
		if active_node.node_type == DiscourseGraphNode.DialogueNodeType.CHOICES:
			var target_choices: int = active_node.choice_count()
			var options: Array[String] = []
			options.assign(DictUtils.get_nested_value(
					active_conversation.localization,
					[node_uuid, "locales", localizer_locale],
					[],
					true))
			var base_lang: Array[String] = []
			base_lang.assign(DictUtils.get_nested_value(
					active_conversation.localization,
					[node_uuid, "locales", base_language],
					[],
					true))
			
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
			var localized_text: String = DictUtils.get_nested_value(
				active_conversation.localization,
				[node_uuid, "locales", localizer_locale],
				"",
				true)
			var base_text: String = DictUtils.get_nested_value(
				active_conversation.localization,
				[node_uuid, "locales", base_language],
				"",
				true)
				
			base_text_edt.text = base_text
			translation_txt_box.text = localized_text
			
			if dialog_previewer != null:
				dialog_previewer.set_dialog(localized_text)
	else:
		# If no active node was selected or no locale is selected we stop to prevent
		# bad data assignation.
		if active_node == null or current_locale.is_empty():
			return
		
		if active_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG:
			active_node.set_dialog_text(
				translation_txt_box.text.strip_edges())
		elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.CHOICES:
			var option_number: int = 0
			for option_node in choices_container.get_children():
				option_number += 1
				active_node.set_choice_text(
					option_number,
					option_node.get_child(2).text)
		elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			active_node.set_text(
				translation_txt_box.text)
	# ----------------------------------------------------------------------


func _on_languages_tree_locale_creation_requested(locale_code: String) -> void:
	if locale_code.is_empty() or has_locale(locale_code):
		return
	
	undo.create_action("Add Locale (%s)" % locale_code)
	undo.add_do_method(_do_add_locale_action.bind(locale_code))
	undo.add_undo_method(_do_remove_locale_action.bind(locale_code))
	undo.commit_action()
	
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
	window.queue_free()
	
	if result.is_empty() or has_locale(result):
		return
	
	undo.create_action("Add Locale")
	undo.add_do_method(_do_add_locale_action.bind(result))
	undo.add_undo_method(_do_remove_locale_action.bind(result))
	undo.commit_action()
	
	_on_conversation_changed()


func _on_locale_delete_requested(locale: String) -> void:
	if locale.is_empty():
		return
	
	var snapshot: Dictionary = _get_locale_snapshot(locale)
	undo.create_action("Delete Locale (%s)" % locale)
	undo.add_do_method(_do_remove_locale_action.bind(locale))
	undo.add_undo_method(_do_add_locale_action.bind(locale, snapshot))
	undo.commit_action()
	_on_conversation_changed()


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
	
	if phrases_lang_menu.selected != -1:
		save_phrase_keys(phrases_lang_menu.get_selected_metadata())
	if $LocalizationContainer.visible and localization_nodes_tree.get_active_node() != null:
		save_localizer_data(languages_tree.get_active_locale())
	
	var locale_map: Dictionary[String, Dictionary] = languages_tree.as_map()
	active_conversation.locale_map = locale_map.duplicate(true)
	
	active_conversation.collapsed_state = discourse_nodes_tree.get_collapsed_folders()
	active_conversation.zoom = discourse_graph_edit.zoom
	active_conversation.scroll_offset = discourse_graph_edit.scroll_offset
	active_conversation.node_structure = discourse_nodes_tree.get_folder_structure()
	active_conversation.dialog_id = dialog_id_ln_edt.text.strip_edges()


func _on_conversation_selected(dialog_id: int) -> void:
	if not _open_files.has(dialog_id):
		return
	
	if active_conversation != null and active_conversation.get_instance_id() == dialog_id:
		return
	
	if _conversation_options_disabled:
		set_graph_edit_visible(true)
		set_conversation_options_enabled(true)
		discourse_nodes_tree.get_root().collapsed = false
		new_folder_button.disabled = false
		dialog_id_ln_edt.editable = true
		
	if active_conversation != null:
		save_current_dialog_to_memory()
	
	if open_conversation(dialog_id): # Resaving Needed
		conversation_tree.active_unsaved = true


func clear_localized_options() -> void:
	for node in choices_container.get_children():
		node.queue_free()
		choices_container.remove_child(node)


func set_localized_choice_line_text(choice_index: int, text: String) -> void:
	var child_count: int = choices_container.get_child_count()
	if child_count == 0:
		return
	var max_index: int = child_count - 1
	if not RangeUtils.is_between(choice_index, -child_count, max_index):
		return
	var true_index: int = wrapi(choice_index, 0, child_count)
	var line: TextEdit = choices_container.get_child(true_index).get_child(2)
	line.text = text
	line.set_meta(&"old_value", text)


func create_choice_node(base_text: String, localized_text: String) -> void:
	var new_container: HBoxContainer = HBoxContainer.new()
	var new_choice_count: Label = Label.new()
	var base_text_label: Label = Label.new()
	#var localization_lnedt: LineEdit = LineEdit.new()
	var new_choice: TextEdit = BracketHandler.new()
	var highlighter: NFEditorDialogSyntaxHighlighter = NFEditorDialogSyntaxHighlighter.new()
	
	highlighter.set_use_token("*", false)
	
	base_text_label.text = base_text
	base_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	base_text_label.size_flags_stretch_ratio = 2.0
	base_text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	base_text_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	base_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	base_text_label.tooltip_text = base_text
	
	new_choice.syntax_highlighter = NFEditorDialogSyntaxHighlighter.new()
	new_choice.text = localized_text
	new_choice.placeholder_text = "Translation"
	new_choice.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	new_choice.scroll_fit_content_height = true
	new_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_choice.syntax_highlighter = highlighter
	new_choice.size_flags_stretch_ratio = 2.0
	new_choice.set_meta(&"old_value", localized_text)
	new_choice.resized.connect(_update_choice_textbox_size.bind(new_choice), CONNECT_DEFERRED)
	
	new_choice_count.text = "Choice #" + str(choices_container.get_child_count() + 1)
	new_choice_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_choice_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	choices_container.add_child(new_container)
	new_container.add_child(new_choice_count)
	new_container.add_child(base_text_label)
	new_container.add_child(new_choice)
	
	new_choice.text_changed.connect(_on_choice_text_changed.bind(new_container))
	new_choice.focus_exited.connect(_on_localization_choice_focus_exited.bind(new_choice))


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
	var file_saver: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	file_saver.file_mode = file_saver.FILE_MODE_SAVE_FILE
	add_child(file_saver)
	file_saver.popup_centered()
	
	var result: Array = await file_saver.dialog_finished
	file_saver.queue_free()
	
	if not result[0]:
		return
	
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
	var file_opener: FileDialog = load("res://addons/nexus_forge/classes/resource_file_dialog.gd").get_file_browser()
	file_opener.file_mode = file_opener.FILE_MODE_OPEN_FILE
	add_child(file_opener)
	file_opener.popup_centered()
	
	var result: Array = await file_opener.dialog_finished
	file_opener.queue_free()
	
	if result[0] and FileAccess.file_exists(result[1]):
		listen_offset = false
		var resource: Resource = load(result[1])
		if resource != null and resource is EditorDiscourseDialog:
			var file_id: int = resource.get_instance_id()
			
			if _open_files.has(file_id):
				conversation_tree.select_conversation(file_id, false)
				if open_conversation(file_id):
					_unsaved = true
				listen_offset = true
				return

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
			
			load_conversation(resource)
			
			add_to_recently_opened_files(result[1])
		
		set_deferred(&"listen_offset", true)


func _on_play_current_dialog_pressed() -> void:
	if active_conversation == null:
		return
	
	var resource_id: int = active_conversation.get_instance_id()
	var res_path: String = active_conversation.resource_path
	var custom_scene: String = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("discourse_custom_dialog_debug_scene"), "").strip_edges()
	var scene_path: String = "res://addons/nexus_forge/discourse/dialog_previewer.tscn"
	
	if not custom_scene.is_empty() and FileAccess.file_exists(custom_scene):
		scene_path = custom_scene
	
	if res_path.is_empty():
		NFPluginGameHandler._log_msg(
			"discourse - editor",
			"Current dialog has no path.",
			NFPluginGameHandler._LogLevel.ERROR)
		return
	
	var cfg: ConfigFile = ConfigFile.new()
	
	if FileAccess.file_exists("user://nexus_forge/discourse_settings.cfg"):
		cfg.load("user://nexus_forge/discourse_settings.cfg")
	
	cfg.set_value("Discourse", "active_scene", res_path)
	cfg.set_value("Discourse", "target_locale", current_locale)
	
	if not DirAccess.dir_exists_absolute("user://nexus_forge/"):
		DirAccess.make_dir_absolute("user://nexus_forge/")
	
	cfg.save("user://nexus_forge/discourse_settings.cfg")
	if _open_files[resource_id]["unsaved"]:
		save_dialog_resource(resource_id)
	EditorInterface.play_custom_scene(scene_path)


func plugin_file_selected(file: EditorDiscourseDialog):
	if _conversation_options_disabled:
		set_graph_edit_visible(true)
		set_conversation_options_enabled(true)
		discourse_nodes_tree.get_root().collapsed = false
		new_folder_button.disabled = false
		dialog_id_ln_edt.editable = true
	
	if active_conversation == file:
		add_to_recently_opened_files(active_conversation.resource_path)
		return
	elif active_conversation != null:
		save_current_dialog_to_memory()
	
	var file_id: int = file.get_instance_id()
	
	if _open_files.has(file_id):
		conversation_tree.select_conversation(file_id, false)
		if open_conversation(file_id):
			_unsaved = true
	else:
		load_conversation(file, true)
	
	add_to_recently_opened_files(file.resource_path)


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

#endregion

func display_conversation(conversation: EditorDiscourseDialog, with_locale: String = current_locale) -> bool:
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
		var data: Dictionary = conversation.get_node_data(node_stnm_uuid, with_locale)
		var metadata: Dictionary = data["metadata"]
		var d_node: DiscourseGraphNode = discourse_graph_edit.spawn_node(data["type"], node_stnm_uuid, data)
		
		if d_node.node_type == DiscourseGraphNode.DialogueNodeType.CALLABLE or d_node.node_type == DiscourseGraphNode.DialogueNodeType.CALLABLE_RETURN:
			if metadata.has("method") and not metadata["method"].is_empty():
				if not d_node.available_methods.has(metadata["method"]):
					NFPluginGameHandler._log_msg(
						"discourse - editor",
						"Node '%s' calls method '%s' but it isn't available." % [data["name"], metadata["method"]],
						NFPluginGameHandler._LogLevel.WARNING)
					needs_resaving = true
		elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.SIGNAL:
			if metadata.has("signal") and not metadata["signal"].is_empty():
				if not d_node.available_signals.has(metadata["signal"]):
					NFPluginGameHandler._log_msg(
						"discurse - editor",
						"Node '%s' calls signal '%s' but it isn't available." % [data["name"], metadata["signal"]],
						NFPluginGameHandler._LogLevel.WARNING)
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
			elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.CHOICES:
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
			NFPluginGameHandler._log_msg(
				"discourse - editor",
				"Connection from node '%s' from port '%s' to node '%s' to port '%s' failed" % [graph_map[output_connection["from"]].get_node_id(), output_connection["from_port"], graph_map[output_connection["to"]].get_node_id(), output_connection["to_port"]],
				NFPluginGameHandler._LogLevel.WARNING)
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
	
	discourse_graph_edit.refresh_anchors()
	
	return needs_resaving


# Loads a conversation into discourse.
func open_conversation(dialog_id: int) -> bool:
	if not _open_files.has(dialog_id):
		return false
	
	var conversation: EditorDiscourseDialog = _open_files[dialog_id]["resource"]
	dialog_id_ln_edt.text = conversation.dialog_id
	dialog_id_ln_edt.set_meta(&"old_value", conversation.dialog_id)
	# Clears discourse_nodes_tree's items
	discourse_nodes_tree.clear_tree()
	
	default_case_edt.clear()
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
	var reload_needed: bool = display_conversation(conversation, base_language) # Load conversation
	
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
	
	for localized_key in conversation.format_strings.keys():
		var localized_text: String = conversation.get_format_string(
			localized_key,
			base_language)
		create_new_phrase_entry(localized_key, localized_text, false)
	
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
	set_phrase_button_locale(base_language)
	
	new_text_button.disabled = current_locale.is_empty()
	
	active_conversation = conversation
	undo = _open_files[dialog_id]["undo"]
	
	return reload_needed


# Adds a conversation into the list, can open it.
func load_conversation(data: EditorDiscourseDialog, open_conv: bool = true) -> void:
	var conversation_id: int = data.get_instance_id()
	
	if not _open_files.has(conversation_id):
		_open_files[conversation_id] = {
			"resource": data,
			"undo": UndoRedo.new(),
			"unsaved": false,
			"offset_changed": false}
	
	conversation_tree.add_conversation(
		conversation_id,
		data.resource_path,
		open_conv, # Select
		false) # Emit Select
	
	if open_conv:
		if open_conversation(conversation_id):
			_unsaved = true


func save_localizer_data(for_locale: String) -> void:
	if active_conversation == null:
		return
	
	var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	
	if active_node == null:
		return
	
	match active_node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			active_conversation.set_dialog_text(
				active_node.get_node_uuid(),
				translation_txt_box.text,
				for_locale)
		DiscourseGraphNode.DialogueNodeType.CHOICES:
			var options: Array[String] = get_localizer_choices()
			active_conversation.set_choices_array(
				active_node.get_node_uuid(),
				options,
				for_locale)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			active_conversation.set_dialog_text(
				active_node.get_node_uuid(),
				translation_txt_box.text,
				for_locale)


func _on_save_conversation_pressed() -> void:
	if active_conversation == null:
		return
	var id: int = active_conversation.get_instance_id()
	save_dialog_resource(id)


func _on_godot_save_triggered() -> void:
	save_all_dialogs()
	conversation_tree.set_conversations_saved()


func save_dialog_resource(dialog_id: int) -> void:
	if not _open_files.has(dialog_id):
		return
	
	var target: EditorDiscourseDialog = _open_files[dialog_id]["resource"]
	
	if active_conversation == target:
		save_current_dialog_to_memory()
	
	if _open_files[dialog_id]["offset_changed"]:
		save_layout_of(dialog_id)
		_open_files[dialog_id]["offset_changed"] = false
	
	if not _open_files[dialog_id]["unsaved"]:
		return
	
	ResourceSaver.save(target)
	_open_files[dialog_id]["unsaved"] = false
	conversation_tree.set_dialog_unsaved(dialog_id, false)


func save_all_dialogs() -> void:
	if active_conversation != null:
		save_current_dialog_to_memory()
	
	for res_id in _open_files:
		if _open_files[res_id]["unsaved"]:
			ResourceSaver.save(_open_files[res_id]["resource"])
			_open_files[res_id]["unsaved"] = false
		if _open_files[res_id]["offset_changed"]:
			save_layout_of(res_id)
			_open_files[res_id]["offset_changed"] = false
	
	conversation_tree.set_all_files_saved()


func save_layout_of(dialog_id: int) -> void:
	if not _open_files.has(dialog_id):
		return
	var target: EditorDiscourseDialog = _open_files[dialog_id]["resource"]
	var layout_data: Dictionary[String, Variant] = {
		"collapsed_state": target.collapsed_state,
		"zoom": target.zoom,
		"scroll_offset": target.scroll_offset}
	
	_save_file_layout_for(
		target.resource_path,
		layout_data)


func set_conversation_active(is_active: bool) -> void:
	discourse_nodes_tree.get_root().collapsed = not is_active
	set_graph_edit_visible(is_active)
	set_conversation_options_enabled(is_active)
	new_folder_button.disabled = not is_active


func has_unsaved_files() -> bool:
	for id in _open_files:
		if _open_files[id]["unsaved"]:
			return true
	return false


func _save_file_layout_for(file_path: String, keys: Dictionary[String, Variant]) -> void:
	if file_path.is_empty():
		NFPluginGameHandler._log_msg(
			"discourse - editor",
			"Can't save layout data for resource without path.",
			NFPluginGameHandler._LogLevel.ERROR)
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
		NFPluginGameHandler._log_msg(
			"discourse - editor",
			"Couldn't save layout settings for file '%s'." % file_path,
			NFPluginGameHandler._LogLevel.WARNING)


#region Phrases

func _on_key_search_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	
	if clean_text == search_text_ln_edt.get_meta(&"current_search", ""):
		return
	
	var mode: int = 1 if clean_text.begins_with("key:") else 2 if clean_text.begins_with("text:") else 0
	
	if mode != 0:
		clean_text = clean_text.trim_prefix("key:" if mode == 1 else "text:")
	
	var idx: int = -1
	
	if clean_text.is_empty():
		for entry in %PhrasesEntries.get_children():
			entry.visible = true
	else:
		for entry in %PhrasesEntries.get_children():
			if mode == 0: # Both
				entry.visible = entry.get_child(1).text.containsn(clean_text) or entry.get_child(2).text.containsn(clean_text)
			elif mode == 1: # Key
				entry.visible = entry.get_child(1).text.containsn(clean_text)
			elif mode == 2: # Phrase
				entry.visible = entry.get_child(2).text.containsn(clean_text)
	
	search_text_ln_edt.set_meta(&"current_search", clean_text)


func _on_case_search_text_changed(text: String) -> void:
	var clean_text: String = text.strip_edges()
	
	if clean_text == search_case_ln_edt.get_meta(&"current_search", ""):
		return
	
	var mode: int = 1 if clean_text.begins_with("case:") else 2 if clean_text.begins_with("result:") else 0
	var entries: Array[Node] = %PhraseCasesEntries.get_children().slice(1)
	
	if mode != 0:
		clean_text = clean_text.trim_prefix("case:" if mode == 1 else "result:")
	
	if clean_text.is_empty():
		for case in entries:
			case.visible = true
	else:
		for case in entries:
			if mode == 0: # Any
				case.visible = case.get_child(1).text.containsn(clean_text) or case.get_child(2).text.containsn(clean_text)
			elif mode == 1: # Case
				case.visible = case.get_child(1).text.containsn(clean_text)
			elif mode == 2: # Result
				case.visible = case.get_child(2).text.containsn(clean_text)
	
	search_case_ln_edt.set_meta(&"current_search", clean_text)


func _on_new_case_button_pressed() -> void:
	create_new_phrase_case()
	_on_conversation_changed()


func _on_erase_case_button_pressed(case_line: Control) -> void:
	erase_case(case_line.get_index())
	_on_case_line_text_changed()


func _on_open_phrase_case_text_editor_pressed(target: TextEdit) -> void:
	if text_editor.visible:
		return
	
	text_editor.clear()
	
	var initial_text: String = target.text
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
	
	text_editor.signal_variables = false
	text_editor.plain_formats = plain_formats
	text_editor.methods = method_strings
	text_editor.variables = var_strings
	
	text_editor.set_code_text(target.text)
	text_editor.popup_centered()
	text_editor.grab_code_focus()
	
	var result = await text_editor.action_finished
	
	if not result[0] or initial_text == result[1]:
		return
	
	target.text = result[1]
	_on_phrase_case_result_focus_exited(target)
	_on_conversation_changed()


func _on_open_character_browser_request(node_uuid: StringName, target: LineEdit) -> void:
	character_browser_requested.emit(node_uuid, target)


func _on_phrase_field_code_editor_requested(target: TextEdit) -> void:
	if text_editor.visible:
		return
	
	text_editor.clear()
	
	var initial_text: String = target.text
	var api_methods: Dictionary = get_api_user_methods()
	var method_strings: Array[String] = []
	method_strings.assign(api_methods.keys())
	var string_keys: Array[String] = []
	string_keys.assign(active_conversation.format_strings.keys())
	
	text_editor.phrase_keys = string_keys
	text_editor.methods = method_strings
	text_editor.set_code_text(target.text)
	text_editor.popup_centered()
	text_editor.grab_code_focus()
	
	var result = await text_editor.action_finished
	
	if not result[0] or result[1] == initial_text:
		return
	
	var phrase_id: String = target.get_parent().get_meta(&"phrase_key")
	var locale_code: String = phrases_lang_menu.get_selected_metadata()
	var old_state: Dictionary = {}
	
	if DictUtils.has_nested_path(active_conversation.format_strings, [phrase_id, locale_code]):
		old_state = active_conversation.format_strings[phrase_id][locale_code].duplicate(true)
	
	set_phrase_format_string(phrase_id, locale_code, result[1])
	target.set_meta(&"old_value", result[1])
	
	var new_state: Dictionary = active_conversation.format_strings[phrase_id][locale_code].duplicate(true)
	
	undo.create_action("Set Phrase Text (%s)" % locale_code)
	undo.add_do_method(_set_phrase_state_action.bind(phrase_id, locale_code, new_state))
	undo.add_undo_method(_set_phrase_state_action.bind(phrase_id, locale_code, old_state))
	undo.commit_action(false)
	
	
	target.text = result[1]
	
	_on_conversation_changed()


func _on_open_code_editor_graph_request(node_uuid: StringName, target: TextEdit) -> void:
	if text_editor.visible:
		return
	
	text_editor.clear()
	
	var initial_text: String = target.text
	var api_methods: Dictionary = get_api_user_methods()
	var method_strings: Array[String] = []
	method_strings.assign(api_methods.keys())
	var string_keys: Array[String] = []
	string_keys.assign(active_conversation.format_strings.keys())
	
	text_editor.phrase_keys = string_keys
	text_editor.methods = method_strings
	text_editor.set_code_text(target.text)
	text_editor.popup_centered()
	text_editor.grab_code_focus()
	
	var result = await text_editor.action_finished
	
	if not result[0] or result[1] == initial_text:
		return
	
	var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(node_uuid)
	target.text = result[1]
	
	if node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG:
		_on_dialog_node_text_changed(node_uuid, initial_text, result[1])
	elif node.node_type == DiscourseGraphNode.DialogueNodeType.CHOICES:
		_on_choice_node_text_changed(node_uuid, target.get_parent().get_index(), initial_text, result[1])
	
	_on_conversation_changed()


func _on_editor_variable_called(path: String) -> void:
	code_editor_variables_requested.emit(path.strip_edges().simplify_path())


func set_text_code_editor_variable_paths(paths: Array[Dictionary]) -> void:
	if not text_editor.visible:
		return
	
	text_editor.display_completion_options_variables(paths)


func _on_case_line_text_changed(_text: String = "") -> void:
	_validate_phrase_cases()
	_on_conversation_changed()


func _validate_phrase_cases() -> void:
	var all_ids: Dictionary[String, Array] = {}
	
	for case_idx in range(1, %PhraseCasesEntries.get_child_count()):
		var case: HBoxContainer = %PhraseCasesEntries.get_child(case_idx)
		if case.is_queued_for_deletion():
			continue
		
		var item: LineEdit = case.get_child(1)
		var key: String = item.text.strip_edges()
		
		if key.is_empty():
			continue
		
		if not all_ids.has(key):
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
	
	if argument_opt_btn.selected == -1:
		return
	
	save_current_phrase_key(
		phrases_lang_menu.get_selected_metadata(),
		argument_opt_btn.get_item_text(argument_opt_btn.selected))
	clear_cases()
	default_case_edt.clear()
	search_case_ln_edt.text = ""
	search_case_ln_edt.set_meta(&"current_search", "")
	argument_opt_btn.clear()


func _on_edit_cases_pressed(field: Control) -> void:
	var phrase_key: String = field.get_meta(&"phrase_key")
	var clean_string: String = field.get_child(2).text.strip_edges()
	var locale_code: String = phrases_lang_menu.get_selected_metadata()
	
	if locale_code.is_empty():
		NFPluginGameHandler._log_msg(
			"discourse - editor",
			"Locale menu is empty. Can't load data.",
			NFPluginGameHandler._LogLevel.ERROR)
		return
	
	phrases_lang_menu.disabled = true
	key_display_label.text = field.get_child(1).text.strip_edges()
	
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
	
	selected_phrase_index = field.get_index()
	default_case_edt.editable = 0 < argument_opt_btn.item_count
	argument_opt_btn.disabled = not default_case_edt.editable
	new_case_btn.disabled = argument_opt_btn.disabled
	
	if 0 < argument_opt_btn.item_count:
		var argument_format: String = argument_opt_btn.get_item_text(0)
		argument_opt_btn.select(0)
		selected_phrase_format = argument_format
		default_case_edt.text = active_conversation.get_format_string_default_case(phrase_key, locale_code, argument_format)
		
		if DictUtils.has_nested_path(active_conversation.format_strings, [phrase_key, locale_code, "format", argument_format, "cases"]):
			for custom_case in active_conversation.format_strings[phrase_key][locale_code]["format"][argument_format]["cases"].keys():
				create_new_phrase_case(
					custom_case,
					active_conversation.get_format_string_case(phrase_key, locale_code, argument_format, custom_case))
	
	case_box_container.visible = true
	key_box_container.visible = false


func _on_key_line_text_changed(_text: String = "") -> void:
	_on_conversation_changed()


func _on_erase_key_button_pressed(field: HBoxContainer) -> void:
	var phrase_key: String = field.get_meta(&"phrase_key")
	if selected_phrase_index == field.get_index():
		selected_phrase_index = -1
		clear_cases()
		default_case_edt.clear()
		default_case_edt.editable = false
		argument_opt_btn.clear()
		argument_opt_btn.disabled = true
		new_case_btn.disabled = true
	
	active_conversation.format_strings.erase(phrase_key)
	
	erase_key(field.get_index())
	
	_on_key_line_text_changed()


func _on_new_key_field_button_pressed() -> void:
	create_new_phrase_entry(&"", "")
	_on_conversation_changed()


func _rebuild_phrase_text_menu(text_menu: PopupMenu) -> void:
	var submenus: Dictionary[int, PopupMenu] = {}
	
	for idx in range(text_menu.item_count):
		var submenu: PopupMenu = text_menu.get_item_submenu_node(idx)
		if submenu != null:
			submenus[text_menu.get_item_id(idx)] = submenu
	
	text_menu.clear(false)
	
	const MENU_MAX: int = LineEdit.MenuItems.MENU_MAX
	
	text_menu.add_icon_item(get_theme_icon("DistractionFree", "EditorIcons"), "Open Editor", MENU_MAX + 1)
	text_menu.add_separator()
	text_menu.add_item("Emoji & Symbols", LineEdit.MenuItems.MENU_EMOJI_AND_SYMBOL)
	text_menu.add_separator()
	text_menu.add_item("Cut", LineEdit.MenuItems.MENU_CUT)
	text_menu.add_item("Copy", LineEdit.MenuItems.MENU_COPY)
	text_menu.add_item("Paste", LineEdit.MenuItems.MENU_PASTE)
	text_menu.add_separator()
	text_menu.add_item("Select All", LineEdit.MenuItems.MENU_SELECT_ALL)
	text_menu.add_item("Clear", LineEdit.MenuItems.MENU_CLEAR)
	text_menu.add_separator()
	text_menu.add_item("Undo", LineEdit.MenuItems.MENU_UNDO)
	text_menu.add_item("Redo", LineEdit.MenuItems.MENU_REDO)
	text_menu.add_separator()
	if submenus.has(LineEdit.MenuItems.MENU_SUBMENU_TEXT_DIR):
		text_menu.add_submenu_node_item("Text Writing Direction", submenus[LineEdit.MenuItems.MENU_SUBMENU_TEXT_DIR],  LineEdit.MenuItems.MENU_SUBMENU_TEXT_DIR)
		text_menu.add_separator()
	text_menu.add_check_item("Display Control Characters", LineEdit.MenuItems.MENU_DISPLAY_UCC)
	if submenus.has(LineEdit.MenuItems.MENU_SUBMENU_INSERT_UCC):
		text_menu.add_submenu_node_item("Insert Control Character", submenus[LineEdit.MenuItems.MENU_SUBMENU_INSERT_UCC], LineEdit.MenuItems.MENU_SUBMENU_INSERT_UCC)
	
	var cut_shortcut: Shortcut = Shortcut.new()
	var copy_shortcut: Shortcut = Shortcut.new()
	var paste_shortcut: Shortcut = Shortcut.new()
	var select_all: Shortcut = Shortcut.new()
	var undo_shortcut: Shortcut = Shortcut.new()
	var redo_shortcut: Shortcut = Shortcut.new()
	
	var cut_event: InputEventKey = InputEventKey.new()
	var copy_event: InputEventKey = InputEventKey.new()
	var paste_event: InputEventKey = InputEventKey.new()
	var select_all_event: InputEventKey = InputEventKey.new()
	var undo_event: InputEventKey = InputEventKey.new()
	var redo_event: InputEventKey = InputEventKey.new()
	
	cut_event.keycode = KEY_X
	cut_event.ctrl_pressed = true
	cut_event.device = -1
	
	copy_event.keycode = KEY_C
	copy_event.ctrl_pressed = true
	copy_event.device = -1
	
	paste_event.keycode = KEY_V
	paste_event.ctrl_pressed = true
	paste_event.device = -1
	
	select_all_event.keycode = KEY_A
	select_all_event.ctrl_pressed = true
	select_all_event.device = -1
	
	undo_event.keycode = KEY_Z
	undo_event.ctrl_pressed = true
	undo_event.device = -1
	
	redo_event.keycode = KEY_Z
	redo_event.ctrl_pressed = true
	redo_event.shift_pressed = true
	redo_event.device = -1
	
	cut_shortcut.events = [cut_event]
	copy_shortcut.events = [copy_event]
	paste_shortcut.events = [paste_event]
	select_all.events = [select_all_event]
	undo_shortcut.events = [undo_event]
	redo_shortcut.events = [redo_event]
	
	text_menu.set_item_shortcut(
		text_menu.get_item_index(
			LineEdit.MenuItems.MENU_CUT),
		cut_shortcut)
	
	text_menu.set_item_shortcut(
		text_menu.get_item_index(
			LineEdit.MenuItems.MENU_COPY),
		copy_shortcut)
	
	text_menu.set_item_shortcut(
		text_menu.get_item_index(
			LineEdit.MenuItems.MENU_PASTE),
		paste_shortcut)
	
	text_menu.set_item_shortcut(
		text_menu.get_item_index(
			LineEdit.MenuItems.MENU_SELECT_ALL),
		select_all)
	
	text_menu.set_item_shortcut(
		text_menu.get_item_index(
			LineEdit.MenuItems.MENU_UNDO),
		undo_shortcut)
	
	text_menu.set_item_shortcut(
		text_menu.get_item_index(
			LineEdit.MenuItems.MENU_REDO),
		redo_shortcut)


func _on_phrase_menu_id_pressed(id: int, field: TextEdit) -> void:
	if id <= TextEdit.MenuItems.MENU_MAX:
		return
	
	const MENU_MAX: int = LineEdit.MenuItems.MENU_MAX
	
	if id == MENU_MAX + 1:
		_on_phrase_field_code_editor_requested(field)


func create_new_phrase_case(case: String = "", case_text: String = "") -> void:
	var case_container: HBoxContainer = HBoxContainer.new()
	var erase_case_btn: Button = Button.new()
	var case_line: LineEdit = LineEdit.new()
	var case_editor: TextEdit = BracketHandler.new()
	var expand_case: Button = Button.new()
	var highlighter: NFEditorDialogSyntaxHighlighter = NFEditorDialogSyntaxHighlighter.new()
	
	highlighter.set_use_token("*", false)
	highlighter.set_use_token("?", false)
	
	case_editor.text = case_text
	case_editor.enter_shifts_focus = true
	case_editor.syntax_highlighter = highlighter
	case_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	case_editor.size_flags_stretch_ratio = 2.0
	case_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	case_editor.scroll_fit_content_height = true
	case_editor.set_meta(&"old_value", case_text)
	
	erase_case_btn.tooltip_text = "Erase case"
	erase_case_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_case_btn.flat = true
	erase_case_btn.icon = get_theme_icon("Remove", "EditorIcons")
	erase_case_btn.custom_minimum_size = Vector2(33.0, 33.0)
	erase_case_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	erase_case_btn.pressed.connect(_on_erase_case_button_pressed.bind(case_container))
	
	expand_case.tooltip_text = "Open Editor"
	expand_case.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_case.flat = true
	expand_case.icon = get_theme_icon("DistractionFree", "EditorIcons")
	expand_case.custom_minimum_size = Vector2(33.0, 33.0)
	expand_case.pressed.connect(_on_open_phrase_case_text_editor_pressed.bind(case_editor))
	
	case_line.placeholder_text = "Case"
	case_line.custom_minimum_size.y = 33.0
	case_line.text = case
	case_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	case_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	case_line.size_flags_stretch_ratio = 1.0
	case_line.set_meta(&"old_value", case)
	
	case_container.add_child(erase_case_btn)
	case_container.add_child(case_line)
	case_container.add_child(case_editor)
	case_container.add_child(expand_case)
	
	%PhraseCasesEntries.add_child(case_container)
	
	case_line.focus_neighbor_right = case_editor.get_path()
	case_editor.focus_neighbor_left = case_line.get_path()
	case_line.focus_next = case_editor.get_path()
	case_editor.focus_previous = case_line.get_path()
	
	if 0 < %PhraseCasesEntries.get_child_count() - 1:
		var prev_expand: Button = %PhraseCasesEntries.get_child(-2).get_child(3)
		prev_expand.focus_next = case_line.get_path()
		case_line.focus_previous = prev_expand.get_path()
	else:
		case_line.focus_previous = default_case_edt.get_path()
		default_case_edt.focus_next = case_line.get_path()
	
	case_line.text_changed.connect(_on_case_line_text_changed)
	case_editor.text_changed.connect(_on_phrase_text_field_changed.bind(case_editor))
	case_editor.resized.connect(_update_choice_textbox_size.bind(case_editor))
	
	case_line.editing_toggled.connect(_on_phrase_case_editing_toggled.bind(case_line))
	case_editor.focus_exited.connect(_on_phrase_case_result_focus_exited.bind(case_editor))


func erase_case(index: int) -> void:
	if index <= 0:
		return
	
	var case: HBoxContainer = %PhraseCasesEntries.get_child(index)
	
	if case.is_queued_for_deletion():
		return
	
	var new_case_count: int = %PhraseCasesEntries.get_child_count() - 1
	
	if %PhraseCasesEntries.get_child_count() - 1 <= 0:
		new_case_btn.focus_next = ^""
	else:
		if index == 1: # It's the first item
			var target_ln: LineEdit = %PhraseCasesEntries.get_child(1)
			new_text_button.focus_next = target_ln.get_path()
			target_ln.focus_previous = new_text_button.get_path()
		elif new_case_count == index: # It's the last item
			var target_text: LineEdit = %PhraseCasesEntries.get_child(-2).get_child(3)
			target_text.focus_next = ^""
		else: # It's between 2 items
			var btn_up: Button = %PhraseCasesEntries.get_child(index - 1).get_child(3)
			var line_down: LineEdit = %PhraseCasesEntries.get_child(index + 1).get_child(1)
			btn_up.focus_next = line_down.get_path()
			line_down.focus_previous = btn_up.get_path()
	
	case.queue_free()


func create_new_phrase_entry(key: String, format: String, unsaved: bool = true) -> StringName:
	var container: HBoxContainer = HBoxContainer.new()
	var erase_button: Button = Button.new()
	var key_line: LineEdit = LineEdit.new()
	var text_field: TextEdit = BracketHandler.new()
	var edit_button: Button = Button.new()
	var highlighter: NFEditorDialogSyntaxHighlighter = NFEditorDialogSyntaxHighlighter.new()
	
	highlighter.set_use_token("&", false)
	highlighter.set_use_token("*", false)
	highlighter.set_use_token("?", false)
	
	text_field.syntax_highlighter = highlighter
	
	if key.is_empty():
		key = get_valid_format_key_id(key)
	else:
		key = get_valid_format_key_id(key)
	
	container.set_meta(&"entry_id", UUID.generate_new())
	container.set_meta(&"phrase_key", key)
	container.set_meta(&"unsaved", unsaved)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	key_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	key_line.custom_minimum_size = Vector2(115.0, 33.0)
	key_line.placeholder_text = "Key"
	key_line.text = String(key)
	key_line.set_meta(&"old_value", key_line.text)
	
	erase_button.icon = get_theme_icon("Remove", "EditorIcons")
	erase_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_button.tooltip_text = "Erase key"
	erase_button.flat = true
	erase_button.custom_minimum_size = Vector2(33.0, 33.0)
	erase_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	text_field.text = format
	text_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_field.placeholder_text = "Phrase Text"
	text_field.enter_shifts_focus = true
	text_field.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_field.set_meta(&"old_value", format)
	
	edit_button.custom_minimum_size = Vector2(33.0, 33.0)
	edit_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit_button.flat = true
	edit_button.icon = get_theme_icon("Edit", "EditorIcons")
	edit_button.tooltip_text = "Edit Cases"
	
	var text_menu: PopupMenu = text_field.get_menu()
	_rebuild_phrase_text_menu(text_menu)
	
	container.add_child(erase_button)
	container.add_child(key_line)
	container.add_child(text_field)
	container.add_child(edit_button)
	
	%PhrasesEntries.add_child(container)
	
	if 0 < %PhrasesEntries.get_child_count() - 1:
		var btn: Button = %PhrasesEntries.get_child(-2).get_child(-1)
		btn.focus_next = key_line.get_path()
		key_line.focus_previous = btn.get_path()
	else:
		new_text_button.focus_next = key_line.get_path()
		key_line.focus_previous = new_text_button.get_path()
	
	key_line.focus_next = text_field.get_path()
	key_line.focus_neighbor_right = text_field.get_path()
	
	text_field.focus_previous = key_line.get_path()
	text_field.focus_neighbor_left = key_line.get_path()
	text_field.focus_next = edit_button.get_path()
	
	edit_button.focus_previous = text_field.get_path()
	
	edit_button.pressed.connect(_on_edit_cases_pressed.bind(container))
	text_menu.id_pressed.connect(_on_phrase_menu_id_pressed.bind(text_field))
	text_field.text_changed.connect(_on_phrase_text_field_changed.bind(text_field), CONNECT_DEFERRED)
	text_field.resized.connect(_update_choice_textbox_size.bind(text_field))
	
	text_field.focus_exited.connect(_on_phrase_text_editing_focus_lost.bind(text_field))
	key_line.editing_toggled.connect(_on_phrase_key_editing_toggled.bind(key_line))
	
	key_line.text_changed.connect(_on_key_line_text_changed)
	erase_button.pressed.connect(_on_erase_key_button_pressed.bind(container))
	
	return key


func erase_key(index: int) -> void:
	var entry: HBoxContainer = %PhrasesEntries.get_child(index)
	var new_count: int = %PhrasesEntries.get_child_count() - 1
	
	if new_count <= 0:
		new_text_button.focus_next = ^""
	else:
		if index == 0: # It's the first item
			var target_ln: LineEdit = %PhrasesEntries.get_child(1).get_child(1)
			new_text_button.focus_next = target_ln.get_path()
			target_ln.focus_previous = new_text_button.get_path()
		elif new_count == index: # It's the last item
			var target_btn: Button = %PhrasesEntries.get_child(-2).get_child(3)
			target_btn.focus_next = ^""
		else: # It's between 2 items
			var button_up: Button = %PhrasesEntries.get_child(index - 1).get_child(3)
			var line_down: LineEdit = %PhrasesEntries.get_child(index + 1).get_child(1)
			button_up.focus_next = line_down.get_path()
			line_down.focus_previous = button_up.get_path()
	
	entry.queue_free()


func clear_cases() -> void:
	for case_idx in range(%PhraseCasesEntries.get_child_count() - 1, 0, -1):
		%PhraseCasesEntries.get_child(case_idx).queue_free()


func clear_localized_keys() -> void:
	for entry in %PhrasesEntries.get_children():
		entry.queue_free()


func save_current_phrase_key(locale_code: String, format: String) -> void:
	if selected_phrase_index < 0:
		return
	
	var phrase_key: String = %PhrasesEntries.get_child(selected_phrase_index).get_meta(&"phrase_key")
	
	active_conversation.set_format_string_default_case(
		phrase_key,
		locale_code,
		format,
		default_case_edt.text.strip_edges())
	
	var desired: String = ""
	var used_keys: Dictionary[String, Variant] = {}
	
	active_conversation.clear_format_string_cases(
		phrase_key,
		locale_code,
		format)
	
	# Fixing the cases:
	for case_idx in range(1, %PhraseCasesEntries.get_child_count()):
		var case_container: HBoxContainer = %PhraseCasesEntries.get_child(case_idx)
		if case_container.is_queued_for_deletion():
			continue
		var desired_key: String = case_container.get_child(1).text.strip_edges()
		var case_key: LineEdit = case_container.get_child(1)
		case_key.text = case_key.text.strip_edges()
		var trailing_int: Dictionary = StringUtils.get_trailing_integer(desired_key)
		var iteration: int = trailing_int["integer"]
		var modified: String = desired_key
		if trailing_int["has_integer"]:
			desired_key = desired_key.trim_suffix(str(iteration))
		
		while used_keys.has(modified):
			iteration += 1
			modified = desired_key + str(iteration)
		
		case_container.get_child(1).text = modified
		
		active_conversation.set_format_string_case(
			phrase_key,
			locale_code,
			format,
			modified,
			case_container.get_child(2).text)
	
	_validate_phrase_cases()


func save_phrase_keys(locale: String) -> void:
	if locale.is_empty():
		return
	
	var claimed_keys: Dictionary[String, Variant] = {}
	
	for entry in %PhrasesEntries.get_children():
		if entry.is_queued_for_deletion():
			continue
		
		var desired_key: String = entry.get_child(1).text.strip_edges()
		
		if desired_key.is_empty():
			desired_key = "PHRASE"
		
		var trailing_int: Dictionary = StringUtils.get_trailing_integer(desired_key)
		var current_loop: int = trailing_int["integer"]
		var modified: String = desired_key
		
		if trailing_int["has_integer"]:
			desired_key = desired_key.trim_suffix(str(current_loop))
		
		while claimed_keys.has(modified):
			current_loop += 1
			modified = desired_key + str(current_loop)
		
		var old_key: String = entry.get_meta(&"phrase_key")
		var new_key: String = modified
		claimed_keys[new_key] = null
		
		if entry.get_meta(&"unsaved"):
			entry.set_meta(&"unsaved", false)
		elif new_key != old_key:
			active_conversation.format_strings[new_key] = active_conversation.format_strings[old_key]
			active_conversation.format_strings.erase(old_key)
		
		entry.set_meta(&"phrase_key", new_key)
		entry.get_child(1).text = modified
		
		active_conversation.set_format_string(
			new_key,
			entry.get_child(2).text,
			locale)
	
	# Remove keys no longer used
	for existing_key in active_conversation.format_strings.keys():
		if claimed_keys.has(existing_key):
			continue
		active_conversation.format_strings.erase(existing_key)
	
	# Saving this last because keys could shift above OR new keys could be
	# assigned.
	if -1 < argument_opt_btn.selected:
		save_current_phrase_key(locale, argument_opt_btn.get_item_text(argument_opt_btn.selected))


func set_phrase_format_string(phrase_key: String, locale: String, format_string: String) -> void:
	active_conversation.set_format_string(phrase_key, format_string, locale)
	
	# Returns ["!a", "$b"] from "{!a} is {$b}". If the second argument is false it would return ["{!a}", "{$b}"]
	var entries: Array[String] = EditorDiscourseDialog.get_phrase_arguments(format_string, true)
	var existing_cases: Dictionary[String, Variant] = {}
	
	# Method returns an array of existing keys e.g. "!c"
	for case in active_conversation.get_format_string_formats(phrase_key, locale):
		if entries.has(case):
			existing_cases[case] = null
		else:
			active_conversation.erase_format_string_format(
				phrase_key,
				locale,
				case)
	
	for new_case in entries:
		# This ensures that the new case exists and its structured properly
		active_conversation.validate_format_string_format(phrase_key, locale, new_case)


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
			NFPluginGameHandler._log_msg(
				"discourse - editor",
				"Couldn't open file '%s'." % file_path,
				NFPluginGameHandler._LogLevel.ERROR)
			return
		conversation_tree.select_conversation.call_deferred(file)
		add_to_recently_opened_files(file_path)
	else:
		NFPluginGameHandler._log_msg(
			"discourse - editor",
			"File '%s' not found. Removing from menu." % file_path,
			NFPluginGameHandler._LogLevel.INFO)
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
	var id: int = resource.get_instance_id()
	if not _open_files.has(id):
		return
	close_dialog_resource(id)


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
	
	if DiscourseGraphNode.api_path.is_empty() or not FileAccess.file_exists(DiscourseGraphNode.api_path):
		if not DiscourseGraphNode.validate_api_path():
			NFPluginGameHandler._log_msg(
				"discourse - editor",
				"Discourse API script not found",
				NFPluginGameHandler._LogLevel.ERROR)
			return methods
	
	var api_script: Script = load(DiscourseGraphNode.api_path)
	
	for method:Dictionary in api_script.get_script_method_list():
		if method["return"]["type"] == TYPE_NIL:
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


func display_format_key_formats(key: String, format: String, locale: String) -> void:
	clear_cases()
	var default: String = active_conversation.get_format_string_default_case(key, locale, format)
	default_case_edt.text = default
	default_case_edt.set_meta(&"old_value", default)
	for case in active_conversation.get_format_string_cases(key, locale, format):
		var case_text: String = active_conversation.get_format_string_case(key, locale, format, case)
		create_new_phrase_case(case, case_text)


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
	
	var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	
	if active_node == null:
		return
	elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG or active_node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
		dialog_previewer.set_dialog(translation_txt_box.text)
	elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.CHOICES:
		dialog_previewer.set_choices(
			get_localizer_choices())


func _on_collapse_previewer_pressed() -> void:
	dialog_scene_previewer.visible = false
	$LocalizationContainer/FooterContainer/UncollapsePreviewBtn.visible = true


func _on_text_changed_sync(text: String) -> void:
	if dialog_previewer == null or not dialog_scene_previewer.visible or not auto_update_previewer.button_pressed:
		return
	dialog_previewer.set_dialog(text)


func _on_choice_text_changed(text: String, control: Control) -> void:
	_on_conversation_changed()
	update_dialog_preview_choice(control.get_index(), text)


func update_dialog_preview_choice(index: int, text: String) -> void:
	if dialog_previewer == null or not dialog_scene_previewer.visible or not auto_update_previewer.button_pressed:
		return
	dialog_previewer.update_choice(index, text)


func _on_play_live_preview_pressed() -> void:
	if dialog_previewer == null or not dialog_scene_previewer.visible:
		return
	
	var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	
	if active_node == null:
		return
	elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG or active_node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
		dialog_previewer.play_dialog(translation_txt_box.text)
	elif active_node.node_type == DiscourseGraphNode.DialogueNodeType.CHOICES:
		dialog_previewer.play_choices(
			get_localizer_choices())


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


func _on_default_case_focus_pressed() -> void:
	_on_open_phrase_case_text_editor_pressed(default_case_edt)


func _is_preview_scene_valid(print_errors: bool = true) -> bool:
	var path: String = ProjectSettings.get_setting(NFPluginGameHandler.get_setting_path("discourse_localization_preview_scene"), "")
	
	if path.is_empty():
		return false
	
	if not FileAccess.file_exists(path):
		if print_errors:
			NFPluginGameHandler._log_msg(
				"discourse - editor",
				"Localization preview scene '%s' was not found" % path,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	var scene = load(path)
	if scene == null or not scene is PackedScene or not scene.can_instantiate():
		if print_errors:
			NFPluginGameHandler._log_msg(
				"discourse - editor",
				"Error during instantiation of scene '%s'" % path,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	var instance: Node = scene.instantiate()
	
	if instance == null and print_errors:
		NFPluginGameHandler._log_msg(
			"discourse - editor",
			"Scene '%s' couldn't be instantiated" % path,
			NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	var scene_script: Script = instance.get_script()
	if scene_script == null:
		if print_errors:
			NFPluginGameHandler._log_msg(
				"discourse - editor",
				"Scene '%s' has no script attatched" % path,
				NFPluginGameHandler._LogLevel.ERROR)
		instance.free()
		return false
	
	var errors: Array[String] = []
	var static_methods: Array[Dictionary] = scene_script.get_script_method_list()
	var has_c_updt: bool = false
	var has_set_d: bool = false
	var has_set_c: bool = false
	var has_p_txt: bool = false
	var has_p_ch: bool = false
	
	for method in static_methods:
		if method["name"] == "set_choices":
			if method["args"].is_empty():
				continue
			var arg: Dictionary = method["args"][0]
			var extra_valid: bool = true
			
			if 1 < method["args"].size():
				var default_size: int = method["default_args"].size()
				extra_valid = method["args"].size() - 1 <= default_size
			
			if arg["type"] == TYPE_NIL:
				has_set_c = extra_valid
			elif arg["type"] == TYPE_ARRAY:
				has_set_c = extra_valid and ( arg["hint_string"].is_empty() or arg["hint_string"] == "String" )
		elif method["name"] == "set_dialog":
			if method["args"].is_empty():
				continue
			var arg: Dictionary = method["args"][0]
			var extra_valid: bool = true
			
			if 1 < method["args"].size():
				var default_size: int = method["default_args"].size()
				extra_valid = method["args"].size() - 1 <= default_size
			
			has_set_d = extra_valid and ( arg["type"] == TYPE_NIL or arg["type"] == TYPE_STRING )
		elif method["name"] == "update_choice":
			if method["args"].size() < 2:
				continue
			var idx_arg: Dictionary = method["args"][0]
			var txt_arg: Dictionary = method["args"][1]
			var extra_valid: bool = true
			
			if 1 < method["args"].size():
				var default_size: int = method["default_args"].size()
				extra_valid = method["args"].size() - 2 <= default_size
			
			if (idx_arg["type"] == TYPE_INT or idx_arg["type"] == TYPE_NIL or idx_arg["type"] == TYPE_FLOAT) and (txt_arg["type"] == TYPE_STRING or txt_arg["type"] == TYPE_NIL):
				has_c_updt = extra_valid
		elif method["name"] == "play_dialog":
			if method["args"].is_empty():
				continue
			var arg: Dictionary = method["args"][0]
			var extra_valid: bool = true
			
			if 1 < method["args"].size():
				var default_size: int = method["default_args"].size()
				extra_valid = method["args"].size() - 1 <= default_size
			
			has_p_txt = extra_valid and ( arg["type"] == TYPE_STRING or arg["type"] == TYPE_NIL )
		elif method["name"] == "play_choices":
			if method["args"].is_empty():
				continue
			var arg: Dictionary = method["args"][0]
			var extra_valid: bool = true
			
			if 1 < method["args"].size():
				var default_size: int = method["default_args"].size()
				extra_valid = method["args"].size() - 1 <= default_size
			
			if arg["type"] == TYPE_NIL:
				has_p_ch = extra_valid
			elif arg["type"] == TYPE_ARRAY:
				has_p_ch = extra_valid and ( arg["hint_string"].is_empty() or arg["hint_string"] == "String" )
		
		if has_set_c and has_set_d and has_c_updt and has_p_txt and has_p_ch:
			break
	
	if not has_c_updt:
		errors.append("Scene has no valid 'update_choice' method.")
	if not has_set_d:
		errors.append("Scene has no valid 'set_dialog' method.")
	if not has_set_c:
		errors.append("Scene has no valid 'set_choices' method.")
	if not has_p_txt:
		errors.append("Scene has no valid 'play_dialog' method.")
	if not has_p_ch:
		errors.append("Scene has no valid 'play_choices' method.")
	
	if not errors.is_empty() and print_errors:
		NFPluginGameHandler._log_msg(
			"discourse - editor",
			"Scene '%s' errored: %s" % [path, ", ".join(errors)],
			NFPluginGameHandler._LogLevel.ERROR)
	
	instance.free()
	return has_c_updt and has_set_c and has_set_d and has_p_txt and has_p_ch


func _update_choice_textbox_size(box: TextEdit) -> void:
	if box.size.x <= 0 or not box.is_visible_in_tree():
		return
	
	box.scroll_fit_content_height = true
	var total_visual_lines: int = 0
	for i in range(box.get_line_count()):
		total_visual_lines += 1 + box.get_line_wrap_count(i)
	if total_visual_lines <= MAX_LINES:
		box.custom_minimum_size.y = 0
		box.queue_redraw.call_deferred()
		return
	box.scroll_fit_content_height = false
	
	var new_height: float = MAX_LINES * box.get_line_height() + EXTRA_Y_PADDING
	if new_height != box.custom_minimum_size.y:
		box.custom_minimum_size.y = new_height
		box.queue_redraw.call_deferred()


func _on_phrase_text_field_changed(field: TextEdit) -> void:
	_update_choice_textbox_size(field)
	_on_conversation_changed()


func _on_argument_button_item_selected(idx: int) -> void:
	var current_key: String = %PhrasesEntries.get_child(selected_phrase_index).get_meta(&"phrase_key")
	var new_format: String = argument_opt_btn.get_item_text(idx)
	var locale: String = phrases_lang_menu.get_selected_metadata()
	
	if not selected_phrase_format.is_empty():
		save_current_phrase_key(
			locale,
			selected_phrase_format)
	
	display_format_key_formats(current_key, new_format, locale)
	selected_phrase_format = argument_opt_btn.get_item_text(idx)

# --- UndoRedo ---
# --- Phrases ---

func _on_phrase_key_editing_toggled(is_toggled: bool, line: LineEdit) -> void:
	if is_toggled:
		return
	
	var current_text: String = line.text
	
	if current_text.is_empty():
		current_text = "PHRASE"
	
	var new_value: String = get_valid_format_key_id(current_text, line)
	var old_value: String = line.get_parent().get_meta(&"phrase_key")
	
	if new_value == old_value:
		return
	
	undo.create_action("Set Phrase Key")
	undo.add_do_method(_rename_phrase_key_action.bind(old_value, new_value))
	undo.add_undo_method(_rename_phrase_key_action.bind(new_value, old_value))
	undo.commit_action()
	_on_conversation_changed()


func _rename_phrase_key_action(from_key: String, to_key: String) -> void:
	if active_conversation.format_strings.has(from_key):
		active_conversation.format_strings[to_key] = active_conversation.format_strings[from_key]
		active_conversation.format_strings.erase(from_key)
	
	for item in %PhrasesEntries.get_children():
		if item.get_meta(&"phrase_key") == from_key:
			item.get_child(1).text = to_key
			item.set_meta(&"phrase_key", to_key)
			break


func get_valid_format_key_id(desired: String, skip: LineEdit = null) -> String:
	var all_ids: Dictionary[String, Variant] = {}
	
	for entry in %PhrasesEntries.get_children():
		var entry_line: LineEdit = entry.get_child(1)
		
		if entry_line == skip:
			continue
		
		all_ids[entry_line.text] = null
	
	var current_id: String = desired
	
	if all_ids.has(desired):
		var base: String = desired
		var modified: String = desired
		var trailing_data: Dictionary = StringUtils.get_trailing_integer(desired)
		var iteration: int = trailing_data["integer"]
		if trailing_data["has_integer"]:
			base = desired.trim_suffix(str(iteration))
		while all_ids.has(modified):
			iteration += 1
			modified = base + str(iteration)
		current_id = modified
	return current_id


func _on_phrase_text_editing_focus_lost(field: TextEdit) -> void:
	var old_text: String = field.get_meta(&"old_value")
	var new_text: String = field.text
	var phrase_id: String = field.get_parent().get_meta(&"phrase_key")
	
	if new_text == old_text:
		return
	
	field.set_meta(&"old_value", new_text)
	var locale_code: String = phrases_lang_menu.get_selected_metadata()
	
	var old_state: Dictionary = {}
	if DictUtils.has_nested_path(active_conversation.format_strings, [phrase_id, locale_code]):
		old_state = active_conversation.format_strings[phrase_id][locale_code].duplicate(true)
	
	set_phrase_format_string(phrase_id, locale_code, new_text)
	
	var new_state: Dictionary = active_conversation.format_strings[phrase_id][locale_code].duplicate(true)
	
	undo.create_action("Set Phrase Text (%s)" % locale_code)
	undo.add_do_method(_set_phrase_state_action.bind(phrase_id, locale_code, new_state))
	undo.add_undo_method(_set_phrase_state_action.bind(phrase_id, locale_code, old_state))
	undo.commit_action(false)


func _set_phrase_state_action(phrase_key: String, locale: String, state_dict: Dictionary) -> void:
	var base_string: String = state_dict.get("base_string", "")
	if not active_conversation.format_strings.has(phrase_key):
		active_conversation.set_format_string(
			phrase_key,
			base_string,
			locale)
	
	active_conversation.format_strings[phrase_key][locale] = state_dict.duplicate(true)
	
	for item in %PhrasesEntries.get_children():
		if item.get_meta(&"phrase_key") == phrase_key:
			var text_field: TextEdit = item.get_child(2)
			if text_field.text != base_string:
				text_field.text = base_string
				text_field.set_meta(&"old_value", base_string)
			break
	
	if -1 < selected_phrase_index: # This means we're editing a phrase
		var key_control: Control = %PhrasesEntries.get_child(selected_phrase_index)
		var editing_key: String = key_control.get_meta(&"phrase_key")
		
		if editing_key == phrase_key and -1 < phrases_lang_menu.selected and phrases_lang_menu.get_selected_metadata() == locale:
			_refresh_cases_screen()

	_on_conversation_changed()


func _refresh_cases_screen() -> void:
	if selected_phrase_index < 0 or phrases_lang_menu.selected < 0:
		return
	
	var key_control: Control = %PhrasesEntries.get_child(selected_phrase_index)
	var editing_key: String = key_control.get_meta(&"phrase_key")
	var locale: String = phrases_lang_menu.get_selected_metadata()
	var selected_format: String = "" if argument_opt_btn.selected < 0 else argument_opt_btn.get_item_text(argument_opt_btn.selected)
	var existing_cases: Array[String] = active_conversation.get_format_string_formats(editing_key, locale)
	var new_idx: int = existing_cases.find(selected_format)
	
	argument_opt_btn.clear()
	
	for case in existing_cases:
		argument_opt_btn.add_item(case)
	
	if new_idx != -1:
		argument_opt_btn.select(new_idx)
		display_format_key_formats(
			editing_key,
			selected_format,
			locale)
	else:
		if argument_opt_btn.item_count == 0: # Exit the editor
			case_box_container.visible = false
			key_box_container.visible = true
			phrases_lang_menu.disabled = false
			
			clear_cases()
			default_case_edt.clear()
			default_case_edt.set_meta(&"old_value", "")
			search_case_ln_edt.text = ""
			search_case_ln_edt.set_meta(&"current_search", "")
		else:
			display_format_key_formats(
				editing_key,
				argument_opt_btn.get_item_text(0),
				locale)
			selected_phrase_format = argument_opt_btn.get_item_text(0)


func _on_phrase_case_editing_toggled(is_toggled: bool, case_line: LineEdit) -> void:
	if is_toggled:
		return
	
	var old_case: String = case_line.get_meta(&"old_value")
	var new_case: String = case_line.text
	
	if new_case == old_case:
		return
	
	var key: String = %PhrasesEntries.get_child(selected_phrase_index).get_meta(&"phrase_key")
	var locale: String = phrases_lang_menu.get_selected_metadata()
	var format: String = argument_opt_btn.get_item_text(argument_opt_btn.selected)
	
	undo.create_action("Set Phrase Case")
	undo.add_do_method(_do_update_phrase_case_key.bind(key, locale, format, old_case, new_case))
	undo.add_undo_method(_do_update_phrase_case_key.bind(key, locale, format, new_case, old_case))
	undo.commit_action()


func _do_update_phrase_case_key(phrase_key: String, locale: String, format: String, from_case: String, to_case: String) -> void:
	var case_value: String = active_conversation.get_format_string_case(phrase_key, locale, format, from_case)
	active_conversation.set_format_string_case(phrase_key, locale, format, to_case, case_value)
	active_conversation.erase_format_string_case(phrase_key, locale, format, from_case)
	
	var is_viewing_cases: bool = -1 < selected_phrase_index # When an edit cases is pressed, the index is assigned, when cases are saved it returns to -1
	var current_phrase: String = "" if selected_phrase_index < 0 else %PhrasesEntries.get_child(selected_phrase_index).get_meta(&"phrase_key")
	var is_correct_phrase: bool = current_phrase == phrase_key
	var current_locale_code: String = "" if phrases_lang_menu.selected < 0 else phrases_lang_menu.get_selected_metadata()
	var is_correct_locale: bool = current_locale_code == locale
	var current_format: String = "" if argument_opt_btn.selected < 0 else argument_opt_btn.get_item_text(argument_opt_btn.selected)
	var is_correct_format: bool = current_format == format
	
	if is_viewing_cases and is_correct_phrase and is_correct_locale and is_correct_format:
		for container_idx in range(1, %PhraseCasesEntries.get_child_count()):
			var container: Control = %PhraseCasesEntries.get_child(container_idx)
			var case_line: LineEdit = container.get_child(1)
			if case_line.get_meta(&"old_value", "") == from_case:
				case_line.text = to_case
				case_line.set_meta(&"old_value", to_case)
				break


func _on_phrase_case_result_focus_exited(result_control: TextEdit) -> void:
	var is_default: bool = result_control == default_case_edt
	
	var old_value: String = result_control.get_meta(&"old_value")
	var new_value: String = result_control.text
	
	if new_value == old_value:
		return
	
	var phrase: String = %PhrasesEntries.get_child(selected_phrase_index).get_meta(&"phrase_key")
	var locale: String = phrases_lang_menu.get_selected_metadata()
	var format: String = argument_opt_btn.get_item_text(argument_opt_btn.selected)
	var case_key: String = ""
	
	if not is_default:
		var case_line: LineEdit = result_control.get_parent().get_child(1)
		case_key = case_line.get_meta(&"old_value")
	
	var action_name: String = "Edit Default Case" if is_default else "Edit Case Result"
	
	undo.create_action(action_name)
	undo.add_do_method(_set_phrase_case_result_action.bind(phrase, locale, format, is_default, case_key, new_value))
	undo.add_undo_method(_set_phrase_case_result_action.bind(phrase, locale, format, is_default, case_key, old_value))
	undo.commit_action()


func _set_phrase_case_result_action(phrase_key: String, locale: String, format: String, is_default: bool, case_key: String, text_value: String) -> void:
	if is_default:
		active_conversation.set_format_string_default_case(phrase_key, locale, format, text_value)
	else:
		active_conversation.set_format_string_case(phrase_key, locale, format, case_key, text_value)
	
	var is_viewing_cases: bool = -1 < selected_phrase_index
	var current_phrase: String = "" if selected_phrase_index < 0 else %PhrasesEntries.get_child(selected_phrase_index).get_meta(&"phrase_key")
	var is_correct_phrase: bool = current_phrase == phrase_key
	var current_locale_code: String = "" if phrases_lang_menu.selected < 0 else phrases_lang_menu.get_selected_metadata()
	var is_correct_locale: bool = current_locale_code == locale
	var current_format: String = "" if argument_opt_btn.selected < 0 else argument_opt_btn.get_item_text(argument_opt_btn.selected)
	var is_correct_format: bool = current_format == format

	if is_viewing_cases and is_correct_phrase and is_correct_locale and is_correct_format:
		if is_default:
			default_case_edt.text = text_value
			default_case_edt.set_meta(&"old_value", text_value)
		else:
			for child_idx in range(1, %PhraseCasesEntries.get_child_count()):
				var container: Control = %PhraseCasesEntries.get_child(child_idx)
				var case_line: LineEdit = container.get_child(1)
				if case_line.get_meta(&"old_value", "") == case_key:
					var case_editor: TextEdit = container.get_child(2)
					case_editor.text = text_value
					case_editor.set_meta(&"old_value", text_value)
					break

# --- Localization ---

func _on_localization_text_edit_focus_exited() -> void:
	var old_value: String = translation_txt_box.get_meta(&"old_value")
	var new_value: String = translation_txt_box.text
	
	if new_value == old_value:
		return
	
	var current_node_uuid: StringName = localization_nodes_tree.get_active_node_uuid()
	var locale_code: String = languages_tree.get_active_locale()
	
	undo.create_action("Set Localized Text (%s)" % locale_code)
	undo.add_do_method(_do_update_dialog_node_text.bind(current_node_uuid, new_value, locale_code))
	undo.add_undo_method(_do_update_dialog_node_text.bind(current_node_uuid, old_value, locale_code))
	undo.commit_action()


func _on_localization_choice_focus_exited(field: TextEdit) -> void:
	var old_value: String = field.get_meta(&"old_value")
	var new_value: String = field.text
	
	if new_value == old_value:
		return
	
	var current_node_uuid: StringName = localization_nodes_tree.get_active_node_uuid()
	var locale_code: String = languages_tree.get_active_locale()
	var current_index: int = field.get_parent().get_index()
	
	undo.create_action("Set Localized Choice Text (%s)" % locale_code)
	undo.add_do_method(_do_update_choice_node_text.bind(current_node_uuid, current_index + 1, new_value, locale_code))
	undo.add_undo_method(_do_update_choice_node_text.bind(current_node_uuid, current_index + 1, old_value, locale_code))
	undo.commit_action()

# --- Node Structure ---

func _on_discourse_item_renamed(uuid: StringName, old_name: String, new_name: String) -> void:
	var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(uuid)
	node.set_node_id(new_name)
	if node.is_node_localized():
		match node.node_type:
			DiscourseGraphNode.DialogueNodeType.DIALOG:
				localization_nodes_tree.rename_dialog_node(uuid, new_name)
			DiscourseGraphNode.DialogueNodeType.CHOICES:
				localization_nodes_tree.rename_options_node(uuid, new_name)
			DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				localization_nodes_tree.rename_text_node(uuid, new_name)
	
	undo.create_action("Set Node ID")
	undo.add_do_method(_do_set_node_id.bind(uuid, new_name))
	undo.add_undo_method(_do_set_node_id.bind(uuid, old_name))
	undo.commit_action(false)
	
	_on_conversation_changed()


func _do_set_node_id(uuid: StringName, id: String) -> void:
	discourse_nodes_tree.set_node_id(uuid, id)
	if not discourse_graph_edit.has_discourse_node(uuid):
		return
	
	var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(uuid)
	node.set_node_id(id)
	if node.is_node_localized():
		match node.node_type:
			DiscourseGraphNode.DialogueNodeType.DIALOG:
				localization_nodes_tree.rename_dialog_node(uuid, id)
			DiscourseGraphNode.DialogueNodeType.CHOICES:
				localization_nodes_tree.rename_options_node(uuid, id)
			DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				localization_nodes_tree.rename_text_node(uuid, id)


func _on_discourse_folder_renamed(folder_id: int, old_name: String, new_name: String) -> void:
	undo.create_action("Set Folder Name")
	undo.add_do_method(conversation_tree.set_folder_name.bind(folder_id, new_name))
	undo.add_undo_method(conversation_tree.set_folder_name.bind(folder_id, old_name))
	undo.commit_action(false)
	
	_on_conversation_changed()


func _on_discourse_item_moved(from_path: String, from_index: int, to_path: String, to_index: int) -> void:
	undo.create_action("Move Discourse Item")
	undo.add_do_method(discourse_nodes_tree.move_item.bind(from_path, to_path, to_index))
	undo.add_undo_method(discourse_nodes_tree.move_item.bind(to_path, from_path, from_index))
	undo.commit_action(false)
	
	_on_conversation_changed()


func _on_discourse_directory_removed(path: String, index: int, id: int, contents: Array[Dictionary]) -> void:
	undo.create_action("Remove Folder")
	undo.add_do_method(discourse_nodes_tree.remove_folder.bind(path))
	undo.add_undo_method(discourse_nodes_tree.restore_folder.bind(path, id, index, contents))
	undo.commit_action(false)
	_on_conversation_changed()

# --- GraphEdit Operations ---

func _on_node_resized(node_uuid: StringName, from: Vector2, to: Vector2) -> void:
	undo.create_action("Resize Node")
	undo.add_do_method(discourse_graph_edit.resize_node.bind(node_uuid, to))
	undo.add_undo_method(discourse_graph_edit.resize_node.bind(node_uuid, from))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_comment_node_text_changed(node_uuid: StringName, old_comment: String, new_comment: String) -> void:
	undo.create_action("Set Comment Node Text")
	undo.add_do_method(discourse_graph_edit.set_comment_node_text.bind(node_uuid, new_comment))
	undo.add_undo_method(discourse_graph_edit.set_comment_node_text.bind(node_uuid, old_comment))
	undo.commit_action(false)


func _on_comparation_node_operator_changed(node_uuid: StringName, old_operator: int, new_operator: int) -> void:
	undo.create_action("Set Comparator Node Operator")
	undo.add_do_method(discourse_graph_edit.set_comparation_node_operator.bind(node_uuid, new_operator))
	undo.add_undo_method(discourse_graph_edit.set_comparation_node_operator.bind(node_uuid, old_operator))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_dialog_node_character_id_changed(node_uuid: StringName, from: String, to: String) -> void:
	undo.create_action("Set Dialog Node Character")
	undo.add_do_method(discourse_graph_edit.set_dialog_node_character_id.bind(node_uuid, to))
	undo.add_undo_method(discourse_graph_edit.set_dialog_node_character_id.bind(node_uuid, from))
	undo.commit_action(false)


func _on_dialog_node_text_changed(node_uuid: StringName, from: String, to: String) -> void:
	if localization_nodes_tree.get_active_node_uuid() == node_uuid and languages_tree.get_active_locale() == current_locale:
		translation_txt_box.text = to
		translation_txt_box.set_meta(&"old_value", to)
		dialog_previewer.set_dialog(to)
	undo.create_action("Set Dialog Node Dialog")
	undo.add_do_method(_do_update_dialog_node_text.bind(node_uuid, to, current_locale))
	undo.add_undo_method(_do_update_dialog_node_text.bind(node_uuid, from, current_locale))
	undo.commit_action(false)


func _do_update_dialog_node_text(node_uuid: StringName, to: String, locale: String) -> void:
	active_conversation.set_dialog_text(node_uuid, to, locale)
	if current_locale == locale:
		discourse_graph_edit.set_dialog_node_dialog_text(node_uuid, to)
	if localization_nodes_tree.get_active_node_uuid() == node_uuid and languages_tree.get_active_locale() == locale:
		translation_txt_box.text = to
		translation_txt_box.set_meta(&"old_value", to)
		dialog_previewer.set_dialog(to)


func _on_dialog_node_presist_toggled(node_uuid: StringName, is_toggled: bool) -> void:
	undo.create_action("Toggle Dialog Node Persist")
	undo.add_do_method(discourse_graph_edit.set_dialog_node_persist_enabled.bind(node_uuid, is_toggled))
	undo.add_undo_method(discourse_graph_edit.set_dialog_node_persist_enabled.bind(node_uuid, not is_toggled))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_choice_node_text_changed(node_uuid: StringName, choice_idx: int, old_text: String, new_text: String) -> void:
	if localization_nodes_tree.get_active_node_uuid() == node_uuid and languages_tree.get_active_locale() == current_locale:
		update_dialog_preview_choice(choice_idx - 1, new_text)
	undo.create_action("Set Choice Node Text")
	undo.add_do_method(_do_update_choice_node_text.bind(node_uuid, choice_idx, new_text, current_locale))
	undo.add_undo_method(_do_update_choice_node_text.bind(node_uuid, choice_idx, old_text, current_locale))
	undo.commit_action(false)


func _do_update_choice_node_text(node_uuid: StringName, choice_id: int, to: String, locale: String) -> void:
	active_conversation.set_choice_text(node_uuid, choice_id, to, locale)
	if current_locale == locale:
		discourse_graph_edit.set_choice_node_text(node_uuid, choice_id, to)
	if localization_nodes_tree.get_active_node_uuid() == node_uuid and languages_tree.get_active_locale() == locale:
		set_localized_choice_line_text(choice_id - 1, to)
		update_dialog_preview_choice(choice_id - 1, to)


func _on_choices_node_resized(node_uuid: StringName, old_snapshot: Dictionary, new_snapshot: Dictionary) -> void:
	var loc_snapshot: Dictionary = {}
	if active_conversation.localization.has(node_uuid):
		loc_snapshot = active_conversation.localization[node_uuid].duplicate(true)
	if localization_nodes_tree.get_active_node_uuid() == node_uuid:
		_set_localization_window_choices(discourse_graph_edit.get_discourse_node(node_uuid))
		dialog_previewer.set_choices(
				get_localizer_choices())
	
	undo.create_action("Set Choice Node Choice Count")
	undo.add_do_method(_set_choices_resize_action.bind(node_uuid, new_snapshot, loc_snapshot, current_locale))
	undo.add_undo_method(_set_choices_resize_action.bind(node_uuid, old_snapshot, loc_snapshot, current_locale))
	undo.commit_action(false)
	_on_conversation_changed()


func _set_choices_resize_action(node_uuid: StringName, node_snapshot: Dictionary, loc_snapshot: Dictionary, locale: String) -> void:
	discourse_graph_edit.set_choices_node_state(node_uuid, node_snapshot)
	
	if not loc_snapshot.is_empty():
		active_conversation.localization[node_uuid] = loc_snapshot.duplicate(true)
	
	var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(node_uuid)
	if node == null:
		return
	
	# Because we don't know the locale data was saved at or if it is even 
	# localized, we update all the choices.
	var node_options: int = node.choice_count()
	var choice_text: Array[String] = []
	var choice_arr_size: int = 0
	
	if locale != current_locale:
		if node.is_node_localized():
			if loc_snapshot.has("locales") and loc_snapshot["locales"].has(current_locale):
				choice_text.assign(loc_snapshot["locales"][current_locale])
		else:
			if loc_snapshot.has("unlocalized"):
				choice_text.assign(loc_snapshot["unlocalized"])
		
		choice_arr_size = choice_text.size()
		
		if choice_arr_size < node_options:
			choice_text.resize(node_options)
			choice_arr_size = node_options
		
		for idx in range(mini(choice_arr_size, node_options)):
			node.set_choice_text(idx + 1, choice_text[idx])
	
	if localization_nodes_tree.get_active_node_uuid() == node_uuid:
		_set_localization_window_choices(node)
		dialog_previewer.set_choices(
				get_localizer_choices())
	
	_on_conversation_changed()


func _set_localization_window_choices(new_node: DiscourseGraphNode) -> void:
	var new_node_uuid: StringName = new_node.get_node_uuid()
	var active_locale: String = languages_tree.get_active_locale()
	
	var options_localized: Array[String] = []
	var options_base: Array[String] = []
	
	options_localized.assign(DictUtils.get_nested_value(
		active_conversation.localization,
		[new_node_uuid, "locales", active_locale],
		[],
		true))
		
	options_base.assign(DictUtils.get_nested_value(
		active_conversation.localization,
		[new_node_uuid, "locales", base_language],
		[],
		true))
		
	var choice_count: int = new_node.choice_count()
	clear_localized_options()
	
	var base_size: int = options_base.size()
	if base_size != choice_count:
		options_base.resize(choice_count)
	var localized_size: int = options_localized.size()
	if localized_size < choice_count:
		options_localized.append_array(options_base.slice(localized_size))
	
	for option_idx in range(options_base.size()):
		create_choice_node(
			options_base[option_idx],
			options_localized[option_idx])
	
	if dialog_previewer != null and dialog_scene_previewer.visible:
		dialog_previewer.set_choices(options_localized)


func _do_set_choice_node_state(node_uuid: StringName, to: Dictionary, locale: String) -> void:
	var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(node_uuid)
	if node == null:
		return
	
	var localized_data: Dictionary = active_conversation.get_node_data(node_uuid)
	discourse_graph_edit.set_chocies_node_state(node_uuid, to)
	node._set_node_data(localized_data)


func _on_shortcut_node_target_changed(node_uuid: StringName, old_anchor: StringName, new_anchor: StringName) -> void:
	undo.create_action("Set Shortcut Node Target")
	undo.add_do_method(discourse_graph_edit.set_shortcut_node_target.bind(node_uuid, new_anchor))
	undo.add_undo_method(discourse_graph_edit.set_shortcut_node_target.bind(node_uuid, old_anchor))
	undo.commit_action(false)
	_on_conversation_changed()


func shortcut_node_id_changed(node_uuid: String, old_id: String, new_id: String) -> void:
	undo.create_action("Set Shortcut Target Node ID")
	undo.add_do_method(discourse_graph_edit.set_shortcut_target_id.bind(node_uuid, new_id))
	undo.add_undo_method(discourse_graph_edit.set_shortcut_target_id.bind(node_uuid, old_id))
	undo.commit_action(false)


func _on_localized_node_text_changed(node_uuid: StringName, old_value: String, new_value: String) -> void:
	undo.create_action("Set Localized Node Text")
	undo.add_do_method(_do_update_localized_node_text.bind(node_uuid, new_value, current_locale))
	undo.add_undo_method(_do_update_localized_node_text.bind(node_uuid, old_value, current_locale))
	undo.commit_action(false)


func _do_update_localized_node_text(node_uuid: StringName, to: String, locale: String) -> void:
	active_conversation.set_dialog_text(node_uuid, to, locale)
	if current_locale == locale:
		discourse_graph_edit.set_localized_text_node_text(node_uuid, to)


func _on_match_node_cases_resized(node_uuid: StringName, old_snapshot: Dictionary, new_snapshot: Dictionary) -> void:
	undo.create_action("Set Match Node Case Count")
	undo.add_do_method(discourse_graph_edit.set_match_node_cases.bind(node_uuid, new_snapshot))
	undo.add_undo_method(discourse_graph_edit.set_match_node_cases.bind(node_uuid, old_snapshot))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_match_node_field_updated(node_uuid: StringName, field_id: int, from: Variant, to: Variant) -> void:
	undo.create_action("Set Match Node Case")
	undo.add_do_method(discourse_graph_edit.set_match_node_field.bind(node_uuid, field_id, to))
	undo.add_undo_method(discourse_graph_edit.set_match_node_field.bind(node_uuid, field_id, from))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_match_node_mode_changed(node_uuid: StringName, old_state: Dictionary, new_state: Dictionary) -> void:
	undo.create_action("Set Match Node Type")
	undo.add_do_method(discourse_graph_edit.set_match_node_state.bind(node_uuid, new_state))
	undo.add_undo_method(discourse_graph_edit.set_match_node_state.bind(node_uuid, old_state))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_metadata_node_key_changed(node_uuid: StringName, index: int, from: String, to: String) -> void:
	undo.create_action("Set Metadata Node Key")
	undo.add_do_method(discourse_graph_edit.set_metadata_node_key.bind(node_uuid, index, to))
	undo.add_undo_method(discourse_graph_edit.set_metadata_node_key.bind(node_uuid, index, from))
	undo.commit_action(false)


func _on_call_node_method_changed(node_uuid: StringName, from_state: Dictionary, to_state: Dictionary) -> void:
	undo.create_action("Set Call Node Method")
	undo.add_do_method(discourse_graph_edit.set_call_node_state.bind(node_uuid, to_state))
	undo.add_undo_method(discourse_graph_edit.set_call_node_state.bind(node_uuid, from_state))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_call_return_method_changed(node_uuid: StringName, old_state: Dictionary, new_state: Dictionary) -> void:
	undo.create_action("Set Call (Return) Node Method")
	undo.add_do_method(discourse_graph_edit.set_call_return_node_state.bind(node_uuid, new_state))
	undo.add_undo_method(discourse_graph_edit.set_call_return_node_state.bind(node_uuid, old_state))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_random_node_count_state_changed(node_uuid: StringName, old_state: Dictionary, new_state: Dictionary) -> void:
	undo.create_action("Set Random Exit Count")
	undo.add_do_method(discourse_graph_edit.set_random_path_node_state.bind(node_uuid, new_state))
	undo.add_undo_method(discourse_graph_edit.set_random_path_node_state.bind(node_uuid, old_state))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_random_val_node_mode_changed(node_uuid: StringName, old_state: Dictionary, new_state: Dictionary) -> void:
	undo.create_action("Set Random Value Node Type")
	undo.add_do_method(discourse_graph_edit.set_random_value_state.bind(node_uuid, new_state))
	undo.add_undo_method(discourse_graph_edit.set_random_value_state.bind(node_uuid, old_state))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_random_val_node_range_changed(node_uuid: StringName, from_min: float, from_max: float, to_min: float, to_max: float) -> void:
	undo.create_action("Set Random Value Node Range")
	undo.add_do_method(discourse_graph_edit.set_random_value_node_range.bind(node_uuid, to_min, to_max))
	undo.add_undo_method(discourse_graph_edit.set_random_value_node_range.bind(node_uuid, from_min, from_max))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_resource_node_path_changed(node_uuid: StringName, from: String, to: String) -> void:
	undo.create_action("Set Resource Node Path")
	undo.add_do_method(discourse_graph_edit.set_resource_node_path.bind(node_uuid, to))
	undo.add_undo_method(discourse_graph_edit.set_resource_node_path.bind(node_uuid, from))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_signal_node_signal_changed(node_uuid: StringName, old_state: Dictionary, new_state: Dictionary) -> void:
	undo.create_action("Set Emit Signal Node Signal")
	undo.add_do_method(discourse_graph_edit.set_emit_signal_node_state.bind(node_uuid, new_state))
	undo.add_undo_method(discourse_graph_edit.set_emit_signal_node_state.bind(node_uuid, old_state))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_guard_node_fallback_changed(node_uuid: StringName, from: Variant, to: Variant) -> void:
	undo.create_action("Set Shield Node Fallback")
	undo.add_do_method(discourse_graph_edit.set_shield_node_fallback.bind(node_uuid, to))
	undo.add_undo_method(discourse_graph_edit.set_shield_node_fallback.bind(node_uuid, from))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_value_node_value_changed(node_uuid: StringName, from: Variant, to: Variant) -> void:
	undo.create_action("Set Value Node Value")
	undo.add_do_method(discourse_graph_edit.set_value_node_value.bind(node_uuid, to))
	undo.add_undo_method(discourse_graph_edit.set_value_node_value.bind(node_uuid, from))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_value_node_type_changed(node_uuid: StringName, old_state: Dictionary, new_state: Dictionary) -> void:
	undo.create_action("Set Value Node Type")
	undo.add_do_method(discourse_graph_edit.set_value_node_state.bind(node_uuid, new_state))
	undo.add_undo_method(discourse_graph_edit.set_value_node_state.bind(node_uuid, old_state))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_variable_node_type_changed(node_uuid: StringName, old_state: Dictionary, new_state: Dictionary) -> void:
	undo.create_action("Set Variable Node Type")
	undo.add_do_method(discourse_graph_edit.set_variable_node_state.bind(node_uuid, new_state))
	undo.add_undo_method(discourse_graph_edit.set_variable_node_state.bind(node_uuid, old_state))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_variable_node_path_changed(node_uuid: StringName, from: String, to: String) -> void:
	undo.create_action("Set Variable Node Path")
	undo.add_do_method(discourse_graph_edit.set_variable_node_path.bind(node_uuid, to))
	undo.add_undo_method(discourse_graph_edit.set_variable_node_path.bind(node_uuid, from))
	undo.commit_action(false)
	_on_conversation_changed()

# ----------------------------
# TEST: This thing. I think it SHOULD work, but I don't know
func _on_nodes_removed(action: String, graph_nodes_data: Dictionary[StringName, Dictionary]) -> void:
	var action_data: Dictionary = {
		"graph_nodes_data": graph_nodes_data,
		"resource_node_data": DictUtils.create_typed(
			TYPE_STRING_NAME,
			TYPE_DICTIONARY),
		"resource_localization": DictUtils.create_typed(
			TYPE_STRING_NAME,
			TYPE_DICTIONARY),
		"tree_hierarchy": DictUtils.create_typed(
			TYPE_STRING_NAME,
			TYPE_DICTIONARY),
		"pointer_states": DictUtils.create_typed(
			TYPE_STRING_NAME,
			TYPE_STRING_NAME)}
	
	var requires_anchor_snapshot: bool = false
	
	for node_uuid in graph_nodes_data:
		var type: int = graph_nodes_data[node_uuid]["data"]["type"]
		if type == DiscourseGraphNode.DialogueNodeType.SHORTCUT_TARGET:
			requires_anchor_snapshot = true
		if active_conversation.node_data.has(node_uuid):
			action_data["resource_node_data"][node_uuid] = active_conversation.node_data[node_uuid].duplicate(true)
		if active_conversation.localization.has(node_uuid):
			action_data["resource_localization"][node_uuid] = active_conversation.localization[node_uuid].duplicate(true)
		
		action_data["tree_hierarchy"][node_uuid] = discourse_nodes_tree.get_node_data(node_uuid)
	
	if requires_anchor_snapshot:
		for pointer in discourse_graph_edit.anchor_pointers:
			var pointing_to: StringName = pointer.get_selected_target_uuid()
			if graph_nodes_data.has(pointing_to):
				action_data["pointer_states"][pointer.get_node_uuid()] = pointer.get_selected_target_uuid()
	
	var action_name: String = action.capitalize() + " Node"
	if 1 < graph_nodes_data.size():
		action_name += "s"
	
	undo.create_action(action_name)
	undo.add_do_method(_do_remove_nodes.bind(action_data))
	undo.add_undo_method(_undo_remove_nodes.bind(action_data))
	undo.commit_action()
	_on_conversation_changed()


func _do_remove_nodes(action_data: Dictionary) -> void:
	var uuids_to_remove: Array[StringName] = ArrayUtils.create_typed(
			TYPE_STRING_NAME,
			action_data.keys())
	
	discourse_graph_edit.remove_nodes(uuids_to_remove)
	
	for uuid in action_data["graph_nodes_data"]:
		discourse_graph_edit.remove_node(uuid)
		discourse_nodes_tree.remove_dialog_node(uuid)
		localization_nodes_tree.remove_node(uuid)
		active_conversation.remove_node(uuid)


func _undo_remove_nodes(action_data: Dictionary) -> void:
	active_conversation.node_data.merge(action_data["resource_node_data"], false)
	active_conversation.localization.merge(action_data["resource_localization"], false)
	
	var graph_nodes_data: Dictionary = action_data["graph_nodes_data"]
	var tree_hierarchy: Dictionary = action_data["tree_hierarchy"]
	var connection_deaf_nodes: Array[DiscourseGraphNode] = []
	var created_nodes: Dictionary[StringName, DiscourseGraphNode] = {}
	var refresh_shortcuts: bool = false
	
	var hierarchy_uuid: Array[StringName] = []
	hierarchy_uuid.assign(tree_hierarchy.keys())
	hierarchy_uuid.sort_custom(
		func(a: StringName, b: StringName) -> bool:
			return tree_hierarchy[a]["index"] < tree_hierarchy[b]["index"])
	
	for node_uuid in graph_nodes_data:
		var node_info: Dictionary = graph_nodes_data[node_uuid]
		var data: Dictionary = node_info["data"]
		
		var d_node: DiscourseGraphNode = discourse_graph_edit.spawn_node(data["type"], node_uuid, data)
		
		if d_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE or d_node.node_type == DiscourseGraphNode.DialogueNodeType.METADATA:
			d_node._connection_updates_disabled = true
			connection_deaf_nodes.append(d_node)
		elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.SHORTCUT or d_node.node_type == DiscourseGraphNode.DialogueNodeType.SHORTCUT_TARGET:
			refresh_shortcuts = true
		
		if d_node.is_node_localized():
			if d_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG:
				d_node.set_dialog_text(DictUtils.get_nested_value(
				active_conversation.localization,
				[node_uuid, "locales", current_locale],
				"",
				true))
				localization_nodes_tree.create_dialog_node(d_node.get_node_id(), d_node)
			elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.CHOICES:
				var localized_options: Array[String] = []
				var choice_size: int = d_node.choice_count()
				
				localized_options.assign(DictUtils.get_nested_value(
						active_conversation.localization,
						[node_uuid, "locales", current_locale],
						[],
						true))
				
				if localized_options.size() < choice_size:
					localized_options.resize(choice_size)
		
				for option_idx in range(choice_size):
					discourse_graph_edit.set_choice_node_text(
						node_uuid,
						option_idx + 1,
						localized_options[option_idx])
				
				localization_nodes_tree.create_options_node(d_node.get_node_id(), d_node)
			elif d_node.node_type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				d_node.set_text(DictUtils.get_nested_value(
				active_conversation.localization,
				[node_uuid, "locales", current_locale],
				"",
				true))
				localization_nodes_tree.create_localized_text_node(d_node.get_node_id(), d_node)
		created_nodes[node_uuid] = d_node
	
	for node_uuid in tree_hierarchy:
		if not created_nodes.has(node_uuid):
			continue
		var tree_data: Dictionary = tree_hierarchy.get(node_uuid, {})
		if not tree_data.is_empty() and tree_data.get("is_node", false):
			discourse_nodes_tree.create_with_path(
				created_nodes[node_uuid],
				tree_data.get("path", ""),
				tree_data.get("index", -1))
	
	for node_uuid in graph_nodes_data:
		var node_info: Dictionary = graph_nodes_data[node_uuid]
		
		var outputs: Dictionary = node_info.get("output_connections", {})
		for field_id in outputs:
			for conn in outputs[field_id].get("connections", []):
				discourse_graph_edit.connect_discourse_nodes(
					node_uuid,
					conn["from_port"],
					conn["target_node_uuid"],
					conn["target_port"])
		
		var inputs: Dictionary = node_info.get("input_connections", {})
		for field_id in inputs:
			for conn in inputs[field_id].get("connections", []):
				discourse_graph_edit.connect_discourse_nodes(
					conn["target_node_uuid"],
					conn["target_port"],
					node_uuid,
					conn["from_port"])
	
	for node in connection_deaf_nodes:
		node._connection_updates_disabled = false
	
	if refresh_shortcuts:
		discourse_graph_edit.refresh_anchors()
		var pointer_states: Dictionary = action_data["pointer_states"]
		for pointer_uuid in action_data["pointer_states"]:
			var pointer: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(pointer_uuid)
			if pointer != null:
				pointer.select_target(pointer_states[pointer_uuid])


func _on_graph_edit_node_duplication_requested(uuids: Array[StringName]) -> void:
	var uuid_size: int = uuids.size()
	
	if uuid_size == 0:
		return
	elif uuid_size == 1:
		var new_uuid: StringName = StringName(UUID.generate_new())
		discourse_graph_edit.duplicate_single(uuids[0], new_uuid)
	else:
		# Existing UUID: New UUID
		var uuid_map: Dictionary[StringName, StringName] = {}
		for uuid in uuids:
			uuid_map[uuid] = StringName(UUID.generate_new())
		
		discourse_graph_edit.duplicate_multiple(uuid_map)
		
	_on_conversation_changed()


func _on_graph_edit_paste_requested() -> void:
	if discourse_graph_edit.node_clipboard.is_empty():
		return
	
	# Original UUID, New UUID
	var uuid_map: Dictionary[StringName, StringName] = {}
	var clipboard: Array[Dictionary] = discourse_graph_edit.node_clipboard.duplicate(true)
	
	
	for clipboard_data in clipboard:
		if discourse_graph_edit.graph_nodes.has(clipboard_data["node_uuid"]):
			uuid_map[clipboard_data["node_uuid"]] = StringName(UUID.generate_new())
		else:
			uuid_map[clipboard_data["node_uuid"]] = clipboard_data["node_uuid"]
	
	discourse_graph_edit.paste_node_clipboard(clipboard, uuid_map)
	_on_conversation_changed()

# ------------------------------

func _on_nodes_moved(movement_data: Dictionary) -> void:
	var moved: bool = false
	
	for node_uuid in movement_data["nodes"]:
		var data: Dictionary = movement_data["nodes"][node_uuid]
		if data["previous_position"] != data["current_position"] or data["previous_frame"] != data["current_frame"]:
			moved = true
			break
	
	if not moved:
		for frame_uuid in movement_data["frames"]:
			var data: Dictionary = movement_data["frames"][frame_uuid]
			if data["previous_position"] != data["current_position"]:
				moved = true
				break
	
	if not moved:
		return
	
	undo.create_action("Move Graph Elements")
	undo.add_do_method(_apply_movement_state.bind(movement_data, false))
	undo.add_undo_method(_apply_movement_state.bind(movement_data, true))
	undo.commit_action(false)
	_on_conversation_changed()


func _apply_movement_state(movement_data: Dictionary, is_undo: bool) -> void:
	for frame_uuid in movement_data["frames"]:
		var frame: GraphFrame = discourse_graph_edit.get_discourse_frame(frame_uuid)
		if frame != null:
			var data: Dictionary = movement_data["frames"][frame_uuid]
			frame.position_offset = data["previous_position"] if is_undo else data["current_position"]
	
	for node_uuid in movement_data["nodes"]:
		var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(node_uuid)
		if node != null:
			var data: Dictionary = movement_data["nodes"][node_uuid]
			node.position_offset = data["previous_position"] if is_undo else data["current_position"]
			
			var target_frame_uuid: StringName = data["previous_frame"] if is_undo else data["current_frame"]
			var current_frame_uuid: StringName = data["current_frame"] if is_undo else data["previous_frame"]
			
			if target_frame_uuid != current_frame_uuid:
				if target_frame_uuid == &"":
					discourse_graph_edit.detach_graph_element_from_frame(node.name)
				else:
					var target_frame: GraphFrame = discourse_graph_edit.get_discourse_frame(target_frame_uuid)
					if target_frame != null:
						discourse_graph_edit.attach_graph_element_to_frame(node.name, target_frame.name)


func _on_node_connected(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	undo.create_action("Connect Nodes")
	undo.add_do_method(discourse_graph_edit.connect_discourse_nodes.bind(from_node, from_port, to_node, to_port))
	undo.add_undo_method(discourse_graph_edit.disconnect_discourse_nodes.bind(from_node, from_port, to_node, to_port))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_node_disconnected(from_node: StringName, from_port: int, to_node: StringName, to_port: int, from_state: Dictionary, to_state: Dictionary) -> void:
	undo.create_action("Disconnect Nodes")
	undo.add_do_method(discourse_graph_edit.disconnect_discourse_nodes.bind(from_node, from_port, to_node, to_port))
	undo.add_undo_method(_undo_node_disconnect.bind(from_node, from_port, to_node, to_port, from_state, to_state))
	undo.commit_action(false)
	_on_conversation_changed()


func _undo_node_disconnect(from_node: StringName, from_port: int, to_node: String, to_port: int, from_state: Dictionary, to_state: Dictionary) -> void:
	var f_node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(from_node)
	var t_node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(to_node)
	var resume_updates_from: bool = false
	var resume_updates_to: bool = false
	
	if f_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE or\
			f_node.node_type == DiscourseGraphNode.DialogueNodeType.METADATA:
		resume_updates_from = true
		f_node._connection_updates_disabled = true
	
	if t_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE or\
			t_node.node_type == DiscourseGraphNode.DialogueNodeType.METADATA:
		resume_updates_to = true
		t_node._connection_updates_disabled = true
	
	f_node._set_node_data(from_state)
	t_node._set_node_data(to_state)
	
	discourse_graph_edit.connect_discourse_nodes(from_node, from_port, to_node, to_port)
	
	if resume_updates_to:
		t_node._connection_updates_disabled = false
	if resume_updates_from:
		f_node._connection_updates_disabled = false


func _on_node_connection_switched(origin_ports: Dictionary, new_node: StringName, new_port: int, old_from_data: Dictionary, old_to_data: Dictionary, new_from_data: Dictionary, new_to_data: Dictionary) -> void:
	# origin_ports holds the OLD connection that was broken.
	var old_from_node: StringName = origin_ports["from_node"]
	var old_from_port: int = origin_ports["from_port"]
	var old_to_node: StringName = origin_ports["to_node"]
	var old_to_port: int = origin_ports["to_port"]
	
	var new_from_node: StringName = old_from_node
	var new_from_port: int = old_from_port
	
	var original_connection: Dictionary = {
		"from_node": old_from_node,
		"from_port": old_from_port,
		"to_node": old_to_node,
		"to_port": old_to_port,
		"from_state": old_from_data,
		"to_state": old_to_data}
	
	var new_connection: Dictionary = {
		"from_node": new_from_node,
		"from_port": new_from_port,
		"to_node": new_node,
		"to_port": new_port,
		"from_state": new_from_data,
		"to_state": new_to_data}
	
	undo.create_action("Switch Node Connection")
	undo.add_do_method(_do_switch_discourse_connections.bind(original_connection, new_connection))
	undo.add_undo_method(_do_switch_discourse_connections.bind(new_connection, original_connection))
	undo.commit_action(false)
	_on_conversation_changed()


func _do_switch_discourse_connections(from: Dictionary, to: Dictionary) -> void:
	var old_from_node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(from["from_node"])
	var old_to_node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(from["to_node"])
	var new_from_node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(to["from_node"])
	var new_to_node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(to["to_node"])
	
	var resume_old_from: bool = false
	var resume_old_to: bool = false
	var resume_new_from: bool = false
	var resume_new_to: bool = false
	
	if old_from_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE or\
			old_from_node.node_type == DiscourseGraphNode.DialogueNodeType.METADATA:
		resume_old_from = true
		old_from_node._connection_updates_disabled = true
	
	if old_to_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE or\
			old_to_node.node_type == DiscourseGraphNode.DialogueNodeType.METADATA:
		resume_old_to = true
		old_to_node._connection_updates_disabled = true
	
	if new_from_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE or\
			new_from_node.node_type == DiscourseGraphNode.DialogueNodeType.METADATA:
		resume_new_from = true
		new_from_node._connection_updates_disabled = true
	
	if new_to_node.node_type == DiscourseGraphNode.DialogueNodeType.DIALOG_MERGE or\
			new_to_node.node_type == DiscourseGraphNode.DialogueNodeType.METADATA:
		resume_new_to = true
		new_to_node._connection_updates_disabled = true
	
	discourse_graph_edit.disconnect_discourse_nodes(from["from_node"], from["from_port"], from["to_node"], from["to_port"])
	old_from_node._set_node_data(from["from_state"])
	old_to_node._set_node_data(from["to_state"])
	
	new_from_node._set_node_data(to["from_state"])
	new_to_node._set_node_data(to["to_state"])
	discourse_graph_edit.connect_discourse_nodes(to["from_node"], to["from_port"], to["to_node"], to["to_port"])
	
	if resume_old_from:
		old_from_node._connection_updates_disabled = false
	if resume_old_to:
		old_to_node._connection_updates_disabled = false
	if resume_new_from:
		new_from_node._connection_updates_disabled = false
	if resume_new_to:
		new_to_node._connection_updates_disabled = false


func _on_nodes_created_batch(node_uuids: Array[StringName], action_name: String = "Create Nodes") -> void:
	var action_data: Dictionary = {
		"graph_nodes_data": {},
		"resource_node_data": {},
		"resource_localization": {},
		"tree_hierarchy": {}}
	
	for uuid in node_uuids:
		var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(uuid)
		if node == null:
			continue
		
		action_data["graph_nodes_data"][uuid] = node.get_node_state()
		
		if active_conversation.node_data.has(uuid):
			action_data["resource_node_data"][uuid] = active_conversation.node_data[uuid].duplicate(true)
		if active_conversation.localization.has(uuid):
			action_data["resource_localization"][uuid] = active_conversation.localization[uuid].duplicate(true)
		
		action_data["tree_hierarchy"][uuid] = discourse_nodes_tree.get_node_data(uuid)
	
	undo.create_action(action_name)
	undo.add_do_method(_undo_remove_nodes.bind(action_data))
	undo.add_undo_method(_do_remove_nodes.bind(action_data))
	undo.commit_action(false)

# --- Other Actions ---

func _get_locale_snapshot(locale: String) -> Dictionary[String, Dictionary]:
	var snapshot: Dictionary[String, Dictionary] = {
		"format_strings": {},
		"localization": {}
	}
	var std_locale: String = TranslationServer.standardize_locale(locale)
	
	# Backup Phrase formats and cases
	for phrase_key in active_conversation.format_strings:
		if active_conversation.format_strings[phrase_key].has(std_locale):
			snapshot["format_strings"][phrase_key] = active_conversation.format_strings[phrase_key][std_locale].duplicate(true)
	
	# Backup Graph Node texts/choices
	for node_uuid in active_conversation.localization.keys():
		if active_conversation.localization[node_uuid]["locales"].has(std_locale):
			snapshot["localization"][node_uuid] = active_conversation.localization[node_uuid]["locales"][std_locale].duplicate(true)
	
	return snapshot


func _do_add_locale_action(locale: String, snapshot: Dictionary = {}) -> void:
	active_conversation.add_locale(locale)
	
	if not snapshot.is_empty():
		var std_locale: String = TranslationServer.standardize_locale(locale)
		for phrase_key in snapshot["format_strings"]:
			if active_conversation.format_strings.has(phrase_key):
				active_conversation.format_strings[phrase_key][std_locale] = snapshot["format_strings"][phrase_key].duplicate(true)
	
		for node_uuid in snapshot["localization"]:
			if active_conversation.localization.has(node_uuid):
				active_conversation.localization[node_uuid]["locales"][std_locale] = snapshot["localization"][node_uuid].duplicate(true)
	
	var parts: PackedStringArray = locale.split("_", false)
	if 1 < parts.size():
		languages_tree.create_region(parts[0], parts[1])
	else:
		languages_tree.create_language(locale)
	add_locale(locale)


func _do_remove_locale_action(locale: String) -> void:
	active_conversation.remove_locale(locale)
	
	remove_locale(locale)
	languages_tree.erase_language(locale)


func _do_set_default_locale(new_locale: String, created_new: bool) -> void:
	if created_new:
		_do_add_locale_action(new_locale)
	
	ProjectSettings.set_setting(
		NFPluginGameHandler.get_setting_path("discourse_base_language"),
		new_locale)
	ProjectSettings.save()
	
	base_language = new_locale
	languages_tree.set_default_language(new_locale)


func _undo_set_default_locale(old_locale: String, new_locale: String, created_new: bool) -> void:
	ProjectSettings.set_setting(
		NFPluginGameHandler.get_setting_path("discourse_base_language"),
		old_locale)
	ProjectSettings.save()
	
	base_language = old_locale
	languages_tree.set_default_language(old_locale)
	
	if created_new:
		_do_remove_locale_action(new_locale)


func _on_dialog_id_edit_toggled(is_editing: bool) -> void:
	if is_editing:
		return
	
	var old_value: String = dialog_id_ln_edt.get_meta(&"old_value")
	var new_value: String = dialog_id_ln_edt.text
	
	if new_value == old_value:
		return
	
	undo.create_action("Set Dialog ID")
	undo.add_do_method(_do_update_dialog_id.bind(new_value))
	undo.add_undo_method(_do_update_dialog_id.bind(old_value))
	undo.commit_action()


func _do_update_dialog_id(new_id: String) -> void:
	dialog_id_ln_edt.text = new_id
	dialog_id_ln_edt.set_meta(&"old_value", new_id)


func _do_update_locale_group(group: String) -> void:
	active_conversation.locale_group = group


func _on_localize_node(node: DiscourseGraphNode) -> void:
	var uuid: StringName = node.get_node_uuid()
	
	if localization_nodes_tree.is_node_localized(uuid):
		return
	
	undo.create_action("Localize Node")
	undo.add_do_method(_do_localize_node.bind(uuid))
	undo.add_undo_method(_do_delocalize_node.bind(uuid))
	undo.commit_action()


func _on_node_delocalization_requested(node: DiscourseGraphNode) -> void:
	var uuid: StringName = node.get_node_uuid()
	
	# We MUST backup all translations before wiping them!
	var snapshot: Dictionary = {}
	if active_conversation.localization.has(uuid):
		snapshot = active_conversation.localization[uuid].duplicate(true)
	
	undo.create_action("Delocalize Node")
	undo.add_do_method(_do_delocalize_node.bind(uuid))
	undo.add_undo_method(_do_localize_node.bind(uuid, snapshot))
	undo.commit_action()


func _do_localize_node(node_uuid: StringName, snapshot: Dictionary = {}) -> void:
	var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(node_uuid)
	
	if node == null:
		return
	
	if snapshot.is_empty():
		# First time localizing
		match node.node_type:
			DiscourseGraphNode.DialogueNodeType.DIALOG:
				active_conversation.set_dialog_text(node_uuid, node.get_dialog_text(), current_locale)
			DiscourseGraphNode.DialogueNodeType.CHOICES:
				active_conversation.set_choices_array(node_uuid, node.get_options(), current_locale)
			DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				active_conversation.set_dialog_text(node_uuid, node.get_text(), current_locale)
	else:
		# Restoring from an Undo
		active_conversation.localization[node_uuid] = snapshot.duplicate(true)
	
	
	node.set_node_localized(true)
	
	match node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			localization_nodes_tree.create_dialog_node(node.get_node_id(), node)
		DiscourseGraphNode.DialogueNodeType.CHOICES:
			localization_nodes_tree.create_options_node(node.get_node_id(), node)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			localization_nodes_tree.create_localized_text_node(node.get_node_id(), node)


func _do_delocalize_node(node_uuid: StringName) -> void:
	var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(node_uuid)
	if node == null:
		return
	
	match node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			var base_text: String = DictUtils.get_nested_value(
				active_conversation.localization,
				[node_uuid, "locales", base_language],
				node.get_dialog_text(),
				true)
			active_conversation.set_dialog_text(node_uuid, base_text)
			if current_locale != base_language: # GUI update only
				discourse_graph_edit.set_dialog_node_dialog_text(node_uuid, base_text)
		DiscourseGraphNode.DialogueNodeType.CHOICES:
			var options: Array[String] = []
			options.assign(DictUtils.get_nested_value(
					active_conversation.localization,
					[node_uuid, "locales", base_language],
					node.get_options(),
					true))
			active_conversation.set_choices_array(node_uuid, options)
			if current_locale != base_language:
				for choice_id in range(1, options.size() + 1): # It uses IDs instead of indexes
					discourse_graph_edit.set_choice_node_text(
							node_uuid,
							choice_id,
							options[choice_id - 1])
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			var base_text: String = DictUtils.get_nested_value(
				active_conversation.localization,
				[node_uuid, "locales", base_language],
				node.get_text(),
				true)
			active_conversation.set_dialog_text(node_uuid, base_text)
			if current_locale != base_language:
				discourse_graph_edit.set_localized_text_node_text(
						node_uuid,
						base_text)
	
	if localization_nodes_tree.get_active_node_uuid() == node_uuid:
		# This variable is used to know the previously selected one.
		# Shouldn't be accessed directly unless it's for a "switch",
		# so we change the comparison being done. SHould yield exacctly
		# the same behaviour as we're removing the node at the very end.
		localization_node_selected = null
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = false
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = false
	
	node.set_node_localized(false)
	localization_nodes_tree.remove_node(node_uuid)


func _on_frame_title_changed(uuid: StringName, from: String, to: String) -> void:
	undo.create_action("Set Frame Title")
	undo.add_do_method(discourse_graph_edit.set_frame_title.bind(uuid, to))
	undo.add_undo_method(discourse_graph_edit.set_frame_title.bind(uuid, from))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_frame_color_changed(uuid: StringName, from: Color, to: Color) -> void:
	undo.create_action("Set Frame Color")
	undo.add_do_method(discourse_graph_edit.set_frame_tint.bind(uuid, to))
	undo.add_undo_method(discourse_graph_edit.set_frame_tint.bind(uuid, from))
	undo.commit_action(false)
	_on_conversation_changed()


func _on_close_frame_requested(uuid: StringName) -> void:
	var frame: GraphFrame = discourse_graph_edit.get_discourse_frame(uuid)
	if frame == null:
		return
	
	# 1. Capture the exact state and contents of the frame before it is destroyed
	var action_data: Dictionary = {
		"uuid": uuid,
		"frame_data": frame.get_frame_data(),
		"attached_elements": discourse_graph_edit.get_elements_in_frame(uuid)}
	
	undo.create_action("Remove Frame")
	undo.add_do_method(_do_remove_frame.bind(uuid))
	undo.add_undo_method(_undo_remove_frame.bind(action_data))
	undo.commit_action()
	_on_conversation_changed()


func _do_remove_frame(uuid: StringName) -> void:
	discourse_graph_edit.remove_frame(uuid)


func _undo_remove_frame(action_data: Dictionary) -> void:
	var uuid: StringName = action_data["uuid"]
	var frame_data: Dictionary = action_data["frame_data"]
	var attached: Dictionary = action_data["attached_elements"]
	
	var frame_pos: Vector2 = frame_data.get("position", Vector2.ZERO)
	var frame: GraphFrame = discourse_graph_edit.spawn_frame(uuid, frame_pos)
	
	frame.set_frame_data(frame_data)
	
	for node_uuid in attached.get("nodes", []):
		var node: DiscourseGraphNode = discourse_graph_edit.get_discourse_node(node_uuid)
		if node != null:
			discourse_graph_edit.attach_graph_element_to_frame(node.name, frame.name)
	
	for nested_uuid in attached.get("frames", []):
		var nested_frame: GraphFrame = discourse_graph_edit.get_discourse_frame(nested_uuid)
		if nested_frame != null:
			discourse_graph_edit.attach_graph_element_to_frame(nested_frame.name, frame.name)


func _on_event_node_path_changed(node_uuid: StringName, from: String, to: String) -> void:
	undo.create_action("Set Event Variable Path")
	undo.add_do_method(discourse_graph_edit.set_event_node_variable_path.bind(node_uuid, to))
	undo.add_undo_method(discourse_graph_edit.set_event_node_variable_path.bind(node_uuid, from))
	undo.commit_action(false)


func _on_data_event_node_path_changed(node_uuid: StringName, from: String, to: String) -> void:
	undo.create_action("Set Data Event Variable Path")
	undo.add_do_method(discourse_graph_edit.set_data_event_node_variable_path.bind(node_uuid, to))
	undo.add_undo_method(discourse_graph_edit.set_data_event_node_variable_path.bind(node_uuid, from))
	undo.commit_action(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for file_id in _open_files:
			if is_instance_valid(_open_files[file_id]["undo"]):
				_open_files[file_id]["undo"].clear_history()
				_open_files[file_id]["undo"].free()
				_open_files[file_id]["undo"] = null
