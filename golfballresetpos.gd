# GolfBall.gd
extends RigidBody3D

var start_position: Vector3 = Vector3(0, 0.15, 0)
const RESET_Y_THRESHOLD := -2.0

@export var debug_enabled: bool = true

# Physics settings
const BALL_MASS := 1.0
const LINEAR_DAMP := 0.01
const ANGULAR_DAMP := 0.01
const BOUNCE := 0.7
const FRICTION := 0.5

func _ready() -> void:
	global_transform.origin = start_position
	mass = BALL_MASS
	linear_damp = LINEAR_DAMP
	angular_damp = ANGULAR_DAMP
	continuous_cd = true

	# Assign physics material directly to the RigidBody3D
	var mat = PhysicsMaterial.new()
	mat.bounce = BOUNCE
	mat.friction = FRICTION
	physics_material_override = mat

	if debug_enabled:
		print("[BALL] Spawn position set to: ", start_position)
		print("[BALL] Bounce=", BOUNCE, " Friction=", FRICTION)

func _physics_process(delta: float) -> void:
	if global_transform.origin.y < RESET_Y_THRESHOLD:
		if debug_enabled:
			print("[BALL] ⚠️ Fell below threshold — resetting...")
		reset_position()

func reset_position() -> void:
	global_transform.origin = start_position
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	sleeping = true
	await get_tree().process_frame
	sleeping = false

	if debug_enabled:
		print("[BALL] Reset to: ", start_position)

func _wake_up() -> void:
	sleeping = false
