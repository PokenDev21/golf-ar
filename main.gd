extends Node3D

var xr_interface: XRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		
		switch_to_ar()

		# Turn off v-sync for better XR performance
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Set viewport to output to HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")


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

	get_viewport().transparent_bg = true
	return true

@onready var viewport : Viewport = get_viewport()
@onready var environment : Environment = $WorldEnvironment.environment

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
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
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
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	return true
