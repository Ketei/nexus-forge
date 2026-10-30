extends RefCounted


var anchor_nodes: Dictionary[String, String] = {}
var dialog_mergers: Dictionary[String, String] = {}
var uuid_to_id_conversions: Dictionary[String, StringName] = {}


func get_target(uuid: String) -> StringName:
	var target: String = _uuid_lookup(uuid)
	return uuid_to_id_conversions.get(target, &"")


func _uuid_lookup(uuid: String, _origin: String = "", _iteration: int = 0) -> StringName:
	if _origin == uuid or 100 <= _iteration:
		if 100 <= _iteration:
			NFPluginGameHandler._log_msg(
					"dialog - export",
					"Error: Over 99 anchor/joiner direct connections found. Breaking connection.\nAt this point, I'm pretty sure you're just drawing a picture of a worm. Please stop drawing worms.",
					NFPluginGameHandler._LogLevel.ERROR)
		return &""
	
	if _origin.is_empty():
		_origin = uuid
	
	if anchor_nodes.has(uuid):
		return _uuid_lookup(anchor_nodes[uuid], _origin, _iteration + 1)
	elif dialog_mergers.has(uuid):
		return _uuid_lookup(dialog_mergers[uuid], _origin, _iteration + 1)
	else:
		return uuid
