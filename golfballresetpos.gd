extends RigidBody3D

var start_position: Vector3
const RESET_Y_THRESHOLD := -2.0   # if ball falls below this, reset it

func _ready() -> void:
	start_position = global_transform.origin
	print("[BALL] Spawn position saved at: ", start_position)

func _physics_process(delta: float) -> void:
	if global_transform.origin.y < RESET_Y_THRESHOLD:
		print("[BALL] ⚠️ Fell into hole or out of bounds — resetting...")
		reset_position()

func reset_position() -> void:
	
	var xform = global_transform
	xform.origin = start_position
	global_transform = xform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true
	await get_tree().process_frame  # wait one frame
	# Restore collisions
	sleeping = false


func _wake_up() -> void:
	sleeping = false
