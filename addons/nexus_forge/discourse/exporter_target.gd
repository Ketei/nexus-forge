extends RefCounted


var anchor_nodes: Dictionary[StringName, StringName] = {}
var dialog_mergers: Dictionary[StringName, StringName] = {}
var uuid_to_id_conversions: Dictionary[StringName, StringName] = {}


func get_target(uuid: StringName, _origin: StringName = &"", _iteration: int = 0) -> StringName:
	var target: StringName = _uuid_lookup(uuid, _origin, _iteration)
	if uuid_to_id_conversions.has(target):
		return uuid_to_id_conversions[target]
	else:
		NFPluginGameHandler._log_msg(
					"dialog - export",
					"Couldn't find ID for node with UUID " + String(uuid),
					NFPluginGameHandler._LogLevel.ERROR)
		return target


func _uuid_lookup(uuid: StringName, _origin: StringName = &"", _iteration: int = 0) -> StringName:
	if _origin == uuid or 100 <= _iteration:
		if 100 <= _iteration:
			printerr("Error: Over 99 anchor/joiner direct connections found. Breaking connection.\nAt this point, I'm pretty sure you're just drawing a picture of a worm. Please stop drawing worms.")
		return &""
	
	if _origin.is_empty():
		_origin = uuid
	
	if anchor_nodes.has(uuid):
		return get_target(anchor_nodes[uuid], _origin, _iteration + 1)
	elif dialog_mergers.has(uuid):
		return get_target(dialog_mergers[uuid], _origin, _iteration + 1)
	else:
		return uuid
