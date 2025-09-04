extends Node

func _process(_delta):
	# FPS log
	var fps = Engine.get_frames_per_second()
	print("FPS: %d" % fps)

	# VSync status log
	var vsync_mode = DisplayServer.window_get_vsync_mode()
	match vsync_mode:
		DisplayServer.VSYNC_DISABLED:
			print("VSync: Disabled")
		DisplayServer.VSYNC_ENABLED:
			print("VSync: Enabled")
		DisplayServer.VSYNC_ADAPTIVE:
			print("VSync: Adaptive")
		DisplayServer.VSYNC_MAILBOX:
			print("VSync: Mailbox")
		_:
			print("VSync: Unknown")
