extends Node
# Connects the ball's 'ball_in_hole' signal to the ScoreMenu and optionally logs ball hits.
# Edit the NodePath exports if your node names differ.

@export var ball_path: NodePath = NodePath("GolfBall")
@export var score_menu_path: NodePath = NodePath("ScoreMenu")

@onready var ball_node: Node = get_node_or_null(ball_path)
@onready var score_menu: Node = get_node_or_null(score_menu_path)

func _ready() -> void:
	if ball_node == null:
		push_warning("GameManager: ball node not found at path: %s" % ball_path)
		return
	if score_menu == null:
		push_warning("GameManager: score_menu not found at path: %s" % score_menu_path)
		return

	# Connect the ball_in_hole signal to this manager (then show the menu)
	if not ball_node.is_connected("ball_in_hole", Callable(self, "_on_ball_in_hole")):
		ball_node.connect("ball_in_hole", Callable(self, "_on_ball_in_hole"))

	# Optional: listen to ball_hit to do UI updates while playing
	if not ball_node.is_connected("ball_hit", Callable(self, "_on_ball_hit")):
		ball_node.connect("ball_hit", Callable(self, "_on_ball_hit"))

func _on_ball_in_hole(strokes: int, par: int) -> void:
	if score_menu and score_menu.has_method("show_score"):
		score_menu.show_score(strokes, par)
	else:
		print("[GameManager] Ball in hole: strokes=%d, par=%d" % [strokes, par])

func _on_ball_hit(strokes: int) -> void:
	# Could update a live counter in the HUD; for now just print
	print("[GameManager] Ball hit. strokes=", strokes)
