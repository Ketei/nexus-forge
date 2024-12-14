@tool
class_name NFDiscourseTool
extends Node


## Emited when dialog text should be displayed
signal dialog_reached(dialog_text: String, character_id: String, dialog_speed: float)
## Emmited when a player choice is needed. {"text": dialog, "choice_idx": int}
signal choices_reached(choices: Array[Dictionary])
## Emmited when a conversation becomes paused
signal dialog_paused
## Emmited when a conversation enters ito a wait time.
signal wait_started(time: float)
## Emmited when a conversation continues from being either paused or waiting.
signal conversation_resumed
## Emmited when a dialog is finished.
signal dialog_finished

# ------------------------------------
# ---------- CUSTOM SIGNALS ----------
# ------------------------------------
signal sandwich_eaten(sammich_number: int, sammich_title: String)
# ------------------------------------

# signal(stringname) : [{type: int, name: str}]
var signal_registry: Dictionary = {
	&"sandwich_eaten": [{"type": TYPE_INT, "name": "Amount"}, {"type": TYPE_STRING, "name": "title"}]
	}

var alpha_timer: Timer = null

var _next_idx: int = -1
var _dialog_resource: DialogResource = null
var _dialog_paused: bool = false


func _ready() -> void:
	alpha_timer = Timer.new()
	add_child(alpha_timer)


## Loads a dialog resource file into Discourse. You can then start the dialog
## with [start_dialog]
func load_dialog(dialog_resource: DialogResource) -> void:
	_dialog_resource = dialog_resource


## Starts a dialog from the begining or at [param custom_idx] if provided.
func start_dialog(custom_idx: int = -1) -> void:
	_next_idx = _dialog_resource.entry_index if custom_idx < 0 else custom_idx
	_progress_conversation()


## Gets the value from a value output index defined by [param from].
func get_value(from: int) -> Variant:
	match _dialog_resource.conversation[from]["_type"]:
		DiscourseGraphNode.GraphType.VALUE:
			var type: DiscourseGraphNode.ValueType = _dialog_resource.conversation[from]["var_type"]
			if type == DiscourseGraphNode.ValueType.TYPE_VARIABLE:
				return NexusForge.Variables.get_variable(_dialog_resource.conversation[from]["value"])
			else:
				return _dialog_resource.conversation[from]["value"]
		DiscourseGraphNode.GraphType.MATH:
			var a: float = get_value(
					_dialog_resource.conversation[from]["a"])
			var b: float = get_value(
				_dialog_resource.conversation[from]["b"])
			
			match _dialog_resource.conversation[from]["operator"]:
				OP_POSITIVE:
					return a + b
				OP_NEGATE:
					return a - b
				OP_MULTIPLY:
					return a * b
				OP_DIVIDE:
					return a / b
				_:
					return 0.0
		DiscourseGraphNode.GraphType.EVAL:
			var a: Variant = get_value(
					_dialog_resource.conversation[from]["a"])
			var b: Variant = get_value(
				_dialog_resource.conversation[from]["b"])
			
			match _dialog_resource.conversation[from]["operator"]:
				OP_EQUAL:
					return a == b
				OP_NOT_EQUAL:
					return a != b
				OP_LESS:
					return a < b
				OP_LESS_EQUAL:
					return a <= b
				OP_GREATER:
					return a > b
				OP_GREATER_EQUAL:
					return a >= b
				_:
					return false
		DiscourseGraphNode.GraphType.RETURN_CALL:
			var callable: Callable = NexusForge.Callables.get_callable_return(_dialog_resource.conversation[from]["call_id"])
			var args: Array = []
			for arg in _dialog_resource.conversation[from]["call_args"]:
				args.append(
					arg["value"] if arg["id"] == -1 else get_value(arg["id"]))
			return callable.callv(args)
		_:
			return null


func _progress_conversation() -> void:
	if _next_idx == -1:
		dialog_finished.emit()
		_dialog_paused = false
		return
	
	match _dialog_resource.conversation[_next_idx]["_type"]:
		DiscourseGraphNode.GraphType.DIALOG:
			dialog_reached.emit(
					_dialog_resource.conversation[_next_idx]["text"],
					_dialog_resource.conversation[_next_idx]["character_id"],
					_dialog_resource.conversation[_next_idx]["speed"])
			_dialog_paused = true
			_next_idx = _dialog_resource.conversation[_next_idx]["next"]
		DiscourseGraphNode.GraphType.CHOICES:
			var choices: Array[Dictionary] = []
			var choice_idx: int = -1
			for choice in _dialog_resource.conversation[_next_idx]["choices"]:
				choice_idx += 1
				if choice["condition"] == -1 or get_value(choice["condition"]):
					choices.append({"text": choice["text"], "id": choice_idx})
			_dialog_paused = true
			choices_reached.emit(choices)
		DiscourseGraphNode.GraphType.WAIT:
			wait_started.emit(_dialog_resource.conversation[_next_idx]["wait_time"])
			_next_idx = _dialog_resource.conversation[_next_idx]["next"]
			_dialog_paused = true
		DiscourseGraphNode.GraphType.PAUSE:
			_dialog_paused = true
			_next_idx = _dialog_resource.conversation[_next_idx]["next"]
		DiscourseGraphNode.GraphType.EVENT:
			# --- VARIABLE ---
			for set_id in _dialog_resource.conversation[_next_idx]["variables"]:
				NexusForge.Variables.set_variable(
						_dialog_resource.conversation[set_id]["path"],
						_dialog_resource.conversation[set_id]["value"] if _dialog_resource.conversation[set_id]["direct"] else get_value(_dialog_resource.conversation[set_id]["value"]))
			# --- CALLABLE ---
			for call_id in _dialog_resource.conversation[_next_idx]["callables"]:
				var call_args: Array = []
				for arg in _dialog_resource.conversation[call_id]["call_args"]:
					call_args.append(
						arg["value"] if arg["id"] == -1 else get_value(arg["id"]))
				NexusForge.Callables.get_callable(_dialog_resource.conversation[call_id]["call_id"]).callv(call_args)
			# --- SIGNAL ---
			for signal_id in _dialog_resource.conversation[_next_idx]["signals"]:
				var sign_args: Array = []
				sign_args.append(
						_dialog_resource.conversation[_next_idx]["signal"])
				for argument in _dialog_resource.conversation[_next_idx]["arguments"]:
					sign_args.append(
						argument["value"] if argument["id"] == -1 else get_value(argument["id"]))
				emit_signal.callv(sign_args)
			# ---------------
			_next_idx = _dialog_resource.conversation[_next_idx]["next"]
		DiscourseGraphNode.GraphType.CONDITIONAL_DIALOG:
			if _dialog_resource.conversation[_next_idx]["result"] == -1 or get_value(_dialog_resource.conversation[_next_idx]["result"]):
				_next_idx = _dialog_resource.conversation[_next_idx]["true"]
			else:
				_next_idx = _dialog_resource.conversation[_next_idx]["false"]
		DiscourseGraphNode.GraphType.MATCH:
			var val_match: Variant = get_value(_dialog_resource.conversation[_next_idx]["match"]) if _dialog_resource.conversation[_next_idx]["match"] != -1 else null
			_next_idx = _dialog_resource.conversation[_next_idx]["default"]
			if val_match != null:
				for case in _dialog_resource.conversation[_next_idx]["cases"]:
					if val_match == case["value"]:
						_next_idx = case["next"]
						break
		DiscourseGraphNode.GraphType.RANDOM:
			if _dialog_resource.conversation[_next_idx]["use_weights"]:
				var new_weighted := Random.create_weighted_pool()
				for exit in _dialog_resource.conversation[_next_idx]["exits"]:
					new_weighted.add_weighted(exit["next"], exit["weight"])
				_next_idx = new_weighted.pick_weighted()
			else:
				_next_idx = _dialog_resource.conversation[_next_idx]["exits"].pick_random()["next"]
		DiscourseGraphNode.GraphType.JUMP:
			_next_idx = _dialog_resource.conversation[_next_idx]["next"]
		DiscourseGraphNode.GraphType.JUMP_TARGET:
			_next_idx = _dialog_resource.conversation[_next_idx]["next"]
		DiscourseGraphNode.GraphType.END:
			_next_idx = -1
	
	if _dialog_paused:
		dialog_paused.emit()
	else:
		_progress_conversation()


## Use it to continue a conversation when it's paused or when to progress
## through a conversation.
func continue_dialog() -> void:
	if not alpha_timer.is_stopped():
		alpha_timer.stop()
	if _dialog_paused:
		_dialog_paused = false
		conversation_resumed.emit()
	_progress_conversation()


## Use it to continue a conversation when a choice is required. Don't use
## unless dialog is in a choice index. You can check with
## [is_current_choice_index]
func select_choice(idx: int) -> void:
	_next_idx = _dialog_resource.conversation[_next_idx]["choices"][idx]["next"]
	continue_dialog()


## Returns true if the conversation is paused.
func is_conversation_paused() -> bool:
	return _dialog_paused


## Returns true if the conversation is paused via a wait event.
func is_conversation_waiting() -> bool:
	return not alpha_timer.is_stopped()


func is_current_choice_index() -> bool:
	if _next_idx == -1 or _dialog_resource.conversation[_next_idx]["_type"] != DiscourseGraphNode.GraphType.CHOICES:
		return false
	return true

func get_discourse_signals() -> Array[StringName]:
	return Array(signal_registry.keys(), TYPE_STRING_NAME, &"", null)


func get_signal_args(signal_name: StringName) -> Array[Dictionary]:
	return Array(signal_registry[signal_name].duplicate(), TYPE_DICTIONARY, &"", null)
