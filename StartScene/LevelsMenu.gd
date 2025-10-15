extends HBoxContainer

func _ready():
	# Connect all buttons to handler
	for child in get_children():
		if child is Button:
			child.pressed.connect(_on_level_button_pressed.bind(child.name))

	# Optional: show last result
	if has_node("LastResultLabel"):
		var label = $LastResultLabel
		if Game.last_result == "":
			label.text = "No results yet"
		else:
			label.text = "Last: %s — Strokes: %d (Par %d)" % [Game.last_result, Game.last_strokes, Game.last_par]

func _on_level_button_pressed(level_name):
	Game.start_level(level_name)
	print("Level pressed:", level_name)
