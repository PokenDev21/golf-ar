extends CharacterBody3D
# Ghost club tracker for VR, applies a single soft impulse per contact and registers strokes.

@export var tracker_group: String = "club_tracker"
@export var debug_enabled: bool = true
@export var ball_collision_layer: int = 1
@export var max_velocity_transfer: float = 10.0  # max impulse magnitude

var tracker: Node3D = null
var last_position: Vector3 = Vector3.ZERO
var club_velocity: Vector3 = Vector3.ZERO

# tracking which balls we've already applied an impulse to while overlapping
var _hit_flags: Dictionary = {} # key: instance_id (int) -> bool
# helper to map instance_id -> RigidBody3D (so we can clear flags cleanly)
var _current_overlaps: Dictionary = {} # key: instance_id (int) -> RigidBody3D

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

	# Move the tracker collider to the controller
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

	# Build new overlap list for this frame
	var new_overlap_ids: Array = []

	for raw_result in results:
		var result: Dictionary = raw_result as Dictionary
		var ball: RigidBody3D = result.get("collider") as RigidBody3D
		if ball == null:
			continue

		var iid: int = ball.get_instance_id()
		new_overlap_ids.append(iid)
		_current_overlaps[iid] = ball

		# If we haven't already hit this ball during this overlap, apply a single impulse
		if not _hit_flags.has(iid) or _hit_flags[iid] == false:
			# compute impulse (simple transfer; tune if you want)
			var impulse: Vector3 = club_velocity * ball.mass
			
			# zero out vertical component so impulse only affects XZ
			impulse.y = 0.0

			# clamp magnitude
			if impulse.length() > max_velocity_transfer:
				impulse = impulse.normalized() * max_velocity_transfer

			# apply impulse once
			ball.apply_central_impulse(impulse)

			# register stroke on the ball if it supports it
			if ball.has_method("register_stroke"):
				ball.register_stroke()

			_hit_flags[iid] = true

			if debug_enabled:
				print("[TRACKER] Hit ball:", ball.name, " id=", iid, " impulse=", impulse)

	# Clear flags for balls that are no longer overlapping so they can be hit again later
	var to_remove: Array = []
	for key in _hit_flags.keys():
		if not new_overlap_ids.has(key):
			to_remove.append(key)
	for key in to_remove:
		_hit_flags.erase(key)
		_current_overlaps.erase(key)
