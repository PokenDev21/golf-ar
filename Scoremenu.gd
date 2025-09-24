extends Control
# Minimal score menu. Must have a Label child at $ScoreLabel.

@onready var score_label: Label = $Scorelabel

func _ready() -> void:
	visible = false

func show_score(strokes: int, par: int) -> void:
	visible = true
	var diff: int = strokes - par
	var result: String

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
