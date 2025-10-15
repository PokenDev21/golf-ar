extends Node
 
signal level_started(level_id)
signal strokes_changed(strokes)
 
var current_level_id := ""
var current_level_path := ""
var strokes := 0
 
var last_result := ""
var last_strokes := 0
var last_par := 0
 
 
func start_level(level_id: String) -> void:
	current_level_id = level_id
	current_level_path = "res://Levels/%s.tscn" % level_id
	strokes = 0
	emit_signal("level_started", level_id)
	get_tree().change_scene_to_file("res://Levels/GameShell.tscn")
 
 
func add_stroke(n := 1) -> void:
	strokes += n
	emit_signal("strokes_changed", strokes)
 
 
func finish_level(strokes_: int, par_: int, result_: String) -> void:
	last_strokes = strokes_
	last_par = par_
	last_result = result_
	print("[GAME] === Finishing Level ===")
	print("[GAME] Result:%s Strokes:%d Par:%d" % [result_, strokes_, par_])
 
	# Cleanup current level
	var cs = get_tree().current_scene
	if cs:
		if cs.has_method("cleanup_before_exit"):
			cs.cleanup_before_exit()
		for c in cs.get_children():
			c.queue_free()
		await get_tree().process_frame
		cs.queue_free()
		await get_tree().process_frame
		get_tree().set_current_scene(null)
 
	print("[GAME] Scene cleanup complete, returning to menu.")
	await get_tree().process_frame
 
	# Switch back to main menu
	get_tree().change_scene_to_file("res://StartScene/golf_start_scene.tscn")
 
	# Wait for menu to fully load
	await get_tree().process_frame
	await get_tree().process_frame
 
	# 🔍 Find StrokeMenu and its VBoxContainer script
	var stroke_menu_container: Node = null
	var scene_root = get_tree().current_scene
	if scene_root:
		var stroke_menu_control = scene_root.find_child("StrokeMenu", true, false)
		if stroke_menu_control:
			# look for its VBoxContainer child (the one with the script)
			for child in stroke_menu_control.get_children():
				if child is VBoxContainer:
					stroke_menu_container = child
					break
 
	if stroke_menu_container:
		print("[GAME] ✅ Found StrokeMenu script container, updating UI directly")
		if stroke_menu_container.has_method("_on_level_finished"):
			stroke_menu_container._on_level_finished(current_level_id, last_strokes, last_par, last_result)
		elif stroke_menu_container.has_method("update_score_display"):
			stroke_menu_container.update_score_display(current_level_id, last_strokes, last_par, last_result)
		if stroke_menu_container.has_method("show_menu"):
			stroke_menu_container.show_menu()
	else:
		print("[GAME] ⚠️ Could not find StrokeMenu VBoxContainer after scene load")
