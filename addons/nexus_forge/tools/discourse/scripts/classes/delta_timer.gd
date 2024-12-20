class_name DeltaTimer
extends Node
## A timer class made for very short timers. 
##
## A timer to measure very short times. Not very precise. Unaffected by
## Engine.time_scale.


signal delta_timeout

var wait_time: float = 1.0
var elapsed_delta: float = 0.0
var _finished: bool = false
var _paused: bool = false


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	elapsed_delta += delta
	if wait_time <= elapsed_delta:
		set_physics_process(false)
		delta_timeout.emit()


func start(time: float = 0.0) -> DeltaTimer:
	var target_time: float = maxf(0, time)
	elapsed_delta = 0
	if 0 < time:
		wait_time = maxf(target_time, 0.01)
	if not _paused:
		set_physics_process(true)
	_finished = false
	return self


func pause(pause_timer: bool) -> void:
	_paused = pause_timer
	if not _finished:
		set_physics_process(pause_timer)


## Returns if the timmer isn't stopped. A timer that has been paused but hasn't
## timed out or being stopped will count as a not stopped timer.
func is_stopped() -> bool:
	return _finished


func is_paused() -> bool:
	return _paused


func stop() -> void:
	set_physics_process(false)
	elapsed_delta = 0
	_finished = true
	_paused = false
