class_name NFCharacterManager
extends RefCounted
## Manages [CharacterSheet] loading, overrides and character mods.

var _characters: Dictionary[StringName, String] = {}
var _character_modifiers: Dictionary[StringName, Dictionary] = {}
var _character_overrides: Dictionary[StringName, String] = {}


## Retuns a [CharacterSheet] via their [param character_id] with modifications
## applied if available.
## Returns [code]null[/code] if the ID is not registered.
func get_character(character_id: StringName, force_reapply_mods: bool = false) -> CharacterSheet:
	if not _characters.has(character_id):
		return null
	
	var using_override: bool = _character_overrides.has(character_id)
	
	var char_sheet: CharacterSheet = null
	
	if using_override:
		var res_load = ResourceLoader.load(_character_overrides[character_id], "", ResourceLoader.CACHE_MODE_REPLACE_DEEP) if force_reapply_mods else load(_character_overrides[character_id])
		if res_load != null and res_load is CharacterSheet:
			char_sheet = res_load
		else:
			NFPluginGameHandler._log_msg(
					"persona",
					"Error while loading override '%s'. Using default resource." % _character_overrides[character_id],
					NFPluginGameHandler._LogLevel.ERROR)
			res_load = ResourceLoader.load(_characters[character_id], "", ResourceLoader.CACHE_MODE_REPLACE_DEEP) if force_reapply_mods else load(_characters[character_id])
			if res_load != null and res_load is CharacterSheet:
				char_sheet = res_load
	else:
		var res_load = ResourceLoader.load(_characters[character_id], "", ResourceLoader.CACHE_MODE_REPLACE_DEEP) if force_reapply_mods else load(_characters[character_id])
		if res_load != null and res_load is CharacterSheet:
			char_sheet = res_load
	
	if char_sheet == null:
		NFPluginGameHandler._log_msg(
				"persona",
				"Error while loading character '%s'" % character_id,
				NFPluginGameHandler._LogLevel.ERROR)
		return null
	
	if char_sheet.id != character_id:
		char_sheet.id = character_id
	
	char_sheet.initialize_objects()
	
	if _character_modifiers.has(character_id) and (not char_sheet._mods_applied or force_reapply_mods):
		for mod_id in _character_modifiers[character_id]["order"]:
			if _character_modifiers[character_id]["mods"][mod_id]["callable"].is_valid():
				_character_modifiers[character_id]["mods"][mod_id]["callable"].call(char_sheet)
		char_sheet._mods_applied = true
	
	return char_sheet


## Registers an override for a character with id [param character_id].
## When this character is going to be loaded, the file [param resource_path]
## is used instead.
func override_character(character_id: StringName, resource_path: String) -> void:
	resource_path = resource_path.strip_edges().simplify_path()
	if resource_path.is_empty():
		_character_overrides.erase(character_id)
	elif not FileAccess.file_exists(resource_path):
		NFPluginGameHandler._log_msg(
				"persona",
				"Override '%s' not found." % resource_path,
				NFPluginGameHandler._LogLevel.ERROR)
	else:
		_character_overrides[character_id] = resource_path


## Registers the resource with [param path] with the ID [param character_id]
## allowing the use of obtaining the character via
## [method CharacterManager.get_character].[br]
## It is not reccomended to override existing characters with this method
## instead use [method CharacterManager.override_character] as it will
## allow the original character to be used if the override fails loading.
func register_character(character_id: StringName, path: String) -> void:
	_characters[character_id] = path


## Returns if a character with ID [param character_id] is registered.
func has_character(character_id: StringName) -> bool:
	return _characters.has(character_id)


## Returns [code]true[/code] if the [param character_id] has an override.
func has_override(character_id: StringName) -> bool:
	return _character_overrides.has(character_id)


## Returns the override path [param for_character] if it exists.
func get_override(for_character: StringName) -> String:
	if _character_overrides.has(for_character):
		return _character_overrides[for_character]
	return ""


## Removes a character from the registry, making it no longer able to be
## fetched via [method CharacterManager.get_character]
func remove_character(id: StringName) -> void:
	_characters.erase(id)


## Registers a [Callable] with ID [param mod_id] to modify [param character_id]
## before returned with [method CharacterManager.get_character].
## The callable must have a single argument of type [CharacterSheet].
## Modifications must be done directly to the object in-place.[br]
## The [param order] argument can be passed which will determine
## the execution sequence. A value less than 0 will append the modifier
## to the end of the execution order.[br]
## The [param depends_on] argument can be used to ensure the given callable
## executes after another modification. The [param order] will be respected.
func register_character_modifiers(character_id: StringName, mod_id: StringName, mod_callable: Callable, order: int = -1, depends_on: StringName = &"") -> void:
	if character_id.is_empty():
		NFPluginGameHandler._log_msg(
				"persona",
				"Attempted to register a character mod with empty ID. Skipping",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	if not mod_callable.is_valid():
		_character_modifiers.erase(character_id)
		return
	
	if _is_dependency_circular(character_id, mod_id, depends_on):
		NFPluginGameHandler._log_msg(
				"persona",
				"Circular dependency detected when adding mod %s to %s. Skipping mod registry." % [mod_id, character_id],
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	
	if not _character_modifiers.has(character_id):
		_character_modifiers[character_id] = {
			"order": ArrayUtils.create_typed(TYPE_STRING_NAME),
			"mods": DictUtils.create_typed(TYPE_STRING_NAME, TYPE_DICTIONARY)}
	
	var new_mod: bool = not _character_modifiers[character_id]["mods"].has(mod_id)
	var trigger_sort: bool = true if new_mod else -1 < order and _character_modifiers[character_id]["mods"][mod_id]["order"] != order
	
	DictUtils.set_nested_value(
			_character_modifiers,
			[character_id, "mods", mod_id], # Key path
			{"order": order, "callable": mod_callable, "dependency": depends_on}, # Value set to
			true) # Create the mod_id dictionary if it doesn't exist
	
	if new_mod:
		_character_modifiers[character_id]["order"].append(mod_id)
	
	if trigger_sort:
		_sort_mods(character_id)


func _sort_mods(for_character: StringName) -> void:
	var mods_with_dependencies: Dictionary[StringName, Array] = {}
	var independent_mods: Array[StringName] = []
	var mods: Dictionary[StringName, Dictionary] = _character_modifiers[for_character]["mods"]
	var final_order: Array[StringName] = []
	var sorting_lambda: Callable = func(a:StringName,b:StringName) -> bool:
		var order_a: int = mods[a]["order"]
		var order_b: int = mods[b]["order"]
		if order_a == order_b:
			return false
		elif order_a < 0:
			return false
		elif order_b < 0:
			return true
		else:
			return order_a < order_b
	var process_mod: Callable = func(current_id: StringName, self_ref: Callable) -> void:
			if final_order.has(current_id):
				return
			
			final_order.append(current_id)
			
			if mods_with_dependencies.has(current_id):
				for child_id in mods_with_dependencies[current_id]:
					self_ref.call(child_id, self_ref)
	
	for mod_id in mods.keys():
		var dependency: StringName = mods[mod_id]["dependency"]
		if dependency.is_empty() or not mods.has(dependency):
			independent_mods.append(mod_id)
		else:
			if not mods_with_dependencies.has(dependency):
				mods_with_dependencies[dependency] = []
			mods_with_dependencies[dependency].append(mod_id)
	
	independent_mods.sort_custom(sorting_lambda)
	for after_id in mods_with_dependencies.keys():
		mods_with_dependencies[after_id].sort_custom(sorting_lambda)
	
	for mod_id in independent_mods:
		process_mod.call(mod_id, process_mod)
	
	if final_order.size() < mods.size():
		for mod_id in mods.keys():
			if not final_order.has(mod_id):
				NFPluginGameHandler._log_msg(
						"persona",
						"Circular dependency detected for mod '%s'. Forcing moving to last of execution order." % mod_id,
						NFPluginGameHandler._LogLevel.WARNING)
				final_order.append(mod_id)
	
	_character_modifiers[for_character]["order"].assign(final_order)


func _is_dependency_circular(character_id: StringName, mod_id: StringName, depends_on: StringName, _visited: Array[StringName] = []) -> bool:
	if depends_on.is_empty() or not _character_modifiers.has(character_id) or not _character_modifiers[character_id]["mods"].has(depends_on):
		return false
	
	if _visited.has(depends_on):
		NFPluginGameHandler._log_msg(
				"persona",
				"Pre-existing cycle detected at '%s'. Aborting check." % depends_on,
				NFPluginGameHandler._LogLevel.ERROR)
		return true
	
	_visited.append(depends_on)
	
	var mods: Dictionary[StringName, Dictionary] = _character_modifiers[character_id]["mods"]
	
	var dependency: StringName = mods[depends_on]["dependency"]
	
	if dependency.is_empty():
		return false
	elif dependency == mod_id:
		return true
	else:
		return _is_dependency_circular(character_id, mod_id, dependency, _visited)
