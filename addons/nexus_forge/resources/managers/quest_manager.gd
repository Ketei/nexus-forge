class_name NFQuestManager
extends RefCounted
## An object to manage and keep track of quests.
##
## This object can keep track of the states of quests and progress them automatically
## as well as keeping a log of all finished quests along with if it was completed
## successfully or failed.[br]
## It also provides methods to get data for storage and restoring it.


## Emitted when a quest is started via [method start_quest].
signal quest_started(quest_id: StringName)
## Emitted when a quest progresses. Emitted too when a quest starts with [param to_stage]
## being the entry stage.
signal quest_progressed(quest_id: StringName, to_stage: StringName)
## Emitted when a quest finishes either automatically or by using [method complete_quest]
signal quest_finished(quest_id: StringName)

## Emitted when a quest stage is completed.
signal stage_completed(quest_id: StringName, stage_id: StringName, successfully: bool)
## Emitted when a stage objective is completed.
signal objective_completed(quest_id: StringName, stage_id: StringName, objective_id: StringName, successfully: bool)

## Emits when a quest/stage/objective is completed either successfully or not.
signal quest_event_triggered(event_data: Dictionary)

enum SuccessStatus{
	SUCCESS,
	FAILURE,
	UNKNOWN,
}

var _active_quests: Dictionary[StringName, NFQuestEntry] = {}
var _static_progress: Dictionary[String, Variant] = {}

## The quest log in which the history of quest started and finished is stored.
var Log: NFQuestLog = NFQuestLog.new()


var _quest_modifiers: Dictionary[StringName, Dictionary] = {}


func _get(property: StringName) -> Variant:
	if _active_quests.has(property):
		return property
	var invalid: NFQuestEntry = NFQuestEntry.new()
	invalid._flags = BitUtils.set_bit_index(0, 63, true)
	return invalid


## Starts a quest. If [param auto_advance_stages] is [code]true[/code]
## then the progression will be made automatically.[br]
## [b]Note:[/b] This manager can only know when a stage is completed [b]successfully[/b].
## To fail a stage and move to the fail flow, use [method complete_stage] and
## pass [param success] as [code]false[/code].
## And it'll auto-advance to the failed quest path if [param auto_advance_stages]
## was enabled.
func start_quest(quest: Quest, auto_advance_stages: bool) -> bool:
	if _active_quests.has(quest.id):
		NFPluginGameHandler._log_msg(
				"odyssey",
				"Coulnd't start quest. Quest with ID '%s' is already active." % quest.id,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	elif not quest.has_stage(quest.entry_stage):
		NFPluginGameHandler._log_msg(
				"odyssey",
				"Coulnd't start quest '%s'. Quest doesn't have starting stage '%s'" % [quest.id, quest.entry_stage],
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	if _quest_modifiers.has(quest.id) and not quest._mods_applied:
		for id in _quest_modifiers[quest.id]["order"]:
			if _quest_modifiers[quest.id]["mods"][id]["callable"].is_valid():
				_quest_modifiers[quest.id]["mods"][id]["callable"].call(quest)
	
	var new_entry: NFQuestEntry = NFQuestEntry.new()
	new_entry.resource = quest
	new_entry.auto_advance_stages = auto_advance_stages
	new_entry._flags = BitUtils.set_bit_index(0, 0, true)
	_active_quests[quest.id] = new_entry
	new_entry.objective_state_changed.connect(_on_quest_objective_state_changed)
	
	var quest_entry: NFQuestLog.NFQuestLogEntry = Log.set_entry(quest.id)
	for stage_id in quest.stages():
		var stage_entry: NFQuestLog.NFQuestLogStageEntry = quest_entry.set_entry(stage_id)
		for objective_id in quest.get_stage(stage_id).objectives():
			stage_entry.set_entry(objective_id)
	
	quest_started.emit(quest.id)
	quest_progressed.emit(quest.id, quest.entry_stage)
	
	if not new_entry.set_stage(quest.entry_stage, _static_progress):
		NFPluginGameHandler._log_msg(
				"odyssey",
				"Failed to set stage '%s' for quest with ID '%s'" % [quest.entry_stage, quest.id],
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	_check_stage_auto_advance(quest.id)
	
	return true


## Adds a quest entry to the manager but does NOT emit signals nor adds entries
## in the [member QuestManager.Log].[br]
## Intended to restore programmatically generated
## quests before calling [method QuestManager.restore_state].
func add_quest_resource(quest: Quest, auto_advance_stages: bool, apply_mods: bool = true) -> bool:
	if _active_quests.has(quest.id):
		return false
	
	if _quest_modifiers.has(quest.id) and not quest._mods_applied and apply_mods:
		for id in _quest_modifiers[quest.id]["order"]:
			if _quest_modifiers[quest.id]["mods"][id]["callable"].is_valid():
				_quest_modifiers[quest.id]["mods"][id]["callable"].call(quest)
	
	var new_entry: NFQuestEntry = NFQuestEntry.new()
	new_entry.resource = quest
	new_entry.auto_advance_stages = auto_advance_stages
	new_entry.current_stage = quest.entry_stage
	new_entry._flags = BitUtils.set_bit_index(0, 0, true)
	_active_quests[quest.id] = new_entry
	new_entry.objective_state_changed.connect(_on_quest_objective_state_changed)
	
	return true


## Returns a dictionary with the active quests' state. Intended for serialization
## purposes.
func get_state() -> Dictionary[StringName, Dictionary]:
	var data: Dictionary[StringName, Dictionary] = {}
	
	for quest_id in _active_quests:
		var quest: Dictionary[String, Variant] = {
			"resource_path": _active_quests[quest_id].resource.resource_path,
			"current_stage": _active_quests[quest_id].current_stage,
			"auto_advance_stages": _active_quests[quest_id].auto_advance_stages,
			"stage_progress": _active_quests[quest_id].get_objectives_state()}
		
		data[quest_id] = quest
	return data


## Restores a previous state of the manager.
func restore_state(state_data: Dictionary) -> void:
	for key in state_data:
		var key_type: int = typeof(key)
		if key_type != TYPE_STRING_NAME and key_type != TYPE_STRING:
			continue
		
		if typeof(state_data[key]) != TYPE_DICTIONARY:
			continue
		
		if not _is_serialized_data_valid(key, state_data[key]):
			continue
		
		var res: Quest = null
		
		if _active_quests.has(key):
			res = _active_quests[key].resource
		else:
			var pre = load(state_data[key]["resource_path"])
			if pre != null and pre is Quest:
				res = pre
		
		if res == null or res is not Quest:
			NFPluginGameHandler._log_msg(
				"quests - deserializer",
				"Resource for quest '%s' couldn't be loaded. Skipping." % key,
				NFPluginGameHandler._LogLevel.WARNING)
			continue
		
		if _quest_modifiers.has(key) and not res._mods_applied:
			for id in _quest_modifiers[key]["order"]:
				if _quest_modifiers[key]["mods"][id]["callable"].is_valid():
					_quest_modifiers[key]["mods"][id]["callable"].call(res)
		
		if not _active_quests.has(key):
			var new_entry: NFQuestEntry = NFQuestEntry.new()
			var auto_advance: bool = false
			if state_data[key].has("auto_advance_stages") and typeof(state_data[key]["auto_advance_stages"]) == TYPE_BOOL:
				auto_advance = state_data[key]["auto_advance_stages"]
			new_entry.resource = res
			new_entry.auto_advance_stages = auto_advance
			new_entry._flags = BitUtils.set_bit_index(0, 0, true)
			_active_quests[key] = new_entry
			new_entry.objective_state_changed.connect(_on_quest_objective_state_changed)
		
		var valid_progress: Dictionary[StringName, Dictionary] = {}
		
		for obj_id in state_data[key]["stage_progress"]:
			var id_type: int = typeof(obj_id)
			if id_type != TYPE_STRING and id_type != TYPE_STRING_NAME:
				continue
			
			if typeof(state_data[key]["stage_progress"][obj_id]) != TYPE_DICTIONARY:
				NFPluginGameHandler._log_msg(
						"quests - deserializer",
						"Objective '%s' data mismatch on quest '%s'. Skipping." % [obj_id, key],
						NFPluginGameHandler._LogLevel.WARNING)
				continue
			
			var obj_progress: Dictionary[String, Variant] = {}
			
			for inner_id in state_data[key]["stage_progress"][obj_id]:
				var inner_id_type: int = typeof(inner_id)
				if inner_id_type != TYPE_STRING and inner_id_type != TYPE_STRING_NAME:
					NFPluginGameHandler._log_msg(
							"quests - deserializer",
							"Objective '%s' progress key data missmatch on quest '%s'. Skipping." % [obj_id, key],
							NFPluginGameHandler._LogLevel.WARNING)
					continue
				obj_progress[inner_id] = state_data[key]["stage_progress"][obj_id][inner_id]
			
			if not obj_progress.is_empty():
				valid_progress[obj_id] = obj_progress
		
		_active_quests[key].set_stage(state_data[key]["current_stage"], _static_progress, false)
		_active_quests[key].set_objectives_state(valid_progress)


## Removes an active quest and clears it from the history if
## [param clear_from_history] is [code]true[/code]
func remove_quest(quest_id: StringName, clear_from_history: bool = true) -> void:
	if _active_quests.erase(quest_id) and clear_from_history:
		Log.erase(quest_id)


## Returns the quest object from the active quest [param quest_id] or
## [code]null[/code] if the quest isn't active.
func get_quest(quest_id: StringName) -> Quest:
	if _active_quests.has(quest_id):
		return _active_quests[quest_id].resource
	return null


## Returns the current [QuestStage] object of the param quest_id or
## [code]null[/code] if the quest doesn't exist.
func get_quest_current_stage(quest_id: StringName) -> QuestStage:
	if _active_quests.has(quest_id):
		return _active_quests[quest_id].resource.get_stage(_active_quests[quest_id].current_stage)
	return null


## Returns the ID of the stage [param quest_id] is in.
func get_quest_current_stage_id(quest_id: StringName) -> StringName:
	if _active_quests.has(quest_id):
		return _active_quests[quest_id].current_stage
	return &""


## Returns if the [param quest_id] is active.
func is_quest_active(quest_id: StringName) -> bool:
	return _active_quests.has(quest_id)


## Returns if a quest was completed successfully or failed.[br]
## If a quest isn't active or hasn't been completed yet it'll return
## [enum SuccessStatus.UNKNOWN].
func quest_success_status(quest_id: StringName) -> SuccessStatus:
	return Log.get_quest_status(quest_id)


## Returns if a stage was completed successfully or failed.[br]
## If the quest isn't active or the stage hasn't been completed yet it'll return
## [enum SuccessStatus.UNKNOWN].
func stage_success_status(quest_id: StringName, stage_id: StringName) -> SuccessStatus:
	if Log.has(quest_id):
		return Log.get_quest_entry(quest_id).get_entry_status(stage_id)
	return SuccessStatus.UNKNOWN


## Returns if an objective was completed successfully or failed.[br]
## If the quest isn't active or the objective hasn't been completed yet it'll return
## [enum SuccessStatus.UNKNOWN].
func objective_success_status(quest_id: StringName, stage_id: StringName, objective_id: StringName) -> SuccessStatus:
	if Log.has_stage_entry(quest_id, stage_id):
		return Log.get_stage_entry(quest_id, stage_id).get_entry_status(objective_id)
	return SuccessStatus.UNKNOWN


## Registers a global [param key] with a [param value] that will be instantly 
## passed to all currently active quests, as well as any future quests when
## they start.
## [br]Calling [method QuestManager.set_objective_progress] with a matching key will
## automatically update this static registry.
## [br][br][b][color=KHAKI]Important:[/color][/b] Quests could progress
## immediately upon registration or starting if the static values fulfill
## all required objectives.
func register_static_progress(key: String, value: Variant) -> void:
	_static_progress[key] = value
	_update_objective_progress(key, value)


## Removes a static progress [param key] previously registered via 
## [method register_static_progress]. 
## [br]Returns [code]true[/code] if the key was found and successfully removed.
func erase_static_progress(key: String) -> bool:
	return _static_progress.erase(key)


## Updates the objective progress for ALL active quests. If the provided
## [param key] is registered globally, it will also update the static progress
## registry.
## [br][br]If a quest is set to [code]auto_advance_stages[/code] and this update 
## completes all of its required objectives, the quest will automatically advance 
## to its next stage.
func set_objective_progress(key: String, value: Variant) -> void:
	if _static_progress.has(key):
		_static_progress[key] = value
	_update_objective_progress(key, value)


## Updates the objective progress for a specific [param quest]. 
## [br]Unlike [method QuestManager.set_objective_progress], this will
## NOT update any registered static progress, even if the [param key] matches.
func set_objective_progress_of(quest: StringName, key: String, value: Variant) -> void:
	if not _active_quests.has(quest):
		return
	
	_active_quests[quest].update_objective_progress(
			key,
			value)


## Forces the completion of the [param objective_id] with a [param success] status.[br]
## If a quest is set to auto-advance and all the required objectives are
## completed successfully it'll continue to the next stage.
## [b]Note:[/b] Failing a required objective means that an auto-advancing quest
## will never progress and [signal QuestManager.stage_completed] won't be 
## emitted if all objectives were completed so it must be progressed using 
## [method QuestManager.complete_stage].
func complete_objective(quest_id: StringName, stage_id: StringName, objective_id: StringName, success: bool) -> void:
	if not _active_quests.has(quest_id) or not _active_quests[quest_id].resource.has_stage(stage_id) or not _active_quests[quest_id].resource.get_stage(stage_id).has_objective(objective_id):
		return
	
	var entry: NFQuestEntry = _active_quests[quest_id]
	
	_set_objective_complete(quest_id, stage_id, objective_id, success)
	objective_completed.emit(quest_id, stage_id, objective_id, success)
	
	if not entry.auto_advance_stages or not entry.can_complete_stage():
		return
	
	var next_stage: StringName = entry.resource.get_stage(stage_id).success_stage_id
	
	_set_stage_complete(quest_id, stage_id, true)
	stage_completed.emit(quest_id, stage_id, true)
	
	_check_stage_auto_advance(quest_id)


## Forces the completion of the [param stage_id] with a [param success] status.[br]
## If a quest is set to auto-advance it'll continue to the next stage based
## on [param success].
func complete_stage(quest_id: StringName, stage_id: StringName, success: bool) -> void:
	if not _active_quests.has(quest_id) or not _active_quests[quest_id].resource.has_stage(stage_id):
		return
	
	_set_stage_complete(quest_id, stage_id, success)
	stage_completed.emit(quest_id, stage_id, success)
	
	if not _active_quests[quest_id].auto_advance_stages:
		return
	
	var entry: NFQuestEntry = _active_quests[quest_id]
	var next_stage: StringName = entry.resource.get_stage(stage_id).success_stage_id
	
	_set_stage_complete(quest_id, stage_id, true)
	stage_completed.emit(quest_id, stage_id, true)
	
	if next_stage.is_empty():
		_set_quest_complete(quest_id, true)
		_active_quests.erase(quest_id)
		quest_finished.emit(quest_id)
	else:
		if entry.set_stage(next_stage, _static_progress):
			quest_progressed.emit(quest_id, next_stage)
		else:
			NFPluginGameHandler._log_msg(
					"odyssey - quest manager",
					"Stage '%s' on quest '%s' not found." % [next_stage, quest_id],
					NFPluginGameHandler._LogLevel.ERROR)


## Forces the completion of the [param quest_id] with a [param success] status.[br]
func complete_quest(quest_id: StringName, success: bool) -> void:
	if _active_quests.has(quest_id):
		_set_quest_complete(quest_id, success)
		_active_quests.erase(quest_id)
		quest_finished.emit(quest_id)


## Registers a [Callable] with ID [param mod_id] to modify [param quest_id]
## before it's tracked with [method QuestManager.start_quest].
## The callable must have a single argument of type [Quest]. Modifications
## must be done directly to the object in-place.[br]
## The [param order] argument can be passed which will determine
## the execution sequence. A value less than 0 will append the modifier
## to the end of the execution order.[br]
## The [param after_mod] argument can be used to ensure the given callable
## executes after another modification. The [param order] will be respected.
func register_quest_modifier(quest_id: StringName, mod_id: StringName, mod_callable: Callable, order: int = -1, after_mod: StringName = &"") -> void:
	if mod_id.is_empty():
		NFPluginGameHandler._log_msg(
				"odyssey",
				"Mod ID can't be empty.",
				NFPluginGameHandler._LogLevel.ERROR)
		return
	
	if _is_dependency_circular(quest_id, mod_id, after_mod):
		NFPluginGameHandler._log_msg(
				"odyssey",
				"Circular dependency detected when adding mod '%s' to '%s'. Skipping mod registry." % [mod_id, quest_id],
				NFPluginGameHandler._LogLevel.ERROR)
		return
		
	
	if not _quest_modifiers.has(quest_id):
		_quest_modifiers[quest_id] = {
			"order": ArrayUtils.create_typed(TYPE_STRING_NAME),
			"mods": DictUtils.create_typed(TYPE_STRING_NAME, TYPE_DICTIONARY)}
	
	
	var new_mod: bool = not _quest_modifiers[quest_id]["mods"].has(mod_id)
	var trigger_sort: bool = true if new_mod else _quest_modifiers[quest_id]["mods"][mod_id]["order"] != order
	
	DictUtils.set_nested_value(
			_quest_modifiers, # ID
			[quest_id, "mods", mod_id], # Key path
			{"order": order, "callable": mod_callable, "dependency": after_mod}, # Value set to
			true) # Create the mod_id dictionary if it doesn't exist
	
	if new_mod:
		_quest_modifiers[quest_id]["order"].append(mod_id)
	
	if trigger_sort:
		_sort_mods(quest_id)


## Returns how many mods are registered for the quest with id [param quest_id].
func get_quest_modifier_count(quest_id: StringName) -> int:
	if _quest_modifiers.has(quest_id):
		return _quest_modifiers[quest_id]["mods"].size()
	return 0


## Returns an array with the registered mod IDs for [param for_quest]
## in the order they are executed.
func get_quest_modifiers(for_quest: StringName) -> Array[StringName]:
	var mods: Array[StringName] = []
	if _quest_modifiers.has(for_quest):
		mods.assign(_quest_modifiers[for_quest]["order"]) # Return the sorted list
	return mods


## Returns [code]true[/code] if the modifier [param mod_id] exists for quest
## [param on_quest].
func has_quest_modifier(on_quest: StringName, mod_id: StringName) -> bool:
	return _quest_modifiers.has(on_quest) and _quest_modifiers[on_quest]["mods"].has(mod_id)


## Removes a quest modifier with [param mod_id] for the quest [param for_quest].
func remove_quest_modifier(for_quest: StringName, mod_id: StringName) -> void:
	if not _quest_modifiers.has(for_quest):
		return
	if _quest_modifiers[for_quest]["mods"].erase(mod_id):
		_quest_modifiers[for_quest]["order"].erase(mod_id)


func _on_quest_objective_state_changed(quest_id: StringName, stage_id: StringName, objective_id: StringName) -> void:
	var entry: NFQuestEntry = _active_quests[quest_id]
	var objective_complete: bool = entry.get_objective_tracker(objective_id).can_complete()
	
	if objective_complete:
		_set_objective_complete(quest_id, stage_id, objective_id, true)
		objective_completed.emit(quest_id, stage_id, objective_id, true)
	
	_check_stage_auto_advance(quest_id)


func _check_stage_auto_advance(quest_id: StringName) -> void:
	if not _active_quests.has(quest_id):
		return
	
	var entry: NFQuestEntry = _active_quests[quest_id]
	
	while entry.auto_advance_stages and entry.can_complete_stage():
		var stage_id: StringName = entry.current_stage
		var next_stage: StringName = entry.resource.get_stage(stage_id).success_stage_id
	
		_set_stage_complete(quest_id, stage_id, true)
		stage_completed.emit(quest_id, stage_id, true)
	
		if next_stage.is_empty():
			_set_quest_complete(quest_id, true)
			_active_quests.erase(quest_id)
			quest_finished.emit(quest_id)
			break
		else:
			quest_progressed.emit(quest_id, next_stage)
			if not entry.set_stage(next_stage, _static_progress):
				NFPluginGameHandler._log_msg(
						"odyssey - quest manager",
						"Stage '%s' on quest '%s' not found." % [next_stage, quest_id],
						NFPluginGameHandler._LogLevel.ERROR)
				break


func _set_quest_complete(quest_id: StringName, success: bool, emit_events: bool = true) -> void:
	var quest: Quest = _active_quests[quest_id].resource
	
	Log.set_entry(
			quest_id,
			SuccessStatus.SUCCESS if success else SuccessStatus.FAILURE)
	
	if not emit_events:
		return
	
	var events: Dictionary[String, Variant] = {}
	
	if success:
		if quest.events.has(&"success"):
			events.assign(quest.events[&"success"])
	else:
		if quest.events.has(&"failure"):
			events.assign(quest.events[&"failure"])
	
	quest_event_triggered.emit(events.duplicate(true))


func _set_stage_complete(quest_id: StringName, stage_id: StringName, success: bool, emit_events: bool = true) -> void:
	var stage: QuestStage = _active_quests[quest_id].resource.get_stage(stage_id)
	
	_log_stage_complete(quest_id, stage_id, success)
	
	if not emit_events:
		return
	
	var events: Dictionary[String, Variant] = {}
	
	if success:
		if stage.events.has(&"success"):
			events.assign(stage.events[&"success"])
	else:
		if stage.events.has(&"failure"):
			events.assign(stage.events[&"failure"])
	
	quest_event_triggered.emit(events.duplicate(true))


func _set_objective_complete(quest_id: StringName, stage_id: StringName, objective_id: StringName, success: bool, emit_events: bool = true) -> void:
	var objective: QuestObjective = _active_quests[quest_id].resource.get_stage(stage_id).get_objective(objective_id)
	_log_objective_complete(quest_id, stage_id, objective_id, success)
	
	if not emit_events:
		return
	
	var events: Dictionary[String, Variant] = {}
	
	if success:
		if objective.events.has(&"success"):
			events.assign(objective.events[&"success"])
	else:
		if objective.events.has(&"failure"):
			events.assign(objective.events[&"failure"])
	
	quest_event_triggered.emit(events.duplicate(true))


func _log_objective_complete(quest_id: StringName, stage_id: StringName, objective_id: StringName, success: bool) -> void:
	if not Log.has_quest(quest_id):
		Log.set_entry(quest_id)
	
	if not Log.has_stage(quest_id, stage_id):
		Log.get_quest(quest_id).set_entry(stage_id)
	
	Log.get_stage(quest_id, stage_id).set_entry(objective_id, SuccessStatus.SUCCESS if success else SuccessStatus.FAILURE)


func _log_stage_complete(quest_id: StringName, stage_id: StringName, success: bool) -> void:
	if not Log.has_quest(quest_id):
		Log.set_entry(quest_id)
	Log.get_quest(quest_id).set_entry(stage_id, SuccessStatus.SUCCESS if success else SuccessStatus.FAILURE)


func _sort_mods(for_quest: StringName) -> void:
	var mods_with_dependencies: Dictionary[StringName, Array] = {}
	var independent_mods: Array[StringName] = []
	var mods: Dictionary[StringName, Dictionary] = _quest_modifiers[for_quest]["mods"]
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
						"odyssey",
						"[ODYSSEY] Circular dependency detected for mod '%s'. Forcing to end of execution order." % mod_id,
						NFPluginGameHandler._LogLevel.WARNING)
				final_order.append(mod_id)
	
	_quest_modifiers[for_quest]["order"].assign(final_order)


func _is_dependency_circular(on_quest: StringName, mod_id: StringName, depends_on: StringName, _visited: Array[StringName] = []) -> bool:
	if depends_on.is_empty() or not _quest_modifiers.has(on_quest) or not _quest_modifiers[on_quest]["mods"].has(depends_on):
		return false
	
	if _visited.has(depends_on):
		NFPluginGameHandler._log_msg(
				"odyssey",
				"Pre-existing cycle detected at '%s'. Aborting check." % depends_on,
				NFPluginGameHandler._LogLevel.WARNING)
		return true
	
	_visited.append(depends_on)
	
	var mods: Dictionary[StringName, Dictionary] = _quest_modifiers[on_quest]["mods"]
	
	var dependency: StringName = mods[depends_on]["dependency"]
	
	if dependency.is_empty():
		return false
	elif dependency == mod_id:
		return true
	else:
		return _is_dependency_circular(on_quest, mod_id, dependency, _visited)


func _update_objective_progress(for_key: String, value: Variant) -> void:
	for quest_id in _active_quests:
		_active_quests[quest_id].update_objective_progress(
				for_key,
				value)


func _is_serialized_data_valid(quest: StringName, data: Dictionary) -> bool:
	if not data.has_all(["resource_path", "current_stage", "stage_progress"]):
		NFPluginGameHandler._log_msg(
				"quests - deserializer",
				"Provided data for quest '%s' is missing entries." % quest,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	if typeof(data["resource_path"]) != TYPE_STRING:
		NFPluginGameHandler._log_msg(
				"quests - deserializer",
				"Invalid resource path given for quest '%s'" % quest,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	if data["resource_path"].is_empty() or not ResourceLoader.exists(data["resource_path"]):
		NFPluginGameHandler._log_msg(
				"quests - deserializer",
				"Resource path '%s' for quest '%s' is empty or does not exist." % [data["resource_path"], quest],
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	var stage_type = typeof(data["current_stage"])
	
	if stage_type != TYPE_STRING_NAME and stage_type != TYPE_STRING:
		NFPluginGameHandler._log_msg(
				"quests - deserializer",
				"Invalid data for stage value on quest '%s'" % quest,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	
	if typeof(data["stage_progress"]) != TYPE_DICTIONARY:
		NFPluginGameHandler._log_msg(
				"quests - deserializer",
				"Invalid data for stage progress value on quest '%s'" % quest,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	return true


class NFQuestEntry extends RefCounted:
	signal objective_state_changed(quest_id: StringName, stage_id: StringName, objective_id: StringName)
	
	var resource: Quest = null: # Blueprint
		set(r):
			if r == null and resource != null:
				_current_stage = &""
				_clear_trackers()
			resource = r
	var auto_advance_stages: bool = false
	var current_stage: StringName = &"":
		set(s):
			return
		get():
			return _current_stage
	var _current_stage: StringName = &""
	var _objective_tracker: Dictionary[StringName, NFObjectiveProgressTracker] = {}
	var _is_stage_initializing: bool = false
	var _flags: int = 0:
		set(f):
			if _flags == 0:
				_flags = f
	
	
	func set_stage(stage_id: StringName, static_progress: Dictionary[String, Variant] = {}, initialize_stage: bool = true) -> bool:
		if resource == null:
			return false
		elif not resource.has_stage(stage_id):
			return false
		elif current_stage == stage_id:
			return true
		
		var stage: QuestStage = resource.get_stage(stage_id)
		_clear_trackers()
		
		for objective_id in stage.objectives():
			var objective: QuestObjective = stage.get_objective(objective_id)
			var progress_tracker: NFObjectiveProgressTracker = NFObjectiveProgressTracker.new()
			progress_tracker.objective_id = objective_id
			progress_tracker.is_required = stage.is_objective_required(objective_id)
			progress_tracker._requirements = objective._requirements
			progress_tracker._assign_progress(static_progress)
			_objective_tracker[objective_id] = progress_tracker
			progress_tracker.state_updated.connect(_on_objective_state_changed)
		
		_current_stage = stage_id
		
		if initialize_stage:
			_initialize_stage()
		
		return true
	
	
	func _initialize_stage() -> void:
		_is_stage_initializing = true
		
		for id in _objective_tracker:
			var tracker: NFObjectiveProgressTracker = _objective_tracker[id]
			
			if not tracker._is_complete and tracker.can_complete():
				tracker._is_complete = true
				objective_state_changed.emit(
						resource.id,
						current_stage,
						id)
		
		_is_stage_initializing = false
	
	
	func can_complete_stage(exclude_optional: bool = true) -> bool:
		if _is_stage_initializing:
			return false
		
		
		for obj_id in _objective_tracker:
			if not _objective_tracker[obj_id].is_required and exclude_optional:
				continue
			if not _objective_tracker[obj_id].can_complete():
				return false
		return true
	
	
	func is_valid() -> bool:
		return BitUtils.is_bit_index(_flags, 0, true)
	
	
	func update_objective_progress(key: String, value: Variant) -> void:
		for tracker_id in _objective_tracker:
			_objective_tracker[tracker_id].set_progress(key, value)
	
	
	func get_objectives_state() -> Dictionary[StringName, Dictionary]:
		var state: Dictionary[StringName, Dictionary] = {}
		for tracker_id in _objective_tracker:
			state[tracker_id] = _objective_tracker[tracker_id].progress.duplicate(true)
		return state
	
	
	func get_objective_tracker(objective_id: StringName) -> NFObjectiveProgressTracker:
		if _objective_tracker.has(objective_id):
			return _objective_tracker[objective_id]
		return null
	
	
	func set_objectives_state(state: Dictionary) -> void:
		var valid_state: Dictionary[StringName, Dictionary] = {}
		
		# --- Validation ---
		for entry in state:
			var entry_type: int = typeof(entry)
			if entry_type != TYPE_STRING_NAME and entry_type != TYPE_STRING:
				continue
			var value_type: int = typeof(state[entry])
			if value_type != TYPE_DICTIONARY:
				continue
			
			var valid_entries: Dictionary[String, Variant] = {}
			
			for state_entry in state[entry]:
				var entry_value_type: int = typeof(state_entry)
				if entry_value_type != TYPE_STRING and entry_value_type != TYPE_STRING_NAME:
					continue
				valid_entries[state_entry] = state[entry][state_entry]
			
			if not valid_entries.is_empty():
				valid_state[entry] = valid_entries
		# ------------------
		
		
		for tracker_id in _objective_tracker:
			var tracker: NFObjectiveProgressTracker = _objective_tracker[tracker_id]
		
			if valid_state.has(tracker_id):
				tracker._assign_progress(valid_state[tracker_id])
			
			if not tracker._is_complete and tracker.can_complete():
				tracker._is_complete = true
	
	
	func _on_objective_state_changed(objective_id: StringName) -> void:
		objective_state_changed.emit(resource.id, current_stage, objective_id)
	
	
	func _clear_trackers() -> void:
		for id in _objective_tracker:
			_objective_tracker[id].state_updated.disconnect(_on_objective_state_changed)
			# Clear the reference for safety
			_objective_tracker[id]._requirements = {}
		_objective_tracker.clear()


class NFObjectiveProgressTracker extends RefCounted:
	signal state_updated(objective_id: StringName)
	
	var objective_id: StringName
	var is_required: bool
	var progress: Dictionary[String, Variant] = {
		"inventory/apples": 2,
		"inventory/oranges": 0}
	var _requirements: Dictionary[String, Dictionary] = {
		"inventory/apples": {"operator": OP_GREATER_EQUAL, "value": 5},
		"inventory/oranges": {"operator": OP_GREATER_EQUAL, "value": 1},
		"time": {"operator": OP_LESS_EQUAL, "value": 720}}
	var _is_complete: bool = false
	
	
	func get_progress() -> Array[Dictionary]:
		var progress_array: Array[Dictionary] = []
		for key in _requirements:
			progress_array.append({
				"key": key,
				"required": _requirements[key]["value"],
				"operator": _requirements[key]["operator"],
				"current": progress[key] if progress.has(key) else _get_default_value(_requirements[key]["value"])})
		return progress_array
	
	
	func clear() -> void:
		_requirements = {}
		progress.clear()
	
	
	func can_complete() -> bool:
		if _is_complete:
			return true
		return _are_requirements_met()
	
	
	func set_progress(key: String, value: Variant) -> void:
		if not _requirements.has(key):
			return
		
		progress[key] = value
		var was_complete: bool = _is_complete
		
		_validate_progress()
		
		if was_complete and not _is_complete:
			state_updated.emit(objective_id)
		elif not was_complete and can_complete():
			_is_complete = true
			state_updated.emit(objective_id)
	
	
	func _validate_progress() -> void:
		if not _is_complete:
			return
		
		if not _are_requirements_met():
			_is_complete = false
	
	
	func _are_requirements_met() -> bool:
		for entry in _requirements:
			var current_progress_value = progress[entry] if progress.has(entry) else _get_default_value(_requirements[entry]["value"])
			if typeof(current_progress_value) == TYPE_NIL:
				return false
			elif not _perform_comparison(current_progress_value, _requirements[entry]["operator"], _requirements[entry]["value"]):
				return false
		return true
	
	
	func _assign_progress(new_progress: Dictionary[String, Variant]) -> void:
		progress.clear()
		for key in new_progress:
			if _requirements.has(key):
				progress[key] = new_progress[key]
	
	
	func _perform_comparison(active_value: Variant, operator: int, target_value: Variant) -> bool:
		match operator:
			OP_EQUAL:
				return active_value == target_value
			OP_NOT_EQUAL:
				return active_value != target_value
			OP_LESS:
				return active_value < target_value
			OP_LESS_EQUAL:
				return active_value <= target_value
			OP_GREATER:
				return active_value > target_value
			OP_GREATER_EQUAL:
				return active_value >= target_value
			_:
				NFPluginGameHandler._log_msg(
						"odyssey - evaluator",
						"Invalid operator '%s' used in requirement comparison." % operator,
						NFPluginGameHandler._LogLevel.ERROR)
				return false
	
	
	func _get_default_value(of_variant: Variant) -> Variant:
		match typeof(of_variant):
			TYPE_INT:
				return 0
			TYPE_FLOAT:
				return 0.0
			TYPE_BOOL:
				return false
			TYPE_STRING:
				return ""
			TYPE_VECTOR2:
				return Vector2.ZERO
			TYPE_VECTOR2I:
				return Vector2i.ZERO
			TYPE_VECTOR3:
				return Vector3.ZERO
			TYPE_VECTOR3I:
				return Vector3i.ZERO
			TYPE_VECTOR4:
				return Vector4.ZERO
			TYPE_VECTOR4I:
				return Vector4i.ZERO
			TYPE_ARRAY:
				return []
			TYPE_DICTIONARY:
				return {}
			_:
				return null
