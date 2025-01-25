@tool
extends IDTree


signal quest_selected(quest_id: String, is_main: bool)
signal quest_id_changed(from: String, to: String, is_main: bool)
signal quest_deleted(quest_id: String, is_main: bool)
signal quest_stage_deleted(quest_id: String, stage_idx: int, is_main: bool)
signal quest_pool_item_deleted(quest_id: String, stage_idx: int, item_idx: int)
signal quest_created(quest_id: String, is_main: bool)
signal quest_stage_selected(quest_id: String, stage_idx: int, is_main: bool, pool_idx: int)
signal quest_stage_created(quest_id: String, quest_idx: int, is_main: bool, stage_title: String)
signal quest_stage_pool_item_created(quest_id: String, stage_id: int, pool_idx: int)

#signal quest_created(quest_id: String)
#signal quest_renamed(from: String, to: String)

const NEW_FILE = preload("res://addons/nexus_forge/common_icons/new_file.svg")
const TRASH_BIN = preload("res://addons/nexus_forge/common_icons/trash_bin.svg")

# Row IDs
const QUEST_ID: int = 0
const STAGE_ID: int = 1
#const ITEMS_ID: int = 2
#const VARIABLES_ID: int = 3
#const TRIGGERS_ID: int = 4
const STAGE_POOL: int = 5

# Button IDs
const NEW_MAIN_QUEST: int = 0
const NEW_STAGE_MAIN: int = 1
const DELETE_QUEST_MAIN: int = 2
const DELETE_STAGE_MAIN: int = 3
const NEW_BOILER_QUEST: int = 4
const NEW_STAGE_BOILER: int = 5
const NEW_STAGE_BOILER_POOL: int = 9
const DELETE_QUEST_BOILER: int = 6
const DELETE_STAGE_BOILER: int = 7
const DELETE_STAGE_BOILER_POOL: int = 8

var root_tree: TreeItem = null
var main_header: TreeItem
var boiler_header: TreeItem


func _ready() -> void:
	root_tree = create_item()
	#item_selected.connect(on_item_selected)
	
	main_header = root_tree.create_child()
	boiler_header = root_tree.create_child()
	
	main_header.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	boiler_header.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	
	main_header.set_text(0, "Main Quests")
	boiler_header.set_text(0, "Boiler Quests")
	
	main_header.add_button(0, NEW_FILE, NEW_MAIN_QUEST, false, "New Main Quest")
	boiler_header.add_button(0, NEW_FILE, NEW_BOILER_QUEST, false, "New Boiler Quest")
	
	main_header.set_metadata(0, {"type": -1})
	boiler_header.set_metadata(0, {"type": -1})
	
	button_clicked.connect(_on_button_pressed)
	item_edited.connect(on_item_edited)
	item_selected.connect(_on_item_selected, CONNECT_DEFERRED)


func create_main_quest(quest_id: String = "") -> String:
	var verified_id: String = get_valid_main_id(quest_id)
	var new_main_quest: TreeItem = main_header.create_child()
	new_main_quest.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_main_quest.set_text(0, verified_id)
	new_main_quest.add_button(0, NEW_FILE, NEW_STAGE_MAIN, false, "Create Stage")
	new_main_quest.add_button(0, TRASH_BIN, DELETE_QUEST_MAIN, false, "Delete Quest")
	new_main_quest.set_editable(0, true)
	new_main_quest.set_metadata(0, {"type": QUEST_ID, "is_main": true, "id": verified_id})
	
	if main_header.collapsed:
		main_header.collapsed = false
	return verified_id


func create_boiler_quest(quest_id: String = "") -> String:
	var verified_id: String = get_valid_boiler_id(quest_id)
	var new_boiler_quest: TreeItem = boiler_header.create_child()
	new_boiler_quest.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_boiler_quest.set_text(0, verified_id)
	new_boiler_quest.add_button(0, NEW_FILE, NEW_STAGE_BOILER_POOL, false, "Create Pool")
	new_boiler_quest.add_button(0, TRASH_BIN, DELETE_QUEST_BOILER, false, "Delete Quest")
	new_boiler_quest.set_editable(0, true)
	new_boiler_quest.set_metadata(0, {"type": QUEST_ID, "is_main": false, "id": verified_id})
	
	if boiler_header.collapsed:
		boiler_header.collapsed = false
	return verified_id


func create_main_stage(on_quest: TreeItem, stage_title: String = "") -> void:
	var new_stage: TreeItem = on_quest.create_child()
	new_stage.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	new_stage.set_text(0, stage_title)
	new_stage.add_button(0, TRASH_BIN, DELETE_STAGE_MAIN, false, "Delete Stage")
	new_stage.set_metadata(0, {"type": STAGE_ID, "is_main": true})
	#var item_tree: TreeItem = new_stage.create_child()
	#var var_tree: TreeItem = new_stage.create_child()
	#var trigger_tree: TreeItem = new_stage.create_child()
	
	#item_tree.set_text(0, "Items")
	#var_tree.set_text(0, "Variables")
	#trigger_tree.set_text(0, "Triggers")
	
	#item_tree.set_metadata(0, {"type": ITEMS_ID})
	#var_tree.set_metadata(0, {"type": VARIABLES_ID})
	#trigger_tree.set_metadata(0, {"type": TRIGGERS_ID})
	
	new_stage.collapsed = true


func create_boiler_stage_pool(on_quest: TreeItem) -> int:
	var new_stage: TreeItem = on_quest.create_child()
	new_stage.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	create_boiler_stage(new_stage)
	new_stage.set_text(0, "Stage Pool")
	new_stage.set_metadata(0, {"type": STAGE_POOL})
	new_stage.add_button(0, NEW_FILE, NEW_STAGE_BOILER, false, "Add to Pool")
	new_stage.add_button(0, TRASH_BIN, DELETE_STAGE_BOILER_POOL, false, "Delete Pool")
	return new_stage.get_index()


func create_boiler_stage(on_pool: TreeItem, stage_title: String = "") -> void:
	var new_stage: TreeItem = on_pool.create_child()
	#var item_tree: TreeItem = new_stage.create_child()
	#var var_tree: TreeItem = new_stage.create_child()
	#var trigger_tree: TreeItem = new_stage.create_child()
	
	new_stage.set_text(0, stage_title if not stage_title.is_empty() else "New Stage")
	new_stage.set_metadata(0, {"type": STAGE_ID, "is_main": false})
	
	#item_tree.set_text(0, "Items")
	#var_tree.set_text(0, "Variables")
	#trigger_tree.set_text(0, "Triggers")
	
	#item_tree.set_metadata(0, {"type": ITEMS_ID})
	#var_tree.set_metadata(0, {"type": VARIABLES_ID})
	#trigger_tree.set_metadata(0, {"type": TRIGGERS_ID})
	new_stage.add_button(0, TRASH_BIN, DELETE_STAGE_BOILER, false, "Delete Stage")
	new_stage.collapsed = true
	
	on_pool.set_range_config(0, 1, on_pool.get_child_count(), 1)
	

func get_valid_main_id(desired_id: String, skip_tree: TreeItem = null) -> String:
	desired_id = desired_id.strip_edges()
	desired_id = desired_id if not desired_id.is_empty() else "main_quest"
	var modified_id: String = desired_id
	var iteration: int = 0
	
	while has_main_id(modified_id, skip_tree):
		iteration += 1
		modified_id = desired_id + str(iteration)
	
	return modified_id


func get_valid_boiler_id(desired_id: String, skip_tree: TreeItem = null) -> String:
	desired_id = desired_id if not desired_id.is_empty() else "boiler_quest"
	var modified_id: String = desired_id
	var iteration: int = 0
	
	while has_boiler_id(modified_id, skip_tree):
		iteration += 1
		modified_id = desired_id + str(iteration)
	
	return modified_id


func has_main_id(id_string: String, skip_tree: TreeItem) -> bool:
	for main_quest in main_header.get_children():
		if main_quest == skip_tree:
			continue
		if main_quest.get_text(0) == id_string:
			return true
	return false


func has_boiler_id(id_string: String, skip_tree: TreeItem) -> bool:
	for boiler_quest in boiler_header.get_children():
		if boiler_quest == skip_tree:
			continue
		if boiler_quest.get_text(0) == id_string:
			return true
	return false


func search_for_text(search_text: String) -> void:
	var clean_text: String = search_text.strip_edges().to_upper()
	for main_quest in main_header.get_children():
		var child_visible: bool = false
		for stage in main_quest.get_children():
			stage.visible = clean_text.is_empty() or stage.get_text(0).containsn(clean_text)
			if not child_visible and stage.visible:
				child_visible = true
		main_quest.visible = child_visible or clean_text.is_empty() or main_quest.get_text(0).containsn(clean_text)
	
	for boiler_quest in boiler_header.get_children():
		var child_visible: bool = false
		for stage_pool in boiler_header.get_children():
			var pool_visible: bool = false
			for stage_item in stage_pool.get_children():
				stage_item.visible = clean_text.is_empty() or stage_item.get_text(0).containsn(clean_text)
				if not pool_visible and stage_item.visible:
					pool_visible = true
			stage_pool.visible = pool_visible or clean_text.is_empty() or clean_text.is_empty()
			child_visible = stage_pool.visible
		boiler_quest.visible = child_visible or clean_text.is_empty() or boiler_quest.get_text(0).containsn(clean_text)


func _on_item_selected() -> void:
	var selected: TreeItem = get_selected()
	var selected_meta: Dictionary = selected.get_metadata(0)
	
	match selected_meta["type"]:
		QUEST_ID:
			quest_selected.emit(selected.get_text(0), selected_meta["is_main"])
		STAGE_ID:
			quest_stage_selected.emit(
				selected.get_parent().get_text(0) if selected_meta["is_main"] else selected.get_parent().get_parent().get_text(0),
				selected.get_index() if selected_meta["is_main"] else selected.get_parent().get_index(),
				selected_meta["is_main"],
				-1 if selected_meta["is_main"] else selected.get_index())


func set_main_quest_stage_title(quest_id: String, stage_id: int, title: String) -> void:
	for main_quest in main_header.get_children():
		if main_quest.get_text(0) == quest_id:
			main_quest.get_child(stage_id).set_text(0, title)
			break


func set_boiler_quest_stage_title(quest_id: String, stage_id: int, pool_idx: int, title: String) -> void:
	for side_quest in boiler_header.get_children():
		if side_quest.get_text(0) == quest_id:
			side_quest.get_child(stage_id).get_child(pool_idx).set_text(0, title)
			break


func get_main_quest_stage_title(quest_id: String, stage_id: int) -> String:
	for main_quest in main_header.get_children():
		if main_quest.get_text(0) == quest_id:
			return main_quest.get_child(stage_id).get_text(0)
	return ""


func get_boiler_quest_stage_title(quest_id: String, stage_id: int, pool_idx: int) -> String:
	for side_quest in boiler_header.get_children():
		if side_quest.get_text(0) == quest_id:
			return side_quest.get_child(stage_id).get_child(pool_idx).get_text(0)
	return ""




func select_quest(quest_id: String, is_main: bool) -> void:
	if is_main:
		for main_quest in main_header.get_children():
			if main_quest.get_text(0) == quest_id:
				main_quest.select(0)
				break
	else:
		for boiler_quest in boiler_header.get_children():
			if boiler_quest.get_text(0) == quest_id:
				boiler_quest.select(0)
				break
	#if  == -1:
		#return
	#elif
		#quest_selected.emit(selected.get_text(0))
#
#
#func add_item(quest_id: String) -> void:
	#var new_quest: TreeItem = create_item(root_tree)
	#new_quest.set_text(0, validate_id(root_tree, quest_id, new_quest))
	#new_quest.add_button(0, TRASH_BIN, 0, false, "Delete quest")
	#new_quest.set_metadata(0, new_quest.get_text(0))
	#new_quest.set_editable(0, true)
	#quest_created.emit(new_quest.get_text(0))
#
#
#func clear_items() -> void:
	#for child in root_tree.get_children():
		#child.free()
#
#
func on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var edited_meta: Dictionary = edited.get_metadata(0)
	match edited_meta["type"]:
		QUEST_ID:
			var prev_id: String = edited_meta["id"]
			var new_id: String = get_valid_main_id(edited.get_text(0), edited) if edited_meta["is_main"] else get_valid_boiler_id(edited.get_text(0), edited)
			
			if prev_id == new_id:
				return
			
			edited.set_text(0, new_id)
			edited_meta["id"] = new_id
			quest_id_changed.emit(prev_id, edited.get_text(0), edited_meta["is_main"])


func _on_button_pressed(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if id == DELETE_QUEST_MAIN:
		quest_deleted.emit(item.get_text(0), item.get_metadata(0)["is_main"])
		item.free()
	elif id == NEW_MAIN_QUEST:
		quest_created.emit(create_main_quest(), true)
	elif id == NEW_STAGE_MAIN:
		create_main_stage(item, "New Stage")
		quest_stage_created.emit(item.get_text(0), -1, true, "New Stage")
	elif id == DELETE_STAGE_MAIN:
		quest_stage_deleted.emit(item.get_parent().get_text(0), item.get_index(), item.get_parent().get_parent() == main_header)
		item.free()
	elif id == NEW_BOILER_QUEST:
		quest_created.emit(create_boiler_quest(), false)
	elif id == NEW_STAGE_BOILER_POOL:
		var stage_id: int = create_boiler_stage_pool(item)
		quest_stage_created.emit(item.get_text(0), -1, false, "")
		quest_stage_pool_item_created.emit(item.get_text(0), stage_id, 0, "New Stage")
	elif id == NEW_STAGE_BOILER: # Boiler Item
		create_boiler_stage(item)
		quest_stage_pool_item_created.emit(item.get_parent().get_text(0), item.get_index(), -1, "New Stage")
	elif id == DELETE_STAGE_BOILER:
		var item_parent: TreeItem = item.get_parent()
		quest_pool_item_deleted.emit(
				item.get_parent().get_parent().get_text(0), # Quest ID
				item_parent.get_index(), # Stage IDX
				item.get_index()) # Item IDX
		item.free()
		if item_parent.get_child_count() == 0:
			item_parent.free()
	elif id == DELETE_QUEST_BOILER:
		quest_deleted.emit(item.get_text(0), item.get_parent() == main_header)
		item.free()
	elif id == DELETE_STAGE_BOILER_POOL:
		quest_stage_deleted.emit(item.get_parent().get_text(0), item.get_index(), item.get_parent().get_parent() == main_header)
		




#func search_item(search: String) -> void:
	#for quest in root_tree.get_children():
		#quest.visible = search.is_empty() or quest.get_text(0).containsn(search)
#
#
#func get_quests() -> Array:
	#var quests: Array = []
	#for quest in root_tree.get_children():
		#quests.append(quest.get_text(0))
	#return quests
