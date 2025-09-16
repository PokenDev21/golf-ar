extends RigidBody3D

var start_position: Vector3
const RESET_Y_THRESHOLD := -2.0   # if ball falls below this, reset it

func _ready() -> void:
	# Remember where the ball started
	start_position = global_transform.origin
	print("[BALL] Spawn position saved at: ", start_position)

func _physics_process(delta: float) -> void:
	# If ball fell too low, reset it
	if global_transform.origin.y < RESET_Y_THRESHOLD:
		print("[BALL] ⚠️ Fell into hole or out of bounds — resetting...")
		reset_position()

func reset_position() -> void:
	# Teleport ball back to start
	global_transform.origin = start_position
	
	# Reset velocity so it doesn’t keep rolling
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
