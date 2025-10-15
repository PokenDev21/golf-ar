extends Node3D

var xr_interface: XRInterface
@onready var viewport: Viewport = get_viewport()
@onready var environment: Environment = $WorldEnvironment.environment

@onready var golfball: RigidBody3D = get_node_or_null("GolfBall")
@onready var score_ui: Control = get_node_or_null("ScoreLabel") # UI node for displaying score

var current_level: Node3D
var _connected_to_game := false
var _can_load_levels := false

var LEVEL_PARS := {
	"level_1": 4,
	"level_2": 3,
	"level_3": 3
}

func _ready():
	_can_load_levels = golfball != null

	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		switch_to_ar()
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		viewport.use_xr = true
	else:
		print("OpenXR not initialized, check headset")

	# Only connect game signals when in play scene
	if _can_load_levels:
		if not Game.is_connected("level_started", Callable(self, "_on_level_started")):
			Game.connect("level_started", Callable(self, "_on_level_started"))
			_connected_to_game = true

		if golfball and score_ui:
			if not golfball.is_connected("ball_in_hole", Callable(score_ui, "show_score")):
				golfball.connect("ball_in_hole", Callable(score_ui, "show_score"))
				print("[Main] Connected golfball to score UI")

		if Game.current_level_path != "":
			load_level(Game.current_level_path)
	else:
		print("[Menu] Level loading disabled.")
		# If returning to menu, show last score
		if score_ui and Game.last_result != "":
			score_ui.show_score(Game.last_strokes, Game.last_par, Game.last_result)

func enable_passthrough() -> bool:
	if not xr_interface:
		return false
	if xr_interface.is_passthrough_supported():
		if not xr_interface.start_passthrough():
			return false
	else:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
			xr_interface.set_environment_blend_mode(XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND)
		else:
			return false
	viewport.transparent_bg = true
	return true

func switch_to_ar() -> bool:
	var xr_interface: XRInterface = XRServer.primary_interface
	if xr_interface:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
			viewport.transparent_bg = true
		elif XRInterface.XR_ENV_BLEND_MODE_ADDITIVE in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ADDITIVE
			viewport.transparent_bg = false
	else:
		return false

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0,0,0,0)
	return true

func switch_to_vr() -> bool:
	var xr_interface: XRInterface = XRServer.primary_interface
	if xr_interface:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_OPAQUE in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE
		else:
			return false
	viewport.transparent_bg = false
	environment.background_mode = Environment.BG_SKY
	return true

func _on_level_started(level_id: String) -> void:
	if not _can_load_levels:
		return
	if LEVEL_PARS.has(level_id):
		golfball.set("par", LEVEL_PARS[level_id])
	else:
		golfball.set("par", 3)
	var level_path = "res://Levels/%s.tscn" % level_id
	load_level(level_path)

func load_level(level_path: String) -> void:
	if not _can_load_levels:
		return

	if current_level and is_instance_valid(current_level):
		remove_child(current_level)
		current_level.queue_free()
		await get_tree().process_frame
		current_level = null

	var level_scene := load(level_path)
	if not level_scene:
		push_error("Failed to load level: " + level_path)
		return

	current_level = level_scene.instantiate()
	add_child(current_level)
	print("[GameShell] ✅ Loaded level:", current_level.name)

	if current_level.has_node("SpawnPoint") and golfball:
		var spawn := current_level.get_node("SpawnPoint")
		var spawn_xform: Transform3D = spawn.global_transform
		if golfball.get_parent():
			golfball.get_parent().remove_child(golfball)
		current_level.add_child(golfball)
		golfball.global_transform = spawn_xform
		if golfball.has_method("set_spawn_transform"):
			golfball.set_spawn_transform(spawn_xform)
		golfball.linear_velocity = Vector3.ZERO
		golfball.angular_velocity = Vector3.ZERO
		golfball.sleeping = true
		await get_tree().process_frame
		golfball.sleeping = false
		print("[GameShell] Golfball spawned at:", spawn_xform.origin)
	else:
		push_warning("SpawnPoint not found in level: " + level_path)

func cleanup_before_exit() -> void:
	if not _can_load_levels:
		return
	var children = get_children()
	for child in children:
		child.queue_free()
	current_level = null
	golfball = null
	await get_tree().process_frame

func _exit_tree() -> void:
	if _can_load_levels and _connected_to_game and Game.is_connected("level_started", Callable(self, "_on_level_started")):
		Game.disconnect("level_started", Callable(self, "_on_level_started"))
		_connected_to_game = false
