extends ConfirmationDialog

var message: String = "":
	set(new_msg):
		message = new_msg
		if is_node_ready():
			_label.text = message
var _label: Label = null


func _ready() -> void:
	size = Vector2i(280, 130)
	initial_position = WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	
	_label = Label.new()
	_label.text = message
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(150, 50)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)
	
