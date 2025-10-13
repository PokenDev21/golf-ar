extends Node3D

# ------------------------------
# XR / AR Setup
# ------------------------------
var xr_interface: XRInterface

@onready var viewport : Viewport = get_viewport()
@onready var environment : Environment = $WorldEnvironment.environment
@onready var golfball : RigidBody3D = $GolfBall  # Your existing GolfBall node

# Currently loaded level
var current_level: Node3D

func _ready():
	# XR initialization
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		switch_to_ar()
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		viewport.use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")

	# Connect to Game.level_started signal
	if not Game.is_connected("level_started", Callable(self, "_on_level_started")):
		Game.connect("level_started", Callable(self, "_on_level_started"))

	# Load current level if already set
	if Game.current_level_path != "":
		load_level(Game.current_level_path)

# ------------------------------
# XR / AR Functions
# ------------------------------
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
	environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
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

# ------------------------------
# Dynamic Level Loading
# ------------------------------
func _on_level_started(level_id: String) -> void:
	var level_path = "res://Levels/%s.tscn" % level_id
	load_level(level_path)

func load_level(level_path: String) -> void:
	# Remove old level
	if current_level:
		current_level.queue_free()

	var level_scene = load(level_path)
	if not level_scene:
		push_error("Failed to load level: " + level_path)
		return

	current_level = level_scene.instantiate()
	add_child(current_level)

	# Move golfball to SpawnPoint (parented to level)
	if current_level.has_node("SpawnPoint") and golfball:
		var spawn = current_level.get_node("SpawnPoint")
		current_level.add_child(golfball)
		golfball.transform = spawn.transform       # local to level
		golfball.linear_velocity = Vector3.ZERO
		golfball.angular_velocity = Vector3.ZERO
		golfball.sleeping = true
		print("Golfball spawned at SpawnPoint for level:", level_path)
