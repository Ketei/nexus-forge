@tool
class_name PortraitTextureRect
extends TextureRect


@export var portrait_frames: SpriteFrames : set = set_portrait_frames
@export var frame: int = -1 : set = set_frame
@export var playing: bool = false: set = set_playing

var animation_name: StringName: set = set_anim_name

var _animation_control: AnimatedSprite2D


func _ready() -> void:
	expand_mode = EXPAND_IGNORE_SIZE
	stretch_mode = STRETCH_KEEP_ASPECT_COVERED
	_animation_control = AnimatedSprite2D.new()
	_animation_control.name = &"_animation_control"
	_animation_control.visible = false
	add_child(_animation_control, false, Node.INTERNAL_MODE_FRONT)
	
	_animation_control.sprite_frames = portrait_frames
	
	if portrait_frames != null:
		if _animation_control.sprite_frames.has_animation(animation_name):
			_animation_control.animation = animation_name
		_animation_control.frame = frame
		if playing:
			_animation_control.play()
	else:
		if playing:
			playing = false
	
	_animation_control.frame_changed.connect(_on_frame_changed)
	_animation_control.animation_finished.connect(_on_animation_finished)


## Plays and stops an animation
func set_playing(is_playing: bool) -> void:
	if not is_node_ready():
		playing = is_playing
		return
	playing = is_playing
	if playing:
		_animation_control.play()
	else:
		if _animation_control.is_playing():
			_animation_control.stop()


## Animations are controlled by this node. Don't delete or it'll stop working.
func get_anim_control() -> AnimatedSprite2D:
	return _animation_control


func set_frame(frame_index: int) -> void:
	if not is_node_ready():
		frame = frame_index
		return
	
	if portrait_frames == null:
		frame = -1
	else:
		frame = clampi(frame_index, -1, portrait_frames.get_frame_count(animation_name) - 1)
	
	if frame == -1:
		texture = null
	else:
		if frame == 0 and _animation_control.frame == 0:
			_on_frame_changed()
		_animation_control.frame = frame


func set_portrait_frames(new_frames: SpriteFrames) -> void:
	if not is_node_ready():
		portrait_frames = new_frames
		return
	_animation_control.sprite_frames = new_frames
	portrait_frames = new_frames
	var anim_names: PackedStringArray = new_frames.get_animation_names() if new_frames != null else PackedStringArray()
	notify_property_list_changed()
	if not anim_names.is_empty():
		animation_name = StringName(anim_names[0])
	frame = 0


func set_anim_name(new_name: StringName) -> void:
	if not is_node_ready():
		animation_name = new_name
		return
	if new_name.is_empty():
		frame = -1
		animation_name = new_name
	else:
		if _animation_control.sprite_frames != null and _animation_control.sprite_frames.has_animation(new_name):
			animation_name = new_name
			_animation_control.animation = new_name
			frame = 0
			if playing:
				_animation_control.play()
		else:
			if Engine.is_editor_hint():
				notify_property_list_changed()


func _on_frame_changed() -> void:
	texture = _animation_control.sprite_frames.get_frame_texture(
			_animation_control.animation,
			_animation_control.frame
			)


func _on_animation_finished() -> void:
	playing = false


func _get_property_list() -> Array[Dictionary]:
	@warning_ignore("incompatible_ternary")
	return [{
		"name": "animation_name",
		"type": TYPE_STRING_NAME,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(_animation_control.sprite_frames.get_animation_names() if portrait_frames != null else [])
	}]


func _set(property: StringName, value: Variant) -> bool:
	if property == &"animation_name":
		animation_name = value
		return true
	return false
