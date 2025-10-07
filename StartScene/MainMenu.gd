extends BoxContainer

func _ready():
	# Connect all button children to one handler
	for child in get_children():
		if child is Button:
			print("Level pressed")
			child.pressed.connect(_on_level_button_pressed.bind(child.name))

	# Optional: show last result if you have a label named "LastResultLabel"
	if has_node("LastResultLabel"):
		var r = Game.last_result
		var label = $LastResultLabel
		if r["level_id"] == "":
			label.text = "No results yet"
		else:
			label.text = "Last Played: %s — Strokes: %d" % [r["level_id"], r["strokes"]]

func _on_level_button_pressed(level_name):
	Game.start_level(level_name)
