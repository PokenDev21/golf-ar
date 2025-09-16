extends XRController3D

func _process(delta: float) -> void:
	for btn_name in [
		"primary_click",
		"secondary_click",
		"trigger_click",
		"grip_click",
		"thumbstick_click",
		"menu",          # sometimes works
		"menu_button",   # depending on Godot version
	]:
		if is_button_pressed(btn_name):
			print(name, " pressed: ", btn_name)
