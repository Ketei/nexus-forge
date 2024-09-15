class_name DeltaTimer
extends Node
## A timer class made for very short timers. 
##
## A timer to measure very short times. Not very precise. Unaffected by
## Engine.time_scale.


signal delta_timeout

var wait_delta: float = 1.0
var elapsed_delta: float = 0.0


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	elapsed_delta += delta
	if wait_delta <= elapsed_delta:
		set_process(false)
		delta_timeout.emit()


func delta_timer_start(time: float) -> DeltaTimer:
	var target_time: float = maxf(0, time)
	elapsed_delta = 0
	wait_delta = target_time
	set_process(true)
	return self
