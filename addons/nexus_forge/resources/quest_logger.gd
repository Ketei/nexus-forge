class_name NFQuestLog
extends RefCounted
## An object that keeps track of quests started, finished and their completion
## status (success/failure/unknown).
##
## This object keeps track of quests, their stages and the objectives of such
## stages. Supports accessing directly using the ID of the quest
## (eg. Log.main_quest). If no quest exist, a fallback object will be
## returned. To differentiate if an object is valid call is_valid() on the object.

var _entries: Dictionary[StringName, NFQuestLogEntry] = {}


func _get(property: StringName) -> Variant:
	if _entries.has(property):
		return _entries[property]
	var invalid: NFQuestLogEntry = NFQuestLogEntry.new(property)
	invalid._flags = BitUtils.set_bit_index(0, 63, true)
	return invalid


## Sets an entry on the log with [param id] and a [param success_status].
func set_entry(id: StringName, success_status: QuestManager.SuccessStatus = QuestManager.SuccessStatus.UNKNOWN) -> NFQuestLogEntry:
	if _entries.has(id):
		_entries[id].success_status = success_status
	else:
		var new_entry: NFQuestLogEntry = NFQuestLogEntry.new(id, success_status)
		new_entry._flags = BitUtils.set_bit_index(0, 0, true)
		_entries[id] = new_entry
	
	return _entries[id]


## Returns the status of the quest with the provided [param id] or
## [enum QuestManager.SuccessStatus.UNKNOWN] if the entry doesn't exist.
func get_quest_status(id: StringName) -> QuestManager.SuccessStatus:
	if _entries.has(id):
		return _entries[id].success_status
	return QuestManager.SuccessStatus.UNKNOWN


## Gets the quest log entry object with [param id].
func get_quest(id: StringName) -> NFQuestLogEntry:
	if _entries.has(id):
		return _entries[id]
	return null


## Gets the stage log [param entry] from [param of_quest].
func get_stage(of_quest: StringName, entry: StringName) -> NFQuestLogStageEntry:
	if _entries.has(of_quest) and _entries[of_quest].has(entry):
		return _entries[of_quest].get_entry(entry)
	return null


## Gets the objective log [param entry] of [param from_stage] on [param of_quest].
func get_objective(of_quest: StringName, from_stage: StringName, entry: StringName) -> NFQuestLogStatusEntry:
	if _entries.has(of_quest) and _entries[of_quest].has(from_stage) and _entries[of_quest].get_entry(from_stage).has(entry):
		return _entries[of_quest].get_entry(from_stage).get_entry(entry)
	return null


## Returns if a quest with ID [param entry] is logged.
func has_quest(entry: StringName) -> bool:
	return _entries.has(entry)


## Returns if a stage [param entry] is logged [param on_quest].
func has_stage(on_quest: StringName, entry: StringName) -> bool:
	return _entries.has(on_quest) and _entries[on_quest].has(entry)


## Returns if an objective [paran entry] is logged on [param from_stage] in
## quest [param on_quest].
func has_objective(on_quest: StringName, from_stage: StringName, entry: StringName) -> bool:
	return _entries.has(on_quest) and _entries[on_quest].has(from_stage) and _entries[on_quest].get_entry(from_stage).has(entry)


## Returns log data as a dictionary for serialization.
func log_state() -> Dictionary[StringName, Dictionary]:
	var log_data: Dictionary[StringName, Dictionary] = {}
	
	for quest_id in _entries.keys():
		var stage_data: Dictionary[StringName, Dictionary] = {}
		var quest_data: Dictionary[String, Variant] = {
			"success_status": _entries[quest_id].success_status,
			"stages": stage_data}
		for stage_id in _entries[quest_id].stages():
			var objective_data: Dictionary[StringName, int] = _entries[quest_id]._entries[stage_id].objective_data()
			var stage: Dictionary[String, Variant] = {
				"success_status": _entries[quest_id]._entries[stage_id].success_status,
				"objectives": objective_data}
			stage_data[stage_id] = stage
		
		log_data[quest_id] = quest_data
	
	return log_data


## Restores the log from [param data].
func restore_state(data: Dictionary) -> void:
	for key_entry in data.keys():
		var key_type: int = typeof(key_entry)
		if (key_type != TYPE_STRING_NAME and key_type != TYPE_STRING) or typeof(data[key_entry]) != TYPE_DICTIONARY:
			continue
		
		var status: QuestManager.SuccessStatus = QuestManager.SuccessStatus.UNKNOWN
		
		if data[key_entry].has("success_status") and typeof(data[key_entry]["success_status"]) == TYPE_INT:
			status = data[key_entry]["success_status"]
		else:
			NFPluginGameHandler._log_msg(
					"quest - log",
					"Quest '%s' doesn't have a valid success status." % key_entry,
					NFPluginGameHandler._LogLevel.WARNING)
		
		var quest_entry: NFQuestLogEntry = NFQuestLogEntry.new(key_entry, status)
		
		quest_entry._flags = BitUtils.set_bit_index(0, 0, true)
		
		if data[key_entry].has("stages"):
			quest_entry._load_from_data(data[key_entry]["stages"])
		
		_entries[key_entry] = quest_entry


## Erases a quest [param entry] from the log.
func erase(entry: StringName) -> bool:
	return _entries.erase(entry)


## Clears the quest log.
func clear() -> void:
	_entries.clear()


class NFQuestLogStatusEntry extends RefCounted:
	## The status of the entry.
	var success_status: QuestManager.SuccessStatus = QuestManager.SuccessStatus.UNKNOWN
	var _flags: int = 0:
		set(f):
			if _flags == 0:
				_flags = f
	
	
	func _init(status: QuestManager.SuccessStatus = QuestManager.SuccessStatus.UNKNOWN) -> void:
		success_status = status
	
	
	## Returns if this entry exists in the log or was provided as a fallback.
	func is_valid() -> bool:
		return BitUtils.is_bit_index(_flags, 0, true)


class NFQuestLogEntry extends NFQuestLogStatusEntry:
	## The ID of the quest.
	var id: StringName = &"":
		set(i): # Lock ID changing
			if id.is_empty():
				id = i
	var _entries: Dictionary[StringName, NFQuestLogStageEntry] = {}
	
	
	func _init(entry_id: StringName = &"", status: QuestManager.SuccessStatus = QuestManager.SuccessStatus.UNKNOWN) -> void:
		id = entry_id
		success_status = status
	
	
	func _get(property: StringName) -> Variant:
		if _entries.has(property):
			return _entries[property]
		var invalid: NFQuestLogStageEntry = NFQuestLogStageEntry.new(property)
		invalid._flags = BitUtils.set_bit_index(0, 63, true)
		return invalid
	
	
	func _load_from_data(dict: Dictionary):
		_entries.clear()
		
		for key_entry in dict.keys():
			var key_type: int = typeof(key_entry)
			
			if (key_type != TYPE_STRING_NAME and key_type != TYPE_STRING) or typeof(dict[key_entry]) != TYPE_DICTIONARY:
				continue
			
			var success: QuestManager.SuccessStatus = QuestManager.SuccessStatus.UNKNOWN
			if dict[key_entry].has("success_status") and typeof(dict[key_entry]["success_status"]) == TYPE_INT:
				success = dict[key_entry]["success_status"]
			else:
				NFPluginGameHandler._log_msg(
					"quest - log",
					"Quest '%s' doesn't have a valid success status." % key_entry,
					NFPluginGameHandler._LogLevel.WARNING)
			
			var entry: NFQuestLogStageEntry = NFQuestLogStageEntry.new(key_entry, success)
			entry._flags = BitUtils.set_bit_index(0, 0, true)
			if dict[key_entry].has("objectives") and typeof(dict[key_entry]["objectives"]) == TYPE_DICTIONARY:
				entry._load_from_data(dict[key_entry]["objectives"])
			_entries[key_entry] = entry
	
	
	## Returns an array with all the IDs of the stages in the log.
	func stages() -> Array[StringName]:
		var loaded_stages: Array[StringName] = []
		loaded_stages.assign(_entries.keys())
		return loaded_stages
	
	
	## Creates an entry with id [param stage_id] unless the entry already exists,
	## in which [param status] is assigned to it.
	func set_entry(stage_id: StringName, status: QuestManager.SuccessStatus = QuestManager.SuccessStatus.UNKNOWN) -> NFQuestLogStageEntry:
		if _entries.has(stage_id):
			_entries[stage_id].success_status = status
		else:
			var new_entry: NFQuestLogStageEntry = NFQuestLogStageEntry.new(stage_id, status)
			new_entry._flags = _flags
			_entries[stage_id] = new_entry
		
		return _entries[stage_id]
	
	
	## Gets a stage log object.
	func get_entry(stage_id: StringName) -> NFQuestLogStageEntry:
		if _entries.has(stage_id):
			return _entries[stage_id]
		return null
	
	
	## Returns the status of a stage or [enum QuestManager.SuccessStatus.UNKNOWN]
	## if the entry doesn't exist.
	func get_status(entry_id: StringName) -> QuestManager.SuccessStatus:
		if _entries.has(entry_id):
			return _entries[entry_id].success_status
		return QuestManager.SuccessStatus.UNKNOWN
	
	
	## Returns the stage entries as a dictionary.
	func stage_data() -> Dictionary[StringName, Dictionary]:
		var stage_data: Dictionary[StringName, Dictionary] = {}
		
		for id in _entries.keys():
			stage_data[id] = _entries[id].objective_data()
		return stage_data
	
	
	## Returns if there is a stage [param entry] on the log.
	func has(entry: StringName) -> bool:
		return _entries.has(entry)
	
	
	## Erases a stage [param entry] on the log.
	func erase(entry: StringName) -> bool:
		return _entries.erase(entry)
	
	
	## Clears all the stage entries on the log.
	func clear() -> void:
		_entries.clear()


class NFQuestLogStageEntry extends NFQuestLogStatusEntry:
	## The ID of the stage.
	var id: StringName = &"":
		set(i): # Lock ID changing
			if id.is_empty():
				id = i
	var _entries: Dictionary[StringName, NFQuestLogStatusEntry] = {}
	
	
	func _init(entry_id: StringName = &"", status: QuestManager.SuccessStatus = QuestManager.SuccessStatus.UNKNOWN) -> void:
		id = entry_id
		success_status = status
	
	
	func _get(property: StringName) -> Variant:
		if _entries.has(property):
			return _entries[property]
		var invalid: NFQuestLogStatusEntry = NFQuestLogStatusEntry.new()
		invalid._flags = BitUtils.set_bit_index(0, 63, true)
		return invalid
	
	
	func _load_from_data(dict: Dictionary):
		_entries.clear()
		
		for key_entry in dict.keys():
			var key_type: int = typeof(key_entry)
			if (key_type != TYPE_STRING_NAME and key_type != TYPE_STRING) or typeof(dict[key_entry]) != TYPE_INT:
				continue
			
			var entry: NFQuestLogStatusEntry = NFQuestLogStatusEntry.new(dict[key_entry])
			entry._flags = BitUtils.set_bit_index(0, 0, true)
			_entries[key_entry] = entry
	
	
	## Creates an entry with id [param objective_id] unless the entry already exists,
	## in which [param status] is assigned to it.
	func set_entry(objective_id: StringName, status: QuestManager.SuccessStatus = QuestManager.SuccessStatus.UNKNOWN) -> void:
		if _entries.has(objective_id):
			_entries[objective_id].success_status = status
		else:
			var new_entry: NFQuestLogStatusEntry = NFQuestLogStatusEntry.new(status)
			new_entry._flags = _flags
			_entries[objective_id] = new_entry
	
	
	## Gets a objective log object.
	func get_entry(objective_id: StringName) -> NFQuestLogStatusEntry:
		if _entries.has(objective_id):
			return _entries[objective_id]
		return null
	
	
	## Returns the status of an objective or [enum QuestManager.SuccessStatus.UNKNOWN]
	## if the entry doesn't exist.
	func get_status(objective_id: StringName) -> QuestManager.SuccessStatus:
		if _entries.has(objective_id):
			return _entries[objective_id].success_status
		return QuestManager.SuccessStatus.UNKNOWN
	
	
	## Returns the logged objectives data as a dictionary.
	func objective_data() -> Dictionary[StringName, int]:
		var objective_data: Dictionary[StringName, int] = {}
		
		for id in _entries.keys():
			objective_data[id] = _entries[id].success_status
		return objective_data
	
	
	## Returns if there is an objective [param entry] in the log.
	func has(entry: StringName) -> bool:
		return _entries.has(entry)
	
	
	## Erases an objective [param entry] from the log.
	func erase(entry: StringName) -> bool:
		return _entries.erase(entry)
	
	
	## Erases all the objective entries of the log.
	func clear() -> void:
		_entries.clear()
