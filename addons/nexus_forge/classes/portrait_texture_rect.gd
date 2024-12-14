@tool
class_name PortraitTextureRect
extends TextureRect


signal animation_finished

@export var portrait_frames: SpriteFrames : set = set_portrait_frames
@export var frame: int = -1 : set = set_frame
@export var playing: bool = false: set = set_playing

var current_animation: StringName: set = set_anim_name

var _animation_control: AnimatedSprite2D = null
var _delta_time: float = 0.0
var _queued_frames: int = 0
var _delta_timeout: float = 0.0


func _ready() -> void:
	expand_mode = EXPAND_IGNORE_SIZE
	stretch_mode = STRETCH_KEEP_ASPECT_COVERED
	set_process(false)


func _process(delta: float) -> void:
	_delta_time += delta
	if _delta_timeout <= _delta_time:
		_queued_frames = int(_delta_time / _delta_timeout)
		frame += _queued_frames
		_delta_time -= _delta_timeout * _queued_frames


## Plays and stops an animation
func set_playing(is_playing: bool) -> void:
	_delta_time = 0
	if is_playing:
		playing = portrait_frames != null and 0 < portrait_frames.get_frame_count(current_animation)
	else:
		playing = false
	
	
	if playing:
		_delta_timeout = 1.0 / portrait_frames.get_animation_speed(current_animation)
	set_process(playing)


func get_animations() -> PackedStringArray:
	if portrait_frames != null:
		return portrait_frames.get_animation_names()
	return PackedStringArray()


func set_frame(frame_index: int) -> void:
	if portrait_frames != null:
		var frame_limit: int = portrait_frames.get_frame_count(current_animation)
		
		if frame_limit == 0:
			frame = -1
			return
		
		if portrait_frames.get_animation_loop(current_animation):
			frame = posmod(frame_index, frame_limit)
		else:
			frame = clampi(frame_index, -1, frame_limit)
			if playing:
				if frame == frame_limit - 1:
					animation_finished.emit()
					playing = false
	else:
		frame = -1
	
	texture = get_current_frame_texture()


func get_current_frame_texture() -> Texture2D:
	if portrait_frames != null and -1 < frame and portrait_frames.has_animation(current_animation):
		return portrait_frames.get_frame_texture(
				current_animation,
				frame)
	return null


func set_portrait_frames(new_frames: SpriteFrames) -> void:
	if portrait_frames != null:
		portrait_frames.changed.disconnect(on_frames_updated)
	
	portrait_frames = new_frames
	notify_property_list_changed()
		
	if new_frames != null:
		new_frames.changed.connect(on_frames_updated)
		print(new_frames.get_signal_list())
	else:
		frame = -1
		playing = false
		return
	
	var anim_names: PackedStringArray = new_frames.get_animation_names()
	
	if not anim_names.is_empty():
		current_animation = anim_names[0]
		frame = 0
	else:
		#current_animation = &"" # Does this clear the thing?
		frame = -1


func on_frames_updated() -> void:
	notify_property_list_changed()
	var anim_count: int = portrait_frames.get_animation_names().size()
	if anim_count == 0:
		playing = false
		frame = -1
		return
	
	if playing:
		if 0 < portrait_frames.get_frame_count(current_animation):
			_delta_timeout = 1.0 / portrait_frames.get_animation_speed(current_animation)
		else:
			playing = false


func set_anim_name(new_name: StringName) -> void:
	current_animation = new_name
	frame = 0


func _get_property_list() -> Array[Dictionary]:
	return [{
		"name": "current_animation",
		"type": TYPE_STRING_NAME,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(get_animations())
	}]


func _set(property: StringName, value: Variant) -> bool:
	if property == &"current_animation":
		current_animation = value
		return true
	return false
