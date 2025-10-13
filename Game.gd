extends Node

signal level_started(level_id)
signal strokes_changed(strokes)
signal level_finished(level_id, strokes)

var current_level_id: String = ""
var current_level_path: String = ""
var strokes: int = 0
var last_result := { "level_id": "", "strokes": 0 }

func start_level(level_id: String) -> void:
	current_level_id = level_id
	current_level_path = "res://Levels/%s.tscn" % level_id
	strokes = 0
	emit_signal("level_started", level_id)
	get_tree().change_scene_to_file("res://Levels/GameShell.tscn")

func add_stroke(n: int = 1) -> void:
	strokes += n
	emit_signal("strokes_changed", strokes)

func finish_level() -> void:
	last_result = { "level_id": current_level_id, "strokes": strokes }
	emit_signal("level_finished", current_level_id, strokes)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
