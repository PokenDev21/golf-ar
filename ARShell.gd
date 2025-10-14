extends Node3D

# ------------------------------
# XR / AR Setup
# ------------------------------
var xr_interface: XRInterface
@onready var viewport: Viewport = get_viewport()
@onready var environment: Environment = $WorldEnvironment.environment

# ------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------
func _ready():
	print("[AR] Initializing AR shell for main menu...")

	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("[AR] OpenXR initialized successfully (Main Menu Mode)")
		switch_to_ar()
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		viewport.use_xr = true
	else:
		push_warning("[AR] ⚠️ OpenXR not initialized. Make sure your headset is connected.")

# ------------------------------------------------------------------------
# XR / AR Functions
# ------------------------------------------------------------------------
func enable_passthrough() -> bool:
	if not xr_interface:
		print("[AR] No XR interface found.")
		return false

	if xr_interface.is_passthrough_supported():
		if not xr_interface.start_passthrough():
			print("[AR] Failed to start passthrough mode.")
			return false
	else:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
			xr_interface.set_environment_blend_mode(XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND)
		else:
			print("[AR] Passthrough not supported on this device.")
			return false

	viewport.transparent_bg = true
	print("[AR] Passthrough enabled.")
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
		print("[AR] No primary XR interface found.")
		return false

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
	print("[AR] Switched to AR rendering mode.")
	return true

func switch_to_vr() -> bool:
	var xr_interface: XRInterface = XRServer.primary_interface
	if xr_interface:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_OPAQUE in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE
		else:
			print("[AR] Opaque blend mode not supported.")
			return false
	viewport.transparent_bg = false
	environment.background_mode = Environment.BG_SKY
	print("[AR] Switched to VR rendering mode.")
	return true
