extends VehicleBody3D

@export var max_speed: float = 20.0
@export var acceleration: float = 10.0
@export var steering_limit: float = 0.5
@export var brake_force: float = 5.0

var current_speed: float = 0.0
var steering_angle: float = 0.0

func _ready() -> void:
	# Configure vehicle physics properties
	mass = 1200.0  # kg
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.5, 0)  # Lower center of mass for stability

func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_check_proximity_triggers()
	
	# Update current speed for reference
	current_speed = linear_velocity.length()

func _handle_input(delta: float) -> void:
	# Get input
	var throttle = Input.get_axis("ui_down", "ui_up")
	var steer = Input.get_axis("ui_right", "ui_left")
	var brake = Input.is_action_pressed("ui_accept")  # Space for brake
	
	# Apply steering
	steering_angle = lerpf(steering_angle, steer * steering_limit, delta * 5.0)
	steering = steering_angle
	
	# Apply throttle/brake
	if brake:
		engine_force = 0.0
		brake = brake_force
	else:
		# Limit speed
		if current_speed < max_speed:
			engine_force = throttle * acceleration
		else:
			engine_force = 0.0
		brake = 0.0

func _check_proximity_triggers() -> void:
	# This will be used in subtask 3.3 for automatic gate/garage opening
	pass
