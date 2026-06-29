class_name QuestManager
extends RefCounted
## An object to manage and keep track of quests.
##
## This object can keep track of the states of quests and progress them automatically
## as well as keeping a log of all finished quests along with if it was completed
## successfully or failed.[br]
## It also provides methods to get data for storage and restoring it.


## Emmited when a quest is started via [method start_quest].
signal quest_started(quest_id: StringName)
## Emmited when a quest progresses. Emmited too when a quest starts with [param to_stage]
## being the entry stage.
signal quest_progressed(quest_id: StringName, to_stage: StringName)
## Emmited when a quest finishes either automatically or by using [method complete_quest]
signal quest_finished(quest_id: StringName)

## Emmited when a quest stage is completed.
signal stage_completed(quest_id: StringName, stage_id: StringName, successfully: bool)
## Emmited when a stage objective is completed.
signal objective_completed(quest_id: StringName, stage_id: StringName, objective_id: StringName, successfully: bool)

## Emits when a quest/stage/objective is completed either successfully or not.
signal quest_event_triggered(event_id: String, event_data)

enum SuccessStatus{
	SUCCESS,
	FAILURE,
	UNKNOWN,
}

var _active_quests: Dictionary[StringName, QuestEntry] = {
	#&"lay_eggs": {
		#"current_stage": &"",
		#"quest": Quest.new(),
		#"auto_advance_stages": true
	#}
}

## The quest log in which the history of quest started and finished is stored.
var Log: NFQuestLog = NFQuestLog.new()


var _quest_modifiers: Dictionary[StringName, Dictionary] = {}


func _get(property: StringName) -> Variant:
	if _active_quests.has(property):
		return property
	var invalid: QuestEntry = QuestEntry.new()
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
	if _active_quests.has(quest.id) or not quest.has_stage(quest.entry_stage):
		return false
	
	if _quest_modifiers.has(quest.id) and not quest._mods_applied:
		for id in _quest_modifiers[quest.id]["order"]:
			if _quest_modifiers[quest.id]["mods"][id]["callable"].is_valid():
				_quest_modifiers[quest.id]["mods"][id]["callable"].call(quest)
	
	var new_entry: QuestEntry = QuestEntry.new()
	new_entry.resource = quest
	new_entry.auto_advance_stages = auto_advance_stages
	new_entry.current_stage = quest.entry_stage
	new_entry._flags = BitUtils.set_bit_index(0, 0, true)
	
	_active_quests[quest.id] = new_entry
	
	var quest_entry: NFQuestLog.NFQuestLogEntry = Log.set_entry(quest.id)
	
	for stage_id in quest.stages():
		var stage_entry: NFQuestLog.NFQuestLogStageEntry = quest_entry.set_entry(stage_id)
		
		for objective_id in quest.get_stage(stage_id).objectives():
			stage_entry.set_entry(objective_id)
	
	quest_started.emit(quest.id)
	quest_progressed.emit(quest.id, quest.entry_stage)
	
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
	
	var new_entry: QuestEntry = QuestEntry.new()
	new_entry.resource = quest
	new_entry.auto_advance_stages = auto_advance_stages
	new_entry.current_stage = quest.entry_stage
	new_entry._flags = BitUtils.set_bit_index(0, 0, true)
	
	_active_quests[quest.id] = new_entry
	return true


## Returns a dictionary with the active quests' state. Intended for serialization
## purposes.
func get_state() -> Dictionary[StringName, Dictionary]:
	var data: Dictionary[StringName, Dictionary] = {}
	
	for quest_id in _active_quests.keys():
		var stages: Dictionary[StringName, Dictionary] = {}
		var quest: Dictionary[String, Variant] = {
			"resource_path": _active_quests[quest_id].resource.resource_path,
			"current_stage": _active_quests[quest_id].current_stage,
			"auto_advance_stages": _active_quests[quest_id].auto_advance_stages,
			"stages": stages}
		
		for stage_id in _active_quests[quest_id].resource.stages():
			var stage: QuestStage = _active_quests[quest_id].resource.get_stage(stage_id)
			var objective_data: Dictionary[StringName, Dictionary] = {}
			for objective_id in stage.objectives():
				var objective: QuestObjective = stage.get_objective(objective_id)
				if objective == null:
					NFPluginGameHandler._log_msg(
							"quests",
							"Couldn't load objective data of '%s' from quest '%s' on stage '%s'" % [objective_id, quest_id, stage_id],
							NFPluginGameHandler._LogLevel.ERROR)
					continue
				objective_data[objective_id] = objective._progress.duplicate(true)
			stages[stage_id] = objective_data
		data[quest_id] = quest
	return data


## Restores a previous state of the manager.
func restore_state(state_data: Dictionary) -> void:
	for key in state_data.keys():
		var key_type: int = typeof(key)
		if key_type != TYPE_STRING_NAME and key_type != TYPE_STRING:
			continue
		
		if typeof(state_data[key]) != TYPE_DICTIONARY:
			continue
		
		if not _is_serialized_data_valid(key, state_data[key]):
			continue
		
		if state_data[key]["resource_path"].is_empty():
			continue
		
		var res = _active_quests[key] if _active_quests.has(key) else load(state_data["resource_path"]) 
		
		if res == null or res is not Quest:
			NFPluginGameHandler._log_msg(
				"quests - deserializer",
				"Resource for quest '%s' couldn't be loaded. Skipping." % key,
				NFPluginGameHandler._LogLevel.ERROR)
			continue
	
		if _quest_modifiers.has(key) and not res._mods_applied:
			for id in _quest_modifiers[key]["order"]:
				if _quest_modifiers[key]["mods"][id]["callable"].is_valid():
					_quest_modifiers[key]["mods"][id]["callable"].call(res)
		
		for stage_id in state_data[key]["stages"].keys():
			var stage_type: int = typeof(stage_id)
			if stage_type != TYPE_STRING_NAME and stage_type != TYPE_STRING:
				continue
			if typeof(state_data[key]["stages"][stage_id]) != TYPE_DICTIONARY:
				NFPluginGameHandler._log_msg(
						"quests - deserializer",
						"Error on provided data of stage '%s' from quest '%s'." % [stage_id, key],
						NFPluginGameHandler._LogLevel.ERROR)
				continue
			
			if not res.has_stage(stage_id):
				NFPluginGameHandler._log_msg(
						"quests - deserializer",
						"Stage '%s' does not exist on quest '%s'. Skipping." % [stage_id, key],
						NFPluginGameHandler._LogLevel.WARNING)
				continue
			var stage: QuestStage = res.get_stage(stage_id)
			var stage_data: Dictionary = state_data[key]["stages"][stage_id]
			for objective_id in stage_data.keys():
				var obj_type: int = typeof(objective_id)
				if obj_type != TYPE_STRING_NAME and obj_type != TYPE_STRING:
					continue
				if not stage.has_objective(objective_id):
					NFPluginGameHandler._log_msg(
							"quests - deserializer",
							"Objective '%s' does not exist in stage '%s' on quest '%s'. Skipping." % [objective_id, stage_id, key],
							NFPluginGameHandler._LogLevel.WARNING)
					continue
				if typeof(stage_data[objective_id]) != TYPE_DICTIONARY:
					NFPluginGameHandler._log_msg(
							"quests - deserializer",
							"Error on provided data of objective '%s' from stage '%s' on quest '%s'." % [objective_id, stage_id, key],
							NFPluginGameHandler._LogLevel.ERROR)
					continue
				var objective: QuestObjective = stage.get_objective(objective_id)
				var obj_progress: Dictionary[String, Variant] = {}
				for progress_key in stage_data[objective_id].keys():
					var pr_type: int = typeof(progress_key)
					if pr_type != TYPE_STRING and pr_type != TYPE_STRING_NAME:
						NFPluginGameHandler._log_msg(
								"quests - deserializer",
								"Invalid objective data key on objective '%s' in stage '%s' on quest '%s'. Skipping progress entry." % [objective_id, stage_id, key],
								NFPluginGameHandler._LogLevel.WARNING)
						continue
					obj_progress[progress_key] = stage_data[objective_id][progress_key]
				objective._progress.assign(obj_progress)


func _is_serialized_data_valid(quest: StringName, data: Dictionary) -> bool:
	if not data.has_all(["resource_path", "current_stage", "stages"]):
		NFPluginGameHandler._log_msg(
				"quests - deserializer",
				"Provided data for quest '%s' is missing entries.",
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
	
	if typeof(data["stages"]) != TYPE_DICTIONARY:
		NFPluginGameHandler._log_msg(
				"quests - deserializer",
				"Invalid data for stages value on quest '%s'" % quest,
				NFPluginGameHandler._LogLevel.ERROR)
		return false
	return true


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


## Sets the progress of [param objective_id] to [param progress_value]. If
## all requirements of the objective are met [signal objective_completed] will be emmited.[br]
## If a quest is set to auto-advance and all the required objectives of [param stage_id]
## are completed it'll trigger it to advance to the next stage.[br][br]
## [b][color=KHAKI]Important:[/color][/b] To keep track of progress correctly it is reccomended to set the
## objectives' progress through this method instead of directly to the QuestObjective
## object directly.
func set_objective_progress(quest_id: StringName, stage_id: StringName, objective_id: StringName, requirement_id: String, progress_value) -> void:
	if not DictUtils.has_nested_path(_active_quests, [quest_id, "quest"]):
		return
	
	var quest: Quest = _active_quests[quest_id].resource
	
	if not quest.has_stage(stage_id) or not quest.get_stage(stage_id).has_objective(objective_id) or not quest.get_stage(stage_id).get_objective(objective_id).has_requirement(requirement_id):
		return
	
	var quest_objective: QuestObjective = quest.get_stage(stage_id).get_objective(objective_id)
	quest_objective.set_progress(requirement_id, progress_value)
	
	if quest_objective.can_complete_objective():
		_set_objective_complete(quest_id, stage_id, objective_id, true)
		objective_completed.emit(quest_id, stage_id, objective_id, true)
		
		var quest_stage: QuestStage = quest.get_stage(stage_id)
		
		if not _active_quests[quest_id].auto_advance_stages or not quest_stage.can_complete_stage():
			return
		
		if quest_stage.success_stage_id.is_empty():
			_set_quest_complete(quest_id, true)
			_active_quests.erase(quest_id)
			quest_finished.emit(quest_id)
		else:
			_set_stage_complete(quest_id, stage_id, true)
			_active_quests[quest_id].current_stage = quest_stage.success_stage_id
			stage_completed.emit(quest_id, stage_id, true)
			quest_progressed.emit(quest_id, quest_stage.success_stage_id)


## Forces the completion of the [param objective_id] with a [param success] status.[br]
## If a quest is set to auto-advance and all the required objectives are
## completed successfully it'll continue to the next stage.
## [b]Note:[/b] Failing a required objective means that an auto-advancing quest
## will never progress and [signal stage_completed] won't be emmited if all
## objectives were completed so it must be progressed using [method complete_stage].
func complete_objective(quest_id: StringName, stage_id: StringName, objective_id: StringName, success: bool) -> void:
	if not _active_quests.has(quest_id) or not _active_quests[quest_id].resource.has_stage(stage_id) or not _active_quests[quest_id].resource.get_stage(stage_id).has_objective(objective_id):
		return
	var stage: QuestStage = _active_quests[quest_id].resource.get_stage(stage_id)
	_set_objective_complete(quest_id, stage_id, objective_id, success)
	
	objective_completed.emit(quest_id, stage_id, objective_id, success)
	
	var can_complete_stage: bool = stage.can_complete_stage()
	
	if can_complete_stage:
		_set_stage_complete(quest_id, stage_id, true)
		stage_completed.emit(quest_id, stage_id, true)
	
	if not _active_quests[quest_id].auto_advance_stages or not can_complete_stage:
		return
	
	var next_stage_id: StringName = stage.success_stage_id if success else stage.failure_stage_id
	
	if next_stage_id.is_empty():
		_set_quest_complete(quest_id, success)
		_active_quests.erase(quest_id)
		quest_finished.emit(quest_id)
	else:
		_active_quests[quest_id].current_stage = next_stage_id
		quest_progressed.emit(quest_id, next_stage_id)


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
	
	var stage: QuestStage = _active_quests[quest_id].resource.get_stage(stage_id)
	var next_stage_id: StringName = stage.success_stage_id if success else stage.failure_stage_id
	
	if next_stage_id.is_empty():
		_set_quest_complete(quest_id, success)
		_active_quests.erase(quest_id)
		quest_finished.emit(quest_id, success)
	else:
		_active_quests[quest_id].current_stage = next_stage_id
		quest_progressed.emit(quest_id, next_stage_id)


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
		push_error("[ODYSSEY] Mod ID can't be empty.")
		return
	
	if _is_dependency_circular(quest_id, mod_id, after_mod):
		push_error("[ODYSSEY] Circular dependency detected when adding mod %s to %s. Skipping mod registry." % [mod_id, quest_id])
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


func _set_quest_complete(quest_id: StringName, success: bool, emit_events: bool = true) -> void:
	var quest: Quest = _active_quests[quest_id].resource
	
	Log.set_entry(quest_id, SuccessStatus.SUCCESS if success else SuccessStatus.FAILURE)
	
	if not emit_events:
		return
	
	var events: Dictionary[String, Variant] = quest.on_success_events if success else quest.on_failure_events
	
	for event_id in events.keys():
		quest_event_triggered.emit(event_id, events[event_id])


func _set_stage_complete(quest_id: StringName, stage_id: StringName, success: bool, emit_events: bool = true) -> void:
	var stage: QuestStage = _active_quests[quest_id].resource.get_stage(stage_id)
	
	_log_stage_complete(quest_id, stage_id, success)
	
	if not emit_events:
		return
	
	var events: Dictionary[String, Variant] = stage.on_success_events if success else stage.on_failure_events
	for event_id in events.keys():
		quest_event_triggered.emit(event_id, events[event_id])


func _set_objective_complete(quest_id: StringName, stage_id: StringName, objective_id: StringName, success: bool, emit_events: bool = true) -> void:
	var objective: QuestObjective = _active_quests[quest_id].resource.get_stage(stage_id).get_objective(objective_id)
	objective.set_completed(true)
	_log_objective_complete(quest_id, stage_id, objective_id, success)
	
	if not emit_events:
		return
	
	var events: Dictionary = objective.on_success_events if success else objective.on_failure_events
	for event_id in events.keys():
		quest_event_triggered.emit(event_id, events[event_id])


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
				push_warning("[ODYSSEY] Circular dependency detected for mod '%s'. Forcing to end of execution order." % mod_id)
				final_order.append(mod_id)
	
	_quest_modifiers[for_quest]["order"].assign(final_order)


func _is_dependency_circular(on_quest: StringName, mod_id: StringName, depends_on: StringName, _visited: Array[StringName] = []) -> bool:
	if depends_on.is_empty() or not _quest_modifiers.has(on_quest) or not _quest_modifiers[on_quest]["mods"].has(depends_on):
		return false
	
	if _visited.has(depends_on):
		push_warning("[ODYSSEY] Pre-existing cycle detected at '%s'. Aborting check." % depends_on)
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


class QuestEntry extends RefCounted:
	var resource: Quest = null
	var auto_advance_stages: bool = false
	var current_stage: StringName = &""
	var _flags: int = 0:
		set(f):
			if _flags == 0:
				_flags = f
	
	func is_valid() -> bool:
		return BitUtils.is_bit_index(_flags, 0, true)
