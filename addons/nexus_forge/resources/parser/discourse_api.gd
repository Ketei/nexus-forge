class_name DiscourseAPI
extends RefCounted
## Object that contains the signals and methods called by Discourse.
##
## Discourse can only type the arguments of type integer, float, bool and string.
## Any other method's/signal's argument type will be displayed as a variant (any type).


signal sandwich_eaten(eaten_whole: bool, time_taken: int)
signal bear_poked

var rat_startled: bool = false


func get_player_name(override: String = "Shibju") -> String:
	return override


func get_character_display_name(character_id: String) -> String:
	if has_met_character(character_id):
		return "James"
	else:
		return "??????"

func get_james_dialog() -> String:
	if randi_range(0, 100) <= 90:
		return "Hello! How are you?"
	else:
		rat_startled = true
		return "Squeeeak!!"

func has_met_character(character_id: String) -> bool:
	return true


func start_quest(quest_id: String) -> void:
	return

func poke_wulfre(with_stick: bool, amout: int) -> void:
	pass


func eat_sammich(salsa: bool, pickles: int = 10) -> void:
	return


func sammich(salsa: bool, pickles: int = 10) -> String:
	return ""
