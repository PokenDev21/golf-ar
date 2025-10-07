extends RigidBody3D
# Ball with stroke counting, par, hole detection entry, reset behavior, and anti-clipping gravity.

@export var start_position: Vector3 = Vector3(0, 0.15, 0)
@export var par: int = 3
@export var debug_enabled: bool = true
@export var reset_y_threshold: float = -6.0  # lower so it truly fell off course

# Physics tuning
const BALL_MASS := 0.046
const LINEAR_DAMP := 0.0
const ANGULAR_DAMP := 0.0
const BOUNCE := 0.7
const FRICTION := 250

# Stroke tracking
var strokes: int = 0
var in_hole: bool = false

# RayCast offset below the ball to avoid self-collision
const RAY_OFFSET: Vector3 = Vector3(0, 0.01, -0.062)
@onready var raycast: RayCast3D = $"../RayCast3D"  # Adjust path if needed

signal ball_hit(strokes: int)
signal ball_in_hole(strokes: int, par: int)

func _ready() -> void:
	global_transform.origin = start_position
	mass = BALL_MASS
	linear_damp = LINEAR_DAMP
	angular_damp = ANGULAR_DAMP
	continuous_cd = true
	can_sleep = true  # allow sleeping normally; enter_hole will sleep explicitly

	# Physics material
	var mat: PhysicsMaterial = PhysicsMaterial.new()
	mat.bounce = BOUNCE
	mat.friction = FRICTION
	physics_material_override = mat

	if debug_enabled:
		print("[BALL] Ready. Par=", par, " start=", start_position)

func _physics_process(delta: float) -> void:
	# Reset ball if it fell off course
	if not in_hole and global_transform.origin.y < reset_y_threshold:
		if debug_enabled:
			print("[BALL] Fell below threshold, resetting...")
		reset_position()
	
	# Update raycast position to just under the ball
	if raycast:
		raycast.global_position = global_transform.origin + RAY_OFFSET
		# Ensure raycast always points straight down (-Y)
		raycast.global_rotation = Vector3.ZERO
		# Control gravity to prevent clipping
		if raycast.is_colliding():
			gravity_scale = 0.01
			print("Raycast colliding → gravity_scale set to 0")
		else:
			gravity_scale = 1.0
			print("Raycast not colliding → gravity_scale set to 1")

# Called by the club tracker once per (valid) hit
func register_stroke() -> void:
	if in_hole:
		return
	strokes += 1
	if debug_enabled:
		print("[BALL] Stroke registered. total=", strokes)
	emit_signal("ball_hit", strokes)

# Called by Hole.gd when the ball is detected inside the hole area
func enter_hole(hole: Area3D) -> void:
	if in_hole:
		return
	in_hole = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true
	if debug_enabled:
		print("[BALL] 🎉 Ball entered hole! Strokes=", strokes, " Par=", par)
	emit_signal("ball_in_hole", strokes, par)

# Reset the ball and strokes
func reset_position() -> void:
	global_transform.origin = start_position
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	strokes = 0
	in_hole = false

	sleeping = true
	await get_tree().process_frame
	sleeping = false

	if debug_enabled:
		print("[BALL] Reset to: ", start_position)
