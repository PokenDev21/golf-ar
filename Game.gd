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

	print("[GAME] === Finishing Level ===")
	var current_scene = get_tree().current_scene
	if current_scene:
		print("[GAME] Cleaning up current scene:", current_scene.name)
		if current_scene.has_method("cleanup_before_exit"):
			current_scene.cleanup_before_exit()
		else:
			print("[GAME] No cleanup method on scene.")

		# Explicitly delete every child node under the current scene
		for child in current_scene.get_children():
			print("[GAME] Freeing child node:", child.name)
			child.queue_free()

		await get_tree().process_frame

		# Remove the current scene itself
		print("[GAME] Freeing the current scene root...")
		current_scene.queue_free()
		await get_tree().process_frame
		get_tree().set_current_scene(null)
	else:
		print("[GAME] No current scene found to clean up!")

	print("[GAME] Scene cleanup complete. Waiting one frame before menu...")
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://StartScene/golf_start_scene.tscn")
