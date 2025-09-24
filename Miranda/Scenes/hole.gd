extends Area3D
# Call enter_hole on the ball when body enters the hole area.
@export var debug_enabled: bool = true

func _ready() -> void:
	monitoring = true
	monitorable = true
	# connect body_entered in code (so no editor wiring required)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	# We expect a RigidBody3D with a public enter_hole() method (GolfBall.gd provides it)
	if body is RigidBody3D and body.has_method("enter_hole"):
		if debug_enabled:
			print("[HOLE] Body entered:", body.name)
		body.enter_hole(self)
