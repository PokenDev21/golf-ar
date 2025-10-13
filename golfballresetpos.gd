extends RigidBody3D

@export var par: int = 3
@export var debug_enabled: bool = true
@export var reset_y_threshold: float = -6.0

var strokes: int = 0
var in_hole: bool = false

const BALL_MASS := 0.046
const LINEAR_DAMP := 0.0
const ANGULAR_DAMP := 0.0
const BOUNCE := 0.7
const FRICTION := 150

const RAY_OFFSET: Vector3 = Vector3(0,0.01,0)
@onready var raycast: RayCast3D = $"../RayCast3D"

signal ball_hit(strokes: int)
signal ball_in_hole(strokes: int, par: int)

func _ready() -> void:
	mass = BALL_MASS
	linear_damp = LINEAR_DAMP
	angular_damp = ANGULAR_DAMP
	continuous_cd = true
	can_sleep = true

	var mat = PhysicsMaterial.new()
	mat.bounce = BOUNCE
	mat.friction = FRICTION
	physics_material_override = mat

	if debug_enabled:
		print("[BALL] Ready. Par=", par)

func _physics_process(delta: float) -> void:
	if not in_hole and global_transform.origin.y < reset_y_threshold:
		if debug_enabled:
			print("[BALL] Fell below threshold, resetting...")
		reset_ball()

	if raycast:
		raycast.global_position = global_transform.origin + RAY_OFFSET
		raycast.global_rotation = Vector3.ZERO
		gravity_scale = 0.01 if raycast.is_colliding() else 1.0

func register_stroke() -> void:
	if in_hole:
		return
	strokes += 1
	if debug_enabled:
		print("[BALL] Stroke registered. Total=", strokes)
	emit_signal("ball_hit", strokes)
	Game.add_stroke()  # update singleton

func enter_hole(hole: Area3D) -> void:
	if in_hole:
		return
	in_hole = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true
	if debug_enabled:
		print("[BALL] Entered hole! Strokes=", strokes)
	emit_signal("ball_in_hole", strokes, par)
	Game.finish_level()

func reset_ball() -> void:
	# Do not override start position; stay where GameShell placed it
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	strokes = 0
	in_hole = false
	sleeping = true
	await get_tree().process_frame
	sleeping = false
