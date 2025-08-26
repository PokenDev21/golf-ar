# test_controller.gd
extends Node

# Ta bort @onready raderna som försöker hitta noder
# och ersätt med:

func _ready():
	# Vänta en frame innan du försöker hitta noder
	await get_tree().process_frame
	setup_references()

func setup_references():
	# Försök hitta noderna säkert
	var golf_ball = get_parent()
	if golf_ball and golf_ball.has_node("GolfBallPhysics"):
		var physics_node = golf_ball.get_node("GolfBallPhysics")
		print("Noder hittades")
	else:
		print("Varning: Noder kunde inte hittas")
