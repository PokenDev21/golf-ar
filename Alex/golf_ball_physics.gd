extends Node3D

# Referenser
@onready var rigid_body = get_parent() as RigidBody3D

# Fysikparametrar
const FRICTION_GREEN = 0.05  # Friktion på green
const ROLLING_RESISTANCE = 0.02
const AIR_RESISTANCE = 0.001
const MIN_VELOCITY = 0.1  # Minsta hastighet för att anses röra sig
const BALL_RADIUS = 0.02135  # Standard golfbollsradie i meter (4.27cm diameter)

# Bolltillstånd
var is_rolling = false
var last_position = Vector3.ZERO
var contact_normal = Vector3.UP
var is_on_green = true

func _ready():
	last_position = rigid_body.global_position
	# Ställ in bollens fysikegenskaper
	rigid_body.continuous_cd = true  # Kontinuerlig kollisionsdetektering

func _physics_process(delta):
	if rigid_body.sleeping:
		return
	
	# Kontrollera om bollen rullar
	check_rolling_state()
	
	# Applicera realistisk fysik
	apply_rolling_friction(delta)
	apply_air_resistance(delta)
	apply_ground_friction(delta)
	
	# Uppdatera rotation baserat på hastighet
	update_ball_rotation(delta)
	
	# Spara position för nästa frame
	last_position = rigid_body.global_position

func apply_force(force_vector: Vector3, position: Vector3 = Vector3.ZERO):
	# Applicera en kraft på bollen (simulerar ett slag)
	rigid_body.apply_impulse(force_vector, position)
	is_rolling = true

func check_rolling_state():
	var linear_velocity = rigid_body.linear_velocity
	var speed = linear_velocity.length()
	
	# Kontrollera om bollen rullar eller glider
	if speed > MIN_VELOCITY and is_on_green:
		# Beräkna rullvillkor
		var angular_speed = rigid_body.angular_velocity.length()
		var expected_angular_speed = speed / BALL_RADIUS
		
		# Om vinkelhastigheten är nära förväntad rullhastighet
		if abs(angular_speed - expected_angular_speed) < 2.0:
			is_rolling = true
		else:
			is_rolling = false
	else:
		is_rolling = false
		if speed < MIN_VELOCITY:
			rigid_body.linear_velocity = Vector3.ZERO
			rigid_body.angular_velocity = Vector3.ZERO

func apply_rolling_friction(delta):
	if not is_rolling:
		return
		
	var linear_velocity = rigid_body.linear_velocity
	var speed = linear_velocity.length()
	
	if speed > 0:
		# Rullfriktion är proportionell mot normalkraften (mass * gravity)
		var friction_force = FRICTION_GREEN * rigid_body.mass * 9.81 * delta
		
		# Rikta friktionskraften mot rörelseriktningen
		var friction_vector = -linear_velocity.normalized() * friction_force
		
		# Applicera friktionen
		rigid_body.apply_central_force(friction_vector)

func apply_air_resistance(delta):
	var linear_velocity = rigid_body.linear_velocity
	var speed = linear_velocity.length()
	
	if speed > 0:
		# Luftmotstånd är proportionellt mot hastighetens kvadrat
		var drag_force = AIR_RESISTANCE * speed * speed * delta
		
		# Rikta mot rörelseriktningen
		var drag_vector = -linear_velocity.normalized() * drag_force
		
		# Applicera luftmotstånd
		rigid_body.apply_central_force(drag_vector)

func apply_ground_friction(delta):
	if not is_on_green:
		return
		
	var linear_velocity = rigid_body.linear_velocity
	var lateral_velocity = linear_velocity - linear_velocity.project(contact_normal)
	var lateral_speed = lateral_velocity.length()
	
	if lateral_speed > 0 and is_rolling:
		# Markfriktion för sidorörelser
		var friction_force = ROLLING_RESISTANCE * rigid_body.mass * 9.81 * delta
		
		# Rikta mot sidorörelsen
		var friction_vector = -lateral_velocity.normalized() * friction_force
		
		# Applicera friktionen
		rigid_body.apply_central_force(friction_vector)

func update_ball_rotation(delta):
	if is_rolling:
		# Uppdatera rotation baserat på linjär hastighet
		var linear_velocity = rigid_body.linear_velocity
		var travel_distance = linear_velocity * delta
		
		# Beräkna rotationsändring baserat på tillryggalagd sträcka
		var rotation_angle = travel_distance.length() / BALL_RADIUS
		
		if travel_distance.length() > 0:
			var rotation_axis = travel_distance.cross(contact_normal).normalized()
			var rotation_change = Quaternion(rotation_axis, rotation_angle)
			
			# Applicera rotation
			rigid_body.rotation *= rotation_change

func _on_rigid_body_contact(contact_count, contacts):
	# Hantera kontakter med ytor
	if contact_count > 0:
		is_on_green = true
		contact_normal = contacts[0].normal
		
		# Ytterligare kontaktlogik kan läggas till här
	else:
		is_on_green = false
