extends PanelContainer


enum TreeButtonID {
	DELETE,
	NEW_PHRASE_ARGUMENT,
	RENAME_LOCALIZED_NODE}

#enum DiscourseNodeType {
	#GROUP,
	#NODE}

const SELECTED_COLOR: Color = Color.SKY_BLUE

var active_conversation: EditorDiscourseDialog = null
var active_conversation_item: TreeItem = null:
	set(new_conversation):
		if active_conversation_item != null:
			active_conversation_item.clear_custom_color(0)
		active_conversation_item = new_conversation
		if new_conversation != null:
			new_conversation.set_custom_color(0, SELECTED_COLOR)
var localization_node_selected: DiscourseGraphNode = null
var base_language: String = "":
	set(l):
		base_language = l
		phrases_tree.base_language = l
		discourse_window.base_language = l
		languages_tree.set_default_language(l)

var localizer_language: String = ""
var localizer_region: String = ""

var listen_offset: bool = true

var _unsaved: bool = false

#var _unsaved: bool = false:
	#get():
		#return not get_unsaved_conversation_resources().is_empty()


#var current_language: String = ""
#var current_region: String = ""
#var locale_map: Dictionary[String, PackedStringArray] = {}
#var registered_locales

# --- Discourse Graph ---
@onready var conversation_tree: Tree = $MainSplitContainer/MainSidebar/SidebarSplitContainer/ConversationContainer/ConversationTree
@onready var node_search_ln_edt: LineEdit = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/SearchHbox/NodeSearchLnEdt
@onready var discourse_nodes_tree: Tree = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/NodesTree
@onready var discourse_window: PanelContainer = $MainSplitContainer/DiscourseSplitContainer/DiscourseWindow
@onready var new_folder_button: Button = $MainSplitContainer/MainSidebar/SidebarSplitContainer/NodesContainer/SearchHbox/NewFolderButton


# --- Localization Window ---
@onready var new_language_btn: Button = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LanguagesSplitContainer/LanguagesContainer/HeaderContainer/NewLanguageBtn
@onready var search_language_ln_edt: LineEdit = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LanguagesSplitContainer/LanguagesContainer/SearchLanguageLnEdt
@onready var languages_tree: Tree = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LanguagesSplitContainer/LanguagesContainer/LanguagesTree
@onready var search_nodes_ln_edt: LineEdit = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LanguagesSplitContainer/NodesContainer/SearchNodesLnEdt
@onready var localization_nodes_tree: Tree = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LanguagesSplitContainer/NodesContainer/NodesTree
@onready var base_text_edt: TextEdit = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer/BasePanelContainer/BaseContainer/BaseTextEdt
@onready var translation_txt_box: TextEdit = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer/TranslationPanel/TranslationContainer/TranslationTxtBox
@onready var create_phrase_btn: Button = $LocalizationContainer/MainSplitContainer/PhrasesContainer/HeaderPanel/PhrasesHeader/CreatePhraseBtn
@onready var search_phrase_ln_edt: LineEdit = $LocalizationContainer/MainSplitContainer/PhrasesContainer/SearchPhraseLnEdt
@onready var phrases_tree: Tree = $LocalizationContainer/MainSplitContainer/PhrasesContainer/PhrasesTree
@onready var locale_label: Label = $LocalizationContainer/LocaleLabel
@onready var return_discourse_btn: Button = $LocalizationContainer/MainSplitContainer/PhrasesContainer/HeaderPanel/PhrasesHeader/ReturnDiscourseBtn
@onready var choices_container: VBoxContainer = $LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer/ChoicesScroller/ChoicesContainer


func _ready() -> void:
	var system_lang = OS.get_locale_language()
	languages_tree.create_language(system_lang, true)
	discourse_window.add_locale(system_lang)
	base_language = system_lang
	
	phrases_tree.create_locale(system_lang)
	phrases_tree.base_language = system_lang
	
	discourse_window.set_localization(system_lang)
	
	create_phrase_btn.disabled = true
	
	conversation_tree.create_item()
	discourse_nodes_tree.create_item().collapsed = true
	
	if discourse_window.discourse_graph_edit.entry_node != null:
		_on_discourse_node_created(discourse_window.discourse_graph_edit.entry_node)
	
	$MainSplitContainer.visible = true
	$LocalizationContainer.visible = false
	new_folder_button.disabled = true
	new_folder_button.icon = get_theme_icon("FolderCreate", "EditorIcons")
	
	return_discourse_btn.icon = get_theme_icon("Back", "EditorIcons")
	
	discourse_window.discourse_graph_edit.dialog_changed.connect(_on_conversation_changed)
	discourse_window.discourse_graph_edit.localization_enabled.connect(_on_localize_node)
	discourse_window.discourse_graph_edit.localized_text_created.connect(_on_localize_node)
	discourse_window.discourse_graph_edit.node_created.connect(_on_discourse_node_created)
	discourse_window.localization_window_pressed.connect(_on_switch_window_pressed)
	discourse_window.new_conversation_pressed.connect(_on_new_conversation_pressed)
	discourse_window.open_conversation_pressed.connect(_on_open_conversation_pressed)
	discourse_window.save_conversation_pressed.connect(_on_save_conversation_pressed)
	discourse_window.close_conversation_pressed.connect(_on_menu_close_pressed)
	
	discourse_window.discourse_graph_edit.node_deleted.connect(_on_node_deleted)
	discourse_window.discourse_graph_edit.scroll_offset_changed.connect(_on_graph_edit_offset_changed)
	discourse_window.change_default_language_pressed.connect(_on_change_default_language_pressed)
	discourse_window.set_locale_group_pressed.connect(_on_change_locale_group_pressed)
	return_discourse_btn.pressed.connect(_on_switch_window_pressed)
	create_phrase_btn.pressed.connect(_on_new_phrase_button_pressed)
	new_language_btn.pressed.connect(_on_new_lang_pressed)
	#languages_tree.locale_changed.connect(_on_locale_changed)
	languages_tree.locale_changed.connect(_on_localizer_locale_changed)
	languages_tree.region_created.connect(_on_region_created)
	
	discourse_nodes_tree.button_clicked.connect(_on_discourse_tree_button_clicked)
	discourse_nodes_tree.item_edited.connect(_on_discourse_item_edited)
	localization_nodes_tree.dialog_selected.connect(_on_localizer_node_selected)
	localization_nodes_tree.node_delocalized.connect(_on_node_delocalized)
	discourse_nodes_tree.item_activated.connect(_on_discourse_node_activated)
	localization_nodes_tree.dialog_item_edited.connect(_on_localizer_item_edited)
	translation_txt_box.text_changed.connect(_on_text_field_changed)
	translation_txt_box.text_changed.connect(_on_translation_text_changed)
	phrases_tree.phrase_changed.connect(_on_conversation_changed)
	
	new_folder_button.pressed.connect(_on_new_folder_button_pressed)
	conversation_tree.item_activated.connect(_on_conversation_activated)


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
	if not listen_offset or active_conversation_item == null or active_conversation_item.get_metadata(0)["offset_changed"]:
		return
	active_conversation_item.get_metadata(0)["offset_changed"] = true


func _on_menu_close_pressed() -> void:
	if active_conversation_item == null:
		return
	
	if discourse_window.discourse_graph_edit.focus_tween != null:
		discourse_window.discourse_graph_edit.stop_focus_animation()
	#print(str("Unsaved: ", active_conversation_item.get_metadata(0)["unsaved"]))
	#print(str("Offset: ", active_conversation_item.get_metadata(0)["offset_changed"]))
	if active_conversation_item.get_metadata(0)["unsaved"] or active_conversation_item.get_metadata(0)["offset_changed"]:
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
	
	var item: TreeItem = active_conversation_item
	var total_items: int = conversation_tree.get_root().get_child_count()
	var new_item: TreeItem = null
	
	if 1 < total_items:
		if item.get_index() == total_items - 1: # Get a -1
			new_item = conversation_tree.get_root().get_child(item.get_index() - 1)
		else: # Get the same index
			new_item = conversation_tree.get_root().get_child(item.get_index() + 1)
		
	if new_item == null:
		active_conversation_item = null
		set_conversation_active(false)
	else:
		active_conversation = new_item.get_metadata(0)["resource"]
		active_conversation_item = new_item
		open_conversation(active_conversation)
	
	item.free()


func _on_new_folder_button_pressed() -> void:
	var new_name: String = get_unique_name_on_tree(
			discourse_nodes_tree.get_root(),
			"NewGroup")
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
			discourse_window.add_locale(result)
			phrases_tree.create_locale(result)
		base_language = result
	window.queue_free()


func _on_node_deleted(uuid: StringName) -> void:
	localization_nodes_tree.remove_node(uuid)
	discourse_nodes_tree.remove_dialog_node(uuid)


func _on_translation_text_changed() -> void:
	if languages_tree.get_base_language() == languages_tree.get_active_language() and languages_tree.get_active_region() == "base":
		base_text_edt.text = translation_txt_box.text


func _on_conversation_changed(_arg = null) -> void:
	if _unsaved:
		return
	
	_unsaved = true
	
	if active_conversation_item != null:
		active_conversation_item.get_metadata(0)["unsaved"] = true
		active_conversation_item.set_text(0, active_conversation_item.get_text(0) + "*")


func _on_localizer_locale_changed(language: String, region: String) -> void:
	var invalid_language: bool = language.is_empty()
	localization_nodes_tree.get_root().collapsed = invalid_language
	create_phrase_btn.disabled = invalid_language
	phrases_tree.get_root().collapsed = invalid_language
	
	if region.is_empty():
		region = "base"
	
	set_localization_tip(language, region)
	
	if phrases_tree.is_locale_valid():
		phrases_tree.save_locale()
	
	if language.is_empty():
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = false
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = false
		set_localizer_locale(language, region)
		#phrases_tree.set_locale(language, region)
		#localizer_language = language
		#localizer_region = region
		return
	
	var uuid: StringName = localization_nodes_tree.get_active_node_uuid()
	
	if uuid.is_empty():
		set_localizer_locale(language, region)
		#phrases_tree.set_locale(language, region)
		#localizer_language = language
		#localizer_region = region
		return
	
	var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	#var current_language: String = languages_tree.get_active_language()
	#var current_region: String = languages_tree.get_active_region()
	
	
	# THere is an UUID to update
	#var localization_node_key: String = "options" if 
	if active_node != null:
		match active_node.node_type:
			DiscourseGraphNode.DialogueNodeType.DIALOG:
				discourse_window.set_localization_dialog(uuid, translation_txt_box.text, localizer_language, localizer_region)
			DiscourseGraphNode.DialogueNodeType.OPTIONS:
				discourse_window.set_localization_options(uuid, get_localizer_choices(), localizer_language, localizer_region)
	
	#var base_lang: String = discourse_window.base_language
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = discourse_window.localization[uuid]["node"].node_type == DiscourseGraphNode.DialogueNodeType.OPTIONS
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = !$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible
	#localization[uuid]["localization"][language][country]["dialog/options/text"]
	
	#localizer_language = language
	#localizer_region = region
	#phrases_tree.set_locale(language, region)
	set_localizer_locale(language, region)
	
	var type: DiscourseGraphNode.DialogueNodeType = discourse_window.localization[uuid]["node"].node_type
	
	if type == DiscourseGraphNode.DialogueNodeType.DIALOG or type == DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
		base_text_edt.text = discourse_window.get_localization_argument(uuid, base_language)
		translation_txt_box.text = discourse_window.get_localization_argument(uuid, language, region)
		#DiscourseGraphNode.DialogueNodeType.DIALOG:
		#base_text_edt.text = discourse_window.localization[uuid]["localization"][base_language]["base"]["dialog"]
		#translation_txt_box.text = discourse_window.localization[uuid]["localization"][language][region]["dialog"]
	elif type == DiscourseGraphNode.DialogueNodeType.OPTIONS:
		clear_localized_options()
		var base_options: Array[String] = discourse_window.get_localization_argument(uuid, base_language)
		var localized_options: Array[String] = discourse_window.get_localization_argument(uuid, language, region)
		for option_idx in range(base_options.size()):
			create_choice_node(
					base_options[option_idx],
					localized_options[option_idx])
			#base_text_edt.text = discourse_window.localization[uuid]["localization"][base_language]["base"]["text"]
			#translation_txt_box.text = discourse_window.localization[uuid]["localization"][language][region]["text"]


func _on_localizer_node_selected(uuid: StringName) -> void:
	if uuid.is_empty():
		localization_node_selected = null
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = false
		$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = false
		return
	
	#var localizer_language: String = languages_tree.get_active_language()
	#var localizer_region: String = languages_tree.get_active_region()
	
	if localizer_language.is_empty():
		return
	
	# Save previous node if needed.
	if localization_node_selected != null:
		var update_node: bool = localizer_language == discourse_window.current_language and localizer_region == discourse_window.current_country
		# Save data to localization dictionary and update node if needed.
		match localization_node_selected.node_type:
			DiscourseGraphNode.DialogueNodeType.DIALOG:
				discourse_window.set_localization_dialog(
						localization_node_selected.get_node_uuid(),
						translation_txt_box.text,
						localizer_language,
						localizer_region)
				if update_node:
					localization_node_selected.set_dialog_text(translation_txt_box.text)
			DiscourseGraphNode.DialogueNodeType.OPTIONS:
				var options: Array[String] = []
				for option_child in choices_container.get_children():
					options.append(option_child.get_child(2).text)
				
				discourse_window.set_localization_options(
						localization_node_selected.get_node_uuid(),
						options,
						localizer_language,
						localizer_region)
				
				if update_node:
					for option_idx in range(options.size()):
						localization_node_selected.set_option_text(
								option_idx + 1,
								options[option_idx])
			DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
				discourse_window.set_localization_text(
						localization_node_selected.get_node_uuid(),
						translation_txt_box.text,
						localizer_language,
						localizer_region)
				if update_node:
					localization_node_selected.set_text(translation_txt_box.text)
	
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible = discourse_window.localization[uuid]["node"].node_type == DiscourseGraphNode.DialogueNodeType.OPTIONS
	$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/LocaleVBoxContainer.visible = !$LocalizationContainer/MainSplitContainer/LeftSplitContainer/LocaleContainer/LocalePanel/ChoicesContainer.visible
	# Set the data
	
	match discourse_window.localization[uuid]["node"].node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			#base_text_edt.text = discourse_window.localization[uuid]["localization"][base_lang]["base"]["dialog"]
			base_text_edt.text = discourse_window.get_localization_argument(uuid, base_language)
			translation_txt_box.text = discourse_window.get_localization_argument(uuid, localizer_language, localizer_region)
			#translation_txt_box.text = discourse_window.localization[uuid]["localization"][language][region]["dialog"]
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			clear_localized_options()
			var options_base: Array[String] = discourse_window.get_localization_argument(uuid, base_language)
			var options_localized: Array[String] = discourse_window.get_localization_argument(uuid, localizer_language, localizer_region)
			for option_idx in range(options_base.size()):
				create_choice_node(
						options_base[option_idx],
						options_localized[option_idx])
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			base_text_edt.text = discourse_window.get_localization_argument(uuid, base_language)
			translation_txt_box.text = discourse_window.get_localization_argument(uuid, localizer_language, localizer_region)
	
	localization_node_selected = localization_nodes_tree.get_active_node()


func _on_localize_node(node: DiscourseGraphNode) -> void:
	match node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			localization_nodes_tree.create_dialog_node(node.custom_id, node)
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			localization_nodes_tree.create_options_node(node.custom_id, node)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			localization_nodes_tree.create_localized_text_node(node.custom_id, node)


func _on_node_delocalized(node: DiscourseGraphNode) -> void:
	match node.node_type: # Reverting node to base language.
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			node.set_dialog_text(
					discourse_window.get_localization_argument(
							node.get_node_uuid(),
							base_language))
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			var options: Array[String] = discourse_window.get_localization_argument(
					node.get_node_uuid(),
					base_language)
			for option_idx in range(options.size()):
				node.set_option_text(option_idx + 1, options[option_idx])
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			node.set_text(
					discourse_window.get_localization_argument(
							node.get_node_uuid(),
							base_language))
	
	node.set_node_localized(false)
	discourse_window.erase_localization(node.get_node_uuid())
	
	if localization_node_selected == node:
		localization_node_selected = null


func _on_switch_window_pressed() -> void:
	var to_localizer: bool = $MainSplitContainer.visible
	
	if not discourse_window.current_language.is_empty():
		if to_localizer:
			discourse_window.save_current_locale()
		else:
			if localization_nodes_tree.get_active_node() != null:
				save_localizer_data()
	
	var localizer_active_region: String = languages_tree.get_active_region()
	if localizer_active_region.is_empty():
		localizer_active_region = "base"
	var on_same_locale: bool = languages_tree.get_active_language() == discourse_window.current_language and discourse_window.current_country == localizer_active_region
	
	if to_localizer and on_same_locale:
		var selected_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
		if selected_node != null:
			match selected_node.node_type:
				DiscourseGraphNode.DialogueNodeType.OPTIONS:
					var options: Array[String] = discourse_window.get_localization_argument(
							selected_node.get_node_uuid(),
							languages_tree.get_active_language(),
							languages_tree.get_active_region())
					var base_lang: Array[String] = discourse_window.get_localization_argument(
						selected_node.get_node_uuid(),
						languages_tree.get_base_language())
					clear_localized_options()
					for option_idx in range(options.size()):
						create_choice_node(
								base_lang[option_idx],
								options[option_idx])
				_:
					var text: String = discourse_window.get_localization_argument(
							selected_node.get_node_uuid(),
							languages_tree.get_active_language(),
							languages_tree.get_active_region())
					base_text_edt.text = discourse_window.get_localization_argument(
							selected_node.get_node_uuid(),
							languages_tree.get_base_language())
					translation_txt_box.text = text
	elif not to_localizer and on_same_locale:
		var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
		if active_node != null:
			match active_node.node_type:
				DiscourseGraphNode.DialogueNodeType.DIALOG:
					active_node.set_dialog_text(
							translation_txt_box.text)
				DiscourseGraphNode.DialogueNodeType.OPTIONS:
					var option_number: int = 0
					for option_node in choices_container.get_children():
						option_number += 1
						active_node.set_option_text(
								option_number,
								option_node.get_child(2).text)
				DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
					active_node.set_text(
							translation_txt_box.text)
	
	$MainSplitContainer.visible = !to_localizer
	$LocalizationContainer.visible = to_localizer


func _on_region_created(language: String, region: String) -> void:
	discourse_window.add_locale(language, region)
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
		discourse_window.add_locale(result)
		if phrases_tree.is_locale_valid() and phrases_tree.on_main_language():
			phrases_tree.save_locale()
		phrases_tree.create_locale(result)
		_on_conversation_changed()
	window.queue_free()


func _on_language_deleted(language: String) -> void:
	phrases_tree.remove_locale(language)
	discourse_window.remove_locale(language)


func set_localization_tip(language_code: String, region_code: String) -> void:
	var language_name: String = TranslationServer.get_language_name(language_code)
	
	var locale_text: String = "Current Locale: " 
	if region_code != "base":
		var country_name: String = TranslationServer.get_country_name(region_code)
		locale_text += country_name
		if country_name.ends_with("s"):
			locale_text += "' "
		else:
			locale_text += "'s "
	
	locale_text += language_name
	locale_label.text = locale_text


func _on_new_phrase_button_pressed() -> void:
	var word_window: ConfirmationDialog = preload("res://addons/nexus_forge/dialogs/lineedit_confirmation_dialog.gd").new()
	word_window.line_placeholder_text = "New Word"
	word_window.title = "Create Word..."
	word_window.ok_button_text = "Create"
	word_window.use_blacklist = true
	word_window.allow_empty = false
	word_window.strip_edges = true
	word_window.character_blacklist.append(" ")
	word_window.error_line_blacklist_character_msg = "Phrase can't contain\nwhitespaces"
	word_window.error_line_blacklist_word_msg = "Phrase is already in use"
	
	word_window.text_blacklist = phrases_tree.get_used_keys()
	
	add_child(word_window)
	word_window.show()
	word_window.grab_text_focus()
	
	var word: Array = await word_window.dialog_finished
	if word[0]:
		phrases_tree.create_key(word[1])
		_on_conversation_changed()
	word_window.queue_free()


func _on_conversation_activated() -> void:
	var item: TreeItem = conversation_tree.get_selected()
	var conversation: EditorDiscourseDialog = item.get_metadata(0)["resource"]
	if not discourse_window.are_conversation_options_enabled():
		discourse_window.set_graph_edit_visible(true)
		discourse_window.set_conversation_options_enabled(true)
		discourse_nodes_tree.get_root().collapsed = false
		new_folder_button.disabled = false
		
	if active_conversation != null:
		var new_dialog: EditorDiscourseDialog = discourse_window.discourse_graph_edit.get_conversation_data(active_conversation)
		
		# Obtaining localization reference
		var localizations: Dictionary = discourse_window.localization
		
		new_dialog.base_language = base_language
		new_dialog.zoom = discourse_window.discourse_graph_edit.zoom
		new_dialog.scroll_offset = discourse_window.discourse_graph_edit.scroll_offset
		new_dialog.node_structure = discourse_nodes_tree.get_folder_structure()
		new_dialog.localized_strings = phrases_tree.get_localization_structure()
		
		# Adding localization data to localized nodes
		for localized_uuid in localizations.keys():
			# --- If the text is unlocalized ---
			if localizations[localized_uuid].has("common"):
				match localized_uuid["node"].node_type:
					DiscourseGraphNode.DialogueNodeType.DIALOG:
						new_dialog.set_localization_text(
							localized_uuid,
							localizations[localized_uuid]["locaization"]["common"]["dialog"],
							"common")
					DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
						new_dialog.set_localization_text(
							localized_uuid,
							localizations[localized_uuid]["locaization"]["common"]["text"],
							"common")
					DiscourseGraphNode.DialogueNodeType.OPTIONS:
						new_dialog.set_localization_choices(
								localized_uuid,
								localizations[localized_uuid]["locaization"]["common"]["options"],
								"common")
			
			# --- Or we have a truly localized node ---
			for language in localizations[localized_uuid]["localization"].keys():
				for region in localizations[localized_uuid]["localization"][language].keys():
					match localized_uuid["node"].node_type:
						DiscourseGraphNode.DialogueNodeType.DIALOG:
							new_dialog.set_localization_text(
								localized_uuid,
								localizations[localized_uuid]["locaization"][language][region]["dialog"],
								language,
								region)
						DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
							new_dialog.set_localization_text(
								localized_uuid,
								localizations[localized_uuid]["locaization"][language][region]["text"],
								language,
								region)
						DiscourseGraphNode.DialogueNodeType.OPTIONS:
							new_dialog.set_localization_choices(
									localized_uuid,
									localizations[localized_uuid]["localization"][language][region]["options"],
									language,
									region)
		
		if _unsaved or active_conversation_item.get_metadata(0)["offset_changed"]:
			active_conversation_item.get_metadata(0)["unsaved"] = true
			active_conversation_item.get_metadata(0)["offset_changed"] = false
	
	active_conversation = conversation
	active_conversation_item = item
	open_conversation(conversation)


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
		choices.append(choice.get_child(2).text)
	
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


func _on_new_conversation_pressed() -> void:
	var file_saver: FileDialog = FileDialog.new()
	file_saver.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_saver.access = FileDialog.ACCESS_RESOURCES
	file_saver.add_filter("*.tres", "Resources")
	file_saver.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	add_child(file_saver)
	file_saver.file_selected.connect(_on_conversation_file_saved.bind(file_saver))
	file_saver.canceled.connect(_on_conversation_file_canceled.bind(file_saver))
	file_saver.show()


func _on_open_conversation_pressed() -> void:
	var file_opener: FileDialog = FileDialog.new()
	file_opener.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_opener.access = FileDialog.ACCESS_RESOURCES
	file_opener.add_filter("*.tres", "Resources")
	file_opener.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	add_child(file_opener)
	file_opener.file_selected.connect(_on_conversation_file_selected.bind(file_opener))
	file_opener.canceled.connect(_on_conversation_file_canceled.bind(file_opener))
	file_opener.show()


func _on_conversation_file_selected(path: String, dialog: FileDialog) -> void:
	if FileAccess.file_exists(path):
		var resource: Resource = load(path)
		if resource != null and resource is EditorDiscourseDialog:
			if not discourse_window.are_conversation_options_enabled():
				discourse_window.set_graph_edit_visible(true)
				discourse_window.set_conversation_options_enabled(true)
				discourse_nodes_tree.get_root().collapsed = false
				new_folder_button.disabled = false
			add_conversation(resource, true)
	dialog.queue_free()


func _on_conversation_file_canceled(dialog: FileDialog) -> void:
	dialog.queue_free()


func _on_conversation_file_saved(path: String, dialog: FileDialog) -> void:
	var new_conv: EditorDiscourseDialog = EditorDiscourseDialog.new()
	listen_offset = false
	ResourceSaver.save(
			new_conv,
			path)
	new_conv.resource_path = path
	new_conv.resource_name = path.get_basename()
	if not discourse_window.are_conversation_options_enabled():
		discourse_window.set_graph_edit_visible(true)
		discourse_window.set_conversation_options_enabled(true)
		discourse_nodes_tree.get_root().collapsed = false
	add_conversation(new_conv, true)
	
	discourse_window.discourse_graph_edit.fix_scroll_offset_for_new(
			discourse_window.size)
	dialog.queue_free()
	listen_offset = true


#region Discourse dialog node tree
func _on_discourse_node_created(node: DiscourseGraphNode) -> void:
	discourse_nodes_tree.create_node(node)


func _on_discourse_tree_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	if item.get_metadata(0)["is_node"]:
		item.select(0)
		discourse_nodes_tree.edit_selected(true)
	else: # Deleting folder
		for sub_item in item.get_children():
			item.remove_child(sub_item)
			item.get_parent().add_child(sub_item)
		item.free()
		_on_conversation_changed()


func _on_discourse_node_activated() -> void:
	var active: TreeItem = discourse_nodes_tree.get_selected()
	if active == null:
		return
	
	var node: DiscourseGraphNode = active.get_metadata(0)["node"]
	discourse_window.discourse_graph_edit.focus_graph_node(node)
	_on_graph_edit_offset_changed(Vector2.ZERO)


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


func set_up_node_structure(structure: Array[Dictionary], level: TreeItem, _map: Dictionary[String, TreeItem]) -> void:
	for item in structure:
		if item["is_node"]:
			level.add_child(_map[item["uuid"]])
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


func _on_discourse_item_edited() -> void:
	var edited: TreeItem = discourse_nodes_tree.get_edited()
	var is_node: bool = edited.get_metadata(0)["is_node"]
	if is_node:
		var node: DiscourseGraphNode = edited.get_metadata(0)["node"]
		if edited.get_text(0) == node.custom_id:
			return
		var new_name: String = get_unique_name_on_tree(edited.get_parent(), edited.get_text(0), edited)
		node.custom_id = new_name
		edited.set_text(0, new_name)
		if node.is_node_localized():
			match node.node_type:
				DiscourseGraphNode.DialogueNodeType.DIALOG:
					localization_nodes_tree.rename_dialog_node(node.get_node_uuid(), new_name)
				DiscourseGraphNode.DialogueNodeType.OPTIONS:
					localization_nodes_tree.rename_options_node(node.get_node_uuid(), new_name)
				DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
					localization_nodes_tree.rename_text_node(node.get_node_uuid(), new_name)
	else:
		var new_name: String = get_unique_name_on_tree(
				edited.get_parent(),
				edited.get_text(0),
				edited)
		edited.set_text(0, new_name)

#endregion


# Loads a conversation into discourse
func open_conversation(conversation: EditorDiscourseDialog) -> void:
	listen_offset = false
	var disc_root: TreeItem = discourse_nodes_tree.get_root()
	for item in disc_root.get_children():
		item.free() # Clear the nodes tree
	
	#locale_map.clear()
	#
	#locale_map.assign(conversation.locale_map.duplicate(true))
	
	discourse_window.load_conversation(conversation) # Load conversation
	
	var node_map: Dictionary[String, TreeItem] = {}
	
	var root: TreeItem = discourse_nodes_tree.get_root()
	
	for item in root.get_children():
		node_map[item.get_metadata(0)["node"].get_node_uuid()] = item
		root.remove_child(item)
	
	set_up_node_structure(conversation.node_structure, discourse_nodes_tree.get_root(), node_map)
	phrases_tree.set_phrase_data(conversation.localized_strings)
	
	for uuid:String in node_map:
		if node_map[uuid].get_tree() == null:
			root.add_child(node_map[uuid])
	
	for language in conversation.locale_map.keys():
		if not languages_tree.has_locale(language):
			languages_tree.create_language(language)
		for region in conversation.locale_map[language]:
			if not languages_tree.has_locale(language, region):
				languages_tree.create_region(language, region)
	
	listen_offset = true


# Adds a conversation into the list, can open it.
func add_conversation(data: EditorDiscourseDialog, open_conv: bool = true) -> void:
	var new_conversation: TreeItem = conversation_tree.get_root().create_child()
	var text: String = data.resource_path.trim_prefix("res://")
	new_conversation.set_text(0, text)
	new_conversation.set_metadata(0, {"resource": data, "unsaved": false, "offset_changed": false})
	
	if open_conv:
		active_conversation_item = new_conversation
		active_conversation = data
		open_conversation(data)


func get_unsaved_conversation_resources() -> Array[EditorDiscourseDialog]:
	var unsaved: Array[EditorDiscourseDialog] = []
	for item in conversation_tree.get_root().get_children():
		var resource: EditorDiscourseDialog = item.get_metadata(0)["resource"]
		if item.get_metadata(0)["unsaved"] or resource.active_offset != resource.scroll_offset or resource.active_zoom != resource.zoom:
			unsaved.append(item.get_metadata(0)["resource"])
	return unsaved


func set_conversations_saved() -> void:
	for item in conversation_tree.get_root().get_children():
		if item.get_metadata(0)["unsaved"]:
			item.set_text(0, item.get_text(0).trim_suffix("*"))
			item.get_metadata(0)["unsaved"] = false
			item.get_metadata(0)["offset_changed"] = false


func save_localizer_data() -> void:
	var active_node: DiscourseGraphNode = localization_nodes_tree.get_active_node()
	#var localizer_language: String = languages_tree.get_active_language()
	#var localizer_region: String = languages_tree.get_active_region()
	match active_node.node_type:
		DiscourseGraphNode.DialogueNodeType.DIALOG:
			discourse_window.set_localization_dialog(
					active_node.get_node_uuid(),
					translation_txt_box.text,
					localizer_language,
					localizer_region)
		DiscourseGraphNode.DialogueNodeType.OPTIONS:
			var options: Array[String] = []
			for option_child in choices_container.get_children():
				options.append(option_child.get_child(2).text)
			
			discourse_window.set_localization_options(
					active_node.get_node_uuid(),
					options,
					localizer_language,
					localizer_region)
		DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
			discourse_window.set_localization_text(
					active_node.get_node_uuid(),
					translation_txt_box.text,
					localizer_language,
					localizer_region)


func _on_save_conversation_pressed() -> void:
	if active_conversation == null:
		return
	
	save_current_dialog()
	active_conversation_item.set_text(0, active_conversation_item.get_text(0).trim_suffix("*"))
	active_conversation_item.get_metadata(0)["unsaved"] = false
	active_conversation_item.get_metadata(0)["offset_changed"] = false


func _on_godot_save_triggered() -> void:
	save_all_dialogs()
	set_conversations_saved()


func save_current_dialog() -> void:
	if $LocalizationContainer.visible and localization_nodes_tree.get_active_node() != null:
		save_localizer_data()
	if not _unsaved and active_conversation_item.get_metadata(0)["offset_changed"]:
		active_conversation.scroll_offset = discourse_window.discourse_graph_edit.scroll_offset
		active_conversation.zoom = discourse_window.discourse_graph_edit.zoom
		active_conversation.save()
		active_conversation_item.get_metadata(0)["offset_changed"] = false
		return
	
	var new_dialog: EditorDiscourseDialog = discourse_window.discourse_graph_edit.get_conversation_data(active_conversation)
	# Obtaining localization reference
	var localizations: Dictionary = discourse_window.localization
	var locale_map: Dictionary[String, PackedStringArray] = discourse_window.locale_map
	
	phrases_tree.save_locale()
	
	new_dialog.base_language = base_language
	new_dialog.zoom = discourse_window.discourse_graph_edit.zoom
	new_dialog.scroll_offset = discourse_window.discourse_graph_edit.scroll_offset
	new_dialog.node_structure = discourse_nodes_tree.get_folder_structure()
	new_dialog.localized_strings = phrases_tree.get_localization_structure()
	new_dialog.locale_map = locale_map.duplicate(true) #discourse_window.locale_map.duplicate(true)
	
	# Adding localization data to localized nodes
	for localized_uuid in localizations.keys():
		# --- If the text is unlocalized ---
		if localizations[localized_uuid].has("common"):
			match localized_uuid["node"].node_type:
				DiscourseGraphNode.DialogueNodeType.DIALOG:
					new_dialog.set_localization_text(
						localized_uuid,
						localizations[localized_uuid]["locaization"]["common"]["dialog"],
						"common")
				DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
					new_dialog.set_localization_text(
						localized_uuid,
						localizations[localized_uuid]["locaization"]["common"]["text"],
						"common")
				DiscourseGraphNode.DialogueNodeType.OPTIONS:
					new_dialog.set_localization_choices(
							localized_uuid,
							localizations[localized_uuid]["locaization"]["common"]["options"],
							"common")
			continue
		
		# --- Or we have a truly localized node ---
		for language in localizations[localized_uuid]["localization"].keys():
			for region in localizations[localized_uuid]["localization"][language].keys():
				match localizations[localized_uuid]["node"].node_type:
					DiscourseGraphNode.DialogueNodeType.DIALOG:
						new_dialog.set_localization_text(
							localized_uuid,
							localizations[localized_uuid]["localization"][language][region]["dialog"],
							language,
							region)
					DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
						new_dialog.set_localization_text(
							localized_uuid,
							localizations[localized_uuid]["localization"][language][region]["text"],
							language,
							region)
					DiscourseGraphNode.DialogueNodeType.OPTIONS:
						new_dialog.set_localization_choices(
								localized_uuid,
								localizations[localized_uuid]["localization"][language][region]["options"],
								language,
								region)
	_unsaved = false
	active_conversation.save()
	active_conversation_item.get_metadata(0)["unsaved"] = false
	active_conversation_item.get_metadata(0)["offset_changed"] = false


func save_all_dialogs() -> void:
	# Update localization active node if on that window.
	if $LocalizationContainer.visible and localization_nodes_tree.get_active_node() != null:
		save_localizer_data()
	
	if active_conversation != null:
		active_conversation.active_zoom = discourse_window.discourse_graph_edit.zoom
		active_conversation.active_offset = discourse_window.discourse_graph_edit.scroll_offset
	
	# Save all unsaved conversations
	for unsaved_conversation:EditorDiscourseDialog in get_unsaved_conversation_resources():
		# Including our active one
		if unsaved_conversation == active_conversation:
			var new_dialog: EditorDiscourseDialog = discourse_window.discourse_graph_edit.get_conversation_data(active_conversation)
			# Obtaining localization reference
			var localizations: Dictionary = discourse_window.localization
			
			new_dialog.base_language = base_language
			new_dialog.node_structure = discourse_nodes_tree.get_folder_structure()
			new_dialog.localized_strings = phrases_tree.get_localization_structure()
			
			# Adding localization data to localized nodes
			for localized_uuid in localizations.keys():
				# --- If the text is unlocalized ---
				if localizations[localized_uuid].has("common"):
					match localized_uuid["node"].node_type:
						DiscourseGraphNode.DialogueNodeType.DIALOG:
							new_dialog.set_localization_text(
								localized_uuid,
								localizations[localized_uuid]["locaization"]["common"]["dialog"],
								"common")
						DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
							new_dialog.set_localization_text(
								localized_uuid,
								localizations[localized_uuid]["locaization"]["common"]["text"],
								"common")
						DiscourseGraphNode.DialogueNodeType.OPTIONS:
							new_dialog.set_localization_choices(
									localized_uuid,
									localizations[localized_uuid]["locaization"]["common"]["options"],
									"common")
					continue
				
				# --- Or we have a truly localized node ---
				for language in localizations[localized_uuid]["localization"].keys():
					for region in localizations[localized_uuid]["localization"][language].keys():
						match localized_uuid["node"].node_type:
							DiscourseGraphNode.DialogueNodeType.DIALOG:
								new_dialog.set_localization_text(
									localized_uuid,
									localizations[localized_uuid]["locaization"][language][region]["dialog"],
									language,
									region)
							DiscourseGraphNode.DialogueNodeType.LOCALIZED_TEXT:
								new_dialog.set_localization_text(
									localized_uuid,
									localizations[localized_uuid]["locaization"][language][region]["text"],
									language,
									region)
							DiscourseGraphNode.DialogueNodeType.OPTIONS:
								new_dialog.set_localization_choices(
										localized_uuid,
										localizations[localized_uuid]["localization"][language][region]["options"],
										language,
										region)
			active_conversation.save()
		else:
			unsaved_conversation.save()
	
	_unsaved = false
	set_all_files_saved()


func set_conversation_active(is_active: bool) -> void:
	discourse_nodes_tree.get_root().collapsed = not is_active
	discourse_window.set_graph_edit_visible(is_active)
	discourse_window.set_conversation_options_enabled(is_active)
	new_folder_button.disabled = not is_active


func set_localizer_locale(language: String, region: String = "base") -> void:
	localizer_language = language
	localizer_region = region
	phrases_tree.set_locale(language, region)


func has_unsaved_files() -> bool:
	for item in conversation_tree.get_root().get_children():
		if item.get_metadata(0)["unsaved"]:
			return true
	return false


func set_all_files_saved() -> void:
	for conv_item in conversation_tree.get_root().get_children():
		if conv_item.get_metadata(0)["unsaved"]:
			conv_item.get_metadata(0)["unsaved"] = false
			conv_item.set_text(0, conv_item.get_text(0).trim_suffix("*"))
