@tool
extends Tree


signal item_id_selected(item_id: StringName)
signal item_id_changed(from: StringName, to: StringName)
signal item_erased(item_id: StringName)
signal pagination_changed

const RESULTS_PER_PAGE: int = 30

var _active_item: StringName = &""
var _items: Dictionary[StringName, TreeItem] = {}
var _search_results: Array[TreeItem] = []
var current_page: int = 0:
	set(i):
		return
	get:
		return _current_page_index + 1
var last_page: int = 0:
	set(i):
		return
	get:
		return _last_page + 1
var _current_page_index: int = 0
var _last_page: int = 0:
	set(p):
		if _last_page == p:
			return
		_last_page = p
		pagination_changed.emit()
var _search_item_query: String = ""
var _search_category_query: String = ""


func ready_plugin() -> void:
	create_item()
	
	item_mouse_selected.connect(_on_item_mouse_selected)
	item_edited.connect(_on_item_edited)
	button_clicked.connect(_on_button_clicked)


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	var item: TreeItem = get_selected()
	_active_item = item.get_metadata(0)["id"]
	item_id_selected.emit(_active_item)


func update_page_count() -> void:
	if 0 < RESULTS_PER_PAGE:
		_last_page = maxi(0, _search_results.size() - 1) / RESULTS_PER_PAGE
	else:
		_last_page = 0


func add_item(item_id: StringName, item_category: StringName = &"") -> bool:
	var id_string: String = String(item_id)
	
	if _items.has(item_id):
		return false
	
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, id_string)
	new_item.set_metadata(0, {"id": item_id, "category": item_category})
	new_item.set_editable(0, true)
	new_item.add_button(
		0,
		get_theme_icon("Remove", "EditorIcons"),
		0,
		false,
		"Erase Item")
	
	_items[id_string] = new_item
	
	if 0 < RESULTS_PER_PAGE:
		get_root().remove_child(new_item)
		var item_query_match: bool = _search_item_query.is_empty() or id_string.containsn(_search_item_query)
		var cat_query_match: bool = _search_category_query.is_empty() or item_category.containsn(_search_category_query)
		
		if item_query_match and cat_query_match:
			_search_results.append(new_item)
			sort_results()
			var item_idx: int = _search_results.find(new_item)
			var page_idx: int = item_idx / RESULTS_PER_PAGE
			
			if page_idx <= _current_page_index:
				_refresh_current_page()
	
		update_page_count() # Update how many pages exist
	else:
		sort_single_item(new_item)
	
	return true


func set_active_item(item_id: StringName) -> void:
	if item_id.is_empty() or _items.has(item_id):
		_active_item = item_id


func set_item_category(item_id: StringName, new_category: StringName) -> void:
	if _items.has(item_id):
		_items[item_id].get_metadata(0)["category"] = new_category


func restore_item(item_id: StringName, category: StringName) -> void:
	if _items.has(item_id):
		return
	
	var item_text: String = String(item_id)
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, String(item_id))
	new_item.set_metadata(0, {"id": item_id, "category": category})
	new_item.set_editable(0, true)
	new_item.add_button(
		0,
		get_theme_icon("Remove", "EditorIcons"),
		0,
		false,
		"Erase Item")
	
	_items[item_id] = new_item
	
	var matches_item: bool = _search_item_query.is_empty() or item_text.containsn(_search_item_query)
	var matches_cat: bool = _search_category_query.is_empty() or category.containsn(_search_category_query)
	
	if matches_item and matches_cat:
		var insert_idx: int = 0
		
		for item in _search_results:
			if item.get_text(0).nocasecmp_to(item_text) > 0:
				break
			insert_idx += 1
		
		_search_results.insert(insert_idx, new_item)
		
		if _current_page_index != insert_idx / RESULTS_PER_PAGE:
			select_item(item_id)
		else:
			sort_single_item(new_item)
	else:
		get_root().remove_child(new_item)


func register_item(item_id: StringName, category: StringName) -> void:
	if _items.has(item_id):
		return
	
	var new_item: TreeItem = get_root().create_child()
	new_item.set_text(0, String(item_id))
	new_item.set_metadata(0, {"id": item_id, "category": category})
	new_item.set_editable(0, true)
	new_item.add_button(
		0,
		get_theme_icon("Remove", "EditorIcons"),
		0,
		false,
		"Erase Item")
	
	_items[item_id] = new_item


func sort_registered_items() -> void:
	if _items.is_empty():
		return
	
	if 0 < RESULTS_PER_PAGE:
		var root: TreeItem = get_root()
		for item in root.get_children():
			root.remove_child(item)
		_search_results.assign(_items.values())
		_current_page_index = 0
		update_page_count()
		sort_results()
		var slice: Array[TreeItem] = _search_results.slice(
			0,
			RESULTS_PER_PAGE)
		
		clear_items()
		
		for item in slice:
			root.add_child(item)
	else:
		sort_all_items()


func select_item(item_id: StringName, emit_selected: bool = false) -> void:
	if not _items.has(item_id):
		return
	
	_active_item = item_id
	var target: TreeItem = _items[item_id]
	
	if 0 < RESULTS_PER_PAGE:
		var idx: int = _search_results.find(_items[item_id]) # 53
		
		if idx < 0:
			return
		
		var page: int = idx / RESULTS_PER_PAGE
		
		if page != _current_page_index:
			clear_items()
			var root: TreeItem = get_root()
			var slice: Array[TreeItem] = _search_results.slice(
				page * RESULTS_PER_PAGE,
				(page + 1) * RESULTS_PER_PAGE)
			for item in slice:
				root.add_child(item)
			_current_page_index = page
	
		target.select(0)
	else:
		target.select(0)
	
	if emit_selected:
		item_selected.emit(item_id)


func has_previous_page() -> bool:
	if 0 < RESULTS_PER_PAGE:
		return 1 < current_page
	return false


func has_next_page() -> bool:
	if 0 < RESULTS_PER_PAGE:
		return current_page < last_page
	return false


func next_page() -> void:
	if last_page <= current_page:
		_current_page_index = _last_page
		return
	
	go_to_page(current_page + 1)


func previous_page() -> void:
	if _current_page_index <= 0:
		_current_page_index = 0
		return
	
	go_to_page(current_page - 1)


func go_to_page(page: int) -> void:
	if RESULTS_PER_PAGE <= 0 or page <= 0 or last_page < page or page == current_page:
		return
	
	var page_index: int = page - 1
	var root: TreeItem = get_root()
	var slice: Array[TreeItem] = _search_results.slice(
		page_index * RESULTS_PER_PAGE,
		(page_index + 1) * RESULTS_PER_PAGE)
	
	clear_items()
	
	for item in slice:
		root.add_child(item)
	
	if not _active_item.is_empty() and _items[_active_item].get_parent() == root:
		_items[_active_item].select(0)
	
	_current_page_index = page_index


func remove_items(items: Array[String]) -> void:
	for item in items:
		if _items.has(item):
			_items[item].free()
			_items.erase(item)


func _on_button_clicked(item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	if id == 0:
		var item_id: StringName = item.get_metadata(0)["id"]
		_erase_item(item_id)
		item_erased.emit(item_id)


func _erase_item(item_id: StringName) -> void:
	if not _items.has(item_id):
		return
	
	var target: TreeItem = _items[item_id]
	var search_idx: int = _search_results.find(target)
	if _active_item == item_id:
		_active_item = &""
	_items.erase(item_id)
	target.free()
	
	if search_idx < 0:
		update_page_count()
		return
	
	_search_results.remove_at(search_idx)
	var page_idx: int = search_idx / RESULTS_PER_PAGE
	if page_idx <= _current_page_index:
		_refresh_current_page()
	update_page_count()


func _on_item_edited() -> void:
	var edited: TreeItem = get_edited()
	var prev_text: String = String(edited.get_metadata(0)["id"])
	var new_text: String = get_valid_id(
		edited.get_text(0),
		edited.get_metadata(0)["id"])
	
	if new_text == prev_text:
		return
	
	var old_id: StringName = edited.get_metadata(0)["id"]
	var new_id: StringName = StringName(new_text)
	
	edited.set_text(0, new_text)
	edited.get_metadata(0)["id"] = new_id
	
	_items[new_id] = _items[old_id]
	_items.erase(old_id)
	
	item_id_changed.emit(old_id, new_id)


func get_valid_id(desired: String, skip_item: StringName = &"") -> String:
	var skip: TreeItem = null if skip_item.is_empty() or not _items.has(skip_item) else _items[skip_item]
	var all_ids: Dictionary[String, Variant] = {}
	
	var base: String = desired
	var modified: String = desired
	var trailing_data: Dictionary = StringUtils.get_trailing_integer(base)
	var iteration: int = trailing_data["integer"]
	if trailing_data["has_integer"]:
		base = desired.trim_suffix(str(iteration))
	
	for tree in _items.values():
		if tree == skip:
			continue
		all_ids[tree.get_text(0)] = null
	
	all_ids.erase(skip.get_text(0))
	
	while all_ids.has(modified):
		iteration += 1
		modified = base + str(iteration)
	
	return modified


func sort_single_item(item: TreeItem) -> void:
	if item.get_parent() == null:
		return
	
	var before_item: TreeItem = null
	
	for child in get_root().get_children():
		if child == item:
			continue # We ignore the item we just added
		if item.get_text(0).naturalnocasecmp_to(child.get_text(0)) < 0:
			before_item = child
			break
	
	if before_item != null:
		item.move_before(before_item)
	else:
		if item.get_index() != get_root().get_child_count() - 1:
			item.move_after(get_root().get_child(-1))


func sort_all_items() -> void:
	var all_items: Array[TreeItem] = get_root().get_children()
	var item_count: int = all_items.size()
	
	if item_count < 2:
		return
	
	all_items.sort_custom(
		func (a:TreeItem, b:TreeItem) -> bool:
			return a.get_text(0).naturalnocasecmp_to(b.get_text(0)) < 0)
	
	if all_items[0].get_index() != 0:
		all_items[0].move_before(get_root().get_first_child())
	
	for idx in range(1, item_count):
		all_items[idx].move_after(all_items[idx-1])


func get_items() -> Array[String]:
	var all_items: Array[String] = []
	for item in _items.values():
		all_items.append(item.get_text(0))
	return all_items


func clear_items() -> void:
	var root: TreeItem = get_root()
	for item in root.get_children():
		root.remove_child(item)


func clear_entries() -> void:
	for item in _items.values():
		item.free()
	_items.clear()
	_active_item = &""
	clear()
	create_item()


func sort_results() -> void:
	_search_results.sort_custom(
		func (a:TreeItem,b:TreeItem) -> bool:
			return a.get_text(0).naturalnocasecmp_to(b.get_text(0)) < 0)


func clear_search() -> void:
	if _search_item_query.is_empty() and _search_category_query.is_empty():
		return
	search_for("", "")


func search_for(text: String, on_category: String) -> void:
	if 0 < RESULTS_PER_PAGE:
		_search_with_pages(text, on_category)
	else:
		_search_without_pages(text, on_category)
	_search_item_query = text
	_search_category_query = on_category


func _search_without_pages(text: String, on_category: String) -> void:
	if text.is_empty() and on_category.is_empty():
		for item in get_root().get_children():
			item.visible = true
	elif text.is_empty():
		if on_category == "*":
			for item in get_root().get_children():
				item.visible = item.get_metadata(0)["category"].is_empty()
		else:
			for item in get_root().get_children():
				item.visible = item.get_metadata(0)["category"].containsn(on_category)
	elif on_category.is_empty():
		for item in get_root().get_children():
			item.visible = item.get_text(0).containsn(text)
	else:
		for item in get_root().get_children():
			item.visible = item.get_text(0).containsn(text) and item.get_metadata(0)["category"].containsn(on_category)


func _search_with_pages(text: String, on_category: String) -> void:
	var empty: bool = text.is_empty()
	clear_items()
	_current_page_index = 0
	_search_results.clear()
	
	if text.is_empty() and on_category.is_empty():
		_search_results.assign(_items.values())
	elif text.is_empty():
		if on_category == "*":
			for item:TreeItem in _items.values():
				if item.get_metadata(0)["category"].is_empty():
					_search_results.append(item)
		else:
			for item:TreeItem in _items.values():
				if item.get_metadata(0)["category"].containsn(on_category):
					_search_results.append(item)
	elif on_category.is_empty():
		for item:TreeItem in _items.values():
			if item.get_text(0).containsn(text):
				_search_results.append(item)
	else:
		for item:TreeItem in _items.values():
			if item.get_text(0).containsn(text) and item.get_metadata(0)["category"].containsn(on_category):
				_search_results.append(item)
	
	update_page_count()
	
	if _search_results.is_empty():
		return
	
	sort_results()
	
	var root: TreeItem = get_root()
	var slice: Array[TreeItem] = _search_results.slice(
		_current_page_index * RESULTS_PER_PAGE,
		RESULTS_PER_PAGE * (_current_page_index + 1))
	
	for r_item in slice:
		root.add_child(r_item)


func _refresh_current_page() -> void:
	clear_items()
	var root: TreeItem = get_root()
	var slice: Array[TreeItem] = _search_results.slice(
			_current_page_index * RESULTS_PER_PAGE,
			(_current_page_index + 1) * RESULTS_PER_PAGE)
	for item in slice:
		root.add_child(item)
	if not _active_item.is_empty() and _items[_active_item].get_parent() == root:
		_items[_active_item].select(0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for item in _items.values():
			item.free()
