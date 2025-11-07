extends Node3D

@export var target: Node3D  # The vehicle to follow
@export var camera_distance: float = 8.0
@export var camera_height: float = 3.0
@export var rotation_speed: float = 2.0
@export var follow_smoothness: float = 5.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var camera_rotation: float = 0.0
var mouse_sensitivity: float = 0.002

func _ready() -> void:
	if spring_arm:
		spring_arm.spring_length = camera_distance
	
	# Set camera as current
	if camera:
		camera.make_current()

func _process(delta: float) -> void:
	if not target:
		return
	
	# Smoothly follow the target
	global_position = global_position.lerp(target.global_position, delta * follow_smoothness)
	
	# Handle camera rotation with keyboard
	var rotate_input = Input.get_axis("ui_page_down", "ui_page_up")
	camera_rotation += rotate_input * rotation_speed * delta
	
	# Apply rotation
	rotation.y = camera_rotation

func _unhandled_input(event: InputEvent) -> void:
	# Handle mouse rotation when right mouse button is held
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_rotation -= event.relative.x * mouse_sensitivity
		
		# Optional: vertical rotation
		if spring_arm:
			var vertical_rotation = spring_arm.rotation.x - event.relative.y * mouse_sensitivity
			spring_arm.rotation.x = clamp(vertical_rotation, -PI/3, PI/6)
