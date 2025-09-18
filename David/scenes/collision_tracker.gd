extends CharacterBody3D
# Ghost club tracker for VR, applies soft impulse to balls

@export var tracker_group: String = "club_tracker"
@export var debug_enabled: bool = true
@export var ball_collision_layer: int = 1
@export var max_velocity_transfer: float = 10.0  # clamp ball impulse

var tracker: Node3D = null
var last_position: Vector3 = Vector3.ZERO
var club_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	call_deferred("_find_tracker")
	if debug_enabled:
		print("[TRACKER] Collision tracker ready")

func _find_tracker() -> void:
	tracker = get_tree().get_first_node_in_group(tracker_group) as Node3D
	if tracker == null:
		tracker = get_tree().root.find_child(tracker_group, true, false) as Node3D
	if tracker:
		last_position = tracker.global_transform.origin
		if debug_enabled:
			print("[TRACKER] ✅ Tracker found at: ", tracker.get_path())
	else:
		if debug_enabled:
			print("[TRACKER] ⚠ Tracker not found!")

func _physics_process(delta: float) -> void:
	if tracker == null or !is_instance_valid(tracker) or !tracker.is_inside_tree():
		return

	var current_pos: Vector3 = tracker.global_transform.origin
	club_velocity = (current_pos - last_position) / max(delta, 0.001)
	last_position = current_pos

	# Teleport the tracker collider to controller
	global_transform.origin = current_pos
	global_transform.basis = tracker.global_transform.basis

	# --- Detect overlapping balls ---
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var shape: Shape3D = $CollisionShape3D.shape
	var transform: Transform3D = $CollisionShape3D.global_transform

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape_rid = shape.get_rid()
	query.transform = transform
	query.collision_mask = 1 << (ball_collision_layer - 1)
	query.collide_with_bodies = true

	var results: Array = space_state.intersect_shape(query, 32)
	for raw_result in results:
		var result: Dictionary = raw_result
		var ball: RigidBody3D = result.get("collider") as RigidBody3D
		if ball != null:
			var collider_id: int = ball.get_instance_id()

			var impulse: Vector3 = club_velocity * ball.mass
			if impulse.length() > max_velocity_transfer:
				impulse = impulse.normalized() * max_velocity_transfer

			ball.apply_central_impulse(impulse)

			if debug_enabled:
				print("[TRACKER] Applied impulse to ball: ", ball.name, " id=", collider_id, " -> ", impulse)
