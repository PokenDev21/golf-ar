# game_manager.gd
extends Node3D

@onready var course_container = $"../Course"
var golf_ball: RigidBody3D

func _ready():
	# Kontrollera att course_container finns
	if course_container == null:
		push_error("Course noden hittades inte! Se till att den finns på samma nivå som GameManager")
		# Skapa en course container automatiskt
		course_container = Node3D.new()
		course_container.name = "Course"
		get_parent().add_child(course_container)
		course_container.owner = get_tree().edited_scene_root
	
	# Kontrollera om testbanan finns
	if ResourceLoader.exists("res://test_course.tscn"):
		load_test_course("res://test_course.tscn")
	else:
		# Om banan inte finns, skapa en enkel direkt
		create_simple_course()
	
	spawn_golf_ball()

func load_test_course(course_path: String):
	var course_scene = load(course_path)
	var current_course = course_scene.instantiate()
	course_container.add_child(current_course)
	print("Testbana laddad från: ", course_path)

func create_simple_course():
	# Skapa en enkel bana programmatiskt
	var green = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(10, 0.1, 20)
	collision.shape = shape
	
	var mesh = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(10, 20)
	mesh.mesh = plane_mesh
	
	# Sätt material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 0.5, 0)  # Grön färg
	mesh.material_override = material
	
	green.add_child(collision)
	green.add_child(mesh)
	green.position = Vector3(0, -0.05, 0)  # Lite under noll
	
	course_container.add_child(green)
	print("Enkel bana skapad automatiskt!")

func spawn_golf_ball():
	# Kontrollera om golfboll-scenen finns
	if ResourceLoader.exists("res://golf_ball.tscn"):
		var ball_scene = load("res://golf_ball.tscn")
		golf_ball = ball_scene.instantiate()
		golf_ball.position = Vector3(0, 0.5, 0)  # Ovanför banan
		add_child(golf_ball)
		print("Golfboll laddad!")
		
		# Ge Godot lite tid att ladda scenen innan vi försöker komma åt dess noder
		await get_tree().create_timer(0.1).timeout
	else:
		# Skapa en enkel boll om den inte finns
		create_simple_ball()

func create_simple_ball():
	golf_ball = RigidBody3D.new()
	golf_ball.name = "GolfBall"
	golf_ball.mass = 0.045
	
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.1
	collision.shape = shape
	
	var mesh = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	mesh.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1)  # Vit färg
	mesh.material_override = material
	
	golf_ball.add_child(collision)
	golf_ball.add_child(mesh)
	golf_ball.position = Vector3(0, 0.2, 0)
	
	add_child(golf_ball)
	print("Enkel golfboll skapad automatiskt!")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Spacebar
		if golf_ball:
			golf_ball.apply_central_impulse(Vector3(0, 0, -0.1))
			print("Mild kraft applicerad på bollen")
	
	# Använd "ui_redo" istället för "ui_reset" om du inte vill lägga till input action
	if event.is_action_pressed("ui_redo"):  # Ctrl+Y eller lägg till ui_reset manuellt
		if golf_ball:
			golf_ball.linear_velocity = Vector3.ZERO
			golf_ball.angular_velocity = Vector3.ZERO
			golf_ball.position = Vector3(0, 0.2, 0)
			print("Bollen återställd!")
