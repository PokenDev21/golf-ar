extends VBoxContainer

@onready var label: Label = $Label
@onready var back_button: Button = $Button

func _ready():
	visible = false
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	# 🔗 Connect to Game's signal
	if Engine.has_singleton("Game"):
		var game = Game
		if not game.is_connected("level_finished", Callable(self, "_on_level_finished")):
			game.connect("level_finished", Callable(self, "_on_level_finished"))
			print("[StrokeMenu] Connected to Game.level_finished")
	else:
		print("[StrokeMenu] ⚠️ Game singleton not found")

func _on_level_finished(level_id, strokes, par, result):
	print("[StrokeMenu] level_finished received:", level_id, strokes, par, result)
	update_score_display(level_id, strokes, par, result)
	show_menu()

func update_score_display(level_id, strokes, par, result):
	label.text = "Level: %s\nStrokes: %d\nPar: %d\nResult: %s" % [level_id, strokes, par, result]

func show_menu():
	print("[StrokeMenu] Showing stroke menu")
	var main = _find_node_global("Levels")
	var stroke = _find_node_global("StrokeMenu")
	if main: main.visible = false
	if stroke: stroke.visible = true
	visible = true

func _on_back_pressed():
	var main = _find_node_global("Levels")
	var stroke = _find_node_global("StrokeMenu")
	if main: main.visible = true
	if stroke: stroke.visible = false
	visible = false

func _find_node_global(name: String) -> Node:
	var root = get_tree().root
	for child in root.get_children():
		var found = child.find_child(name, true, false)
		if found:
			return found
	return null
