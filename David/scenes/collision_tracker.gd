extends CharacterBody3D
# Follows a Marker3D (or any Node3D) that is in the given group, e.g. "club_tracker".

@export var tracker_group: String = "club_tracker"
@export var max_speed: float = 10.0
@export var max_accel: float = 50.0
@export_range(0.0, 1.0) var rot_lerp: float = 0.25
@export var debug_enabled: bool = true
@export var use_direct_positioning: bool = false  # Skip physics, directly set position
@export var disable_gravity: bool = true  # Disable gravity for 3D tracking
@export var setup_collision_layers: bool = true  # Auto-setup collision layers
@export var collision_layer_bit: int = 1  # What layer this object is on
@export var collision_mask_bits: int = 0  # What layers this object collides with (0 = none)

var tracker: Node3D = null
var refind_cooldown := 0.0
var search_attempts := 0
var max_search_attempts := 20  # Try for ~5 seconds (20 * 0.25s)

func _ready() -> void:
	# Setup collision layers
	if setup_collision_layers:
		collision_layer = 1 << (collision_layer_bit - 1)  # Set which layer we're on
		collision_mask = collision_mask_bits  # Set what we collide with (0 = nothing)
		if debug_enabled:
			print("[TRACKER] Collision layer: ", collision_layer, " | Collision mask: ", collision_mask)
	
	if debug_enabled:
		print("[TRACKER] Script starting on node: ", name)
		print("[TRACKER] Looking for group: ", tracker_group)
		print("[TRACKER] Current scene tree ready state: ", get_tree().current_scene != null)
		print("[TRACKER] Gravity disabled: ", disable_gravity)
	
	# Multiple deferred attempts to ensure everything is loaded
	call_deferred("_delayed_search", 0.1)
	call_deferred("_delayed_search", 0.5)
	call_deferred("_delayed_search", 1.0)
	
	# Keep watching the tree for new nodes
	get_tree().node_added.connect(_on_node_added)
	
	# Also try periodic searches
	var timer = Timer.new()
	timer.wait_time = 0.25
	timer.timeout.connect(_periodic_search)
	timer.autostart = true
	add_child(timer)

func _delayed_search(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if tracker == null:
		if debug_enabled:
			print("[TRACKER] Attempting delayed search after ", delay, " seconds")
		_comprehensive_search()

func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)

func _on_node_added(n: Node) -> void:
	if tracker != null:
		return
	
	if debug_enabled:
		print("[TRACKER] New node added: ", n.name, " (type: ", n.get_class(), ")")
	
	if n is Node3D and n.is_in_group(tracker_group):
		tracker = n
		if debug_enabled:
			print("[TRACKER] ✓ Found tracker via node_added signal: ", tracker.name)
			print("[TRACKER] Tracker position: ", tracker.global_transform.origin)

func _comprehensive_search() -> void:
	if debug_enabled:
		print("[TRACKER] === Starting comprehensive search (attempt ", search_attempts + 1, ") ===")
		
		# Debug: Print all nodes in the group
		var group_nodes = get_tree().get_nodes_in_group(tracker_group)
		print("[TRACKER] Nodes in group '", tracker_group, "': ", group_nodes.size())
		for node in group_nodes:
			print("[TRACKER] - ", node.name, " (", node.get_class(), ") - Path: ", node.get_path())
			if node is Node3D:
				print("[TRACKER]   Position: ", (node as Node3D).global_transform.origin)
				print("[TRACKER]   In tree: ", node.is_inside_tree())
				print("[TRACKER]   Valid: ", is_instance_valid(node))
		
		# Debug: Print scene structure (deeper search)
		print("[TRACKER] Scene structure:")
		_debug_print_scene_tree(get_tree().current_scene, 0, 6)
		
		# Special search within GolfGlubbaScene if it exists
		var golf_scene = _find_node_by_name(get_tree().current_scene, "GolfGlubbaScene")
		if golf_scene:
			print("[TRACKER] === Searching within GolfGlubbaScene ===")
			_debug_print_scene_tree(golf_scene, 0, 4)
	
	_find_best_tracker()

func _debug_print_scene_tree(node: Node, depth: int, max_depth: int) -> void:
	if depth > max_depth or node == null:
		return
	
	var indent = "  ".repeat(depth)
	var group_info = ""
	if node.is_in_group(tracker_group):
		group_info = " [IN TARGET GROUP]"
	
	var type_info = node.get_class()
	if node is Marker3D:
		type_info += " ⭐"  # Special marker for Marker3D nodes
	
	print("[TRACKER] ", indent, node.name, " (", type_info, ")", group_info)
	
	for child in node.get_children():
		_debug_print_scene_tree(child, depth + 1, max_depth)

func _find_node_by_name(root: Node, target_name: String) -> Node:
	if root.name == target_name:
		return root
	
	for child in root.get_children():
		var result = _find_node_by_name(child, target_name)
		if result != null:
			return result
	
	return null

func _find_best_tracker() -> void:
	var best: Node3D = null
	var best_d: float = INF
	var candidates: int = 0
	
	# Search in multiple ways to be thorough
	var all_nodes: Array[Node] = []
	
	# Method 1: Group search
	all_nodes.append_array(get_tree().get_nodes_in_group(tracker_group))
	
	# Method 2: Recursive search from root (as backup)
	if all_nodes.is_empty():
		if debug_enabled:
			print("[TRACKER] Group search failed, trying recursive search...")
		_recursive_node_search(get_tree().current_scene, all_nodes)
	
	# Method 3: Search by name as fallback (if group method fails)
	if all_nodes.is_empty():
		if debug_enabled:
			print("[TRACKER] Recursive search failed, trying name-based search...")
		var name_result = _find_node_by_name(get_tree().current_scene, tracker_group)
		if name_result and name_result is Node3D:
			all_nodes.append(name_result)
			if debug_enabled:
				print("[TRACKER] Found by name: ", name_result.name)
	
	if debug_enabled:
		print("[TRACKER] Found ", all_nodes.size(), " potential candidates")
	
	for n in all_nodes:
		if n is Node3D and is_instance_valid(n) and n.is_inside_tree():
			candidates += 1
			var node3d = n as Node3D
			var d: float = node3d.global_transform.origin.distance_to(global_transform.origin)
			
			if debug_enabled:
				print("[TRACKER] Candidate: ", n.name, " at distance: ", d)
			
			if d < best_d:
				best_d = d
				best = node3d
	
	if best != null:
		tracker = best
		search_attempts = 0  # Reset attempts counter
		if debug_enabled:
			print("[TRACKER] ✓ Found best tracker: ", tracker.name, " at distance: ", best_d)
			print("[TRACKER] Tracker path: ", tracker.get_path())
	else:
		if debug_enabled:
			print("[TRACKER] ✗ No valid tracker found. Candidates checked: ", candidates)

func _recursive_node_search(node: Node, results: Array[Node]) -> void:
	if node == null:
		return
	
	if node.is_in_group(tracker_group):
		results.append(node)
	
	for child in node.get_children():
		_recursive_node_search(child, results)

func _periodic_search() -> void:
	if tracker == null and search_attempts < max_search_attempts:
		search_attempts += 1
		if debug_enabled:
			print("[TRACKER] Periodic search attempt ", search_attempts, "/", max_search_attempts)
		_comprehensive_search()
	elif tracker == null and search_attempts >= max_search_attempts:
		if debug_enabled:
			print("[TRACKER] ⚠ Giving up search after ", max_search_attempts, " attempts")

func _physics_process(delta: float) -> void:
	if tracker == null or !is_instance_valid(tracker) or !tracker.is_inside_tree():
		refind_cooldown -= delta
		if refind_cooldown <= 0.0:
			_find_best_tracker()
			refind_cooldown = 0.25
		return

	var to_target: Vector3 = tracker.global_transform.origin - global_transform.origin

	# Always interpolate position smoothly
	if use_direct_positioning:
		global_transform.origin = global_transform.origin.lerp(tracker.global_transform.origin, 0.25)
	else:
		var desired_vel: Vector3 = to_target / max(delta, 1e-4)
		var dv: Vector3 = desired_vel - velocity
		if dv.length() > max_accel:
			dv = dv.normalized() * max_accel
		velocity += dv
		if velocity.length() > max_speed:
			velocity = velocity.normalized() * max_speed
		
		if not disable_gravity:
			velocity += get_gravity() * delta
		
		move_and_slide()
	
	var tgt_basis := tracker.global_transform.basis.orthonormalized()
	global_transform.basis = global_transform.basis.slerp(tgt_basis, rot_lerp)
