extends Camera3D

## Free exploration camera with WASD movement and mouse look

@export var move_speed: float = 5.0
@export var sprint_multiplier: float = 2.0
@export var mouse_sensitivity: float = 0.003
@export var acceleration: float = 10.0
@export var deceleration: float = 8.0

var velocity: Vector3 = Vector3.ZERO
var mouse_captured: bool = false

# Collision detection
@onready var ray_cast: RayCast3D = $RayCast3D

func _ready() -> void:
	# Create raycast for collision detection if it doesn't exist
	if not has_node("RayCast3D"):
		ray_cast = RayCast3D.new()
		add_child(ray_cast)
		ray_cast.target_position = Vector3(0, 0, -0.5)
		ray_cast.enabled = true
	
	# Capture mouse on ready
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true

func _input(event: InputEvent) -> void:
	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		if mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			mouse_captured = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true
	
	# Mouse look
	if event is InputEventMouseMotion and mouse_captured:
		_handle_mouse_look(event.relative)

func _physics_process(delta: float) -> void:
	_handle_movement(delta)

func _handle_mouse_look(relative: Vector2) -> void:
	"""Handle mouse look rotation"""
	# Rotate camera horizontally (around Y axis)
	rotate_y(-relative.x * mouse_sensitivity)
	
	# Rotate camera vertically (around local X axis)
	var camera_rot = rotation
	camera_rot.x -= relative.y * mouse_sensitivity
	# Clamp vertical rotation to prevent flipping
	camera_rot.x = clamp(camera_rot.x, -PI/2 + 0.1, PI/2 - 0.1)
	rotation = camera_rot

func _handle_movement(delta: float) -> void:
	"""Handle WASD movement with acceleration/deceleration"""
	# Get input direction
	var input_dir = Vector3.ZERO
	
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir += transform.basis.z
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir += transform.basis.x
	
	# Normalize to prevent faster diagonal movement
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	# Apply sprint multiplier
	var current_speed = move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed *= sprint_multiplier
	
	# Calculate target velocity
	var target_velocity = input_dir * current_speed
	
	# Smooth acceleration/deceleration
	if input_dir.length() > 0:
		velocity = velocity.lerp(target_velocity, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector3.ZERO, deceleration * delta)
	
	# Check for collision before moving
	var next_position = global_position + velocity * delta
	if not _will_collide(next_position):
		global_position = next_position

func _will_collide(next_position: Vector3) -> bool:
	"""Check if moving to next_position would cause a collision"""
	if not ray_cast:
		return false
	
	# Cast ray from current position to next position
	var direction = (next_position - global_position).normalized()
	var distance = global_position.distance_to(next_position)
	
	ray_cast.target_position = direction * (distance + 0.3)  # Add small buffer
	ray_cast.force_raycast_update()
	
	return ray_cast.is_colliding()

func set_position_and_rotation(pos: Vector3, rot: Vector3) -> void:
	"""Set camera position and rotation (useful for transitions)"""
	global_position = pos
	rotation = rot
	velocity = Vector3.ZERO
