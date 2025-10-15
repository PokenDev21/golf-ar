extends Control
# Must have a Label child called "ScoreLabel"

@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	visible = false

func show_score(strokes: int, par: int, result: String = "") -> void:
	visible = true

	var diff: int = strokes - par
	if result == "":
		if diff == 0:
			result = "Par"
		elif diff == -1:
			result = "Birdie"
		elif diff == -2:
			result = "Eagle"
		elif diff <= -3:
			result = "Albatross"
		elif diff == 1:
			result = "Bogey"
		elif diff == 2:
			result = "Double Bogey"
		else:
			result = str(diff) + " over Par"

	score_label.text = "Strokes: %d\nPar: %d\nResult: %s" % [strokes, par, result]
	print("[ScoreLabel] Showing score:", score_label.text)
