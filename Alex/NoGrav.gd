extends RigidBody3D

@onready var raycast: RayCast3D = $"../RayCast3D"

# Offset under the ball to prevent self-collision
const RAY_OFFSET: Vector3 = Vector3(0, -0.034, 0)

func _physics_process(delta: float) -> void:
	# Keep the raycast just below the ball
	raycast.global_position = global_position + RAY_OFFSET

	# Make sure it always points straight down in world space (-Y)
	raycast.global_rotation = Vector3.ZERO

	# Control gravity based on collision
	gravity_scale = 0.0 if raycast.is_colliding() else 1.0
