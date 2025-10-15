extends XROrigin3D

var golf_ball: Node3D = null
const Y_OFFSET := 0    # about 30 cm above the ball
const Z_OFFSET := 0.3  # just 5 cm back on Z, barely noticeable

func _ready() -> void:
	call_deferred("_find_golf_ball")

func _find_golf_ball() -> void:
	# Try by group
	golf_ball = get_tree().get_first_node_in_group("golf_ball")
	
	# If not found, try by name
	if golf_ball == null:
		golf_ball = get_tree().root.find_child("GolfBall", true, false)
	
	if golf_ball:
		print("[GOLF] ✅ GolfBall found at: ", golf_ball.get_path())
		teleport_to_ball()
	else:
		print("[GOLF] ⚠️ GolfBall not found in groups or by name.")

func teleport_to_ball() -> void:
	if golf_ball == null:
		return
	
	var target_pos = golf_ball.global_transform.origin
	
	# Apply small offsets 
	target_pos.y += Y_OFFSET
	target_pos.z += Z_OFFSET
	
	global_transform.origin = target_pos
